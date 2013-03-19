
library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

entity XORSHIFT_TB is
end XORSHIFT_TB;

architecture Behavioral of XORSHIFT_TB is
    component XORSHIFT_128
        port (
            CLK : in std_logic;
            RESET : in std_logic;
            OUTPUT : out std_logic_vector(127 downto 0)
        );
    end component;
    
    for XORSHIFT_0: XORSHIFT_128 use entity work.XORSHIFT_128;
    
    signal SYSCLK: std_logic := '1';
    signal RESET : std_logic := '1';
    signal OUTPUT : std_logic_vector(127 downto 0);
    
begin
    XORSHIFT_0: XORSHIFT_128 port map(
        CLK => SYSCLK,
        RESET => RESET,
        OUTPUT => OUTPUT
    );
    
    process
    begin
        for i in 0 to 10240 loop
            SYSCLK <= '1';
            wait for 1 ns;
            SYSCLK <= '0';
            wait for 1 ns;
        end loop;
        assert false report "end of test" severity note;
        wait; -- Wait forever; this will finish the simulation.
    end process;
end Behavioral;
