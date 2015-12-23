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
    type stack_t is array (0 to 31) of std_logic_vector(7 downto 0); -- actual storage, 256 Byte
    signal stack : stack_t := (others => (others => '0'));
    signal stack_write: unsigned(4 downto 0) := (others=>'0');
    signal stack_read: unsigned(4 downto 0) := (others=>'0');
begin
    process(clk)
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
                if we = '1' then -- new data available
                    stack(to_integer(stack_write)) <= input;
                    stack_write <= stack_write + 1;
                    
                    empty <= '0';
                        
                    if to_unsigned(to_integer(stack_write) + 1, stack_write'length) = stack_read then
                        full <= '1';
                    else
                        full <= '0';
                    end if;
                end if;
                
                -- read access
                if re = '1' then -- read request
                    stack_read <= stack_read + 1;
                    
                    full <= '0';
                        
                    if to_unsigned(to_integer(stack_read) + 1, stack_read'length) = stack_write then
                        empty <= '1';
                    else
                        empty <= '0';
                    end if;
                end if;
                output <= stack(to_integer(stack_read));
            end if;
        end if;
    end process;
end Behavioral;

