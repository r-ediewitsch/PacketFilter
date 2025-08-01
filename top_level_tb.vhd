library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity top_level_tb is
end top_level_tb;

architecture behavior of top_level_tb is
    signal clk             : std_logic := '0';
    signal rst             : std_logic := '0';
    signal source_packet   : std_logic_vector(103 downto 0);
    signal acl_rule        : std_logic_vector(168 downto 0);
    signal finish          : std_logic;
    signal accept          : std_logic;
    signal drop            : std_logic;

    constant clk_period : time := 1 ns;

    component top_level
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

    -- Dedicated wait + report procedure
    procedure wait_and_check(signal clk : in std_logic;
                             signal accept : in std_logic;
                             signal drop : in std_logic;
                             expected_accept : std_logic;
                             expected_drop   : std_logic;
                             message         : string) is
    begin
        wait until finish = '1';
        if accept = expected_accept and drop = expected_drop then
            report message & ": PASS";
        else
            report message & ": FAIL. Got accept = " & std_logic'image(accept) &
                   ", drop = " & std_logic'image(drop)
                   severity error;
        end if;
    end procedure;

begin
    uut: top_level
        port map (
            clk => clk,
            rst => rst,
            source_packet => source_packet,
            acl_rule => acl_rule,
            finish => finish,
            accept => accept,
            drop => drop
        );

    clk_process : process
    begin
        while true loop
            clk <= '0';
            wait for clk_period / 2;
            clk <= '1';
            wait for clk_period / 2;
        end loop;
    end process;

    stim_proc : process
    begin
        -- Reset pulse
        rst <= '1';
        wait for 30 ns;
        rst <= '0';

        -- === TEST 1: All match ===
        acl_rule <=
            '1' &                          -- permit
            x"C0A8010A" &                  -- src IP = 192.168.1.10
            x"FFFFFF00" &                  -- src mask
            x"0A000001" &                  -- dst IP = 10.0.0.1
            x"FFFFFFFF" &                  -- dst mask
            x"06" &                        -- TCP
            x"04D2" &                      -- src port = 1234
            x"0050";                       -- dst port = 80

        source_packet <=
            x"06" &                        -- TCP
            x"C0A80137" &                  -- src IP = 192.168.1.55
            x"04D2" &                      -- src port = 1234
            x"0A000001" &                  -- dst IP
            x"0050";                       -- dst port

        wait_and_check(clk, accept, drop, '1', '0', "Test 1");

        -- === TEST 2: Source IP mismatch ===
        source_packet <=
            x"06" &
            x"C0A80201" &                  -- src IP outside subnet
            x"04D2" &
            x"0A000001" &
            x"0050";

        wait_and_check(clk, accept, drop, '0', '1', "Test 2");

        -- === TEST 3: Destination port mismatch ===
        source_packet <=
            x"06" &
            x"C0A80111" &
            x"04D2" &
            x"0A000001" &
            x"1234";                       -- Wrong dst port

        wait_and_check(clk, accept, drop, '0', '1', "Test 3");

        -- === TEST 4: Protocol mismatch ===
        source_packet <=
            x"11" &                        -- UDP instead of TCP
            x"C0A80133" &
            x"04D2" &
            x"0A000001" &
            x"0050";

        wait_and_check(clk, accept, drop, '0', '1', "Test 4");

        wait;
    end process;
end behavior;
