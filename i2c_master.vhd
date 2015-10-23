----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    14:39:34 10/19/2015 
-- Design Name: 
-- Module Name:    i2c_master - Behavioral 
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
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity i2c_master is
    Port ( clk : in  STD_LOGIC;
           rst : in  STD_LOGIC;
           clk_i2c_4 : in  STD_LOGIC;
           adr : in  STD_LOGIC_VECTOR (6 downto 0);
           rw : in  STD_LOGIC;
           transmit : in  STD_LOGIC;
           ready : out  STD_LOGIC := '1';
           data_in : in  STD_LOGIC_VECTOR (7 downto 0);
           data_out : out  STD_LOGIC_VECTOR (7 downto 0);
           scl : out  STD_LOGIC;
           sda : inout  STD_LOGIC);
end i2c_master;

architecture Behavioral of i2c_master is
	type state_t is (idle, gen_start, transmit_adr, transmit_data, receive_data, gen_stop); -- State machine für den Empfang
	signal state : state_t := idle;
	
	signal scl_int: STD_LOGIC := 'Z'; -- Internes SCL Signal
	signal sda_int: STD_LOGIC := 'Z'; -- internes SDA Signal
	
	signal cnt_clk: unsigned(2 downto 0) := "000"; -- Counter: In welchem Teil des I2C  Clock Zyklusses befinden wir uns gerade?
	signal cnt_byte: unsigned(3 downto 0) := "1001"; -- Mitzählen bei der Datenübertragung eines Bytes (Adresse + rw + ack oder data + ack)
	
	signal adr_int: std_logic_vector(6 downto 0); -- Adresse des Slaves (interne Kopie)
	signal rw_int: std_logic; -- rw bit (interne Kopie)
	signal data_in_int: std_logic_vector(7 downto 0); -- Zu übertragende Daten (interne Kopie)
	
	signal clk_i2c_4_old: std_logic := '0'; -- erkenne flanke (vergleich mit altem state)
