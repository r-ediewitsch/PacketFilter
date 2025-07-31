library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity microinstr_gen is
    Port ( 
        permit         : in STD_LOGIC;
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
                instr := "0001" & "000" & permit & allowed_ip(31 downto 24);

            when 1 => -- JNZ to instruction 2
                instr := "1000" & "000" & permit & "00000010";

            when 2 => -- CMP field 1
                instr := "0001" & "010" & permit & allowed_ip(23 downto 16);

            when 3 =>
                instr := "1000" & "000" & permit & "00000100";

            when 4 =>
                instr := "0001" & "100" & permit & allowed_ip(15 downto 8);

            when 5 =>
                instr := "1000" & "000" & permit & "00000110";

            when 6 =>
                instr := "0001" & "110" & permit & allowed_ip(7 downto 0);

            when 7 =>
                instr := "1000" & "000" & permit & "00001000";

            when 8 => -- ACCEPT
                instr := "1110000" & permit & "00000000";

            when 9 => -- DROP fallback
                instr := "1111000" & permit & "00000000";

            when others =>
                instr := (others => '0');
        end case;

        instruction <= instr;
    end process;
end architecture;