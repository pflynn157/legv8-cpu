library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity cpu_tb is
end cpu_tb;

architecture Behavior of cpu_tb is

    -- Declare the CPU component
    component CPU is
        port (
            clk           : in std_logic;
            Reset         : in std_logic;
            I_instr       : in std_logic_vector(31 downto 0);
            O_PC          : out std_logic_vector(31 downto 0);
            O_Mem_Write   : out std_logic;
            O_Mem_Read    : out std_logic;
            O_Mem_Address : out std_logic_vector(31 downto 0);
            O_Mem_Data    : out std_logic_vector(31 downto 0);
            O_Data_Len    : out std_logic_vector(1 downto 0);
            I_Mem_Data    : in std_logic_vector(31 downto 0)
        );
    end component;
    
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
    
    -- The clock signals
    signal clk : std_logic := '0';
    constant clk_period : time := 10 ns;
    
    -- The other signals
    signal Reset : std_logic := '0';
    signal I_instr, O_PC, O_Mem_Address, O_Mem_Data, I_Mem_Data : std_logic_vector(31 downto 0) := X"00000000";
    signal O_Data_Len : std_logic_vector(1 downto 0) := "00";
    signal O_Mem_Write, O_Mem_Read : std_logic := '0';
    
    -- Memory signals
    signal I_write : std_logic := '0';
    signal data_len : std_logic_vector(1 downto 0) := "00";
    signal address, I_data, O_data : std_logic_vector(31 downto 0) := X"00000000";
    
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
    
    -- Our test program
    --constant SIZE : integer := 22;
    --type instr_memory is array (0 to (SIZE - 1)) of std_logic_vector(31 downto 0);
    --signal rom_memory : instr_memory := (
    --    MOV & "11111" & "00000",                               -- MOV X0, XZR  
    --    MOV & "11111" & "00001",                               -- MOV X1, XZR
    --    MOV & "11111" & "00010",                               -- MOV X2, XZR
    --    ADDI & "000000000100" & "00000" & "00000",             -- ADDI X0, X0, #4    (X0 == 4)
    --    ADDI & "000000000010" & "00001" & "00001",             -- ADDI X1, X1, #2    (X1 == 2)
    --    ADDI & "000000010000" & "00111" & "00111",             -- ADDI X7, X7, #2    (X7 == 16)
    --    ADDI & "000000001010" & "00010" & "00010",             -- ADDI X2, X2, #10   (X2 == 10)
    --    ADDI & "000000001011" & "11111" & "00011",             -- ADDI X3, XZR, #11   (X3 == 11)
    --    ADD & "00000" & "000000" & "00001" & "00100",          -- ADD X4, X0, X1      (X4 == 6)
    --    SUB & "00010" & "000010" & "00001" & "00100",          -- SUB X4, X2, X1       (X4 == 8)
    --    R_AND & "00000" & "000000" & "00001" & "00100",        -- AND X4, X0, X1       (X4 == 0)
    --    R_OR & "00000" & "000000" & "00001" & "00100",         --  OR X4, X0, X1       (X4 == 6)
    --    R_LSL & "00000" & "000010" & "00000" & "00100",        -- LSL X4, X0, #2       (X4 == 16)
    --    R_LSR & "00000" & "000010" & "00000" & "00100",        -- LSR X4, X0, #2       (X4 == 1)
    --    ADDI & "000000000101" & "00010" & "00100",             -- ADDI X4, X2, #5      (X4 == 15)
    --    SUBI & "000000000101" & "00010" & "00100",             -- SUBI X4, X2, #5      (X4 == 5)
    --    STUR & "000000000" & "00" & "00111" & "00011",         -- STUR X3, [X7, #0]     MEM(0x10) = 11
    --    STUR & "000000011" & "00" & "11111" & "00010",         -- STUR X2, [XZR, #3]    MEM(0x03) = 10
    --    LDUR & "000000000" & "00" & "00111" & "00110",         -- LDUR X6, [X7, #0]     (X6 == 11)
    --    LDUR & "000000011" & "00" & "11111" & "00101",         -- LDUR X5, [XZR, #3]     (X5 == 10)
    --    ADDI & "000000000010" & "00101" & "00101",             -- ADDI X5, X5, #2        (X5 == 12)
    --    NOP & "0000000000"
    --);
    
    --constant SIZE : integer := 14;
    --type instr_memory is array (0 to (SIZE - 1)) of std_logic_vector(31 downto 0);
    --signal rom_memory : instr_memory := (
    --    B & "0000000000000000000000" & "0100",                   -- [0] B <4> -> (4 * 32)
    --    ADDI & "000000000001" & "00000" & "00000",             -- [1] ADDI X0, X0, #1 (should NOT happen)
    --    ADDI & "000000000001" & "00001" & "00001",             -- [2] ADDI X1, X1, #1 (should NOT happen)
    --    ADDI & "000000000001" & "00010" & "00010",             -- [3] ADDI X2, X2, #1 (should NOT happen)
    --    ADDI & "000000000100" & "00011" & "00011",             -- [4] ADDI X3, X3, #4 (should happen)
    --    B & "0000000000000000000000" & "0100",                 -- [5] B <4> -> (4 * 32)
    --    ADDI & "000000000010" & "00000" & "00000",             -- [6] ADDI X0, X0, #2 (should NOT happen)
    --    ADDI & "000000000101" & "00001" & "00001",             -- [7] ADDI X1, X1, #5 (should NOT happen)
    --    ADDI & "000000000101" & "00010" & "00010",             -- [8] ADDI X2, X2, #5 (should NOT happen)
    --    ADDI & "000000000100" & "00011" & "00011",             -- [9] ADDI X3, X3, #4 (should happen)
    --    ADDI & "000000000111" & "00100" & "00100",             -- [10] ADDI X4, X4, #7 (should happen)
    --    B & "1111111111111111111111" & "0101",                 -- [11] B <-9> -> (4 * 32)
    --    NOP & "0000000000",
    --    NOP & "0000000000"
    --);
    
    --constant CODE3_SIZE : integer := 32 * 10 - 1;
    --signal code3 : std_logic_vector(CODE3_SIZE downto 0) :=
    --    CMP & "00" & "000000000000" & "00000" & "00001" &       -- CMP X0, X1          (FLAGS = 100) 10 - 7 = 3
    --    NOP & "0000000000" &                                    -- NOP
    --    ADDI & "000000001010" & "11111" & "00000" &             -- ADDI X0, XZR, #10
    --    CMP & "00" & "000000000000" & "00000" & "00001" &       -- CMP X0, X1          (FLAGS = 010) 3 - 7 = -4
    --    NOP & "0000000000" &                                    -- NOP
    --    ADDI & "000000000111" & "11111" & "00001" &             -- ADDI X1, XZR, #7
    --    CMP & "00" & "000000000000" & "00000" & "00001" &       -- CMP X0, X1          (FLAGS = 001) 3-3 = 0
    --    NOP & "0000000000" &                                    -- NOP
    --    ADDI & "000000000011" & "11111" & "00001" &             -- ADDI X1, XZR, #3
      ---  ADDI & "000000000011" & "11111" & "00000"               -- ADDI X0, XZR, #3
    --;
    
    --constant SIZE : integer := 5;
    --type instr_memory is array (0 to (SIZE - 1)) of std_logic_vector(31 downto 0);
    --signal rom_memory : instr_memory := (
    --    ADDI & "000000000011" & "11111" & "00000",               -- ADDI X0, XZR, #3
    --    ADDI & "000000000011" & "11111" & "00001",               -- ADDI X1, XZR, #3
    --    --NOP & "0000000000",
    --    CMP & "00" & "000000000000" & "00000" & "00001",       -- CMP X0, X1          (FLAGS = 001) 3-3 = 0
    --    ADDI & "000000000111" & "11111" & "00001",               -- ADDI X1, XZR, #7
    --    ADDI & "000000000111" & "11111" & "00000"               -- ADDI X0, XZR, #7
    --);
    
    constant SIZE : integer := 40;
    type instr_memory is array (0 to (SIZE - 1)) of std_logic_vector(31 downto 0);
    signal rom_memory : instr_memory := (
        ADDI & "000000000011" & "11111" & "00000",               -- [0] ADDI X0, XZR, #3
        ADDI & "000000000011" & "11111" & "00001",               -- [1] ADDI X1, XZR, #3
        CMP & "00" & "000000000000" & "00000" & "00001",         -- [2] CMP X0, X1          (FLAGS = 001) 3-3 = 0
        BC & "0000000000000000000011" & BEQ,                     -- [3] BEQ 3
        ADDI & "000000000001" & "11111" & "00101",               -- [4] ADDI X5, XZR, #1 (should NOT happen)
        ADDI & "000000000001" & "11111" & "00100",               -- [5] ADDI X4, XZR, #1 (should NOT happen)
        ADDI & "000000000001" & "00010" & "00010",               -- [6] ADDI X2, X2, #1 (should happen)                X2 = 1
        ADDI & "000000000001" & "11111" & "00000",               -- [7] ADDI X0, XZR, #1
        CMP & "00" & "000000000000" & "00000" & "00001",         -- [8] CMP X0, X1          (FLAGS = 010) 1-3 = -2
        BC & "0000000000000000000011" & BNE,                     -- [9] BNE 3
        ADDI & "000000000010" & "11111" & "00101",               -- [10] ADDI X5, XZR, #2 (should NOT happen)
        ADDI & "000000000010" & "11111" & "00100",               -- [11] ADDI X4, XZR, #2 (should NOT happen)
        ADDI & "000000000010" & "00010" & "00010",               -- [12] ADDI X2, X2, #2 (should happen)               X2 = 3
        CMP & "00" & "000000000000" & "00000" & "00001",         -- [13] CMP X0, X1          (FLAGS = 010) 1-3 = -2
        BC & "0000000000000000000011" & BLT,                     -- [14] BLT 3
        ADDI & "000000000011" & "11111" & "00101",               -- [15] ADDI X5, XZR, #3 (should NOT happen)
        ADDI & "000000000011" & "11111" & "00100",               -- [16] ADDI X4, XZR, #3 (should NOT happen)
        ADDI & "000000000010" & "00010" & "00010",               -- [17] ADDI X2, X2, #2 (should happen)               X2 = 5
        CMP & "00" & "000000000000" & "00000" & "00001",         -- [18] CMP X0, X1          (FLAGS = 001) 1-3 = -1
        BC & "0000000000000000000011" & BLE,                     -- [19] BLE 3  (1 - 3 = -2) -> BRANCH
        ADDI & "000000000011" & "11111" & "00101",               -- [20] ADDI X5, XZR, #3 (should NOT happen)
        ADDI & "000000000011" & "11111" & "00100",               -- [21] ADDI X4, XZR, #3 (should NOT happen)
        ADDI & "000000000010" & "00010" & "00010",               -- [22] ADDI X2, X2, #2 (should happen)              X2 = 7
        ADDI & "000000000011" & "11111" & "00000",               -- [23] ADDI X0, XZR, #3
        CMP & "00" & "000000000000" & "00000" & "00001",         -- [24] CMP X0, X1          (FLAGS = 001) 3-3 = 0
        BC & "0000000000000000000011" & BLE,                     -- [25] BLE 3  (3 - 3 = 0) -> BRANCH 
        ADDI & "000000000011" & "11111" & "00101",               -- [26] ADDI X5, XZR, #3 (should NOT happen)
        ADDI & "000000000011" & "11111" & "00100",               -- [27] ADDI X4, XZR, #3 (should NOT happen)
        ADDI & "000000000010" & "00010" & "00010",               -- [28] ADDI X2, X2, #2 (should happen)              X2 = 9
        CMP & "00" & "000000000000" & "00000" & "00001",         -- [29] CMP X0, X1          (FLAGS = 001) 3-3 = 0
        BC & "0000000000000000000011" & BGE,                     -- [30] BGE 3  (1 - 3 = -2) -> BRANCH 
        ADDI & "000000000011" & "11111" & "00101",               -- [31] ADDI X5, XZR, #3 (should NOT happen)
        ADDI & "000000000011" & "11111" & "00100",               -- [32] ADDI X4, XZR, #3 (should NOT happen)
        ADDI & "000000000010" & "00010" & "00010",               -- [33] ADDI X2, X2, #2 (should happen)              X2 = 11 (B)
        ADDI & "000000001010" & "11111" & "00000",               -- [34] ADDI X0, XZR, #10
        CMP & "00" & "000000000000" & "00000" & "00001",         -- [35] CMP X0, X1          (FLAGS = 100) 10-3 = 7
        BC & "0000000000000000000011" & BGT,                     -- [36] BGE 3  (10 - 3 = 7) -> BRANCH
        ADDI & "000000000011" & "11111" & "00101",               -- [37] ADDI X5, XZR, #3 (should NOT happen)
        ADDI & "000000000011" & "11111" & "00100",               -- [38] ADDI X4, XZR, #3 (should NOT happen)
        ADDI & "000000000010" & "00010" & "00010"                -- [39] ADDI X2, X2, #2 (should happen)              X2 = 13 (D)
    );
begin
    uut : CPU port map (
        clk => clk,
        Reset => Reset,
        I_instr => I_instr,
        O_PC => O_PC,
        O_Mem_Write => O_Mem_Write,
        O_Mem_Read => O_Mem_Read,
        O_Mem_Address => O_Mem_Address,
        O_Mem_Data => O_Mem_Data,
        O_Data_Len => O_Data_Len,
        I_Mem_Data => I_Mem_Data
    );
    
    -- Connect memory
    mem_uut : Memory port map(
        clk => clk,
        I_write => I_write,
        data_len => data_len,
        address => address,
        I_data => I_data,
        O_data => O_data
    );
    
    -- Create the clock
    I_clk_process : process
    begin
        clk <= '0';
        wait for clk_period / 2;
        clk <= '1';
        wait for clk_period / 2;
    end process;
    
    -- Run the CPU
    sim_proc : process
    begin
        I_instr <= rom_memory(0);
        wait until O_PC'event;
        
        while to_integer(unsigned(O_PC)) < SIZE loop
            I_instr <= rom_memory(to_integer(unsigned(O_PC)));
            wait until O_PC'event;
        end loop;
        
        --for i in 1 to SIZE loop
        --    if to_integer(unsigned(O_PC)) < SIZE then
        --        I_instr <= rom_memory(to_integer(unsigned(O_PC)));
        --        wait until O_PC'event;
        --    --else
        --     --   Reset <= '1';
        --    end if;
        --end loop;
        
        --I_instr <= rom_memory(SIZE - 1);
        I_Instr <= X"00000000";
        Reset <= '1';
        wait;
    end process;
    
    -- This process handles the memory signals
    mem_proc : process(O_Mem_Read, O_Mem_Write, O_Mem_Address, O_Mem_Data, O_Data)
    begin
        I_write <= O_Mem_Write;
        Address <= O_Mem_Address;
        I_data <= O_Mem_Data;
        data_len <= O_Data_Len;
        if O_Mem_Read = '1' then
            I_Mem_Data <= O_Data;
        end if;
    end process;
end Behavior;
