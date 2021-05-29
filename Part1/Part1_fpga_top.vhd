library ieee;
use ieee.std_logic_1164.all;

entity fpga_top is
    generic(
        NUM_SEQ_WRITES : integer := 4
    );
    port(
        clk_100MHz  :  in     std_logic;
        sys_rst     :  in     std_logic;
        i_UART_RX   :  in     std_logic;
        o_UART_TX   :  out    std_logic;
        ddr2_addr   :  out    std_logic_vector(12  downto  0);
        ddr2_ba     :  out    std_logic_vector(2   downto  0);
        ddr2_ras_n  :  out    std_logic;
        ddr2_cas_n  :  out    std_logic;
        ddr2_we_n   :  out    std_logic;
        ddr2_ck_p   :  out    std_logic_vector(0   downto  0);
        ddr2_ck_n   :  out    std_logic_vector(0   downto  0);
        ddr2_cke    :  out    std_logic_vector(0   downto  0);
        ddr2_cs_n   :  out    std_logic_vector(0   downto  0);
        ddr2_dm     :  out    std_logic_vector(1   downto  0);
        ddr2_odt    :  out    std_logic_vector(0   downto  0);
        ddr2_dq     :  inout  std_logic_vector(15  downto  0);
        ddr2_dqs_p  :  inout  std_logic_vector(1   downto  0);
        ddr2_dqs_n  :  inout  std_logic_vector(1   downto  0)
    );
end fpga_top;

