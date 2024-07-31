----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 07/22/2024 05:13:20 PM
-- Design Name: 
-- Module Name: lab7_top - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;
use work.constants_pkg.all;
use work.types_pkg.all;
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity lab7_top is
Port ( 
    CLK100MHZ : in STD_LOGIC;
    -- Reset
    SW  : in std_logic_vector(15 downto 0);
    BTNU    : in std_logic;
    BTNL    : in std_logic;
    BTNR    : in std_logic;
    BTND    : in std_logic;
    -- VGA Signals  
    VGA_R  : out std_logic_vector (3 downto 0); 
    VGA_G  : out std_logic_vector (3 downto 0); 
    VGA_B  : out std_logic_vector (3 downto 0); 
    VGA_HS : out std_logic; 
    VGA_VS : out std_logic; 
    --Seg7 Display Signals
    SEG7_CATH   : out STD_LOGIC_VECTOR (7 downto 0);
    AN          : out STD_LOGIC_VECTOR (7 downto 0);
    --SPI Signals between FPGA and accelerometer
    CSb : out STD_LOGIC;
    MOSI : out STD_LOGIC;
    SCLK : out STD_LOGIC;
    MISO : in STD_LOGIC
);
end lab7_top;

architecture Behavioral of lab7_top is

    COMPONENT vio_0
      PORT (
        clk : IN STD_LOGIC;
        probe_in0 : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
        probe_out0 : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
        probe_out1 : OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
        probe_out2 : OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
        probe_out3 : OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
        probe_out4 : OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
        probe_out5 : OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
        probe_out6 : OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
        probe_out7 : OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
        probe_out8 : OUT STD_LOGIC_VECTOR(0 DOWNTO 0) 
      );
    END COMPONENT;

    component accel_spi_rw is
        port
        (
            clk   : in std_logic;
            reset : in std_logic;
            --Values from accelerometer used for movement and display
            DATA_X : out std_logic_vector(7 downto 0);
            DATA_Y : out std_logic_vector(7 downto 0);
            DATA_Z : out std_logic_vector(7 downto 0);
            ID_AD  : out std_logic_vector(7 downto 0);
            ID_1D  : out std_logic_vector(7 downto 0);
            --SPI Signals between FPGA and accelerometer
            CSb  : out std_logic;
            MOSI : out std_logic;
            SCLK : out std_logic;
            MISO : in std_logic);
    end component;

    component pulse_gen is
        generic (
            CLK_DIV : natural := 1000000
        );
        port ( 
            clk             : in std_logic;
            rst             : in std_logic;
            pulse_out       : out std_logic
        );
    end component;

    component vga_controller is 
        port 
        (
            rst   : in std_logic;
            clk   : in std_logic;
            en25 : in std_logic;
            sw1  :  in std_logic;
            btnu  : in std_logic;
            btnd  : in std_logic;
            btnl  : in std_logic;
            btnr  : in std_logic;
            data_x : in std_logic_vector(7 downto 0);
            data_y : in std_logic_vector(7 downto 0);
            -- Red Square XY Coordinates
            seg7_xy : out t_vect4_arry8;
            -- VGA Signals  
            vga_r  : out std_logic_vector (3 downto 0);
            vga_g  : out std_logic_vector (3 downto 0);
            vga_b  : out std_logic_vector (3 downto 0);
            vga_hs : out std_logic;
            vga_vs : out std_logic
        );
    end component;

    component seg7_controller is 
        port 
        (
            clk         : in STD_LOGIC;
            rst         : in STD_LOGIC;
            an_en       : in std_logic;
            char_arry8  : in t_vect4_arry8;
            ca_out      : out STD_LOGIC_VECTOR (7 downto 0);
            an_out      : out STD_LOGIC_VECTOR (7 downto 0)
        );
    end component;

    signal rst           : std_logic;
    signal char_arr8     : t_vect4_arry8; -- 8-deep array of 4-bit characters
    signal pulse_25mhz   : std_logic;     -- 25Hz pulse enable signal
    signal pulse_1khz    : std_logic;     -- 1KHz pulse enable signal for anode counter
    signal seg7_xy      : t_vect4_arry8;
    signal data_x       : std_logic_vector(7 downto 0);
    signal data_y       : std_logic_vector(7 downto 0);
    signal data_z       : std_logic_vector(7 downto 0);
    signal id_ad       : std_logic_vector(7 downto 0);
    signal id_1d       : std_logic_vector(7 downto 0);
    signal probe_in0 : STD_LOGIC_VECTOR(7 DOWNTO 0);
    signal probe_out0 : STD_LOGIC_VECTOR(0 DOWNTO 0);
    signal probe_out1 : STD_LOGIC_VECTOR(0 DOWNTO 0);
    signal probe_out2 : STD_LOGIC_VECTOR(0 DOWNTO 0);
    signal probe_out3 : STD_LOGIC_VECTOR(0 DOWNTO 0);
    signal probe_out4 : STD_LOGIC_VECTOR(0 DOWNTO 0);
    signal probe_out5 : STD_LOGIC_VECTOR(0 DOWNTO 0);
    signal probe_out6 : STD_LOGIC_VECTOR(0 DOWNTO 0);
    signal probe_out7 : STD_LOGIC_VECTOR(0 DOWNTO 0);
    signal probe_out8 : STD_LOGIC_VECTOR(0 DOWNTO 0);
    signal switch : std_logic_vector(15 downto 0);
    signal anode : std_logic_vector(7 downto 0);
