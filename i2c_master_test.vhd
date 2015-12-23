--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   14:41:19 10/19/2015
-- Design Name:   
-- Module Name:   /home/jblumenkamp/FPGA/avnet_spartana3/tutorium/i2c_master_test.vhd
-- Project Name:  tutorium
-- Target Device:  
-- Tool versions:  
-- Description:   
-- 
-- VHDL Test Bench Created by ISE for module: i2c_master
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
 
ENTITY i2c_master_test IS
END i2c_master_test;
 
ARCHITECTURE behavior OF i2c_master_test IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
    

   --Inputs
   signal clk : std_logic := '0';
   signal rst : std_logic := '0';
   signal clk_i2c_4 : std_logic := '0';
   signal adr : std_logic_vector(6 downto 0) := (others => '0');
   signal rw : std_logic := '0';
   signal transmit : std_logic := '0';
   signal data_in : std_logic_vector(7 downto 0) := (others => '0');

    --BiDirs
   signal sda : std_logic;

     --Outputs
   signal ready : std_logic;
   signal data_out : std_logic_vector(7 downto 0);
   signal scl : std_logic;

   -- Clock period definitions
   constant clk_period : time := 62.5 ns;
 
BEGIN
 
    -- Frequenzteiler serielle Schnittstelle
    FREQ_I2C_4 : entity work.freqdiv port map(
        clkin=>clk,
        rst=>rst,
        clkout=>clk_i2c_4,
        fac=>"0000000000100111"
    ); -- Frequenzteiler für I2C Clock (50 kHz)
    
    -- Instantiate the Unit Under Test (UUT)
   uut: entity work.i2c_master PORT MAP (
          clk => clk,
          rst => rst,
          clk_i2c_4 => clk_i2c_4,
          adr => adr,
          rw => rw,
          transmit => transmit,
          ready => ready,
          data_in => data_in,
          data_out => data_out,
          scl => scl,
          sda => sda
        );
    
   -- Clock process definitions
   clk_process :process
   begin
        clk <= '0';
        wait for clk_period/2;
        clk <= '1';
        wait for clk_period/2;
   end process;
 
    data_ser: process -- main process serial interface
    begin
        wait for 1ms;
        data_in <= "00000010";
        rw <= '0';
        adr <= "1001000";
        transmit <= '1';
        wait until ready = '0';
        wait until ready = '1';
        data_in <= "10000010";
        wait until ready = '0';
        transmit <= '0';
        wait;
    end process;
    
   -- Stimulus process
   stim_proc: process
   begin        
      -- hold reset state for 100 ns.
        rst <= '1';
      wait for clk_period * 2;    
        rst <= '0';
      
      wait;
   end process;

END;
