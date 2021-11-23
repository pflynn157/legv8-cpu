library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity instr_memory_tb is
end instr_memory_tb;

architecture Behavior of instr_memory_tb is
    
    -- Declare the instruction memory component
    component Instr_Memory is
        port (
            clk     : in std_logic;
            I_write : in std_logic;
            address : in std_logic_vector(31 downto 0);
            I_data  : in std_logic_vector(31 downto 0);
            O_data  : out std_logic_vector(31 downto 0)
        );
    end component;
    
    -- The clock
    signal clk : std_logic := '0';
    constant clk_period : time := 10 ns;
    
    -- The memory signals
    signal I_write : std_logic := '0';
    signal address, I_data, O_data : std_logic_vector(31 downto 0);
begin
    
    -- Setup the memory controller
    uut : Instr_Memory port map (
        clk => clk,
        I_write => I_write,
        address => address,
        I_data => I_data,
        O_data => O_data
    );
    
    -- Define the clock process
    I_clk_process : process
    begin
        clk <= '0';
        wait for clk_period/2;
        clk <= '1';
        wait for clk_period/2;
    end process;
    
    sim_process : process
    begin
        I_write <= '1';
        address <= X"00000001";
        I_data <= X"000000AB";
        wait for clk_period;
        
        address <= X"00000002";
        I_data <= X"0000ABCD";
        wait for clk_period;
        
        address <= X"00000004";
        I_data <= X"12345ABC";
        wait for clk_period;
        
        I_write <= '0';
        address <= X"00000002";
        wait for clk_period;
    
        wait;
    end process;
    
end Behavior;