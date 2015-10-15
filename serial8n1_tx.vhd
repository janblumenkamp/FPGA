----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    16:32:24 10/08/2015 
-- Design Name: 
-- Module Name:    serial8n1_tx - Behavioral 
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

entity serial8n1_tx is
    Port ( clk_baud : in  STD_LOGIC;
           rst : in  STD_LOGIC;
           tx : out  STD_LOGIC := '1';
           send : in  STD_LOGIC;
           ready : out  STD_LOGIC := '1';
           data : in  STD_LOGIC_VECTOR (7 downto 0));
end serial8n1_tx;

architecture Behavioral of serial8n1_tx is
	type state_main is (idle, start, transmit); -- State machine für das Senden
		signal current_state : state_main := idle;
	signal send_cnt : std_logic_vector (3 downto 0) := "0000"; -- counter für das Senden der 8 bits und sichern des stop bits
	signal tx_buffer : std_logic_vector (7 downto 0) := "00000000"; -- das Signal soll gepuffert werden, da unter Umständen schon neue Daten am eingang anliegen, obwohl das Signal noch nicht gesendet ist
begin
RECEIVE: process (clk_baud, rst, send)
	begin
		if clk_baud'event and clk_baud = '1' then -- kein reset und steigende Flanke
			if rst = '1' then -- synchroner reset
				tx <= '1';
				ready <= '1';
				
				current_state <= idle; -- architecture signals
				send_cnt <= "0000";
			else -- kein reset, normalbetrieb
				case current_state is 
					when idle =>
						if send = '1' then -- warte auf start signal
							ready <= '0';
							tx_buffer <= data;
							current_state <= start;
						end if;
					when start => -- start bit
						tx <= '0';
						current_state <= transmit;
					when transmit => -- eigentliche Daten
						if send_cnt = "1000" then -- 8 datenbits und stop bit als letztes
							send_cnt <= "0000";
							tx <= '1'; -- stop bit
							ready <= '1'; -- ready
							current_state <= idle; -- next state
						else
							tx <= tx_buffer(to_integer(unsigned(send_cnt(2 downto 0))));
							send_cnt <= std_logic_vector(unsigned(send_cnt) + 1); -- inkrementieren
						end if;
					when others =>
						current_state <= idle; -- idle, safe state
				end case;
			end if;
		end if;
	end process;
end Behavioral;

