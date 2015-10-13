----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    14:21:32 10/05/2015 
-- Design Name: 
-- Module Name:    pwm - Behavioral 
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

entity pwm is
    Port ( clk : in  STD_LOGIC;
			  rst : in STD_LOGIC;
           output : out  STD_LOGIC;
           pwmval : in  STD_LOGIC_VECTOR (7 downto 0)
			 );
end pwm;

architecture Behavioral of pwm is
	signal pwm_cnt: std_logic_vector (7 downto 0) := (others=>'0');
begin
	pwm: process (clk, rst) -- PWM Prozess
	begin
		if clk'event and clk = '1' then -- steigende Flanke
			if rst = '1' then -- synchroner Reset
				pwm_cnt <= (others=>'0');
				output <= '0';
			else -- kein reset
				if pwmval = "00000000" then
					output <= '0';
				else
					if (pwm_cnt = "11111111") then -- Alle bits gesetzt: Neuer Zyklus beginnt
						pwm_cnt <= (others=>'0'); -- Setze auf 0
						output <= '1';
					elsif (pwm_cnt = pwmval) then -- PWM Wert erreicht
						output <= '0';
					end if;
					pwm_cnt <= std_logic_vector( unsigned(pwm_cnt) + 1 );
				end if;
			end if;
		end if;
	end process;
end Behavioral;

