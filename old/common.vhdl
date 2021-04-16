library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package common is
    subtype word    is std_ulogic_vector(15 downto 0);
    subtype address is std_ulogic_vector(12 downto 0);
    subtype offset  is unsigned(3 downto 0);

    constant start_address:   natural  := 0;
    constant stack_size_log2: positive := 4;
    constant stack_size:      positive := 2 ** stack_size_log2;
end package;
