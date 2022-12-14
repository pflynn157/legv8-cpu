library IEEE;
use IEEE.std_logic_1164.all;

entity cpu_tb is
end cpu_tb;

architecture Behavior of cpu_tb is
    constant INSTR_MEM_SIZE : integer := 2048 - 1;

    --constant INSTR_COUNT : integer := 64;
    --constant MEM_SIZE : integer := (32 * INSTR_COUNT) - 1;

    -- The CPU
    component CPU is
        port (
            clk    : in std_logic;
            input  : in std_logic_vector(INSTR_MEM_SIZE downto 0)
        );
    end component;
    
    -- Instruction constants
    constant ADD : std_logic_vector := "10001011000";
    constant SUB : std_logic_vector := "11001011000";
    constant R_AND : std_logic_vector := "10001010000";
    constant R_OR : std_logic_vector := "10101010000";
    constant R_LSL : std_logic_vector := "11010011011";
    constant R_LSR : std_logic_vector := "11010011010";
    constant MOV : std_logic_vector := "1101001010000000000000";
    constant NOP : std_logic_vector := "1101001111100000000000";
    constant ADDI : std_logic_vector := "1001000100";
    constant SUBI : std_logic_vector := "1101000100";
    constant STUR : std_logic_vector := "11111000000";
    constant LDUR : std_logic_vector := "11111000010";
    constant CMP : std_logic_vector := "10110101";
    constant B : std_logic_vector := "000101";
    constant BC : std_logic_vector := "010101";    -- Conditional branch of any kind
    
    -- For the conditional branches
    constant BEQ : std_logic_vector := "0000";
    constant BNE : std_logic_vector := "0001";
    constant BGT : std_logic_vector := "1100";
    constant BGE : std_logic_vector := "1010";
    constant BLT : std_logic_vector := "1011";
    constant BLE : std_logic_vector := "1101";
    
    constant CODE1_SIZE : integer := 32 * 21 - 1;
    signal code1 : std_logic_vector(CODE1_SIZE downto 0) :=
          LDUR & "000000000" & "00" & "00001" & "00110" &         -- LDUR X6, [X1, #0]    == MEM(0) = 10 (X6 == 10)
          ADDI & "000000000010" & "00101" & "00101" &             -- ADDI X5, X5, #2  == 12
          NOP & "0000000000" &                                    -- NOP
          LDUR & "000000011" & "00" & "11111" & "00101" &         -- LDUR X5, [XZR, #3]    == MEM(3) = 10 (X5 == 10)
          STUR & "000000011" & "00" & "11111" & "00010" &         -- STUR X2, [XZR, #3]    == MEM(3) = 10
          STUR & "000000000" & "00" & "00001" & "00010" &         -- STUR X2, [X1, #0]     == MEM(0) = 10
          SUBI & "000000000101" & "00010" & "00100" &             -- SUBI X4, X2, #5  == 5
          ADDI & "000000000101" & "00010" & "00100" &             -- ADDI X4, X2, #5  == 15
          R_LSR & "00000" & "000010" & "00000" & "00100" &        -- LSR X4, X0, #2 == 1
          R_LSL & "00000" & "000010" & "00000" & "00100" &        -- LSL X4, X0, #2 == 16
          R_OR & "00000" & "000000" & "00001" & "00100" &         --  OR X4, X0, X1 == 6
          R_AND & "00000" & "000000" & "00001" & "00100" &        -- AND X4, X0, X1 == 0        
          SUB & "00010" & "000010" & "00001" & "00100" &          -- SUB X4, X2, X1 == 8
          ADD & "00000" & "000000" & "00001" & "00100" &          -- ADD X4, X0, X1 == 6
          ADDI & "000000001010" & "11111" & "00011" &             -- ADDI X3, XZR, #10
          ADDI & "000000001010" & "00010" & "00010" &             -- ADDI X2, X2, #10 
          ADDI & "000000000010" & "00001" & "00001" &             -- ADDI X1, X1, #2 
          ADDI & "000000000100" & "00000" & "00000" &             -- ADDI X0, X0, #4 
          MOV & "11111" & "00010" &                               -- MOV X2, XZR
          MOV & "11111" & "00001" &                               -- MOV X1, XZR
          MOV & "11111" & "00000"                                 -- MOV X0, XZR 
    ;
    
    constant CODE2_SIZE : integer := 32 * 11 - 1;
    signal code2 : std_logic_vector(CODE2_SIZE downto 0) :=
          B & "1111111111111111111111" & "0111"    &              -- [0] B <-9> -> (4 * 32)
          
          ADDI & "000000000111" & "00100" & "00100" &             -- [] ADDI X4, X4, #7 (should NOT happen)
          ADDI & "000000000100" & "00011" & "00011" &             -- [128] ADDI X3, X3, #4 (should happen)
          
          ADDI & "000000000101" & "00010" & "00010" &             -- [96] ADDI X2, X2, #5 (should NOT happen)
          ADDI & "000000000101" & "00001" & "00001" &             -- [64] ADDI X1, X1, #5 (should NOT happen)
          ADDI & "000000000010" & "00000" & "00000" &             -- [32] ADDI X0, X0, #2 (should NOT happen)
          
          B & "0000000000000000000000" & "0100"    &              -- [0] B <4> -> (4 * 32)
          
          ADDI & "000000000001" & "00010" & "00010" &             -- [96] ADDI X2, X2, #1 (should NOT happen)
          ADDI & "000000000001" & "00001" & "00001" &             -- [64] ADDI X1, X1, #1 (should NOT happen)
          ADDI & "000000000001" & "00000" & "00000" &             -- [32] ADDI X0, X0, #3 (should NOT happen)
          
          B & "0000000000000000000000" & "0100"                   -- [0] B <4> -> (4 * 32)
    ;
    
    constant CODE3_SIZE : integer := 32 * 10 - 1;
    signal code3 : std_logic_vector(CODE3_SIZE downto 0) :=
        CMP & "00" & "000000000000" & "00000" & "00001" &       -- CMP X0, X1          (FLAGS = 100) 10 - 7 = 3
        NOP & "0000000000" &                                    -- NOP
        ADDI & "000000001010" & "11111" & "00000" &             -- ADDI X0, XZR, #10
        CMP & "00" & "000000000000" & "00000" & "00001" &       -- CMP X0, X1          (FLAGS = 010) 3 - 7 = -4
        NOP & "0000000000" &                                    -- NOP
        ADDI & "000000000111" & "11111" & "00001" &             -- ADDI X1, XZR, #7
        CMP & "00" & "000000000000" & "00000" & "00001" &       -- CMP X0, X1          (FLAGS = 001) 3-3 = 0
        NOP & "0000000000" &                                    -- NOP
        ADDI & "000000000011" & "11111" & "00001" &             -- ADDI X1, XZR, #3
        ADDI & "000000000011" & "11111" & "00000"               -- ADDI X0, XZR, #3
    ;
    
    constant CODE4_SIZE : integer := 32 * 58 - 1;
    signal code4 : std_logic_vector(CODE4_SIZE downto 0) :=
        ADDI & "000000000010" & "00010" & "00010" &             -- ADDI X2, X2, #2 (should happen)              X2 = 13 (D)
        ADDI & "000000000011" & "11111" & "00100" &             -- ADDI X4, XZR, #3 (should NOT happen)
        ADDI & "000000000011" & "11111" & "00101" &             -- ADDI X5, XZR, #3 (should NOT happen)
        BC & "0000000000000000000011" & BGT &                   -- BGE 3  (10 - 3 = 7) -> BRANCH 
        NOP & "0000000000" &                                    -- NOP
        NOP & "0000000000" &                                    -- NOP
        CMP & "00" & "000000000000" & "00000" & "00001" &       -- CMP X0, X1          (FLAGS = 100) 10-3 = 7
        NOP & "0000000000" &                                    -- NOP
        ADDI & "000000001010" & "11111" & "00000" &             -- ADDI X0, XZR, #10
        ADDI & "000000000010" & "00010" & "00010" &             -- ADDI X2, X2, #2 (should happen)              X2 = 11 (B)
        ADDI & "000000000011" & "11111" & "00100" &             -- ADDI X4, XZR, #3 (should NOT happen)
        ADDI & "000000000011" & "11111" & "00101" &             -- ADDI X5, XZR, #3 (should NOT happen)
        BC & "0000000000000000000011" & BGE &                   -- BGE 3  (1 - 3 = -2) -> BRANCH 
        NOP & "0000000000" &                                    -- NOP
        NOP & "0000000000" &                                    -- NOP
        CMP & "00" & "000000000000" & "00000" & "00001" &       -- CMP X0, X1          (FLAGS = 001) 3-3 = 0
        ADDI & "000000000010" & "00010" & "00010" &             -- ADDI X2, X2, #2 (should happen)              X2 = 9
        ADDI & "000000000011" & "11111" & "00100" &             -- ADDI X4, XZR, #3 (should NOT happen)
        ADDI & "000000000011" & "11111" & "00101" &             -- ADDI X5, XZR, #3 (should NOT happen)
        BC & "0000000000000000000011" & BLE &                   -- BLE 3  (3 - 3 = 0) -> BRANCH 
        NOP & "0000000000" &                                    -- NOP
        NOP & "0000000000" &                                    -- NOP
        CMP & "00" & "000000000000" & "00000" & "00001" &       -- CMP X0, X1          (FLAGS = 001) 3-3 = 0
        NOP & "0000000000" &                                    -- NOP
        ADDI & "000000000011" & "11111" & "00000" &             -- ADDI X0, XZR, #3
        ADDI & "000000000010" & "00010" & "00010" &             -- ADDI X2, X2, #2 (should happen)              X2 = 7
        ADDI & "000000000011" & "11111" & "00100" &             -- ADDI X4, XZR, #3 (should NOT happen)
        ADDI & "000000000011" & "11111" & "00101" &             -- ADDI X5, XZR, #3 (should NOT happen)
        BC & "0000000000000000000011" & BLE &                   -- BLE 3  (1 - 3 = -2) -> BRANCH 
        NOP & "0000000000" &                                    -- NOP
        NOP & "0000000000" &                                    -- NOP
        CMP & "00" & "000000000000" & "00000" & "00001" &       -- CMP X0, X1          (FLAGS = 001) 1-3 = -2
        ADDI & "000000000010" & "00010" & "00010" &             -- ADDI X2, X2, #2 (should happen)               X2 = 5
        ADDI & "000000000011" & "11111" & "00100" &             -- ADDI X4, XZR, #3 (should NOT happen)
        ADDI & "000000000011" & "11111" & "00101" &             -- ADDI X5, XZR, #3 (should NOT happen)
        BC & "0000000000000000000011" & BLT &                   -- BLT 3
        NOP & "0000000000" &                                    -- NOP
        NOP & "0000000000" &                                    -- NOP
        CMP & "00" & "000000000000" & "00000" & "00001" &       -- CMP X0, X1          (FLAGS = 001) 1-3 = -2
        ADDI & "000000000010" & "00010" & "00010" &             -- ADDI X2, X2, #2 (should happen)               X2 = 3
        ADDI & "000000000010" & "11111" & "00100" &             -- ADDI X4, XZR, #2 (should NOT happen)
        ADDI & "000000000010" & "11111" & "00101" &             -- ADDI X5, XZR, #2 (should NOT happen)
        BC & "0000000000000000000011" & BNE &                   -- BNE 3
        NOP & "0000000000" &                                    -- NOP
        NOP & "0000000000" &                                    -- NOP
        CMP & "00" & "000000000000" & "00000" & "00001" &       -- CMP X0, X1          (FLAGS = 001) 1-3 = -2
        NOP & "0000000000" &                                    -- NOP
        ADDI & "000000000001" & "11111" & "00000" &             -- ADDI X0, XZR, #1
        ADDI & "000000000001" & "00010" & "00010" &             -- ADDI X2, X2, #1 (should happen)                X2 = 1
        ADDI & "000000000001" & "11111" & "00100" &             -- ADDI X4, XZR, #1 (should NOT happen)
        ADDI & "000000000001" & "11111" & "00101" &             -- ADDI X5, XZR, #1 (should NOT happen)
        BC & "0000000000000000000011" & BEQ &                   -- BEQ 3
        NOP & "0000000000" &                                    -- NOP
        NOP & "0000000000" &                                    -- NOP
        CMP & "00" & "000000000000" & "00000" & "00001" &       -- CMP X0, X1          (FLAGS = 001) 3-3 = 0
        NOP & "0000000000" &                                    -- NOP
        ADDI & "000000000011" & "11111" & "00001" &             -- ADDI X1, XZR, #3
        ADDI & "000000000011" & "11111" & "00000"               -- ADDI X0, XZR, #3
    ;
    
    -- Equivalent C code
    -- int n = 0;
    -- for (int i = 0; i<10; i++) {
    --    n += i;
    -- }
    constant CODE5_SIZE : integer := 32 * 18 - 1;
    signal code5 : std_logic_vector(CODE5_SIZE downto 0) :=
        NOP & "0000000000" &                                    -- NOP
        NOP & "0000000000" &                                    -- NOP
        ADDI & "000000000000" & "11111" & "00001" &             -- ADDI X1, XZR, #0
        B & "1111111111111111111111" & "0111"     &             -- B -9
        ADDI & "000000000001" & "00001" & "00001" &             -- ADDI X1 X1, #1
        STUR & "000000000" & "00" & "11111" & "00011" &         -- STUR X3, [XZR, #0]    == MEM(0)
        NOP & "0000000000" &                                    -- NOP
        ADD & "00000" & "000011" & "00001" & "00011" &          -- ADD X3, X3, X1
        LDUR & "000000000" & "00" & "11111" & "00011" &         -- LDUR X3, [XZR, #0]    == MEM(0)
        BC & "0000000000000000000111" & BGE &                   -- BGE 7
        NOP & "0000000000" &                                    -- NOP
        NOP & "0000000000" &                                    -- NOP 
        CMP & "00" & "000000000000" & "00001" & "00010" &       -- CMP X1, X2
        NOP & "0000000000" &                                    -- NOP
        ADDI & "000000001010" & "11111" & "00010" &             -- ADDI X2, XZR, #10
        MOV & "11111" & "00010" &                               -- MOV X1, XZR          X1 == i = 0
        STUR & "000000000" & "00" & "11111" & "00000" &         -- STUR X0, [XZR, #0]    == MEM(0) = 0
        MOV & "11111" & "00000"                                 -- MOV X0, XZR
    ;
    
    signal clk : std_logic := '0';
    signal input : std_logic_vector(INSTR_MEM_SIZE downto 0);
    
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
        --input(CODE1_SIZE downto 0) <= code1;
        --input(CODE2_SIZE downto 0) <= code2;
        --input(CODE3_SIZE downto 0) <= code3;
        --input(CODE4_SIZE downto 0) <= code4;
        input(CODE5_SIZE downto 0) <= code5;
        wait;
    end process;
end Behavior;
