library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity acl_system is
    Port ( 
        clk             : in STD_LOGIC;
        rst             : in STD_LOGIC;
        source_ip       : in STD_LOGIC_VECTOR(31 downto 0);

        accept          : out STD_LOGIC;
        drop            : out STD_LOGIC
    );    
end acl_system;