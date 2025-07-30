library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity fsm_interpreter is
    Port ( 
        clk            : in STD_LOGIC;
        rst            : in STD_LOGIC;
        micro_instr    : in STD_LOGIC_VECTOR(15 downto 0);
        source_ip      : in STD_LOGIC_VECTOR(31 downto 0);

        jump_en        : out STD_LOGIC;
        jump_addr      : out STD_LOGIC_VECTOR(7 downto 0);
        accept         : out STD_LOGIC;
        drop           : out STD_LOGIC
    );    
end fsm_interpreter;
    
architecture interpreter_arch of fsm_interpreter is
    type state_type is (IDLE, DECODE, EXECUTE, FINISH);
    signal current_state : state_type := IDLE;
    
    signal opcode   : STD_LOGIC_VECTOR(3 downto 0);
    signal field    : integer range 0 to 3;
    signal value    : STD_LOGIC_VECTOR(7 downto 0);
    signal jmp_addr : STD_LOGIC_VECTOR(7 downto 0);
    signal cmp_flag : STD_LOGIC := '0';
    
    function get_octet(ip     : STD_LOGIC_VECTOR(31 downto 0);
                       index  : integer)
                       return STD_LOGIC_VECTOR is 
    begin
        case index is
            when 0 => return ip(31 downto 24);
            when 1 => return ip(23 downto 16);
            when 2 => return ip(15 downto 8);
            when 3 => return ip(7 downto 0);
            when others => return (others => '0');
        end case;
    end;
    
begin
    process(clk, rst)
    begin
        if rst = '1' then
            jump_en <= '0';
            accept <= '0';
            drop <= '0';
            cmp_flag <= '0';
            current_state <= IDLE;
        
        elsif rising_edge(clk) then
            case current_state is
                when IDLE =>
                    jump_en <= '0';
                    accept <= '0';
                    drop <= '0';
                    current_state <= DECODE;
                    
                when DECODE =>
                    opcode   <= micro_instr(15 downto 12);
                    field    <= to_integer(unsigned(micro_instr(11 downto 10)));
                    value    <= micro_instr(9 downto 2);
                    jmp_addr <= micro_instr(7 downto 0);
                    
                    current_state <= EXECUTE;
                    
                when EXECUTE =>
                    case opcode is
                        when "0001" =>
                            if get_octet(source_ip, field) = value then
                                cmp_flag <= '1';
                            else
                                cmp_flag <= '0';
                            end if;
                            
                            current_state <= FINISH;
                            
                        when "1000" =>
                            if cmp_flag = '0' then
                                jump_en <= '1';
                                jump_addr <= jmp_addr;
                            end if;
                            
                            current_state <= FINISH;
                            
                        when "1110" => 
                            accept <= '1';
                            current_state <= FINISH;
                            
                        when "1111" => 
                            drop <= '1';
                            current_state <= FINISH;
                            
                        when others =>
                            current_state <= FINISH;
                    end case;
                
                when FINISH =>
                    current_state <= IDLE;
                    
            end case;
        end if;
    end process;    
end architecture;