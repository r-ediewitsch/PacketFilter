library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity microinstr_gen is
    Port ( 
        permit            : in STD_LOGIC;
        address           : in STD_LOGIC_VECTOR(7 downto 0);
        allowed_protocol  : in STD_LOGIC_VECTOR(7 downto 0);
        allowed_src_ip    : in STD_LOGIC_VECTOR(31 downto 0);
        allowed_dst_ip    : in STD_LOGIC_VECTOR(31 downto 0);
        allowed_src_port  : in STD_LOGIC_VECTOR(15 downto 0);
        allowed_dst_port  : in STD_LOGIC_VECTOR(15 downto 0);
        instruction       : out STD_LOGIC_VECTOR(15 downto 0)
    );
end microinstr_gen;

architecture generator_arch of microinstr_gen is
begin
    process(address, allowed_src_ip, allowed_dst_ip)
        variable instr : STD_LOGIC_VECTOR(15 downto 0);
    begin
        case to_integer(unsigned(address)) is
            -- Source IP (4 bytes)
            when 0 => instr := "0001" & "000" & permit & allowed_src_ip(31 downto 24);
            when 1 => instr := "1000" & "000" & permit & "00011011"; -- jump to final if mismatch
            when 2 => instr := "0001" & "001" & permit & allowed_src_ip(23 downto 16);
            when 3 => instr := "1000" & "000" & permit & "00011011";
            when 4 => instr := "0001" & "010" & permit & allowed_src_ip(15 downto 8);
            when 5 => instr := "1000" & "000" & permit & "00011011";
            when 6 => instr := "0001" & "011" & permit & allowed_src_ip(7 downto 0);
            when 7 => instr := "1000" & "000" & permit & "00011011";

            -- Destination IP (4 bytes)
            when 8  => instr := "0001" & "100" & permit & allowed_dst_ip(31 downto 24);
            when 9  => instr := "1000" & "000" & permit & "00011011";
            when 10 => instr := "0001" & "101" & permit & allowed_dst_ip(23 downto 16);
            when 11 => instr := "1000" & "000" & permit & "00011011";
            when 12 => instr := "0001" & "110" & permit & allowed_dst_ip(15 downto 8);
            when 13 => instr := "1000" & "000" & permit & "00011011";
            when 14 => instr := "0001" & "111" & permit & allowed_dst_ip(7 downto 0);
            when 15 => instr := "1000" & "000" & permit & "00011011";

            -- Protocol
            when 16 => instr := "0010" & "001" & permit & allowed_protocol;
            when 17 => instr := "1000" & "000" & permit & "00011011";

            -- Source Port (2 bytes)
            when 18 => instr := "0010" & "010" & permit & allowed_src_port(15 downto 8);
            when 19 => instr := "1000" & "000" & permit & "00011011";
            when 20 => instr := "0010" & "011" & permit & allowed_src_port(7 downto 0);
            when 21 => instr := "1000" & "000" & permit & "00011011";

            -- Destination Port (2 bytes)
            when 22 => instr := "0010" & "100" & permit & allowed_dst_port(15 downto 8);
            when 23 => instr := "1000" & "000" & permit & "00011011";
            when 24 => instr := "0010" & "101" & permit & allowed_dst_port(7 downto 0);
            when 25 => instr := "1000" & "000" & permit & "00011011";

            -- Accept
            when 26 => instr := "1110" & "000" & permit & "00000000";
            -- Deny fallback
            when 27 => instr := "1111" & "000" & permit & "00000000";

            when others => instr := (others => '0');
        end case;

        instruction <= instr;
    end process;
end architecture;