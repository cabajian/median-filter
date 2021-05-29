----------------------------------------------------------------------------------
-- Engineer:     Chris Abajian (cxa6282@rit.edu)
--
-- Module Name:  MLUART_TX - Behavioral
-- Project Name: Ex2 - UART Serial Communication & FIFO
-- Description:  UART transmission module.
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity MLUART_TX is
port ( CLK_100MHZ         : in std_logic;
       clk_en_16_x_baud   : in std_logic;
       data_in            : in std_logic_vector(7 downto 0);
       send_data          : in std_logic;
       UART_TX            : out std_logic;
       send_data_complete : out std_logic
     );

end MLUART_TX;

architecture Behavioral of MLUART_TX is

type   tstateTX is (idle, sstart, sstop, sd0, sd1, sd2, sd3, sd4, sd5, sd6, sd7);
signal sstateTX : tstateTX;
signal scount4 : std_logic_vector (3 downto 0) := (others => '0');

signal sdata_reg : std_logic_vector(7 downto 0) := (others => '0');
signal sdata_out : std_logic := '1';

begin

UART_TX <= sdata_out;

-- State Machine: transitions
process(CLK_100MHZ)
begin
  if CLK_100MHZ'event and CLK_100MHZ = '1' then
    if clk_en_16_x_baud = '1' then
      case sstateTX is
        when idle      => if scount4 = X"F" and send_data = '1' then sstateTX <= sstart; end if;
        when sstart    => if scount4 = X"F" then sstateTX <= sd0; end if;
        when sd0       => if scount4 = X"F" then sstateTX <= sd1; end if;
        when sd1       => if scount4 = X"F" then sstateTX <= sd2; end if;
        when sd2       => if scount4 = X"F" then sstateTX <= sd3; end if;
        when sd3       => if scount4 = X"F" then sstateTX <= sd4; end if;
        when sd4       => if scount4 = X"F" then sstateTX <= sd5; end if;
        when sd5       => if scount4 = X"F" then sstateTX <= sd6; end if;
        when sd6       => if scount4 = X"F" then sstateTX <= sd7; end if;
        when sd7       => if scount4 = X"F" then sstateTX <= sstop; end if;
        when sstop     => if scount4 = X"F" then sstateTX <= idle; end if;
      end case;
    end if;
  end if;
end process;

process(sstateTX, scount4)
begin
  case sstateTX is
    when sstop => if scount4 = X"F" then send_data_complete <= '1'; else send_data_complete <= '0'; end if;
    when others => send_data_complete <= '0';
  end case;
end process;

-- datapath

-- input data register
process(CLK_100MHZ)
begin
  if CLK_100MHZ'event and CLK_100MHZ = '1' then
    if clk_en_16_x_baud = '1' then
      case sstateTX is
        when sstart => sdata_reg <= data_in;
        when sd0|sd1|sd2|sd3|sd4|sd5|sd6|sd7 => if scount4 = X"F" then sdata_reg <= '0' & sdata_reg(7 downto 1); end if; 
        when others => sdata_reg <= sdata_reg;
      end case;
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

-- tx out
process(sstateTX, sdata_reg)
begin
  case sstateTX is
    when sstart => sdata_out <= '0';
    when sd0|sd1|sd2|sd3|sd4|sd5|sd6|sd7 => sdata_out <= sdata_reg(0);
    when sstop => sdata_out <= '1';
    when others => sdata_out <= '1';
  end case;
end process;

end Behavioral;

