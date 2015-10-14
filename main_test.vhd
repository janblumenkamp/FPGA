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
   signal btn : std_logic_vector(2 downto 0) := (others => '0');

 	--Outputs
   signal tx : std_logic;
   signal led : std_logic_vector(3 downto 0);

	-- intern
	signal serial_tx_clk: std_logic;
	signal serial_tx_send: std_logic := '0';
	signal serial_tx_ready: std_logic;
	signal serial_tx_data: std_logic_vector(7 downto 0) := "00000000";
	
	
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
          btn => btn
        );

	FREQ_SERIAL_TX : entity work.freqdiv port map(
		clkin=>clk,
		rst=>rst,
		clkout=>serial_tx_clk,
		fac=>"0000001100111111"
	); -- Frequenzteiler für UART Clock (16000000/(1100111111 + 1) ~ 19200Baud)
	
	-- Serielles Sendemodul
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
 
	simtx_process: process
		procedure transmit(data: in std_logic_vector(7 downto 0)) is
		begin
			wait for clk_period * 3;
			serial_tx_data <= data;
			serial_tx_send <= '1';
			
			wait until serial_tx_ready = '0'; -- sendemodul hat begonnen, daten zu senden
			serial_tx_send <= '0'; -- lösche senden flag, damit es nicht bald direkt erneut gesendet wird
			wait until serial_tx_ready = '1';
		end transmit;
	begin
		transmit("01010101");
		wait for 1ms;
		transmit("00000000");
		wait for 1ms;
		transmit("11000000");
		wait for 1ms;
		transmit("00010101"); -- checksum
		wait for 3ms;
		
	end process;

   -- Stimulus process
   stim_proc: process
   begin		
      rst <= '1';
      wait for clk_period;	
		rst <= '0';
		
      wait for clk_period*10;

      -- insert stimulus here 

      wait;
   end process;

END;
