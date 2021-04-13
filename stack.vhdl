library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use work.common;

entity stack is
    port (

            clock:         in  std_ulogic;
            read_address:  in  common.offset;
            read_data:     out common.word;
            write_address: in  common.offset;
            write_data:    in  common.word;
            write_enable:  in  std_ulogic
         );
end entity;


architecture rtl of stack is
    type stack_type is array (31 downto 0) of common.word;
    signal store: stack_type := (others => (others => '0'));
begin
    read_data <= store(to_integer(read_address));

    process
    begin
        wait until rising_edge(clock);
        if write_enable = '1' then
            store(to_integer(write_address)) <= write_data;
        end if;
    end process;
end architecture;
