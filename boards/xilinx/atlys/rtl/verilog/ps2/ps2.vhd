-------------------------------------------------------------------------------
-- Title      : PS/2 interface
-- Project    :
-------------------------------------------------------------------------------
-- File       : ps2.vhd
-- Author     : Daniel Quintero <danielqg@infonegocio.com>
-- Company    : Itoo Software
-- Created    : 2003-04-14
-- Last update: 2003-10-30
-- Platform   : VHDL'87
-------------------------------------------------------------------------------
-- Description: PS/2 generic UART for mice/keyboard
-------------------------------------------------------------------------------
--  This code is distributed under the terms and conditions of the
--  GNU General Public License
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2003-04-14  1.0      daniel  Created
-------------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;
use ieee.std_logic_arith.all;

entity ps2 is
        port (
                clk_i : in std_logic;   -- Global clk
                rst_i : in std_logic;   -- GLobal Asinchronous reset

                data_o    : out std_logic_vector(7 downto 0);  -- Data in
                data_i    : in  std_logic_vector(7 downto 0);  -- Data out
                ibf_clr_i : in  std_logic;  -- Ifb flag clear input
                obf_set_i : in  std_logic;  -- Obf flag set input
                ibf_o     : out std_logic;  -- Received data available
                obf_o     : out std_logic;  -- Data ready to sent

                frame_err_o  : out std_logic;  -- Error receiving data
                parity_err_o : out std_logic;  -- Error in received data parity
                busy_o       : out std_logic;  -- uart busy
                err_clr_i : in std_logic;  -- Clear error flags

                wdt_o : out std_logic;  -- Watchdog timer out every 400uS

                ps2_clk_io  : inout std_logic;   -- PS2 Clock line
                ps2_data_io : inout std_logic);  -- PS2 Data line
end ps2;

architecture rtl of ps2 is

        type states is (idle, write_request, start, data, parity, stop);
        type debounce_states is (stable, rise, fall, wait_stable);

        --constant DEBOUNCE_TIMEOUT : integer := 200;  -- clks to debounce the ps2_clk signal
        constant DEBOUNCE_BITS    : integer := 8;
        --constant WATCHDOG_TIMEOUT : integer := 19200 / DEBOUNCE_TIMEOUT;  -- clks to wait 400uS
        constant WATCHDOG_BITS    : integer := 8;

        signal state             : states;
        signal debounce_state    : debounce_states;
        signal debounce_cnt      : std_logic_vector(DEBOUNCE_BITS-1 downto 0);
        signal debounce_cao      : std_logic;
        signal ps2_clk_syn       : std_logic;  -- PS2 clock input syncronized
        signal ps2_clk_clean     : std_logic;  -- PS2 clock debounced and clean
        signal ps2_clk_fall      : std_logic;  -- PS2 clock fall edge
        signal ps2_clk_rise      : std_logic;  -- PS2 clock rise edge
        signal ps2_data_syn      : std_logic;  -- PS2 data  input syncronized
        signal ps2_clk_out       : std_logic;  -- PS2 clock output
        signal ps2_data_out      : std_logic;  -- PS2 clock output
        signal writing           : std_logic;  -- read / write cycle flag
        signal shift_cnt         : std_logic_vector(2 downto 0);
        signal shift_cao         : std_logic;  -- Shift counter carry out
        signal shift_reg         : std_logic_vector(8 downto 0);
        signal shift_in_read     : std_logic;  -- Shift register to right
        signal shift_in_write    : std_logic;  -- Shift register to right
        signal shift_load        : std_logic;  -- Shift register parallel load
        signal shift_calc_parity : std_logic;  -- Shift register set parity
        signal wdt_cnt           : std_logic_vector(WATCHDOG_BITS-1 downto 0);
        signal wdt_rst           : std_logic;  -- watchdog reset
        signal wdt_cao           : std_logic;  -- watchdog carry out
        signal shift_parity      : std_logic;  -- Current parity of shift_reg
        signal ibf               : std_logic;  -- IBF, In Buffer Full
        signal obf               : std_logic;  -- OBF, Out Buffer Full
        signal parity_err        : std_logic;  -- Parity error
        signal frame_err         : std_logic;  -- Frame error
        signal data_i_reg        : std_logic_vector(7 downto 0);
        signal data_o_reg        : std_logic_vector(7 downto 0);
        signal obf_set           : std_logic;
        
