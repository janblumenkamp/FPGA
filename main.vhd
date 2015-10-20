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
			  btn : in STD_LOGIC_VECTOR (2 downto 0); -- 3 Push buttons
			  scl : out STD_LOGIC;
			  sda : inout STD_LOGIC
			 );
end main;

architecture Behavioral of main is
	type comm_arr_t is array(6 downto 0) of std_logic_vector(7 downto 0); -- 4 LED, 1 btn (4 bit) und 2 temperatur
		signal comm_reg: comm_arr_t  := (others=>(others=>'0')); -- Puffer/Register für die serielle Kommunikation
	
	-- serielles Empfangmodul
	signal serial_rx_clk: std_logic := '0'; -- Clockrate der seriellen Schnittstelle (16 x der Baudrate)
	signal serial_rx_clear: std_logic := '0'; -- löschen des newdata flags
	signal serial_rx_data: std_logic_vector(7 downto 0) := (others=>'0'); -- Seriell empfangenes Signal (8 bit)
	--signal serial_rx_error: std_logic := '0'; -- Flag: Fehler beim Empfang? (muss ggf. manuell gecleart werden)
	signal serial_rx_data_new: std_logic := '0'; -- Flag: befinden sich neue Daten im Signal?
	--FIFO empfang
	signal fifo_rx_data: std_logic_vector(7 downto 0) := (others=>'0'); -- Ausgang des Fifos! Der Eingang ist direkt die serielle Schnittstelle!
	signal fifo_rx_we: std_logic := '0'; -- write enable
	signal fifo_rx_re: std_logic := '0'; -- read enable
	signal fifo_rx_empty: std_logic;
	signal fifo_rx_full: std_logic;
	--FIFO sender
	signal fifo_tx_data: std_logic_vector(7 downto 0) := (others=>'0'); -- Eingang des Fifos! Der Ausgang ist direkt mit der seriellen Schnittstelle verbunden!
	signal fifo_tx_we: std_logic := '0'; -- write enable
	signal fifo_tx_re: std_logic := '0'; -- read enable
	signal fifo_tx_empty: std_logic;
	signal fifo_tx_full: std_logic;
	
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
	-- sendpackage
	signal sendpackage_tx_reg : std_logic_vector(6 downto 0) := (others=>'0');
	signal sendpackage_tx_rw : std_logic := '0';
	signal sendpackage_tx_data : std_logic_vector(7 downto 0) := (others=>'0');
	signal sendpackage_tx_send : std_logic := '0';
	signal sendpackage_tx_ready : std_logic;
	
	-- i2c master
	signal i2c_master_clockx4 : std_logic;
	signal i2c_master_slave_adr : std_logic_vector(6 downto 0) := (others=>'0'); -- Slave Adresse
	signal i2c_master_rw : std_logic; -- Schreib oder Lesezugriff
	signal i2c_master_transmit : std_logic; -- Starte transmit
	signal i2c_master_ready : std_logic; -- hat das Modul die aktuelle transaktion beendet?
	signal i2c_master_data_in : std_logic_vector(7 downto 0) := (others=>'0'); -- Daten vom Master zum Slave
	signal i2c_master_data_out : std_logic_vector(7 downto 0) := (others=>'0'); -- Daten vom Slave zum Master
	-- tmp100 Temperatursensor
	signal i2c_master_delay : unsigned(19 downto 0) := (others => '0'); -- Delay zwischen dem Abfragen zweier Werte (am ANfang auch zur Initialisierung benötigt)
	type i2c_read_state_t is (idle, transmit_reg, read_msb, read_lsb); -- State machine für eine Read Transaktion zum Temperatursensor
		signal tmp_100_read_state : i2c_read_state_t := idle;
	signal tmp100_data : std_logic_vector(15 downto 0) := (others=>'0'); -- Rohe Daten des Temperatursensors zum Übertragen in die Register
	type i2c_write_state_t is (idle, transmit_reg, transmit_dat); -- State machine für eine write Transaktion zum Temperatursensor (1 byte)
		signal tmp_100_write_state : i2c_write_state_t := idle;
	signal tmp100_initialized : unsigned(1 downto 0) := "00"; -- Wurde der Sensor initialisiert? Muss vektor sein, weil das I2C Modul erst eine Trash-Wandlung braucht...
