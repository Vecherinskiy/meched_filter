
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
USE ieee.std_logic_arith.all;


entity multiplier_LUT is

    generic(
        N : integer := 16);

    Port ( clk : in STD_LOGIC;
        reset       : in  std_logic;
        samp_dv     : in  std_logic;
        coef_real   : in  STD_LOGIC_VECTOR (N - 1 downto 0);
        coef_imag   : in  STD_LOGIC_VECTOR (N - 1 downto 0);
        real_count  : in  STD_LOGIC_VECTOR (N - 1 downto 0);
        imag_count  : in  STD_LOGIC_VECTOR (N - 1 downto 0);
        real_sum_dv : out std_logic;
        real_sum    : out STD_LOGIC_VECTOR (2 * N - 1 downto 0);
        imag_sum    : out STD_LOGIC_VECTOR (2 * N - 1 downto 0));



end multiplier_LUT;


architecture Behavioral of multiplier_LUT is


    signal dv_reg : STD_LOGIC_VECTOR(3 downto 0) := (others => '0');

    type ROM_COUNT is array (0 to 1) of std_logic_vector(N - 1 downto 0);
    signal r_count : ROM_COUNT := (others => (others => '0'));

    type SUM is array (0 to 1) of std_logic_vector(2 * N - 1 downto 0);
    signal rez_real_sum    : SUM                                  := (others => (others => '0'));
    signal rez_imag_sum    : SUM                                  := (others => (others => '0'));
    signal sum_r, sum_i    : std_logic_vector(2 * N - 1 downto 0) := (others => '0');


begin
    process (clk)
    begin
        if reset = '1' then
            dv_reg       <= (others => '0');
            rez_real_sum <= (others => (others => '0'));
            rez_imag_sum <= (others => (others => '0'));
            r_count      <= (others => (others => '0'));
        else
            if rising_edge(clk) then
                dv_reg(0)       <= samp_dv;
                dv_reg(1)       <= dv_reg(0);
                rez_real_sum(0) <= signed(coef_real) * signed(real_count);
                rez_imag_sum(0) <= signed(coef_real) * signed(imag_count);
                r_count(0)      <= real_count;
                r_count(1)      <= imag_count;
                rez_real_sum(1) <= signed(rez_real_sum(0)) - signed(coef_imag) * signed(r_count(1));
                rez_imag_sum(1) <= signed(rez_imag_sum(0)) + signed(coef_imag) * signed(r_count(0));
            end if;
        end if;
    end process;

    process (clk)
    begin
        if reset = '1' then
            real_sum_dv <= '0';
            real_sum    <= (others => '0');
            imag_sum    <= (others => '0');
        else
            if rising_edge(clk) then
                real_sum_dv <= dv_reg(1);
                real_sum <= rez_real_sum(1);
                imag_sum <= rez_imag_sum(1);
            end if;
        end if;
    end process;


end Behavioral;
