library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.std_logic_arith.all;

use work.MY_COEF.all;


entity Adder_new is
    generic (
        N_X        : natural;
        N_COEF     : natural;
        WIDTH_IN   : natural;
        WIDTH_OUT  : natural;
        WIDTH_COEF : natural
    );

    port (
        clk        : in  std_logic;
        reset      : in  std_logic;
        samp_dv    : in  std_logic;
        input_coef : in  COEF_X_COMPLEX;
        samp       : in  complex_num_in;
        part_sum   : in  complex_num;
        out_sum_dv : out std_logic;
        out_sum    : out complex_num
    );

end Adder_new;

architecture Behavioral of Adder_new is

    constant null_un : unsigned(N_X - 1 downto 0) := (others => '0');
    signal sum       : complex_num                := zeros_complex;

    type DELAY_SAMP is array (0 to N_X - 1, 0 to 1) of complex_num;
    signal delay_data : DELAY_SAMP;

    type PSUM_REG is array (0 to N_X - 1) of complex_num;
    signal part_sum_reg : PSUM_REG;

    signal count       : std_logic_vector (3 downto 0)       := (others => '0');
    signal dv_reg      : std_logic_vector (N_X - 1 downto 0) := (others => '0');
    signal rez_mult    : complex_num;
    signal sum_dv      : std_logic;
    signal rez_mult_dv : std_logic;


    procedure write_mult (count : in unsigned;
            signal rez_mult   : in    complex_num;
            signal delay_data : inout DELAY_SAMP
        ) is
    begin
        delay_data(conv_integer(count), 0) <= delay_data(conv_integer(count), 1);
        delay_data(conv_integer(count), 1) <= rez_mult;
    end procedure write_mult;

    procedure write_part_sum (
            signal part_sum     : in    complex_num;
            signal part_sum_reg : inout PSUM_REG
        ) is
    begin
        for i in 0 to N_X - 2 loop
            part_sum_reg(i + 1) <= part_sum_reg(i);
        end loop;
        part_sum_reg(0) <= part_sum;
    end procedure write_part_sum;

    procedure write_dv_reg (
            signal rez_mult_dv : in    std_logic;
            signal dv_reg      : inout std_logic_vector (N_X - 1 downto 0)
        ) is
    begin
        for i in 0 to N_X - 2 loop
            dv_reg(i + 1) <= dv_reg(i);
        end loop;
        dv_reg(0) <= rez_mult_dv;
    end procedure write_dv_reg;

    procedure reset_mamory (
            signal delay_data : out DELAY_SAMP
        ) is
    begin
        for i in 0 to N_X - 1 loop
            for j in 0 to 1 loop
                delay_data(i, j) <= zeros_complex;
            end loop;
        end loop;
    end procedure reset_mamory;

    procedure reset_part_sum_reg (
            signal part_sum_reg : out PSUM_REG
        ) is
    begin
        for i in 0 to N_X - 1 loop
            part_sum_reg(i) <= zeros_complex;
        end loop;
    end procedure reset_part_sum_reg;

    component complex_multiplier
        generic (
            N_X        : natural;
            N_COEF     : natural;
            WIDTH_IN   : natural;
            WIDTH_OUT  : natural;
            WIDTH_COEF : natural
        );

        port (
            clk         : in  std_logic;
            samp_dv     : in  std_logic;
            input_coef  : in  COEF_X_COMPLEX;
            samp        : in  complex_num_in;
            out_mult_dv : out std_logic;
            out_mult    : out complex_num
        );
    end component complex_multiplier;


begin

    mult : complex_multiplier

        generic map (
            N_X        => N_X,
            N_COEF     => N_COEF,
            WIDTH_IN   => WIDTH_IN,
            WIDTH_OUT  => WIDTH_OUT,
            WIDTH_COEF => WIDTH_COEF
        )

        port map(
            clk         => clk,
            samp_dv     => samp_dv,
            input_coef  => input_coef,
            samp        => samp,
            out_mult_dv => rez_mult_dv,
            out_mult    => rez_mult
        );


    process(clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                count <= (others => '0');
                reset_mamory(delay_data);
            else
                if rez_mult_dv = '1' then
                    write_mult(conv_unsigned(0, count'length), rez_mult, delay_data);
                else
                    if (unsigned(count) > 0 and unsigned(count) < N_X) then
                        delay_data(conv_integer(unsigned(count)), 0)          <= delay_data(conv_integer(unsigned(count)), 1);
                        delay_data(conv_integer(unsigned(count)), 1).num_real <= signed(rez_mult.num_real) + signed(delay_data(conv_integer(unsigned(count)) - 1, 0).num_real);
                        delay_data(conv_integer(unsigned(count)), 1).num_imag <= signed(rez_mult.num_imag) + signed(delay_data(conv_integer(unsigned(count)) - 1, 0).num_imag);
                    end if;
                end if;

                if rez_mult_dv = '1' then
                    count <= conv_std_logic_vector(1, count'length);
                else
                    if (unsigned(count) > 0 and unsigned(count) < N_X + 2) then
                        count <= unsigned(count) + 1;
                    end if;
                end if;
            end if;
        end if;
    end process;

    process(clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                reset_part_sum_reg(part_sum_reg);
            else
                if dv_reg(N_X - 1) = '1' then
                    write_part_sum(part_sum, part_sum_reg);
                end if;
            end if;
        end if;
    end process;


    process(clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                out_sum <= zeros_complex;
                dv_reg  <= (others => '0');
                out_sum_dv <= '0';
                sum_dv <= '0';
            else
                if dv_reg(N_X - 1) = '1' then
                    sum <= delay_data(N_X - 1, 1);
                end if;
                write_dv_reg(rez_mult_dv, dv_reg);
                sum_dv     <= dv_reg(N_X - 1);
                out_sum_dv <= sum_dv;
                if sum_dv = '1' then
                    out_sum.num_real <= signed(sum.num_real) + signed(part_sum_reg(N_X - 1).num_real);
                    out_sum.num_imag <= signed(sum.num_imag) + signed(part_sum_reg(N_X - 1).num_imag);
                end if;
            end if;
        end if;
    end process;


end Behavioral;