
library ieee;
    use ieee.std_logic_1164.all;
--    use ieee.numeric_bit.all;
    use ieee.numeric_std.all;

entity SLx2016_TB is
end SLx2016_TB;

architecture Behavioral of SLx2016_TB is
    component SLx2016
        port (
            SYSCLK : in std_logic;
            DISPCLK : in std_logic;
            RESET : in std_logic;
            WRITE : in std_logic;
            WRITE_VALUE : in std_logic_vector(31 downto 0);
            LED_DAT : out std_logic_vector(6 downto 0);
            LED_ADDR : out std_logic_vector(1 downto 0);
            LED_WR : out std_logic
        );
    end component;
    for SLx2016_0: SLx2016 use entity work.SLx2016;
    
    signal SYSCLK: std_logic := '1';
    signal DISPCLK: std_logic := '1';
    signal RESET : std_logic := '1';
    signal START_WRITE : std_logic;
    signal LED_IN_VALUE : std_logic_vector(31 downto 0);
    signal LED_DAT : std_logic_vector(6 downto 0);
    signal LED_ADDR : std_logic_vector(1 downto 0);
    signal LED_WR : std_logic;
    
begin
    SLx2016_0: SLx2016 port map(
        SYSCLK => SYSCLK,
        DISPCLK => DISPCLK,
        RESET => RESET,
        WRITE => START_WRITE,
        WRITE_VALUE => LED_IN_VALUE,
        LED_DAT => LED_DAT,
        LED_ADDR => LED_ADDR,
        LED_WR => LED_WR
    );
    
    process
    begin
        RESET <= '0';
        for i in 0 to 500000000 loop
            SYSCLK <= '1';
            wait for 1 ns;
            SYSCLK <= '0';
            wait for 1 ns;
        end loop;
        wait; -- Wait forever; this will finish the simulation.
    end process;
    
--    DISPCLK <= SYSCLK;
    process(SYSCLK)
        variable CNT : integer := 0;
    begin
        if(rising_edge(SYSCLK)) then
            CNT := CNT + 1;
            if(CNT = 12) then
                CNT := 0;
                DISPCLK <= not DISPCLK;
            end if;
        end if;
    end process;
    
    process
        type pattern_type is record
            START_WRITE : std_logic;
            LED_IN_VALUE : std_logic_vector(31 downto 0);
            
--            LED_DAT : std_logic_vector(6 downto 0);
--            LED_ADDR : std_logic_vector(1 downto 0);
--            LED_WR : std_logic
        end record;
        
        type pattern_array is array (natural range <>) of pattern_type;
        constant test_patterns : pattern_array := (
            ('0', x"11223344"),
            ('0', x"00000000"),
            ('0', x"AABBCCDD"),
            ('0', x"FFFFFFFF"),
            ('1', x"55555555"),
            ('1', x"AAAAAAAA")
        ); -- test_patterns
        
    begin
        START_WRITE <= '0';
        LED_IN_VALUE <= test_patterns(0).LED_IN_VALUE;
        wait for 1 ns;
        START_WRITE <= '1';
        wait for 2 ns;
        START_WRITE <= '0';
        wait for 100 ms;
--         for i in test_patterns'range loop
--             LED_IN_VALUE <= test_patterns(i).LED_IN_VALUE;
--             wait for 1 ns;
--             START_WRITE <= '1';
--             wait for 2 ns;
--             START_WRITE <= '0';
--             wait for 768 ns;
--         end loop;
        
        assert false report "end of test" severity note;
        wait; -- Wait forever; this will finish the simulation.
    end process;
end Behavioral;