begin
	-- PWM Module:
	PWM_1 : entity work.pwm port map(
		clk=>clk,
		rst=>rst,
		output=>led(0),
		pwmval=>comm_reg(0)
	); -- PWM Modul 1
	PWM_2 : entity work.pwm port map(
		clk=>clk,
		rst=>rst,
		output=>led(1),
		pwmval=>comm_reg(1)
	); -- PWM Modul 2
	PWM_3 : entity work.pwm port map(
		clk=>clk,
		rst=>rst,
		output=>led(2),
		pwmval=>comm_reg(2)
	); -- PWM Modul 3
	PWM_4 : entity work.pwm port map(
		clk=>clk,
		rst=>rst,
		output=>led(3),
		pwmval=>comm_reg(3)
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
	FREQ_I2C_4 : entity work.freqdiv port map(
		clkin=>clk,
		rst=>rst,
		clkout=>i2c_master_clockx4,
		fac=>"0000000000100111"
	); -- Frequenzteiler für I2C Clock (400 kHz -> 50kHz I2C Clock)
	
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
	-- FIFO zum Puffern der zu sendenden Daten
	FIFO_TX : entity work.fifo port map(
		clk=>clk,
		rst=>rst,
		input=>fifo_tx_data,
		we=>fifo_tx_we,
		output=>serial_tx_data,
		re=>fifo_tx_re,
		empty=>fifo_tx_empty,
		full=>fifo_tx_full
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
	SENDPACKAGE_TX: entity work.sendpackage_tx port map(
		clk=>clk,
		rst=>rst,
		fifo_data=>fifo_tx_data, -- verbindung zum eingang des fifo
		fifo_full=>fifo_tx_full, -- ist der fifo voll?
		fifo_we=>fifo_tx_we, -- schreibe daten in den fifo
		reg=>sendpackage_tx_reg, -- register, das angesprochen werden soll
		rw=>sendpackage_tx_rw, -- lese oder schreibe in das Register?
		data=>sendpackage_tx_data, -- ggf. Daten (schreibzugriff)
		send=>sendpackage_tx_send, -- übernehme daten (ein takt high/bis ready low ist)
		ready=>sendpackage_tx_ready -- daten gesendet
	);
	
	-- i2c master Modul
	I2C_MASTER: entity work.i2c_master PORT MAP (
		clk => clk,
		rst => rst,
		clk_i2c_4 => i2c_master_clockx4,
		adr => i2c_master_slave_adr,
		rw => i2c_master_rw,
		transmit => i2c_master_transmit,
		ready => i2c_master_ready,
		data_in => i2c_master_data_in,
		data_out => i2c_master_data_out,
		scl => scl,
		sda => sda
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
					if fifo_rx_full = '0' then -- wenn der fifo noch nicht voll ist!
						fifo_rx_we <= '1';
					end if;
					serial_rx_clear <= '1'; -- Die Daten aus dem seriellen register liegen nun auf jeden Fall am EIngang des Fifos an, nun einfach we schalten und das Emfpangsmodul clearen
				end if;
			end if;
		end if;
	end process;
	
	-- Prozess zum senden der seriellen Daten (übernahme aus den FIFO in die serielle Schnittstelle)
	PROC_TX: process (clk, rst)
	begin
		if clk'event and clk = '1' then
			if rst = '1' then -- Reset
				serial_tx_send <= '0';
			else
				fifo_tx_re <= '0'; -- darf nur für einen Takt 1 bleiben!
				if serial_tx_ready = '0' and serial_tx_send = '1' then -- sendemodul sendet gerade, das senden flag kann nun gelöscht werden
					serial_tx_send <= '0'; -- lösche senden flag, damit es nicht bald direkt erneut gesendet wird
					fifo_tx_re <= '1'; -- inkrementiere adresse, nachdem gesendet wurde (bereite nächstes byte vor)
				elsif serial_tx_ready = '1' and serial_tx_send = '0' then
					if fifo_tx_empty = '0' then -- es liegen noch Daten im FIFO
						-- der fifo ausgang ist direkt mit der seriellen Schnittstelle verbunden, es muss einfach nur die adresse inkrementiert werden
						serial_tx_send <= '1';
					end if;
				end if;
			end if;
		end if;
	end process;
	
	-- Prozess für das Abfragen und initialisieren des Temperatursensors über I2C
	PROC_TEMP: process (clk, rst)
	begin
		if clk'event and clk = '1' then
			if rst = '1' then -- Reset
				tmp_100_read_state <= idle;
				i2c_master_transmit <= '0';
				tmp100_initialized <= "00";
			else
				if tmp100_initialized = "10" then -- Initialisierung zum Sensor abgeschlosse
					case tmp_100_read_state is
						when idle =>
							if i2c_master_delay = 0 then -- Timer abgelaufen, neue Transaktion
								i2c_master_slave_adr <= "1001000"; -- Adresse des Temperatursensors
								i2c_master_rw <= '0'; -- Schreibzugriff (schreiben des Registers, welches ausgelesen werden soll)
								i2c_master_data_in <= "00000000"; -- Temperaturregister
								i2c_master_transmit <= '1'; -- starte transaktion
								if i2c_master_ready = '0' then -- jetzt hat das Modul die Transaktion begonnen, nun darf der state gewechselt werden
									i2c_master_delay <= "11111111111111111111"; --  Timer neu starten
									tmp_100_read_state <= transmit_reg;
								end if;
							else
								i2c_master_delay <= i2c_master_delay - 1;
							end if;
						when transmit_reg =>
							if i2c_master_ready = '0' then -- Übertragung beendet
								i2c_master_rw <= '1'; -- Schalte nun um auf Lesezugriff
								tmp_100_read_state <= read_msb;
							end if;
						when read_msb =>
							if i2c_master_ready = '0' then -- Byte eingelesen
								tmp100_data(7 downto 0) <= i2c_master_data_out;
								tmp_100_read_state <= read_lsb;
							end if;
						when read_lsb =>
							if i2c_master_ready = '0' then -- Byte eingelesen
								tmp100_data(15 downto 8) <= i2c_master_data_out;
								i2c_master_transmit <= '0'; -- Wir wollen nichts mehr senden o.ä. - modul kann stop generieren
								tmp_100_read_state <= idle;
							end if;
						when others =>
							tmp_100_read_state <= idle;
					end case;
				else -- Initialisieren
					case tmp_100_write_state is
						when idle =>
							if i2c_master_delay = 0 then -- Timer abgelaufen, neue Transaktion
								i2c_master_slave_adr <= "1001000"; -- Adresse des Temperatursensors
								i2c_master_rw <= '0'; -- Schreibzugriff (schreiben des Registers, welches beschrieben werden soll)
								i2c_master_data_in <= "00000001"; -- Konfigurationsregister
								i2c_master_transmit <= '1'; -- starte transaktion
								if i2c_master_ready = '0' then -- jetzt hat das Modul die Transaktion begonnen, nun darf der state gewechselt werden
									i2c_master_delay <= "00001111111111111111"; --  Timer neu starten
									tmp_100_write_state <= transmit_reg;
								end if;
							else
								i2c_master_delay <= i2c_master_delay - 1;
							end if;
						when transmit_reg =>
							if i2c_master_ready = '0' then -- Übertragung beendet
								i2c_master_data_in <= "01000000"; -- 11 bit Auflösung
								tmp_100_write_state <= transmit_dat;
							end if;
						when transmit_dat =>
							if i2c_master_ready = '0' then -- Byte eingelesen
								i2c_master_transmit <= '0'; -- Wir wollen nichts mehr senden o.ä. - modul kann stop generieren
								tmp_100_write_state <= idle;
								tmp100_initialized <= tmp100_initialized + 1; -- Mache initialisierung mehrmals, weil die erste Übertragung immer fehlschlägt...
							end if;
						when others =>
							tmp_100_write_state <= idle;
					end case;
				end if;
			end if;
		end if;
	end process;
	
	-- Prozess für die Register und das verarbeiten von Anfragen über die serielle Schnittstelle
	PROC_REG: process (clk, rst)
	begin
		if clk'event and clk = '1' then
			if rst = '1' then -- Reset
				comm_reg <= (others=>(others=>'0'));
			else
				sendpackage_tx_send <= '0'; -- wenn zuvor eine Leseanfrage gesendet wurde das flag nun auf jeden fall löschen (Sendeprozess muss eingeleitet worden sein).
				if parser_rx_we = '1' then -- Paket empfangen
					if parser_rx_rw = '1' then -- write access
						comm_reg(to_integer(unsigned(parser_rx_reg(2 downto 0)))) <= parser_rx_out;
					else -- es sollte ein Paket gelesen werden. eigentlich müsste hier noch auf ready flag geprüft werden...
						sendpackage_tx_reg <= parser_rx_reg;
						sendpackage_tx_rw <= '1';
						sendpackage_tx_data <= comm_reg(to_integer(unsigned(parser_rx_reg(2 downto 0))));
						sendpackage_tx_send <= '1';
					end if;
				else -- hier können spontane Sendeanfragen bearbeitet werden (damit eventuelle Anfragen nicht verloren gehen)
					if btn /= comm_reg(4)(2 downto 0) and sendpackage_tx_ready = '1' then -- Änderung im Status einer der Buttons und serielle schnittstelle frei
						comm_reg(4)(2 downto 0) <= btn; -- Speichere register und sende Datenpaket an den Master
						sendpackage_tx_reg <= "0000100";
						sendpackage_tx_rw <= '1'; -- write
						sendpackage_tx_data <= "00000" & btn;
						sendpackage_tx_send <= '1';
					elsif tmp100_data(7 downto 0) /= comm_reg(5) and sendpackage_tx_ready = '1' then -- Low Byte des Temperatursensors
						comm_reg(5) <= tmp100_data(7 downto 0);
						sendpackage_tx_reg <= "0000101";
						sendpackage_tx_rw <= '1'; -- write
						sendpackage_tx_data <= tmp100_data(7 downto 0);
						sendpackage_tx_send <= '1';
					elsif tmp100_data(15 downto 8) /= comm_reg(6) and sendpackage_tx_ready = '1' then -- High Byte des Temperatursensors
						comm_reg(6) <= tmp100_data(15 downto 8);
						sendpackage_tx_reg <= "0000110";
						sendpackage_tx_rw <= '1'; -- write
						sendpackage_tx_data <= tmp100_data(15 downto 8);
						sendpackage_tx_send <= '1';	
					end if;
				end if;
			end if;
		end if;
	end process;
end Behavioral;