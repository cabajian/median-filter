library ieee;
use ieee.std_logic_1164.all;
use  ieee.numeric_std.all;

entity top is
    port(
        clk              :  in   std_logic;
        rst              :  in   std_logic;
        i_uart_rx        :  in   std_logic;
        o_uart_tx        :  out  std_logic;
        -- write address channel
        m_axi_awaddr     :  out  std_logic_vector(26  downto  0);
        m_axi_awvalid    :  out  std_logic;
        m_axi_awready    :  in   std_logic;
        -- write data channel
        m_axi_wdata      :  out  std_logic_vector(31  downto  0);
        m_axi_wstrb      :  out  std_logic_vector(3   downto  0);
        m_axi_wvalid     :  out  std_logic;
        m_axi_wready     :  in   std_logic;
        -- write/read response channel
        m_axi_bresp      :  in   std_logic_vector(1   downto  0); -- b'00 OKAY
        m_axi_bvalid     :  in   std_logic;
        m_axi_bready     :  out  std_logic;
        -- read address channel
        m_axi_araddr     :  out  std_logic_vector(26  downto  0);
        m_axi_arvalid    :  out  std_logic;
        m_axi_arready    :  in   std_logic;
        -- read data channel
        m_axi_rdata      :  in   std_logic_vector(31  downto  0);
        m_axi_rresp      :  in   std_logic_vector(1   downto  0);
        m_axi_rvalid     :  in   std_logic;
        m_axi_rready     :  out  std_logic
    );
end top;

architecture behavioral of top is

    signal rstn              : std_logic := '1';

    -- baud clock
    signal scount12          : unsigned (11 downto 0) := (others => '0');
    signal sclk_en_16_x_baud : std_logic := '0';
    
    -- uart rx
    signal m_axis_uart_rx_valid    : std_logic := '0';
    signal m_axis_uart_rx_data     : std_logic_vector(7 downto 0) := (others => '0');
    -- rx fifo
    signal m_fifo_rx_valid : std_logic := '0';
    signal m_fifo_rx_data  : std_logic_vector(7 downto 0) := (others => '0');
    signal s_fifo_rx_ready : std_logic := '0';
    signal fifo_rx_full  : std_logic := '0';
    -- axi stream signals
    signal nxt_m_axis_valid : std_logic := '0';
    signal m_axis_valid : std_logic := '0';
    signal m_axis_ready : std_logic := '0';
    signal s_axis_valid : std_logic := '0';
    signal s_axis_data  : std_logic_vector(7 downto 0) := (others => '0');
    signal s_axis_ready : std_logic := '0';
    -- tx fifo
    signal m_fifo_tx_valid : std_logic := '0';
    signal m_fifo_rx_ready : std_logic := '0';
    signal m_fifo_tx_data  : std_logic_vector(7 downto 0) := (others => '0');
    signal s_fifo_tx_ready : std_logic := '0';
    signal fifo_tx_full    : std_logic := '0';
    -- uart tx
    signal s_axis_uart_tx_ready    : std_logic := '0';
    
    -- data mover state machines    
    type twr_movestate is (idle, rdinfo, rstaddr, rdpixel, wrpixel);
    signal wr_movestate         : twr_movestate := idle;
    signal nxt_wr_movestate     : twr_movestate := idle;
    type trd_movestate is (idle, rstaddr, rdpixel);
    signal nxt_rd_movestate     : trd_movestate := idle;
    signal rd_movestate         : trd_movestate := idle;
    
    --
    signal nxt_axi_rst     : std_logic := '0';
    signal axi_rst         : std_logic := '0';
    signal nxt_rd_en       : std_logic := '0';
    signal rd_en           : std_logic := '0';
    signal axi_wr_complete : std_logic;
    signal axi_rd_complete : std_logic;
    signal bytes_stored    : unsigned(31 downto 0);
    
    --
    signal nxt_rdinfo_ready: std_logic := '0';
    signal rdinfo_ready    : std_logic := '0';
    signal nxt_rdinfo_cnt  : unsigned(3 downto 0) := (others => '0');
    signal rdinfo_cnt      : unsigned(3 downto 0) := (others => '0');
    signal nxt_num_rows    : std_logic_vector(15 downto 0) := (others => '0');
    signal num_rows        : std_logic_vector(15 downto 0) := (others => '0');
    signal nxt_num_cols    : std_logic_vector(15 downto 0) := (others => '0');
    signal num_cols        : std_logic_vector(15 downto 0) := (others => '0');
    signal nxt_img_size    : std_logic_vector(31 downto 0) := (others => '0');
    signal img_size        : std_logic_vector(31 downto 0) := (others => '0');
    
    
    -- axis fifo components
    component axis_data_fifo_0
        port (
            s_axis_aresetn : in std_logic;
            s_axis_aclk : in std_logic;
            s_axis_tvalid : in std_logic;
            s_axis_tready : out std_logic;
            s_axis_tdata : in std_logic_vector(7 downto 0);
            m_axis_tvalid : out std_logic;
            m_axis_tready : in std_logic;
            m_axis_tdata : out std_logic_vector(7 downto 0);
            almost_empty : out std_logic;
            almost_full : out std_logic
        );
    end component;
    component axis_data_fifo_1
        port (
            s_axis_aresetn : in std_logic;
            s_axis_aclk : in std_logic;
            s_axis_tvalid : in std_logic;
            s_axis_tready : out std_logic;
            s_axis_tdata : in std_logic_vector(7 downto 0);
            m_axis_tvalid : out std_logic;
            m_axis_tready : in std_logic;
            m_axis_tdata : out std_logic_vector(7 downto 0);
            almost_empty : out std_logic;
            almost_full : out std_logic
        );
    end component;

