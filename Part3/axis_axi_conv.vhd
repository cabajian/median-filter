library ieee;
use ieee.std_logic_1164.all;
use  ieee.numeric_std.all;

entity axis_axi_conv is
    port(
        clk              :  in   std_logic;
        rst              :  in   std_logic;
        
        -- AXI Stream signals
        m_axis_valid     :  in   std_logic;
        m_axis_ready     :  out  std_logic;
        m_axis_data      :  in   std_logic_vector(7 downto 0);
        s_axis_valid     :  out  std_logic;
        s_axis_ready     :  in   std_logic;
        s_axis_data      :  out  std_logic_vector(7 downto 0);
        
        -- AXI Lite signals
        -- write address
        in_axi_awaddr    :  in   std_logic_vector(26 downto 0);
        m_axi_awaddr     :  out  std_logic_vector(26 downto 0);
        m_axi_awvalid    :  out  std_logic;
        m_axi_awready    :  in   std_logic;
        -- write data
        m_axi_wdata      :  out  std_logic_vector(31  downto  0);
        m_axi_wstrb      :  out  std_logic_vector(3   downto  0);
        m_axi_wvalid     :  out  std_logic;
        m_axi_wready     :  in   std_logic;
        -- write/read response channel
        m_axi_bresp      :  in   std_logic_vector(1   downto  0); -- b'00 OKAY
        m_axi_bvalid     :  in   std_logic;
        m_axi_bready     :  out  std_logic;
        -- read address channel
        in_axi_araddr    :  in   std_logic_vector(26 downto 0);
        m_axi_araddr     :  out  std_logic_vector(26  downto  0);
        m_axi_arvalid    :  out  std_logic;
        m_axi_arready    :  in   std_logic;
        -- read data channel
        m_axi_rdata      :  in   std_logic_vector(31  downto  0);
        m_axi_rresp      :  in   std_logic_vector(1   downto  0);
        m_axi_rvalid     :  in   std_logic;
        m_axi_rready     :  out  std_logic;
        
        -- read control
        rd_en            :  in   std_logic;
        -- write/read complete strobes
        axi_wr_complete  :  out  std_logic;
        axi_rd_complete  :  out  std_logic
    );
end axis_axi_conv;


architecture behavioral of axis_axi_conv is
    -- state machines
    type twrstate is (idle, wraddr, wrdata, wrresp, wrcomplete);
    signal nxt_wrstate     : twrstate;
    signal wrstate         : twrstate;
    type trdstate is (idle, rdaddr, rddata, rdwait, rdcomplete);
    signal nxt_rdstate     : trdstate;
    signal rdstate         : trdstate;
    -- write
    signal nxt_axi_awvalid : std_logic := '0';
    signal axi_awvalid     : std_logic := '0';
    signal nxt_axi_wstrb   : std_logic_vector(3 downto 0) := "0000";
    signal axi_wstrb       : std_logic_vector(3 downto 0) := "0000";
    signal nxt_axi_wvalid  : std_logic := '0';
    signal axi_wvalid      : std_logic := '0';
    signal nxt_axi_wdata   : std_logic_vector(7 downto 0) := (others => '0');
    signal axi_wdata       : std_logic_vector(7 downto 0) := (others => '0');
    -- write response
    signal nxt_axi_bready  : std_logic := '0';
    signal axi_bready      : std_logic := '0';
    -- read
    signal nxt_axi_arvalid : std_logic := '0';
    signal axi_arvalid     : std_logic := '0';
    signal axi_rvalid_fb   : std_logic := '0';
    signal nxt_axi_rready  : std_logic := '0';
    signal axi_rready      : std_logic := '0';
    -- complete signals
    signal nxt_wr_complete : std_logic := '0';
    signal wr_complete     : std_logic := '0';
    signal nxt_rd_complete : std_logic := '0';
    signal rd_complete     : std_logic := '0';
