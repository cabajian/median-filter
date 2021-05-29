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
    signal nxt_m_fifo_rx_ready : std_logic := '0';
    signal m_fifo_rx_ready : std_logic := '0';
    signal m_fifo_rx_data  : std_logic_vector(7 downto 0) := (others => '0');
    signal s_fifo_rx_ready : std_logic := '0';
    signal fifo_rx_full  : std_logic := '0';
    -- axi stream signals
    signal nxt_m_axis_valid : std_logic := '0';
    signal m_axis_valid : std_logic := '0';
    signal nxt_m_axis_data : std_logic_vector(7 downto 0) := (others => '0');
    signal m_axis_data : std_logic_vector(7 downto 0) := (others => '0');
    signal m_axis_ready : std_logic := '0';
    signal nxt_axis_ready : std_logic := '0';
    signal axis_ready : std_logic := '0';
    signal s_axis_valid : std_logic := '0';
    signal nxt_s_fifo_tx_valid : std_logic := '0';
    signal s_fifo_tx_valid : std_logic := '0';
    signal s_axis_data  : std_logic_vector(7 downto 0) := (others => '0');
    signal s_axis_ready : std_logic := '0';
    -- tx fifo
    signal m_fifo_tx_valid : std_logic := '0';
    signal m_fifo_tx_data  : std_logic_vector(7 downto 0) := (others => '0');
    signal s_fifo_tx_ready : std_logic := '0';
    signal fifo_tx_full    : std_logic := '0';
    -- uart tx
    signal s_axis_uart_tx_ready    : std_logic := '0';
    
    -- axi address signals
    signal nxt_axi_rd_bank : std_logic := '0';
    signal axi_rd_bank : std_logic := '0';
    signal nxt_axi_awaddr : std_logic_vector(26 downto 0) := (others => '0');
    signal axi_awaddr     : std_logic_vector(26 downto 0) := (others => '0');
    signal nxt_axi_araddr : std_logic_vector(26 downto 0) := (others => '0');
    signal axi_araddr     : std_logic_vector(26 downto 0) := (others => '0');
    
    -- data mover state machines  
    type tctrl_movestate is (idle, read_in, filter, send_raw, send_filt);
    signal nxt_ctrl_movestate     : tctrl_movestate := idle;
    signal ctrl_movestate         : tctrl_movestate := idle;    
    type twr_movestate is (idle, rdinfo, rstaddr, rdpixel, wrpixel, complete);
    signal wr_movestate         : twr_movestate := idle;
    signal nxt_wr_movestate     : twr_movestate := idle;
    type trd_movestate is (idle, rstaddr, rdpixel, complete);
    signal nxt_rd_movestate     : trd_movestate := idle;
    signal rd_movestate         : trd_movestate := idle;
    type tfilt_movestate is (idle, rstaddr, rdpixel1, ldpixel1, rdpixel2, ldpixel2, rdpixel3, ldpixel3, get_median, wrpixel, complete);
    signal nxt_filt_movestate     : tfilt_movestate := idle;
    signal filt_movestate         : tfilt_movestate := idle;
    
    -- status and control signals
    signal nxt_axi_rst     : std_logic := '0';
    signal axi_rst         : std_logic := '0';
    signal nxt_rd_en       : std_logic := '0';
    signal rd_en           : std_logic := '0';
    signal axi_wr_complete : std_logic;
    signal axi_rd_complete : std_logic;
    signal nxt_byte_cnt    : integer;
    signal byte_cnt        : integer;
    signal nxt_wrimg_en : std_logic;
    signal nxt_filter_en : std_logic;
    signal nxt_rdimg_en : std_logic;
    
    -- rdinfo control signals (reading first 8 bytes of image header)
    signal nxt_rdinfo_cnt  : unsigned(3 downto 0)  := (others => '0');
    signal rdinfo_cnt      : unsigned(3 downto 0)  := (others => '0');
    -- rows, cols, image size
    signal nxt_num_rows    : unsigned(15 downto 0) := (others => '0');
    signal num_rows        : unsigned(15 downto 0) := (others => '0');
    signal nxt_num_cols    : unsigned(15 downto 0) := (others => '0');
    signal num_cols        : unsigned(15 downto 0) := (others => '0');
    signal nxt_img_size    : unsigned(31 downto 0) := (others => '0');
    signal img_size        : unsigned(31 downto 0) := (others => '0');
    
    -- median signals
    signal nxt_med_data_vld : std_logic := '0';
    signal med_data_vld : std_logic := '0';
    signal median_data : unsigned(7 downto 0);
    signal nxt_med_wait_cnt : unsigned(2 downto 0);
    signal med_wait_cnt : unsigned(2 downto 0);
    
    
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
        m_axis_data => m_axis_data,
        s_axis_valid => s_axis_valid,
        s_axis_ready => s_axis_ready,
        s_axis_data => s_axis_data,
        -- axi lite
        -- wr
        in_axi_awaddr => axi_awaddr,
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
        in_axi_araddr => axi_araddr,
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
        axi_rd_complete => axi_rd_complete
    );
  
    s_axis_ready <= s_fifo_tx_ready and not fifo_tx_full;
    
    -- slave/master fifo tx interface
    axis_fifo_tx_inst : axis_data_fifo_1 port map (
        -- slave signals
        s_axis_aresetn => rstn,
        s_axis_aclk => clk,
        s_axis_tvalid => s_fifo_tx_valid,
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
    -- MEDIAN FILTER
    -- ----------------------------------------------
    median_top_inst : entity work.median_top
    port map (
        clk => clk,
        rst => rst,
        i_data_vld => med_data_vld,
        i_data => unsigned(s_axis_data(7 downto 0)),
        o_median => median_data
    );
    
    -- ----------------------------------------------
    -- Combintational process
    -- ----------------------------------------------
    process(all) begin
    
        -- IMAGE MOVER CONTROL
        nxt_ctrl_movestate   <= ctrl_movestate;
        nxt_m_fifo_rx_ready <= '0';
        nxt_wrimg_en        <= '0';
        nxt_filter_en       <= '0';
        nxt_rdimg_en        <= '0';
        nxt_axi_rd_bank     <= '0';
        if rst = '1' then
            nxt_ctrl_movestate   <= idle;
            nxt_axi_awaddr <= (others => '0');
            nxt_axi_araddr <= (others => '0');
        else
            case ctrl_movestate is
                -- wait for command
                when idle      => if m_fifo_rx_valid = '1' and m_fifo_rx_data = X"01" then
                                      nxt_ctrl_movestate <= read_in;
                                  elsif m_fifo_rx_valid = '1' and m_fifo_rx_data = X"02" then
                                      nxt_ctrl_movestate <= send_raw;
                                  elsif m_fifo_rx_valid = '1' and m_fifo_rx_data = X"03" then
                                      nxt_ctrl_movestate <= send_filt;
                                  elsif m_fifo_rx_valid = '1' and m_fifo_rx_data = X"04" then
                                      nxt_ctrl_movestate <= filter;
                                  end if;
                                  nxt_m_fifo_rx_ready <= '1'; -- read fifo byte
                                  
                -- 
                when read_in   => if wr_movestate = complete then
                                      nxt_ctrl_movestate <= idle;
                                  end if;
                                  nxt_wrimg_en <= '1';
                when filter    => if filt_movestate = complete then
                                      nxt_ctrl_movestate <= idle;
                                  end if;
                                  nxt_filter_en <= '1';
                when send_raw  => if rd_movestate = complete then
                                      nxt_ctrl_movestate <= idle;
                                  end if;
                                  nxt_rdimg_en <= '1';
                                  nxt_axi_rd_bank <= '0';
                when send_filt => if rd_movestate = complete then
                                      nxt_ctrl_movestate <= idle;
                                  end if;
                                  nxt_rdimg_en <= '1';
                                  nxt_axi_rd_bank <= '1';
            end case;
        end if;
    
    
        -- WRITE IMAGE TO MEM
        nxt_wr_movestate    <= wr_movestate;
        nxt_m_axis_valid    <= '0';
        nxt_m_axis_data     <= m_axis_data;
        nxt_axi_rst         <= '0';
        nxt_axi_awaddr      <= axi_awaddr;
        nxt_byte_cnt    <= byte_cnt;
        if rst = '1' then
            nxt_wr_movestate <= idle;
            nxt_axi_rst      <= '1';
            nxt_m_axis_data  <= (others => '0');
        else
            case wr_movestate is
                -- wait for enable
                when idle    => if nxt_wrimg_en = '1' then
                                    nxt_wr_movestate <= rdinfo;
                                end if;
                
                -- read image data from RX
                when rdinfo  => if m_fifo_rx_valid = '1' and rdinfo_cnt = X"7" then
                                    nxt_wr_movestate <= rstaddr;
                                end if;
                                nxt_m_fifo_rx_ready <= '1'; -- read fifo byte
                
                -- reset address
                when rstaddr => nxt_wr_movestate <= rdpixel;
                                nxt_axi_rst <= '1';
                                nxt_axi_awaddr <= (others => '0');
                                nxt_byte_cnt <= 0;

                -- read pixel from RX
                when rdpixel => if m_fifo_rx_valid = '1' then
                                    nxt_wr_movestate <= wrpixel;
                                end if;
                                nxt_m_axis_valid <= m_fifo_rx_valid;
                                nxt_m_axis_data <= m_fifo_rx_data;
                
                -- write pixel to memory
                when wrpixel => if axi_wr_complete = '1' and byte_cnt = img_size-1 then
                                    nxt_wr_movestate <= complete;
                                elsif axi_wr_complete = '1' then
                                    nxt_wr_movestate <= rdpixel;
                                    nxt_byte_cnt <= byte_cnt + 1;
                                    nxt_axi_awaddr <= std_logic_vector(unsigned(axi_awaddr) + 4);
                                else
                                    nxt_m_fifo_rx_ready <= m_axis_ready; -- read rx fifo data
                                end if;
                -- complete
                when complete => nxt_wr_movestate <= idle;
            end case;
        end if;
        
        
        -- READ IMAGE FROM MEM
        nxt_rd_movestate    <= rd_movestate;
        nxt_rd_en           <= '0';
        nxt_axi_araddr      <= axi_araddr;
        nxt_s_fifo_tx_valid <= '0';
        if rst = '1' then
            nxt_rd_movestate <= idle;
            -- axi_rst set in write state reset condition
        else
            case rd_movestate is
                -- wait for enable
                when idle    => if nxt_rdimg_en = '1' then
                                    nxt_rd_movestate <= rstaddr;
                                end if;
                
                -- reset address, enable reads, clear byte counter
                when rstaddr => nxt_rd_movestate <= rdpixel;
                                nxt_axi_rst <= '1';
                                nxt_byte_cnt <= 0;
                                if axi_rd_bank = '1' then
                                    -- skip the first six bytes of bad medians. set to filter bank.
                                    nxt_axi_araddr(7 downto 0) <= X"18";
                                    nxt_axi_araddr(25 downto 8) <= (others => '0');
                                    nxt_axi_araddr(26) <= '1';
                                else
                                    nxt_axi_araddr <= (others => '0');
                                end if;
                
                -- read pixel from memory
                when rdpixel => nxt_rd_en <= '1';
                                if axi_rd_bank = '1' then
                                    if axi_rd_complete = '1' and byte_cnt = img_size-1-num_cols-num_cols then
                                        nxt_rd_movestate <= complete;
                                        nxt_byte_cnt   <= 0;
                                        nxt_rd_en <= '0';
                                    elsif axi_rd_complete = '1' then
                                        nxt_byte_cnt <= byte_cnt + 1;
                                        nxt_axi_araddr <= std_logic_vector(unsigned(axi_araddr) + 4);
                                    end if;
                                else
                                    if axi_rd_complete = '1' and byte_cnt = img_size-1 then
                                        nxt_rd_movestate <= complete;
                                        nxt_byte_cnt   <= 0;
                                        nxt_rd_en <= '0';
                                    elsif axi_rd_complete = '1' then
                                        nxt_byte_cnt <= byte_cnt + 1;
                                        nxt_axi_araddr <= std_logic_vector(unsigned(axi_araddr) + 4);
                                    end if;
                                end if;
                                nxt_s_fifo_tx_valid <= s_axis_valid;
                                
                -- complete
                when complete => nxt_rd_movestate <= idle;
            end case;
        end if;
        
        
        -- FILTER IMAGE
        nxt_filt_movestate <= filt_movestate;
        nxt_med_data_vld <= '0';
        nxt_med_wait_cnt <= med_wait_cnt;
        if rst = '1' then
            nxt_filt_movestate <= idle;
            -- axi_rst set in write state reset condition
        else
            case filt_movestate is
                -- wait for enable
                when idle    => if nxt_filter_en = '1' then
                                    nxt_filt_movestate <= rstaddr;
                                end if;
                
                -- reset address
                when rstaddr => nxt_filt_movestate <= rdpixel1;
                                nxt_axi_rst <= '1';
                                -- write to bank 1, skip first row of pixels
                                -- multiply by 4 since our addresses are multiples of 4
                                nxt_axi_awaddr(15 downto 0) <= std_logic_vector(num_cols);
                                nxt_axi_awaddr(25 downto 0) <= nxt_axi_awaddr(25 downto 0) sll 2;
                                nxt_axi_awaddr(26) <= '1';
                                nxt_byte_cnt <= 0;
                                nxt_med_wait_cnt <= (others => '0');
                
                -- read pixel1 from memory
                when rdpixel1 => if axi_rd_complete = '1' then
                                     nxt_filt_movestate <= ldpixel1;
                                 else
                                     nxt_rd_en <= '1';
                                     -- set middle read address
                                     nxt_axi_araddr <= std_logic_vector(to_unsigned(byte_cnt,27)+num_cols) sll 2; -- 4x
                                 end if;
                -- load pixel1 into the filter
                when ldpixel1 => nxt_filt_movestate <= rdpixel2;
                                 nxt_med_data_vld <= '1';
                                 
                -- read pixel2 from memory
                when rdpixel2 => if axi_rd_complete = '1' then
                                     nxt_filt_movestate <= ldpixel2;
                                 else
                                     nxt_rd_en <= '1';
                                     -- set top read address
                                     nxt_axi_araddr <= std_logic_vector(to_unsigned(byte_cnt,27)) sll 2; -- 4x
                                 end if;
                -- load pixel2 into the filter
                when ldpixel2 => nxt_filt_movestate <= rdpixel3;
                                 nxt_med_data_vld <= '1';

                -- read pixel3 from memory
                when rdpixel3 => if axi_rd_complete = '1' then
                                     nxt_filt_movestate <= ldpixel3;
                                 else
                                     nxt_rd_en <= '1';
                                     -- set bottom read address
                                     nxt_axi_araddr <= std_logic_vector(to_unsigned(byte_cnt,27)+num_cols+num_cols) sll 2; -- 4x
                                 end if;
                -- load pixel3 into the filter (starts a filter processing cycle)
                when ldpixel3 => nxt_filt_movestate <= get_median;
                                 nxt_med_data_vld <= '1';
                                 
                when get_median => nxt_filt_movestate <= wrpixel;
                                   nxt_m_axis_valid <= '1';
                                   nxt_m_axis_data <= std_logic_vector(median_data);
                
                -- write fitltered pixel to memory
                when wrpixel => -- incomplete below here
                                if axi_wr_complete = '1' and byte_cnt = img_size-num_cols-num_cols-1+5 then --(img_size-(num_cols+num_cols+num_rows+num_rows)+4-1) then
                                    -- TODO: push pipeline for an extra 5 cycles to get the last median values
                                     nxt_filt_movestate <= complete;
                                elsif axi_wr_complete = '1' then
                                    nxt_filt_movestate <= rdpixel1;
                                    nxt_axi_awaddr <= std_logic_vector(unsigned(axi_awaddr)+4);
                                    nxt_byte_cnt <= byte_cnt + 1;
                                end if;
                                                
                -- complete
                when complete => nxt_filt_movestate <= idle;
            end case;
        end if;
        
        
        -- rdinfo counter
        nxt_rdinfo_cnt <= rdinfo_cnt;
        if rst = '1' or axi_rst = '1' then
            nxt_rdinfo_cnt <= (others => '0');
        elsif wr_movestate = rdinfo and m_fifo_rx_valid = '1' then
            nxt_rdinfo_cnt <= rdinfo_cnt + 1;
        end if;
        -- rdinfo store rows, cols, size
        nxt_num_rows <= num_rows;
        nxt_num_cols <= num_cols;
        nxt_img_size <= img_size;
        if wr_movestate = rdinfo then
            if nxt_rdinfo_cnt = X"1" then
                nxt_num_rows(7 downto 0)   <= unsigned(m_fifo_rx_data);
            elsif nxt_rdinfo_cnt = X"2" then
                nxt_num_rows(15 downto 8)  <= unsigned(m_fifo_rx_data);
            elsif nxt_rdinfo_cnt = X"3" then
                nxt_num_cols(7 downto 0)   <= unsigned(m_fifo_rx_data);
            elsif nxt_rdinfo_cnt = X"4" then
                nxt_num_cols(15 downto 8)  <= unsigned(m_fifo_rx_data);
            elsif nxt_rdinfo_cnt = X"5" then
                nxt_img_size(7 downto 0)   <= unsigned(m_fifo_rx_data);
            elsif nxt_rdinfo_cnt = X"6" then
                nxt_img_size(15 downto 8)  <= unsigned(m_fifo_rx_data);
            elsif nxt_rdinfo_cnt = X"7" then
                nxt_img_size(23 downto 16) <= unsigned(m_fifo_rx_data);
            elsif nxt_rdinfo_cnt = X"8" then
                nxt_img_size(31 downto 24) <= unsigned(m_fifo_rx_data);
            end if;
        end if;
        
        
        
    end process;
    
    -- ----------------------------------------------
    -- Sequential process
    -- ----------------------------------------------
    process(clk) begin
        if rising_edge(clk) then
            ctrl_movestate  <= nxt_ctrl_movestate;
            wr_movestate    <= nxt_wr_movestate;
            rd_movestate    <= nxt_rd_movestate;
            filt_movestate  <= nxt_filt_movestate;
            axi_rd_bank     <= nxt_axi_rd_bank;
            axi_awaddr      <= nxt_axi_awaddr;
            axi_araddr      <= nxt_axi_araddr;
            axi_rst         <= nxt_axi_rst;
            rd_en           <= nxt_rd_en;
            m_axis_valid    <= nxt_m_axis_valid;
            m_axis_data     <= nxt_m_axis_data;
            m_fifo_rx_ready <= nxt_m_fifo_rx_ready;
            s_fifo_tx_valid <= nxt_s_fifo_tx_valid;
            byte_cnt        <= nxt_byte_cnt;
            rdinfo_cnt      <= nxt_rdinfo_cnt;
            num_rows        <= nxt_num_rows;
            num_cols        <= nxt_num_cols;
            img_size        <= nxt_img_size;
            med_data_vld    <= nxt_med_data_vld;
            med_wait_cnt    <= nxt_med_wait_cnt;
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
