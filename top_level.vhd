library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity top_level is
    Port ( 
        clk             : in STD_LOGIC;
        rst             : in STD_LOGIC;
        source_packet   : in STD_LOGIC_VECTOR(103 downto 0);
        acl_rule        : in STD_LOGIC_VECTOR(168 downto 0);

        accept          : out STD_LOGIC;
        drop            : out STD_LOGIC
    );    
end top_level;

architecture top_arch of top_level is
    type state_type is (IDLE, DECODE, GEN, EXECUTE);
    signal state : state_type := IDLE;
    
    signal protocol          : std_logic_vector(7 downto 0);
    signal source_addr       : std_logic_vector(31 downto 0);
    signal dest_addr         : std_logic_vector(31 downto 0);
    signal source_port       : std_logic_vector(15 downto 0);
    signal dest_port         : std_logic_vector(15 downto 0);
    
    signal masked_source     : std_logic_vector(31 downto 0) := (others => '0');
    signal masked_allowed_sc : std_logic_vector(31 downto 0) := (others => '0');
    signal masked_dest       : std_logic_vector(31 downto 0) := (others => '0');
    signal masked_allowed_ds : std_logic_vector(31 downto 0) := (others => '0');
    
    signal permit            : std_logic := '0';
    signal source_allowed_ip : std_logic_vector(31 downto 0);
    signal source_mask       : std_logic_vector(31 downto 0);
    signal dest_allowed_ip   : std_logic_vector(31 downto 0);
    signal dest_mask         : std_logic_vector(31 downto 0);
    signal allowed_protocol  : std_logic_vector(7 downto 0);
    signal src_allowed_port  : std_logic_vector(15 downto 0);
    signal dest_allowed_port : std_logic_vector(15 downto 0);
    
    signal instr_addr        : std_logic_vector(7 downto 0) := (others => '0');
    signal micro_instr       : std_logic_vector(15 downto 0):= (others => '0');
    signal jump_addr         : std_logic_vector(7 downto 0);
    signal jump_en           : std_logic;
    signal cmp_result        : std_logic;
    
    signal accept_sig        : std_logic;
    signal drop_sig          : std_logic;
    signal start             : std_logic;
    signal done              : std_logic;

    component microinstr_gen is
        port (
            permit            : in STD_LOGIC;
            address           : in STD_LOGIC_VECTOR(7 downto 0);
            allowed_protocol  : in STD_LOGIC_VECTOR(7 downto 0);
            allowed_src_ip    : in STD_LOGIC_VECTOR(31 downto 0);
            allowed_dst_ip    : in STD_LOGIC_VECTOR(31 downto 0);
            allowed_src_port  : in STD_LOGIC_VECTOR(15 downto 0);
            allowed_dst_port  : in STD_LOGIC_VECTOR(15 downto 0);
            instruction       : out STD_LOGIC_VECTOR(15 downto 0)
        );
    end component;

    component fsm_interpreter is
        port (
            clk            : in std_logic;
            rst            : in std_logic;
            start          : in std_logic;
            micro_instr    : in std_logic_vector(15 downto 0);
            
            protocol       : in STD_LOGIC_VECTOR(7 downto 0); 
            source_addr    : in STD_LOGIC_VECTOR(31 downto 0);
            source_port    : in STD_LOGIC_VECTOR(15 downto 0);
            dest_addr      : in STD_LOGIC_VECTOR(31 downto 0);
            dest_port      : in STD_LOGIC_VECTOR(15 downto 0);

            jump_addr      : out std_logic_vector(7 downto 0);
            jump_en        : out std_logic;
            accept         : out std_logic;
            drop           : out std_logic;
            done           : out std_logic
        );
    end component;

begin
    protocol    <= source_packet(103 downto 96);
    source_addr <= source_packet(95 downto 64);
    source_port <= source_packet(63 downto 48);
    dest_addr   <= source_packet(47 downto 16);
    dest_port   <= source_packet(15 downto 0);

    microgen_inst: microinstr_gen
        port map (
            permit            => permit,
            address           => instr_addr,
            allowed_protocol  => allowed_protocol,
            allowed_src_ip    => masked_allowed_sc,
            allowed_dst_ip    => masked_allowed_ds,
            allowed_src_port  => src_allowed_port,
            allowed_dst_port  => dest_allowed_port,
            instruction       => micro_instr
        );

    -- Interpreter not done yet
    interpreter_inst: fsm_interpreter
        port map (
            clk            => clk,
            rst            => rst,
            start          => start,
            micro_instr    => micro_instr,
            
            protocol       => protocol,
            source_addr    => masked_source,
            source_port    => source_port,
            dest_addr      => masked_dest,
            dest_port      => dest_port,

            jump_addr      => jump_addr,
            jump_en        => jump_en,
            accept         => accept_sig,
            drop           => drop_sig,
            done           => done
        );
    
    process(clk, rst)
    begin
        if rst = '1' then
            state <= IDLE;
            instr_addr <= (others => '0');
        elsif rising_edge(clk) then
            case state is
                when IDLE =>
                    state <= DECODE;
                    
                when DECODE =>
                    permit             <= acl_rule(168);
                    source_allowed_ip  <= acl_rule(167 downto 136);
                    source_mask        <= acl_rule(135 downto 104);
                    dest_allowed_ip    <= acl_rule(103 downto 72);
                    dest_mask          <= acl_rule(71 downto 40);
                    allowed_protocol   <= acl_rule(39 downto 32);
                    src_allowed_port   <= acl_rule(31 downto 16);
                    dest_allowed_port  <= acl_rule(15 downto 0);
                    
                    state <= GEN;
                    
                when GEN =>
                    masked_source      <= source_addr and source_mask;
                    masked_allowed_sc  <= source_allowed_ip and source_mask;
                    masked_dest        <= dest_addr and dest_mask;
                    masked_allowed_ds  <= dest_allowed_ip and dest_mask;
                    
                    state <= EXECUTE;
                    
                when EXECUTE =>
                    if done = '1' then
                        if to_integer(unsigned(instr_addr)) <= 21 then
                            if jump_en = '1' then
                                instr_addr <= jump_addr;
                            else
                                instr_addr <= std_logic_vector(unsigned(instr_addr) + 1);
                            end if;
                        else
                            state <= IDLE;
                        end if;
                    end if;
                
           end case;
        end if;
    end process;
end architecture;