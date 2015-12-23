----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    14:39:34 10/19/2015 
-- Design Name: 
-- Module Name:    i2c_master - Behavioral 
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

entity i2c_master is
    Port ( clk : in  STD_LOGIC;
           rst : in  STD_LOGIC;
           clk_i2c_4 : in  STD_LOGIC;
           adr : in  STD_LOGIC_VECTOR (6 downto 0);
           rw : in  STD_LOGIC;
           transmit : in  STD_LOGIC;
           ready : out  STD_LOGIC := '1';
           data_in : in  STD_LOGIC_VECTOR (7 downto 0);
           data_out : out  STD_LOGIC_VECTOR (7 downto 0);
           scl : out  STD_LOGIC;
           sda : inout  STD_LOGIC);
end i2c_master;

architecture Behavioral of i2c_master is
    type state_t is (idle, gen_start, transmit_adr, transmit_data, receive_data, gen_stop); -- State machine
    signal state : state_t := idle;
    
    signal scl_int: STD_LOGIC := 'Z'; -- internal SCL Signal
    signal sda_int: STD_LOGIC := 'Z'; -- internes SDA Signal
    
    signal cnt_clk: unsigned(2 downto 0) := "000"; -- Counter: In which part of the i2c clock cycle are we?
    signal cnt_byte: unsigned(3 downto 0) := "1001"; -- Count the bits of the byte (adress + rw + ack or data + ack)
    
    signal adr_int: std_logic_vector(6 downto 0); -- slave address (internal)
    signal rw_int: std_logic; -- rw bit (internal)
    signal data_in_int: std_logic_vector(7 downto 0); -- data to transmit (internal)
    
    signal clk_i2c_4_old: std_logic := '0'; -- recognize edge (compare to last state)
begin
    clock: process (clk)
    begin
        if clk'event and clk = '1' then
            if rst = '1' then
                scl_int <= 'Z';
                cnt_clk <= "000";
                state <= idle;
                sda_int <= 'Z';
                cnt_byte <= "1001";
                ready <= '1';
            else
                ready <= '1';
            
                if clk_i2c_4_old /= '1' and clk_i2c_4 = '1' then
                    clk_i2c_4_old <= '1';
                    if state /= idle then -- toggle scl only as long as there is a transmission or the last cycle has not finished yet
                        if cnt_clk = "011" then
                            scl_int <= '0';
                        elsif cnt_clk = "111" then
                            scl_int <= '1';
                        end if;
                        cnt_clk <= cnt_clk + 1;
                    else
                        cnt_clk <= "000";
                        scl_int <= '1';
                    end if;
                    
                    case state is
                        when idle =>
                            if transmit = '1' then -- begin transmission
                                state <= gen_start;
                                adr_int <= adr;
                                rw_int <= rw;
                                data_in_int <= data_in;
                                cnt_byte <= "1001";
                                ready <= '0'; -- signalize the copy of registers for transmission
                            end if;
                        when gen_start =>
                            if cnt_clk = "001" then
                                sda_int <= '0';
                            elsif cnt_clk = "100" then
                                sda_int <= '1';
                                state <= transmit_adr;
                            end if;
                        when transmit_adr =>
                            if cnt_clk = "110" then
                                if cnt_byte = "0010" then
                                    sda_int <= rw_int; -- rw byte
                                    cnt_byte <= cnt_byte - 1;
                                elsif cnt_byte = "0001" then -- Ack?
                                    sda_int <= 'Z'; -- set state to open drain so that slave send ack
                                    cnt_byte <= cnt_byte - 1;
                                elsif cnt_byte = "0000" then
                                    if rw_int = '0' then -- write access: send data to slave
                                        cnt_byte <= "1000";
                                        state <= transmit_data;
                                        sda_int <= data_in_int(7); -- output first bit
                                    else
                                        cnt_byte <= "1001";
                                        sda_int <= 'Z';
                                        state <= receive_data; -- read access
                                    end if;
                                else
                                    sda_int <= adr_int(to_integer(cnt_byte) - 3);
                                    cnt_byte <= cnt_byte - 1;
                                end if;
                            end if;
                        when transmit_data =>
                            if cnt_clk = "110" then
                                if cnt_byte = "0001" then -- ack?
                                    sda_int <= 'Z';
                                    cnt_byte <= cnt_byte - 1;
                                    ready <= '0'; -- signalize transmission of byte
                                elsif cnt_byte = "0000" then
                                    if transmit = '1' then
                                        if rw_int = rw and rw = '0' then
                                            cnt_byte <= "1000";
                                            data_in_int <= data_in;
                                            sda_int <= data_in_int(7); -- already output first byte
                                        else -- repeated start
                                            rw_int <= rw;
                                            cnt_byte <= "1001";
                                            sda_int <= '1'; -- set state to 1 (important for start condition)
                                            state <= gen_start; -- in the meantime the mode was switched fromm write to read -> repeated start
                                        end if;
                                    else
                                        sda_int <= '0'; -- set state to 0 (important for stop condition)
                                        state <= gen_stop; -- don't transmit any more date, stop communication
                                    end if;
                                else
                                    sda_int <= data_in_int(to_integer(cnt_byte) - 2);
                                    cnt_byte <= cnt_byte - 1;
                                end if;
                            end if;
                        when receive_data =>
                            if cnt_byte = "0001" and cnt_clk = "110" then -- ack
                                sda_int <= '0'; -- setze state auf 0 (ack)
                                cnt_byte <= cnt_byte - 1;
                                ready <= '0'; -- signalize the receiving of data
                            elsif cnt_byte = "0000" and cnt_clk = "110" then
                                if transmit = '1' then
                                    if rw_int = rw and rw = '1' then -- get next byte
                                        sda_int <= 'Z'; -- tri state: slave sets data
                                        cnt_byte <= "1001";
                                    else -- repeated start not allowed here! Stop transmission!
                                        sda_int <= '0';
                                        state <= gen_stop; -- no more data to transmit (stop transmission)
                                    end if;
                                else
                                    sda_int <= '0';
                                    state <= gen_stop;
                                end if;
                            elsif cnt_byte > "0001" and cnt_clk = "001" then
                                data_out(to_integer(cnt_byte) - 2) <= sda; -- read bit
                                cnt_byte <= cnt_byte - 1;
                            end if;
                        when gen_stop =>
                            if cnt_clk = "001" then
                                sda_int <= '1';
                                state <= idle;
                            end if;
                        when others =>
                            state <= idle;
                    end case;
                else
                    clk_i2c_4_old <= '0';
                end if;
                
                if scl_int = '0' then
                    scl <= '0';
                else
                    scl <= 'Z'; -- Open Drain
                end if;
                
                if sda_int = '0' then
                    sda <= '0';
                else
                    sda <= 'Z'; -- Open Drain
                end if;
            end if;
        end if;
    end process;
end Behavioral;
