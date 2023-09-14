library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.std_logic_arith.all;

use work.MY_COEF.all;

entity common_multiplier is
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

end common_multiplier;

architecture Behavioral of common_multiplier is
    type DV is array (0 to 2) of std_logic;
    signal dv_regist          : DV                                                   := (others => '0');
    signal rez_mult           : std_logic_vector(WIDTH_IN + WIDTH_COEF - 1 downto 0) := (others => '0');
    signal regist_1, regist_2 : std_logic_vector(WIDTH_IN - 1 downto 0)              := (others => '0');
    signal count              : std_logic_vector (3 downto 0)                        := (others => '0');
begin

    process(clk)
    begin
        if rising_edge(clk) then
            regist_1 <= samp;
            if samp_dv = '1' then
                regist_2     <= input_coef(0);
                dv_regist(0) <= samp_dv;
                count        <= conv_std_logic_vector(1, count'length);
            else
                regist_2     <= input_coef(conv_integer(unsigned(count)));
                dv_regist(0) <= samp_dv;
                if unsigned(count) < N_X - 1 then
                    count <= unsigned(count) + 1;
                end if;
            end if;
        end if;
    end process;

    process(clk)
    begin
        if rising_edge(clk) then
            rez_mult     <= signed(regist_1) * signed(regist_2);
            dv_regist(1) <= dv_regist(0);
        end if;
    end process;

    process(clk)
    begin
        if rising_edge(clk) then
            mult    <= rez_mult;
            mult_dv <= dv_regist(1);
        end if;
    end process;

end Behavioral;
