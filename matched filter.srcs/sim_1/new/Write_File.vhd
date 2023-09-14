LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.std_logic_arith.all;
LIBRARY std;
USE std.textio.all;

ENTITY WriteFile_full IS
    generic(
        numOfBits      : integer;
        file_name_real : string;
        file_name_imag : string
    );

    port(
        clk         : in std_logic;
        dv_samp     : in std_logic;
        DataIn_real : in std_logic_vector ((numOfBits-1) downto 0);
        DataIn_imag : in std_logic_vector ((numOfBits-1) downto 0)
    );

END ENTITY WriteFile_full;

ARCHITECTURE a OF WriteFile_full IS
    constant log_file1_real : string := file_name_real;
    file file_wr_real       : TEXT open write_mode is log_file1_real;

    constant log_file1_imag : string := file_name_imag;
    file file_wr_imag       : TEXT open write_mode is log_file1_imag;

BEGIN
    write_data_real : process(clk)
        variable l2 : line;
    begin
        if(rising_edge(clk)) then
            if dv_samp = '1' then
                write (l2, CONV_INTEGER(SIGNED(DataIn_real)));
                writeline(file_wr_real, l2);
            end if;
        end if;
    end process write_data_real;

    write_data_imag : process(clk)
        variable l2 : line;
    begin
        if(rising_edge(clk)) then
            if dv_samp = '1' then
                write (l2, CONV_INTEGER(SIGNED(DataIn_imag)));
                writeline(file_wr_imag, l2);
            end if;
        end if;
    end process write_data_imag;

END ARCHITECTURE a;