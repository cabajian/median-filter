library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_median_top is
end tb_median_top;

architecture Behavioral of tb_median_top is

    constant clk_period : time := 10 ns;
    signal clk        :   std_logic := '1';
    signal rst        :   std_logic := '1';
    
    type tarray2d is array (0 to 2, 0 to 5) of integer range 0 to 255;
    signal med_array : tarray2d := ( (1,  2,  3,  4,  5,  6),
                                     (7,  8,  9,  10, 11, 12),
                                     (13, 14, 15, 16, 17, 18) );
    
    signal data_vld   : std_logic;
    signal data       : unsigned(7 downto 0);
    signal median     : unsigned(7 downto 0);

begin

    median_top_uut : entity work.median_top
    port map (
        clk => clk,
        rst => rst,
        i_data_vld => data_vld,
        i_data => data,
        o_median => median
    );

    -- Clock process definitions
    process
    begin
        clk <= '0';
        wait for clk_period/2;
        clk <= '1';
        wait for clk_period/2;
    end process;

    -- Stimulus process
    process begin
        wait for 200 ns;
        rst <= '0';
        wait for 100 ns;
        
        -- ----------------------------------------------
        -- CENTERED MEDIAN
        -- ----------------------------------------------
        data_vld <= '1';
        for i in 0 to 5 loop
            data <= to_unsigned(med_array(1,i),8);
            wait for clk_period;
            data <= to_unsigned(med_array(0,i),8);
            wait for clk_period;
            data <= to_unsigned(med_array(2,i),8);
            wait for clk_period;
        end loop;
        
        -- input is 6 columns, outputs shoud be coming in now.
        assert median = X"08"
            report "Incorrect median."
            severity error;
        wait for 3*clk_period; -- 3 load cycles
        assert median = X"09"
            report "Incorrect median."
            severity error;
        wait for 3*clk_period; -- 3 load cycles
        assert median = X"0a"
            report "Incorrect median."
            severity error;
        wait for 3*clk_period; -- 3 load cycles
        assert median = X"0b"
            report "Incorrect median."
            severity error;
        wait for 3*clk_period; -- 3 load cycles
                
        data_vld <= '0';
        rst <= '1';
        wait for 2*clk_period;
        rst <= '0';
        wait for clk_period;
        
        -- ----------------------------------------------
        -- MEDIAN ON TOP
        -- ----------------------------------------------
        data_vld <= '1';
        for i in 0 to 5 loop
            data <= to_unsigned(med_array(0,i),8);
            wait for clk_period;
            data <= to_unsigned(med_array(1,i),8);
            wait for clk_period;
            data <= to_unsigned(med_array(2,i),8);
            wait for clk_period;
        end loop;
        
        -- input is 6 columns, outputs shoud be coming in now.
        assert median = X"08"
            report "Incorrect median."
            severity error;
        wait for 3*clk_period; -- 3 load cycles
        assert median = X"09"
            report "Incorrect median."
            severity error;
        wait for 3*clk_period; -- 3 load cycles
        assert median = X"0a"
            report "Incorrect median."
            severity error;
        wait for 3*clk_period; -- 3 load cycles
        assert median = X"0b"
            report "Incorrect median."
            severity error;
        wait for 3*clk_period; -- 3 load cycles
        
        data_vld <= '0';
        rst <= '1';
        wait for 2*clk_period;
        rst <= '0';
        wait for clk_period;
        
        -- ----------------------------------------------
        -- MEDIAN ON BOTTOM
        -- ----------------------------------------------
        data_vld <= '1';
        for i in 0 to 5 loop
            data <= to_unsigned(med_array(0,i),8);
            wait for clk_period;
            data <= to_unsigned(med_array(2,i),8);
            wait for clk_period;
            data <= to_unsigned(med_array(1,i),8);
            wait for clk_period;
        end loop;
        
        -- input is 6 columns, outputs shoud be coming in now.
        assert median = X"08"
            report "Incorrect median."
            severity error;
        wait for 3*clk_period; -- 3 load cycles
        assert median = X"09"
            report "Incorrect median."
            severity error;
        wait for 3*clk_period; -- 3 load cycles
        assert median = X"0a"
            report "Incorrect median."
            severity error;
        wait for 3*clk_period; -- 3 load cycles
        assert median = X"0b"
            report "Incorrect median."
            severity error;
        wait for 3*clk_period; -- 3 load cycles
        
                        
        wait for 20*clk_period;
        
        assert false
            report "End of simulation"
            severity failure;

    end process;

end Behavioral;
