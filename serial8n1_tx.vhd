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
    type state_main is (idle, start, transmit); -- State machine für transmission
        signal current_state : state_main := idle;
    signal send_cnt : std_logic_vector (3 downto 0) := "0000"; -- counter for transmission of 8 data bits and one stop bit
    signal tx_buffer : std_logic_vector (7 downto 0) := "00000000"; -- byte has to be buffered so that we can change the byte at the input during transmission
RECEIVE: process (clk_baud, rst, send)
    begin
        if clk_baud'event and clk_baud = '1' then
            if rst = '1' then
                tx <= '1';
                ready <= '1';
                
                current_state <= idle;
                send_cnt <= "0000";
            else
                case current_state is 
                    when idle =>
                        if send = '1' then -- wait for start
                            ready <= '0';
                            tx_buffer <= data;
                            current_state <= start;
                        end if;
                    when start => -- start bit
                        tx <= '0';
                        current_state <= transmit;
                    when transmit => -- actual data
                        if send_cnt = "1000" then -- 8 data bits and stop bit at the end
                            send_cnt <= "0000";
                            tx <= '1'; -- stop bit
                            ready <= '1'; -- ready
                            current_state <= idle; -- next state
                        else
                            tx <= tx_buffer(to_integer(unsigned(send_cnt(2 downto 0))));
                            send_cnt <= std_logic_vector(unsigned(send_cnt) + 1); -- increment
                        end if;
                    when others =>
                        current_state <= idle; -- idle, safe state
                end case;
            end if;
        end if;
    end process;
end Behavioral;

