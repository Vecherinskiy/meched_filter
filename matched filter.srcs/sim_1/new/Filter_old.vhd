library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
USE ieee.std_logic_arith.all;

entity Filter_old is
    generic (
        N : integer := 16);
    Port (clk : in STD_LOGIC;
        reset      : in  std_logic;
        samp_dv    : in  std_logic;
        real_count : in  STD_LOGIC_VECTOR (N - 1 downto 0);
        imag_count : in  STD_LOGIC_VECTOR (N - 1 downto 0);
        out_dv     : out std_logic;
        out_real   : out STD_LOGIC_VECTOR (N - 1 downto 0);
        out_imag   : out STD_LOGIC_VECTOR (N - 1 downto 0));
end Filter_old;

architecture Behavioral of Filter_old is

    type DELAY_REAL is array (0 to N - 1) of std_logic_vector(2 * N - 1 downto 0);
    type DELAY_DATA is array (0 to 1) of std_logic_vector(2 * N - 1 downto 0);
    signal data_r, data_i : DELAY_DATA;
    signal dv             : std_logic;
    signal zero_point_five : std_logic_vector(2 * N - 1 downto 0) := (others => '0');
    -- signal partial_sum_real : DELAY_REAL := (others => (others => '0'));

    -- type DELAY_IMAG is array (0 to N - 1) of std_logic_vector(N - 1 downto 0);
    -- signal partial_sum_imag : DELAY_IMAG := (others => (others => '0'));
    signal partial_sum_real, partial_sum_imag : DELAY_REAL := (others => (others => '0'));
    type DELAY_DATA_DV is array (0 to 15) of std_logic;
    signal data_dv_reg : DELAY_DATA_DV := (others => '0');
    signal flag        : std_logic     := '0';

    type ROM is array (0 to 15) of std_logic_vector(N - 1 downto 0);
    constant real_number : ROM := (
            0  => "0000010111100011",
            1  => "0000000001001101",
            2  => "1111010111110011",
            3  => "1111111001100001",
            4  => "0000000000000000",
            5  => "1111111001100001",
            6  => "1111010111110011",
            7  => "0000000001001101",
            8  => "0000010111100011",
            9  => "1110111100001100",
            10 => "1111111001000111",
            11 => "0001001001000110",
            12 => "0000101111000111",
            13 => "0001001001000110",
            14 => "1111111001000111",
            15 => "1110111100001100");

    constant imag_number : ROM := (
            0  => "1111101000011101",
            1  => "0001000011110100",
            2  => "0000000110111001",
            3  => "1110110110111010",
            4  => "1111010000111001",
            5  => "1110110110111010",
            6  => "0000000110111001",
            7  => "0001000011110100",
            8  => "1111101000011101",
            9  => "1111111110110011",
            10 => "0000101000001101",
            11 => "0000000110011111",
            12 => "0000000000000000",
            13 => "0000000110011111",
            14 => "0000101000001101",
            15 => "1111111110110011");


    component filter_cell is
        generic(
            N : integer);
        Port (
            clk            : in  STD_LOGIC;
            reset          : in  std_logic;
            samp_dv        : in  std_logic;
            coef_real      : in  STD_LOGIC_VECTOR (N - 1 downto 0);
            coef_imag      : in  STD_LOGIC_VECTOR (N - 1 downto 0);
            real_count     : in  STD_LOGIC_VECTOR (N - 1 downto 0);
            imag_count     : in  STD_LOGIC_VECTOR (N - 1 downto 0);
            part_sum_real  : in  STD_LOGIC_VECTOR (2 * N - 1 downto 0);
            part_sum_imag  : in  STD_LOGIC_VECTOR (2 * N - 1 downto 0);
            real_signal_dv : out std_logic;
            real_signal    : out STD_LOGIC_VECTOR (2 * N - 1 downto 0);
            imag_signal    : out STD_LOGIC_VECTOR (2 * N - 1 downto 0));
    end component filter_cell;

    procedure conv_to_0_5 (signal out_real : out std_logic_vector) is
    begin
        out_real(14) <= '1';
    end procedure conv_to_0_5;

begin
    conv_to_0_5(zero_point_five);

    InstTaps : for I in 0 to (N - 1) generate
        lable : if (I = 0) generate
        begin
            Taps : filter_cell
                generic map(
                    N => N)
                port map (
                    clk            => clk,
                    reset          => reset,
                    samp_dv        => samp_dv,
                    coef_real      => real_number(N - 1),
                    coef_imag      => imag_number(N - 1),
                    real_count     => real_count,
                    imag_count     => imag_count,
                    part_sum_real  => (others => '0'),
                    part_sum_imag  => (others => '0'),
                    real_signal_dv => data_dv_reg(I),
                    real_signal    => partial_sum_real(I),
                    imag_signal    => partial_sum_imag(I));
        end generate lable;

        lable1 : if (I > 0) generate
        begin
            Taps : filter_cell
                generic map(
                    N => N)
                port map (
                    clk            => clk,
                    reset          => reset,
                    samp_dv        => samp_dv,
                    coef_real      => real_number(N - 1 - I),
                    coef_imag      => imag_number(N - 1 - I),
                    real_count     => real_count,
                    imag_count     => imag_count,
                    part_sum_real  => partial_sum_real(I-1),
                    part_sum_imag  => partial_sum_imag(I-1),
                    real_signal_dv => data_dv_reg(I),
                    real_signal    => partial_sum_real(I),
                    imag_signal    => partial_sum_imag(I));
        end generate lable1;

    end generate InstTaps;

    process (clk)
    begin
        if flag = '0' then
            dv <= '0';
        else
            if rising_edge(clk) then
                dv <= not(dv);
            end if;
        end if;
    end process;



    process (clk)
    begin
        if reset = '1' then
            flag     <= '0';
            out_dv   <= '0';
            data_r   <= (others => (others => '0'));
            data_i   <= (others => (others => '0'));
            out_real <= (others => '0');
            out_imag <= (others => '0');
        else
            if rising_edge(clk) then
                flag      <= data_dv_reg(N - 1);
                out_dv    <= dv;
                data_r(0) <= signed(partial_sum_real(N - 1)) + signed(zero_point_five);
                data_i(0) <= signed(partial_sum_imag(N - 1)) + signed(zero_point_five);
                data_r(1) <= data_r(0);
                data_i(1) <= data_i(0);
                if (signed(data_r(1)) > 0) and (unsigned(data_r(1)(N - 2 downto 0)) = 0) then
                    out_real <= signed(data_r(1)(2 * N - 2 downto 15)) - 1;
                else
                    out_real <= data_r(1)(2 * N - 2 downto 15);
                end if;
                if (signed(data_i(1)) > 0) and (unsigned(data_i(1)(N - 2 downto 0)) = 0) then
                    out_imag <= signed(data_i(1)(2 * N - 2 downto 15)) - 1;
                else
                    out_imag <= data_i(1)(2 * N - 2 downto 15);
                end if;
            end if;
        end if;
    end process;


end Behavioral;
