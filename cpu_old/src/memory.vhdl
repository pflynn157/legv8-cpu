library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity Memory is
    port (
        clk     : in std_logic;
        I_write : in std_logic;
        address : in std_logic_vector(31 downto 0);
        I_data  : in std_logic_vector(31 downto 0);
        O_data  : out std_logic_vector(31 downto 0)
    );
end Memory;

architecture Behavior of Memory is
    type mem_block is array (0 to 1024) of std_logic_vector(31 downto 0);
    signal mem : mem_block;
begin
    process (clk, I_write, address, I_data)
    begin
        O_data <= mem(to_integer(unsigned(address)));
        
        if I_write = '1' then
            mem(to_integer(unsigned(address))) <= I_data;
        end if;
    end process;
end Behavior;
