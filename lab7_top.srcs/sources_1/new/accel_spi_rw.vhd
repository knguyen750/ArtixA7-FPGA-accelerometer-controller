library IEEE;
use IEEE.STD_LOGIC_1164.all;
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.all;

entity accel_spi_rw is
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
end accel_spi_rw;

architecture behavioral of accel_spi_rw is

    type t_cmd_fsm_state is (
        S_IDLE,
        S_WRITE_ADDR_2D,
        S_DONE_INIT,
        S_READ_ADDR_00,
        S_CAPTURE_ID_AD,
        S_READ_ADDR_01,
        S_CAPTURE_ID_1D,
        S_READ_ADDR_08,
        S_CAPTURE_X,
        S_READ_ADDR_09,
        S_CAPTURE_Y,
        S_READ_ADDR_0A,
        S_CAPTURE_Z
    );
    signal state_cmd_d : t_cmd_fsm_state;
    signal state_cmd_q : t_cmd_fsm_state;

    type t_spi_fsm_state is (
      S_IDLE,
      S_SET_CS_LO,
      S_SCLK_HI,
      S_SCLK_LO,
      S_INC_SCLK_CNTR,
      S_CHECK_SCLK_CNTR,
      S_SET_CS_HI,
      S_WAIT_100MS
    );
    signal state_spi_d : t_spi_fsm_state;
    signal state_spi_q : t_spi_fsm_state;

    signal sclk_counter_d : unsigned(4 downto 0);
    signal sclk_counter_q : unsigned(4 downto 0);

    signal spi_start_d : std_logic;
    signal spi_start_q : std_logic;
    signal spi_done : std_logic;

    signal timer_start : std_logic;
    signal timer_max : unsigned(26 downto 0);
    signal timer_done : std_logic;
    signal timer_counter_d : unsigned(26 downto 0);
    signal timer_counter_q : unsigned(26 downto 0);

    signal shift_mosi_d : std_logic_vector(23 downto 0);
    signal shift_mosi_q : std_logic_vector(23 downto 0);

    signal shift_miso_d : std_logic_vector(23 downto 0);
    signal shift_miso_q : std_logic_vector(23 downto 0);

    signal to_spi_bytes_d : std_logic_vector(23 downto 0);
    signal to_spi_bytes_q : std_logic_vector(23 downto 0);

    signal id_ad_d  : std_logic_vector(7 downto 0);
    signal id_1d_d  : std_logic_vector(7 downto 0);
    signal data_x_d : std_logic_vector(7 downto 0);
    signal data_y_d : std_logic_vector(7 downto 0);
    signal data_z_d : std_logic_vector(7 downto 0);
    signal id_ad_q  : std_logic_vector(7 downto 0);
    signal id_1d_q  : std_logic_vector(7 downto 0);
    signal data_x_q : std_logic_vector(7 downto 0);
    signal data_y_q : std_logic_vector(7 downto 0);
    signal data_z_q : std_logic_vector(7 downto 0);

