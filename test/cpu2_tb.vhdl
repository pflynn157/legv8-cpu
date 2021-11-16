library IEEE;
use IEEE.std_logic_1164.all;

entity cpu2_tb is
end cpu2_tb;

architecture Behavior of cpu2_tb is
    constant INSTR_COUNT : integer := 12;
    constant MEM_SIZE : integer := (32 * INSTR_COUNT) - 1;

    -- The CPU
    component CPU2 is
        port (
            clk    : in std_logic;
            input  : in std_logic_vector(MEM_SIZE downto 0)
        );
    end component;
    
    signal clk : std_logic := '0';
    signal input : std_logic_vector(MEM_SIZE downto 0) :=
          "11010011010" & "00000" & "000010" & "00000" & "00100" &    -- LSR X4, X0, #2 == 1
          "11010011011" & "00000" & "000010" & "00000" & "00100" &    -- LSL X4, X0, #2 == 16
          "10101010000" & "00000" & "000000" & "00001" & "00100" &    --  OR X4, X0, X1 == 6
          "10001010000" & "00000" & "000000" & "00001" & "00100" &    -- AND X4, X0, X1 == 0        
          "11001011000" & "00010" & "000010" & "00001" & "00100" &    -- SUB X4, X2, X1 == 8
          "10001011000" & "00000" & "000000" & "00001" & "00100" &    -- ADD X4, X0, X1 == 6
          "1001000100" & "000000001010" & "00010" & "00010" &   -- ADDI X2, X2, #10 
          "1001000100" & "000000000010" & "00001" & "00001" &   -- ADDI X1, X1, #2 
          "1001000100" & "000000000100" & "00000" & "00000" &   -- ADDI X0, X0, #4 
          "1101001010000000000000" & "11111" & "00010" &        -- MOV X2, XZR
          "1101001010000000000000" & "11111" & "00001" &        -- MOV X1, XZR
          "1101001010000000000000" & "11111" & "00000"          -- MOV X0, XZR
          
    ;
    
    -- Our clock period definition
    constant clk_period : time := 10 ns;
begin
    uut : CPU2 port map (
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
        wait;
    end process;
end Behavior;
