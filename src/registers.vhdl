library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity Registers is
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
end Registers;

architecture Behavior of Registers is
    type register_file is array (0 to 31) of std_logic_vector(31 downto 0);
    signal regs : register_file := (others => X"00000000");
begin
    process (clk, sel_A, sel_B, sel_D, I_dataD, I_enD)
    begin
        -- Source A
        if not is_X(sel_A) then
            if unsigned(sel_A) = 0 then
                O_dataA <= X"00000000";
            else
                O_dataA <= regs(to_integer(unsigned(sel_A)));
            end if;
        end if;
        
        -- Source B
        if not is_X(sel_B) then
            if unsigned(sel_B) = 0 then
                O_dataB <= X"00000000";
            else
                O_dataB <= regs(to_integer(unsigned(sel_B)));
            end if;
        end if;
        
        -- Write if enable
        if I_enD = '1' then
            regs(to_integer(unsigned(sel_D))) <= I_dataD;
        end if;
    end process;
end Behavior;