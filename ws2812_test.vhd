--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   16:18:20 10/23/2015
-- Design Name:   
-- Module Name:   /home/jblumenkamp/FPGA/avnet_spartana3/tutorium/ws2812_test.vhd
-- Project Name:  tutorium
-- Target Device:  
-- Tool versions:  
-- Description:   
-- 
-- VHDL Test Bench Created by ISE for module: ws2812
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
 
ENTITY ws2812_test IS
END ws2812_test;
 
ARCHITECTURE behavior OF ws2812_test IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT ws2812
    PORT(
         led_r : IN  std_logic_vector(7 downto 0);
         led_g : IN  std_logic_vector(7 downto 0);
         led_b : IN  std_logic_vector(7 downto 0);
         transmit : IN  std_logic;
         rst : IN  std_logic;
         clk_16MHz : IN  std_logic;
         sig : OUT  std_logic
        );
    END COMPONENT;
    

   --Inputs
   signal led_r : std_logic_vector(7 downto 0) := (others => '0');
   signal led_g : std_logic_vector(7 downto 0) := (others => '0');
   signal led_b : std_logic_vector(7 downto 0) := (others => '0');
   signal transmit : std_logic := '0';
   signal rst : std_logic := '0';
   signal clk_16MHz : std_logic := '0';

 	--Outputs
   signal sig : std_logic;

   -- Clock period definitions
   constant clk_16MHz_period : time := 62.5 ns;
 
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: ws2812 PORT MAP (
          led_r => led_r,
          led_g => led_g,
          led_b => led_b,
          transmit => transmit,
          rst => rst,
          clk_16MHz => clk_16MHz,
          sig => sig
        );

   -- Clock process definitions
   clk_16MHz_process :process
   begin
		clk_16MHz <= '0';
		wait for clk_16MHz_period/2;
		clk_16MHz <= '1';
		wait for clk_16MHz_period/2;
   end process;
 

   -- Stimulus process
   stim_proc: process
   begin		
      -- hold reset state for 100 ns.
      led_g <= "10000001";
		led_r <= "00000000";
		led_b <= "10000001";
		transmit <= '1';
		wait for clk_16MHz_period;
      transmit <= '0';
		
      -- insert stimulus here 

      wait;
   end process;

END;