begin
	clock: process (clk, rst)
	begin
		if clk'event and clk = '1' then
			if rst = '1' then
				scl_int <= 'Z';
				cnt_clk <= "000";
				state <= idle;
				sda_int <= 'Z';
				cnt_byte <= "1001";
				ready <= '1';
			else
				ready <= '1';
			
				if clk_i2c_4_old /= '1' and clk_i2c_4 = '1' then
					clk_i2c_4_old <= '1';
					if state /= idle then -- SCL nur toggeln, solange wirklich eine Übertragung stattfindet oder der letzte Clock Zyklus noch nicht beendet ist
						if cnt_clk = "011" then
							scl_int <= '0';
						elsif cnt_clk = "111" then
							scl_int <= '1';
						end if;
						cnt_clk <= cnt_clk + 1;
					else
						cnt_clk <= "000";
						scl_int <= '1';
					end if;
					
					case state is
						when idle =>
							if transmit = '1' then -- Beginne Übertragung
								state <= gen_start;
								adr_int <= adr;
								rw_int <= rw;
								data_in_int <= data_in;
								cnt_byte <= "1001";
								ready <= '0'; -- signalisiere übergeordnetem Modul, dass Register übernommen wurden
							end if;
						when gen_start =>
							if cnt_clk = "001" then
								sda_int <= '0';
							elsif cnt_clk = "100" then
								sda_int <= '1';
								state <= transmit_adr;
							end if;
						when transmit_adr =>
							if cnt_clk = "110" then
								if cnt_byte = "0010" then
									sda_int <= rw_int; -- rw byte
									cnt_byte <= cnt_byte - 1;
								elsif cnt_byte = "0001" then -- Ack?
									sda_int <= 'Z'; -- setze state auf open drain, damit slave ggf. ack senden kann
									cnt_byte <= cnt_byte - 1;
								elsif cnt_byte = "0000" then
									if rw_int = '0' then -- Schreibzugriff: Sende Daten zum Slave
										cnt_byte <= "1000";
										state <= transmit_data;
										sda_int <= data_in_int(7); -- Gebe erstes Bit schon aus
									else
										cnt_byte <= "1001"; -- TODO muss evtl geändert werden
										sda_int <= 'Z'; -- Schalte auf Open Drain, um Einlesen zu können
										state <= receive_data; -- Lesezugriff
									end if;
								else
									sda_int <= adr_int(to_integer(cnt_byte) - 3);
									cnt_byte <= cnt_byte - 1;
								end if;
							end if;
						when transmit_data =>
							if cnt_clk = "110" then
								if cnt_byte = "0001" then -- ack?
									sda_int <= 'Z'; -- setze state auf open drain, damit slave ggf. ack senden kann
									cnt_byte <= cnt_byte - 1;
									ready <= '0'; -- interface sgnalisiert, dass byte übertragen wurde
								elsif cnt_byte = "0000" then
									if transmit = '1' then
										if rw_int = rw and rw = '0' then
											cnt_byte <= "1000";
											--state <= transmit_data; -- es sollen immer noch Daten gesendet werden und wir haben rw in der zwischenzeit nicht geändert
											data_in_int <= data_in; -- Daten neu übernehmen
											sda_int <= data_in_int(7); -- Gebe erstes Bit schon aus
										else -- repeated start
											rw_int <= rw;
											cnt_byte <= "1001";
											sda_int <= '1'; -- setze state auf 1 (wichtig für die start considition)
											state <= gen_start; -- es wurde zwischenzeitlich umgeschaltet von senden auf lesen. Das heißt repeated start.
										end if;
									else
										sda_int <= '0'; -- setze state auf 0 (wichtig für die stop considition)
										state <= gen_stop; -- Es sollen keine Daten mehr übertragen werden, beende Kommunikation
									end if;
								else
									sda_int <= data_in_int(to_integer(cnt_byte) - 2);
									cnt_byte <= cnt_byte - 1;
								end if;
							end if;
						when receive_data =>
							if cnt_byte = "0001" and cnt_clk = "110" then -- ack
								sda_int <= '0'; -- setze state auf 0 (ack)
								--data_out <= "00000000";
								cnt_byte <= cnt_byte - 1;
								ready <= '0'; -- interface sgnalisiert, dass byte empfangen wurde
							elsif cnt_byte = "0000" and cnt_clk = "110" then
								if transmit = '1' then
									if rw_int = rw and rw = '1' then -- nächstes Byte entgegennehmen
										sda_int <= 'Z'; -- setze state auf z (entgegennehmen der Daten)
										cnt_byte <= "1001";
									else -- repeated start nicht zulässig! Breche Transaktion ab
										sda_int <= '0'; -- setze state auf 0 (wichtig für die stop considition)
										state <= gen_stop; -- Es sollen keine Daten mehr übertragen werden, beende Kommunikation
									end if;
								else
									sda_int <= '0'; -- setze state auf 0 (wichtig für die stop considition)
									state <= gen_stop; -- Es sollen keine Daten mehr übertragen werden, beende Kommunikation
								end if;
							elsif cnt_byte > "0001" and cnt_clk = "001" then
								data_out(to_integer(cnt_byte) - 2) <= sda; -- lese bit ein
								cnt_byte <= cnt_byte - 1;
							end if;
						when gen_stop =>
							if cnt_clk = "001" then
								sda_int <= '1';
								state <= idle;
							end if;
						when others =>
							state <= idle;
					end case;
				else
					clk_i2c_4_old <= '0';
				end if;
				
				if scl_int = '0' then
					scl <= '0';
				else
					scl <= 'Z'; -- Open Drain
				end if;
				
				if sda_int = '0' then
					sda <= '0';
				else
					sda <= 'Z'; -- Open Drain
				end if;
			end if;
		end if;
	end process;
end Behavioral;