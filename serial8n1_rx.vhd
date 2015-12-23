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
    Port ( clk_baudx16 : in  STD_LOGIC; -- Baud rate times 16
           rst : in  STD_LOGIC; -- reset
           rx : in  STD_LOGIC; -- receive input
           clr : in STD_LOGIC; -- master clear newdata
           data : out  STD_LOGIC_VECTOR (7 downto 0) := "00000000"; 
           newdata : out  STD_LOGIC := '0' -- set if a new byte was received
         );
end serial8n1_rx;

architecture Behavioral of serial8n1_rx is
    type state_main is (idle, get);
    signal current_state : state_main := idle;
    signal freqdiv : std_logic_vector (3 downto 0) := "0000"; -- counter for dividing and counting clk_baudx16
    signal get_cnt : std_logic_vector (3 downto 0) := "0000"; -- counter to receive 8 bits und save of stop bit
begin
    RECEIVE: process (clk_baudx16, rst, rx, clr)
    begin
        if clk_baudx16'event and clk_baudx16 = '1' then
            if rst = '1' then
                data <= "00000000";
                newdata <= '0';
                
                current_state <= idle;
                get_cnt <= "0000";
                freqdiv <= "0000";
            else
                case current_state is 
                    when idle =>
                        if rx = '0' then -- start signal, wait 8 cycles
                            if freqdiv = "0111" then
                                freqdiv <= "0000";
                                current_state <= get; -- next state
                            else
                                freqdiv <= std_logic_vector(unsigned(freqdiv) + 1);
                            end if;
                        end if;
                    when get =>
                        if freqdiv = "1111" then -- wait 16 Cycles (next Bit)
                            freqdiv <= "0000"; -- reset to wait for next bit
                            if get_cnt = "1000" then -- 8 data bits and stop bit at the end
                                get_cnt <= (others=>'0');
                                if rx = '1' then -- Stop bit
                                    newdata <= '1';
                                end if;
                                current_state <= idle; -- next state
                            else
                                data(to_integer(unsigned(get_cnt(2 downto 0)))) <= rx; 
                                get_cnt <= std_logic_vector(unsigned(get_cnt) + 1);
                            end if;
                        else
                            freqdiv <= std_logic_vector(unsigned(freqdiv) + 1);
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
