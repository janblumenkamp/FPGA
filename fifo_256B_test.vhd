--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   15:49:26 10/12/2015
-- Design Name:   
-- Module Name:   /home/jblumenkamp/FPGA/avnet_spartana3/Tutorium/fifo_test.vhd
-- Project Name:  helloword
-- Target Device:  
-- Tool versions:  
-- Description:   
-- 
-- VHDL Test Bench Created by ISE for module: fifo_256B
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
 
ENTITY fifo_test IS
END fifo_test;
 
ARCHITECTURE behavior OF fifo_test IS 
   --Inputs
   signal clk : std_logic := '0';
   signal rst : std_logic := '1';
   signal input : std_logic_vector(7 downto 0) := (others => '0');
   signal we : std_logic := '0';
   signal re : std_logic := '0';

	-- buffer
	type buff_t is array (0 to 255) of std_logic_vector(7 downto 0);
		signal buff : buff_t := (others => (others => '0'));
		
 	--Outputs
   signal output : std_logic_vector(7 downto 0);
   signal empty : std_logic;
   signal full : std_logic;

   -- Clock period definitions
   constant clk_period : time := 62.5 ns;
 
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: entity work.fifo_256B PORT MAP (
          clk => clk,
          rst => rst,
          input => input,
          we => we,
          output => output,
          re => re,
          empty => empty,
          full => full
        );

   -- Clock process definitions
   clk_process :process
   begin
		clk <= '0';
		wait for clk_period/2;
		clk <= '1';
		wait for clk_period/2;
   end process;

	-- Daten einlesen
	inp_process: process
		variable counter : unsigned (7 downto 0) := (others => '0');
	begin
		wait for clk_period*10; -- reset
		we <= '1';
		for i in 1 to 257 loop
			counter := counter + 1;
			input <= std_logic_vector(counter);
			wait for clk_period;
		end loop;
		we <= '0';
		counter := "00000000";
		wait for clk_period*5;
		re <= '1';
		for i in 1 to 260 loop
			counter := counter + 1;
			buff(to_integer(counter)) <= output;
			wait for clk_period*10;
		end loop;
		re <= '0';
		
		wait;
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
