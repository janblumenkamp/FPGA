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
	type led_value_arr_t is array(2 downto 0) of std_logic_vector(7 downto 0);
		signal led_value: led_value_arr_t := (others=>(others=>'0')); -- Helligkeit der 1. LED
	type count_arr_t is array(1 downto 0) of std_logic_vector(15 downto 0);
		signal count: count_arr_t := (others=>(others=>'0')); -- Aufdimmen der LED
	
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
	
begin
	-- PWM Module:
	PWM_1 : entity work.pwm port map(clk=>clk,
												rst=>rst,
												output=>led(0),
												pwmval=>led_value(0)); -- PWM Modul 1
	PWM_2 : entity work.pwm port map(clk=>clk,
												rst=>rst,
												output=>led(1),
												pwmval=>led_value(1)); -- PWM Modul 2
	PWM_3 : entity work.pwm port map(clk=>clk,
												rst=>rst,
												output=>led(2),
												pwmval=>led_value(2)); -- PWM Modul 3
												
	-- Frequenzteiler serielle Schnittstelle
	FREQ_SERIAL_RX : entity work.freqdiv port map(clkin=>clk,
																 rst=>rst,
																 clkout=>serial_rx_clk,
																 fac=>"0000000000110011"); -- Frequenzteiler für UART Clock (16000000/(00110011 + 1) ~ 19200Baud*16)
	FREQ_SERIAL_TX : entity work.freqdiv port map(clkin=>clk,
																 rst=>rst,
																 clkout=>serial_tx_clk,
																 fac=>"0000001100111111"); -- Frequenzteiler für UART Clock (16000000/(1100111111 + 1) ~ 19200Baud)
	
	-- Seriellen Module
	SERIAL_RX : entity work.serial8n1_rx port map(clk_baudx16=>serial_rx_clk,
																 rst=>rst,
																 rx=>rx,
																 clr=>serial_rx_clear,
																 data=>serial_rx_data,
																 newdata=>serial_rx_data_new);
	SERIAL_TX : entity work.serial8n1_tx port map(clk_baud=>serial_tx_clk,
																 rst=>rst,
																 tx=>tx,
																 send=>serial_tx_send,
																 ready=>serial_tx_ready,
																 data=>serial_tx_data);
	
	FIFO_RX : entity work.fifo port map(clk=>clk,
														  rst=>rst,
														  input=>serial_rx_data,
														  we=>fifo_rx_we,
														  output=>fifo_rx_data,
														  re=>fifo_rx_re,
														  empty=>fifo_rx_empty,
														  full=>fifo_rx_full);
	
	-- Prozess zum entgegennehmen der seriellen Daten undlegen in den FIFO
	PROC_RX: process (clk, rst)
	begin
		if clk'event and clk = '1' then
			if rst = '1' then -- Reset
				fifo_rx_we <= '0';
			else
				if serial_rx_clear = '1' and serial_rx_data_new = '0' then -- wenn der reset für die serielle Leitung im letzten Takt ausgeführt wurde den reset löschen, damit neue Daten empfangen werden können.
					serial_rx_clear <= '0';
					fifo_rx_we <= '0';
				elsif serial_rx_data_new = '1' then -- neue Daten vorhanden
					if fifo_rx_full = '0' then -- wenn der fifo noch nicht voll ist!
						fifo_rx_we <= '1';
					end if;
					serial_rx_clear <= '1'; -- Die Daten aus dem seriellen register liegen nun auf jeden Fall am EIngang des Fifos an, nun einfach we schalten und das Emfpangsmodul clearen
				end if;
			end if;
		end if;
	end process;
	
	CALC_LED : process (clk, rst) -- berechne auf und abschwellen der led Prozess (auf und abschwellen der LED)
	begin
		if clk'event and clk = '1' then
			if rst = '1' then -- Reset
				count(0) <= "0000000000000000";
				count(1) <= "0000000000000000";
				
				fifo_rx_re <= '0';
				
				led_value(0) <= (led_value(0)'range=>'0');
				led_value(1) <= (led_value(1)'range=>'0');
				led_value(2) <= "00000000";
			else
				for i in 0 to 1 loop
					if (count(i) = "01010111111001000") then
						if (led_value(i) = (led_value(i)'range=>'1')) then -- Alle bits gesetzt
							led_value(i) <= (led_value(i)'range=>'0'); -- setze alle bits auf 0
						else
							led_value(i) <= std_logic_vector( unsigned(led_value(i)) + 1 );
						end if;
						count(i) <= "0000000000000000";
					elsif btn (i) = '0' then
						count(i) <= std_logic_vector(unsigned(count(i)) + 1);
					end if;
				end loop;
				
				-- button
				led(3) <= btn(2);				
				
				-- FIFO auslesen
				if fifo_rx_empty = '0' and fifo_rx_re = '0' then -- fifo hat neue Daten und wir haben das Abfrage bit noch nicht gesetzt
					fifo_rx_re <= '1';
				elsif fifo_rx_empty = '0' and fifo_rx_re = '1' then -- fifo hat neue Daten und wir haben das Abfragebit gesetzt
					led_value(2) <= fifo_rx_data;
					
					if serial_tx_ready = '1' then -- send input to tx
						serial_tx_data <= serial_rx_data;
						serial_tx_send <= '1';
					end if;
					
					if fifo_rx_empty = '0' then -- wenn der fifo nun leer ist, darf auch nicht weiter ausgelesen weden
						fifo_rx_re <= '0';
					end if;
				end if;

				if serial_tx_ready = '0' then -- sendemodul hat begonnen, daten zu senden
					serial_tx_send <= '0'; -- lösche senden flag, damit es nicht bald direkt erneut gesendet wird
				end if;
			end if;
		end if;
	end process;
end Behavioral;