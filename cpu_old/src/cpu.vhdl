library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity CPU is
    port (
        clk    : in std_logic;
        input  : in std_logic_vector(((32 * 64) - 1) downto 0)
    );
end CPU;

architecture Behavior of CPU is
    -- The size of our instruction memory (2048)
    constant INSTR_COUNT : integer := 64;
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
            BR_address  : out std_logic_vector(21 downto 0);
            BR_op       : out std_logic_vector(3 downto 0);
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
    
    -- Declare the Memory component
    component Memory is
        port (
            clk     : in std_logic;
            I_write : in std_logic;
            address : in std_logic_vector(31 downto 0);
            I_data  : in std_logic_vector(31 downto 0);
            O_data  : out std_logic_vector(31 downto 0)
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
    signal DT_address, DT_address2 : std_logic_vector(8 downto 0);
    signal DT_op : std_logic_vector(1 downto 0);
    signal BR_address : std_logic_vector(21 downto 0);
    signal BR_op : std_logic_vector(3 downto 0);
    signal CBR_address : std_logic_vector(18 downto 0);
    
    -- Signals for the registers
    signal sel_A, sel_B, sel_D, sel_D_1, sel_D_2 : std_logic_vector(4 downto 0);
    signal I_dataD, O_dataA, O_dataB : std_logic_vector(31 downto 0);
    signal I_enD : std_logic := '0';
    
    -- Signals for the ALU
    signal A, B, Result : std_logic_vector(31 downto 0);
    signal ALU_Op : std_logic_vector(3 downto 0);
    signal Zero : std_logic;
    
    -- Signals for the memory
    signal I_write : std_logic := '0';
    signal address : std_logic_vector(31 downto 0) := X"00000000";
    signal I_data, O_data : std_logic_vector(31 downto 0) := X"00000000";
    
    -- Various control lines
    signal srcB, srcB2, srcShamt, srcAddr : std_logic := '0';                    -- 0 = reg, 1 = imm
    signal RegWrite, RegWrite2, Reg2Loc : std_logic := '0';                -- 0 = no write, 1 = write
    signal MemWrite, MemWrite2 : std_logic := '0';
    signal MemRead, MemRead2 : std_logic := '0';
    signal ALU_Op1 : std_logic_vector(3 downto 0);
    signal MemData : std_logic_vector(31 downto 0) := X"00000000";
    signal Stall : std_logic := '0';
    
    -- Flag-related stuff
    signal Flags : std_logic_vector(2 downto 0) := "000";   -- GT LT EQ
    signal SetFlags, SetFlags2 : std_logic := '0';
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
        BR_op => BR_op,
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
    
    -- Map the memory
    mem_block : Memory port map (
        clk => clk,
        I_write => I_write,
        address => address,
        I_data => I_data,
        O_data => O_data
    );
    
    process (clk)
    begin
        if rising_edge(clk) then
            -- Instruction fetch
            for stage in 1 to 5 loop
                -- Instruction fetch
                if stage = 1 then
                    if PC+32 <= MEM_SIZE then
                        PC <= PC + 32;
                    else
                        done <= '1';
                    end if;
                    if done = '0' then
                        instr <= input((PC + 31) downto PC);
                    end if;
                    
                -- Instruction decode
                elsif stage = 2 and Stall = '0' then
                    -- Zero out and/or set inputs
                    -- We will reset others as needed
                    sel_A <= Rn;
                    sel_D_1 <= Rd;
                    srcB <= '0';
                    MemWrite <= '0';
                    MemRead <= '0';
                    srcAddr <= '0';
                    Reg2Loc <= '0';
                    RegWrite <= '0';
                    srcShamt <= '0';
                    SetFlags <= '0';
                
                    -- R-format instructons
                    case (R_opcode) is
                        -- Add
                        when "10001011000" =>
                            sel_A <= Rm;
                            sel_B <= Rn;
                            ALU_Op1 <= "0010";
                            RegWrite <= '1';
                            
                        -- SUB
                        when "11001011000" =>
                            sel_A <= Rm;
                            sel_B <= Rn;
                            ALU_Op1 <= "0110";
                            RegWrite <= '1';
                        
                        -- AND
                        when "10001010000" =>
                            sel_A <= Rm;
                            sel_B <= Rn;
                            ALU_Op1 <= "0000";
                            RegWrite <= '1';
                        
                        -- OR
                        when "10101010000" =>
                            sel_A <= Rm;
                            sel_B <= Rn;
                            ALU_Op1 <= "0001";
                            RegWrite <= '1';
                        
                        -- LSL
                        when "11010011011" =>
                            srcShamt <= '1';
                            ALU_Op1 <= "1100";
                            RegWrite <= '1';
                            shamt2 <= shamt;
                        
                        -- LSR
                        when "11010011010" =>
                            srcShamt <= '1';
                            ALU_Op1 <= "1101";
                            RegWrite <= '1';
                            shamt2 <= shamt;
                    
                        when others =>
                        
                    -- I format instructions
                    case (I_opcode) is
                        -- ADDI
                        when "1001000100" =>
                            Imm2 <= Imm;
                            srcB <= '1';
                            ALU_Op1 <= "0010";
                            RegWrite <= '1';
                            
                        -- SUBI
                        when "1101000100" =>
                            Imm2 <= Imm;
                            srcB <= '1';
                            ALU_Op1 <= "0110";
                            RegWrite <= '1';
                        
                        when others =>
                        
                    -- D format instructions
                    case (D_opcode) is
                        -- LDUR
                        when "11111000010" =>
                            ALU_Op1 <= "0010";
                            MemRead <= '1';
                            srcAddr <= '1';
                            DT_Address2 <= DT_Address;
                            RegWrite <= '1';
                        
                        -- STUR
                        when "11111000000" =>
                            ALU_Op1 <= "0010";
                            MemWrite <= '1';
                            srcAddr <= '1';
                            DT_Address2 <= DT_Address;
                            sel_B <= Rd;
                            
                        
                        -- MOV
                        when "11010010100" =>
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
                            PC <= PC + ((to_integer(signed(BR_address & BR_op)) - 1) * 32);
                            Stall <= '1';
                        
                        -- BR
                        when "010101" =>
                            case (BR_op) is
                                -- BEQ
                                when "0000" =>
                                    if flags(0) = '1' then
                                        PC <= PC + ((to_integer(signed(BR_address)) - 1) * 32);
                                        Stall <= '1';
                                    end if;
                                
                                -- BNE
                                when "0001" =>
                                    if flags(0) = '0' then
                                        PC <= PC + ((to_integer(signed(BR_address)) - 1) * 32);
                                        Stall <= '1';
                                    end if;
                                
                                -- BGT
                                when "1100" =>
                                    if flags(2) = '1' then
                                        PC <= PC + ((to_integer(signed(BR_address)) - 1) * 32);
                                        Stall <= '1';
                                    end if;
                                
                                -- BGE
                                when "1010" =>
                                    if flags(2) = '1' or flags(0) = '1' then
                                        PC <= PC + ((to_integer(signed(BR_address)) - 1) * 32);
                                        Stall <= '1';
                                    end if;
                                
                                -- BLT
                                when "1011" =>
                                    if flags(1) = '1' then
                                        PC <= PC + ((to_integer(signed(BR_address)) - 1) * 32);
                                        Stall <= '1';
                                    end if;
                                
                                -- BLE
                                when "1101" =>
                                    if flags(1) = '1' or flags(0) = '1' then
                                        PC <= PC + ((to_integer(signed(BR_address)) - 1) * 32);
                                        Stall <= '1';
                                    end if;
                                
                                -- TODO: The CPU should have a heart attack
                                when others =>
                            end case;
                        
                        when others =>
                    
                    -- CB format instructions
                    case (CB_opcode) is
                        -- CMP
                        when "10110101" =>
                            sel_A <= Rn;
                            sel_B <= Rd;
                            ALU_Op1 <= "0110";
                            SetFlags <= '1';
                        
                        -- CBZ
                        
                        when others =>
                    end case; -- case CB_opcode
                    end case; -- case B_opcode
                    end case; -- case D_opcode
                    end case; -- case I_opcode
                    end case; -- case R_opcode
                   
                -- Stall the decoder for branches 
                elsif stage = 2 and Stall = '1' then
                    Stall <= '0';
                
                -- Instruction execute
                elsif stage = 3 then
                    sel_D_2 <= sel_D_1;
                    RegWrite2 <= RegWrite;
                    MemWrite2 <= MemWrite;
                    MemRead2 <= MemRead;
                    MemData <= O_dataB;
                    SetFlags2 <= SetFlags;
                    
                    if Reg2Loc = '1' then
                        I_dataD <= O_dataA;
                    else
                        ALU_Op <= ALU_Op1;
                        A <= O_dataA;
                        if srcShamt = '1' then
                            B <= X"000000" & "00" & shamt2;
                        elsif srcB = '1' then
                            B <= "00000000000000000000" & Imm2;
                        elsif srcAddr = '1' then
                            B <=  "00000000000000000000000" & DT_Address2;
                        else
                            B <= O_dataB;
                        end if;
                    end if;
                    
                -- Memory read/write
                elsif stage = 4 then
                    if MemWrite2 = '1' then
                        Address <= Result;
                        I_data <= MemData;
                        I_write <= '1';
                    else
                        I_write <= '0';
                    end if;
                    
                    if MemRead2 = '1' then
                        Address <= Result;
                    end if;
                
                -- Register write_back
                elsif stage = 5 then
                    -- Write to the registers
                    if RegWrite2 = '1' then
                        if Reg2Loc = '0' then
                            if MemRead2 = '1' then
                                I_dataD <= O_data;
                            else
                                I_dataD <= Result;
                            end if;
                        end if;
                        sel_D <= sel_D_2;
                        I_enD <= '1';
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
                end if;
            end loop;
        end if;
    end process;
end Behavior;
