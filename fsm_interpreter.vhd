library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity fsm_interpreter is
    Port ( 
        clk            : in STD_LOGIC;
        rst            : in STD_LOGIC;
        start          : in STD_LOGIC;
        micro_instr    : in STD_LOGIC_VECTOR(15 downto 0);
        
        protocol       : in STD_LOGIC_VECTOR(7 downto 0); 
        source_addr    : in STD_LOGIC_VECTOR(31 downto 0);
        source_port    : in STD_LOGIC_VECTOR(15 downto 0);
        dest_addr      : in STD_LOGIC_VECTOR(31 downto 0);
        dest_port      : in STD_LOGIC_VECTOR(15 downto 0);

        jump_en        : out STD_LOGIC;
        jump_addr      : out STD_LOGIC_VECTOR(7 downto 0);
        done           : out STD_LOGIC;
        accept         : out STD_LOGIC;
        drop           : out STD_LOGIC
    );    
end fsm_interpreter;
    
architecture interpreter_arch of fsm_interpreter is
    type state_type is (IDLE, DECODE, EXECUTE, FINISH);
    signal current_state : state_type := IDLE;
    
    signal opcode   : STD_LOGIC_VECTOR(3 downto 0);
    signal field    : integer range 0 to 7;
    signal value    : STD_LOGIC_VECTOR(7 downto 0);
    signal jmp_addr : STD_LOGIC_VECTOR(7 downto 0);
    signal cmp_flag : STD_LOGIC := '0';
    signal permit   : STD_LOGIC := '0';
    signal control  : integer := 0;
    
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
    
    function get_octet(pr     : STD_LOGIC_VECTOR(7 downto 0);
                       sip    : STD_LOGIC_VECTOR(31 downto 0);
                       sport  : STD_LOGIC_VECTOR(15 downto 0);
                       dip    : STD_LOGIC_VECTOR(31 downto 0);
                       dport  : STD_LOGIC_VECTOR(15 downto 0);
                       opcode : STD_LOGIC_VECTOR(3 downto 0);
                       index  : integer)
                       return STD_LOGIC_VECTOR is 
    begin
        case index is
            when 0 => return sip(31 downto 24);
            when 1 => 
                case opcode is
                    when "0001" => return sip(23 downto 16);
                    when "0010" => return pr(7 downto 0);
                end case;
            when 2 =>
                case opcode is
                    when "0001" => return sip(15 downto 8);
                    when "0010" => return sport(15 downto 8);
                end case;
            when 3 =>
                case opcode is
                    when "0001" => return sip(7 downto 0);
                    when "0010" => return sport(7 downto 0);
                end case;
            when 4 =>
                case opcode is
                    when "0001" => return dip(31 downto 24);
                    when "0010" => return dport(15 downto 8);
                end case;
            when 5 =>
                case opcode is
                    when "0001" => return dip(23 downto 16);
                    when "0010" => return dport(7 downto 0);
                end case;
            when 6 => return dip(15 downto 8);
            when 7 => return dip(7 downto 0);
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
            control <= 0;
            current_state <= IDLE;
        
        elsif rising_edge(clk) then
            case current_state is
                when IDLE =>
                    done <= '0';
                    jump_en <= '0';
                    accept <= '0';
                    drop <= '0';
                    
                    if start = '1' then
                        control <= control + 1;
                    end if;
                    
                    if control = 1 then     -- 1 clock cycle delay
                        control <= 0;
                        current_state <= DECODE;
                    end if;
                    
                when DECODE =>
                    opcode   <= micro_instr(15 downto 12);
                    field    <= to_integer(unsigned(micro_instr(11 downto 9)));
                    permit   <= micro_instr(8);
                    value    <= micro_instr(7 downto 0);
                    jmp_addr <= micro_instr(7 downto 0);
                    
                    current_state <= EXECUTE;
                    
                when EXECUTE =>
                    case opcode is
                        when "0001" =>      -- CMP_IP
                            if get_octet(protocol, 
                                         source_addr, source_port, 
                                         dest_addr, dest_port, 
                                         opcode, 
                                         field) = value then
                                cmp_flag <= '1';
                            else
                                cmp_flag <= '0';
                            end if;
                            
                            current_state <= FINISH;
                        
                        when "0010" =>      -- CMP_PR
                            if get_octet(protocol, 
                                         source_addr, source_port, 
                                         dest_addr, dest_port, 
                                         opcode, 
                                         field) = value then
                                cmp_flag <= '1';
                            else
                                cmp_flag <= '0';
                            end if;
                            
                            current_state <= FINISH;
                        
                        when "1000" =>     -- JNZ
                            if cmp_flag = '0' then
                                jump_en <= '1';
                                jump_addr <= jmp_addr;
                            end if;
                            
                            current_state <= FINISH;
                            
                        when "1110" =>     -- ACCEPT
                            if permit = '1' then
                                accept <= '1';
                            else
                                drop <= '1';
                            end if;
                            
                            current_state <= FINISH;
                            
                        when "1111" =>     -- DENY
                            if permit = '1' then
                                drop <= '1';
                            else
                                accept <= '1';
                            end if;
                            
                            current_state <= FINISH;
                            
                        when others =>
                            current_state <= FINISH;
                    end case;
                
                when FINISH =>
                    done <= '1';
                    current_state <= IDLE; 
            end case;
        end if;
    end process;    
end architecture;