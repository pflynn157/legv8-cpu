library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity Decoder is
    port (
        instr       : in std_logic_vector(31 downto 0);
        R_opcode    : out std_logic_vector(10 downto 0);
        I_opcode    : out std_logic_vector(9 downto 0);
        D_opcode    : out std_logic_vector(10 downto 0);
        B_opcode    : out std_logic_vector(5 downto 0);
        CB_opcode   : out std_logic_vector(7 downto 0);
        Rm          : out std_logic_vector(4 downto 0);
        Rn          : out std_logic_vector(4 downto 0);
        Rd          : out std_logic_vector(4 downto 0);
        shamt       : out std_logic_vector(5 downto 0);
        Imm         : out std_logic_vector(11 downto 0);
        DT_address  : out std_logic_vector(8 downto 0);
        DT_op       : out std_logic_vector(1 downto 0);
        BR_address  : out std_logic_vector(21 downto 0);
        BR_op       : out std_logic_vector(3 downto 0);
        CBR_address : out std_logic_vector(18 downto 0)
    );
end Decoder;

architecture Behavior of Decoder is
begin
    process (instr)
    begin
        -- Decode R-type instructions
        R_opcode <= instr(31 downto 21);
        Rm <= instr(20 downto 16);
        shamt <= instr(15 downto 10);
        Rn <= instr(9 downto 5);
        Rd <= instr(4 downto 0);
            
        -- Decode I-type instructions
        I_opcode <= instr(31 downto 22);
        Imm <= instr(21 downto 10);
            
        -- Decode D-type instructions
        D_opcode <= instr(31 downto 21);
        DT_address <= instr(20 downto 12);
        DT_op <= instr(11 downto 10);
        
        -- Decode B-type instructions
        B_opcode <= instr(31 downto 26);
        BR_address <= instr(25 downto 4);
        BR_op <= instr(3 downto 0);
            
        -- Decode CB-type instructions
        CB_opcode <= instr(31 downto 24);
        CBR_address <= instr(23 downto 5);
    end process;
end Behavior;
