----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    14:16:24 10/02/2015 
-- Design Name: 
-- Module Name:    blink - Behavioral 
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
------------------------- Main/LEDs ----------------------------------------------------

entity main is
    Port ( clk : in  STD_LOGIC;
              rst : in STD_LOGIC;
              rx : in STD_LOGIC;
           tx : out STD_LOGIC;
           led : out  STD_LOGIC_VECTOR (3 downto 0); -- 4 LEDs
              btn : in STD_LOGIC_VECTOR (2 downto 0); -- 3 Push buttons
              scl : out STD_LOGIC;
              sda : inout STD_LOGIC;
              ws2812 : out STD_LOGIC
             );
end main;

architecture Behavioral of main is
    type comm_arr_t is array(9 downto 0) of std_logic_vector(7 downto 0); -- 4 LED, 1 btn (4 bit), 2 temperatur, 3 led rgb
        signal comm_reg: comm_arr_t  := (others=>(others=>'0')); -- Buffer/Register for serial communication
    
    -- serial rx
    signal serial_rx_clk: std_logic := '0'; -- clock rate of serial interface (16 x baud rate)
    signal serial_rx_clear: std_logic := '0'; -- delete new data flag
    signal serial_rx_data: std_logic_vector(7 downto 0) := (others=>'0'); -- Byte of serial input
    --signal serial_rx_error: std_logic := '0'; -- Flag: rx error?
    signal serial_rx_data_new: std_logic := '0'; -- Flag: new data
    --FIFO receive
    signal fifo_rx_data: std_logic_vector(7 downto 0) := (others=>'0'); -- Output of Fifo! The serial interface inputs data directly!
    signal fifo_rx_we: std_logic := '0'; -- write enable
    signal fifo_rx_re: std_logic := '0'; -- read enable
    signal fifo_rx_empty: std_logic;
    signal fifo_rx_full: std_logic;
    --FIFO transmit
    signal fifo_tx_data: std_logic_vector(7 downto 0) := (others=>'0'); -- Input of Fifo! The output is directly connected to serial interface!
    signal fifo_tx_we: std_logic := '0'; -- write enable
    signal fifo_tx_re: std_logic := '0'; -- read enable
    signal fifo_tx_empty: std_logic;
    signal fifo_tx_full: std_logic;
    
    -- serielles tx
    signal serial_tx_clk: std_logic := '0';
    signal serial_tx_send: std_logic := '0';
    signal serial_tx_ready: std_logic := '0';
    signal serial_tx_data: std_logic_vector(7 downto 0) := (others=>'0'); 
    
    -- parser
    signal parser_rx_we : std_logic; -- parser received new package
    signal parser_rx_reg : std_logic_vector(6 downto 0); -- register of package
    signal parser_rx_rw : std_logic; -- master wants to read or write?
    signal parser_rx_out : std_logic_vector(7 downto 0); -- value of registers
    -- sendpackage
    signal sendpackage_tx_reg : std_logic_vector(6 downto 0) := (others=>'0');
    signal sendpackage_tx_rw : std_logic := '0';
    signal sendpackage_tx_data : std_logic_vector(7 downto 0) := (others=>'0');
    signal sendpackage_tx_send : std_logic := '0';
    signal sendpackage_tx_ready : std_logic;
    
    -- i2c master
    signal i2c_master_clockx4 : std_logic;
    signal i2c_master_slave_adr : std_logic_vector(6 downto 0) := (others=>'0'); -- Slave Address
    signal i2c_master_rw : std_logic; -- Read or write access
    signal i2c_master_transmit : std_logic; -- start transmission
    signal i2c_master_ready : std_logic; -- Module finished current transmission
    signal i2c_master_data_in : std_logic_vector(7 downto 0) := (others=>'0'); -- Data Master -> Slave
    signal i2c_master_data_out : std_logic_vector(7 downto 0) := (others=>'0'); -- Data Slave -> Master
    -- tmp100 temperature sensor
    signal i2c_master_delay : unsigned(19 downto 0) := (others => '0'); -- Delay between the query of two values from temperature sensor (also important during initialization)
    type i2c_read_state_t is (idle, transmit_reg, read_msb, read_lsb); -- State machine for read transaction to temperature sensor
        signal tmp_100_read_state : i2c_read_state_t := idle;
    signal tmp100_data : std_logic_vector(15 downto 0) := (others=>'0'); -- raw data of temperature sensor for transmission into data package
    type i2c_write_state_t is (idle, transmit_reg, transmit_dat); -- State machine for a write transaction to Temperature sensor (1 byte)
        signal tmp_100_write_state : i2c_write_state_t := idle;
    signal tmp100_initialized : std_logic := '0'; -- Initilization done?
    
    -- WS2812
    signal ws2812_transmit : std_logic := '0';
