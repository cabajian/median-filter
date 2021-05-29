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
        axi_rd_complete  :  out  std_logic;
        bytes_stored     :  out  unsigned(31 downto 0)
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
    signal nxt_axi_awaddr  : std_logic_vector(26 downto 0) := (others => '0');
    signal axi_awaddr      : std_logic_vector(26 downto 0) := (others => '0');
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
    signal nxt_axi_araddr  : std_logic_vector(26 downto 0) := (others => '0');
    signal axi_araddr      : std_logic_vector(26 downto 0) := (others => '0');
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
    -- bytes stored
    signal nxt_num_stored  : unsigned(31 downto 0) := (others => '0');
    signal num_stored      : unsigned(31 downto 0) := (others => '0');
begin

    -- ----------------------------------------------
    -- Combinational logic
    -- ----------------------------------------------    
    process(all) begin
        -- write state machine
        nxt_wrstate         <= wrstate;
        nxt_axi_awaddr      <= axi_awaddr;
        nxt_axi_awvalid     <= '0';
        nxt_axi_wstrb       <= "0000";
        nxt_axi_wvalid      <= '0';
        nxt_axi_wdata       <= (others => '0');
        nxt_axi_bready      <= '0';
        nxt_wr_complete     <= '0';
        if (rst = '1') then
            nxt_wrstate    <= idle;
            nxt_axi_awaddr <= (others => '0');
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
                                    elsif (m_axi_bvalid = '1') then
                                        nxt_wrstate <= wraddr;
                                    end if;
                                    -- outputs
                                    nxt_axi_bready  <= '1';
                                    
                when wrcomplete =>  nxt_wrstate     <= idle;
                                    -- outputs
                                    nxt_axi_awaddr  <= std_logic_vector(unsigned(axi_awaddr)+4);
                                    nxt_wr_complete <= '1';
            end case;
        end if;
        
        
        -- read state machine 
        nxt_rdstate         <= rdstate;       
        nxt_axi_araddr      <= axi_araddr;
        nxt_axi_arvalid     <= '0';
        nxt_axi_rready      <= '0';
        nxt_rd_complete     <= '0';
        if (rst = '1') then
            nxt_rdstate     <= idle;
            nxt_axi_araddr  <= (others => '0');
        else
            case rdstate is
                when idle =>        if (bytes_stored > 0 and rd_en = '1') then
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
                                    end if;
                                    
                when rdcomplete =>  nxt_rdstate     <= idle;
                                    -- outputs
                                    nxt_axi_araddr  <= std_logic_vector(unsigned(axi_araddr)+4);
                                    nxt_rd_complete <= '1';
            end case;
        end if;
             
        -- update number of bytes stored in mem
        nxt_num_stored  <= num_stored;
        if wrstate = wrcomplete then
            if rdstate /= rdcomplete then
                nxt_num_stored <= num_stored + 1;
            end if;
        elsif rdstate = rdcomplete then
            nxt_num_stored <= num_stored - 1;
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
            axi_awaddr    <= nxt_axi_awaddr;
            axi_awvalid   <= nxt_axi_awvalid;
            axi_wstrb     <= nxt_axi_wstrb;
            axi_wvalid    <= nxt_axi_wvalid;
            axi_wdata     <= nxt_axi_wdata;
            -- write response
            axi_bready    <= nxt_axi_bready;
            -- read
            axi_araddr    <= nxt_axi_araddr;
            axi_arvalid   <= nxt_axi_arvalid;
            axi_rvalid_fb <= m_axi_rvalid;
            axi_rready    <= nxt_axi_rready;
            -- wr/rd complete
            wr_complete <= nxt_wr_complete;
            rd_complete <= nxt_rd_complete;
            --
            num_stored  <= nxt_num_stored;
        end if;
    end process;
    
    
    -- ----------------------------------------------
    -- Outputs
    -- ----------------------------------------------
    -- wr
    m_axi_awaddr  <= axi_awaddr;
    m_axi_awvalid <= axi_awvalid;
    m_axi_wstrb   <= axi_wstrb;
    m_axi_wvalid  <= axi_wvalid;
    m_axi_wdata   <= (31 downto 8 => '0') & axi_wdata;
    m_axis_ready  <= m_axi_wready;
    m_axi_bready  <= axi_bready;    
    -- rd
    m_axi_araddr  <= axi_araddr;
    m_axi_arvalid <= axi_arvalid;
    s_axis_valid  <= rd_complete;
    s_axis_data   <= m_axi_rdata(7 downto 0);
    m_axi_rready  <= axi_rready;
    --
    axi_wr_complete <= wr_complete;
    axi_rd_complete <= rd_complete;
    bytes_stored    <= num_stored;

end behavioral;