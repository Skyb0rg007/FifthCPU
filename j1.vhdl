
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.common;
use work.stack;

entity j1 is
    port (
             clock:           in  std_ulogic;
             -- io_write_enable: out std_ulogic;
             -- io_data_address: in  common.word;
             -- io_data_input:   in  common.word;
             -- io_data_output:  out common.word;
             instruction:     in  common.word;
             code_address:    out common.address;
         );
end entity;

architecture rtl of j1 is
    signal pc, pc_next, pc_plus_one: common.address := (others => '0');

    signal T, T_next, N, R, rwd: common.word := (others => '0');
    signal dsp, rsp, dsp_next, rsp_next: common.offset := x"0";
    signal dwe, rwe: std_ulogic := '0';

    signal dsp_delta, rsp_delta: common.offset := x"0";

    signal func_T2N, func_T2R, func_write, func_iow: std_ulogic;
begin
    pc_plus_one <= std_ulogic_vector(unsigned(pc) + 1);
    code_address <= pc_next;

    -- Data stack
    dstack: entity work.stack
    port map(
                clock         => clock,
                read_address  => dsp,
                read_data     => N,
                write_address => dsp_next,
                write_data    => T,
                write_enable  => dwe
            );

    -- Return stack
    rstack: entity work.stack
    port map(
                clock         => clock,
                read_address  => rsp,
                read_data     => R,
                write_address => rsp_next,
                write_data    => rwd,
                write_enable  => rwe
            );

    -- Determine the value of T_next
    process (all)
    begin
        if instruction(15) = '1' then
            -- Literal: T := instr[14:0]
            T_next <= '0' & instruction(14 downto 0);
        elsif instruction(14 downto 13) = "00" then
            -- Branch: T unaffected
            T_next <= T;
        elsif instruction(14 downto 13) = "01" then
            -- 0Branch: T := N (T controls if branching occurs)
            T_next <= N;
        elsif instruction(14 downto 13) = "10" then
            -- Call: T unaffected
            T_next <= T;
        elsif instruction(14 downto 13) = "11" then
            -- ALU operation
            case instruction(11 downto 8) is
                -- T := T
                when "0000" => T_next <= T;
                -- T := N
                when "0001" => T_next <= N;
                -- T := N + T
                when "0010" => T_next <= common.word(unsigned(N) + unsigned(T));
                -- T := T & N
                when "0011" => T_next <= N and T;
                -- T := T | N
                when "0100" => T_next <= N or T;
                -- T := T ^ N
                when "0101" => T_next <= N xor T;
                -- T := ~T
                when "0110" => T_next <= not T;
                -- T := N == T
                when "0111" => T_next <= (others => N ?= T);
                -- T := N < T
                when "1000" => T_next <= (others => signed(N) ?< signed(T));
                -- T := N >> T
                when "1001" => T_next <= common.word(unsigned(N) srl to_integer(unsigned(T(4 downto 0))));
                -- T := N << T
                when "1010" => T_next <= common.word(unsigned(N) sll to_integer(unsigned(T(4 downto 0))));
                -- T := R
                when "1011" => T_next <= R;
                -- T := *T
                -- when "1100" =>
                -- T := IO/T
                -- when "1101" =>
                -- T := (rdepth << 4) | depth
                when "1110" =>
                    T_next(15 downto 8) <= (others => '0');
                    T_next(7 downto 4) <= std_ulogic_vector(rsp);
                    T_next(3 downto 0) <= std_ulogic_vector(dsp);
                -- T := N u< T
                when "1111" => T_next <= (others => unsigned(N) ?< unsigned(T));
                when others =>
                    T_next <= (others => 'X');
                    report "Invalid ALU instruction: " & integer'image(to_integer(unsigned(instruction(11 downto 8))))
                    severity error;
            end case;
        else
            report "Invalid instruction: " & integer'image(to_integer(unsigned(instruction)))
            severity error;
        end if;
    end process;

    func_T2N   <= instruction(6 downto 4) ?= "001";
    func_T2R   <= instruction(6 downto 4) ?= "010";
    func_write <= instruction(6 downto 4) ?= "011";
    func_iow   <= instruction(6 downto 4) ?= "100";

    rwd <= "00" & pc_plus_one & "0" when instruction(13) = '0' else T;

    process (all)
    begin
        if instruction(15) = '1' then
            -- Literal: dstack[dsp] = T, dsp += 1
            dwe <= '1';
            dsp_delta <= "0001";
        elsif instruction(14 downto 13) = "01" then
            -- Conditional branch: dsp -= 1
            dwe <= '0';
            dsp_delta <= "1111";
        elsif instruction(14 downto 13) = "11" then
            -- ALU op:
            --   if (T->N) dstack[dsp] = T
            --   dsp += instr[1:0]
            dwe <= func_T2N;
            dsp_delta(0) <= instruction(0);
            dsp_delta(3 downto 1) <= (others => instruction(1));
        else
            -- Call/Unconditional branch: no changes
            dwe <= '0';
            dsp_delta <= "0000";
        end if;
        dsp_next <= dsp + dsp_delta;

        case instruction(15 downto 13) is
            -- Call: rstack[rsp] = PC+1, rsp += 1
            when "010" =>  rwe <= '1';
                           rsp_delta <= "0001";
            -- ALU: if (T->R) rstack[rsp] = T, rsp += instr[3:2]
            when "011" =>  rwe <= func_T2R;
                           rsp_delta(0) <= instruction(2);
                           rsp_delta(3 downto 1) <= (others => instruction(3));
            -- Branches: no change
            when others => rwe <= '0';
                           rsp_delta <= "0000";
        end case;
        rsp_next <= rsp + rsp_delta;

        if instruction(15 downto 13) = "000" or instruction(15 downto 13) = "010" or (instruction(15 downto 13) = "001" and (or T) = '0') then
            -- Branch, Call, 0Branch when T != 0: PC := instr[12:0]
            pc_next <= instruction(12 downto 0);
        elsif instruction(15 downto 13) = "011" and instruction(7) = '1' then
            -- ALU op with (R->PC) bit set: PC := R
            pc_next <= R(13 downto 1);
        else
            -- 0Branch with T = 0 or other ALU ops: PC += 1
            pc_next <= pc_plus_one;
        end if;
    end process;

    process (clock)
    begin
        if rising_edge(clock) or falling_edge(clock) then
            pc  <= pc_next;
            T   <= T_next;
            dsp <= dsp_next;
            rsp <= rsp_next;
        end if;
    end process;
end architecture;