begin
    -- PWM modules:
    PWM_1 : entity work.pwm port map(
        clk            =>  clk,
        rst            =>  rst,
        output         => led(0),
        pwmval         => comm_reg(0)
    ); -- PWM module 1
    PWM_2 : entity work.pwm port map(
        clk            => clk,
        rst            => rst,
        output         => led(1),
        pwmval         => comm_reg(1)
    ); -- PWM modul 2
    PWM_3 : entity work.pwm port map(
        clk            => clk,
        rst            => rst,
        output         => led(2),
        pwmval         => comm_reg(2)
    ); -- PWM modul 3
    PWM_4 : entity work.pwm port map(
        clk            => clk,
        rst            => rst,
        output         => led(3),
        pwmval         => comm_reg(3)
    ); -- PWM modul 4
                                                
    -- Frequency divider of serial interface
    FREQ_SERIAL_RX : entity work.freqdiv port map(
        clkin          => clk,
        rst            => rst,
        clkout         => serial_rx_clk,
        fac            => "0000000000110011"
    ); -- Frequency divider of UART Clock (16000000/(00110011 + 1) ~ 19200Baud*16)
    FREQ_SERIAL_TX : entity work.freqdiv port map(
        clkin          => clk,
        rst            => rst,
        clkout         => serial_tx_clk,
        fac            => "0000001100111111"
    ); -- Frequency divider of UART Clock (16000000/(1100111111 + 1) ~ 19200Baud)
    FREQ_I2C_4 : entity work.freqdiv port map(
        clkin          => clk,
        rst            => rst,
        clkout         => i2c_master_clockx4,
        fac            => "0000000000100111"
    ); -- Frequency divider of I2C Clock (400 kHz -> 50kHz I2C Clock)
    
    -- serial modules
    SERIAL_RX : entity work.serial8n1_rx port map(
        clk_baudx16    => serial_rx_clk,
        rst            => rst,
        rx             => rx,
        clr            => serial_rx_clear,
        data           => serial_rx_data,
        newdata        => serial_rx_data_new
    );
    SERIAL_TX : entity work.serial8n1_tx port map(
        clk_baud       => serial_tx_clk,
        rst            => rst,
        tx             => tx,
        send           => serial_tx_send,
        ready          => serial_tx_ready,
        data           => serial_tx_data
    );
    
    -- FIFO for data receive
    FIFO_RX : entity work.fifo port map(
        clk            => clk,
        rst            => rst,
        input          => serial_rx_data,
        we             => fifo_rx_we,
        output         => fifo_rx_data,
        re             => fifo_rx_re,
        empty          => fifo_rx_empty,
        full           => fifo_rx_full
    );
    -- FIFO for data transmit
    FIFO_TX : entity work.fifo port map(
        clk            => clk,
        rst            => rst,
        input          => fifo_tx_data,
        we             => fifo_tx_we,
        output         => serial_tx_data,
        re             => fifo_tx_re,
        empty          => fifo_tx_empty,
        full           => fifo_tx_full
    );
        
    -- Parser for uart protocol
    PARSER_RX : entity work.parser_rx port map(
        clk            => clk,
        rst            => rst,
        input_raw      => fifo_rx_data, -- connect input to FIFO
        re_raw         => fifo_rx_re, -- fifo re
        no_newdata_raw =>  fifo_rx_empty, -- fifo_rx_empty is 1, if it is empty and not fifo_rx_empty is 1, if there are data in the fifo
        
        out_we         => parser_rx_we, -- parser received new package
        out_rw         => parser_rx_rw, -- master wants ro write? if 0 master wants to read
        out_adr        => parser_rx_reg, -- register
        out_data       => parser_rx_out
    );
    SENDPACKAGE_TX: entity work.sendpackage_tx port map(
        clk            => clk,
        rst            => rst,
        fifo_data      => fifo_tx_data, -- connection to fifo input
        fifo_full      => fifo_tx_full, -- fifo full?
        fifo_we        => fifo_tx_we, -- write data to fifo
        reg            => sendpackage_tx_reg, -- register to access
        rw             => sendpackage_tx_rw, -- write?
        data           => sendpackage_tx_data, -- Data (if write access)
        send           => sendpackage_tx_send, -- start trasmission
        ready          => sendpackage_tx_ready -- transmission done
    );
    
    -- i2c master Modul
    I2C_MASTER: entity work.i2c_master PORT MAP (
        clk            => clk,
        rst            => rst,
        clk_i2c_4      => i2c_master_clockx4,
        adr            => i2c_master_slave_adr,
        rw             => i2c_master_rw,
        transmit       => i2c_master_transmit,
        ready          => i2c_master_ready,
        data_in        => i2c_master_data_in,
        data_out       => i2c_master_data_out,
        scl            => scl,
        sda            => sda
    );
    
    -- WS2812 RGB LED
    RGB_LED: entity work.ws2812 PORT MAP (
        led_r          => comm_reg(7),
        led_g          => comm_reg(8),
        led_b          => comm_reg(9),
        transmit       => ws2812_transmit,
        rst            => rst,
        clk_16MHz      => clk,
        sig            => ws2812
    );
    -- process for taking data from serial interface and putting it into the fifo
    PROC_RX: process (clk, rst)
    begin
        if clk'event and clk = '1' then
            if rst = '1' then -- Reset
                fifo_rx_we <= '0';
            else
                fifo_rx_we <= '0';
                if serial_rx_clear = '1' and serial_rx_data_new = '0' then -- if the reset of the serial interface was executed in th last cylce clear the reset so that we can receive new data
                    serial_rx_clear <= '0';
                elsif serial_rx_clear = '0' and serial_rx_data_new = '1' then -- new data available, serial interface is connected directly to the fifo, so we don't have to copy any data or register
                    if fifo_rx_full = '0' then -- if fifo is not full
                        fifo_rx_we <= '1';
                    end if;
                    serial_rx_clear <= '1'; -- Data of serial interface are now definitely at the input of the fifo, now we simply have switch the we of the fifo and clear the receive interface
                end if;
            end if;
        end if;
    end process;
    
    -- process for the transmission of the serial data (read from fifo and send via serial interface)
    PROC_TX: process (clk, rst)
    begin
        if clk'event and clk = '1' then
            if rst = '1' then
                serial_tx_send <= '0';
            else
                fifo_tx_re <= '0';
                if serial_tx_ready = '0' and serial_tx_send = '1' then -- serial interface is sending right nw, the send flag has to be cleared now
                    serial_tx_send <= '0'; -- delete sending flag so that the byte will not be sent again
                    fifo_tx_re <= '1'; -- prepare next byte and incrementation of address
                elsif serial_tx_ready = '1' and serial_tx_send = '0' then
                    if fifo_tx_empty = '0' then -- still data in the fifo
                        -- the output is directly connected to the serialinterface
                        serial_tx_send <= '1';
                    end if;
                end if;
            end if;
        end if;
    end process;
    
    -- process to query and configure the i2c temperature sensor
    PROC_TEMP: process (clk, rst)
    begin
        if clk'event and clk = '1' then
            if rst = '1' then -- Reset
                tmp_100_read_state <= idle;
                i2c_master_transmit <= '0';
                tmp100_initialized <= '0';
            else
                if tmp100_initialized = '1' then
                    case tmp_100_read_state is
                        when idle =>
                            if i2c_master_delay = 0 then -- Timer ran out, new transaction
                                i2c_master_slave_adr <= "1001000"; -- adress of temperature sensor
                                i2c_master_rw <= '0'; -- write access: write the register we want to read
                                i2c_master_data_in <= "00000000"; -- temperature register
                                i2c_master_transmit <= '1'; -- start transaction
                                if i2c_master_ready = '0' then -- module started transaction, switch state
                                    i2c_master_delay <= "11111111111111111111"; --  restart timer
                                    tmp_100_read_state <= transmit_reg;
                                end if;
                            else
                                i2c_master_delay <= i2c_master_delay - 1;
                            end if;
                        when transmit_reg =>
                            if i2c_master_ready = '0' then -- Transmission finished
                                i2c_master_rw <= '1'; -- switch to read access
                                tmp_100_read_state <= read_msb;
                            end if;
                        when read_msb =>
                            if i2c_master_ready = '0' then -- read byte
                                tmp100_data(7 downto 0) <= i2c_master_data_out;
                                tmp_100_read_state <= read_lsb;
                            end if;
                        when read_lsb =>
                            if i2c_master_ready = '0' then
                                tmp100_data(15 downto 8) <= i2c_master_data_out;
                                i2c_master_transmit <= '0'; -- Transmission done - stop
                                tmp_100_read_state <= idle;
                            end if;
                        when others =>
                            tmp_100_read_state <= idle;
                    end case;
                else -- Initialisieren
                    case tmp_100_write_state is
                        when idle =>
                            if i2c_master_delay = 0 then
                                i2c_master_slave_adr <= "1001000";
                                i2c_master_rw <= '0';
                                i2c_master_data_in <= "00000001"; -- Configuration register
                                i2c_master_transmit <= '1';
                                if i2c_master_ready = '0' then 
                                    i2c_master_delay <= "00001111111111111111";
                                    tmp_100_write_state <= transmit_reg;
                                end if;
                            else
                                i2c_master_delay <= i2c_master_delay - 1;
                            end if;
                        when transmit_reg =>
                            if i2c_master_ready = '0' then
                                i2c_master_data_in <= "01100000"; -- set resolution to 12 bit
                                tmp_100_write_state <= transmit_dat;
                            end if;
                        when transmit_dat =>
                            if i2c_master_ready = '0' then
                                i2c_master_transmit <= '0';
                                tmp_100_write_state <= idle;
                                tmp100_initialized <= '1';
                            end if;
                        when others =>
                            tmp_100_write_state <= idle;
                    end case;
                end if;
            end if;
        end if;
    end process;
    
    -- Most important process, manages all the fifo and the parser
    PROC_REG: process (clk, rst)
    begin
        if clk'event and clk = '1' then
            if rst = '1' then -- Reset
                comm_reg <= (others=>(others=>'0'));
            else
                ws2812_transmit <= '0';
                sendpackage_tx_send <= '0';
                if parser_rx_we = '1' then -- package received
                    if parser_rx_rw = '1' then -- master wants to write
                        comm_reg(to_integer(unsigned(parser_rx_reg(3 downto 0)))) <= parser_rx_out;
                        if parser_rx_reg = "0000111" or -- LED RGB register changed: Re-transfer ws2812 data
                            parser_rx_reg = "0001000" or
                            parser_rx_reg = "0001001" then
                            
                            ws2812_transmit <= '1';
                        end if;
                    else -- master wants to read data. Actually, we should check the ready flag...
                        sendpackage_tx_reg <= parser_rx_reg;
                        sendpackage_tx_rw <= '1';
                        sendpackage_tx_data <= comm_reg(to_integer(unsigned(parser_rx_reg(2 downto 0))));
                        sendpackage_tx_send <= '1';
                    end if;
                else -- here we can manage spontanious send requests (so that querys don't get lost)
                    if btn /= comm_reg(4)(2 downto 0) and sendpackage_tx_ready = '1' then -- Changes in the state
                        comm_reg(4)(2 downto 0) <= btn; -- Store register and send to maser
                        sendpackage_tx_reg <= "0000100";
                        sendpackage_tx_rw <= '1'; -- write
                        sendpackage_tx_data <= "00000" & btn;
                        sendpackage_tx_send <= '1';
                    elsif tmp100_data(7 downto 0) /= comm_reg(5) and sendpackage_tx_ready = '1' then -- Low Byte of temperature sensor
                        comm_reg(5) <= tmp100_data(7 downto 0);
                        sendpackage_tx_reg <= "0000101";
                        sendpackage_tx_rw <= '1'; -- write
                        sendpackage_tx_data <= tmp100_data(7 downto 0);
                        sendpackage_tx_send <= '1';
                    elsif tmp100_data(15 downto 8) /= comm_reg(6) and sendpackage_tx_ready = '1' then -- High Byte of temperature sensor
                        comm_reg(6) <= tmp100_data(15 downto 8);
                        sendpackage_tx_reg <= "0000110";
                        sendpackage_tx_rw <= '1'; -- write
                        sendpackage_tx_data <= tmp100_data(15 downto 8);
                        sendpackage_tx_send <= '1';    
                    end if;
                end if;
            end if;
        end if;
    end process;
end Behavioral;
