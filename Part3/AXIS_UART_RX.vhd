----------------------------------------------------------------------------------
-- Engineer:     Chris Abajian (cxa6282@rit.edu)
--
-- Module Name:  AXIS_UART_RX - RTL
-- Project Name: Ex2 - UART Serial Communication & FIFO
-- Description:  AXIS master interface for UART receive.
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use  IEEE.NUMERIC_STD.ALL;

entity AXIS_UART_RX is
    port (
        -- clocks and rx data
        CLK_100MHZ       : in std_logic;
        clk_en_16_x_baud : in std_logic;
        UART_RX          : in std_logic;
        -- master signals
        m_axis_valid     : out std_logic;
        m_axis_ready     : in std_logic;
        m_axis_data      : out std_logic_vector(7 downto 0);
        -- fifo status
        almost_full      : in std_logic
    );
end AXIS_UART_RX;

architecture RTL of AXIS_UART_RX is

    type tstateAXIS_RX is (read, complete);
    signal sstateAXIS_RX : tstateAXIS_RX := read;

    signal read_complete    : std_logic := '0';
begin

    uart_rx_inst : entity work.MLUART_RX port map (
        CLK_100MHZ         => CLK_100MHZ,
        clk_en_16_x_baud   => clk_en_16_x_baud,
        read_data_complete => read_complete,
        data_out           => m_axis_data,
        UART_RX            => UART_RX
    );
    
    process(CLK_100MHZ) begin
        if rising_edge(CLK_100MHZ) then
            case sstateAXIS_RX is
                when read     => if read_complete = '1' and clk_en_16_x_baud = '1' then -- hold until read_complete pulses
                                     sstateAXIS_RX <= complete;
                                 end if;
                when complete => if m_axis_ready = '1' and almost_full = '0' then
                                     sstateAXIS_RX <= read;
                                 end if;
            end case;
        end if;
    end process;
    
    process(sstateAXIS_RX, almost_full) begin
        case sstateAXIS_RX is
            when read   =>
                m_axis_valid <= '0';
            when others =>
                m_axis_valid <= not almost_full;
        end case;
    end process;


end RTL;