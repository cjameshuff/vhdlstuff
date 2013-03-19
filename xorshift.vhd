
-- Xorshift pseudo-random number generator
-- http://en.wikipedia.org/wiki/Xorshift

-- uint32_t xor128(void) {
--     static uint32_t x = 123456789;
--     static uint32_t y = 362436069;
--     static uint32_t z = 521288629;
--     static uint32_t w = 88675123;
--     uint32_t t;
-- 
--     t = x ^ (x << 11); x = y; y = z; z = w;
--     w = w ^ (w >> 19) ^ (t ^ (t >> 8));
--     return w;
-- }

library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

entity XORSHIFT_128 is
    port (
        CLK : in std_logic;
        RESET : in std_logic;
        OUTPUT : out std_logic_vector(127 downto 0)
    );
end XORSHIFT_128;

architecture Behavioral of XORSHIFT_128 is
    signal STATE : unsigned(127 downto 0) := to_unsigned(1, 128);
    
begin
    OUTPUT <= std_logic_vector(STATE);
    
    Update : process(CLK) is
        variable tmp : unsigned(31 downto 0);
    begin
        if(rising_edge(CLK)) then
            if(RESET = '1') then
                STATE <= (others => '0');
            end if;
            tmp := (STATE(127 downto 96) xor (STATE(127 downto 96) sll 11));
            STATE <= STATE(95 downto 0) &
                ((STATE(31 downto 0) xor (STATE(31 downto 0) srl 19)) xor (tmp xor (tmp srl 8)));
        end if; -- rising_edge(CLK)
    end process;
end Behavioral;

