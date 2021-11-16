library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity registers is
    port (
        sel_A   : in std_logic_vector(4 downto 0);      -- Register A (source 1)
        sel_B   : in std_logic_vector(4 downto 0);      -- Register B (source 2)
        sel_D   : in std_logic_vector(4 downto 0);      -- Register D
        I_dataD : in std_logic_vector(31 downto 0);     -- Data to write to the destination register
        I_enD   : in std_logic;                         -- Enable write
        O_dataA : out std_logic_vector(31 downto 0);    -- Output of register input A
        O_dataB : out std_logic_vector(31 downto 0)     -- Output of register input B
    );
end registers;

architecture Behavior of registers is
    type register_file is array (0 to 31) of std_logic_vector(31 downto 0);
    signal regs : register_file := (others => X"00000000");
begin
    process (sel_A, sel_B, sel_D, I_dataD, I_enD)
    begin
        -- Source A
        if unsigned(sel_A) = 31 then
            O_dataA <= X"00000005";
        else
            O_dataA <= regs(to_integer(unsigned(sel_A)));
        end if;
        
        -- Source 2
        if unsigned(sel_B) = 31 then
            O_dataB <= X"00000005";
        else
            O_dataB <= regs(to_integer(unsigned(sel_B)));
        end if;
            
        -- Write to the register if enable
        if I_enD = '1' then
            regs(to_integer(unsigned(sel_D))) <= I_dataD;
        end if;
    end process;
end Behavior;
