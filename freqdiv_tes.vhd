--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   14:53:13 10/06/2015
-- Design Name:   
-- Module Name:   /home/jblumenkamp/FPGA/avnet_spartana3/helloword/freqdiv_tes.vhd
-- Project Name:  helloword
-- Target Device:  
-- Tool versions:  
-- Description:   
-- 
-- VHDL Test Bench Created by ISE for module: freqdiv
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
 
ENTITY freqdiv_tes IS
END freqdiv_tes;
 
ARCHITECTURE behavior OF freqdiv_tes IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT freqdiv
    PORT(
         clkin : IN  std_logic;
         rst : IN  std_logic;
         clkout : OUT  std_logic;
         fac : IN  std_logic_vector(15 downto 0)
        );
    END COMPONENT;
    

   --Inputs
   signal clkin : std_logic := '0';
   signal fac : std_logic_vector(15 downto 0) := "0000000000000010";
   signal rst : std_logic := '0';

     --Outputs
   signal clkout : std_logic;

   -- Clock period definitions
   constant clkin_period : time := 62.5 ns; --16MHz
BEGIN
    -- Instantiate the Unit Under Test (UUT)
   uut: freqdiv PORT MAP (
          clkin => clkin,
          rst => rst,
          clkout => clkout,
          fac => fac
        );

   -- Clock process definitions
   clkin_process :process
   begin
        clkin <= '0';
        wait for clkin_period/2;
        clkin <= '1';
        wait for clkin_period/2;
   end process;

   -- Stimulus process
   stim_proc: process
   begin        
      --wait for 100 ms;    
        rst <= '1';
      wait for clkin_period;
        rst <= '0';
        
      wait;
   end process;
END;
