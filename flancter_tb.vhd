
library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;
    use ieee.math_real.all;

entity Flancter_TB is
end Flancter_TB;

architecture Behavioral of Flancter_TB is
    component Flancter
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
    end component;
    
    signal RESET : std_logic := '0';
    signal SRC_CLK: std_logic := '1';
    signal SET: std_logic := '0';
    signal DST_CLK: std_logic := '1';
    signal CLR: std_logic := '0';
    signal RAW_VALUE: std_logic := '0';
    signal SRC_SYNC_VALUE: std_logic := '0';
    signal DST_SYNC_VALUE: std_logic := '0';
    
    signal RUN: std_logic := '1';
    
    signal SRC_CLK_CNT: unsigned(31 downto 0) := (others => '0');
    signal DST_CLK_CNT: unsigned(31 downto 0) := (others => '0');
    
    
    type DST_STATE_TYPE is (DST_WAITING, DST_TRIGGERED);
    signal DST_STATE : DST_STATE_TYPE := DST_WAITING;
    
begin
    Flancter_0: Flancter port map(
        RESET => RESET,
        SET => SET,
        SRC_CLK => SRC_CLK,
        DST_CLK => DST_CLK,
        CLR => CLR,
        RAW_VALUE => RAW_VALUE,
        SRC_SYNC_VALUE => SRC_SYNC_VALUE,
        DST_SYNC_VALUE => DST_SYNC_VALUE
    );
    
    process
    begin
        for i in 0 to 10240 loop
            SRC_CLK <= '1';
            wait for 1 ns;
            SRC_CLK <= '0';
            wait for 1 ns;
        end loop;
        RUN <= '0';
        wait;
        assert false report "end of test" severity note;
        wait; -- Wait forever; this will finish the simulation.
    end process;
    
    process
    begin
        while (RUN = '1') loop
            DST_CLK <= '1';
            wait for 3.14159 ns;
            DST_CLK <= '0';
            wait for 3.14159 ns;
            DST_CLK_CNT <= DST_CLK_CNT + 1;
        end loop;
        wait;
    end process;
    
    process(SRC_CLK)
    begin
        if(rising_edge(SRC_CLK)) then
            SRC_CLK_CNT <= SRC_CLK_CNT + 1;
            if(SRC_CLK_CNT = 32) then
                SET <= '1';
            elsif(SRC_CLK_CNT = 33) then
                SET <= '0';
                SRC_CLK_CNT <= (others => '0');
            end if;
        end if; -- rising_edge(SRC_CLK)
    end process;
    
    process(DST_CLK)
    begin
        if(rising_edge(DST_CLK)) then
            case DST_STATE is
                when DST_WAITING =>
                    if(DST_SYNC_VALUE = '1') then
                        CLR <= '1';
                        DST_STATE <= DST_TRIGGERED;
                    end if;
                -- end state DST_WAITING
                
                when DST_TRIGGERED =>
                    CLR <= '0';
                    if(DST_SYNC_VALUE = '0') then
                        DST_STATE <= DST_WAITING;
                    end if;
                -- end state ST_START_WRITE
            end case; -- DST_TRIGGERED
        end if; -- rising_edge(DST_CLK)
    end process;
end Behavioral;
