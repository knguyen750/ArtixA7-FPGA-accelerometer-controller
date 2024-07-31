library IEEE;
use IEEE.STD_LOGIC_1164.all;
use ieee.numeric_std.all;

package constants_pkg is
  constant V_SYNC_PULSE_LINES  : natural := 521;
  constant H_SYNC_PULSE_CLKS  : natural := 800;

  constant H_PULSE_CLK_START     : natural := 652;
  constant H_PULSE_CLK_END       : natural := 752;
  constant V_PULSE_LINE_START    : natural := 490;
  constant V_PULSE_LINE_END      : natural := 492;

  constant H_DISP_CLK_START     : natural := 0;
  constant H_DISP_CLK_END       : natural := 640;
  constant V_DISP_LINE_START    : natural := 0;
  constant V_DISP_LINE_END      : natural := 480;

  constant BTN_DEBOUNCE_THRESHOLD     : natural := 10000000;
  constant ACL_LOCK_WAIT     : natural := 100;

end package constants_pkg;