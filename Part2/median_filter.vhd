library ieee;
use ieee.std_logic_1164.all;
use  ieee.numeric_std.all;

entity median_filter is
    port (
        clk    : in  std_logic;
        rst    : in  std_logic;
        i_data : in  unsigned(7 downto 0);
        i_en1  : in  std_logic;
        i_en2  : in  std_logic;
        o_med  : out unsigned(7 downto 0)
    );
end median_filter;

architecture behavioral of median_filter is
    
    -- registers to hold input data
    signal data_m2     : unsigned(7 downto 0);
    signal data_m1     : unsigned(7 downto 0);
    signal a,b,c       : unsigned(7 downto 0);
        
    -- d1
    signal nxt_h1_d1   : unsigned(7 downto 0);
    signal nxt_h2_d1   : unsigned(7 downto 0);
    signal nxt_l1_d1   : unsigned(7 downto 0);
    signal nxt_high_d1 : unsigned(7 downto 0);
    signal nxt_med_d1  : unsigned(7 downto 0);
    signal nxt_low_d1  : unsigned(7 downto 0);
    signal high_d1     : unsigned(7 downto 0);
    signal med_d1      : unsigned(7 downto 0);
    signal low_d1      : unsigned(7 downto 0);
    
    -- d2
    signal high_d2     : unsigned(7 downto 0);
    signal med_d2      : unsigned(7 downto 0);
    signal low_d2      : unsigned(7 downto 0);
    
    -- d3
    signal nxt_high_d3 : unsigned(7 downto 0);
    signal nxt_medh_d3 : unsigned(7 downto 0);
    signal nxt_medl_d3 : unsigned(7 downto 0);
    signal nxt_low_d3  : unsigned(7 downto 0);
    signal high_d3     : unsigned(7 downto 0);
    signal medh_d3     : unsigned(7 downto 0);
    signal medl_d3     : unsigned(7 downto 0);
    signal low_d3      : unsigned(7 downto 0);
    
    -- d4
    signal nxt_high_d4 : unsigned(7 downto 0);
    signal nxt_m1_d4   : unsigned(7 downto 0);
    signal nxt_med_d4  : unsigned(7 downto 0);
    signal nxt_low_d4  : unsigned(7 downto 0);
    signal high_d4     : unsigned(7 downto 0);
    signal med_d4      : unsigned(7 downto 0);
    signal low_d4      : unsigned(7 downto 0);
    
    -- d5
    signal nxt_h1_d5   : unsigned(7 downto 0);
    signal nxt_h2_d5   : unsigned(7 downto 0);
    signal nxt_l1_d5   : unsigned(7 downto 0);
    signal nxt_med_d5  : unsigned(7 downto 0);
    signal med_d5      : unsigned(7 downto 0);
    
    -- "bubble" (comparison) interconnects



begin

    -- combinational process
    process(all)
        -- partial sort subroutines