begin
   -- Signal Assignments
        -- Reset 
        rst <= switch(0) or SW(15);
        anode <= AN;

        -- 7-Seg Display Character MUX
        char_arr8(7) <= id_1d(7 downto 4) when SW(4 downto 3) = "00" else x"0";

        char_arr8(6) <= id_1d(3 downto 0) when SW(4 downto 3) = "00" else x"0";

        char_arr8(5) <= id_ad(7 downto 4) when SW(4 downto 3) = "00" else 
                        data_x(7 downto 4) when SW(4 downto 3) = "01" else 
                        data_y(7 downto 4) when SW(4 downto 3) = "10" else
                        data_z(7 downto 4) when SW(4 downto 3) = "11";

        char_arr8(4) <= id_ad(3 downto 0) when SW(4 downto 3) = "00" else 
            data_x(3 downto 0) when SW(4 downto 3) = "01" else 
            data_y(3 downto 0) when SW(4 downto 3) = "10" else
            data_z(3 downto 0) when SW(4 downto 3) = "11";

        char_arr8(3 downto 0) <= seg7_xy(3 downto 0);
    
        -- Pulse Generator 1KHz
        u_pulse_1khz_gen : pulse_gen
        generic map (
            CLK_DIV => 100000
        )
        port map (
            clk       => CLK100MHZ,
            rst       => rst,
            pulse_out => pulse_1khz
        );

        -- Pulse Generator 25MHz
        u_pulse_25mhz_gen : pulse_gen
        generic map (
            CLK_DIV => 3
        )
        port map (
            clk       => CLK100MHZ,
            rst       => rst,
            pulse_out => pulse_25mhz
        );

        -- 7 Segment Display Controller
        u_vga_ctrl : vga_controller
        port map 
        (
            rst     => rst  ,  
            clk     => CLK100MHZ,    
            en25    => pulse_25mhz,
            sw1     => SW(1),
            btnu    => BTNU ,  
            btnd    => BTND ,  
            btnl    => BTNL ,  
            btnr    => BTNR , 
            data_x  => data_x,
            data_y  => data_y, 
            seg7_xy => seg7_xy,
            vga_r   => VGA_R  ,
            vga_g   => VGA_G  ,
            vga_b   => VGA_B  ,
            vga_hs  => VGA_HS ,
            vga_vs  => VGA_VS 
        );
        
        -- 7 Segment Display Controller
        u_seg7_ctrl : seg7_controller
        port map 
        (
            clk         => CLK100MHZ,
            rst         => rst,
            an_en       => pulse_1khz,
            char_arry8  => char_arr8,
            ca_out      => SEG7_CATH,
            an_out      => AN
        );

    u_accel_spi_rw : accel_spi_rw
        port map
        (
            clk     => CLK100MHZ   ,
            reset   => rst ,
            DATA_X  => data_x,
            DATA_Y  => data_y,
            DATA_Z  => data_z,
            ID_AD   => id_ad ,
            ID_1D   => id_1d ,
            CSb     => CSb   ,
            MOSI    => MOSI  ,
            SCLK    => SCLK  ,
            MISO    => MISO  
        );

        u_vio_0 : vio_0
        PORT MAP (
          clk => CLK100MHZ,
          probe_in0  => anode,
          probe_out0 => switch,
          probe_out1 => probe_out1,
          probe_out2 => probe_out2,
          probe_out3 => probe_out3,
          probe_out4 => probe_out4,
          probe_out5 => probe_out5,
          probe_out6 => probe_out6,
          probe_out7 => probe_out7,
          probe_out8 => probe_out8
        );


end Behavioral;
