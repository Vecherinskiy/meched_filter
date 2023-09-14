library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.std_logic_arith.all;

use work.MY_COEF.all;

entity complex_multiplier is
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

end complex_multiplier;

architecture Behavioral of complex_multiplier is

    constant SIZE_MULT : natural := WIDTH_COEF + WIDTH_IN;

    signal dv_regist                                      : std_logic_vector(1 downto 0)             := (others => '0');
    signal coefs_real, coefs_imag                         : COEF_X;
    signal rez_mult_1, rez_mult_2, rez_mult_3, rez_mult_4 : std_logic_vector(SIZE_MULT - 1 downto 0) := (others => '0');
    signal rez_sum_real, rez_sum_imag                     : std_logic_vector(SIZE_MULT - 1 downto 0) := (others => '0');

    procedure conv_to_0_5 (signal out_real : out std_logic_vector) is
    begin
        out_real(SIZE_MULT - WIDTH_COEF - 2) <= '1';
    end procedure conv_to_0_5;

    component common_multiplier
        generic (
            N_X        : natural;
            N_COEF     : natural;
            WIDTH_IN   : natural;
            WIDTH_OUT  : natural;
            WIDTH_COEF : natural
        );

        port (
            clk        : in  std_logic;
            input_coef : in  COEF_X;
            samp_dv    : in  std_logic;
            samp       : in  std_logic_vector(WIDTH_IN - 1 downto 0);
            mult_dv    : out std_logic;
            mult       : out std_logic_vector(WIDTH_OUT - 1 downto 0)
        );
    end component common_multiplier;


begin

    Assign_coeff(input_coef, coefs_real, coefs_imag);

    mult_real_real : common_multiplier

        generic map (
            N_X        => N_X,
            N_COEF     => N_COEF,
            WIDTH_IN   => WIDTH_IN,
            WIDTH_OUT  => SIZE_MULT,
            WIDTH_COEF => WIDTH_COEF
        )

        port map(
            clk        => clk,
            input_coef => coefs_real,
            samp_dv    => samp_dv,
            samp       => samp.num_real,
            mult_dv    => dv_regist(0),
            mult       => rez_mult_1
        );

    mult_imag_imag : common_multiplier

        generic map (
            N_X        => N_X,
            N_COEF     => N_COEF,
            WIDTH_IN   => WIDTH_IN,
            WIDTH_OUT  => SIZE_MULT,
            WIDTH_COEF => WIDTH_COEF
        )

        port map(
            clk        => clk,
            input_coef => coefs_imag,
            samp_dv    => samp_dv,
            samp       => samp.num_imag,
            mult       => rez_mult_2
        );

    mult_real_imag : common_multiplier

        generic map (
            N_X        => N_X,
            N_COEF     => N_COEF,
            WIDTH_IN   => WIDTH_IN,
            WIDTH_OUT  => SIZE_MULT,
            WIDTH_COEF => WIDTH_COEF
        )

        port map(
            clk        => clk,
            input_coef => coefs_imag,
            samp_dv    => samp_dv,
            samp       => samp.num_real,
            mult       => rez_mult_3
        );

    mult_imag_real : common_multiplier

        generic map (
            N_X        => N_X,
            N_COEF     => N_COEF,
            WIDTH_IN   => WIDTH_IN,
            WIDTH_OUT  => SIZE_MULT,
            WIDTH_COEF => WIDTH_COEF
        )

        port map(
            clk        => clk,
            input_coef => coefs_real,
            samp_dv    => samp_dv,
            samp       => samp.num_imag,
            mult       => rez_mult_4
        );

    process(clk)
    begin
        if rising_edge(clk) then
            rez_sum_real <= signed(rez_mult_1) - signed(rez_mult_2);
            rez_sum_imag <= signed(rez_mult_3) + signed(rez_mult_4);
            dv_regist(1) <= dv_regist(0);
            out_mult_dv <= dv_regist(1);
            out_mult.num_real <= rez_sum_real;
            out_mult.num_imag <= rez_sum_imag;
        end if;
    end process;

end Behavioral;