begin  -- rtl

        -- Sincronize input signals
        syn_ps2 : process (clk_i, rst_i)
        begin
                if rst_i = '0' then     -- asynchronous reset (active low)
                        ps2_clk_syn  <= '0';
                        ps2_data_syn <= '0';
                elsif clk_i'event and clk_i = '1' then  -- rising clock edge
                        ps2_clk_syn  <= TO_X01(ps2_clk_io);
                        ps2_data_syn <= TO_X01(ps2_data_io);
                end if;
        end process syn_ps2;

        -- clk debounce timer
        debounce_count : process (clk_i, rst_i)
        begin
                if rst_i = '0' then     -- asynchronous reset (active low)
                        debounce_cnt <= (others => '0');
                elsif clk_i'event and clk_i = '1' then  -- rising clock edge
                        if ((debounce_state = fall) or (debounce_state = rise) or debounce_cao = '1') then
                                debounce_cnt <= (others => '0');
                        else
                                debounce_cnt <= debounce_cnt + 1;
                        end if;
                end if;
        end process;
        debounce_cao <= debounce_cnt(DEBOUNCE_BITS-1);
--        debounce_cao <= '1' when debounce_cnt =
--                        CONV_STD_LOGIC_VECTOR(DEBOUNCE_TIMEOUT-1, DEBOUNCE_BITS)
--                        else '0';

        -- PS2 clock debounce and edge detector
        debounce_stm : process (clk_i, rst_i)
        begin
                if rst_i = '0' then
                        debounce_state <= stable;
                        ps2_clk_clean  <= '0';
                elsif clk_i'event and clk_i = '1' then
                        case debounce_state is
                                when stable =>
                                        if ps2_clk_clean /= ps2_clk_syn then
                                                if ps2_clk_syn = '1' then
                                                        debounce_state <= rise;
                                                else
                                                        debounce_state <= fall;
                                                end if;
                                        end if;
                                when wait_stable =>
                                        if debounce_cao = '1' then
                                                debounce_state <= stable;
                                        end if;
                                when rise => debounce_state <= wait_stable;
                                             ps2_clk_clean <= '1';
                                when fall => debounce_state <= wait_stable;
                                             ps2_clk_clean <= '0';
                                when others => null;
                        end case;
                end if;
        end process;
        ps2_clk_fall <= '1' when debounce_state = fall else '0';
        ps2_clk_rise <= '1' when debounce_state = rise else '0';

        -- PS2 watchdog
        wdt_proc : process(clk_i, rst_i)
        begin
                if rst_i = '0' then     -- asynchronous reset (active low)
                        wdt_cnt <= (others => '0');
                elsif clk_i'event and clk_i = '1' then  -- rising clock edge
                        if (wdt_rst or wdt_cao) = '1' then
                                wdt_cnt <= (others => '0');
                        elsif debounce_cao = '1' then
                                wdt_cnt <= wdt_cnt + 1;
                        end if;
                end if;
        end process;
        wdt_cao <= wdt_cnt(WATCHDOG_BITS-1);
