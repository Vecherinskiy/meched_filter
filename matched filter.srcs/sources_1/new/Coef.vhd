library ieee;
use ieee.std_logic_1164.all;

package MY_COEF is

    constant N          : natural := 32;
    constant WIDTH_IN   : natural := 16;
    constant WIDTH_OUT  : natural := 16;
    constant WIDTH_COEF : natural := 16;
    constant N_COEF     : natural := 16;
    constant N_X        : natural := 4;



    type ROM is array (0 to 15) of std_logic_vector(WIDTH_COEF - 1 downto 0);
    constant real_coef : ROM := (
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

    constant imag_coef : ROM := (
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

--    type ROM is array (0 to 15) of std_logic_vector(WIDTH_COEF - 1 downto 0);
--    constant real_coef : ROM := (
--            0  => "0100000000000000",
--            1  => "1100000000000000",
--            2  => "0100000000000000",
--            3  => "1100000000000000",
--            4  => "0100000000000000",
--            5  => "1100000000000000",
--            6  => "0100000000000000",
--            7  => "1100000000000000",
--            8  => "0100000000000000",
--            9  => "1100000000000000",
--            10 => "0100000000000000",
--            11 => "1100000000000000",
--            12 => "0100000000000000",
--            13 => "1100000000000000",
--            14 => "0100000000000000",
--            15 => "1100000000000000");
--
--    constant imag_coef : ROM := (
--            0  => "0000000000000000",
--            1  => "0000000000000000",
--            2  => "0000000000000000",
--            3  => "0000000000000000",
--            4  => "0000000000000000",
--            5  => "0000000000000000",
--            6  => "0000000000000000",
--            7  => "0000000000000000",
--            8  => "0000000000000000",
--            9  => "0000000000000000",
--            10 => "0000000000000000",
--            11 => "0000000000000000",
--            12 => "0000000000000000",
--            13 => "0000000000000000",
--            14 => "0000000000000000",
--            15 => "0000000000000000");

    type complex_num is record
        num_real : std_logic_vector (N - 1 downto 0);
        num_imag : std_logic_vector (N - 1 downto 0);
    end record complex_num;

    type complex_num_in is record
        num_real : std_logic_vector (WIDTH_IN - 1 downto 0);
        num_imag : std_logic_vector (WIDTH_IN - 1 downto 0);
    end record complex_num_in;

    constant zeros_complex : complex_num := (
            num_real => (others => '0'),
            num_imag => (others => '0')
        );

    type COEF_X is array (0 to N_X - 1) of std_logic_vector (WIDTH_COEF - 1 downto 0);
    type COEF_X_COMPLEX is array (0 to N_X - 1) of complex_num_in;
    type ROM_COMPLEX_COEF is array (0 to N_COEF - 1) of complex_num_in;
    type ARRAY_COEF_X is array (0 to N_COEF / N_X - 1) of COEF_X_COMPLEX;

    procedure assemb_complex_coeff(constant real_coef : in ROM;
            constant imag_coef      : in  ROM;
            signal arr_complex_coef : out ROM_COMPLEX_COEF);

    procedure assemb_complex_num(signal real_num : in std_logic_vector;
            signal imag_num    : in  std_logic_vector;
            signal complex_num : out complex_num_in);


    procedure assemb_coeff_x(signal arr_complex_coef : in ROM_COMPLEX_COEF;
            signal arr_coef_x : out ARRAY_COEF_X);

    procedure Assign_coeff(signal input_coef : in COEF_X_COMPLEX;
            signal coefs_real : out COEF_X;
            signal coefs_imag : out COEF_X);

end package MY_COEF;

package body MY_COEF is

    procedure assemb_complex_num(signal real_num : in std_logic_vector;
            signal imag_num    : in  std_logic_vector;
            signal complex_num : out complex_num_in) is
    begin
        complex_num.num_real <= real_num;
        complex_num.num_imag <= imag_num;
    end procedure;

    procedure assemb_complex_coeff(constant real_coef : in ROM;
            constant imag_coef      : in  ROM;
            signal arr_complex_coef : out ROM_COMPLEX_COEF) is
    begin
        for i in 0 to N_COEF - 1 loop
            arr_complex_coef(i).num_real <= real_coef(i);
            arr_complex_coef(i).num_imag <= imag_coef(i);
        end loop;
    end procedure;

    procedure assemb_coeff_x(signal arr_complex_coef : in ROM_COMPLEX_COEF;
            signal arr_coef_x : out ARRAY_COEF_X) is
        variable temp : COEF_X_COMPLEX;
    begin
        for i in 0 to N_COEF / N_X - 1 loop
            for j in 0 to N_X - 1 loop
                temp(j) := arr_complex_coef(N_X * i + N_X - 1 - j);
            end loop;
            arr_coef_x(i) <= temp;
        end loop;
    end procedure;

    procedure Assign_coeff(signal input_coef : in COEF_X_COMPLEX;
            signal coefs_real : out COEF_X;
            signal coefs_imag : out COEF_X) is
    begin
        for i in 0 to N_X - 1 loop
            coefs_real(i) <= input_coef(i).num_real;
            coefs_imag(i) <= input_coef(i).num_imag;
        end loop;
    end procedure;

end package body MY_COEF;
