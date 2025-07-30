library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity top_level is
    Port ( 
        clk             : in STD_LOGIC;
        rst             : in STD_LOGIC;
        source_ip       : in STD_LOGIC_VECTOR(31 downto 0);
        allowed_network : in STD_LOGIC_VECTOR(31 downto 0);
        subnet_mask     : in STD_LOGIC_VECTOR(31 downto 0);

        accept          : out STD_LOGIC;
        drop            : out STD_LOGIC
    );    
end top_level;

architecture top_arch of top_level is
    signal masked_source    : std_logic_vector(31 downto 0);
    signal masked_allowed   : std_logic_vector(31 downto 0);
    signal instr_addr       : std_logic_vector(7 downto 0) := (others => '0');
    signal micro_instr      : std_logic_vector(15 downto 0);
    signal jump_addr        : std_logic_vector(7 downto 0);
    signal jump_en          : std_logic;
    signal cmp_result       : std_logic;
    signal accept_sig       : std_logic;
    signal drop_sig         : std_logic;
    signal done             : std_logic;

    component microinstr_gen is
        port (
            address     : in  std_logic_vector(7 downto 0);
            allowed_ip  : in  std_logic_vector(31 downto 0);
            instruction : out std_logic_vector(15 downto 0)
        );
    end component;

    component fsm_interpreter is
        port (
            clk         : in  std_logic;
            rst         : in  std_logic;
            micro_instr : in  std_logic_vector(15 downto 0);
            source_ip   : in  std_logic_vector(31 downto 0);

            jump_addr   : out std_logic_vector(7 downto 0);
            jump_en     : out std_logic;
            accept      : out std_logic;
            drop        : out std_logic;
            done        : out std_logic
        );
    end component;

begin
    masked_source  <= source_ip and subnet_mask;
    masked_allowed <= allowed_network and subnet_mask;
    
    microgen_inst: microinstr_gen
        port map (
            address     => instr_addr,
            allowed_ip  => masked_allowed,
            instruction => micro_instr
        );

    interpreter_inst: fsm_interpreter
        port map (
            clk         => clk,
            rst         => rst,
            micro_instr => micro_instr,
            source_ip   => masked_source,
            jump_addr   => jump_addr,
            jump_en     => jump_en,
            accept      => accept_sig,
            drop        => drop_sig,
            done        => done
        );
    
    process(clk, rst)
    begin
        if rst = '1' then
            instr_addr <= (others => '0');
        elsif rising_edge(clk) then
            if done = '1' then
                if jump_en = '1' then
                    instr_addr <= jump_addr;
                else
                    instr_addr <= std_logic_vector(unsigned(instr_addr) + 1);
                end if;
            end if;
        end if;
    end process;
end architecture;