begin
    
    rstn <= not rst;

    -- ----------------------------------------------
    -- AXIS_UART_RX
    -- ----------------------------------------------
    axis_uart_rx_0 : entity work.AXIS_UART_RX
    port map (
        -- clocks and rx data
        CLK_100MHZ       => clk,
        clk_en_16_x_baud => sclk_en_16_x_baud,
        UART_RX          => i_uart_rx,
        -- master signals
        m_axis_valid     => m_axis_uart_rx_valid,
        m_axis_ready     => s_fifo_rx_ready,
        m_axis_data      => m_axis_uart_rx_data,
        -- fifo status
        almost_full      => fifo_rx_full
    );
     
    m_fifo_rx_ready <= m_axis_ready or rdinfo_ready;
    -- slave/master fifo rx interface
    axis_fifo_rx_inst : axis_data_fifo_0 port map (
        -- slave signals
        s_axis_aresetn => rstn,
        s_axis_aclk => clk,
        s_axis_tvalid => m_axis_uart_rx_valid,
        s_axis_tready => s_fifo_rx_ready,
        s_axis_tdata => m_axis_uart_rx_data,
        -- master signals
        m_axis_tvalid => m_fifo_rx_valid,
        m_axis_tready => m_fifo_rx_ready,
        m_axis_tdata => m_fifo_rx_data,
        -- fifo status
        almost_empty => open,
        almost_full => fifo_rx_full
    );
    
    -- ----------------------------------------------
    -- AXI Stream to Lite Conversion
    -- ----------------------------------------------
    axis_axi_conv_inst : entity work.axis_axi_conv port map (
        clk => clk,
        rst => axi_rst,
        -- axi stream
        m_axis_valid => m_axis_valid,
        m_axis_ready => m_axis_ready,
        m_axis_data => m_fifo_rx_data,
        s_axis_valid => s_axis_valid,
        s_axis_ready => s_axis_ready,
        s_axis_data => s_axis_data,
        -- axi lite
        -- wr
        m_axi_awaddr => m_axi_awaddr,
        m_axi_awvalid => m_axi_awvalid,
        m_axi_awready => m_axi_awready,
        m_axi_wdata => m_axi_wdata,
        m_axi_wstrb => m_axi_wstrb,
        m_axi_wvalid => m_axi_wvalid,
        m_axi_wready => m_axi_wready,
        m_axi_bresp => m_axi_bresp,
        m_axi_bvalid => m_axi_bvalid,
        m_axi_bready => m_axi_bready,
        -- rd
        m_axi_araddr => m_axi_araddr,
        m_axi_arvalid => m_axi_arvalid,
        m_axi_arready => m_axi_arready,
        m_axi_rdata => m_axi_rdata,
        m_axi_rresp => m_axi_rresp,
        m_axi_rvalid => m_axi_rvalid,
        m_axi_rready => m_axi_rready,
        -- control/status
        rd_en => rd_en,
        axi_wr_complete => axi_wr_complete,
        axi_rd_complete => axi_rd_complete,
        bytes_stored    => bytes_stored
    );
  
    s_axis_ready <= s_fifo_tx_ready and not fifo_tx_full;
    
    -- slave/master fifo tx interface
    axis_fifo_tx_inst : axis_data_fifo_1 port map (
        -- slave signals
        s_axis_aresetn => rstn,
        s_axis_aclk => clk,
        s_axis_tvalid => s_axis_valid,
        s_axis_tready => s_fifo_tx_ready,
        s_axis_tdata => s_axis_data(7 downto 0),
        -- master signals
        m_axis_tvalid => m_fifo_tx_valid,
        m_axis_tready => s_axis_uart_tx_ready,
        m_axis_tdata => m_fifo_tx_data,
        -- fifo status
        almost_empty => open,
        almost_full => fifo_tx_full
    );
    
    -- ----------------------------------------------
    -- AXIS_UART_TX
    -- ----------------------------------------------
    axis_uart_tx_0 : entity work.AXIS_UART_TX
    port map (
        -- clocks and rx data
        CLK_100MHZ       => clk,
        clk_en_16_x_baud => sclk_en_16_x_baud,
        UART_TX          => o_uart_tx,
        -- slave signals
        s_axis_valid     => m_fifo_tx_valid,
        s_axis_ready     => s_axis_uart_tx_ready,
        s_axis_data      => m_fifo_tx_data
    );
    
    -- ----------------------------------------------
    -- Combintational process
    -- ----------------------------------------------
    process(all) begin
        -- image mover state machines
        nxt_wr_movestate <= wr_movestate;
        nxt_rd_movestate <= rd_movestate;
        nxt_m_axis_valid <= '0';
        nxt_axi_rst      <= '0';
        nxt_rd_en        <= '0';
        nxt_rdinfo_ready <= '0';
        if (rst = '1') then
            nxt_wr_movestate <= idle;
            nxt_rd_movestate <= idle;
            nxt_axi_rst      <= '1';
        else
            -- move image to mem
            case wr_movestate is
                when idle    => if m_fifo_rx_valid = '1' and m_fifo_rx_data = X"01" then
                                    nxt_wr_movestate <= rdinfo;
                                end if;
                                
                when rdinfo  => if m_fifo_rx_valid = '1' and rdinfo_cnt > X"8" then
                                    nxt_wr_movestate <= rstaddr;
                                    nxt_axi_rst <= '1';
                                end if;
                                nxt_rdinfo_ready <= '1';
                                
                when rstaddr => nxt_wr_movestate <= rdpixel;

                when rdpixel => if m_fifo_rx_valid = '1' then
                                    nxt_wr_movestate <= wrpixel;
                                    nxt_m_axis_valid <= '1';
                                end if;
                                
                when wrpixel => if axi_wr_complete = '1' and bytes_stored = unsigned(img_size) then
                                    nxt_wr_movestate <= idle;
                                else
                                    nxt_wr_movestate <= rdpixel;
                                end if;
            end case;
            -- move image from mem
            case rd_movestate is
                when idle    => if m_fifo_rx_valid = '1' and m_fifo_rx_data = X"02" then
                                    nxt_rd_movestate <= rstaddr;
                                    nxt_axi_rst <= '1';
                                end if;
                                
                when rstaddr => nxt_rd_movestate <= rdpixel;
                                nxt_rd_en <= '1';
                
                when rdpixel => if axi_rd_complete = '1' and bytes_stored = 0 then
                                    nxt_rd_movestate <= idle;
                                else
                                    nxt_rd_en <= '1';
                                end if;
            end case;
        end if;
        
        
        -- rdinfo counter
        nxt_rdinfo_cnt <= rdinfo_cnt;
        if rst = '1' or axi_rst = '1' then
            nxt_rdinfo_cnt <= (others => '0');
        elsif wr_movestate = rdinfo and m_fifo_rx_valid = '1' then
            nxt_rdinfo_cnt <= rdinfo_cnt + 1;
        end if;
        
        nxt_num_rows <= num_rows;
        nxt_num_cols <= num_cols;
        nxt_img_size <= img_size;
        if wr_movestate = rdinfo then
            if nxt_rdinfo_cnt = X"1" then
                nxt_num_rows(7 downto 0)   <= m_fifo_rx_data;
            elsif nxt_rdinfo_cnt = X"2" then
                nxt_num_rows(15 downto 8)  <= m_fifo_rx_data;
            elsif nxt_rdinfo_cnt = X"3" then
                nxt_num_cols(7 downto 0)   <= m_fifo_rx_data;
            elsif nxt_rdinfo_cnt = X"4" then
                nxt_num_cols(15 downto 8)  <= m_fifo_rx_data;
            elsif nxt_rdinfo_cnt = X"5" then
                nxt_img_size(7 downto 0)   <= m_fifo_rx_data;
            elsif nxt_rdinfo_cnt = X"6" then
                nxt_img_size(15 downto 8)  <= m_fifo_rx_data;
            elsif nxt_rdinfo_cnt = X"7" then
                nxt_img_size(23 downto 16) <= m_fifo_rx_data;
            elsif nxt_rdinfo_cnt = X"8" then
                nxt_img_size(31 downto 24) <= m_fifo_rx_data;
            end if;
        end if;
        
        
        
    end process;
    
    -- ----------------------------------------------
    -- Sequential process
    -- ----------------------------------------------
    process(clk) begin
        if rising_edge(clk) then
            wr_movestate <= nxt_wr_movestate;
            rd_movestate <= nxt_rd_movestate;
            m_axis_valid <= nxt_m_axis_valid;
            axi_rst <= nxt_axi_rst;
            rd_en <= nxt_rd_en;
            rdinfo_cnt <= nxt_rdinfo_cnt;
            rdinfo_ready <= nxt_rdinfo_ready;
            num_rows <= nxt_num_rows;
            num_cols <= nxt_num_cols;
            img_size <= nxt_img_size;
        end if;
    end process;
    
    -- ----------------------------------------------
    -- baud clock
    -- ----------------------------------------------
    sclk_en_16_x_baud <= '1' when scount12 = X"36" else '0';

    process(clk)
    begin
        if clk'event and clk = '1' then
            if rst = '1' then
                scount12 <= (others => '0');
            -- if scount = X"28B" then      --  for    9600 baud : 100 MHZ / (16 * 9600)   = 651 => 0x28B /
            elsif scount12 = X"36" then     --  for  115200 baud : 100 MHZ / (16 * 115200) =  54 => 0x 36 /
                scount12 <= (others => '0');
            else
                scount12 <= scount12 + 1;
            end if;
        end if;
    end process;
    
end behavioral;
