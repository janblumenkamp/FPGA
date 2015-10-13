--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   10:17:49 10/08/2015
-- Design Name:   
-- Module Name:   /home/jblumenkamp/FPGA/avnet_spartana3/helloword/pwm_test.vhd
-- Project Name:  helloword
-- Target Device:  
-- Tool versions:  
-- Description:   
-- 
-- VHDL Test Bench Created by ISE for module: pwm
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
use ieee.numeric_std.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--USE ieee.numeric_std.ALL;
 
ENTITY pwm_test IS
END pwm_test;
 
ARCHITECTURE behavior OF pwm_test IS 
   --Inputs
   signal clk : std_logic := '0';
   signal rst : std_logic := '0';
   signal pwmval : std_logic_vector(7 downto 0) := "00000000";

 	--Outputs
   signal output : std_logic;

   -- Clock period definitions
   constant clk_period : time := 62.5 ns;
 
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: entity work.pwm PORT MAP (
          clk => clk,
          rst => rst,
          output => output,
          pwmval => pwmval
			 );

   -- pwm incr
   incr :process
   begin
		wait for 1 ms;
		pwmval <= std_logic_vector(unsigned(pwmval)+15);
   end process;
 
-- Clock process definitions
   clk_process :process
   begin
		clk <= '0';
		wait for clk_period/2;
		clk <= '1';
		wait for clk_period/2;
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
