LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.std_logic_arith.all;
LIBRARY std;
USE std.textio.all;

ENTITY ReadFile IS
    generic(
        numOfBits      : integer;
        file_name_rael : string := "D:\learning_fpga\project_1\data_real.txt";
        file_name_imag : string := "D:\learning_fpga\project_1\data_imag.txt");
    port(
        data_real : out std_logic_vector ((numOfBits-1) downto 0);
        dv_samp   : out std_logic;
        data_imag : out std_logic_vector ((numOfBits-1) downto 0);
        rst       : in  std_logic;
        rfd       : in  std_logic;
        clk       : in  std_logic);
END ENTITY ReadFile;

ARCHITECTURE a OF ReadFile IS
    constant log_file_rd_real : string := file_name_rael;
    file file_rd_real         : TEXT open read_mode is log_file_rd_real;

    constant log_file_rd_imag : string := file_name_imag;
    file file_rd_imag         : TEXT open read_mode is log_file_rd_imag;

BEGIN
    read_data_real : process(clk,rst)
        variable s_real : integer;
        variable l_real : line;
    begin
        if (rst = '1') then
            data_real <= (others => '0');
            dv_samp   <= '0';
        elsif(rising_edge(clk)) then
            if rfd = '1' then
                readline(file_rd_real, l_real);
                read (l_real, s_real);
                data_real <= CONV_STD_LOGIC_VECTOR(s_real,numOfBits);
                dv_samp   <= '1';
            else
                dv_samp <= '0';
            end if;
        end if;
    end process read_data_real;

    read_data_imag : process(clk,rst)
        variable s_imag : integer;
        variable l_imag : line;
    begin
        if (rst = '1') then
            data_imag <= (others => '0');
        elsif(rising_edge(clk)) then
            if rfd = '1' then
                readline(file_rd_imag, l_imag);
                read (l_imag, s_imag);
                data_imag <= CONV_STD_LOGIC_VECTOR(s_imag,numOfBits);
            end if;
        end if;
    end process read_data_imag;

END ARCHITECTURE a;
