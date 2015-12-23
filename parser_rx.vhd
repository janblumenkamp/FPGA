----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    15:04:16 10/13/2015 
-- Design Name: 
-- Module Name:    parser_rx - Behavioral 
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

entity parser_rx is
    Port ( clk : in  STD_LOGIC;
           rst : in  STD_LOGIC;
           input_raw : in  STD_LOGIC_VECTOR (7 downto 0); -- fifo input
           re_raw : out  STD_LOGIC; -- read fifo
           no_newdata_raw : in  STD_LOGIC; -- fifo empty?
			  
           out_we : out  STD_LOGIC; -- one cycle high after a new package was parsed
			     out_rw : out STD_LOGIC; -- master wants ro read or write?
           out_adr : out  STD_LOGIC_VECTOR (6 downto 0); -- register
           out_data : out  STD_LOGIC_VECTOR (7 downto 0)); -- value/data of register
end parser_rx;

architecture Behavioral of parser_rx is
	type state_pars is (idle, get_reg_rw, get_data, get_chk); -- State machine
		signal current_state : state_pars := idle;
	signal re_raw_sig : std_logic := '0'; -- re of fifo
	
	signal chk_calc : unsigned(7 downto 0); -- checksum
	
begin
	PARSER: process (clk, rst)
	begin
		if clk'event and clk = '1' then
			if rst = '1' then
				current_state <= idle;
				re_raw_sig <= '0';
			else
				-- read FIFO
				out_we <= '0';
				
				if no_newdata_raw = '0' and re_raw_sig = '0' then -- FIFO has new data and the query bit is not yet set
					re_raw_sig <= '1';
					re_raw <= '1';
				elsif no_newdata_raw = '0' and re_raw_sig = '1' then -- FIFO has new data and we already set the query bit
					-- sm
					case current_state is 
						when idle =>
							if input_raw = "01010101" then -- start byte
								chk_calc <= unsigned(input_raw); -- reset checksum
								current_state <= get_reg_rw;
							end if;
						when get_reg_rw =>
							out_rw <= input_raw(7);
							out_adr <= input_raw(6 downto 0);
							chk_calc <= chk_calc + unsigned(input_raw);
							current_state <= get_data;
						when get_data =>
							out_data <= input_raw;
							chk_calc <= chk_calc + unsigned(input_raw);
							current_state <= get_chk;
						when get_chk =>
							if chk_calc = unsigned(input_raw) then -- checksum matches: set enable flag to process result
								out_we <= '1';
							end if;
							current_state <= idle;
						when others =>
							current_state <= idle;
					end case;
					
					re_raw_sig <= '0';
					re_raw <= '0';
				end if;
			end if;
		end if;
	end process;
end Behavioral;

