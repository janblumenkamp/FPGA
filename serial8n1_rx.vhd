----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    13:55:45 10/06/2015 
-- Design Name: 
-- Module Name:    serial8n1_rx - Behavioral 
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
use ieee.numeric_std.all;

entity serial8n1_rx is
    Port ( clk_baudx16 : in  STD_LOGIC; -- Baud rate mal 16
           rst : in  STD_LOGIC; -- reset
           rx : in  STD_LOGIC; -- receive input
           clr : in STD_LOGIC; -- master clear newdata
			  data : out  STD_LOGIC_VECTOR (7 downto 0) := "00000000"; 
           newdata : out  STD_LOGIC := '0' -- Wird gesetzt, wenn ein neues Byte empfangen wurde
			  );
end serial8n1_rx;

architecture Behavioral of serial8n1_rx is
	type state_main is (idle, get); -- State machine für den Empfang
	signal current_state : state_main := idle;
	signal freqdiv : std_logic_vector (3 downto 0) := "0000"; -- counter zum Herunterteilen und zählen der clk_baudx16
	signal get_cnt : std_logic_vector (3 downto 0) := "0000"; -- counter für den Empfang der 8 bits und sichern des stop bits
begin
	RECEIVE: process (clk_baudx16, rst, rx, clr)
	begin
		if clk_baudx16'event and clk_baudx16 = '1' then -- kein reset und steigende Flanke
			if rst = '1' then -- synchroner reset
				data <= "00000000"; -- output signals
				newdata <= '0';
				
				current_state <= idle; -- architecture signals
				get_cnt <= "0000";
				freqdiv <= "0000";
			else -- kein reset, normalbetrieb
				case current_state is 
					when idle =>
						if rx = '0' then -- start signal, warte nun 8 Takte
							if freqdiv = "0111" then
								freqdiv <= "0000";
								current_state <= get; -- next state
							else
								freqdiv <= std_logic_vector(unsigned(freqdiv) + 1); -- inkrementieren
							end if;
						end if;
					when get =>
						if freqdiv = "1111" then -- warte 16 Takte (nächstes Bit)
							freqdiv <= "0000"; -- setze zurück um auf das nächste bit zu warten
							if get_cnt = "1000" then -- 8 datenbits und stop bit als letztes
								get_cnt <= (others=>'0');
								if rx = '1' then -- Stopbit
									newdata <= '1';
								end if;
								current_state <= idle; -- next state
							else
								data(to_integer(unsigned(get_cnt(2 downto 0)))) <= rx; 
								get_cnt <= std_logic_vector(unsigned(get_cnt) + 1); -- inkrementieren
							end if;
						else
							freqdiv <= std_logic_vector(unsigned(freqdiv) + 1); -- inkrementieren
						end if;
					when others =>
						current_state <= idle; -- idle, safe state
				end case;
			end if;
			
			if clr = '1' then -- lösche newdata flag
				newdata <= '0';
			end if;
		end if;
	end process;
end Behavioral;