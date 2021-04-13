library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.common;

entity alu is
    port (
            -- Top of data stack
            -- Secondmost data stack element
            -- Top of return stack
            T, N, R: in common.word;
            -- Data stack pointer & return stack pointer
            dsp, rsp: in common.offset;
            -- Operation to perform
            op: in std_ulogic_vector(3 downto 0);
            -- Result of the operation
            result: out common.word
         );
end entity;

architecture rtl of alu is
    signal compare_equal, compare_less, compare_uless: std_ulogic;
begin
    compare_equal <= '1' when N = T else '0';
    compare_less  <= '1' when signed(N) < signed(T) else '0';
    compare_uless <= '1' when unsigned(N) < unsigned(T) else '0';

    process (T, N, R, op)
    begin
        case op is
            when "0000" => result <= T;
            when "0001" => result <= N;
            when "0010" => result <= common.word(unsigned(N) + unsigned(T));
            when "0011" => result <= common.word(unsigned(N) and unsigned(T));
            when "0100" => result <= common.word(unsigned(N) or unsigned(T));
            when "0101" => result <= common.word(unsigned(N) xor unsigned(T));
            when "0110" => result <= common.word(not unsigned(T));
            when "0111" => result <= (others => compare_equal);
            when "1000" => result <= (others => compare_less);
            when "1001" => result <= common.word(unsigned(N) srl to_integer(unsigned(T)));
            when "1010" => result <= common.word(unsigned(T) - 1);
            when "1011" => result <= R;
            when "1110" =>
                result(15 downto 12) <= std_ulogic_vector(rsp);
                result(11 downto 4) <= (others => '0');
                result(3 downto 0) <= std_ulogic_vector(dsp);
            when "1111" => result <= (others => compare_uless);
            when others =>
                report "Invalid ALU operation: " & integer'image(to_integer(unsigned(op)))
                severity error;
        end case;
    end process;
end architecture;
