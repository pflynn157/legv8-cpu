library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity mem_tb is
end mem_tb;

architecture Behavior of mem_tb is

    -- Declare the memory component
    component Memory is
        port (
            clk      : in std_logic;
            I_write  : in std_logic;
            data_len : in std_logic_vector(1 downto 0);
            address  : in std_logic_vector(31 downto 0);
            I_data   : in std_logic_vector(31 downto 0);
            O_data   : out std_logic_vector(31 downto 0)
        );
    end component;
    
    -- Declare the signals we need
    signal I_write : std_logic := '0';
    signal data_len : std_logic_vector(1 downto 0) := "00";
    signal address, I_data, O_data : std_logic_vector(31 downto 0) := X"00000000";
    
    -- The clock
    signal clk : std_logic := '0';
    constant clk_period : time := 10 ns;
begin

    -- Setup the component
    uut : Memory port map(
        clk => clk,
        I_write => I_write,
        data_len => data_len,
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
    
    -- Test the process
    sim_proc : process
    begin
        I_write <= '1';
        address <= X"00000000";
        I_data <= X"0000000A";
        wait for clk_period;
        
        address <= X"00000010";
        I_data <= X"4321DCBA";
        data_len <= "01";
        wait for clk_period;
        
        address <= X"00000013";
        data_len <= "10";
        wait for clk_period;
        
        address <= X"00000051";
        data_len <= "11";
        wait for clk_period;
        
        I_write <= '0';
        address <= X"00000010";
        data_len <= "01";
        wait for clk_period;
    
        wait;
    end process;
    
end Behavior;
