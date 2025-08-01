library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

--  This is the testbench for the top_level entity.
--  It will instantiate the top_level component and apply a series of test vectors
--  to verify the ACL logic.

entity top_level_tb is
end top_level_tb;

architecture behavior of top_level_tb is

    -- Component Declaration for the Device Under Test (DUT)
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

    -- Inputs
    signal clk           : std_logic := '0';
    signal rst           : std_logic := '0';
    signal source_packet : std_logic_vector(103 downto 0) := (others => '0');
    signal acl_rule      : std_logic_vector(168 downto 0) := (others => '0');

    -- Outputs
    signal finish : std_logic;
    signal accept : std_logic;
    signal drop   : std_logic;

    -- Clock period definitions
    constant clk_period : time := 1 ns;

    -- Test Case Data
    -- This rule permits TCP traffic from 192.168.1.10 to any host in the 10.0.0.0/24 subnet,
    -- with a source port of 1234 and a destination port of 80.
    constant PERMIT_RULE : std_logic_vector(168 downto 0) :=
        "1" &                                                       -- permit
        "11000000101010000000000100001010" &                         -- source_allowed_ip (192.168.1.10)
        "11111111111111111111111111111111" &                         -- source_mask (255.255.255.255)
        "00001010000000000000000000000000" &                         -- dest_allowed_ip (10.0.0.0)
        "11111111111111111111111100000000" &                         -- dest_mask (255.255.255.0)
        "00000110" &                                                -- allowed_protocol (6 - TCP)
        "0000010011010010" &                                        -- src_allowed_port (1234)
        "0000000001010000";                                         -- dest_allowed_port (80)

    -- A corresponding rule that denies the same traffic pattern.
    constant DENY_RULE : std_logic_vector(168 downto 0) :=
        "0" &                                                       -- deny
        "11000000101010000000000100001010" &                         -- source_allowed_ip (192.168.1.10)
        "11111111111111111111111111111111" &                         -- source_mask (255.255.255.255)
        "00001010000000000000000000000000" &                         -- dest_allowed_ip (10.0.0.0)
        "11111111111111111111111100000000" &                         -- dest_mask (255.255.255.0)
        "00000110" &                                                -- allowed_protocol (6 - TCP)
        "0000010011010010" &                                        -- src_allowed_port (1234)
        "0000000001010000";                                         -- dest_allowed_port (80)

    -- A packet that should match the PERMIT_RULE and be accepted.
    constant MATCHING_PACKET : std_logic_vector(103 downto 0) :=
        x"06" &         -- Protocol: 6 (TCP)
        x"C0A8010A" &   -- Source IP: 192.168.1.10
        x"04D2" &       -- Source Port: 1234
        x"0A000063" &   -- Dest IP: 10.0.0.99
        x"0050";        -- Dest Port: 80

    -- A packet with the wrong protocol (UDP instead of TCP).
    constant WRONG_PROTOCOL_PACKET : std_logic_vector(103 downto 0) :=
        x"11" &         -- Protocol: 17 (UDP)
        x"C0A8010A" &   -- Source IP: 192.168.1.10
        x"04D2" &       -- Source Port: 1234
        x"0A000063" &   -- Dest IP: 10.0.0.99
        x"0050";        -- Dest Port: 80

    -- A packet with the wrong source IP.
    constant WRONG_SOURCE_IP_PACKET : std_logic_vector(103 downto 0) :=
        x"06" &         -- Protocol: 6 (TCP)
        x"C0A8010B" &   -- Source IP: 192.168.1.11
        x"04D2" &       -- Source Port: 1234
        x"0A000063" &   -- Dest IP: 10.0.0.99
        x"0050";        -- Dest Port: 80

begin

    -- Instantiate the Unit Under Test (UUT)
    uut: top_level
        port map (
            clk           => clk,
            rst           => rst,
            source_packet => source_packet,
            acl_rule      => acl_rule,
            finish        => finish,
            accept        => accept,
            drop          => drop
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
        -- ####################  RESET ####################
        report "Starting Testbench...";
        rst <= '1';
        wait for 2 * clk_period;
        rst <= '0';
        wait for clk_period;

        -- #################### TEST CASE 2: WRONG PROTOCOL, PERMIT RULE ####################
        report "TEST 2: Applying a packet with wrong protocol. EXPECT: DROP";
        acl_rule      <= PERMIT_RULE;
        source_packet <= WRONG_PROTOCOL_PACKET;
        wait until rising_edge(finish);
        wait for clk_period;

        assert (accept = '0' and drop = '1')
            report "TEST 2 FAILED: Packet was not dropped." severity error;
        if (accept = '0' and drop = '1') then
            report "TEST 2 PASSED: Packet was correctly DROPPED.";
        end if;
     
        -- #################### TEST CASE 1: MATCHING PACKET, PERMIT RULE ####################
        report "TEST 1: Applying a matching packet with a PERMIT rule. EXPECT: ACCEPT";
        acl_rule      <= PERMIT_RULE;
        source_packet <= MATCHING_PACKET;
        wait until rising_edge(finish);
        wait for clk_period; -- Allow signals to settle before checking

        assert (accept = '1' and drop = '0')
            report "TEST 1 FAILED: Packet was not accepted." severity error;
        if (accept = '1' and drop = '0') then
            report "TEST 1 PASSED: Packet was correctly ACCEPTED.";
        end if;

        -- #################### TEST CASE 3: WRONG SOURCE IP, PERMIT RULE ####################
        report "TEST 3: Applying a packet with wrong source IP. EXPECT: DROP";
        acl_rule      <= PERMIT_RULE;
        source_packet <= WRONG_SOURCE_IP_PACKET;
        wait until rising_edge(finish);
        wait for clk_period;

        assert (accept = '0' and drop = '1')
            report "TEST 3 FAILED: Packet was not dropped." severity error;
        if (accept = '0' and drop = '1') then
            report "TEST 3 PASSED: Packet was correctly DROPPED.";
        end if;

        -- #################### TEST CASE 4: MATCHING PACKET, DENY RULE ####################
        report "TEST 4: Applying a matching packet with a DENY rule. EXPECT: DROP";
        acl_rule      <= DENY_RULE;
        source_packet <= MATCHING_PACKET;
        wait until rising_edge(finish);
        wait for clk_period;

        assert (accept = '0' and drop = '1')
            report "TEST 4 FAILED: Packet was not dropped." severity error;
        if (accept = '0' and drop = '1') then
            report "TEST 4 PASSED: Packet was correctly DROPPED.";
        end if;

        report "All test cases finished." severity note;
        wait; -- will wait forever
    end process;

end behavior;
