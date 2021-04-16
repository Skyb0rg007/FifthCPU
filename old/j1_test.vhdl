library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.common;
use work.j1;

entity j1_test is
end entity;

architecture rtl of j1_test is
    constant nop:   common.word := "0110000000000000";
    constant lit_1: common.word := "1000000000000011";
    constant lit_2: common.word := "1000000000000010";
    constant add:   common.word := "0110001000000000";

    type instructions_type is array (3 downto 0) of common.word;
    constant instructions: instructions_type := (add, add, lit_2, lit_1);

    signal clock: std_ulogic := '1';
    signal t: integer := 0;
    signal finished: boolean := false;
    signal code_address: common.address := (others => '0');
    signal instruction: common.word := nop;
    signal tos, nos: common.word := (others => '0');
begin
    instance: entity j1
    port map (
                 clock => clock,
                 instruction => instruction,
                 code_address => code_address,
                 tos => tos, nos => nos
             );

    clock <= not clock after 5 ns when not finished else '0';

    process (clock)
    begin
        if falling_edge(clock) then
            if t < 4 then
                instruction <= instructions(t);
            else
                instruction <= nop;
            end if;
            t <= t + 1;
            finished <= t = 10;
        end if;
    end process;
end architecture;
