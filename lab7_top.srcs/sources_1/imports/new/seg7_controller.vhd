----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 06/09/2024 11:36:51 PM
-- Design Name: 
-- Module Name: seg7_controller - Behavioral
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
--use IEEE.STD_LOGIC_UNSIGNED.ALL;
use work.types_pkg.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity seg7_controller is
    Port (  clk         : in STD_LOGIC;
            rst         : in STD_LOGIC;
            an_en       : in std_logic;
            char_arry8  : in t_vect4_arry8;
            ca_out      : out STD_LOGIC_VECTOR (7 downto 0);
            an_out      : out STD_LOGIC_VECTOR (7 downto 0)
        );
end seg7_controller;

architecture Behavioral of seg7_controller is

    component seg7_hex is
        Port (  digit : in STD_LOGIC_VECTOR (3 downto 0);
                seg7  : out STD_LOGIC_VECTOR (7 downto 0)
         );
    end component;

    signal char_dcd         : std_logic_vector(3 downto 0);
    signal count_anode_d    : unsigned(20 downto 0);
    signal count_anode_q    : unsigned(20 downto 0);
    signal an_shift_reg_d   : std_logic_vector(7 downto 0);
    signal an_shift_reg_q   : std_logic_vector(7 downto 0);
    signal static_val_out_d : t_vect4_arry8;

begin

    -- Set Anode Outputs
    an_out <= an_shift_reg_q;

    -- Clock process for D to Q
    s_clk : process (clk, rst)
    begin
        if (rst = '1') then
            count_anode_q   <= (others => '0');
            --an_shift_reg_q  <= (0 => '0', others => '1');
            an_shift_reg_q  <= (others => '0');
        elsif rising_edge(clk) then
            count_anode_q   <= count_anode_d;
            an_shift_reg_q  <= an_shift_reg_d;
        end if;
    end process;

    -- Anode Shift Register
    c_anode_pos : process (count_anode_q, an_shift_reg_q, an_en) is
    begin
        an_shift_reg_d  <= an_shift_reg_q;
        count_anode_d   <= count_anode_q;
        if (an_en = '1') then
            if (count_anode_q = 7) then
                count_anode_d <= (others => '0');
                an_shift_reg_d  <= (0 => '0', others => '1');
            else
                count_anode_d <= count_anode_q + "1";
                an_shift_reg_d  <= an_shift_reg_q(6 downto 0) & "1";
            end if;
        end if;
    end process;

    -- Character Selection MUX
    c_char_sel : process (rst, char_arry8, count_anode_q) is
    begin
        char_dcd <= "0000" when rst = '1' else char_arry8(to_integer(count_anode_q));
    end process;
    
    -- 7 Segment Decoder 
    -- Outputs to cathode lines
    u_seg7_hex : seg7_hex
    PORT MAP (
        digit   => char_dcd,
        seg7    => ca_out
    );

end Behavioral;
