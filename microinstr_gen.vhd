library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity microinstr_gen is
    Port ( 
        address        : in STD_LOGIC_VECTOR(7 downto 0);
        allowed_ip     : in STD_LOGIC_VECTOR(31 downto 0);
        instruction    : out STD_LOGIC_VECTOR(15 downto 0)
    );
end microinstr_gen;

architecture generator_arch of microinstr_gen is
begin
    process(address, allowed_ip)
        variable instr : STD_LOGIC_VECTOR(15 downto 0);
        --variable index : integer := to_integer(unsigned(address));
    begin
         case to_integer(unsigned(address)) is
            when 0 => -- CMP field 0
                instr := "0001" & "00" & allowed_ip(31 downto 24) & "00";

            when 1 => -- JNZ to instruction 2
                instr := "1000" & "0000" & "00000010";

            when 2 => -- CMP field 1
                instr := "0001" & "01" & allowed_ip(23 downto 16) & "00";

            when 3 =>
                instr := "1000" & "0000" & "00000100";

            when 4 =>
                instr := "0001" & "10" & allowed_ip(15 downto 8) & "00";

            when 5 =>
                instr := "1000" & "0000" & "00000110";

            when 6 =>
                instr := "0001" & "11" & allowed_ip(7 downto 0) & "00";

            when 7 =>
                instr := "1000" & "0000" & "00001000";

            when 8 => -- ACCEPT
                instr := "1110000000000000";

            when 9 => -- DROP fallback
                instr := "1111000000000000";

            when others =>
                instr := (others => '0');
        end case;

        instruction <= instr;
    end process;
end architecture;