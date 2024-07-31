----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 07/05/2024 09:30:29 PM
-- Design Name: 
-- Module Name: vga_controller - Behavioral
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
use IEEE.STD_LOGIC_1164.all;
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.all;
use work.constants_pkg.all;
use work.types_pkg.all;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity vga_controller is
    port
    (
        rst    : in std_logic;
        clk    : in std_logic;
        en25   : in std_logic;
        sw1    : in std_logic;
        btnu   : in std_logic;
        btnd   : in std_logic;
        btnl   : in std_logic;
        btnr   : in std_logic;
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
end vga_controller;

architecture Behavioral of vga_controller is

    signal h_count_d : unsigned(9 downto 0);
    signal h_count_q : unsigned(9 downto 0);
    signal v_count_d : unsigned(9 downto 0);
    signal v_count_q : unsigned(9 downto 0);

    signal h_sync : std_logic;
    signal v_sync : std_logic;

    signal vga_r_t : std_logic_vector(3 downto 0);
    signal vga_g_t : std_logic_vector(3 downto 0);
    signal vga_b_t : std_logic_vector(3 downto 0);

    signal red_sqr_x_d  : unsigned(4 downto 0);
    signal red_sqr_x_q  : unsigned(4 downto 0);
    signal red_sqr_y_d  : unsigned(4 downto 0);
    signal red_sqr_y_q  : unsigned(4 downto 0);
    signal red_sqr_xy_d : t_vect4_arry8;
    signal red_sqr_xy_q : t_vect4_arry8;

    signal btnu_db     : std_logic;
    signal btnd_db     : std_logic;
    signal btnl_db     : std_logic;
    signal btnr_db     : std_logic;
    signal btnu_1_d    : std_logic;
    signal btnd_1_d    : std_logic;
    signal btnl_1_d    : std_logic;
    signal btnr_1_d    : std_logic;
    signal btnu_1_q    : std_logic;
    signal btnd_1_q    : std_logic;
    signal btnl_1_q    : std_logic;
    signal btnr_1_q    : std_logic;
    signal btnu_2_d    : std_logic;
    signal btnd_2_d    : std_logic;
    signal btnl_2_d    : std_logic;
    signal btnr_2_d    : std_logic;
    signal btnu_2_q    : std_logic;
    signal btnd_2_q    : std_logic;
    signal btnl_2_q    : std_logic;
    signal btnr_2_q    : std_logic;
    signal btn_count_d : unsigned(31 downto 0);
    signal btn_count_q : unsigned(31 downto 0);

    signal acl_u_thr   : std_logic;
    signal acl_d_thr   : std_logic;
    signal acl_l_thr   : std_logic;
    signal acl_r_thr   : std_logic;
    signal acl_u_1_d   : std_logic;
    signal acl_d_1_d   : std_logic;
    signal acl_l_1_d   : std_logic;
    signal acl_r_1_d   : std_logic;
    signal acl_u_2_d   : std_logic;
    signal acl_d_2_d   : std_logic;
    signal acl_l_2_d   : std_logic;
    signal acl_r_2_d   : std_logic;
    signal acl_u_1_q   : std_logic;
    signal acl_d_1_q   : std_logic;
    signal acl_l_1_q   : std_logic;
    signal acl_r_1_q   : std_logic;
    signal acl_u_2_q   : std_logic;
    signal acl_d_2_q   : std_logic;
    signal acl_l_2_q   : std_logic;
    signal acl_r_2_q   : std_logic;
    signal acl_count_d : unsigned(31 downto 0);
    signal acl_count_q : unsigned(31 downto 0);
    signal acl_lock_d  : std_logic;
    signal acl_lock_q  : std_logic;
    signal up          : std_logic;
    signal down        : std_logic;
    signal left        : std_logic;
    signal right       : std_logic;

    signal data_x_out : std_logic_vector(7 downto 0);
    signal data_y_out : std_logic_vector(7 downto 0);

begin
    -- 100MHz Clock process
    s_clk100mhz : process (clk, rst)
    begin
        if (rst = '1') then
            red_sqr_xy_q <= (others => (others => '0'));
            red_sqr_x_q  <= "01000";
            red_sqr_y_q  <= "01000";
            h_count_q    <= (others => '0');
            v_count_q    <= (others => '0');
            btn_count_q  <= (others => '0');
            btnu_1_q     <= '0';
            btnd_1_q     <= '0';
            btnl_1_q     <= '0';
            btnr_1_q     <= '0';
            btnu_2_q     <= '0';
            btnd_2_q     <= '0';
            btnl_2_q     <= '0';
            btnr_2_q     <= '0';
            acl_count_q  <= (others => '0');
            acl_lock_q   <= '0';
            acl_u_1_q    <= '0';
            acl_d_1_q    <= '0';
            acl_l_1_q    <= '0';
            acl_r_1_q    <= '0';
            acl_u_2_q    <= '0';
            acl_d_2_q    <= '0';
            acl_l_2_q    <= '0';
            acl_r_2_q    <= '0';
        elsif rising_edge(clk) then
            red_sqr_xy_q <= red_sqr_xy_d;
            red_sqr_x_q  <= red_sqr_x_d;
            red_sqr_y_q  <= red_sqr_y_d;
            h_count_q    <= h_count_d;
            v_count_q    <= v_count_d;
            btn_count_q  <= btn_count_d;
            btnu_1_q     <= btnu_1_d;
            btnd_1_q     <= btnd_1_d;
            btnl_1_q     <= btnl_1_d;
            btnr_1_q     <= btnr_1_d;
            btnu_2_q     <= btnu_2_d;
            btnd_2_q     <= btnd_2_d;
            btnl_2_q     <= btnl_2_d;
            btnr_2_q     <= btnr_2_d;
            acl_count_q  <= acl_count_d;
            acl_lock_q   <= acl_lock_d;
            acl_u_1_q    <= acl_u_1_d;
            acl_d_1_q    <= acl_d_1_d;
            acl_l_1_q    <= acl_l_1_d;
            acl_r_1_q    <= acl_r_1_d;
            acl_u_2_q    <= acl_u_2_d;
            acl_d_2_q    <= acl_d_2_d;
            acl_l_2_q    <= acl_l_2_d;
            acl_r_2_q    <= acl_r_2_d;
        end if;
    end process;

    h_sync <= '0' when (h_count_q >= H_PULSE_CLK_START and h_count_q < H_PULSE_CLK_END) else
        '1';
    v_sync <= '0' when (v_count_q >= V_PULSE_LINE_START and v_count_q < V_PULSE_LINE_END) else
        '1';
    vga_hs <= h_sync;
    vga_vs <= v_sync;

    s_counters : process (h_count_q, v_count_q, en25)
    begin
        h_count_d <= h_count_q;
        v_count_d <= v_count_q;
        if (en25 = '1') then
            if (h_count_q < H_SYNC_PULSE_CLKS) then
                h_count_d <= h_count_q + 1;
            else
                h_count_d <= (others => '0');
                if (v_count_q < V_SYNC_PULSE_LINES) then
                    v_count_d <= v_count_q + 1;
                else
                    v_count_d <= (others => '0');
                end if;
            end if;
        end if;
    end process;

    vga_r <= vga_r_t;
    vga_g <= vga_g_t;
    vga_b <= vga_b_t;

    s_rgb_ctrl : process (v_count_q, h_count_q, red_sqr_x_q, red_sqr_y_q)
    begin
        if (h_count_q >= H_DISP_CLK_START and h_count_q < H_DISP_CLK_END
            and v_count_q >= V_DISP_LINE_START and v_count_q < V_DISP_LINE_END)
            then
            if (h_count_q(9 downto 5) = red_sqr_x_q and v_count_q(9 downto 5) = red_sqr_y_q) then
                vga_r_t <= "1111";
                vga_g_t <= "0000";
                vga_b_t <= "0000";
            elsif ((h_count_q(5) = '0' and v_count_q(5) = '0') or (h_count_q(5) = '1' and v_count_q(5) = '1')) then
                vga_r_t <= "0000";
                vga_g_t <= "1111";
                vga_b_t <= "0000";
            else
                vga_r_t <= "0000";
                vga_g_t <= "0000";
                vga_b_t <= "1111";
            end if;
        else
            vga_r_t <= (others => '0');
            vga_g_t <= (others => '0');
            vga_b_t <= (others => '0');
        end if;
    end process;

    red_sqr_xy_d(7 downto 4) <= red_sqr_xy_q(7 downto 4);
    red_sqr_xy_d(3)          <= "000" & red_sqr_x_q(4);
    red_sqr_xy_d(2)          <= std_logic_vector(red_sqr_x_q(3 downto 0));
    red_sqr_xy_d(1)          <= "0000";
    red_sqr_xy_d(0)          <= std_logic_vector(red_sqr_y_q(3 downto 0));
    seg7_xy                  <= red_sqr_xy_q;

    s_red_sqr_ctrl : process (red_sqr_x_q, red_sqr_y_q, up, down, left, right)
    begin
        red_sqr_x_d <= red_sqr_x_q;
        red_sqr_y_d <= red_sqr_y_q;
        if (up = '1') then
            if (red_sqr_y_q = 0) then
                red_sqr_y_d <= "0" & x"E";
            else
                red_sqr_y_d <= red_sqr_y_q - 1;
            end if;
        elsif (down = '1') then
            if (red_sqr_y_q = 14) then
                red_sqr_y_d <= (others => '0');
            else
                red_sqr_y_d <= red_sqr_y_q + 1;
            end if;
        elsif (left = '1') then
            if (red_sqr_x_q = 0) then
                red_sqr_x_d <= "1" & x"3";
            else
                red_sqr_x_d <= red_sqr_x_q - 1;
            end if;
        elsif (right = '1') then
            if (red_sqr_x_q = 19) then
                red_sqr_x_d <= (others => '0');
            else
                red_sqr_x_d <= red_sqr_x_q + 1;
            end if;
        end if;
    end process;

    s_red_sqr_ctrl_mux : process (
        sw1,
        btnu_db,
        btnd_db,
        btnl_db,
        btnr_db,
        acl_u_thr,
        acl_d_thr,
        acl_l_thr,
        acl_r_thr)
    begin
        if (sw1 = '0') then
            up    <= btnu_db;
            down  <= btnd_db;
            left  <= btnl_db;
            right <= btnr_db;
        else
            up    <= acl_u_thr;
            down  <= acl_d_thr;
            left  <= acl_l_thr;
            right <= acl_r_thr;
        end if;
    end process;

    acl_u_2_d <= acl_u_1_q;
    acl_d_2_d <= acl_d_1_q;
    acl_l_2_d <= acl_l_1_q;
    acl_r_2_d <= acl_r_1_q;

    acl_u_thr <= acl_u_1_q and not acl_u_2_q;
    acl_d_thr <= acl_d_1_q and not acl_d_2_q;
    acl_l_thr <= acl_l_1_q and not acl_l_2_q;
    acl_r_thr <= acl_r_1_q and not acl_r_2_q;
    -- Temporarily locks the accelerometer red-square coord. updates 
    -- to ensure coordinate is only updated once per accelerometer change
    --s_wait_acl : process (acl_count_q, acl_lock_q, acl_u_thr, acl_d_thr, acl_l_thr, acl_r_thr,data_x,data_y) is
    --begin
    --    if (acl_u_thr = '1' or acl_d_thr = '1' or acl_l_thr = '1' or acl_r_thr = '1') then
    --        acl_count_d <= (others => '0');
    --        acl_lock_d  <= '1';
    --    elsif (acl_count_q = ACL_LOCK_WAIT and (data_x > x"FA" and data_x < x"05" and data_y > x"FA" and data_y < x"05")) then
    --        acl_count_d <= (others => '0');
    --        acl_lock_d  <= '0';
    --    else
    --        acl_count_d <= acl_count_q + "1";
    --        acl_lock_d  <= acl_lock_q;
    --    end if;
    --end process;

    s_acl_threshold : process (data_x, data_y)--, acl_lock_q)
    begin
        acl_u_1_d <= '0';
        acl_d_1_d <= '0';
        acl_l_1_d <= '0';
        acl_r_1_d <= '0';
        --if (acl_lock_q /= '1') then
            if (data_x < x"F0" and data_x > x"E3") then
                acl_u_1_d <= '1';
            elsif (data_x < x"45" and data_x > x"25") then
                acl_d_1_d <= '1';
            elsif (data_y < x"45" and data_y > x"25") then
                acl_l_1_d <= '1';
            elsif (data_y < x"F0" and data_y > x"C8") then
                acl_r_1_d <= '1';
            else
                acl_u_1_d <= '0';
                acl_d_1_d <= '0';
                acl_l_1_d <= '0';
                acl_r_1_d <= '0';
            end if;
        --end if;
    end process;

    btnu_2_d <= btnu_1_q;
    btnd_2_d <= btnd_1_q;
    btnl_2_d <= btnl_1_q;
    btnr_2_d <= btnr_1_q;

    btnu_db <= btnu_1_q and not btnu_2_q;
    btnd_db <= btnd_1_q and not btnd_2_q;
    btnl_db <= btnl_1_q and not btnl_2_q;
    btnr_db <= btnr_1_q and not btnr_2_q;

    s_btn_debounce : process (btnu, btnd, btnl, btnr, btn_count_q)
    begin
        if (btnu = '1') then
            if (btn_count_q < BTN_DEBOUNCE_THRESHOLD) then
                btn_count_d <= btn_count_q + "1";
            else
                btnu_1_d <= '1';
            end if;
        elsif (btnd = '1') then
            if (btn_count_q < BTN_DEBOUNCE_THRESHOLD) then
                btn_count_d <= btn_count_q + "1";
            else
                btnd_1_d <= '1';
            end if;
        elsif (btnl = '1') then
            if (btn_count_q < BTN_DEBOUNCE_THRESHOLD) then
                btn_count_d <= btn_count_q + "1";
            else
                btnl_1_d <= '1';
            end if;
        elsif (btnr = '1') then
            if (btn_count_q < BTN_DEBOUNCE_THRESHOLD) then
                btn_count_d <= btn_count_q + "1";
            else
                btnr_1_d <= '1';
            end if;
        else
            btn_count_d <= (others => '0');
            btnu_1_d    <= '0';
            btnd_1_d    <= '0';
            btnl_1_d    <= '0';
            btnr_1_d    <= '0';
        end if;
    end process;

end Behavioral;