--        procedure compare (
--            signal a : in  unsigned(7 downto 0);
--            signal b : in  unsigned(7 downto 0);
--            signal h : out unsigned(7 downto 0);
--            signal l : out unsigned(7 downto 0)
--        ) is
--        begin
--            if a > b then
--                h <= a;
--                l <= b;
--            else
--                h <= b;
--                l <= a;
--            end if;
--        end compare;
--        procedure compare_low (
--            signal a : in  unsigned(7 downto 0);
--            signal b : in  unsigned(7 downto 0);
--            signal l : out unsigned(7 downto 0)
--        ) is
--        begin
--            if a > b then
--                l <= b;
--            else
--                l <= a;
--            end if;
--        end compare_low;
--        procedure compare_high (
--            signal a : in  unsigned(7 downto 0);
--            signal b : in  unsigned(7 downto 0);
--            signal h : out unsigned(7 downto 0)
--        ) is
--        begin
--            if a > b then
--                h <= a;
--            else
--                h <= b;
--            end if;
--        end compare_high;
    begin
       
        -- partial sort
        -- d1
        --compare(a, b, nxt_h1_d1, nxt_l1_d1);
        if a > b then
            nxt_h1_d1 <= a;
            nxt_l1_d1 <= b;
        else
            nxt_h1_d1 <= b;
            nxt_l1_d1 <= a;
        end if;
        --compare(nxt_l1_d1, c, nxt_h2_d1, nxt_low_d1);
        if nxt_l1_d1 > c then
            nxt_h2_d1 <= nxt_l1_d1;
            nxt_low_d1 <= c;
        else
            nxt_h2_d1 <= c;
            nxt_low_d1 <= nxt_l1_d1;
        end if;
        --compare(nxt_h1_d1, nxt_h2_d1, nxt_high_d1, nxt_med_d1);
        if nxt_h1_d1 > nxt_h2_d1 then
            nxt_high_d1 <= nxt_h1_d1;
            nxt_med_d1 <= nxt_h2_d1;
        else
            nxt_high_d1 <= nxt_h2_d1;
            nxt_med_d1 <= nxt_h1_d1;
        end if;
        -- d3
        --compare_low(high_d2, high_d1, nxt_high_d3);
        if high_d2 > high_d1 then
            nxt_high_d3 <= high_d1;
        else
            nxt_high_d3 <= high_d2;
        end if;
        --compare(med_d2, med_d1, nxt_medh_d3, nxt_medl_d3);
        if med_d2 > med_d1 then
            nxt_medh_d3 <= med_d2;
            nxt_medl_d3 <= med_d1;
        else
            nxt_medh_d3 <= med_d1;
            nxt_medl_d3 <= med_d2;
        end if;
        --compare_high(low_d2, low_d1, nxt_low_d3);
        if low_d2 > low_d1 then
            nxt_low_d3 <= low_d2;
        else
            nxt_low_d3 <= low_d1;
        end if;
        -- d4
        --compare_low(high_d3, high_d1, nxt_high_d4);
        if high_d3 > high_d1 then
            nxt_high_d4 <= high_d1;
        else
            nxt_high_d4 <= high_d3;
        end if;
        --compare_high(medl_d3, med_d1, nxt_m1_d4);
        if medl_d3 > med_d1 then
            nxt_m1_d4 <= medl_d3;
        else
            nxt_m1_d4 <= med_d1;
        end if;
        --compare_low(medh_d3, nxt_m1_d4, nxt_med_d4);
        if medh_d3 > nxt_m1_d4 then
            nxt_med_d4 <= nxt_m1_d4;
        else
            nxt_med_d4 <= medh_d3;
        end if;
        --compare_high(low_d3, low_d1, nxt_low_d4);
        if low_d3 > low_d1 then
            nxt_low_d4 <= low_d3;
        else
            nxt_low_d4 <= low_d1;
        end if;
        -- d5
        --compare(high_d4, med_d4, nxt_h1_d5, nxt_l1_d5);
        if high_d4 > med_d4 then
            nxt_h1_d5 <= high_d4;
            nxt_l1_d5 <= med_d4;
        else
            nxt_h1_d5 <= med_d4;
            nxt_l1_d5 <= high_d4;
        end if;
        --compare_high(nxt_l1_d5, low_d4, nxt_h2_d5);
        if nxt_l1_d5 > low_d4 then
            nxt_h2_d5 <= nxt_l1_d5;
        else
            nxt_h2_d5 <= low_d4;
        end if;
        --compare_low(nxt_h1_d5, nxt_h2_d5, nxt_med_d5);
        if nxt_h1_d5 > nxt_h2_d5 then
            nxt_med_d5 <= nxt_h2_d5;
        else
            nxt_med_d5 <= nxt_h1_d5;
        end if;
        
    end process;
    
    -- sequential process
    process(clk) begin
        if rising_edge(clk) then
            if rst = '1' then
                data_m2 <= (others => '0');
                data_m1 <= (others => '0');
                --
                a <= (others => '0');
                b <= (others => '0');
                c <= (others => '0');
                -- high sorted elements
                high_d1 <= (others => '0');
                high_d2 <= (others => '0');
                high_d3 <= (others => '0');
                high_d4 <= (others => '0');
                -- median sorted elements
                med_d1  <= (others => '0');
                med_d2  <= (others => '0');
                medh_d3 <= (others => '0');
                medl_d3 <= (others => '0');
                med_d4  <= (others => '0');
                med_d5  <= (others => '0');
                -- low sorted elements
                low_d1  <= (others => '0');
                low_d2  <= (others => '0');
                low_d3  <= (others => '0');
                low_d4  <= (others => '0');
            elsif i_en1 = '1' then
                data_m2 <= i_data;
                data_m1 <= data_m2;
            elsif i_en2 = '1' then
                a <= data_m1;
                b <= data_m2;
                c <= i_data;
                -- high sorted elements
                high_d1 <= nxt_high_d1;
                high_d2 <= high_d1;
                high_d3 <= nxt_high_d3;
                high_d4 <= nxt_high_d4;
                -- median sorted elements
                med_d1  <= nxt_med_d1;
                med_d2  <= med_d1;
                medh_d3 <= nxt_medh_d3;
                medl_d3 <= nxt_medl_d3;
                med_d4  <= nxt_med_d4;
                med_d5  <= nxt_med_d5;
                -- low sorted elements
                low_d1  <= nxt_low_d1;
                low_d2  <= low_d1;
                low_d3  <= nxt_low_d3;
                low_d4  <= nxt_low_d4;
            end if;
        end if;
    end process;
    
    -- output
    o_med <= med_d5;

end behavioral;