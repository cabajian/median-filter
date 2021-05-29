library ieee;
use ieee.std_logic_1164.all;
use  ieee.numeric_std.all;

entity median_top is
    port (
        clk          : in  std_logic;
        rst          : in  std_logic;
        i_data_vld   : in  std_logic;
        i_data       : in  unsigned(7 downto 0);
        o_median     : out unsigned(7 downto 0)
    );
end median_top;

architecture behavioral of median_top is

    type tmedstate is (load1, load2, load3);
    signal nxt_medstate   : tmedstate := load1;
    signal medstate       : tmedstate := load1;
    
    signal en1            : std_logic := '0';
    signal en2            : std_logic := '0';
begin

    median_filter_inst : entity work.median_filter
    port map (
        clk => clk,
        rst => rst,
        i_data => i_data,
        i_en1 => en1,
        i_en2 => en2,
        o_med => o_median
    );
    
    process(all) begin
        en1 <= '0';
        en2 <= '0';
        nxt_medstate <= medstate;
        case medstate is
            -- load stages (need 2 registered bytes in filter)
            when load1    => if i_data_vld = '1' then
                                 nxt_medstate <= load2;
                             end if;
                             en1 <= i_data_vld;
            when load2    => if i_data_vld = '1' then
                                 nxt_medstate <= load3;
                             end if;
                             en1 <= i_data_vld;
            -- final load stage that registers all data inputs in filter and median output
            when load3    => if i_data_vld = '1' then
                                 nxt_medstate <= load1;
                             end if;
                             en2 <= i_data_vld;
        end case;
        
    end process;
    
    process(clk) begin
        if rising_edge(clk) then
            if rst = '1' then
                medstate   <= load1;
            else
                medstate   <= nxt_medstate;
            end if;
        end if;
    end process;

end behavioral;