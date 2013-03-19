
-- *****************************************************************************
-- Driver for a SL*2016 4-character dot matrix LED display.
-- Displays a 4 7-bit character string encoded as 4 octets in a 32 bit vector.
-- 
-- The display is simply updated at regular intervals. With an 8 MHz clock, the
-- refresh rate is approximately 122 Hz. No attempt is made to avoid glitches
-- from clock domain differences, any resulting display artifacts will only be
-- displayed briefly before the next update corrects them. The goal is a simple,
-- bulletproof debug display.
-- 
-- Timing and clocking:
-- Frequency of DISPCLK should not exceed 11 MHz.
--
-- The setup period, write pulse, and hold period each take a full DISPCLK period. Worst
-- case write time for the LED display module at 5V and 85 C is 90 ns, limiting the
-- maximum display clock to 11 MHz. The data and address setup and hold times are well
-- within the worst case timings if this frequency isn't exceeded.


library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

entity SLx2016 is
    port (
        SYSCLK : in std_logic;
        DISPCLK : in std_logic;
        RESET : in std_logic;
        WRITE : in std_logic;
        WRITE_VALUE : in std_logic_vector(31 downto 0);
        LED_DAT : out std_logic_vector(6 downto 0) := (others => '0');
        LED_ADDR : out std_logic_vector(1 downto 0) := (others => '0');
        LED_WR : out std_logic := '1'
    );
end SLx2016;

architecture Behavioral of SLx2016 is
    type UPDATE_STATE is (ST_WAITING, ST_SETUP, ST_START_WRITE, ST_END_WRITE);
    signal STATE : UPDATE_STATE := ST_WAITING;
    signal DIGIT : unsigned(1 downto 0);
    signal UPDATE_CTR : unsigned(16 downto 0) := (others => '0');
    
    signal VALUE : std_logic_vector(27 downto 0) := (others => '0');
    
begin
    ControlProc: process(RESET, SYSCLK) is
    begin
        if(RESET = '1') then
            VALUE <= (others => '0');
        elsif(rising_edge(SYSCLK) and WRITE = '1') then
            VALUE <= WRITE_VALUE(30 downto 24) & WRITE_VALUE(22 downto 16) & WRITE_VALUE(14 downto 8) & WRITE_VALUE(6 downto 0);
        end if; -- rising_edge(SYSCLK)
    end process;
    
    DisplayProc : process(RESET, DISPCLK) is
    begin
        if(RESET = '1') then
            STATE <= ST_WAITING;
        elsif(rising_edge(DISPCLK)) then
            case STATE is
                when ST_WAITING =>
                    LED_WR <= '1';
                    UPDATE_CTR <= UPDATE_CTR + 1;
                    if(UPDATE_CTR = 0) then
                        DIGIT <= "00";
                        STATE <= ST_SETUP;
                    end if;
                -- end state ST_WAITING
                
                when ST_SETUP =>
                    -- setup digit address and character data lines
                    LED_ADDR <= std_logic_vector(DIGIT);
                    case to_integer(DIGIT) is
                        when 0 => LED_DAT <= VALUE(27 downto 21);
                        when 1 => LED_DAT <= VALUE(20 downto 14);
                        when 2 => LED_DAT <= VALUE(13 downto 7);
                        when 3 => LED_DAT <= VALUE(6 downto 0);
                        when others => LED_DAT <= "0100011";
                    end case;
                    STATE <= ST_START_WRITE;
                -- end state ST_SETUP
                
                when ST_START_WRITE =>
                    -- start LED_WR strobe
                    LED_WR <= '0';
                    STATE <= ST_END_WRITE;
                -- end state ST_START_WRITE
                
                when ST_END_WRITE =>
                    -- end LED_WR strobe, and either move on to next digit or go back to ST_WAITING state.
                    LED_WR <= '1';
                    if(DIGIT = 3) then
                        STATE <= ST_WAITING;
                    else
                        DIGIT <= DIGIT + 1;
                        STATE <= ST_SETUP;
                    end if;
                -- end state ST_END_WRITE
            end case; -- STATE
        end if; -- rising_edge(DISPCLK)
    end process;
end Behavioral;

