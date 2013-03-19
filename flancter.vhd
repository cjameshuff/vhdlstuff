
-- *****************************************************************************
-- The flancter is a device for reliably getting a bit flag from a fast clock
-- domain into a slow one. It can also be used for detecting short pulses,
-- provided they do not repeat too quickly.
-- Simple two-stage synchronizers are used to provide outputs synchronized to
-- each clock domain, as well as the non-synchronized output.
--
-- The raw output changes synchronously with the source domain on set and with
-- the destination domain on clear. It can be used to guard against repeated
-- attempts to set or clear the flancter, bypassing the delay due to the
-- synchronizer flip-flops.
--
-- The source domain can set the flancter, the destination domain can clear it.
-- http://www.floobydust.com/flancter/Flancter_App_Note.pdf
-- *****************************************************************************


library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

entity Flancter is
    port (
        RESET:   in std_logic;-- asynchronous reset
        
        SET:     in std_logic;
        SRC_CLK: in std_logic;
        
        CLR:     in std_logic;
        DST_CLK: in std_logic;
        
        RAW_VALUE:       out std_logic; -- raw output
        SRC_SYNC_VALUE:  out std_logic; -- output synchronized to SRC_CLK
        DST_SYNC_VALUE:  out std_logic  -- output synchronized to DST_CLK
    );
end Flancter;

architecture Behavioral of Flancter is
    signal SET_FF: std_logic := '0';
    signal CLR_FF: std_logic := '0';
    signal SRC_SYNC0: std_logic := '0';
    signal SRC_SYNC1: std_logic := '0';
    signal DST_SYNC0: std_logic := '0';
    signal DST_SYNC1: std_logic := '0';
    
    signal VALUE: std_logic;
    
begin
    VALUE <= SET_FF xor CLR_FF;
    RAW_VALUE <= VALUE;
    SRC_SYNC_VALUE <= SRC_SYNC0;
    DST_SYNC_VALUE <= DST_SYNC0;
    
    SrcProc: process(SRC_CLK) is
    begin
        if(RESET = '1') then
            SET_FF <= '0';
        elsif(rising_edge(SRC_CLK)) then
            if(SET = '1') then
                SET_FF <= not CLR_FF;
            end if;
            SRC_SYNC0 <= SRC_SYNC1;
            SRC_SYNC1 <= VALUE;
        end if;
    end process;
    
    DstProc : process(DST_CLK) is
    begin
        if(RESET = '1') then
            CLR_FF <= '0';
        elsif(rising_edge(DST_CLK)) then
            if(CLR = '1') then
                CLR_FF <= SET_FF;
            end if;
            DST_SYNC0 <= DST_SYNC1;
            DST_SYNC1 <= VALUE;
        end if;
    end process;
end Behavioral;

