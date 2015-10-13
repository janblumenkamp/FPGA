--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   19:14:40 10/07/2015
-- Design Name:   
-- Module Name:   /home/jblumenkamp/FPGA/avnet_spartana3/helloword/uart_test.vhd
-- Project Name:  helloword
-- Target Device:  
-- Tool versions:  
-- Description:   
-- 
-- VHDL Test Bench Created by ISE for module: serial8n1_rx
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
 
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--USE ieee.numeric_std.ALL;
 
ENTITY uart_test IS
END uart_test;
 
ARCHITECTURE behavior OF uart_test IS     

   --Inputs
   signal clk_baudx16 : std_logic := '0';
   signal rst : std_logic := '0';
   signal rx : std_logic := '1';
	signal clr : std_logic := '0';

 	--Outputs
   signal data : std_logic_vector(7 downto 0);
   signal newdata : std_logic;
   signal error : std_logic;

	signal led_reg : std_logic_vector (7 downto 0) := "00000000"; -- Kopie für LED
	
	signal init : std_logic := '0';
	
	-- Clock period definitions
   constant clk_baudx16_period : time := 3.25 us;
 
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: entity work.serial8n1_rx
	PORT MAP (
          clk_baudx16 => clk_baudx16,
          rst => rst,
          rx => rx,
          clr => clr,
          data => data,
          newdata => newdata,
          error => error
        );

   -- Clock process definitions
   clk_baudx16_process :process
   begin
		clk_baudx16 <= '0';
		wait for clk_baudx16_period/2;
		clk_baudx16 <= '1';
		wait for clk_baudx16_period/2;
   end process;

	-- transmit simulation
	tr: process
	begin
		wait for 2 ms;
		
		rx <= '0'; -- start
		wait for clk_baudx16_period*16; -- wait start bit
		rx <= '1'; -- bit
		wait for clk_baudx16_period*16; -- wait bit 0
		rx <= '1'; -- bi
		wait for clk_baudx16_period*16; -- wait bit 1
		rx <= '1'; -- bit
		wait for clk_baudx16_period*16; -- wait bit 2
		rx <= '1'; -- bi
		wait for clk_baudx16_period*16; -- wait bit 3
		rx <= '1'; -- bit
		wait for clk_baudx16_period*16; -- wait bit 4
		rx <= '1'; -- bi
		wait for clk_baudx16_period*16; -- wait bit 5
		rx <= '1'; -- bit
		wait for clk_baudx16_period*16; -- wait bit 6
		rx <= '0'; -- bit
		wait for clk_baudx16_period*16; -- wait bit 7
		rx <= '1'; -- stop bit
	end process;
	
	-- init process
   initialize: process
   begin
		if init = '0' then
			rst <= '1';
			wait for 0.7 ms;
			rst <= '0';
			init <= '1';
		end if;
		
		wait;
   end process;
	
	-- process data
	proc: process
	begin
		wait for 62.5 ns;
		
		if clr = '1' and newdata = '0' then
			clr <= '0';
		elsif newdata = '1' then
			led_reg <= data; -- Daten in LED Register übertragen
			clr <= '1';
		end if;
	end process;
END;
