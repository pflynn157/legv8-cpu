library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity ALU is
    port (
        clk    : in std_logic;
        A      : in std_logic_vector(31 downto 0);
        B      : in std_logic_vector(31 downto 0);
        ALU_Op : in std_logic_vector(3 downto 0);
        Zero   : out std_logic;
        Result : out std_logic_vector(31 downto 0)
    );
end ALU;

architecture Behavior of ALU is
    signal shift : std_logic_vector(2 downto 0) := "001";
    signal Rs1 : std_logic_vector(31 downto 0) := X"00000000";
begin
    process (clk)
    begin
        case ALU_Op is
            -- AND
            when "0000" =>
                Zero <= '0';
                Result <= A and B;
            
            -- OR
            when "0001" =>
                Zero <= '0';
                Result <= A or B;
            
            -- Add
            when "0010" =>
                Zero <= '0';
                Result <= std_logic_vector(unsigned(A) + unsigned(B));
            
            -- Sub
            when "0110" =>
                Rs1 <= std_logic_vector(unsigned(A) - unsigned(B));
                if Rs1 = X"00000000" then
                    Zero <= '1';
                else
                    Zero <= '0';
                end if;
                Result <= Rs1;
            
            -- Set on less than
            when "0111" =>
                if unsigned(A) < unsigned(B) then
                    Zero <= '1';
                else
                    Zero <= '0';
                end if;
            
            -- LSL
            when "1100" =>
                Zero <= '0';
                Result <= std_logic_vector(shift_left(unsigned(A), to_integer(unsigned(B))));
                
            -- LSR
            when "1101" =>
                Zero <= '0';
                Result <= std_logic_vector(shift_right(unsigned(A), to_integer(unsigned(B))));
            
            -- Trash
            when others =>
                Zero <= '0';
                Result <= X"00000000";
                
        end case;
    end process;
end Behavior;