begin

    -- ----------------------------------------------
    -- Combinational logic
    -- ----------------------------------------------    
    process(all) begin
        -- write state machine
        nxt_wrstate         <= wrstate;
        nxt_axi_awvalid     <= '0';
        nxt_axi_wstrb       <= "0000";
        nxt_axi_wvalid      <= '0';
        nxt_axi_wdata       <= (others => '0');
        nxt_axi_bready      <= '0';
        nxt_wr_complete     <= '0';
        if (rst = '1') then
            nxt_wrstate    <= idle;
        else
            case wrstate is
                when idle =>        if (m_axis_valid = '1') then
                                        nxt_wrstate <= wraddr;
                                    end if;
                                    
                when wraddr =>      if (m_axi_awready = '1') then
                                        nxt_wrstate <= wrdata;
                                    end if;
                                    -- outputs
                                    nxt_axi_awvalid <= '1';
                                    nxt_axi_wdata   <= m_axis_data; -- lock in data in case it changes
                                    
                when wrdata =>      if (m_axi_wready = '1') then
                                        nxt_wrstate <= wrresp;
                                    end if;
                                    -- outputs
                                    nxt_axi_wstrb   <= "0001";
                                    nxt_axi_wvalid  <= '1';
                                    nxt_axi_wdata   <= axi_wdata;
                                    
                when wrresp =>      if (m_axi_bvalid = '1' and m_axi_bresp = "00") then
                                        nxt_wrstate <= wrcomplete;
                                        -- outputs
                                        nxt_wr_complete <= '1';
                                    elsif (m_axi_bvalid = '1') then
                                        nxt_wrstate <= wraddr;
                                    end if;
                                    -- outputs
                                    nxt_axi_bready  <= '1';
                                    
                when wrcomplete =>  nxt_wrstate     <= idle;
            end case;
        end if;
        
        
        -- read state machine 
        nxt_rdstate         <= rdstate;       
        nxt_axi_arvalid     <= '0';
        nxt_axi_rready      <= '0';
        nxt_rd_complete     <= '0';
        if (rst = '1') then
            nxt_rdstate     <= idle;
        else
            case rdstate is
                when idle =>        if (rd_en = '1') then
                                        nxt_rdstate <= rdaddr;
                                    end if;
                                    
                when rdaddr =>      if (m_axi_arready = '1') then
                                        nxt_rdstate <= rddata;
                                    end if;
                                    -- outputs
                                    nxt_axi_arvalid <= '1';
                                    
                when rddata =>      if (m_axi_rvalid = '1' and m_axi_rresp = "00") then
                                        nxt_rdstate <= rdwait;
                                    elsif (m_axi_rvalid = '1') then
                                        nxt_rdstate <= rdaddr;
                                    end if;
                                    -- outputs
                                    nxt_axi_rready  <= '1';
                                    
                when rdwait =>      if (s_axis_ready = '1') then
                                        nxt_rdstate <= rdcomplete;
                                        -- outputs
                                        nxt_rd_complete <= '1';
                                    end if;
                                    
                when rdcomplete =>  nxt_rdstate     <= idle;
            end case;
        end if;
    end process;

    -- registers
    process(clk)
    begin
        if rising_edge(clk) then
            -- states
            wrstate <= nxt_wrstate;
            rdstate <= nxt_rdstate;
            -- write
            axi_awvalid   <= nxt_axi_awvalid;
            axi_wstrb     <= nxt_axi_wstrb;
            axi_wvalid    <= nxt_axi_wvalid;
            axi_wdata     <= nxt_axi_wdata;
            -- write response
            axi_bready    <= nxt_axi_bready;
            -- read
            axi_arvalid   <= nxt_axi_arvalid;
            axi_rvalid_fb <= m_axi_rvalid;
            axi_rready    <= nxt_axi_rready;
            -- wr/rd complete
            wr_complete <= nxt_wr_complete;
            rd_complete <= nxt_rd_complete;
        end if;
    end process;
    
    
    -- ----------------------------------------------
    -- Outputs
    -- ----------------------------------------------
    -- wr
    m_axi_awaddr  <= in_axi_awaddr;
    m_axi_awvalid <= axi_awvalid;
    m_axi_wstrb   <= axi_wstrb;
    m_axi_wvalid  <= axi_wvalid;
    m_axi_wdata   <= (31 downto 8 => '0') & axi_wdata;
    m_axis_ready  <= m_axi_wready;
    m_axi_bready  <= axi_bready;    
    -- rd
    m_axi_araddr  <= in_axi_araddr;
    m_axi_arvalid <= axi_arvalid;
    s_axis_valid  <= rd_complete;
    s_axis_data   <= m_axi_rdata(7 downto 0);
    m_axi_rready  <= axi_rready;
    --
    axi_wr_complete <= wr_complete;
    axi_rd_complete <= rd_complete;

end behavioral;