architecture Behavioral of fpga_top is

    component axi_protocol_converter_0
    port (
        aclk            :  in   std_logic;
        aresetn         :  in   std_logic;
        s_axi_awaddr    :  in   std_logic_vector(26  downto  0);
        s_axi_awprot    :  in   std_logic_vector(2   downto  0);
        s_axi_awvalid   :  in   std_logic;
        s_axi_awready   :  out  std_logic;
        s_axi_wdata     :  in   std_logic_vector(31  downto  0);
        s_axi_wstrb     :  in   std_logic_vector(3   downto  0);
        s_axi_wvalid    :  in   std_logic;
        s_axi_wready    :  out  std_logic;
        s_axi_bresp     :  out  std_logic_vector(1   downto  0);
        s_axi_bvalid    :  out  std_logic;
        s_axi_bready    :  in   std_logic;
        s_axi_araddr    :  in   std_logic_vector(26  downto  0);
        s_axi_arprot    :  in   std_logic_vector(2   downto  0);
        s_axi_arvalid   :  in   std_logic;
        s_axi_arready   :  out  std_logic;
        s_axi_rdata     :  out  std_logic_vector(31  downto  0);
        s_axi_rresp     :  out  std_logic_vector(1   downto  0);
        s_axi_rvalid    :  out  std_logic;
        s_axi_rready    :  in   std_logic;
        m_axi_awaddr    :  out  std_logic_vector(26  downto  0);
        m_axi_awlen     :  out  std_logic_vector(7   downto  0);
        m_axi_awsize    :  out  std_logic_vector(2   downto  0);
        m_axi_awburst   :  out  std_logic_vector(1   downto  0);
        m_axi_awlock    :  out  std_logic_vector(0   downto  0);
        m_axi_awcache   :  out  std_logic_vector(3   downto  0);
        m_axi_awprot    :  out  std_logic_vector(2   downto  0);
        m_axi_awregion  :  out  std_logic_vector(3   downto  0);
        m_axi_awqos     :  out  std_logic_vector(3   downto  0);
        m_axi_awvalid   :  out  std_logic;
        m_axi_awready   :  in   std_logic;
        m_axi_wdata     :  out  std_logic_vector(31  downto  0);
        m_axi_wstrb     :  out  std_logic_vector(3   downto  0);
        m_axi_wlast     :  out  std_logic;
        m_axi_wvalid    :  out  std_logic;
        m_axi_wready    :  in   std_logic;
        m_axi_bresp     :  in   std_logic_vector(1   downto  0);
        m_axi_bvalid    :  in   std_logic;
        m_axi_bready    :  out  std_logic;
        m_axi_araddr    :  out  std_logic_vector(26  downto  0);
        m_axi_arlen     :  out  std_logic_vector(7   downto  0);
        m_axi_arsize    :  out  std_logic_vector(2   downto  0);
        m_axi_arburst   :  out  std_logic_vector(1   downto  0);
        m_axi_arlock    :  out  std_logic_vector(0   downto  0);
        m_axi_arcache   :  out  std_logic_vector(3   downto  0);
        m_axi_arprot    :  out  std_logic_vector(2   downto  0);
        m_axi_arregion  :  out  std_logic_vector(3   downto  0);
        m_axi_arqos     :  out  std_logic_vector(3   downto  0);
        m_axi_arvalid   :  out  std_logic;
        m_axi_arready   :  in   std_logic;
        m_axi_rdata     :  in   std_logic_vector(31  downto  0);
        m_axi_rresp     :  in   std_logic_vector(1   downto  0);
        m_axi_rlast     :  in   std_logic;
        m_axi_rvalid    :  in   std_logic;
        m_axi_rready    :  out  std_logic
    );
    end component;

    component clk_wiz_0
    port (
        clk_out1          : out    std_logic;
        locked            : out    std_logic;
        reset             : in     std_logic;
        clk_in1           : in     std_logic
    );
    end component;

    component mig_7series_0 is
    port (
        ddr2_dq              :  inout  std_logic_vector(15 downto  0);
        ddr2_dqs_n           :  inout  std_logic_vector(1  downto  0);
        ddr2_dqs_p           :  inout  std_logic_vector(1  downto  0);
        ddr2_addr            :  out    std_logic_vector(12 downto  0);
        ddr2_ba              :  out    std_logic_vector(2  downto  0);
        ddr2_ras_n           :  out    std_logic;
        ddr2_cas_n           :  out    std_logic;
        ddr2_we_n            :  out    std_logic;
        ddr2_ck_p            :  out    std_logic_vector(0  to      0);
        ddr2_ck_n            :  out    std_logic_vector(0  to      0);
        ddr2_cke             :  out    std_logic_vector(0  to      0);
        ddr2_cs_n            :  out    std_logic_vector(0  to      0);
        ddr2_dm              :  out    std_logic_vector(1  downto  0);
        ddr2_odt             :  out    std_logic_vector(0  to      0);
        sys_clk_i            :  in     std_logic;
        ui_clk               :  out    std_logic;
        ui_clk_sync_rst      :  out    std_logic;
        mmcm_locked          :  out    std_logic;
        aresetn              :  in     std_logic;
        app_sr_req           :  in     std_logic;
        app_ref_req          :  in     std_logic;
        app_zq_req           :  in     std_logic;
        app_sr_active        :  out    std_logic;
        app_ref_ack          :  out    std_logic;
        app_zq_ack           :  out    std_logic;
        s_axi_awid           :  in     std_logic_vector(3  downto  0);
        s_axi_awaddr         :  in     std_logic_vector(26 downto 0);
        s_axi_awlen          :  in     std_logic_vector(7  downto  0);
        s_axi_awsize         :  in     std_logic_vector(2  downto  0);
        s_axi_awburst        :  in     std_logic_vector(1  downto  0);
        s_axi_awlock         :  in     std_logic_vector(0  to      0);
        s_axi_awcache        :  in     std_logic_vector(3  downto  0);
        s_axi_awprot         :  in     std_logic_vector(2  downto  0);
        s_axi_awqos          :  in     std_logic_vector(3  downto  0);
        s_axi_awvalid        :  in     std_logic;
        s_axi_awready        :  out    std_logic;
        s_axi_wdata          :  in     std_logic_vector(31 downto  0);
        s_axi_wstrb          :  in     std_logic_vector(3  downto  0);
        s_axi_wlast          :  in     std_logic;
        s_axi_wvalid         :  in     std_logic;
        s_axi_wready         :  out    std_logic;
        s_axi_bready         :  in     std_logic;
        s_axi_bid            :  out    std_logic_vector(3  downto  0);
        s_axi_bresp          :  out    std_logic_vector(1  downto  0);
        s_axi_bvalid         :  out    std_logic;
        s_axi_arid           :  in     std_logic_vector(3  downto  0);
        s_axi_araddr         :  in     std_logic_vector(26 downto  0);
        s_axi_arlen          :  in     std_logic_vector(7  downto  0);
        s_axi_arsize         :  in     std_logic_vector(2  downto  0);
        s_axi_arburst        :  in     std_logic_vector(1  downto  0);
        s_axi_arlock         :  in     std_logic_vector(0  to      0);
        s_axi_arcache        :  in     std_logic_vector(3  downto  0);
        s_axi_arprot         :  in     std_logic_vector(2  downto  0);
        s_axi_arqos          :  in     std_logic_vector(3  downto  0);
        s_axi_arvalid        :  in     std_logic;
        s_axi_arready        :  out    std_logic;
        s_axi_rready         :  in     std_logic;
        s_axi_rid            :  out    std_logic_vector(3  downto  0);
        s_axi_rdata          :  out    std_logic_vector(31 downto  0);
        s_axi_rresp          :  out    std_logic_vector(1  downto  0);
        s_axi_rlast          :  out    std_logic;
        s_axi_rvalid         :  out    std_logic;
        init_calib_complete  :  out    std_logic;
        sys_rst              :  in     std_logic
    );
    end component;

    signal  clk_200MHZ, clk_200_rst, clk, rstn, rst_mig  :  std_logic;
    signal  m_axi_awaddr    :  std_logic_vector(26  downto  0);
    signal  m_axi_awvalid   :  std_logic;
    signal  m_axi_awready   :  std_logic;
    signal  m_axi_wdata     :  std_logic_vector(31  downto  0);
    signal  m_axi_wstrb     :  std_logic_vector(3   downto  0);
    signal  m_axi_wvalid    :  std_logic;
    signal  m_axi_wready    :  std_logic;
    signal  m_axi_bresp     :  std_logic_vector(1   downto  0);
    signal  m_axi_bvalid    :  std_logic;
    signal  m_axi_bready    :  std_logic;
    signal  m_axi_araddr    :  std_logic_vector(26  downto  0);
    signal  m_axi_arvalid   :  std_logic;
    signal  m_axi_arready   :  std_logic;
    signal  m_axi_rdata     :  std_logic_vector(31  downto  0);
    signal  m_axi_rresp     :  std_logic_vector(1   downto  0);
    signal  m_axi_rvalid    :  std_logic;
    signal  m_axi_rready    :  std_logic;
    signal  s_axi_awaddr    :  std_logic_vector(26  downto  0);
    signal  s_axi_awlen     :  std_logic_vector(7  downto  0);
    signal  s_axi_awsize    :  std_logic_vector(2  downto  0);
    signal  s_axi_awburst   :  std_logic_vector(1  downto  0);
    signal  s_axi_awlock    :  std_logic_vector(0  downto  0);
    signal  s_axi_awcache   :  std_logic_vector(3  downto  0);
    signal  s_axi_awprot    :  std_logic_vector(2  downto  0);
    signal  s_axi_awqos     :  std_logic_vector(3  downto  0);
    signal  s_axi_awvalid   :  std_logic;
    signal  s_axi_awready   :  std_logic;
    signal  s_axi_wdata     :  std_logic_vector(31 downto  0);
    signal  s_axi_wstrb     :  std_logic_vector(3  downto  0);
    signal  s_axi_wlast     :  std_logic;
    signal  s_axi_wvalid    :  std_logic;
    signal  s_axi_wready    :  std_logic;
    signal  s_axi_bresp     :  std_logic_vector(1  downto  0);
    signal  s_axi_bvalid    :  std_logic;
    signal  s_axi_bready    :  std_logic;
    signal  s_axi_araddr    :  std_logic_vector(26  downto  0);
    signal  s_axi_arlen     :  std_logic_vector(7  downto  0);
    signal  s_axi_arsize    :  std_logic_vector(2  downto  0);
    signal  s_axi_arburst   :  std_logic_vector(1  downto  0);
    signal  s_axi_arlock    :  std_logic_vector(0  downto  0);
    signal  s_axi_arcache   :  std_logic_vector(3  downto  0);
    signal  s_axi_arprot    :  std_logic_vector(2  downto  0);
    signal  s_axi_arregion  :  std_logic_vector(3  downto  0);
    signal  s_axi_arqos     :  std_logic_vector(3  downto  0);
    signal  s_axi_arvalid   :  std_logic;
    signal  s_axi_arready   :  std_logic;
    signal  s_axi_rdata     :  std_logic_vector(31 downto  0);
    signal  s_axi_rresp     :  std_logic_vector(1  downto  0);
    signal  s_axi_rlast     :  std_logic;
    signal  s_axi_rvalid    :  std_logic;
    signal  s_axi_rready    :  std_logic;

