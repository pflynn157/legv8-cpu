library IEEE;
use IEEE.std_logic_1164.all;

entity cpu_tb is
end cpu_tb;

architecture Behavior of cpu_tb is
    constant INSTR_COUNT : integer := 12;
    constant MEM_SIZE : integer := (32 * INSTR_COUNT) - 1;

    -- The CPU
    component CPU is
        port (
            clk    : in std_logic;
            input  : in std_logic_vector(MEM_SIZE downto 0)
        );
    end component;
    
    signal clk : std_logic := '0';
    signal input : std_logic_vector(MEM_SIZE downto 0) :=
        --"10010001000000000010100100101001" &        -- ADDI X9, X9, #10
        --"10001011000010010000001010101001"          -- ADD X9, X21, X9

          "11010011010" & "00000" & "000010" & "00000" & "00101" &    -- LSR X5, X0, #2 == 1
          "11010011011" & "00000" & "000010" & "00000" & "00101" &    -- LSL X5, X0, #2 == 16
          "10101010000" & "00000" & "000000" & "00001" & "00101" &    --  OR X5, X0, X1 == 6
          "10001010000" & "00000" & "000000" & "00001" & "00100" &    -- AND X4, X0, X1 == 0        
          "11001011000" & "00011" & "000000" & "00001" & "00101" &    -- SUB X5, X3, X1
          "10001011000" & "00000" & "000000" & "00011" & "00100" &    -- ADD X4, X0, X3
          "1001000100" & "000000001010" & "00011" & "00011" &   -- ADDI X3, X3, #10 
          "1001000100" & "000000000010" & "00001" & "00001" &   -- ADDI X1, X1, #2 
          "1001000100" & "000000000100" & "00000" & "00000" &   -- ADDI X0, X0, #4 
          "1101001010000000000000" & "00010" & "11111" &        -- MOV X2, XZR
          "1101001010000000000000" & "00001" & "11111" &        -- MOV X1, XZR
          "1101001010000000000000" & "00000" & "11111"          -- MOV X0, XZR
          
    ;
    
    -- Our clock period definition
    constant clk_period : time := 10 ns;
begin
    uut : CPU port map (
        clk => clk,
        input => input
    );
    
    -- Create the clock
    I_clk_process: process
    begin
        clk <= '0';
        wait for clk_period / 2;
        clk <= '1';
        wait for clk_period / 2;
    end process;
    
    -- Run the CPU
    sim_proc: process
    begin
        --wait for 100 ns;
        
        -- LDUR X9, [X10, #240]
        --input <= "11111000010011110000000101001001";
        --wait for clk_period;
        
        -- ADDI X9, X9, #10
        --input <= "10010001000000000010100100101001";
        --wait for clk_period;
        
        -- ADD X9, X21, X9
        --input <= "10001011000010010000001010101001";
        --wait for clk_period;
        
        wait;
    end process;
end Behavior;