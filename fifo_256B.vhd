----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    11:20:12 10/12/2015 
-- Design Name: 
-- Module Name:    fifo_256B - Behavioral 
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

entity fifo is
    Port ( clk : in  STD_LOGIC;
           rst : in  STD_LOGIC;
           input : in  STD_LOGIC_VECTOR (7 downto 0);
           we : in  STD_LOGIC;
           output : out  STD_LOGIC_VECTOR (7 downto 0);
           re : in  STD_LOGIC;
			  empty: out STD_LOGIC;
           full: out STD_LOGIC);
end fifo;

architecture Behavioral of fifo is
	
	type stack_t is array (0 to 31) of std_logic_vector(7 downto 0); -- eigentlicher Speicher, 256 Byte
		signal stack : stack_t := (others => (others => '0'));
		signal stack_write: unsigned(4 downto 0) := (others=>'0'); -- Adresse vor dem neusten Bytes im Stack (nächste leere Zelle)
		signal stack_read: unsigned(4 downto 0) := (others=>'0'); -- Adresse des ältesten Bytes im Stack (muss dann auf Data_out ausgegeben werden und inkrementiert über next)
begin

	proc_in: process (clk, rst, we, re, stack) -- prozess zum Ablegen eines neuen Elements
	begin
		if clk'event and clk = '1' then
			if rst = '1' then
				output <= "00000000";
				full <= '0';
				empty <= '1';
				
				stack <= (others => (others => '0'));
				stack_write <= (stack_write'range=>'0');
				stack_read <= (stack_read'range=>'0');
			else
				-- write access
				if we = '1' then -- neue Daten vorhanden
					stack(to_integer(stack_write)) <= input; -- Daten in stack übertragen
					stack_write <= stack_write + 1; -- inkrementiere Adresse
					
					empty <= '0';
						
					if to_unsigned(to_integer(stack_write) + 1, stack_write'length) = stack_read then
						full <= '1';
					else
						full <= '0';
					end if;
				end if; -- neue Daten?
				
				-- read access
				if re = '1' then -- es sollen Daten ausgelesen werden
					stack_read <= stack_read + 1; -- inkrementiere Adresse
					
					full <= '0';
						
					if to_unsigned(to_integer(stack_read) + 1, stack_read'length) = stack_write then
						empty <= '1';
					else
						empty <= '0';
					end if;
				end if; -- neue Daten?
				output <= stack(to_integer(stack_read)); -- auf dem Ausgang soll immer die aktuelle lese Adresse liegen
			end if; -- reset?
		end if; -- clock?
	end process;
end Behavioral;

