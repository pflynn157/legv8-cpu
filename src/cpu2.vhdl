library IEEE;
use IEEE.std_logic_1164.all;

entity CPU2 is
    port (
        clk    : in std_logic;
        input  : in std_logic_vector(((32 * 12) - 1) downto 0)
    );
end CPU2;

architecture Behavior of CPU2 is
    -- The size of our instruction memory
    constant INSTR_COUNT : integer := 12;
    constant MEM_SIZE : integer := (32 * INSTR_COUNT) - 1;
    
    -- Declare the decoder component
    component Decoder is
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
            BR_address  : out std_logic_vector(25 downto 0);
            CBR_address : out std_logic_vector(18 downto 0)
        );
    end component;
    
    -- Declare the register component
    component Registers is
        port (
            sel_A   : in std_logic_vector(4 downto 0);      -- Register A (source 1)
            sel_B   : in std_logic_vector(4 downto 0);      -- Register B (source 2)
            sel_D   : in std_logic_vector(4 downto 0);      -- Register D
            I_dataD : in std_logic_vector(31 downto 0);     -- Data to write to the destination register
            I_enD   : in std_logic;                         -- Enable write
            O_dataA : out std_logic_vector(31 downto 0);    -- Output of register input A
            O_dataB : out std_logic_vector(31 downto 0)     -- Output of register input B
        );
    end component;
    
    -----------------
    -- Our signals --
    -----------------
    
    -- The program counter
    signal PC : integer := 0;
    signal done : std_logic := '0';
    
    -- Various control signals
    signal ID_en, EX_en, MEM_en, WB_en : std_logic := '0';
    signal RegWrite, Reg2Loc : std_logic := '0';
    
    -- Signals for the decoder
    signal instr : std_logic_vector(31 downto 0) := X"00000000";
    signal R_opcode, D_opcode : std_logic_vector(10 downto 0);
    signal I_opcode : std_logic_vector(9 downto 0);
    signal B_opcode : std_logic_vector(5 downto 0);
    signal CB_opcode : std_logic_vector(7 downto 0);
    signal Rm, Rn, Rd : std_logic_vector(4 downto 0);
    signal shamt : std_logic_vector(5 downto 0);
    signal Imm : std_logic_vector(11 downto 0);
    signal DT_address : std_logic_vector(8 downto 0);
    signal DT_op : std_logic_vector(1 downto 0);
    signal BR_address : std_logic_vector(25 downto 0);
    signal CBR_address : std_logic_vector(18 downto 0);
    
    -- Signals for the registers
    signal sel_A, sel_B, sel_D : std_logic_vector(4 downto 0);
    signal I_dataD, O_dataA, O_dataB : std_logic_vector(31 downto 0);
    signal I_enD : std_logic := '0';
begin
    -- Map the decoder
    decode : Decoder port map (
        instr => instr,
        R_opcode => R_opcode,
        I_opcode => I_opcode,
        D_opcode => D_opcode,
        B_opcode => B_opcode,
        CB_opcode => CB_opcode,
        Rm => Rm,
        Rn => Rn,
        Rd => Rd,
        shamt => shamt,
        Imm => Imm,
        DT_address => DT_address,
        DT_op => DT_op,
        BR_address => BR_address,
        CBR_address => CBR_address
    );
    
    -- Map the registers
    regs : Registers port map (
        sel_A => sel_A,
        sel_B => sel_B,
        sel_D => sel_D,
        I_dataD => I_dataD,
        I_enD => I_enD,
        O_dataA => O_dataA,
        O_dataB => O_dataB
    );
    
    process (clk)
    begin
        if rising_edge(clk) and done = '0' then
            -- Instruction fetch
            for stage in 1 to 5 loop
                -- Instruction fetch
                if stage = 1 then
                    instr <= input((PC + 31) downto PC);
                    ID_en <= '1';
                    if PC + 32 <= MEM_SIZE then
                        PC <= PC + 32;
                    else
                        done <= '1';
                    end if;
                    
                    -- Reset signals
                    RegWrite <= '0';
                    Reg2Loc <= '0';
                    
                -- Instruction decode
                elsif stage = 2 and ID_en = '1' then
                    EX_en <= '1';
                    -- R-format instructons
                    case (R_opcode) is
                        -- Add
                        when "10001011000" =>
                            --sel_A <= Rm;
                            --sel_B <= Rn;
                            --sel_D <= Rd;
                            --srcB <= '0';
                            --ALU_Op1 <= "0010";
                            --RegWrite <= '1';
                            
                        -- SUB
                        when "11001011000" =>
                            --sel_A <= Rm;
                            --sel_B <= Rn;
                            --sel_D <= Rd;
                            --srcB <= '0';
                            --ALU_Op1 <= "0110";
                            --RegWrite <= '1';
                        
                        -- AND
                        when "10001010000" =>
                            --sel_A <= Rm;
                            --sel_B <= Rn;
                            --sel_D <= Rd;
                            --srcB <= '0';
                            --ALU_Op1 <= "0000";
                            --RegWrite <= '1';
                        
                        -- OR
                        when "10101010000" =>
                            --sel_A <= Rm;
                            --sel_B <= Rn;
                            --sel_D <= Rd;
                            --srcB <= '0';
                            --ALU_Op1 <= "0001";
                            --RegWrite <= '1';
                        
                        -- LSL
                        when "11010011011" =>
                            --sel_A <= Rn;
                            --sel_D <= Rd;
                            --srcShamt <= '1';
                            --ALU_Op1 <= "1100";
                            --RegWrite <= '1';
                        
                        -- LSR
                        when "11010011010" =>
                            --sel_A <= Rn;
                            --sel_D <= Rd;
                            --srcShamt <= '1';
                            --ALU_Op1 <= "1101";
                            --RegWrite <= '1';
                    
                        when others =>
                        
                    -- I format instructions
                    case (I_opcode) is
                        -- ADDI
                        when "1001000100" =>
                            --sel_A <= Rn;
                            --sel_D <= Rd;
                            --srcB <= '1';
                            --ALU_Op1 <= "0010";
                            --RegWrite <= '1';
                            
                        -- SUBI
                        
                        when others =>
                        
                    -- D format instructions
                    case (D_opcode) is
                        -- LDUR
                        
                        -- STUR
                        
                        -- MOV
                        when "11010010100" =>
                            sel_A <= Rn;
                            sel_D <= Rd;
                            RegWrite1 <= '1';
                            Reg2Loc1 <= '1';
                        
                        when others =>
                        
                    -- B format instructions
                    case (B_opcode) is
                        -- B
                        
                        -- BR
                        
                        when others =>
                    
                    -- CB format instructions
                    case (CB_opcode) is
                        -- CMP
                        
                        -- CBZ
                        
                        when others =>
                    end case; -- case CB_opcode
                    end case; -- case B_opcode
                    end case; -- case D_opcode
                    end case; -- case I_opcode
                    end case; -- case R_opcode
                
                -- Instruction execute
                elsif stage = 3 and EX_en = '1' then
                    MEM_en <= '1';
                    
                -- Memory read/write
                elsif stage = 4 and MEM_en = '1' then
                    WB_en <= '1';
                
                -- Register write_back
                elsif stage = 5 and WB_en = '1' then
                    if RegWrite2 = '1' then
                        I_enD <= '1';
                        if Reg2Loc2 = '1' then
                            I_dataD <= O_dataA;
                        else
                        
                        end if;
                    else
                        I_enD <= '0';
                    end if;
                    
                end if;
            end loop;
        end if;
    end process;
end Behavior;