begin
    
    s_clk : process (clk, reset)
    begin
        if (reset = '1') then
            state_cmd_q     <= S_IDLE;
            state_spi_q     <= S_IDLE;
            to_spi_bytes_q  <= (others => '0');
            sclk_counter_q  <= (others => '0');
            timer_counter_q <= (others => '0');
            shift_mosi_q    <= (others => '0');
            shift_miso_q    <= (others => '0');
            id_ad_q   <= (others => '0');
            id_1d_q   <= (others => '0');
            data_x_q  <= (others => '0');
            data_y_q  <= (others => '0');
            data_z_q  <= (others => '0');
            spi_start_q <= '0';
        elsif rising_edge(clk) then
            state_cmd_q     <= state_cmd_d;
            state_spi_q     <= state_spi_d;
            to_spi_bytes_q  <= to_spi_bytes_d;
            sclk_counter_q  <= sclk_counter_d;
            timer_counter_q <= timer_counter_d;
            shift_mosi_q    <= shift_mosi_d;
            shift_miso_q    <= shift_miso_d;
            id_ad_q   <= id_ad_d; 
            id_1d_q   <= id_1d_d; 
            data_x_q  <= data_x_d;
            data_y_q  <= data_y_d;
            data_z_q  <= data_z_d;
            spi_start_q <= spi_start_d;
        end if;
    end process;

    -- Command FSM
    s_cmd_fsm : process (state_cmd_q, to_spi_bytes_q, spi_done) is
    begin
        state_cmd_d <= state_cmd_q;
        to_spi_bytes_d  <= to_spi_bytes_q;
        spi_start_d <= '0'; 

        case (state_cmd_q) is
            -- Idle at Startup/Reset
            when S_IDLE =>
              spi_start_d    <= '1';
                to_spi_bytes_d <= X"0A2D02";
                state_cmd_d  <= S_WRITE_ADDR_2D;

            -- Write to Reg. Addr. 0x2D
            when S_WRITE_ADDR_2D =>
              if (spi_done = '1') then
                state_cmd_d <= S_DONE_INIT;
              end if;
            
            -- Startup Done
            when S_DONE_INIT =>
            spi_start_d <= '1';
              to_spi_bytes_d <= x"0B0000";
              state_cmd_d <= S_READ_ADDR_00;

            -- Read Reg. Addr. 0x00
            when S_READ_ADDR_00 =>
              if (spi_done = '1') then
                state_cmd_d <= S_CAPTURE_ID_AD;
              end if;
                
            -- Capture Device ID Reg. Addr. 0xAD
            when S_CAPTURE_ID_AD =>
            spi_start_d <= '1';
              to_spi_bytes_d <= X"0B0100";
              state_cmd_d <= S_READ_ADDR_01;

            -- Read Reg. Addr. 0x01
            when S_READ_ADDR_01 =>
              if (spi_done = '1') then
                state_cmd_d <= S_CAPTURE_ID_1D;
              end if;

            -- Capture Device ID Reg. Addr. 0x1D
            when S_CAPTURE_ID_1D =>
            spi_start_d <= '1';
              to_spi_bytes_d <= X"0B0800";
              state_cmd_d <= S_READ_ADDR_08;

            -- Read Reg. Addr. 0x08
            when S_READ_ADDR_08 =>
              if (spi_done = '1') then
                state_cmd_d <= S_CAPTURE_X;
              end if;

            -- Capture X Data
            when S_CAPTURE_X =>
            spi_start_d <= '1';
              to_spi_bytes_d <= X"0B0900";
              state_cmd_d <= S_READ_ADDR_09;

            -- Read Reg. Addr. 0x09
            when S_READ_ADDR_09 =>
            if (spi_done = '1') then
              state_cmd_d <= S_CAPTURE_Y;
            end if;

            -- Capture Y Data
            when S_CAPTURE_Y =>
            spi_start_d <= '1';
              to_spi_bytes_d <= X"0B0A00";
              state_cmd_d <= S_READ_ADDR_0A;

            -- Read Reg. Addr. 0x0A
            when S_READ_ADDR_0A =>
              if (spi_done = '1') then
                state_cmd_d <= S_CAPTURE_Z;
              end if;

              -- Capture Z Data
            when S_CAPTURE_Z =>
            spi_start_d <= '1';
              to_spi_bytes_d <= X"0B0000";
              state_cmd_d <= S_READ_ADDR_00;
              
            when others =>
                null;
        end case;
    end process;

    -- SPI FSM

    -- Timing Requirements relative to SCLK @ 
    -- 1) CSb: Wait 6 clocks (15ns * 6 clks = 100ns) for CSb setup time
    -- 2) MOSI Write Data: (20ns data setup time, 20ns data hold time)
    -- 3) MISO Read Data: Valid 35ns after clock low

    s_spi_fsm : process (state_spi_q, spi_start_q, timer_done) is
    begin
      state_spi_d <= state_spi_q;
      --timer_start <= '0';
      --timer_max <= 1;
      CSb <= '1';
      SCLK <= '0';
      spi_done <= '0';

      case (state_spi_q) is
          when S_IDLE =>
            SCLK <= '0';
            CSb <= '1';
            state_spi_d <= S_IDLE;
            spi_done <= '0';
            timer_start <= '0';
            timer_max <= (others => '1');
            if (spi_start_q = '1') then
              state_spi_d <= S_SET_CS_LO;
            end if;
  
          when S_SET_CS_LO =>
            SCLK <= '0';
            CSb <= '0';
            if (timer_done = '1') then
              timer_start <= '0';
              state_spi_d <= S_SCLK_HI;
            else
              timer_start <= '1';
              timer_max <= to_unsigned(19, 27);
            end if;

          when S_SCLK_HI =>
            SCLK <= '1';
            CSb <= '0';
            if (timer_done = '1') then
              timer_start <= '0';
              state_spi_d <= S_SCLK_LO;
            else
              timer_start <= '1';
              timer_max <= to_unsigned(49, 27);
            end if;

          when S_SCLK_LO =>
            SCLK <= '0';
            CSb <= '0';
            if (timer_done = '1') then
              timer_start <= '0';
              state_spi_d <= S_INC_SCLK_CNTR;
            else
              timer_start <= '1';
              timer_max <= to_unsigned(47, 27);
            end if;

          when S_INC_SCLK_CNTR =>
            timer_start <= '0';
            SCLK <= '0';
            CSb <= '0';
            state_spi_d <= S_CHECK_SCLK_CNTR;

          when S_CHECK_SCLK_CNTR =>
            state_spi_d <= S_SCLK_HI;
            CSb <= '0';
            SCLK <= '0';
            timer_start <= '0';
            if (sclk_counter_q = to_unsigned(24, 5)) then
              state_spi_d <= S_SET_CS_HI;
            end if;
            
          when S_SET_CS_HI =>
            timer_start <= '0';
            CSb <= '1';
            SCLK <= '0';
            state_spi_d <= S_WAIT_100MS;
            
          when S_WAIT_100MS =>
            CSb <= '1';
            SCLK <= '0';
            if (timer_done = '1') then
              timer_start <= '0';
              spi_done <= '1';
              state_spi_d <= S_IDLE;
            else 
              timer_start <= '1';
              timer_max <= to_unsigned(10000000, 27);
            end if;
          
          when others => null;
          
      end case;
    end process;

    -------- Serial to Parallel --------
    s_ser_to_par : process (state_spi_q, shift_miso_q, sclk_counter_q, MISO) is
    begin
      shift_miso_d <= shift_miso_q;
      if (state_spi_q = S_CHECK_SCLK_CNTR and sclk_counter_q < to_unsigned(24, 5)) then
        shift_miso_d <= shift_miso_q(22 downto 0) & MISO;
      end if;
    end process;

    MOSI <= shift_mosi_q(23);
    -------- Parallel to Serial --------
    s_par_to_ser : process (state_spi_q, timer_done, shift_mosi_q, to_spi_bytes_q, spi_start_q) is
    begin
      if (state_spi_q = S_SCLK_HI and timer_done = '1') then
          shift_mosi_d <= shift_mosi_q(22 downto 0) & shift_mosi_q(23);
      else 
        shift_mosi_d <= shift_mosi_q;
      end if;

      if (spi_start_q = '1') then
        shift_mosi_d <= to_spi_bytes_q;
      end if;
    end process;
    
    -------- SPI FSM Timer --------
    timer_done <= '1' when timer_counter_q = timer_max else '0';
    s_fsm_timer : process (timer_start, timer_max, timer_counter_q) is
    begin
      timer_counter_d <= timer_counter_q;
      if(timer_start = '1') then
        if(timer_counter_q < timer_max) then
          --timer_done <= '0';
          timer_counter_d <= timer_counter_q + 1;
        else 
          --timer_done <= '1';
          timer_counter_d <= (others => '0');
        end if;
      else 
        --timer_done <= '0';
        timer_counter_d <= (others => '0');
      end if;
    end process;

    s_sclk_counter : process (state_spi_q, sclk_counter_q, spi_done) is
    begin
      sclk_counter_d  <= sclk_counter_q;

      if (state_spi_q = S_INC_SCLK_CNTR and sclk_counter_q < 24) then
        sclk_counter_d <= sclk_counter_q + 1;
      elsif (state_spi_q = S_WAIT_100MS and spi_done = '1') then
        sclk_counter_d <= (others => '0');
      end if;
    end process;


    ID_AD  <= id_ad_q;
    ID_1D  <= id_1d_q;
    DATA_X <= data_x_q;
    DATA_Y <= data_y_q;
    DATA_Z <= data_z_q;

    s_capture_data : process 
    (
      state_cmd_q,
      id_ad_q,
      id_1d_q,
      data_x_q,
      data_y_q,
      data_z_q,
      shift_miso_q
    ) is
    begin
      id_ad_d   <= id_ad_q;
      id_1d_d   <= id_1d_q;
      data_x_d  <= data_x_q;
      data_y_d  <= data_y_q;
      data_z_d  <= data_z_q;

      if (state_cmd_q = S_CAPTURE_ID_AD) then
        id_ad_d <= shift_miso_q(7 downto 0);
      end if;

      if (state_cmd_q = S_CAPTURE_ID_1D) then
        id_1d_d <= shift_miso_q(7 downto 0);
      end if;

      if (state_cmd_q = S_CAPTURE_X) then
        data_x_d <= shift_miso_q(7 downto 0);
      end if;

      if (state_cmd_q = S_CAPTURE_Y) then
        data_y_d <= shift_miso_q(7 downto 0);
      end if;

      if (state_cmd_q = S_CAPTURE_Z) then
        data_z_d <= shift_miso_q(7 downto 0);
      end if;
    end process;

end behavioral;