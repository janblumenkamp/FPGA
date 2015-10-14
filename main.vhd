----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    14:16:24 10/02/2015 
-- Design Name: 
-- Module Name:    blink - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: 
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
----------------------------------------------------------------------------------
library IEEE;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_unsigned.all;
USE ieee.numeric_std.ALL;
------------------------- Main/LEDs ----------------------------------------------------

entity main is
    Port ( clk : in  STD_LOGIC;
			  rst : in STD_LOGIC;
			  rx : in STD_LOGIC;
           tx : out STD_LOGIC;
           led : out  STD_LOGIC_VECTOR (3 downto 0); -- 4 LEDs
			  btn : in STD_LOGIC_VECTOR (2 downto 0) -- 3 Push buttons
			 );
end main;

architecture Behavioral of main is
	type led_value_arr_t is array(3 downto 0) of std_logic_vector(7 downto 0);
		signal led_value: led_value_arr_t := (others=>(others=>'0')); -- Helligkeit der LEDs
	
	-- serielles Empfangmodul
	signal serial_rx_clk: std_logic := '0'; -- Clockrate der seriellen Schnittstelle (16 x der Baudrate)
	signal serial_rx_clear: std_logic := '0'; -- löschen des newdata flags
	signal serial_rx_data: std_logic_vector(7 downto 0) := (others=>'0'); -- Seriell empfangenes Signal (8 bit)
	--signal serial_rx_error: std_logic := '0'; -- Flag: Fehler beim Empfang? (muss ggf. manuell gecleart werden)
	signal serial_rx_data_new: std_logic := '0'; -- Flag: befinden sich neue Daten im Signal?
	--FIFO
	signal fifo_rx_data: std_logic_vector(7 downto 0) := (others=>'0'); -- Ausgang des Fifos! Der Eingang ist direkt die serielle Schnittstelle!
	signal fifo_rx_we: std_logic := '0'; -- write enable
	signal fifo_rx_re: std_logic := '0'; -- read enable
	signal fifo_rx_empty: std_logic;
	signal fifo_rx_full: std_logic;
	
	-- serielles Sendemodul
	signal serial_tx_clk: std_logic := '0'; -- Clockrate der seriellen Schnittstelle (Baudrate)
	signal serial_tx_send: std_logic := '0'; -- Clockrate der seriellen Schnittstelle (Baudrate)
	signal serial_tx_ready: std_logic := '0'; -- Clockrate der seriellen Schnittstelle (Baudrate)
	signal serial_tx_data: std_logic_vector(7 downto 0) := (others=>'0'); -- Clockrate der seriellen Schnittstelle (Baudrate)
	
	-- parser
	signal parser_rx_we : std_logic; -- hat der Parser ein neues Signal?
	signal parser_rx_reg : std_logic_vector(6 downto 0); -- register des signals
	signal parser_rx_rw : std_logic; -- möchte der Master Register lesen oder schreiben?
	signal parser_rx_out : std_logic_vector(7 downto 0); -- wert des registers
begin
	-- PWM Module:
	PWM_1 : entity work.pwm port map(
		clk=>clk,
		rst=>rst,
		output=>led(0),
		pwmval=>led_value(0)
	); -- PWM Modul 1
	PWM_2 : entity work.pwm port map(
		clk=>clk,
		rst=>rst,
		output=>led(1),
		pwmval=>led_value(1)
	); -- PWM Modul 2
	PWM_3 : entity work.pwm port map(
		clk=>clk,
		rst=>rst,
		output=>led(2),
		pwmval=>led_value(2)
	); -- PWM Modul 3
	PWM_4 : entity work.pwm port map(
		clk=>clk,
		rst=>rst,
		output=>led(3),
		pwmval=>led_value(3)
	); -- PWM Modul 3
												
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
		rx=>rx,
		clr=>serial_rx_clear,
		data=>serial_rx_data,
		newdata=>serial_rx_data_new
	);
	SERIAL_TX : entity work.serial8n1_tx port map(
		clk_baud=>serial_tx_clk,
		rst=>rst,
		tx=>tx,
		send=>serial_tx_send,
		ready=>serial_tx_ready,
		data=>serial_tx_data
	);
	
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
	
	-- Prozess zum entgegennehmen der seriellen Daten undlegen in den FIFO
	PROC_RX: process (clk, rst)
	begin
		if clk'event and clk = '1' then
			if rst = '1' then -- Reset
				fifo_rx_we <= '0';
			else
				fifo_rx_we <= '0'; -- darf nur für einen takt high sein
				if serial_rx_clear = '1' and serial_rx_data_new = '0' then -- wenn der reset für die serielle Leitung im letzten Takt ausgeführt wurde den reset löschen, damit neue Daten empfangen werden können.
					serial_rx_clear <= '0';
				elsif serial_rx_clear = '0' and serial_rx_data_new = '1' then -- neue Daten vorhanden, die serielle schnittstelle ist direkt mit dem fifo verbunden, weshalb hier kein register kopiert werden muss.
				
					--if serial_tx_ready = '1' then -- send input to tx
					--	serial_tx_data <= serial_rx_data;
					--	serial_tx_send <= '1';
					--end if;
					
					if fifo_rx_full = '0' then -- wenn der fifo noch nicht voll ist!
						fifo_rx_we <= '1';
					end if;
					serial_rx_clear <= '1'; -- Die Daten aus dem seriellen register liegen nun auf jeden Fall am EIngang des Fifos an, nun einfach we schalten und das Emfpangsmodul clearen
				end if;
				
				--if serial_tx_ready = '0' then -- sendemodul hat begonnen, daten zu senden
				--	serial_tx_send <= '0'; -- lösche senden flag, damit es nicht bald direkt erneut gesendet wird
				--end if;
			end if;
		end if;
	end process;
	
	PROC: process (clk, rst)
	begin
		if clk'event and clk = '1' then
			if rst = '1' then -- Reset
				led_value(0) <= (led_value(0)'range=>'0');
				led_value(1) <= (led_value(1)'range=>'0');
				led_value(2) <= (led_value(2)'range=>'0');
				led_value(3) <= (led_value(3)'range=>'0');
			else
				-- set led value from parser output
				if parser_rx_we = '1' then
					case parser_rx_reg is
						when "0000000" =>
							led_value(0) <= parser_rx_out;
						when "0000001" =>
							led_value(1) <= parser_rx_out;
						when "0000010" =>
							led_value(2) <= parser_rx_out;
						when "0000011" =>
							led_value(3) <= parser_rx_out;
						when others=>
					end case;
					led_value(to_integer(unsigned(parser_rx_reg))) <= parser_rx_out;
					
					if serial_tx_ready = '1' then -- send input to tx
						serial_tx_data(6 downto 0) <= parser_rx_reg;
						serial_tx_send <= '1';
					end if;
					
				end if;
				if serial_tx_ready = '0' then -- sendemodul hat begonnen, daten zu senden
					serial_tx_send <= '0'; -- lösche senden flag, damit es nicht bald direkt erneut gesendet wird
				end if;
			end if;
		end if;
	end process;
end Behavioral;