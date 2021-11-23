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
    
    -- Our test program
    constant SIZE : integer := 3;
    type instr_memory is array (0 to (SIZE - 1)) of std_logic_vector(31 downto 0);
    signal rom_memory : instr_memory := (
        ADDI & "000000000010" & "00001" & "00001",            -- ADDI X1, X1, #2 
        ADDI & "000000000100" & "00000" & "00000",            -- ADDI X0, X0, #4
        ADDI & "000000000101" & "00000" & "00000"             -- ADDI X0, X0, #5    (X0 == 9)
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
        
        for i in 1 to SIZE loop
            if to_integer(unsigned(O_PC)) < SIZE then
                I_instr <= rom_memory(to_integer(unsigned(O_PC)));
                wait until O_PC'event;
            else
                Reset <= '1';
            end if;
        end loop;
        
        I_instr <= X"00000000";
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
