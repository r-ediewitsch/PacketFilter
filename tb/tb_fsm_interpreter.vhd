library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity tb_fsm_interpreter is
end entity;

architecture test of tb_fsm_interpreter is
    signal clk         : std_logic := '0';
    signal rst         : std_logic := '1';
    signal start       : std_logic := '0';
    signal micro_instr : std_logic_vector(15 downto 0);

    signal protocol    : std_logic_vector(7 downto 0)  := x"11";
    signal source_addr : std_logic_vector(31 downto 0) := x"C0A80164"; -- 192.168.1.100
    signal source_port : std_logic_vector(15 downto 0) := x"1234";
    signal dest_addr   : std_logic_vector(31 downto 0) := x"08080808";
    signal dest_port   : std_logic_vector(15 downto 0) := x"0050";

    signal jump_en     : std_logic;
    signal jump_addr   : std_logic_vector(7 downto 0);
    signal done        : std_logic;
    signal accept      : std_logic;
    signal drop        : std_logic;

    constant clk_period : time := 10 ns;

begin
    -- Clock process
    clk_process : process
    begin
        clk <= '0';
        wait for clk_period / 2;
        clk <= '1';
        wait for clk_period / 2;
    end process;

    -- DUT instance
    uut: entity work.fsm_interpreter
        port map (
            clk => clk,
            rst => rst,
            start => start,
            micro_instr => micro_instr,
            protocol => protocol,
            source_addr => source_addr,
            source_port => source_port,
            dest_addr => dest_addr,
            dest_port => dest_port,
            jump_en => jump_en,
            jump_addr => jump_addr,
            done => done,
            accept => accept,
            drop => drop
        );

    -- Stimulus process
    stimulus: process
        procedure exec(instr : std_logic_vector(15 downto 0)) is
        begin
            micro_instr <= instr;
            start <= '1';
            wait for clk_period;
            start <= '0';

            wait until done = '1';
            wait for clk_period;
        end procedure;
    begin
        -- Reset
        wait for clk_period * 2;
        rst <= '0';

        report "TEST 1: CMP_IP match (should set cmp_flag = 1)";
        exec("0001" & "000" & "0" & x"C0");

        report "TEST 2: JNZ (cmp_flag = 1, should NOT jump)";
        exec("1000" & "000" & "0" & x"55");
        if jump_en = '1' then
            report "FAIL: JNZ incorrectly jumped" severity error;
        else
            report "PASS: JNZ did not jump as expected" severity note;
        end if;

        report "TEST 3: CMP_IP mismatch (should set cmp_flag = 0)";
        exec("0001" & "000" & "0" & x"DE");

        report "TEST 4: JNZ (cmp_flag = 0, should jump)";
        exec("1000" & "000" & "0" & x"AA");
        if jump_en = '1' and jump_addr = x"AA" then
            report "PASS: JNZ jumped to " & integer'image(to_integer(unsigned(jump_addr))) severity note;
        else
            report "FAIL: JNZ did NOT jump as expected" severity error;
        end if;

        report "TEST 5: ACCEPT instruction";
        exec("1110" & "000" & "1" & x"00");
        if accept = '1' then
            report "PASS: ACCEPT set accept = 1" severity note;
        else
            report "FAIL: ACCEPT did not set accept = 1" severity error;
        end if;

        report "TEST 6: DENY instruction";
        exec("1111" & "000" & "1" & x"00");
        if drop = '1' then
            report "PASS: DENY set drop = 1" severity note;
        else
            report "FAIL: DENY did not set drop = 1" severity error;
        end if;

        wait;
    end process;
end architecture;
