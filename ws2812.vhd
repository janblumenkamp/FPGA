----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    15:51:22 10/23/2015 
-- Design Name: 
-- Module Name:    ws2812 - Behavioral 
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

entity ws2812 is
    Port ( led_r : in  STD_LOGIC_VECTOR (7 downto 0);
           led_g : in  STD_LOGIC_VECTOR (7 downto 0);
           led_b : in  STD_LOGIC_VECTOR (7 downto 0);
           transmit : in  STD_LOGIC;
           rst : in  STD_LOGIC;
           clk_16MHz : in  STD_LOGIC;
			  sig : out STD_LOGIC);
end ws2812;

architecture Behavioral of ws2812 is
	type state_t is (idle, transmission, transmit_0, transmit_1, stop); -- State machine
	signal state : state_t := idle;
	signal led : std_logic_vector(23 downto 0); -- 24 bit (8r8g8b) für LED
	signal bit_cnt : unsigned (4 downto 0) := (others=>'0'); -- Bit counter
	signal time_cnt : unsigned (6 downto 0) := (others=>'0'); -- Herunterskalieren der 16MHz auf 0,35us (6 Takte), 0,9us (14 Takte) und 50us (80 Takte)
begin

	PROC_TRANS: process (clk_16MHz, rst)
	begin
		if clk_16MHz'event and clk_16MHz = '1' then
			if rst = '1' then
				state <= idle;
			else
				case state is
					when idle =>
						sig <= '0';
						if transmit = '1' then
							bit_cnt <= "10111";
							led <= led_g & led_r & led_b; -- In dieser Reihenfolge von 0 bis 23 muss gesendet werden!
							state <= transmission;
						end if;
					when transmission =>
						time_cnt <= "0000000";
						if bit_cnt = "11111" then -- Frame Übertragung beendet
							state <= stop;
						else
							if led(to_integer(bit_cnt(4 downto 0))) = '1' then
								state <= transmit_1;
							else
								state <= transmit_0;
							end if;
						end if;
						bit_cnt <= bit_cnt - 1;
					when transmit_0 =>
						if time_cnt = 6 then
							sig <= '0';
						elsif time_cnt = 0 then
							sig <= '1';
						elsif time_cnt = 18 then
							state <= transmission;
						end if;
						time_cnt <= time_cnt + 1;
					when transmit_1 =>
						if time_cnt = 14 then
							sig <= '0';
						elsif time_cnt = 0 then
							sig <= '1';
						elsif time_cnt = 18 then
							state <= transmission;
						end if;
						time_cnt <= time_cnt + 1;
					when stop =>
						if time_cnt = 80 then
							state <= idle;
						end if;
						time_cnt <= time_cnt + 1;
					when others =>
						state <= idle;
				end case;
			end if;
		end if;
	end process;
end Behavioral;

