library IEEE;
use IEEE.std_logic_1164.all;

entity decoder_tb is
end decoder_tb;

architecture Behavior of decoder_tb is

    -- Instructions
    constant ADD : std_logic_vector := "000"; 
    constant O_XOR : std_logic_vector := "100";
    constant O_OR : std_logic_vector := "110";
    constant LW : std_logic_vector := "010";
    
    constant ALU : std_logic_vector := "0110011";
    constant ALU_I : std_logic_vector := "0010011";
    constant LD : std_logic_vector := "0000011";
    
    constant STD_ALU : std_logic_vector := "0000000";
    constant SUB_ALU : std_logic_vector := "0100000";

    -- Declare our component
    component Decoder is
        port (
            instr  : in std_logic_vector(31 downto 0);
            opcode : out std_logic_vector(6 downto 0);
            rd     : out std_logic_vector(4 downto 0);
            rs1    : out std_logic_vector(4 downto 0);
            rs2    : out std_logic_vector(4 downto 0);
            funct3 : out std_logic_vector(2 downto 0);
            funct7 : out std_logic_vector(6 downto 0);
            imm    : out std_logic_vector(11 downto 0);
            imm1   : out std_logic_vector(4 downto 0);
            imm2   : out std_logic_vector(6 downto 0);
            UJ_imm : out std_logic_vector(19 downto 0)
        );
    end component;
    
    -- Our signals
    signal instr : std_logic_vector(31 downto 0);
    signal opcode, funct7, imm2 : std_logic_vector(6 downto 0);
    signal rd, rs1, rs2, imm1 : std_logic_vector(4 downto 0);
    signal funct3 : std_logic_vector(2 downto 0);
    signal imm : std_logic_vector(11 downto 0);
    signal UJ_imm : std_logic_vector(19 downto 0);
    
    -- Clock period definitions
    signal clk : std_logic := '0';
    constant clk_period : time := 10 ns;
begin
    -- Initialize component
    uut : Decoder port map (
        instr => instr,
        opcode => opcode,
        rd => rd,
        rs1 => rs1,
        rs2 => rs2,
        funct3 => funct3,
        funct7 => funct7,
        imm => imm,
        imm1 => imm1,
        imm2 => imm2,
        UJ_imm => UJ_imm
    );
    
    -- Clock process definitions
    I_clk_process : process
    begin
        clk <= '0';
        wait for clk_period/2;
        clk <= '1';
        wait for clk_period/2;
    end process;
 
    -- Test process
    -- Here, we will test decoding 2 of each type of instruction
    stim_proc: process
    begin
        wait for 10 ns;
        
        -----------------
        -- Test R type --
        -----------------
        
        -- ADD x0, x1, x2
        instr <= STD_ALU & "00010" & "00001" & ADD & "00000" & ALU;
        wait for clk_period;
        assert opcode = ALU report "R-type test1 failed-> Invalid opcode" severity error;
        assert rd = "00000" report "R-type test1 failed-> Invalid rd" severity error;
        assert rs1 = "00001" report "R-type test1 failed-> Invalid rs1" severity error;
        assert rs2 = "00010" report "R-type test1 failed-> Invalid rs2" severity error;
        assert funct3 = ADD report "R-type test1 failed-> Invalid funct3" severity error;
        assert funct7 = STD_ALU report "R-type test1 failed-> Invalid funct7" severity error;
        
        -- SUB x5, x0, x1
        instr <= SUB_ALU & "00001" & "00000" & ADD & "00101" & ALU;
        wait for clk_period;
        assert opcode = ALU report "R-type test2 failed-> Invalid opcode" severity error;
        assert rd = "00101" report "R-type test2 failed-> Invalid rd" severity error;
        assert rs1 = "00000" report "R-type test2 failed-> Invalid rs1" severity error;
        assert rs2 = "00001" report "R-type test2 failed-> Invalid rs2" severity error;
        assert funct3 = ADD report "R-type test2 failed-> Invalid funct3" severity error;
        assert funct7 = SUB_ALU report "R-type test2 failed-> Invalid funct7" severity error;
        
        -- OR x7, x8, x9
        instr <= STD_ALU & "01001" & "01000" & O_OR & "00111" & ALU;
        wait for clk_period;
        assert opcode = ALU report "R-type test3 failed-> Invalid opcode" severity error;
        assert rd = "00111" report "R-type test3 failed-> Invalid rd" severity error;
        assert rs1 = "01000" report "R-type test3 failed-> Invalid rs1" severity error;
        assert rs2 = "01001" report "R-type test3 failed-> Invalid rs2" severity error;
        assert funct3 = O_OR report "R-type test3 failed-> Invalid funct3" severity error;
        assert funct7 = STD_ALU report "R-type test3 failed-> Invalid funct7" severity error;
        
        -----------------
        -- Test I type --
        -----------------
        
        -- XORI X1, X2, #10
        instr <= "000000001010" & "00010" & O_XOR & "00001" & ALU_I;
        wait for clk_period;
        assert opcode = ALU_I report "I-type test1 failed-> Invalid opcode" severity error;
        assert rd = "00001" report "I-type test1 failed-> Invalid Rd" severity error;
        assert rs1 = "00010" report "I-type test1 failed-> Invalid Rs1" severity error;
        assert funct3 = O_XOR report "I-type test1 failed-> Invalid opcode" severity error;
        assert Imm = "000000001010" report "I-type test1 failed-> Invalid imm" severity error;
        
        -- LW X3, [X1, #5]
        instr <= "000000000101" & "00001" & LW & "00011" & LD;
        wait for clk_period;
        assert opcode = LD report "I-type test2 failed-> Invalid opcode" severity error;
        assert rd = "00011" report "I-type test2 failed-> Invalid Rd" severity error;
        assert rs1 = "00001" report "I-type test2 failed-> Invalid Rs1" severity error;
        assert funct3 = LW report "I-type test2 failed-> Invalid opcode" severity error;
        assert Imm = "000000000101" report "I-type test2 failed-> Invalid imm" severity error;
        
        wait;
    end process;
end architecture;

