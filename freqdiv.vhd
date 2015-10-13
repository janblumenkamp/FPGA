----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    14:30:05 10/06/2015 
-- Design Name: 
-- Module Name:    freqdiv - Behavioral 
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

entity freqdiv is
    Port ( clkin : in  STD_LOGIC;
           rst : in  STD_LOGIC;
           clkout : out  STD_LOGIC;
           fac : in  STD_LOGIC_VECTOR (15 downto 0));
end freqdiv;

architecture Behavioral of freqdiv is
	signal cnt: std_logic_vector(15 downto 0) := (others=>'0'); -- counter
begin
	DIV: process (clkin, rst, fac)
	begin
		if (clkin'event and clkin = '1') then -- steigende Flanke
			if rst = '1' then -- synchroner Reset
				cnt <= (cnt'range=>'0');
			else -- kein reset
				if (cnt = fac) then
					clkout <= '1';
					cnt <= (cnt'range=>'0');
				else
					clkout <= '0';
					cnt <= std_logic_vector(unsigned(cnt) + 1 );
				end if;
			end if;
		end if;
	end process;
end Behavioral;

