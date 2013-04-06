#!/usr/bin/env ruby

if(ARGV.length == 0)
    puts "Usage:"
    puts "vhdgen.rb ENTITY_NAME"
#     puts "vhdgen.rb ENTITY_NAME [IO_FORMAT]"
#     puts "IO_FORMAT:"
#     puts "\tg:GENERICS (integers)"
#     puts "\ti:IN_PORTS"
#     puts "\to:OUT_PORTS"
#     puts "\tn:INOUT_PORTS"
#     puts "\tb:BUFFER_PORTS"
#     puts "Ports are given std_logic or std_logic_vector types unless otherwise specified."
#     puts "Port mode is given in lower case. Port mode is non-optional."
#     puts "Type, if specified, is given in upper case:"
#     puts "\tI: integer"
#     puts "\tU: unsigned"
#     puts "\tS: signed"
#     puts "\tS: signed"
end

if(ARGV.length >= 1)
    $io_format = ARGV[1]
else
    $io_format = "i:RESET,SYS_CLK;o:OUTPUT"
end

$entity_name = ARGV[0]
$testbed_name = "#{$entity_name}_TB"
$package_name = "#{$entity_name}_pkg"
$arch_name = "Behavioral"


$entity_file_name = "#{$entity_name.downcase}.vhd"
$testbed_file_name = "#{$entity_name.downcase}_tb.vhd"
$package_file_name = "#{$entity_name.downcase}_pkg.vhd"


$port_spec = {}

def port_list(spec, indent)
"#{indent}RESET:   in std_logic;-- asynchronous reset
#{indent}SYS_CLK: in std_logic;
#{indent}OUTPUT:  out std_logic"
end

def port_map(spec, indent)
"#{indent}RESET => RESET,
#{indent}SYS_CLK => SYS_CLK,
#{indent}OUTPUT => OUTPUT"
end

def tb_signal_list(spec, indent)
"#{indent}signal RESET: std_logic := '0';
#{indent}signal SYS_CLK: std_logic := '0';
#{indent}signal OUTPUT: std_logic := '0';"
end

# ******************************************************************************
# Implementation definition
# ******************************************************************************
$implementation = "
library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

library UNISIM;
    use UNISIM.VComponents.all;

entity #{$entity_name} is
    port(
#{port_list($port_spec, "    "*2)}
    );
end #{$entity_name};

architecture #{$arch_name} of #{$entity_name} is
    signal TOG_VAL: std_logic := '0';
    
begin
    MainProc: process(RESET, SYS_CLK) is
    begin
        if(RESET = '1') then
            TOG_VAL <= '0';
        elsif(rising_edge(SYS_CLK)) then
            TOG_VAL <= not TOG_VAL;
        end if;
    end process;
end #{$arch_name};

"


# ******************************************************************************
# Testbed definition
# ******************************************************************************
$testbed = "
library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

library UNISIM;
    use UNISIM.VComponents.all;

library work;
    use work.#{$package_name}.all;

entity #{$testbed_name} is
end #{$testbed_name};

architecture #{$arch_name} of #{$testbed_name} is
#{tb_signal_list($port_spec, "    ")}
    
begin
    #{$entity_name}_0: #{$entity_name}
    port map(
#{port_map($port_spec, "    "*2)}
    );
    
    process
    begin
        for i in 0 to 10240 loop
            SYS_CLK <= '1';
            wait for 1 ns;
            SYS_CLK <= '0';
            wait for 1 ns;
        end loop;
        wait;
        assert false report \"end of test\" severity note;
        wait; -- Wait forever; this will finish the simulation.
    end process;
end #{$arch_name};

"


# ******************************************************************************
# Package definition
# ******************************************************************************
$package = "
library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

library UNISIM;
    use UNISIM.VComponents.all;

package #{$package_name} is
    component #{$entity_name} is
        port(
#{port_list($port_spec, "    "*3)}
        );
    end component;
end package #{$package_name};

"


File.open($entity_file_name, 'w') {|f| f.write($implementation)}
File.open($testbed_file_name, 'w') {|f| f.write($testbed)}
File.open($package_file_name, 'w') {|f| f.write($package)}

puts "******************************************************************************"
puts "******************************************************************************"
puts $implementation
puts ""
puts "******************************************************************************"
puts "******************************************************************************"
puts $testbed
puts ""
puts "******************************************************************************"
puts "Package definition"
puts "******************************************************************************"
puts $package

