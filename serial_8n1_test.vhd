--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   17:03:34 10/08/2015
-- Design Name:   
-- Module Name:   /home/jblumenkamp/FPGA/avnet_spartana3/helloword/serial_send_test.vhd
-- Project Name:  helloword
-- Target Device:  
-- Tool versions:  
-- Description:   
-- 
-- VHDL Test Bench Created by ISE for module: serial8n1_tx
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
 
ENTITY serial_send_test IS
END serial_send_test;
 
ARCHITECTURE behavior OF serial_send_test IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT serial8n1_tx
    PORT(
         clk_baud : IN  std_logic;
         rst : IN  std_logic;
         tx : OUT  std_logic;
         send : IN  std_logic;
         ready : OUT  std_logic;
         data : IN  std_logic_vector(7 downto 0)
        );
    END COMPONENT;
    

   --Inputs
   signal clk_baud : std_logic := '0';
   signal rst : std_logic := '0';
   signal send : std_logic := '0';
   signal data : std_logic_vector(7 downto 0) := (others => '0');

 	--Outputs
   signal tx : std_logic;
   signal ready : std_logic;

   -- Clock period definitions
   constant clk_baud_period : time := 52 us;
 
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: serial8n1_tx PORT MAP (
          clk_baud => clk_baud,
          rst => rst,
          tx => tx,
          send => send,
          ready => ready,
          data => data
        );

   -- Clock process definitions
   clk_baud_process :process
   begin
		clk_baud <= '0';
		wait for clk_baud_period/2;
		clk_baud <= '1';
		wait for clk_baud_period/2;
   end process;
 
	
	putdata: process
	begin
		wait for 1 ms;
		data <= "10101010";
		send <= '1';
		wait for clk_baud_period;
		send <= '0';
		wait until ready = '1';
	end process;
	
   -- Stimulus process
   stim_proc: process
   begin		
      -- hold reset state for 100 ns.
		rst <= '1';
      wait for 0.7 ms;	
		rst <= '0';
      
      wait for clk_baud_period*10;

      -- insert stimulus here 

      wait;
   end process;

END;
