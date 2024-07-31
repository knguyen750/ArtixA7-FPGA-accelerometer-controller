----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 06/10/2024 12:57:26 AM
-- Design Name: 
-- Module Name: pulse_gen - Behavioral
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
use IEEE.NUMERIC_STD.ALL;
--use IEEE.STD_LOGIC_UNSIGNED.ALL;
use work.types_pkg.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity pulse_gen is
    generic (
        CLK_DIV : natural := 100000000 -- pulse freq. = clk freq. / CLK_DIV+1
      );
    port ( 
        clk             : in std_logic;
        rst             : in std_logic;
        pulse_out       : out std_logic
    );
end pulse_gen;

architecture Behavioral of pulse_gen is

    signal count_d : unsigned(26 downto 0);
    signal count_q : unsigned(26 downto 0);

begin

    -- Clock process for D to Q
    s_clk : process (clk, rst)
    begin
      if (rst = '1') then
        count_q <= (others => '0');
      elsif rising_edge(clk) then
        count_q <= count_d;
      end if;
    end process;

    -- Counts to CLK_DIV then outputs
    s_pulse_gen : process (count_q) is
    begin
        pulse_out <= '0';
        count_d <= count_q + "1";
        if (count_q >= CLK_DIV) then
            pulse_out <= '1';
            count_d   <= (others => '0');
        end if;
    end process;

end Behavioral;
