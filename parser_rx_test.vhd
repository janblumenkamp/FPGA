--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   17:30:08 10/13/2015
-- Design Name:   
-- Module Name:   /home/jblumenkamp/FPGA/avnet_spartana3/tutorium/parser_rx_test.vhd
-- Project Name:  tutorium
-- Target Device:  
-- Tool versions:  
-- Description:   
-- 
-- VHDL Test Bench Created by ISE for module: parser_rx
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
 
ENTITY parser_rx_test IS
END parser_rx_test;
 
ARCHITECTURE behavior OF parser_rx_test IS 
   --Inputs
   signal clk : std_logic := '0';
   signal rst : std_logic := '0';

   -- Clock period definitions
   constant clk_period : time := 62.5 ns;
	
	signal serial_rx_data: std_logic_vector(7 downto 0) := (others=>'0'); -- Seriell empfangenes Signal (8 bit)
	
	-- fifo
	signal fifo_rx_data: std_logic_vector(7 downto 0) := (others=>'0'); -- Ausgang des Fifos! Der Eingang ist direkt die serielle Schnittstelle!
	signal fifo_rx_we: std_logic := '0'; -- write enable
	signal fifo_rx_re: std_logic := '0'; -- read enable
	signal fifo_rx_empty: std_logic;
	signal fifo_rx_full: std_logic;
	
	-- parser
	signal parser_rx_we : std_logic; -- hat der Parser ein neues Signal?
	signal parser_rx_reg : std_logic_vector(6 downto 0); -- register des signals
	signal parser_rx_rw : std_logic; -- möchte der Master Register lesen oder schreiben?
	signal parser_rx_out : std_logic_vector(7 downto 0); -- wert des registers
	
BEGIN

		-- FIFO für den Empfang der Daten
	FIFO_RX : entity work.fifo port map(
		clk=>clk,
		rst=>rst,
		input=>serial_rx_data,
		we=>fifo_rx_we,
		output=>fifo_rx_data,
		re=>fifo_rx_re,
		empty=>fifo_rx_empty,
		full=>fifo_rx_full
	);
		
	-- Parser für das Protokoll
	PARSER_RX : entity work.parser_rx port map(
		clk=>clk,
		rst=>rst,
		input_raw=>fifo_rx_data, -- verbinde eingang direkt mit FIFO
		re_raw=>fifo_rx_re, -- fifo re
		no_newdata_raw=> fifo_rx_empty, -- fifo_rx_empty ist 1, wenn es leer ist und not fifo_rx_empty ist somit 1, wenn es irgendwelche Daten im FIFO gibt
		
		out_we=>parser_rx_we, -- hat der Parser ein neues Signal?
		out_rw=>parser_rx_rw, -- möchte der sender in das register schreiben oder das register lesen?
		out_adr=>parser_rx_reg, -- register
		out_data=>parser_rx_out
	);
	
   -- Clock process definitions
   clk_process :process
   begin
		clk <= '0';
		wait for clk_period/2;
		clk <= '1';
		wait for clk_period/2;
   end process;
 
	proc_sendserial: process
	begin
		wait for clk_period * 5;
		fifo_rx_we <= '1';
		serial_rx_data <= "01010101"; -- start
		wait for clk_period;
		fifo_rx_we <= '0';
		wait for clk_period*10;
		fifo_rx_we <= '1';
		serial_rx_data <= "00000001"; -- register
		wait for clk_period;
		fifo_rx_we <= '0';
		wait for clk_period*10;
		fifo_rx_we <= '1';
		serial_rx_data <= "00110011"; -- wert
		wait for clk_period;
		fifo_rx_we <= '0';
		wait for clk_period*10;
		fifo_rx_we <= '1';
		serial_rx_data <= "11000000"; -- chk
		wait for clk_period;
		fifo_rx_we <= '0';
		wait for clk_period*50;
		
		fifo_rx_we <= '1';
		serial_rx_data <= "01010101"; -- start
		wait for clk_period;
		fifo_rx_we <= '0';
		wait for clk_period*10;
		fifo_rx_we <= '1';
		serial_rx_data <= "00000010"; -- register
		wait for clk_period;
		fifo_rx_we <= '0';
		wait for clk_period*10;
		fifo_rx_we <= '1';
		serial_rx_data <= "00111111"; -- wert
		wait for clk_period;
		fifo_rx_we <= '0';
		wait for clk_period*10;
		fifo_rx_we <= '1';
		serial_rx_data <= "11100000"; -- chk
		wait for clk_period;
		fifo_rx_we <= '0';
		
		wait;-- for clk_period*10;
	end process;

	proc_pars: process
	begin
		if parser_rx_we = '1' then
			report "Newdata";
		end if;
		wait for clk_period;
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
