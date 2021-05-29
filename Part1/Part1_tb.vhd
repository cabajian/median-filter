library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use std.textio.all;
use IEEE.std_logic_textio.all;

entity tb_top is
end tb_top;

architecture Behavioral of tb_top is
    -- --------------------------------------
    -- components
    -- --------------------------------------
    component blk_mem_gen_0
        port (
            rsta_busy      :  out  std_logic;
            rstb_busy      :  out  std_logic;
            s_aclk         :  in   std_logic;
            s_aresetn      :  in   std_logic;
            
            s_axi_awaddr   :  in   std_logic_vector(31  downto  0);
            s_axi_awvalid  :  in   std_logic;
            s_axi_awready  :  out  std_logic;
            
            s_axi_wdata    :  in   std_logic_vector(31  downto  0);
            s_axi_wstrb    :  in   std_logic_vector(3   downto  0);
            s_axi_wvalid   :  in   std_logic;
            s_axi_wready   :  out  std_logic;
            
            s_axi_bresp    :  out  std_logic_vector(1   downto  0);
            s_axi_bvalid   :  out  std_logic;
            s_axi_bready   :  in   std_logic;
            
            s_axi_araddr   :  in   std_logic_vector(31  downto  0);
            s_axi_arvalid  :  in   std_logic;
            s_axi_arready  :  out  std_logic;
            
            s_axi_rdata    :  out  std_logic_vector(31  downto  0);
            s_axi_rresp    :  out  std_logic_vector(1   downto  0);
            s_axi_rvalid   :  out  std_logic;
            s_axi_rready   :  in   std_logic
        );
    end component;

    -- --------------------------------------
    -- signals
    -- --------------------------------------
    signal clk             :   std_logic := '1';
    signal rst             :   std_logic := '1';
    signal i_uart_rx       :   std_logic := '1';
    signal rstn            :   std_logic;
    signal o_uart_tx       :   std_logic;
    signal m_axi_awaddr    :   std_logic_vector(26  downto  0);
    signal m_axi_awaddr32  :   std_logic_vector(31  downto  0);
    signal m_axi_awvalid   :   std_logic;
    signal m_axi_awready   :   std_logic;
    signal m_axi_wdata     :   std_logic_vector(31  downto  0);
    signal m_axi_wstrb     :   std_logic_vector(3   downto  0);
    signal m_axi_wvalid    :   std_logic;
    signal m_axi_wready    :   std_logic;
    signal m_axi_bresp     :   std_logic_vector(1   downto  0);
    signal m_axi_bvalid    :   std_logic;
    signal m_axi_bready    :   std_logic;
    signal m_axi_araddr    :   std_logic_vector(26  downto  0);
    signal m_axi_araddr32  :   std_logic_vector(31  downto  0);
    signal m_axi_arvalid   :   std_logic;
    signal m_axi_arready   :   std_logic;
    signal m_axi_rdata     :   std_logic_vector(31  downto  0);
    signal m_axi_rresp     :   std_logic_vector(1   downto  0);
    signal m_axi_rvalid    :   std_logic;
    signal m_axi_rready    :   std_logic;

    -- Clock period definitions
    constant  clk_period   :  time     :=  10 ns;
    constant  clk_per_sym  :  integer  :=  868;
    constant  symbol_len   :  time     :=  clk_period*clk_per_sym;  --   100  MHz  /  115200  =  868.1  clock/symbol
    
    -- constants
    constant  N : integer := 4; -- max number of reads/writes from text file
