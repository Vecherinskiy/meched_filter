library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use work.MY_COEF.all;

entity Filter is
    generic (
        N_X        : natural := 2;
        N_COEF     : natural := 16;
        WIDTH_IN   : natural := 16;
        WIDTH_OUT  : natural := 16;
        WIDTH_COEF : natural := 16
    );

    port (
        clk           : in  std_logic;
        reset         : in  std_logic;
        samp_dv       : in  std_logic;
        samp_real     : in  std_logic_vector (WIDTH_IN - 1 downto 0);
        samp_imag     : in  std_logic_vector (WIDTH_IN - 1 downto 0);
        out_data_dv   : out std_logic;
        out_data_real : out std_logic_vector (WIDTH_OUT - 1 downto 0);
        out_data_imag : out std_logic_vector (WIDTH_OUT - 1 downto 0)
    );

end Filter;

architecture Behavioral of Filter is

    type DELAY_PARTIAL_SUM is array (0 to N_COEF / N_X + 1) of complex_num;
    signal partial_sum : DELAY_PARTIAL_SUM;

    type DELAY_DATA_DV is array (0 to N_COEF / N_X) of std_logic;
    signal data_dv_reg : DELAY_DATA_DV;

    signal arr_complex_coef : ROM_COMPLEX_COEF;
    signal arr_coef_x       : ARRAY_COEF_X;
    signal samp_complex     : complex_num_in;

    signal zero_point_five : std_logic_vector(N - 1 downto 0) := (others => '0');

    procedure conv_to_0_5 (signal out_real : out std_logic_vector) is
    begin
        out_real(N - WIDTH_COEF - 2) <= '1';
    end procedure conv_to_0_5;

    component Adder_new is
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
    end component Adder_new;

begin
    assemb_complex_coeff(real_coef, imag_coef, arr_complex_coef);
    assemb_coeff_x(arr_complex_coef, arr_coef_x);
    assemb_complex_num(samp_real, samp_imag, samp_complex);
    partial_sum(0).num_real <= (others => '0');
    partial_sum(0).num_imag <= (others => '0');
    conv_to_0_5(zero_point_five);

    InstTaps : for i in 0 to N_COEF / N_X - 1 generate
        Taps : Adder_new
            generic map(
                N_X        => N_X,
                N_COEF     => N_COEF,
                WIDTH_IN   => WIDTH_IN,
                WIDTH_OUT  => WIDTH_OUT,
                WIDTH_COEF => WIDTH_COEF
            )
            port map (
                clk        => clk,
                reset      => reset,
                samp_dv    => samp_dv,
                input_coef => arr_coef_x(N_COEF / N_X - 1 - i),
                samp       => samp_complex,
                part_sum   => partial_sum(i),
                out_sum_dv => data_dv_reg(i),
                out_sum    => partial_sum(i + 1)
            );
    end generate InstTaps;

    process(clk)
    begin
        if rising_edge(clk) then
            data_dv_reg(N_COEF / N_X)              <= data_dv_reg(N_COEF / N_X - 1);
            partial_sum(N_COEF / N_X + 1).num_real <= signed(partial_sum(N_COEF / N_X).num_real) + signed(zero_point_five);
            partial_sum(N_COEF / N_X + 1).num_imag <= signed(partial_sum(N_COEF / N_X).num_imag) + signed(zero_point_five);
        end if;
    end process;

    process(clk)
    begin
        if rising_edge(clk) then
            out_data_dv <= data_dv_reg(N_COEF / N_X);
            if (signed(partial_sum(N_COEF / N_X + 1).num_real) > 0) and (unsigned(partial_sum(N_COEF / N_X + 1).num_real(WIDTH_COEF - 2 downto 0)) = 0) then
                out_data_real <= partial_sum(N_COEF / N_X + 1).num_real(N - 2 downto WIDTH_COEF) & "0";
            else
                out_data_real <= partial_sum(N_COEF / N_X + 1).num_real(N - 2 downto WIDTH_COEF - 1);
            end if;
            if (signed(partial_sum(N_COEF / N_X + 1).num_imag) > 0) and (unsigned(partial_sum(N_COEF / N_X + 1).num_imag(WIDTH_COEF - 2 downto 0)) = 0) then
                out_data_imag <= partial_sum(N_COEF / N_X + 1).num_imag(N - 2 downto WIDTH_COEF) & "0";
            else
                out_data_imag <= partial_sum(N_COEF / N_X + 1).num_imag(N - 2 downto WIDTH_COEF - 1);
            end if;
        end if;
    end process;

end Behavioral;
