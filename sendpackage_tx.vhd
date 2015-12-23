----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    10:49:05 10/15/2015 
-- Design Name: 
-- Module Name:    sendpackage_tx - Behavioral 
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

entity sendpackage_tx is
    Port ( clk : in  STD_LOGIC;
           rst : in  STD_LOGIC;
           fifo_data : out  STD_LOGIC_VECTOR (7 downto 0);
           fifo_full : in  STD_LOGIC;
           fifo_we : out  STD_LOGIC;
           reg : in  STD_LOGIC_VECTOR (6 downto 0); -- register to access
           rw : in  STD_LOGIC;-- read or write access?
           data : in  STD_LOGIC_VECTOR (7 downto 0); -- data (if write access)
           send : in  STD_LOGIC; -- send data
           ready : out  STD_LOGIC); -- data sent
end sendpackage_tx;

architecture Behavioral of sendpackage_tx is
    type state_main is (idle, send_reg, send_dat, send_chk);
    signal current_state : state_main := idle;
    signal chk : unsigned(7 downto 0); -- checksum
begin
    PROC_TRANSMIT: process (clk, rst)
    begin
        if clk'event and clk = '1' then
            if rst = '1' then
                current_state <= idle;
                ready <= '1';
            else
                case current_state is
                    when idle =>
                        fifo_we <= '0';
                        ready <= '1'; -- ready to take data
                        if send = '1' then
                            ready <= '0';
                            fifo_we <= '1'; -- transmit data into fifo in the enxt four cylces (we has to be 1 the whole time)
                            fifo_data <= "01010101"; -- start byte
                            chk <= "01010101"; -- initialize check sum with start byte
                            current_state <= send_reg;
                        end if;
                    when send_reg =>
                        fifo_data(6 downto 0) <= reg;
                        fifo_data(7) <= rw;
                        chk <= chk + unsigned(rw & reg);
                        current_state <= send_dat;
                    when send_dat =>
                        fifo_data <= data;
                        chk <= chk + unsigned(data);
                        current_state <= send_chk;
                    when send_chk =>
                        fifo_data <= std_logic_vector(chk);
                        current_state <= idle;
                end case;
            end if;
        end if;
    end process;
end Behavioral;

