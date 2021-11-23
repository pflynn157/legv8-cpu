library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity Memory is
    port (
        clk      : in std_logic;
        I_write  : in std_logic;
        data_len : in std_logic_vector(1 downto 0);
        address  : in std_logic_vector(31 downto 0);
        I_data   : in std_logic_vector(31 downto 0);
        O_data   : out std_logic_vector(31 downto 0)
    );
end Memory;

architecture Behavior of Memory is
    type index_array is array (0 to 3) of integer;
    type word_block is array(0 to 15) of std_logic_vector(7 downto 0);
    type mem_block is array (0 to 4095) of word_block;
    signal mem : mem_block;
begin
    process (clk, I_write, data_len, address, I_data)
        variable I_address : std_logic_vector(31 downto 0);
        variable block_indices : index_array;
        variable word_indices : index_array;
    begin
        for i in 0 to 3 loop
            if not is_X(address) then
                I_address := std_logic_vector(unsigned(address) + i);
                block_indices(i) := to_integer(unsigned(I_address(31 downto 4)));
                word_indices(i) := to_integer(unsigned(I_address(3 downto 0)));
                
                -- This is crude, but it does give some added protection
                if block_indices(i) >= 4096 or word_indices(i) >= 16 then
                    block_indices(i) := 0;
                    word_indices(i) := 0;
                end if;
            end if;
        end loop;
        
        case data_len is
            -- Read one word
            when "00" =>
                O_data <= X"000000" & mem(block_indices(0))(word_indices(0));
                if I_write = '1' then
                    mem(block_indices(0))(word_indices(0)) <= I_data(7 downto 0);
                end if;
            
            -- Read two words
            when "01" =>
                O_data <= X"0000" & mem(block_indices(1))(word_indices(1))
                                  & mem(block_indices(0))(word_indices(0));
                if I_write = '1' then
                    mem(block_indices(0))(word_indices(0)) <= I_data(7 downto 0);
                    mem(block_indices(1))(word_indices(1)) <= I_data(15 downto 8);
                end if;
            
            -- Read three words
            when "10" =>
                O_data <= X"00" & mem(block_indices(2))(word_indices(2))
                                & mem(block_indices(1))(word_indices(1))
                                & mem(block_indices(0))(word_indices(0));
                if I_write = '1' then
                    mem(block_indices(0))(word_indices(0)) <= I_data(7 downto 0);
                    mem(block_indices(1))(word_indices(1)) <= I_data(15 downto 8);
                    mem(block_indices(2))(word_indices(2)) <= I_data(23 downto 16);
                end if;
            
            -- Read four words
            when "11" =>
                O_data <=   mem(block_indices(3))(word_indices(3))
                          & mem(block_indices(2))(word_indices(2))
                          & mem(block_indices(1))(word_indices(1))
                          & mem(block_indices(0))(word_indices(0));
                if I_write = '1' then
                    mem(block_indices(0))(word_indices(0)) <= I_data(7 downto 0);
                    mem(block_indices(1))(word_indices(1)) <= I_data(15 downto 8);
                    mem(block_indices(2))(word_indices(2)) <= I_data(23 downto 16);
                    mem(block_indices(3))(word_indices(3)) <= I_data(31 downto 24);
                end if;
            
            when others =>
        end case;
    end process;
end Behavior;