begin

    axi_protocol_conv : axi_protocol_converter_0
    port map (
        aclk            =>  clk,
        aresetn         =>  rst_mig,
        s_axi_awaddr    =>  m_axi_awaddr,
        s_axi_awprot    =>  (others => '0'),
        s_axi_awvalid   =>  m_axi_awvalid,
        s_axi_awready   =>  m_axi_awready,
        s_axi_wdata     =>  m_axi_wdata,
        s_axi_wstrb     =>  m_axi_wstrb,
        s_axi_wvalid    =>  m_axi_wvalid,
        s_axi_wready    =>  m_axi_wready,
        s_axi_bresp     =>  m_axi_bresp,
        s_axi_bvalid    =>  m_axi_bvalid,
        s_axi_bready    =>  m_axi_bready,
        s_axi_araddr    =>  m_axi_araddr,
        s_axi_arprot    =>  (others => '0'),
        s_axi_arvalid   =>  m_axi_arvalid,
        s_axi_arready   =>  m_axi_arready,
        s_axi_rdata     =>  m_axi_rdata,
        s_axi_rresp     =>  m_axi_rresp,
        s_axi_rvalid    =>  m_axi_rvalid,
        s_axi_rready    =>  m_axi_rready,
        m_axi_awaddr    =>  s_axi_awaddr,
        m_axi_awlen     =>  s_axi_awlen,
        m_axi_awsize    =>  s_axi_awsize,
        m_axi_awburst   =>  s_axi_awburst,
        m_axi_awlock    =>  s_axi_awlock,
        m_axi_awcache   =>  s_axi_awcache,
        m_axi_awprot    =>  s_axi_awprot,
        m_axi_awregion  =>  open,
        m_axi_awqos     =>  s_axi_awqos,
        m_axi_awvalid   =>  s_axi_awvalid,
        m_axi_awready   =>  s_axi_awready,
        m_axi_wdata     =>  s_axi_wdata,
        m_axi_wstrb     =>  s_axi_wstrb,
        m_axi_wlast     =>  s_axi_wlast,
        m_axi_wvalid    =>  s_axi_wvalid,
        m_axi_wready    =>  s_axi_wready,
        m_axi_bresp     =>  s_axi_bresp,
        m_axi_bvalid    =>  s_axi_bvalid,
        m_axi_bready    =>  s_axi_bready,
        m_axi_araddr    =>  s_axi_araddr,
        m_axi_arlen     =>  s_axi_arlen,
        m_axi_arsize    =>  s_axi_arsize,
        m_axi_arburst   =>  s_axi_arburst,
        m_axi_arlock    =>  s_axi_arlock,
        m_axi_arcache   =>  s_axi_arcache,
        m_axi_arprot    =>  s_axi_arprot,
        m_axi_arregion  =>  s_axi_arregion,
        m_axi_arqos     =>  s_axi_arqos,
        m_axi_arvalid   =>  s_axi_arvalid,
        m_axi_arready   =>  s_axi_arready,
        m_axi_rdata     =>  s_axi_rdata,
        m_axi_rresp     =>  s_axi_rresp,
        m_axi_rlast     =>  s_axi_rlast,
        m_axi_rvalid    =>  s_axi_rvalid,
        m_axi_rready    =>  s_axi_rready
    );

    clk_wiz : clk_wiz_0
    port map (
        clk_in1   =>  clk_100MHz,
        clk_out1  =>  clk_200MHZ,
        locked    =>  clk_200_rst,
        reset     =>  sys_rst
    );

    mig_7series : mig_7series_0
    port map (
            -- DDR Chip
        ddr2_dq              =>      ddr2_dq,
        ddr2_dqs_n           =>      ddr2_dqs_n,
        ddr2_dqs_p           =>      ddr2_dqs_p,
        ddr2_addr            =>      ddr2_addr,
        ddr2_ba              =>      ddr2_ba,
        ddr2_ras_n           =>      ddr2_ras_n,
        ddr2_cas_n           =>      ddr2_cas_n,
        ddr2_we_n            =>      ddr2_we_n,
        ddr2_ck_p            =>      ddr2_ck_p,
        ddr2_ck_n            =>      ddr2_ck_n,
        ddr2_cke             =>      ddr2_cke,
        ddr2_cs_n            =>      ddr2_cs_n,
        ddr2_dm              =>      ddr2_dm,
        ddr2_odt             =>      ddr2_odt,
        init_calib_complete  =>      open,
            -- Common
        sys_clk_i            =>      clk_200MHz,
        sys_rst              =>      clk_200_rst,
        ui_clk               =>      clk,
        ui_clk_sync_rst      =>      rst_mig,
        mmcm_locked          =>      open,
        aresetn              =>      rstn,
        app_sr_req           =>      '0',
        app_ref_req          =>      '0',
        app_zq_req           =>      '0',
        app_sr_active        =>      open,
        app_ref_ack          =>      open,
        app_zq_ack           =>      open,
            -- AXI
        s_axi_awid           =>      (others => '0'),
        s_axi_awaddr         =>      s_axi_awaddr,
        s_axi_awlen          =>      s_axi_awlen,
        s_axi_awsize         =>      s_axi_awsize,
        s_axi_awburst        =>      s_axi_awburst,
        s_axi_awlock         =>      s_axi_awlock,
        s_axi_awcache        =>      s_axi_awcache,
        s_axi_awprot         =>      s_axi_awprot,
        s_axi_awqos          =>      s_axi_awqos,
        s_axi_awvalid        =>      s_axi_awvalid,
        s_axi_awready        =>      s_axi_awready,
        s_axi_wdata          =>      s_axi_wdata,
        s_axi_wstrb          =>      s_axi_wstrb,
        s_axi_wlast          =>      s_axi_wlast,
        s_axi_wvalid         =>      s_axi_wvalid,
        s_axi_wready         =>      s_axi_wready,
        s_axi_bresp          =>      s_axi_bresp,
        s_axi_bvalid         =>      s_axi_bvalid,
        s_axi_bready         =>      s_axi_bready,
        s_axi_arid           =>      (others => '0'),
        s_axi_araddr         =>      s_axi_araddr,
        s_axi_arlen          =>      s_axi_arlen,
        s_axi_arsize         =>      s_axi_arsize,
        s_axi_arburst        =>      s_axi_arburst,
        s_axi_arlock         =>      s_axi_arlock,
        s_axi_arcache        =>      s_axi_arcache,
        s_axi_arprot         =>      s_axi_arprot,
        s_axi_arqos          =>      s_axi_arqos,
        s_axi_arvalid        =>      s_axi_arvalid,
        s_axi_arready        =>      s_axi_arready,
        s_axi_rdata          =>      s_axi_rdata,
        s_axi_rresp          =>      s_axi_rresp,
        s_axi_rlast          =>      s_axi_rlast,
        s_axi_rvalid         =>      s_axi_rvalid,
        s_axi_rready         =>      s_axi_rready
    );

    top_0 : entity work.top
    port map (
        clk             =>  clk,
        rst             =>  rst_mig,
        i_UART_RX       =>  i_UART_RX,
        o_UART_TX       =>  o_UART_TX,
        m_axi_awaddr    =>  m_axi_awaddr,
        m_axi_awvalid   =>  m_axi_awvalid,
        m_axi_awready   =>  m_axi_awready,
        m_axi_wdata     =>  m_axi_wdata,
        m_axi_wstrb     =>  m_axi_wstrb,
        m_axi_wvalid    =>  m_axi_wvalid,
        m_axi_wready    =>  m_axi_wready,
        m_axi_bresp     =>  m_axi_bresp,
        m_axi_bvalid    =>  m_axi_bvalid,
        m_axi_bready    =>  m_axi_bready,
        m_axi_araddr    =>  m_axi_araddr,
        m_axi_arvalid   =>  m_axi_arvalid,
        m_axi_arready   =>  m_axi_arready,
        m_axi_rdata     =>  m_axi_rdata,
        m_axi_rresp     =>  m_axi_rresp,
        m_axi_rvalid    =>  m_axi_rvalid,
        m_axi_rready    =>  m_axi_rready
    );

    process(clk)
    begin
        if rising_edge(clk) then
            rstn <= not rst_mig;
        end if;
    end process;

end Behavioral;
