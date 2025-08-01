library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity acl_system is
    Port ( 
        clk             : in STD_LOGIC;
        rst             : in STD_LOGIC;
        source_packet   : in STD_LOGIC_VECTOR(103 downto 0);
        
        acl_done        : out STD_LOGIC;
        permit          : out STD_LOGIC
    );    
end acl_system;

architecture acl_arch of acl_system is
    signal finish          : std_logic;
    signal accept          : std_logic;
    signal drop            : std_logic;
    signal current_rule    : std_logic_vector(168 downto 0);

    signal rule_index : integer := 0;
    
    type state_type is (IDLE, CHECK_RULE, FINISHED);
    signal state : state_type := IDLE;

    constant NUM_RULES : integer := 3;
    type acl_rom_type is array (0 to NUM_RULES - 1) of std_logic_vector(168 downto 0);
    

    constant ACL_ROM : acl_rom_type := (
        -- Rule 0: Permit TCP traffic from 192.168.1.0/24 to web server 10.20.30.40:80
        0 => "1" & "11000000101010000000000100000000" & "11111111111111111111111100000000" & "00001010000101000001111000101000" & "11111111111111111111111111111111" & "00000110" & x"0000" & x"0050",
        -- Rule 1: Deny any traffic from "bad" host 172.16.10.10
        1 => "0" & "10101100000100000000101000001010" & "11111111111111111111111111111111" & x"00000000" & x"00000000" & x"00" & x"0000" & x"0000",
        -- Rule 2: Permit ICMP (ping) from any source to any destination
        2 => "1" & x"00000000" & x"00000000" & x"00000000" & x"00000000" & "00000001" & x"0000" & x"0000"
    );
    
    component top_level is
        port (
            clk           : in  std_logic;
            rst           : in  std_logic;
            source_packet : in  std_logic_vector(103 downto 0);
            acl_rule      : in  std_logic_vector(168 downto 0);

            finish        : out std_logic;
            accept        : out std_logic;
            drop          : out std_logic
        );
    end component;

begin
    ace_inst : top_level
        port map (
            clk             => clk,
            rst             => rst,
            source_packet   => source_packet,
            acl_rule        => current_rule,
            finish          => finish,
            accept          => accept,
            drop            => drop
        );
    
    process(clk, rst)
    begin
        if rst = '1' then
            current_rule <= (others => '0');
            permit <= '0';
            state <= IDLE;
            
        elsif rising_edge(clk) then
            case state is
                when IDLE =>
                    rule_index <= 0;  -- Reset rule index
                    permit <= '0';
                    acl_done <= '0';
                    state <= CHECK_RULE;

                when CHECK_RULE =>
                    if rule_index < NUM_RULES and accept = '0' and drop = '0' then
                        current_rule <= ACL_ROM(rule_index);
                        
                        if finish = '1' then
                            rule_index <= rule_index + 1;
                        end if;
                        
                    else
                        permit <= accept;
                        state <= FINISHED;
                    end if;
                                        
                when FINISHED =>
                    acl_done <= '1';
                    state <= IDLE;
            end case;
        end if;
    end process;
end architecture;