--        wdt_cao <= '1' when wdt_cnt =
--                   CONV_STD_LOGIC_VECTOR(WATCHDOG_TIMEOUT-1, WATCHDOG_BITS)
--                        else '0';
        wdt_rst <= ps2_clk_fall;


        -- Shift register
        shift : process (clk_i, rst_i)
        begin
                if rst_i = '0' then     -- asynchronous reset (active low)
                        shift_reg <= (others => '0');
                elsif clk_i'event and clk_i = '1' then  -- rising clock edge
                        if shift_load = '1' then
                                shift_reg(7 downto 0) <= data_i_reg;
                                shift_reg(8)          <= '0';
                        elsif shift_calc_parity = '1' then
                                shift_reg(8) <= not shift_parity;
                        elsif writing = '0' then
                                if shift_in_read = '1' then
                                        shift_reg(7 downto 0) <= shift_reg(8 downto 1);
                                        shift_reg(8)          <= ps2_data_syn;
                                end if;
                        elsif writing = '1' then
                                if shift_in_write = '1' then
                                        shift_reg(7 downto 0) <= shift_reg(8 downto 1);
                                        shift_reg(8)          <= '1';
                                end if;
                        end if;
                end if;
        end process;

        -- Shift counter
        sft_cnt : process(clk_i, rst_i)
        begin
                if rst_i = '0' then     -- asynchronous reset (active low)
                        shift_cnt <= (others => '0');
                elsif clk_i'event and clk_i = '1' then  -- rising clock edge
                        if state = start then
                                shift_cnt <= (others => '0');
                        elsif state = data and 
                            ((ps2_clk_fall = '1' and writing = '0') or
                             (ps2_clk_rise = '1' and writing = '1')) then
                                shift_cnt <= shift_cnt + 1;
                        end if;
                end if;
        end process;
        shift_cao <= '1' when shift_cnt = "111" else '0';

        -- Odd Parity generator
        shift_parity <= (shift_reg(0) xor
                   shift_reg(1) xor
                   shift_reg(2) xor
                   shift_reg(3) xor
                   shift_reg(4) xor
                   shift_reg(5) xor
                   shift_reg(6) xor
                   shift_reg(7));


        -- Main State Machine
        stm : process (clk_i, rst_i)
        begin
                if rst_i = '0' then     -- asynchronous reset (active low)
                        state   <= idle;
                        writing <= '0';
                elsif clk_i'event and clk_i = '1' then  -- rising clock edge
                        case state is

                                -- Waiting for clk
                                when idle => 
                                        if obf_set = '1' and writing = '0' then
                                                state <= write_request;
                                                writing <= '1';
                                        elsif ps2_clk_fall = '1' then
                                                state <= start;
                                        elsif wdt_cao = '1' and writing = '1' then
                                                writing <= '0';
                                        end if;

                                -- Write request, clk low
                                when write_request => 
                                        if wdt_cao = '1' then
                                                state <= idle;
                                        end if;

                                -- Clock 1, start bit
                                when start => 
                                        if wdt_cao = '1' then
                                                writing <= '0';
                                                state <= idle;
                                        elsif writing = '1' then
                                                if ps2_clk_rise = '1' then
                                                        state <= data;
                                                end if;
                                        elsif ps2_clk_fall = '1' then
                                                state <= data;
                                        end if;

                                -- Clocks 2-9, Data bits (LSB first)
                                when data => 
                                        if wdt_cao = '1' then
                                                writing <= '0';
                                                state <= idle;
                                        elsif writing = '1' then
                                                if ps2_clk_rise = '1' and
                                                   shift_cao    = '1' then
                                                        state <= parity;
                                                end if;
                                        elsif ps2_clk_fall = '1' and
                                              shift_cao    = '1' then
                                                state <= parity;
                                        end if;

                                -- Clock 10, Parity bit
                                when parity => 
                                        if wdt_cao = '1' then
                                                writing <= '0';
                                                state <= idle;
                                        elsif writing = '1' then
                                                if ps2_clk_rise = '1' then
                                                        state <= stop;
                                                end if;
                                        elsif ps2_clk_fall = '1' then
                                                state <= stop;
                                        end if;
                                -- Clock 11, Stop bit
                                when stop => 
                                        if writing = '1' then
                                                -- ack
                                                if (ps2_clk_fall = '1' and ps2_data_syn = '0') or
                                                   (wdt_cao = '1') then
                                                        state <= idle;
                                                        writing <= '0';
                                                end if;
                                        else
                                                data_o_reg <= shift_reg(7 downto 0);
                                                state <= idle;
                                        end if;
                                when others => null;
                        end case;
                end if;
        end process;

        -- State flags
        flags_proc : process (clk_i, rst_i, state, writing)
        begin  -- process stm_out
                 -- Input Buffer write flag
                if rst_i = '0' then     -- asynchronous reset (active low)
                        --obf <= '0';
                        ibf <= '0';
                        parity_err <= '0';
                        frame_err  <= '0';
                elsif clk_i'event and clk_i = '1' then  -- rising clock edge

                        -- Parity error flag
                        if err_clr_i = '1' then
                                parity_err <= '0';
                        elsif writing = '0' and state = stop then
                                if shift_reg(8) /= not shift_parity then
                                        parity_err <= '1';
                                end if;
                        end if;

                        -- Frame error flag
                        if err_clr_i = '1' then
                                frame_err <= '0';
                        elsif (state = start or
                               state = data or state = parity) and wdt_cao = '1' then
                                frame_err <= '1';
                        end if;

                        -- Input Buffer full flag
                        if ibf_clr_i = '1' then
                                ibf <= '0';
                        elsif writing = '0' and state = stop then
                                if shift_reg(8) = not shift_parity then
                                        ibf <= '1';
                                end if;
                        end if;

                        -- Output buffer full flag
                        --if state = stop and writing = '1' then
                        --        obf <= '0';
                        --elsif obf_set_i = '1' then
                        --        obf <= '1';
                        --end if;
                end if;
        end process;

        obf <= writing;

        -- Shift register control
        shift_load        <= '1' when obf_set = '1' and state = write_request else '0';
        shift_calc_parity <= '1' when state = idle and writing = '1' else '0';
        shift_in_read     <= ps2_clk_fall when (state = data or state = start)  else '0';
        shift_in_write    <= ps2_clk_rise when (state = data or state = parity) else '0';


        -- PS2 Registered outputs
        syn_ps2_out : process (clk_i, rst_i)
        begin
                if rst_i = '0' then     -- asynchronous reset (active low)
                        ps2_data_out <= '1';
                        ps2_clk_out  <= '1';
                elsif clk_i'event and clk_i = '1' then  -- rising clock edge

                        -- PS2 Data out
                        if writing = '1' then
                                if state = idle or state = start then
                                        ps2_data_out <= '0';
                                elsif state = data or state = parity then
                                        ps2_data_out <= shift_reg(0);
                                else
                                        ps2_data_out <= '1';
                                end if;
                        end if;

                        -- PS2 Clk out
                        if state = write_request then
                                ps2_clk_out <= '0';
                        else
                                ps2_clk_out <= '1';
                        end if;
                end if;
        end process;
        
        indata : process (clk_i, rst_i)
        begin
                if rst_i = '0' then
                        data_i_reg <= (others => '0');
                        obf_set    <= '0';
                elsif clk_i'event and clk_i = '1' then
                        if obf_set_i = '1' then
                                data_i_reg <= data_i;
                                obf_set    <= '1';
                        elsif state = write_request then
                                obf_set    <= '0';
                        end if;
                end if;
        end process;
        
        data_o       <= data_o_reg;
        ibf_o        <= ibf;
        obf_o        <= obf;
        busy_o       <= '0' when state = idle and writing = '0' else '1';
        parity_err_o <= parity_err;
        frame_err_o  <= frame_err;
        wdt_o        <= wdt_cao;

        ps2_clk_io  <= '0' when ps2_clk_out = '0'  else 'Z';
        ps2_data_io <= '0' when ps2_data_out = '0' else 'Z';

end rtl;

