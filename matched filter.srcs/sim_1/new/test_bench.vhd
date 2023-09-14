library ieee;
use ieee.std_logic_1164.all; -- standard unresolved logic UX01ZWLH-
use ieee.numeric_std.all;    -- for the signed, unsigned types and arithmetic ops
use work.MY_COEF.all;

LIBRARY std;
USE std.textio.all;

Library UNISIM;
use UNISIM.vcomponents.all;

Library UNIMACRO;
use UNIMACRO.vcomponents.all;

entity test_bench is
--  Port ( );
end test_bench;

architecture Behavioral of test_bench is
    constant INPUT_PERIOD : time    := 10 ns;
    constant N            : integer := 16;
    constant WIDTH_RAM    : natural := 16;
    constant DAPTH_RAM    : natural := 10;

    constant file_r1_real : string := "D:\learning_fpga\project_1\data_real.txt";
    constant file_r1_imag : string := "D:\learning_fpga\project_1\data_imag.txt";

    constant file_r2_real : string := "D:\learning_fpga\project_1\data_real_2.txt";
    constant file_r2_imag : string := "D:\learning_fpga\project_1\data_imag_2.txt";

    constant file_name_real : string := "D:\learning_fpga\project_1\data_from_fpga_real.txt";
    constant file_name_imag : string := "D:\learning_fpga\project_1\data_from_fpga_imag.txt";

    constant file_name_real_old : string := "D:\learning_fpga\project_1\data_from_fpga_real_old.txt";
    constant file_name_imag_old : string := "D:\learning_fpga\project_1\data_from_fpga_imag_old.txt";

    constant N_X   : natural := 4;
    signal case_id : natural := 2;

    signal r_perm            : std_logic;
    signal clk               : std_logic;
    signal samp_dv           : std_logic;
    signal out_dv            : std_logic                         := '0';
    signal samp_real         : std_logic_vector (N - 1 downto 0) := (others => '0');
    signal samp_imag         : std_logic_vector (N - 1 downto 0) := (others => '0');
    signal out_data_dv       : std_logic                         := '0';
    signal out_data_real     : std_logic_vector (N - 1 downto 0) := (others => '0');
    signal out_data_imag     : std_logic_vector (N - 1 downto 0) := (others => '0');
    signal reset             : std_logic;
    signal out_data_real_old : std_logic_vector (N - 1 downto 0) := (others => '0');
    signal out_data_imag_old : std_logic_vector (N - 1 downto 0) := (others => '0');
    signal samp_old_dv       : std_logic;
    signal data_dv, data_dv_reg           : std_logic                        := '0';
    signal data_real         : std_logic_vector(N - 1 downto 0) := (others => '0');
    signal data_real_old     : std_logic_vector(N - 1 downto 0) := (others => '0');
    signal data_imag         : std_logic_vector(N - 1 downto 0) := (others => '0');
    signal data_imag_old     : std_logic_vector(N - 1 downto 0) := (others => '0');

    signal empty1, empty2  : std_logic                            := '1';
    signal din_fifo_dv     : std_logic                            := '0';
    signal din_fifo_old_dv : std_logic                            := '0';
    signal din_fifo        : std_logic_vector(2 * N - 1 downto 0) := (others => '0');
    signal din_fifo_old    : std_logic_vector(2 * N - 1 downto 0) := (others => '0');
    signal dout_fifo       : std_logic_vector(2 * N - 1 downto 0) := (others => '0');
    signal dout_fifo_old   : std_logic_vector(2 * N - 1 downto 0) := (others => '0');

    signal RDEN : std_logic := '0';

    procedure wait_clk ( takt : natural := 1
        ) is
    begin
        m1 : for i in 0 to takt - 1 loop
            wait until clk'event and clk = '1';
        end loop m1;
    end procedure wait_clk;

    procedure set_cs ( real_val : in integer; imag_val : in integer;
            signal out_real : out std_logic_vector;
            signal out_imag : out std_logic_vector
        ) is
    begin
        out_real <= std_logic_vector(to_signed(real_val, WIDTH_IN));
        out_imag <= std_logic_vector(to_signed(imag_val, WIDTH_IN));
    end procedure set_cs;

    component ReadFile is
        generic(
            numOfBits : integer);
        port(
            data_real : out std_logic_vector ((numOfBits-1) downto 0);
            dv_samp   : out std_logic;
            data_imag : out std_logic_vector ((numOfBits-1) downto 0);
            rst       : in  std_logic;
            rfd       : in  std_logic;
            clk       : in  std_logic
        );

    end component ReadFile;

    component Filter is
        generic (
            N_X        : natural ;
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

    end component Filter;

    component Filter_old is
        generic (
            N : integer := 16
        );

        Port ( clk : in STD_LOGIC;
            reset      : in  std_logic;
            samp_dv    : in  std_logic;
            real_count : in  STD_LOGIC_VECTOR (N - 1 downto 0);
            imag_count : in  STD_LOGIC_VECTOR (N - 1 downto 0);
            out_dv     : out std_logic;
            out_real   : out STD_LOGIC_VECTOR (N - 1 downto 0);
            out_imag   : out STD_LOGIC_VECTOR (N - 1 downto 0)
        );

    end component Filter_old;

    component WriteFile_full is
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

    end component WriteFile_full;

    component fifo is
        generic (
            WIDTH_RAM : natural;
            DAPTH_RAM : natural
        );
        port (
            clk         : in  std_logic;
            reset       : in  std_logic;
            samp_dv     : in  std_logic;
            samp        : in  std_logic_vector(WIDTH_RAM - 1 downto 0);
            samp_old_dv : in  std_logic;
            samp_old    : in  std_logic_vector(WIDTH_RAM - 1 downto 0);
            data_dv     : out std_logic;
            data        : out std_logic_vector(WIDTH_RAM - 1 downto 0);
            data_old    : out std_logic_vector(WIDTH_RAM - 1 downto 0)
        );
    end component fifo;

begin

    generate_clk : process
    begin
        clk <= '0';
        wait for INPUT_PERIOD;
        loop
            clk <= '1';
            wait for INPUT_PERIOD/2;
            clk <= '0';
            wait for INPUT_PERIOD/2;
        end loop;
    end process generate_clk;

    generate_reset : process
    begin
        if case_id = 5 then
            reset <= '1';
            wait_clk(50);
            reset <= '0';
            wait_clk(1000);
            reset <= '1';
            wait_clk(10);
            loop
                reset <= '0';
                wait_clk;
            end loop;
        else
            reset <= '1';
            wait_clk(12);
            loop
                reset <= '0';
                wait_clk;
            end loop;
        end if;
    end process generate_reset;

    generate_r_perm : process
    begin
        if case_id = 2 then
            loop
                for i in N_X to N_X * 3 loop
                    r_perm <= '1';
                    wait_clk;
                    r_perm <= '0';
                    wait_clk(i - 1);
                end loop;
            end loop;
        else
            loop
                r_perm <= '1';
                wait_clk;
                r_perm <= '0';
                wait_clk(N_X - 1);
            end loop;
        end if;

    end process generate_r_perm;

    process(clk, out_dv)
    begin
        if out_dv'event then
            samp_old_dv <= '1';
        else
            if rising_edge(clk) then
                samp_old_dv <= '0';
            end if;
        end if;
    end process;


    --                generate_samp : process
    --                begin
    --                    case case_id is
    --                        when 1 =>
    --                            samp_dv   <= '0';
    --                            samp_real <= "0000000000000000";
    --                            samp_imag <= "0000000000000000";
    --                            wait_clk(5);
    --                            loop
    --                                samp_dv <= '1';
    --                                set_cs(1000, -2000, samp_real, samp_imag);
    --                                wait_clk;
    --                                samp_dv <= '0';
    --                                set_cs(1000, -2000, samp_real, samp_imag);
    --                                wait_clk(N_X - 1) ;
    --                                samp_dv <= '1';
    --                                set_cs(6, -5, samp_real, samp_imag);
    --                                wait_clk;
    --                                samp_dv <= '0';
    --                                set_cs(6, -5, samp_real, samp_imag);
    --                                wait_clk(N_X - 1);
    --                                samp_dv <= '1';
    --                                set_cs(520, -571, samp_real, samp_imag);
    --                                wait_clk;
    --                                samp_dv <= '0';
    --                                set_cs(520, -571, samp_real, samp_imag);
    --                                wait_clk(N_X - 1);
    --                                samp_dv <= '1';
    --                                set_cs(78, -56, samp_real, samp_imag);
    --                                wait_clk;
    --                                samp_dv <= '0';
    --                                set_cs(78, -56, samp_real, samp_imag);
    --                                wait_clk(N_X - 1);
    --                            end loop;

    --                        when others =>
    --                            samp_dv   <= '0';
    --                            samp_real <= "0000000000000000";
    --                            samp_imag <= "0000000000000000";
    --                            wait_clk(2);
    --                    end case;
    --                end process generate_samp;

    READ : ReadFile
        generic map (
            numOfBits => N
        )

        port map (
            clk       => clk,
            rst       => reset,
            rfd       => r_perm,
            dv_samp   => samp_dv,
            data_real => samp_real,
            data_imag => samp_imag
        );

    FILTERING : Filter
        generic map (
            N_X    => N_X,
            N_COEF => 16
        )
        port map (
            clk           => clk,
            reset         => reset,
            samp_dv       => samp_dv,
            samp_real     => samp_real,
            samp_imag     => samp_imag,
            out_data_dv   => out_data_dv,
            out_data_real => out_data_real,
            out_data_imag => out_data_imag
        );

    FILTERING_OLD : Filter_old
        port map (
            clk        => samp_dv,
            reset      => reset,
            samp_dv    => samp_dv,
            real_count => samp_real,
            imag_count => samp_imag,
            out_dv     => out_dv,
            out_real   => out_data_real_old,
            out_imag   => out_data_imag_old
        );

    --    ALIGM_REAL : fifo
    --        generic map (
    --            WIDTH_RAM => WIDTH_RAM,
    --            DAPTH_RAM => DAPTH_RAM
    --        )
    --        port map (
    --            clk         => clk,
    --            reset       => reset,
    --            samp_dv     => out_data_dv,
    --            samp        => out_data_real,
    --            samp_old_dv => samp_old_dv,
    --            samp_old    => out_data_real_old,
    --            data_dv     => data_dv,
    --            data        => data_real,
    --            data_old    => data_real_old
    --        );

    --    ALIGM_IMAG : fifo
    --        generic map (
    --            WIDTH_RAM => WIDTH_RAM,
    --            DAPTH_RAM => DAPTH_RAM
    --        )
    --        port map (
    --            clk         => clk,
    --            reset       => reset,
    --            samp_dv     => out_data_dv,
    --            samp        => out_data_imag,
    --            samp_old_dv => samp_old_dv,
    --            samp_old    => out_data_imag_old,
    --            data        => data_imag,
    --            data_old    => data_imag_old
    --        );

    process(clk)
    begin
        if reset = '1' then
            din_fifo_dv                      <= '0';
            din_fifo_old_dv                  <= '0';
            din_fifo     <= (others => '0');
            din_fifo_old <= (others => '0');
        else
            if rising_edge(clk) then
                din_fifo_dv                      <= out_data_dv;
                din_fifo_old_dv                  <= samp_old_dv;
                din_fifo(2 * N - 1 downto N)     <= out_data_real;
                din_fifo(N - 1 downto 0)         <= out_data_imag;
                din_fifo_old(2 * N - 1 downto N) <= out_data_real_old;
                din_fifo_old(N - 1 downto 0)     <= out_data_imag_old;
            end if;
        end if;
    end process;

    FIFO_SYNC_MACRO_inst : FIFO_SYNC_MACRO
        generic map (
            DEVICE              => "7SERIES", -- Target Device: "VIRTEX5, "VIRTEX6", "7SERIES"
            ALMOST_FULL_OFFSET  => X"0080",   -- Sets almost full threshold
            ALMOST_EMPTY_OFFSET => X"0080",   -- Sets the almost empty threshold
            DATA_WIDTH          => 2 * N,     -- Valid values are 1-72 (37-72 only valid when FIFO_SIZE="36Kb")
            FIFO_SIZE           => "18Kb")    -- Target BRAM, "18Kb" or "36Kb"
        port map (
            DO    => dout_fifo,
            EMPTY => empty1,     -- Output data, width defined by DATA_WIDTH parameter
            CLK   => clk,        -- 1-bit input clock
            DI    => din_fifo,   -- Input data, width defined by DATA_WIDTH parameter
            RDEN  => RDEN,       -- 1-bit input read enable
            RST   => reset,      -- 1-bit input reset
            WREN  => din_fifo_dv -- 1-bit input write enable
        );

    FIFO_SYNC_MACRO_inst_old : FIFO_SYNC_MACRO
        generic map (
            DEVICE              => "7SERIES", -- Target Device: "VIRTEX5, "VIRTEX6", "7SERIES"
            ALMOST_FULL_OFFSET  => X"0080",   -- Sets almost full threshold
            ALMOST_EMPTY_OFFSET => X"0080",   -- Sets the almost empty threshold
            DATA_WIDTH          => 2 * N,     -- Valid values are 1-72 (37-72 only valid when FIFO_SIZE="36Kb")
            FIFO_SIZE           => "18Kb")    -- Target BRAM, "18Kb" or "36Kb"
        port map (
            DO    => dout_fifo_old,
            EMPTY => empty2,         -- Output data, width defined by DATA_WIDTH parameter
            CLK   => clk,            -- 1-bit input clock
            DI    => din_fifo_old,   -- Input data, width defined by DATA_WIDTH parameter
            RDEN  => RDEN,           -- 1-bit input read enable
            RST   => reset,          -- 1-bit input reset
            WREN  => din_fifo_old_dv -- 1-bit input write enable
        );

    process(clk)
    begin
            RDEN <= not(empty1) and not(empty2);
    end process;

    process(clk)
    begin
        if rising_edge(clk) then
            data_real     <= dout_fifo(2 * N - 1 downto N);
            data_imag     <= dout_fifo(N - 1 downto 0);
            data_real_old <= dout_fifo_old(2 * N - 1 downto N);
            data_imag_old <= dout_fifo_old(N - 1 downto 0);
        end if;
    end process;

    process(clk)
    begin
        if rising_edge(clk) then
            data_dv_reg <= RDEN;
            data_dv <= data_dv_reg;
            if (data_dv = '1') and (data_real /= data_real_old) then
                report "Error" severity error;
            end if;
            if (data_dv = '1') and (data_imag /= data_imag_old) then
                report "Error" severity error;
            end if;
        end if; 
    end process;

    --    WRITE_FILTERING : WriteFile_full
    --        generic map (
    --            numOfBits      => N,
    --            file_name_real => file_name_real,
    --            file_name_imag => file_name_imag
    --        )
    --        port map (
    --            clk         => clk,
    --            dv_samp     => data_dv,
    --            DataIn_real => data_real,
    --            DataIn_imag => data_imag);

    --    WRITE_FILTERING_OLD : WriteFile_full
    --        generic map (
    --            numOfBits      => N,
    --            file_name_real => file_name_real_old,
    --            file_name_imag => file_name_imag_old
    --        )
    --        port map (
    --            clk         => clk,
    --            dv_samp     => data_dv,
    --            DataIn_real => data_real_old,
    --            DataIn_imag => data_imag_old);

end Behavioral;
