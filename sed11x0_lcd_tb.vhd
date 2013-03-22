
library ieee;
    use ieee.std_logic_1164.all;
--    use ieee.numeric_bit.all;
    use ieee.numeric_std.all;

entity SED11x0_LCD_TB is
end SED11x0_LCD_TB;

architecture Behavioral of SED11x0_LCD_TB is
    component SED11x0_LCD
        port(
            FB_ADDR:  in std_logic_vector(13 downto 0);
            FB_DI:    in std_logic_vector(0 downto 0);
            FB_DO:    out std_logic_vector(0 downto 0);
            FB_EN:    in std_logic;
            FB_SSR:   in std_logic;
            FB_WE:    in std_logic;
            
            SYS_CLK:      in std_logic;
            DISP_CLK:     in std_logic;
            
            SED11x0_LP:   out std_logic;-- pin 4
            SED11x0_FR:   out std_logic;-- pin 5
            SED11x0_YDIS: out std_logic;-- pin 6
            SED11x0_YSCL: out std_logic;-- pin 7
            SED11x0_DIN:  out std_logic;-- pin 8
            SED11x0_XSCL: out std_logic;-- pin 9
            SED11x0_XECL: out std_logic;-- pin 10
            SED11x0_DAT:  out std_logic_vector(3 downto 0) -- pins 11-14
        );
    end component;
--     for SED11x0_LCD_0: SED11x0_LCD use entity work.SED11x0_LCD;
    
    signal FB_ADDR: std_logic_vector(13 downto 0) := (others => '0');
    signal FB_DI: std_logic_vector(0 downto 0) := "0";
    signal FB_DO: std_logic_vector(0 downto 0) := "0";
    signal FB_EN: std_logic := '0';
    signal FB_SSR: std_logic := '0';
    signal FB_WE: std_logic := '0';
    
    signal SYS_CLK: std_logic := '0';
    
    signal SED11x0_LP: std_logic := '0';
    signal SED11x0_FR: std_logic := '0';
    signal SED11x0_YDIS: std_logic := '0';
    signal SED11x0_YSCL: std_logic := '0';
    signal SED11x0_DIN: std_logic := '0';
    signal SED11x0_XSCL: std_logic := '0';
    signal SED11x0_XECL: std_logic := '0';
    signal SED11x0_DAT : std_logic_vector(3 downto 0) := "0000";
    
begin
    SED11x0_LCD_0: SED11x0_LCD port map(
        FB_ADDR => FB_ADDR,
        FB_DI => FB_DI,
        FB_DO => FB_DO,
        FB_EN => FB_EN,
        FB_SSR => FB_SSR,
        FB_WE => FB_WE,
        
        SYS_CLK => SYS_CLK,
        DISP_CLK => SYS_CLK,
        
        SED11x0_LP => SED11x0_LP,
        SED11x0_FR => SED11x0_FR,
        SED11x0_YDIS => SED11x0_YDIS,
        SED11x0_YSCL => SED11x0_YSCL,
        SED11x0_DIN => SED11x0_DIN,
        SED11x0_XSCL => SED11x0_XSCL,
        SED11x0_XECL => SED11x0_XECL,
        SED11x0_DAT => SED11x0_DAT
    );
    
    process
    begin
        for i in 0 to 1000000000 loop
            SYS_CLK <= '1';
            wait for 1 ns;
            SYS_CLK <= '0';
            wait for 1 ns;
        end loop;
        wait; -- Wait forever; this will finish the simulation.
    end process;
end Behavioral;
