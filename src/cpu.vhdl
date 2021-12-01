library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity CPU is
    port (
        clk           : in std_logic;
        reset         : in std_logic;
        I_instr       : in std_logic_vector(31 downto 0);
        O_PC          : out std_logic_vector(31 downto 0);
        O_Mem_Write   : out std_logic;
        O_Mem_Read    : out std_logic;
        O_Mem_Address : out std_logic_vector(31 downto 0);
        O_Mem_Data    : out std_logic_vector(31 downto 0);
        O_Data_Len    : out std_logic_vector(1 downto 0);
        I_Mem_Data    : in std_logic_vector(31 downto 0)
    );
end CPU;

architecture Behavior of CPU is

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
            BR_address  : out std_logic_vector(21 downto 0);
            BR_op       : out std_logic_vector(3 downto 0);
            CBR_address : out std_logic_vector(18 downto 0)
        );
    end component;
    
    -- The ALU component
    component ALU is
        port (
            A      : in std_logic_vector(31 downto 0);
            B      : in std_logic_vector(31 downto 0);
            ALU_op : in std_logic_vector(3 downto 0);
            Zero   : out std_logic;
            Result : out std_logic_vector(31 downto 0)
        );
    end component;
    
    -- The register file
    component Registers is
        port (
            clk     : in std_logic;
            sel_A   : in std_logic_vector(4 downto 0);
            sel_B   : in std_logic_vector(4 downto 0);
            sel_D   : in std_logic_vector(4 downto 0);
            I_dataD : in std_logic_vector(31 downto 0);
            I_enD   : in std_logic;
            O_dataA : out std_logic_vector(31 downto 0);
            O_dataB : out std_logic_vector(31 downto 0)
        );
    end component;
    
    -- Signals for the decoder component
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
    signal BR_address, BR_Address2 : std_logic_vector(21 downto 0);
    signal BR_op, BR_op2 : std_logic_vector(3 downto 0);
    signal CBR_address : std_logic_vector(18 downto 0);
    
    -- Signals for the ALU component
    signal A, B, Result: std_logic_vector(31 downto 0);
    signal ALU_Op, ALU_Op1 : std_logic_vector(3 downto 0);
    signal Zero : std_logic := '0';
    
    -- Signals for the register file component
    signal sel_A, sel_B, sel_D : std_logic_vector(4 downto 0);
    signal I_dataD, O_dataA, O_dataB : std_logic_vector(31 downto 0);
    signal I_enD : std_logic;
    
    -- Intermediate signals for the pipeline
    signal sel_D_1, sel_D_2 : std_logic_vector(4 downto 0);
    signal srcImm, RegWrite, RegWrite2, MemWrite, MemWrite2 : std_logic := '0';
    signal Reg2Loc, Reg2Loc2 : std_logic := '0';
    signal MemRead, MemRead2 : std_logic := '0';
    signal Imm_S2 : std_logic_vector(11 downto 0);
    signal MemData : std_logic_vector(31 downto 0);
    signal Data_Len, Data_Len2 : std_logic_vector(1 downto 0);
    
    -- Comparison-related stuff
    signal Flags : std_logic_vector(2 downto 0) := "000";   -- GT LT EQ
    signal SetFlags, SetFlags2 : std_logic := '0';

    -- Pipeline and program counter signals
    signal PC : std_logic_vector(31 downto 0) := X"00000000";
    signal IF_stall, MEM_stall, Cond_Br : std_logic := '0';
    signal Cp_Rn, Cp_Rm : std_logic := '0';
    signal WB_stall, Br : integer := 0;