begin

    m_axi_awaddr32 <= "00000" & m_axi_awaddr;
    m_axi_araddr32 <= "00000" & m_axi_araddr;

    top_0 : entity work.top
    port map (
        clk              => clk,
        rst              => rst,
        i_uart_rx        => i_uart_rx,
        o_uart_tx        => o_uart_tx,
        -- write address channel
        m_axi_awaddr     => m_axi_awaddr,
        m_axi_awvalid    => m_axi_awvalid,
        m_axi_awready    => m_axi_awready,
        -- write data channel
        m_axi_wdata      => m_axi_wdata,
        m_axi_wstrb      => m_axi_wstrb,
        m_axi_wvalid     => m_axi_wvalid,
        m_axi_wready     => m_axi_wready,
        -- write response channel
        m_axi_bresp      => m_axi_bresp,
        m_axi_bvalid     => m_axi_bvalid,
        m_axi_bready     => m_axi_bready,
        
        -- read address channel
        m_axi_araddr     => m_axi_araddr,
        m_axi_arvalid    => m_axi_arvalid,
        m_axi_arready    => m_axi_arready,
        -- read data channel
        m_axi_rdata      => m_axi_rdata,
        m_axi_rresp      => m_axi_rresp,
        m_axi_rvalid     => m_axi_rvalid,
        m_axi_rready     => m_axi_rready
    );

    memory : blk_mem_gen_0
    port map (
        rsta_busy      =>  open,
        rstb_busy      =>  open,
        s_aclk         =>  clk,
        s_aresetn      =>  rstn,
        -- write address channe;
        s_axi_awaddr   =>  m_axi_awaddr32,
        s_axi_awvalid  =>  m_axi_awvalid,
        s_axi_awready  =>  m_axi_awready,
        -- write data channel
        s_axi_wdata    =>  m_axi_wdata,
        s_axi_wstrb    =>  m_axi_wstrb,
        s_axi_wvalid   =>  m_axi_wvalid,
        s_axi_wready   =>  m_axi_wready,
        -- write response channe
        s_axi_bresp    =>  m_axi_bresp,
        s_axi_bvalid   =>  m_axi_bvalid,
        s_axi_bready   =>  m_axi_bready,
        
        -- read address channel
        s_axi_araddr   =>  m_axi_araddr32,
        s_axi_arvalid  =>  m_axi_arvalid,
        s_axi_arready  =>  m_axi_arready,
        -- read data channel
        s_axi_rdata    =>  m_axi_rdata,
        s_axi_rresp    =>  m_axi_rresp,
        s_axi_rvalid   =>  m_axi_rvalid,
        s_axi_rready   =>  m_axi_rready
    );

    rstn <= not rst;
    -- Clock process definitions
    process
    begin
        clk <= '0';
        wait for clk_period/2;
        clk <= '1';
        wait for clk_period/2;
    end process;
    
    -- PGM verification process
    process
        constant MAX_ROW : integer := 512;
        constant MAX_COL : integer := 512;
        constant MAX_PX  : integer := 255;
        -- pgm image storage
        type timage is array( 1 to MAX_ROW, 1 to MAX_COL ) of integer range 0 to MAX_PX;
        -- pgm files
        file in_file  : TEXT open READ_MODE is "LenaFormatted.pgm";
        file out_file : TEXT open WRITE_MODE is "LenaOUT.pgm";
        -- pgm variables
        variable in_image, out_image : timage;
        variable hline1, hline2, hline3 : line;
        variable nrows, ncols : integer;
        variable size : integer;
        variable px_max : integer;
        
        -- --------------------------------------
        -- SEND CHAR PROC
        -- --------------------------------------
        procedure send_char( chr : in unsigned(7 downto 0) ) is begin
            i_UART_RX <= '0';
            wait for symbol_len;
            for i in 0 to chr'high loop
                i_UART_RX <= chr(i);
                wait for symbol_len;
            end loop;
            i_UART_RX <= '1';
            wait for symbol_len;
        end send_char;
        
        -- --------------------------------------
        -- RX CHAR PROC
        -- --------------------------------------
        procedure rx_char( chr : out unsigned(7 downto 0) ) is
            variable vect : std_logic_vector(7 downto 0);
        begin
            if o_UART_TX /= '0' then        -- in case UART is started
                wait until o_UART_TX = '0'; -- start
            end if;
            wait for symbol_len/2; -- center
            wait for symbol_len; -- start bit
            for i in 0 to vect'high loop
                vect(i) := o_UART_TX;
                wait for symbol_len;
            end loop;
            chr := unsigned(vect);
            wait for symbol_len/2;
        end rx_char;
    
        -- --------------------------------------
        -- READ PGM PROC
        -- --------------------------------------
        procedure read_pgm is
          variable ltemp: line;
          variable px, row, col : integer;
          variable status : boolean;
        begin
          	--save header lines
            readline( in_file, hline1 );
            readline( in_file, hline2 );
            readline( in_file, hline3 );
            
            -- read number of rows/cols
            read(hline2, ncols);
            read(hline2, nrows);
            read(hline3, px_max);
            size := nrows * ncols;
            
            row := 1;
            col := 1;
            
            --read rest of file
            while not endfile( in_file ) loop
              --get line
              readline( in_file, ltemp );
              status := true;
              while (status = true) loop     --checks for end of line
                --read pixels from line
                read( ltemp, px, status );
                if (status = true) then
                  if (px > px_max) then px := px_max; end if;
                  in_image(row,col) := px;
                  if ( col = ncols ) then
                    col := 1;
                    row := row + 1;
                  else
                    col := col + 1;
                  end if;
                end if;
              end loop;
            end loop;
        end read_pgm;
        
        -- --------------------------------------
        -- SEND PGM PROC
        -- --------------------------------------
        procedure send_pgm is
          variable px : integer;
          variable urows : unsigned(15 downto 0);
          variable ucols : unsigned(15 downto 0);
          variable usize : unsigned(31 downto 0);
        begin
            -- send command indicating PGM data is about to be sent
            send_char(X"01");
            -- send number of rows
            urows := to_unsigned(nrows,urows'length);
            send_char(urows(7 downto 0));
            send_char(urows(15 downto 8));
            -- send number of cols
            ucols := to_unsigned(ncols,ucols'length);
            send_char(ucols(7 downto 0));
            send_char(ucols(15 downto 8));
            -- send image size
            usize := to_unsigned(size,usize'length);
            send_char(usize(7 downto 0));
            send_char(usize(15 downto 8));
            send_char(usize(23 downto 16));
            send_char(usize(31 downto 24));
            -- send image data
            for row in 1 to nrows loop
                for col in 1 to ncols loop
                    px := in_image(row, col);
                    send_char(to_unsigned(px,8));
                end loop;
            end loop;
        end send_pgm;
        
        -- --------------------------------------
        -- RECV PGM PROC
        -- --------------------------------------
        procedure recv_pgm is
          variable upx : unsigned(7 downto 0);
        begin
            -- send command requesting PGM data
            send_char(X"02");
            -- receive pixel data, store locally
            for row in 1 to nrows loop
                for col in 1 to ncols loop
                    rx_char(upx);
                    out_image(row, col) := to_integer(upx);
                end loop;
            end loop;
        end recv_pgm;
        
        -- --------------------------------------
        -- SAVE PGM PROC
        -- --------------------------------------
        procedure save_pgm is
          variable lout: line;
        begin
            --rewrite header information
            writeline( out_file, hline1 );
            writeline( out_file, hline2 );
            writeline( out_file, hline3 );
            
            -- write received image
            for row in 1 to nrows loop
                for col in 1 to ncols loop
                  write( lout, out_image(row, col) );
                  write( lout, ' ' );
                end loop;
                writeline( out_file, lout );
            end loop;
        end save_pgm;
        
    begin
        wait for 200 ns;
        rst <= '0';
        wait for 1 us; -- wait for ui_clk_sync_rst
        
        read_pgm;
        report "READ PGM COMPLETE" severity note;
        
        send_pgm;
        report "SEND PGM COMPLETE" severity note;
        
        recv_pgm;
        report "RECEIVE PGM COMPLETE" severity note;
        
        save_pgm;
        report "SAVE PGM COMPLETE" severity note;
        
        wait for 300 us;

        assert false
            report "End of simulation"
            severity failure;
        
    end process;

end Behavioral;
