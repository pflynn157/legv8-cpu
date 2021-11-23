library IEEE;
use IEEE.std_logic_1164.all;

entity Decoder is
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
end Decoder;

architecture Behavior of Decoder is
begin
    process (instr)
    begin
        -- All instructions have an opcode
        opcode <= instr(6 downto 0);
        
        -- All instructions have either an Rd or the lower half of the IMM
        rd <= instr(11 downto 7);
        imm1 <= instr(11 downto 7);
        
        -- R, I, S, and B type instructions have funct3 and rs1
        funct3 <= instr(14 downto 12);
        rs1 <= instr(19 downto 15);
        
        -- R type have rs2 and funct7
        rs2 <= instr(24 downto 20);
        funct7 <= instr(31 downto 25);
        
        -- I type have the immediate field
        imm <= instr(31 downto 20);
        
        -- S and B type have the second immediate field
        imm2 <= instr(31 downto 25);
        
        -- U and J type have the long immediate fields
        UJ_imm <= instr(31 downto 12);
    end process;
end Behavior;