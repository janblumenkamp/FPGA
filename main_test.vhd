--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   14:02:45 10/14/2015
-- Design Name:   
-- Module Name:   /home/jblumenkamp/FPGA/avnet_spartana3/tutorium/main_test.vhd
-- Project Name:  tutorium
-- Target Device:  
-- Tool versions:  
-- Description:   
-- 
-- VHDL Test Bench Created by ISE for module: main
-- 
-- Dependencies:
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
--
-- Notes: 
-- This testbench has been automatically generated using types std_logic and
-- std_logic_vector for the ports of the unit under test.  Xilinx recommends
-- that these types always be used for the top-level I/O of a design in order
-- to guarantee that the testbench will bind correctly to the post-implementation 
-- simulation model.
--------------------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
 
ENTITY main_test IS
END main_test;
 
ARCHITECTURE behavior OF main_test IS 

    --Inputs
    signal clk : std_logic := '0';
    signal rst : std_logic := '0';
    signal rx : std_logic := '0';
    signal btn : std_logic_vector(2 downto 0) := "000";

     --Outputs
    signal tx : std_logic;
    signal led : std_logic_vector(3 downto 0);
    signal scl : std_logic;
    
    -- inouts
    signal sda : std_logic;
    
    -- intern
    -- serielles Empfangmodul
    signal serial_rx_clk: std_logic := '0'; -- Clockrate der seriellen Schnittstelle (16 x der Baudrate)
    signal serial_rx_clear: std_logic := '0'; -- löschen des newdata flags
    signal serial_rx_data: std_logic_vector(7 downto 0) := (others=>'0'); -- Seriell empfangenes Signal (8 bit)
    --signal serial_rx_error: std_logic := '0'; -- Flag: Fehler beim Empfang? (muss ggf. manuell gecleart werden)
    signal serial_rx_data_new: std_logic := '0'; -- Flag: befinden sich neue Daten im Signal?
    
    signal serial_rx_received_data: std_logic_vector(7 downto 0);
    
    -- serielles Sendemodul
    signal serial_tx_clk: std_logic := '0'; -- Clockrate der seriellen Schnittstelle (Baudrate)
    signal serial_tx_send: std_logic := '0'; -- Clockrate der seriellen Schnittstelle (Baudrate)
    signal serial_tx_ready: std_logic := '0'; -- Clockrate der seriellen Schnittstelle (Baudrate)
    signal serial_tx_data: std_logic_vector(7 downto 0) := (others=>'0'); -- Clockrate der seriellen Schnittstelle (Baudrate)
    
    
   -- Clock period definitions
   constant clk_period : time := 62.5 ns;

BEGIN
 
    -- Instantiate the Unit Under Test (UUT)
   uut: entity work.main PORT MAP (
          clk => clk,
          rst => rst,
          rx => rx,
          tx => tx,
          led => led,
          btn => btn,
             scl => scl,
             sda => sda
        );

        -- Frequenzteiler serielle Schnittstelle
    FREQ_SERIAL_RX : entity work.freqdiv port map(
        clkin=>clk,
        rst=>rst,
        clkout=>serial_rx_clk,
        fac=>"0000000000110011"
    ); -- Frequenzteiler für UART Clock (16000000/(00110011 + 1) ~ 19200Baud*16)
    FREQ_SERIAL_TX : entity work.freqdiv port map(
        clkin=>clk,
        rst=>rst,
        clkout=>serial_tx_clk,
        fac=>"0000001100111111"
    ); -- Frequenzteiler für UART Clock (16000000/(1100111111 + 1) ~ 19200Baud)
    
    -- Seriellen Module
    SERIAL_RX : entity work.serial8n1_rx port map(
        clk_baudx16=>serial_rx_clk,
        rst=>rst,
        rx=>tx,
        clr=>serial_rx_clear,
        data=>serial_rx_data,
        newdata=>serial_rx_data_new
    );
    SERIAL_TX : entity work.serial8n1_tx port map(
        clk_baud=>serial_tx_clk,
        rst=>rst,
        tx=>rx,
        send=>serial_tx_send,
        ready=>serial_tx_ready,
        data=>serial_tx_data
    );
    
   -- Clock process definitions
   clk_process :process
   begin
        clk <= '0';
        wait for clk_period/2;
        clk <= '1';
        wait for clk_period/2;
   end process;
    
    -- main process
    simtx_process: process
        -- ein byte senden
        procedure transmit(data: in std_logic_vector(7 downto 0)) is
        begin
            wait for clk_period * 3;
            serial_tx_data <= data;
            serial_tx_send <= '1';
            
            wait until serial_tx_ready = '0'; -- sendemodul hat begonnen, daten zu senden
            serial_tx_send <= '0'; -- lösche senden flag, damit es nicht bald direkt erneut gesendet wird
            wait until serial_tx_ready = '1';
        end transmit;
        
        -- senden eins ganzen Pakets inkl. Berechnung der Checksumme
        procedure transmit_package(reg: in std_logic_vector(6 downto 0); rw: in std_logic; data: in std_logic_vector(7 downto 0)) is
            variable checksum : unsigned (7 downto 0);
        begin
            transmit("01010101"); -- start
            checksum := "01010101";
            wait for 1 ms;
            transmit(rw & reg); -- rw + reg
            checksum := checksum + unsigned(rw & reg);
            wait for 1 ms;
            transmit(data); -- data
            checksum := checksum + unsigned(data);
            wait for 1 ms;
            transmit(std_logic_vector(checksum)); -- checksum
        end transmit_package;
        
    begin
        wait for 1 ms;
        
        --transmit_package(std_logic_vector(unsigned(to_unsigned(0, 7))), '0', "00000000");
        transmit_package(std_logic_vector(unsigned(to_unsigned(7, 7))), '1', "11111111"); -- Schreibzugriff auf RGB LED R Kanal
        --wait for 2 ms;
        --transmit_package(std_logic_vector(unsigned(to_unsigned(1, 7))), '0', "10100000");
        wait for 50 ms;
    end process;
    
    -- verarbeiten eines empfangenen Pakets
    chk_rec_proc: process
    begin
        wait until serial_rx_data_new = '1'; -- neue Daten vorhanden, die serielle schnittstelle ist direkt mit dem fifo verbunden, weshalb hier kein register kopiert werden muss.
        serial_rx_received_data <= serial_rx_data;
        serial_rx_clear <= '1'; -- Die Daten aus dem seriellen register liegen nun auf jeden Fall am EIngang des Fifos an, nun einfach we schalten und das Emfpangsmodul clearen
        wait until serial_rx_data_new = '0';
        serial_rx_clear <= '0';
    end process;
    
   -- Stimulus process
   stim_proc: process
   begin        
      --rst <= '1';
      wait for clk_period * 5;    
        rst <= '0';
        
      wait for clk_period*10;

      -- insert stimulus here 

      wait;
   end process;

END;
