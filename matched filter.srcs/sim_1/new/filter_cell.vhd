library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
USE ieee.std_logic_arith.all;

entity filter_cell is
    generic(
        N : integer := 16);
    Port ( clk : in STD_LOGIC;
        reset          : in  std_logic;
        samp_dv        : in  std_logic;
        coef_real      : in  STD_LOGIC_VECTOR (N - 1 downto 0);
        coef_imag      : in  STD_LOGIC_VECTOR (N - 1 downto 0);
        real_count     : in  STD_LOGIC_VECTOR (N - 1 downto 0);
        imag_count     : in  STD_LOGIC_VECTOR (N - 1 downto 0);
        part_sum_real  : in  STD_LOGIC_VECTOR (2 * N - 1 downto 0);
        part_sum_imag  : in  STD_LOGIC_VECTOR (2 * N - 1 downto 0);
        real_signal_dv : out STD_LOGIC;
        real_signal    : out STD_LOGIC_VECTOR (2 * N - 1 downto 0);
        imag_signal    : out STD_LOGIC_VECTOR (2 * N - 1 downto 0));
end filter_cell;

architecture Behavioral of filter_cell is

    component multiplier_LUT
        generic(
            N : integer := 16);
        Port ( clk : in STD_LOGIC;
            reset       : in  std_logic;
            samp_dv     : in  std_logic;
            coef_real   : in  STD_LOGIC_VECTOR (N - 1 downto 0);
            coef_imag   : in  STD_LOGIC_VECTOR (N - 1 downto 0);
            real_count  : in  STD_LOGIC_VECTOR (N - 1 downto 0);
            imag_count  : in  STD_LOGIC_VECTOR (N - 1 downto 0);
            real_sum_dv : out STD_LOGIC;
            real_sum    : out STD_LOGIC_VECTOR (2 * N - 1 downto 0);
            imag_sum    : out STD_LOGIC_VECTOR (2 * N - 1 downto 0));
    end component multiplier_LUT;

    signal rez_real_sum : std_logic_vector(2 * N - 1 downto 0) := (others => '0');
    signal rez_imag_sum : std_logic_vector(2 * N - 1 downto 0) := (others => '0');
    signal dv           : std_logic                        := '0';

begin

    MULT : multiplier_LUT
        generic map(
            N => N)
        port map(
            clk         => clk,
            reset       => reset,
            samp_dv     => samp_dv,
            coef_real   => coef_real,
            coef_imag   => coef_imag,
            real_count  => real_count,
            imag_count  => imag_count,
            real_sum_dv => dv,
            real_sum    => rez_real_sum,
            imag_sum    => rez_imag_sum);

    process (clk)
    begin
        if reset = '1' then
            real_signal_dv <= '0';
            real_signal    <= (others => '0');
            imag_signal    <= (others => '0');
        else
            if rising_edge(clk) then
                real_signal_dv <= dv;
                real_signal    <= signed(part_sum_real) + signed(rez_real_sum);
                imag_signal    <= signed(part_sum_imag) + signed(rez_imag_sum);
            end if;
        end if;
    end process;


end Behavioral;

