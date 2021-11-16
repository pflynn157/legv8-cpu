library IEEE;
use IEEE.std_logic_1164.all;

entity CPU is
    port (
        clk    : in std_logic;
        input  : in std_logic_vector(((32 * 14) - 1) downto 0)
    );
end CPU;

architecture Behavior of CPU is
    -- The size of our instruction memory
    constant INSTR_COUNT : integer := 14;
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
            clk     : in std_logic;
            sel_A   : in std_logic_vector(4 downto 0);      -- Register A (source 1)
            sel_B   : in std_logic_vector(4 downto 0);      -- Register B (source 2)
            sel_D   : in std_logic_vector(4 downto 0);      -- Register D
            I_dataD : in std_logic_vector(31 downto 0);     -- Data to write to the destination register
            I_enD   : in std_logic;                         -- Enable write
            O_dataA : out std_logic_vector(31 downto 0);    -- Output of register input A
            O_dataB : out std_logic_vector(31 downto 0)     -- Output of register input B
        );
    end component;
    
    -- Declare the ALU component
    component ALU is
        port (
            clk    : in std_logic;
            A      : in std_logic_vector(31 downto 0);
            B      : in std_logic_vector(31 downto 0);
            ALU_Op : in std_logic_vector(3 downto 0);
            Zero   : out std_logic;
            Result : out std_logic_vector(31 downto 0)
        );
    end component;
    
    -----------------
    -- Our signals --
    -----------------
    
    -- The program counter
    signal PC : integer := 0;
    signal done : std_logic := '0';
    
    -- Signals for the decoder
    signal instr : std_logic_vector(31 downto 0) := X"00000000";
    signal R_opcode, D_opcode : std_logic_vector(10 downto 0);
    signal I_opcode : std_logic_vector(9 downto 0);
    signal B_opcode : std_logic_vector(5 downto 0);
    signal CB_opcode : std_logic_vector(7 downto 0);
    signal Rm, Rn, Rd : std_logic_vector(4 downto 0);
    signal shamt, shamt2 : std_logic_vector(5 downto 0);
    signal Imm, Imm2 : std_logic_vector(11 downto 0);
    signal DT_address : std_logic_vector(8 downto 0);
    signal DT_op : std_logic_vector(1 downto 0);
    signal BR_address : std_logic_vector(25 downto 0);
    signal CBR_address : std_logic_vector(18 downto 0);
    
    -- Signals for the registers
    signal sel_A, sel_B, sel_D, sel_D_1, sel_D_2 : std_logic_vector(4 downto 0);
    signal I_dataD, O_dataA, O_dataB : std_logic_vector(31 downto 0);
    signal I_enD : std_logic := '0';
    
    -- Signals for the ALU
    signal A, B, Result : std_logic_vector(31 downto 0);
    signal ALU_Op : std_logic_vector(3 downto 0);
    signal Zero : std_logic;
    
    -- Various control lines
    signal srcB, srcB2, srcShamt : std_logic := '0';                    -- 0 = reg, 1 = imm
    signal RegWrite, Reg2Loc : std_logic := '0';                -- 0 = no write, 1 = write
    signal ALU_Op1 : std_logic_vector(3 downto 0);
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
        clk => clk,
        sel_A => sel_A,
        sel_B => sel_B,
        sel_D => sel_D,
        I_dataD => I_dataD,
        I_enD => I_enD,
        O_dataA => O_dataA,
        O_dataB => O_dataB
    );
    
    -- Map the ALU
    compALU : ALU port map (
        clk => clk,
        A => A,
        B => B,
        ALU_Op => ALU_Op,
        Zero => Zero,
        Result => Result
    );
    
    process (clk)
    begin
        if rising_edge(clk) then
            -- Instruction fetch
            for stage in 1 to 5 loop
                -- Instruction fetch
                --if stage = 1 and done = '0' then
                if stage = 1 then
                    instr <= input((PC + 31) downto PC);
                    if PC + 32 <= MEM_SIZE then
                        PC <= PC + 32;
                    else
                        done <= '1';
                    end if;
                    
                -- Instruction decode
                elsif stage = 2 then
                    -- R-format instructons
                    case (R_opcode) is
                        -- Add
                        when "10001011000" =>
                            sel_A <= Rm;
                            sel_B <= Rn;
                            sel_D_1 <= Rd;
                            srcB <= '0';
                            ALU_Op1 <= "0010";
                            RegWrite <= '1';
                            Reg2Loc <= '0';
                            
                        -- SUB
                        when "11001011000" =>
                            sel_A <= Rm;
                            sel_B <= Rn;
                            sel_D_1 <= Rd;
                            srcB <= '0';
                            ALU_Op1 <= "0110";
                            RegWrite <= '1';
                            Reg2Loc <= '0';
                        
                        -- AND
                        when "10001010000" =>
                            sel_A <= Rm;
                            sel_B <= Rn;
                            sel_D_1 <= Rd;
                            srcB <= '0';
                            ALU_Op1 <= "0000";
                            RegWrite <= '1';
                            Reg2Loc <= '0';
                        
                        -- OR
                        when "10101010000" =>
                            sel_A <= Rm;
                            sel_B <= Rn;
                            sel_D_1 <= Rd;
                            srcB <= '0';
                            ALU_Op1 <= "0001";
                            RegWrite <= '1';
                            Reg2Loc <= '0';
                        
                        -- LSL
                        when "11010011011" =>
                            sel_A <= Rn;
                            sel_D_1 <= Rd;
                            srcShamt <= '1';
                            ALU_Op1 <= "1100";
                            RegWrite <= '1';
                            Reg2Loc <= '0';
                            shamt2 <= shamt;
                        
                        -- LSR
                        when "11010011010" =>
                            sel_A <= Rn;
                            sel_D_1 <= Rd;
                            srcShamt <= '1';
                            ALU_Op1 <= "1101";
                            RegWrite <= '1';
                            Reg2Loc <= '0';
                            shamt2 <= shamt;
                    
                        when others =>
                        
                    -- I format instructions
                    case (I_opcode) is
                        -- ADDI
                        when "1001000100" =>
                            sel_A <= Rn;
                            sel_D_1 <= Rd;
                            Imm2 <= Imm;
                            srcB <= '1';
                            ALU_Op1 <= "0010";
                            RegWrite <= '1';
                            Reg2Loc <= '0';
                            srcShamt <= '0';
                            
                        -- SUBI
                        when "1101000100" =>
                            sel_A <= Rn;
                            sel_D_1 <= Rd;
                            Imm2 <= Imm;
                            srcB <= '1';
                            ALU_Op1 <= "0110";
                            RegWrite <= '1';
                            Reg2Loc <= '0';
                            srcShamt <= '0';
                        
                        when others =>
                        
                    -- D format instructions
                    case (D_opcode) is
                        -- LDUR
                        
                        -- STUR
                        
                        -- MOV
                        when "11010010100" =>
                            sel_A <= Rn;
                            sel_D_1 <= Rd;
                            RegWrite <= '1';
                            Reg2Loc <= '1';
                        
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
                elsif stage = 3 then
                    sel_D_2 <= sel_D_1;
                    if Reg2Loc = '1' then
                        I_dataD <= O_dataA;
                    else
                        ALU_Op <= ALU_Op1;
                        A <= O_dataA;
                        if srcShamt = '1' then
                            B <= X"000000" & "00" & shamt2;
                        elsif srcB = '1' then
                            B <= "00000000000000000000" & Imm2;
                        else
                            B <= O_dataB;
                        end if;
                    end if;
                    
                -- Memory read/write
                elsif stage = 4 then
                
                -- Register write_back
                elsif stage = 5 then
                    if RegWrite = '1' then
                        if Reg2Loc = '0' then
                            I_dataD <= Result;
                        end if;
                        sel_D <= sel_D_2;
                        I_enD <= '1';
                    else
                        I_enD <= '0';
                    end if;
                    
                end if;
            end loop;
        end if;
    end process;
end Behavior;
