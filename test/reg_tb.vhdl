library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity reg_tb is
end reg_tb;

architecture Behavior of reg_tb is
    
    -- Declare component
    component registers is
        port (
            sel_A   : in std_logic_vector(4 downto 0);
            sel_B   : in std_logic_vector(4 downto 0);
            sel_D   : in std_logic_vector(4 downto 0);
            I_dataD : in std_logic_vector(31 downto 0);
            I_enD   : in std_logic;
            O_dataA : out std_logic_vector(31 downto 0);
            O_dataB : out std_logic_vector(31 downto 0)
        );
    end component;
    
    -- Our signals
    -- The clock for our CPU
    signal clk : std_logic := '0';
    
    -- Signals to the register
    signal I_enD : std_logic := '0';
    signal I_dataD, O_dataA, O_dataB : std_logic_vector(31 downto 0) := X"00000000";
    signal sel_A, sel_B, sel_D : std_logic_vector(4 downto 0) := "00000";
    
    -- Our clock period time
    constant clk_period : time := 10 ns;
begin

    -- Init the UUT
    uut : registers port map(
        sel_A => sel_A,
        sel_B => sel_B,
        sel_D => sel_D,
        I_dataD => I_dataD,
        I_enD => I_enD,
        O_dataA => O_dataA,
        O_dataB => O_dataB
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
        -- Hold and reset
        wait for 100 ns;
        
        -- Now test
        
        -- Set the following registers:
        ---- X0 -> AB11
        ---- X1 -> AB22
        ---- X2 -> AB33
        ---- X10 -> BB11
        ---- X11 -> BB22
        ---- X20 -> BB33
        sel_D <= std_logic_vector(to_unsigned(0, 5));
        I_dataD <= X"0000AB11";
        I_enD <= '1';
        wait for clk_period;
        
        sel_D <= std_logic_vector(to_unsigned(1, 5));
        I_dataD <= X"0000AB22";
        wait for clk_period;
        
        sel_D <= std_logic_vector(to_unsigned(2, 5));
        I_dataD <= X"0000AB33";
        wait for clk_period;
        
        sel_D <= std_logic_vector(to_unsigned(10, 5));
        I_dataD <= X"0000BB11";
        wait for clk_period;
        
        sel_D <= std_logic_vector(to_unsigned(11, 5));
        I_dataD <= X"0000BB22";
        wait for clk_period;
        
        sel_D <= std_logic_vector(to_unsigned(20, 5));
        I_dataD <= X"0000BB33";
        wait for clk_period;
        
        -- Now, set src1 = 10, src2 = 1
        -- Result should be (BB11, AB22)
        sel_A <= std_logic_vector(to_unsigned(10, 5));
        sel_B <= std_logic_vector(to_unsigned(1, 5));
        I_enD <= '0';
        wait for clk_period;
        assert O_dataA = X"0000BB11" report "Test 1 failed-> x10 wrong." severity error;
        assert O_dataB = X"0000AB22" report "Test 1 failed->  x1 wrong." severity error;
        
        -- Now do the same thing to src1 = 0, src2 = 20
        -- Result should be (AB11, BB33)
        sel_A <= std_logic_vector(to_unsigned(0, 5));
        sel_B <= std_logic_vector(to_unsigned(20, 5));
        wait for clk_period;
        assert O_dataA = X"0000AB11" report "Test 2 failed-> x0 wrong." severity error;
        assert O_dataB = X"0000BB33" report "Test 2 failed-> x20 wrong." severity error;
        
        -- Now set src1 = 0, src2 = 1, dest = 2
        -- Write X"12345678" to the destination
        -- Read result should be (AB11, AB22)
        sel_A <= std_logic_vector(to_unsigned(0, 5));
        sel_B <= std_logic_vector(to_unsigned(1, 5));
        sel_D <= std_logic_vector(to_unsigned(2, 5));
        I_enD <= '1';
        I_dataD <= X"12345678";
        wait for clk_period;
        assert O_dataA = X"0000AB11" report "Test 3 failed-> x0 wrong." severity error;
        assert O_dataB = X"0000AB22" report "Test 3 failed-> x1 wrong." severity error;
        
        -- Now set src1 = 2
        -- Check the result
        sel_A <= std_logic_vector(to_unsigned(2, 5));
        I_enD <= '1';
        wait for clk_period;
        assert O_dataA = X"12345678" report "Write test failed-> x2 wrong." severity error;
        
        wait;
    end process;
end Behavior;
