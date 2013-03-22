
-- *****************************************************************************
-- Company: 
-- Engineer: Christopher James Huff
-- 
-- Create Date:    03/19/2013
-- Design Name: 
-- Module Name:    SED11x0_LCD - Behavioral 
-- Project Name: 
-- Target Devices: Epson EG2401 256x64 LCD display
-- Tool versions: 
-- Description: 
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
-- *****************************************************************************

-- Epson EG2401 pinout:
-- 1: Vdd
-- 2: Vss
-- 3: Vlcd
-- 4: LP Latch pulse signal input (1180 and 1190)
-- 5: FR Frame input (1180 and 1190)
-- 6: YDIS Display control (1190)
-- 7: YSCL Row scan shift clock input (1190)
-- 8: DIN Row scan data (1190)
-- 9: XSCL Display data shift clock input (1180)
-- 10: XECL Enable transition clock input (1180)
-- 11: D0 (all 1180)
-- 12: D1
-- 13: D2
-- 14: D3
-- 
-- SED1180 and SED1190 are essentially shift registers with LCD-drive outputs.
--  FR determines polarity of output
--
-- SED1190:
--  LCD LP -> 1190 YSCL (Yes, latch pulse is clock and clock is latch. Don't ask me why.)
--  LCD YSCL -> 1190 LAT
--  LCD YD/DIN -> 1190 DIN
--  LCD YDIS => _INH_
--  1 64-bit shift register drives rows
--  A 1 is latched into the 1190 and shifted along to each row in turn.
--  Data is shifted from latched DIN and along the shift register on the falling edge of LAT
--
-- SED1180:
--  4 parallel and interleaved shift registers drive 64 columns
--  4 bits at a time are shifted into a chain of 1180s and shifted along the columns
--  XSCL is shift clock, data is shifted on falling edge
--  ECL "Daisy chain enable clock: the daisy chain enable is propagated on the falling edge of this clock."
--      Enable input is connected to LP. A falling edge on ECL with LP high enables the first controller of
--      the chain. A falling edge on ECL with LP low disables it and enables the next, switching to the next
--      64x64 pixel block of the display.
--  LP is output latch. Display data is latched on falling edge
-- 
-- There are 4 SED1180 column drivers and one SED1190 row driver on the EG2401.
-- 

library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

library UNISIM;
    use UNISIM.VComponents.all;


entity SED11x0_LCD is
    port(
        FB_ADDR:  in std_logic_vector(13 downto 0);
        FB_DI:    in std_logic_vector(0 downto 0);
        FB_DO:    out std_logic_vector(0 downto 0);
        FB_EN:    in std_logic;
        FB_SSR:   in std_logic;
        FB_WE:    in std_logic;
        
        SYS_CLK:      in std_logic;
        DISP_CLK:     in std_logic;
        
        SED11x0_LP:   out std_logic := '0';-- pin 4
        SED11x0_FR:   out std_logic := '0';-- pin 5
        SED11x0_YDIS: out std_logic := '0';-- pin 6
        SED11x0_YSCL: out std_logic := '0';-- pin 7
        SED11x0_DIN:  out std_logic := '0';-- pin 8
        SED11x0_XSCL: out std_logic := '0';-- pin 9
        SED11x0_XECL: out std_logic := '0';-- pin 10
        SED11x0_DAT:  out std_logic_vector(3 downto 0) -- pins 11-14
    );
end SED11x0_LCD;

architecture Behavioral of SED11x0_LCD is
    type UPDATE_STATE is (
        ST_WRITE_DATA, ST_WRITE_DATA2,
        ST_NEXT_DRIVER,
        ST_NEXT_LINE, ST_NEXT_LINE2, ST_NEXT_LINE3,
        ST_INTER_LINE_DELAY);
    signal STATE: UPDATE_STATE := ST_WRITE_DATA;
    
    signal ODD_FRAME: std_logic := '0';
    signal COL4_ADDR: std_logic_vector(11 downto 0) := (others => '0');
    signal COL4_CTR: unsigned(11 downto 0) := (others => '0');
    signal INTERLINE_CTR: unsigned(31 downto 0) := (others => '0');
    
    signal COL4_DATA: std_logic_vector(3 downto 0) := (others => '0');
    
begin
    COL4_ADDR <= std_logic_vector(COL4_CTR);
    -- reverse order of column data
    SED11x0_DAT <= COL4_DATA(0) & COL4_DATA(1) & COL4_DATA(2) & COL4_DATA(3);
    SED11x0_FR <= ODD_FRAME;
    
    framebuffer: RAMB16_S1_S4
    generic map (
        INIT_A => "0",   --  Value of output RAM registers on Port A at startup
        INIT_B => X"0",  --  Value of output RAM registers on Port B at startup
        SRVAL_A => "0",  --  Port A output value upon SSR assertion
        SRVAL_B => X"0", --  Port B output value upon SSR assertion
        WRITE_MODE_A => "WRITE_FIRST", --  WRITE_FIRST, READ_FIRST or NO_CHANGE
        WRITE_MODE_B => "WRITE_FIRST", --  WRITE_FIRST, READ_FIRST or NO_CHANGE
        SIM_COLLISION_CHECK => "ALL", -- "NONE", "WARNING", "GENERATE_X_ONLY", "ALL" 
        -- Initial framebuffer contents are a simple test pattern:
        -- 8x8 checkers, vlines, hlines, 1x1 checkers
        INIT_00 => X"FF00FF00FF00FF008080808080808080FFFFFFFFFFFFFFFF5555555555555555",
        INIT_01 => X"FF00FF00FF00FF0080808080808080800000000000000000AAAAAAAAAAAAAAAA",
        INIT_02 => X"FF00FF00FF00FF00808080808080808000000000000000005555555555555555",
        INIT_03 => X"FF00FF00FF00FF0080808080808080800000000000000000AAAAAAAAAAAAAAAA",
        INIT_04 => X"FF00FF00FF00FF00808080808080808000000000000000005555555555555555",
        INIT_05 => X"FF00FF00FF00FF0080808080808080800000000000000000AAAAAAAAAAAAAAAA",
        INIT_06 => X"FF00FF00FF00FF00808080808080808000000000000000005555555555555555",
        INIT_07 => X"FF00FF00FF00FF0080808080808080800000000000000000AAAAAAAAAAAAAAAA",
        INIT_08 => X"00FF00FF00FF00FF8080808080808080FFFFFFFFFFFFFFFF5555555555555555",
        INIT_09 => X"00FF00FF00FF00FF80808080808080800000000000000000AAAAAAAAAAAAAAAA",
        INIT_0A => X"00FF00FF00FF00FF808080808080808000000000000000005555555555555555",
        INIT_0B => X"00FF00FF00FF00FF80808080808080800000000000000000AAAAAAAAAAAAAAAA",
        INIT_0C => X"00FF00FF00FF00FF808080808080808000000000000000005555555555555555",
        INIT_0D => X"00FF00FF00FF00FF80808080808080800000000000000000AAAAAAAAAAAAAAAA",
        INIT_0E => X"00FF00FF00FF00FF808080808080808000000000000000005555555555555555",
        INIT_0F => X"00FF00FF00FF00FF80808080808080800000000000000000AAAAAAAAAAAAAAAA",
        INIT_10 => X"FF00FF00FF00FF008080808080808080FFFFFFFFFFFFFFFF5555555555555555",
        INIT_11 => X"FF00FF00FF00FF0080808080808080800000000000000000AAAAAAAAAAAAAAAA",
        INIT_12 => X"FF00FF00FF00FF00808080808080808000000000000000005555555555555555",
        INIT_13 => X"FF00FF00FF00FF0080808080808080800000000000000000AAAAAAAAAAAAAAAA",
        INIT_14 => X"FF00FF00FF00FF00808080808080808000000000000000005555555555555555",
        INIT_15 => X"FF00FF00FF00FF0080808080808080800000000000000000AAAAAAAAAAAAAAAA",
        INIT_16 => X"FF00FF00FF00FF00808080808080808000000000000000005555555555555555",
        INIT_17 => X"FF00FF00FF00FF0080808080808080800000000000000000AAAAAAAAAAAAAAAA",
        INIT_18 => X"00FF00FF00FF00FF8080808080808080FFFFFFFFFFFFFFFF5555555555555555",
        INIT_19 => X"00FF00FF00FF00FF80808080808080800000000000000000AAAAAAAAAAAAAAAA",
        INIT_1A => X"00FF00FF00FF00FF808080808080808000000000000000005555555555555555",
        INIT_1B => X"00FF00FF00FF00FF80808080808080800000000000000000AAAAAAAAAAAAAAAA",
        INIT_1C => X"00FF00FF00FF00FF808080808080808000000000000000005555555555555555",
        INIT_1D => X"00FF00FF00FF00FF80808080808080800000000000000000AAAAAAAAAAAAAAAA",
        INIT_1E => X"00FF00FF00FF00FF808080808080808000000000000000005555555555555555",
        INIT_1F => X"00FF00FF00FF00FF80808080808080800000000000000000AAAAAAAAAAAAAAAA",
        INIT_20 => X"FF00FF00FF00FF008080808080808080FFFFFFFFFFFFFFFF5555555555555555",
        INIT_21 => X"FF00FF00FF00FF0080808080808080800000000000000000AAAAAAAAAAAAAAAA",
        INIT_22 => X"FF00FF00FF00FF00808080808080808000000000000000005555555555555555",
        INIT_23 => X"FF00FF00FF00FF0080808080808080800000000000000000AAAAAAAAAAAAAAAA",
        INIT_24 => X"FF00FF00FF00FF00808080808080808000000000000000005555555555555555",
        INIT_25 => X"FF00FF00FF00FF0080808080808080800000000000000000AAAAAAAAAAAAAAAA",
        INIT_26 => X"FF00FF00FF00FF00808080808080808000000000000000005555555555555555",
        INIT_27 => X"FF00FF00FF00FF0080808080808080800000000000000000AAAAAAAAAAAAAAAA",
        INIT_28 => X"00FF00FF00FF00FF8080808080808080FFFFFFFFFFFFFFFF5555555555555555",
        INIT_29 => X"00FF00FF00FF00FF80808080808080800000000000000000AAAAAAAAAAAAAAAA",
        INIT_2A => X"00FF00FF00FF00FF808080808080808000000000000000005555555555555555",
        INIT_2B => X"00FF00FF00FF00FF80808080808080800000000000000000AAAAAAAAAAAAAAAA",
        INIT_2C => X"00FF00FF00FF00FF808080808080808000000000000000005555555555555555",
        INIT_2D => X"00FF00FF00FF00FF80808080808080800000000000000000AAAAAAAAAAAAAAAA",
        INIT_2E => X"00FF00FF00FF00FF808080808080808000000000000000005555555555555555",
        INIT_2F => X"00FF00FF00FF00FF80808080808080800000000000000000AAAAAAAAAAAAAAAA",
        INIT_30 => X"FF00FF00FF00FF008080808080808080FFFFFFFFFFFFFFFF5555555555555555",
        INIT_31 => X"FF00FF00FF00FF0080808080808080800000000000000000AAAAAAAAAAAAAAAA",
        INIT_32 => X"FF00FF00FF00FF00808080808080808000000000000000005555555555555555",
        INIT_33 => X"FF00FF00FF00FF0080808080808080800000000000000000AAAAAAAAAAAAAAAA",
        INIT_34 => X"FF00FF00FF00FF00808080808080808000000000000000005555555555555555",
        INIT_35 => X"FF00FF00FF00FF0080808080808080800000000000000000AAAAAAAAAAAAAAAA",
        INIT_36 => X"FF00FF00FF00FF00808080808080808000000000000000005555555555555555",
        INIT_37 => X"FF00FF00FF00FF0080808080808080800000000000000000AAAAAAAAAAAAAAAA",
        INIT_38 => X"00FF00FF00FF00FF8080808080808080FFFFFFFFFFFFFFFF5555555555555555",
        INIT_39 => X"00FF00FF00FF00FF80808080808080800000000000000000AAAAAAAAAAAAAAAA",
        INIT_3A => X"00FF00FF00FF00FF808080808080808000000000000000005555555555555555",
        INIT_3B => X"00FF00FF00FF00FF80808080808080800000000000000000AAAAAAAAAAAAAAAA",
        INIT_3C => X"00FF00FF00FF00FF808080808080808000000000000000005555555555555555",
        INIT_3D => X"00FF00FF00FF00FF80808080808080800000000000000000AAAAAAAAAAAAAAAA",
        INIT_3E => X"00FF00FF00FF00FF808080808080808000000000000000005555555555555555",
        INIT_3F => X"00FF00FF00FF00FF80808080808080800000000000000000AAAAAAAAAAAAAAAA")
    port map (
        DOA => FB_DO,       -- Port A 1-bit Data Output
        DOB => COL4_DATA,   -- Port B 4-bit Data Output
        ADDRA => FB_ADDR,   -- Port A 14-bit Address Input
        ADDRB => COL4_ADDR, -- Port B 12-bit Address Input
        CLKA => SYS_CLK,    -- Port A Clock
        CLKB => DISP_CLK,   -- Port B Clock
        DIA  => FB_DI,      -- Port A 1-bit Data Input
        DIB  => "0000",     -- Port B 4-bit Data Input
        ENA  => FB_EN,    -- Port A RAM Enable Input
        ENB  => '1',      -- Port B RAM Enable Input
        SSRA => FB_SSR,   -- Port A Synchronous Set/Reset Input
        SSRB => '0',      -- Port B Synchronous Set/Reset Input
        WEA  => FB_WE,    -- Port A Write Enable Input
        WEB  => '0'       -- Port B Write Enable Input
    );
    
    process(DISP_CLK)
    begin
        if(rising_edge(DISP_CLK)) then
            SED11x0_YDIS <= '1';-- enable display once started
            case STATE is
                when ST_WRITE_DATA =>
                    SED11x0_XSCL <= '1';
                    STATE <= ST_WRITE_DATA2;
                -- end state ST_WRITE_DATA
                
                when ST_WRITE_DATA2 =>
                    SED11x0_XSCL <= '0';
                    COL4_CTR <= COL4_CTR + 1;
                    
                    if(COL4_CTR(5 downto 0) = 63) then
                        STATE <= ST_NEXT_LINE;
                    elsif(COL4_CTR(3 downto 0) = 15) then
                        SED11x0_XECL <= '1';
                        STATE <= ST_NEXT_DRIVER;
                    else
                        STATE <= ST_WRITE_DATA;
                    end if;
                -- end state ST_WRITE_DATA2
                
                
                when ST_NEXT_DRIVER =>
                    SED11x0_XECL <= '0';
                    STATE <= ST_WRITE_DATA;
                -- end state ST_NEXT_DRIVER
                
                
                when ST_NEXT_LINE =>
                    SED11x0_LP <= '1';
                    SED11x0_YSCL <= '1';
                    SED11x0_XECL <= '1';
                    if(COL4_CTR = 64) then
                        -- first line, need to restart row scanning shift register
                        SED11x0_DIN <= '1';
                        ODD_FRAME <= not ODD_FRAME;
                    else
                        SED11x0_DIN <= '0';
                    end if;
                    STATE <= ST_NEXT_LINE2;
                -- end state ST_NEXT_LINE
                
                when ST_NEXT_LINE2 =>
                    SED11x0_YSCL <= '0';
                    SED11x0_XECL <= '0';
                    SED11x0_DIN <= '0';
                    STATE <= ST_NEXT_LINE3;
                -- end state ST_NEXT_LINE2
                
                when ST_NEXT_LINE3 =>
                    SED11x0_LP <= '0';
                    INTERLINE_CTR <= to_unsigned(2000, 32);
                    STATE <= ST_INTER_LINE_DELAY;
                -- end state ST_NEXT_LINE3
                
                
                when ST_INTER_LINE_DELAY =>
                    INTERLINE_CTR <= INTERLINE_CTR - 1;
                    if(INTERLINE_CTR = 0) then
                        STATE <= ST_WRITE_DATA;
                    end if;
                -- end state ST_INTER_LINE_DELAY
            end case; -- STATE
        end if;
    end process;
end Behavioral;


