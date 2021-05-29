----------------------------------------------------------------------------------
-- Engineer:     Chris Abajian (cxa6282@rit.edu)
--
-- Module Name:  AXIS_UART_TX - RTL
-- Project Name: Ex2 - UART Serial Communication & FIFO
-- Description:  AXIS slave interface for UART transmission.
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use  IEEE.NUMERIC_STD.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity AXIS_UART_TX is
    port (
        -- clocks and tx data
        CLK_100MHZ       : in std_logic;
        clk_en_16_x_baud : in std_logic;
        UART_TX          : out std_logic;
        -- slave signals
        s_axis_valid     : in std_logic;
        s_axis_ready     : out std_logic;
        s_axis_data      : in std_logic_vector(7 downto 0)
    );
end AXIS_UART_TX;

architecture RTL of AXIS_UART_TX is

    type tstateAXIS_TX is (idle, start, hold, complete, pause);
    signal sstateAXIS_TX : tstateAXIS_TX := idle;
    
    signal scount4 : std_logic_vector(3 downto 0) := (others => '0');
    
    signal char_count : integer := 0;
    signal pause_count : integer := 0;

    signal send_complete      : std_logic := '0';
    
    signal tx_send            : std_logic := '0';
    signal tx_data            : std_logic_vector(7 downto 0) := (others => '0');
    signal tx_data_fb         : std_logic_vector(7 downto 0) := (others => '0');
begin

    uart_tx_inst : entity work.MLUART_TX port map (
        CLK_100MHZ         => CLK_100MHZ,
        clk_en_16_x_baud   => clk_en_16_x_baud,
        data_in            => tx_data,
        send_data          => tx_send,
        UART_TX            => UART_TX,
        send_data_complete => send_complete
    );
    
    process(CLK_100MHZ) begin
        if rising_edge(CLK_100MHZ) then
            case sstateAXIS_TX is
                when idle     => if s_axis_valid = '1' then
                                     sstateAXIS_TX <= start;
                                 end if;
                when start    => if clk_en_16_x_baud = '1' and scount4 = X"F" then -- synchronize with UART data rate
                                     sstateAXIS_TX <= hold;
                                 end if;
                when hold     => if send_complete = '1' and clk_en_16_x_baud = '1' then -- hold until send_complete pulses
                                     sstateAXIS_TX <= complete;
                                 end if;
                when complete => if char_count < 256 then 
                                     sstateAXIS_TX <= idle;
                                 else
                                     sstateAXIS_TX <= pause;
                                 end if;
                when pause    => if pause_count >= 30 then -- pause state to "reset" TX. Wait for 3 data transmission cycles
                                     sstateAXIS_TX <= idle;
                                 end if;
            end case;
        end if;
    end process;
    
    process(sstateAXIS_TX, s_axis_data, tx_data_fb) begin
        case sstateAXIS_TX is
            when idle   =>
                tx_send      <= '0';
                tx_data      <= s_axis_data;
                s_axis_ready <= '1';
            when start   =>
                tx_send      <= '1';
                tx_data      <= tx_data_fb;
                s_axis_ready <= '0';
            when hold   =>
                tx_send      <= '0';
                tx_data      <= tx_data_fb;
                s_axis_ready <= '0';
            when others =>
                tx_send      <= '0';
                tx_data      <= (others => '0');
                s_axis_ready <= '0';
        end case;
    end process;
    
    process(CLK_100MHZ)
    begin
      if CLK_100MHZ'event and CLK_100MHZ = '1' then
        if sstateAXIS_TX = complete then
            char_count <= char_count + 1;
        elsif sstateAXIS_TX = pause then
            char_count <= 0;
        end if;
      end if;
    end process;
    
    -- 4-bit baud counter
    process(CLK_100MHZ)
    begin
      if CLK_100MHZ'event and CLK_100MHZ = '1' then
        if clk_en_16_x_baud = '1' then
           scount4 <= scount4 + '1';
        end if;
      end if;
    end process;
    
    -- pause counter (counts uart bits)
    process(CLK_100MHZ)
    begin
      if CLK_100MHZ'event and CLK_100MHZ = '1' then
        if sstateAXIS_TX = idle then
            pause_count <= 0;
        elsif sstateAXIS_TX = pause and clk_en_16_x_baud = '1' and scount4 = X"F" then
            pause_count <= pause_count + 1;
        end if;
      end if;
    end process;
    
    process(CLK_100MHZ)
    begin
        if rising_edge(CLK_100MHZ) then
            tx_data_fb <= tx_data;
        end if;
    end process;

end RTL;