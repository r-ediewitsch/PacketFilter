library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity acl_system_tb is
end acl_system_tb;

architecture behavior of acl_system_tb is
    -- Component Declaration for the Device Under Test (DUT)
    component acl_system is
        Port (
            clk           : in  STD_LOGIC;
            rst           : in  STD_LOGIC;
            source_packet : in  STD_LOGIC_VECTOR(103 downto 0);
            acl_done      : out STD_LOGIC;
            permit        : out STD_LOGIC
        );
    end component;

    -- Inputs
    signal clk           : std_logic := '0';
    signal rst           : std_logic := '0';
    signal source_packet : std_logic_vector(103 downto 0) := (others => '0');

    -- Outputs
    signal acl_done : std_logic;
    signal permit   : std_logic;

    -- Clock period definition
    constant clk_period : time := 1 ns;

    -- Test Case Packet Data
    -- Packet 1: Should match Rule 0 and be PERMITTED.
    constant PACKET_MATCH_RULE_0 : std_logic_vector(103 downto 0) := x"06C0A80132C0010A141E280050";
    -- Packet 2: Should be blocked by Rule 1 and be DENIED.
    constant PACKET_MATCH_RULE_1 : std_logic_vector(103 downto 0) := x"11AC100A0AA001080808080035";
    -- Packet 3: Should match Rule 2 and be PERMITTED.
    constant PACKET_MATCH_RULE_2 : std_logic_vector(103 downto 0) := x"01C0A8016400000A141E280000";
    -- Packet 4: Should not match any rule and be DENIED by default.
    constant PACKET_NO_MATCH : std_logic_vector(103 downto 0) := x"1101010101B00102020202B002";

begin

    -- Instantiate the Unit Under Test (UUT)
    uut: acl_system
        port map (
            clk           => clk,
            rst           => rst,
            source_packet => source_packet,
            acl_done      => acl_done,
            permit        => permit
        );

    -- Clock process definition
    clk_process : process
    begin
        clk <= '0';
        wait for clk_period/2;
        clk <= '1';
        wait for clk_period/2;
    end process;

    -- Stimulus process
    stim_proc: process
    begin
        report "Starting Testbench";
        rst <= '1';
        wait for 2 * clk_period;
        rst <= '0';
        wait for clk_period;

        -- TEST CASE 1: MATCH RULE 0 (PERMIT)
        report "TEST 1: Applying packet that should match Rule 0. EXPECT: PERMIT";
        source_packet <= PACKET_MATCH_RULE_0;
        wait until rising_edge(acl_done);
        wait for clk_period; -- Allow signals to settle
        assert (permit = '1')
            report "TEST 1 FAILED: Packet was not permitted." severity error;
        if (permit = '1') then
            report "TEST 1 PASSED: Packet was correctly PERMITTED.";
        end if;

        -- TEST CASE 2: MATCH RULE 1 (DENY)
        report "TEST 2: Applying packet that should be denied by Rule 1. EXPECT: DENY";
        source_packet <= PACKET_MATCH_RULE_1;
        wait until rising_edge(acl_done);
        wait for clk_period;
        assert (permit = '0')
            report "TEST 2 FAILED: Packet was not denied." severity error;
        if (permit = '0') then
            report "TEST 2 PASSED: Packet was correctly DENIED.";
        end if;

        -- TEST CASE 3: MATCH RULE 2 (PERMIT)
        report "TEST 3: Applying ICMP packet that should match Rule 2. EXPECT: PERMIT";
        source_packet <= PACKET_MATCH_RULE_2;
        wait until rising_edge(acl_done);
        wait for clk_period;
        assert (permit = '1')
            report "TEST 3 FAILED: ICMP packet was not permitted." severity error;
        if (permit = '1') then
            report "TEST 3 PASSED: ICMP packet was correctly PERMITTED.";
        end if;

        -- TEST CASE 4: NO MATCH (DEFAULT DENY)
        report "TEST 4: Applying packet that matches no rules. EXPECT: DENY";
        source_packet <= PACKET_NO_MATCH;
        wait until rising_edge(acl_done);
        wait for clk_period;
        assert (permit = '0')
            report "TEST 4 FAILED: Packet was not denied by default." severity error;
        if (permit = '0') then
            report "TEST 4 PASSED: Packet was correctly DENIED by default.";
        end if;

        report "All test cases finished." severity note;
        wait;
    end process;

end behavior;