begin
    -- Connect the decoder
    -- Map the decoder
    uut_decode : Decoder port map (
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
        BR_op => BR_op,
        CBR_address => CBR_address
    );
    
    -- Connect the ALU
    uut_ALU : ALU port map (
        A => A,
        B => B,
        ALU_Op => ALU_Op,
        Zero => Zero,
        Result => Result
    );
    
    -- Connect the registers
    uut_Registers : Registers port map (
        clk => clk,
        sel_A => sel_A,
        sel_B => sel_B,
        sel_D => sel_D,
        I_dataD => I_dataD,
        I_enD => I_enD,
        O_dataA => O_dataA,
        O_dataB => O_dataB
    );

    process (clk)
        variable type_I, type_R, type_C : boolean := false;
        variable Should_Br : boolean := false;
    begin
        type_I := false;
        type_R := false;
        type_C := false;
        Should_Br := false;
        
        if rising_edge(clk) then
            if reset = '1' then
                O_Mem_Write <= '0';
            end if;
            
            for stage in 1 to 5 loop
                -- Instruction fetch
                if stage = 1 and IF_stall = '0' then
                    PC <= std_logic_vector(unsigned(PC) + 1);
                    instr <= I_instr;
                    O_PC <= PC;
                elsif stage = 1 and IF_stall = '1' then
                    PC <= std_logic_vector(unsigned(PC) - 1);
                    
                -- Instruction decode
                elsif stage = 2 and IF_stall = '0' and Br = 0 then
                    sel_D_1 <= rd;
                    sel_A <= Rn;
                    sel_B <= Rm;
                    srcImm <= '0';
                    RegWrite <= '0';
                    Reg2Loc <= '0';
                    MemWrite <= '0';
                    Mem_Stall <= '0';
                    MemRead <= '0';
                    SetFlags <= '0';
                    Cond_Br <= '0';
                    Imm_S2 <= Imm;
                    BR_Address2 <= BR_Address;
                    
                    -- R-format instructons
                    case (R_opcode) is
                        -- Add
                        when "10001011000" =>
                            ALU_Op1 <= "0010";
                            RegWrite <= '1';
                            type_R := true;
                            
                        -- SUB
                        when "11001011000" =>
                            sel_A <= Rm;
                            sel_B <= Rn;
                            ALU_Op1 <= "0110";
                            RegWrite <= '1';
                            type_R := true;
                        
                        -- AND
                        when "10001010000" =>
                            ALU_Op1 <= "0000";
                            RegWrite <= '1';
                            type_R := true;
                        
                        -- OR
                        when "10101010000" =>
                            ALU_Op1 <= "0001";
                            RegWrite <= '1';
                            type_R := true;
                        
                        -- LSL
                        when "11010011011" =>
                            ALU_Op1 <= "1100";
                            Imm_S2 <= "000000" & shamt;
                            RegWrite <= '1';
                            srcImm <= '1';
                            type_R := true;
                        
                        -- LSR
                        when "11010011010" =>
                            ALU_Op1 <= "1101";
                            Imm_S2 <= "000000" & shamt;
                            RegWrite <= '1';
                            srcImm <= '1';
                            type_R := true;
                    
                        when others =>
                        
                    -- I format instructions
                    case (I_opcode) is
                        -- ADDI
                        when "1001000100" =>
                            srcImm <= '1';
                            ALU_Op1 <= "0010";
                            RegWrite <= '1';
                            type_I := true;
                            
                        -- SUBI
                        when "1101000100" =>
                            srcImm <= '1';
                            ALU_Op1 <= "0110";
                            RegWrite <= '1';
                            type_I := true;
                        
                        when others =>
                        
                    -- D format instructions
                    case (D_opcode) is
                        -- LDUR
                        when "11111000010" =>
                            ALU_Op1 <= "0010";
                            srcImm <= '1';
                            MemRead <= '1';
                            WB_Stall <= 2;
                            IF_stall <= '1';
                            RegWrite <= '1';
                            Imm_S2 <= "000" & DT_Address;
                            type_I := true;
                        
                        -- STUR
                        when "11111000000" =>
                            ALU_Op1 <= "0010";
                            sel_B <= Rd;
                            srcImm <= '1';
                            MemWrite <= '1';
                            Mem_Stall <= '1';
                            Imm_S2 <= "000" & DT_Address;
                        
                        -- MOV
                        when "11010010100" =>
                            ALU_Op1 <= "0010";
                            RegWrite <= '1';
                            Reg2Loc <= '1';
                            
                        -- NOP
                        -- I doubt this is the actual NOP for Arm; I just made something
                        -- up because I needed it.
                        when "11010011111" =>
                        
                        when others =>
                        
                    -- B format instructions
                    case (B_opcode) is
                        -- B
                        when "000101" =>
                            if to_integer(signed(PC)) = 1 then
                                PC <= std_logic_vector((signed(PC)) + (signed("000000" & BR_address & BR_op) - 1));
                                Br <= 2;
                            else
                                if BR_address(21) = '1' then
                                    PC <= std_logic_vector((signed(PC)) + (signed("111111" & BR_address & BR_op) - 2));
                                else
                                    PC <= std_logic_vector((signed(PC)) + (signed("000000" & BR_address & BR_op) - 2));
                                    Br <= 2;
                                end if;
                            end if;
                            O_PC <= PC;
                            
                        
                        -- BR
                        when "010101" =>
                            BR_op2 <= BR_op;
                            Cond_Br <= '1';
                            IF_Stall  <= '1';
                        
                        when others =>
                    
                    -- CB format instructions
                    case (CB_opcode) is
                        -- CMP
                        when "10110101" =>
                            sel_D_1 <= "XXXXX";
                            sel_A <= Rn;
                            sel_B <= Rd;
                            ALU_Op1 <= "0110";
                            SetFlags <= '1';
                            type_C := true;
                            IF_Stall <= '1';
                        
                        -- CBZ
                        
                        when others =>
                    end case; -- case CB_opcode
                    end case; -- case B_opcode
                    end case; -- case D_opcode
                    end case; -- case I_opcode
                    end case; -- case R_opcode
                    
                    -- Check to see if we have a RAW dependency. If so, stall the pipeline
                    if type_I then
                        if rn = sel_d_1 then
                            IF_stall <= '1';
                        end if;
                    elsif type_R then
                        if rn = sel_d_1 then
                            Cp_Rm <= '1';
                        end if;
                        if rm = sel_d_1 then
                            Cp_Rn <= '1';
                        end if;
                    elsif type_C then
                        if rn = sel_d_1 or rd = sel_d_1 then
                            IF_stall <= '1';
                        end if;
                    end if;
                elsif stage = 2 and IF_stall = '1' then
                    IF_stall <= '0';
                elsif stage = 2 and Br > 0 then
                    Br <= Br - 1;
                
                -- Instruction execute
                elsif stage = 3 and Cond_Br = '0' then
                    sel_D_2 <= sel_D_1;
                    MemWrite2 <= MemWrite;
                    MemRead2 <= MemRead;
                    RegWrite2 <= RegWrite;
                    MemData <= O_dataB;
                    Data_Len2 <= Data_Len;
                    ALU_Op <= ALU_Op1;
                    SetFlags2 <= SetFlags;
                    
                    --if Cp_Rn = '1' then
                    --    A <= Result;
                    --    Cp_Rn <= '0';
                    --else
                        A <= O_dataA;
                    --end if;
                    
                    if srcImm = '1' then
                        B <= "00000000000000000000" & Imm_S2;
                    elsif Reg2Loc = '1' then
                        A <= O_dataA;
                        B <= X"00000000";
                    elsif Cp_Rn = '1' then
                        B <= Result;
                        Cp_Rn <= '0';
                    else
                        B <= O_dataB;
                    end if;
                    
                -- Instruction execute- specific for conditional branches
                elsif stage = 3 and Cond_Br = '1' then
                    case (BR_op2) is
                        -- BEQ
                        when "0000" =>
                            if flags(0) = '1' or signed(Result) = 0 then
                                PC <= std_logic_vector((signed(PC)) + (signed("000000" & BR_address2) - 2));
                                O_PC <= PC;
                                Br <= 2;
                            else
                                PC <= std_logic_vector(unsigned(PC) + 1);
                                instr <= I_instr;
                                O_PC <= PC;
                            end if;
                            
                        -- BNE
                        when "0001" =>
                            if flags(0) = '0' or signed(Result) /= 0 then
                                PC <= std_logic_vector((signed(PC)) + (signed("000000" & BR_address2) - 2));
                                O_PC <= PC;
                                Br <= 2;
                            else
                                PC <= std_logic_vector(unsigned(PC) + 1);
                                instr <= I_instr;
                                O_PC <= PC;
                            end if;
                            
                        -- BLT
                        when "1011" =>
                            if flags(1) = '1' or signed(Result) < 0 then
                                PC <= std_logic_vector((signed(PC)) + (signed("000000" & BR_address2) - 2));
                                O_PC <= PC;
                                Br <= 2;
                            else
                                PC <= std_logic_vector(unsigned(PC) + 1);
                                instr <= I_instr;
                                O_PC <= PC;
                            end if;
                            
                        -- BLE
                        when "1101" =>
                            if (flags(1) = '1' or signed(Result) < 0) or (flags(0) = '1' or signed(Result) = 0) then
                                PC <= std_logic_vector((signed(PC)) + (signed("000000" & BR_address2) - 2));
                                O_PC <= PC;
                                Br <= 2;
                            else
                                PC <= std_logic_vector(unsigned(PC) + 1);
                                instr <= I_instr;
                                O_PC <= PC;
                            end if;
                            
                        -- BGT
                        when "1100" =>
                            if flags(2) = '1' or signed(Result) > 0 then
                                PC <= std_logic_vector((signed(PC)) + (signed("000000" & BR_address2) - 2));
                                O_PC <= PC;
                                Br <= 2;
                            else
                                PC <= std_logic_vector(unsigned(PC) + 1);
                                instr <= I_instr;
                                O_PC <= PC;
                            end if;
                            
                        -- BGE
                        when "1010" =>
                            if (flags(2) = '1' or signed(Result) > 0) or (flags(0) = '1' or signed(Result) = 0) then
                                PC <= std_logic_vector((signed(PC)) + (signed("000000" & BR_address2) - 2));
                                O_PC <= PC;
                                Br <= 2;
                            else
                                PC <= std_logic_vector(unsigned(PC) + 1);
                                instr <= I_instr;
                                O_PC <= PC;
                            end if;
                            
                        when others =>
                    end case;
                    
                    Cond_Br <= '0';
                
                -- Memory
                elsif stage = 4 and Mem_Stall = '0' then
                    O_Mem_Write <= MemWrite2;
                    O_Mem_Read <= MemRead2;
                    O_Mem_Address <= Result;
                    O_Data_Len <= "11";
                    
                    if MemWrite2 = '1' then
                        O_Mem_Data <= MemData;
                    end if;
                elsif stage = 4 and Mem_Stall = '1' then
                    Mem_Stall <= '0';
                
                -- Write-back
                elsif stage = 5 and WB_Stall = 0 then
                    if RegWrite2 = '1' then
                        sel_D <= sel_D_2;
                        I_enD <= '1';
                        
                        if MemRead2 = '1' then
                            I_dataD <= I_Mem_Data;
                        else
                            I_dataD <= Result;
                        end if;
                    else
                        I_enD <= '0';
                    end if;
                    
                    -- Write the flags registers
                    if SetFlags2 = '1' then
                        if signed(Result) < 0 then
                            Flags <= "010";
                        elsif signed(Result) > 0 then
                            Flags <= "100";
                        else
                            Flags <= "001";
                        end if;
                    end if;
                elsif stage = 5 and WB_Stall > 0 then
                    WB_Stall <= WB_stall - 1;
                end if;
            end loop;
        end if;
    end process;
end Behavior;
