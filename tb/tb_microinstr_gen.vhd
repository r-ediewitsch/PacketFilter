library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- This testbench is not updated for the latest microinstruction generation.

entity tb_microinstr_gen is
end tb_microinstr_gen;

architecture sim of tb_microinstr_gen is

    signal permit            : STD_LOGIC := '1';
    signal address           : STD_LOGIC_VECTOR(7 downto 0);
    signal allowed_protocol  : STD_LOGIC_VECTOR(7 downto 0) := x"06";        -- TCP
    signal allowed_src_ip    : STD_LOGIC_VECTOR(31 downto 0) := x"C0A80101"; -- 192.168.1.1
    signal allowed_dst_ip    : STD_LOGIC_VECTOR(31 downto 0) := x"AC100102"; -- 172.16.1.2
    signal allowed_src_port  : STD_LOGIC_VECTOR(15 downto 0) := x"1F90";     -- 8080
    signal allowed_dst_port  : STD_LOGIC_VECTOR(15 downto 0) := x"0050";     -- 80
    signal instruction       : STD_LOGIC_VECTOR(15 downto 0);

    function to_string(microinstr: std_logic_vector) return string is
        variable s : string(1 to microinstr'length);
    begin
        for i in 1 to microinstr'length loop
            if microinstr(microinstr'length - i) = '1' then
                s(i) := '1';
            else
                s(i) := '0';
            end if;
        end loop;

        return s;
    end function;

begin
    uut: entity work.microinstr_gen
        port map (
            permit           => permit,
            address          => address,
            allowed_protocol => allowed_protocol,
            allowed_src_ip   => allowed_src_ip,
            allowed_dst_ip   => allowed_dst_ip,
            allowed_src_port => allowed_src_port,
            allowed_dst_port => allowed_dst_port,
            instruction      => instruction
        );

    process
        procedure test(addr: integer; expected: std_logic_vector) is
        begin
            address <= std_logic_vector(to_unsigned(addr, 8));
            wait for 10 ns;
            assert instruction = expected
                report "Fail at address " & integer'image(addr) & ": got " & to_string(instruction)
                severity error;
            report "Address " & integer'image(addr) & " OK: " & to_string(instruction);
        end procedure;

    begin
        -- Src IP
        test(0,  "00010001" & x"C0");
        test(1,  "10000001" & x"1B");

        test(2,  "00010011" & x"A8");
        test(3,  "10000001" & x"1B");

        test(4,  "00010101" & x"01");
        test(5,  "10000001" & x"1B");

        test(6,  "00010111" & x"01");
        test(7,  "10000001" & x"1B");

        -- Dst IP
        test(8,  "00011001" & x"AC");
        test(9,  "10000001" & x"1B");

        test(10, "00011011" & x"10");
        test(11, "10000001" & x"1B");

        test(12, "00011101" & x"01");
        test(13, "10000001" & x"1B");

        test(14, "00011111" & x"02");
        test(15, "10000001" & x"1B");

        -- Protocol
        test(16, "00010011" & x"06");
        test(17, "10000001" & x"1B");

        -- Src Port
        test(18, "00010101" & x"1F");
        test(19, "10000001" & x"1B");

        test(20, "00010111" & x"90");
        test(21, "10000001" & x"1B");

        -- Dst Port
        test(22, "00011001" & x"00");
        test(23, "10000001" & x"1B");

        test(24, "00011011" & x"50");
        test(25, "10000001" & x"1B");

        -- Accept
        test(26, "11100001" & x"00");

        -- Drop fallback
        test(27, "11110001" & x"00");

        -- Done
        report "All tests passed." severity note;
        wait;
    end process;

end sim;
