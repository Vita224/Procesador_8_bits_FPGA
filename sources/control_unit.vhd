library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity control_unit is
    Port ( 
        clock: in std_logic;
        reset: in std_logic;
        instr: in std_logic_vector(3 downto 0);
        do : out std_logic_vector(16 downto 0)
    );
end entity;

architecture behave of control_unit is
    signal counter: std_logic_vector(3 downto 0) := "0000";
	
begin
    count_proc: process(clock, reset)
    begin
        if reset = '1' then
            counter <= "0000";
        elsif rising_edge(clock) then
            if counter = "0110" then
                counter <= "0000";
            else
                counter <= std_logic_vector(unsigned(counter) + 1);
            end if;
        end if;
    end process;

-- Este componente se encarga de ejecutar los microcodigos, estos dependen de la instruccion almacenada en la RAM y del counter que se ejecuta en cada pulso de reloj.
-- Dando como salida una mascara que habilita o no la salida, entrada en los diferentes componentes de nuestro microcontrolador.
-- Cada microcodigo se utiliza por ejemplo para mover un valor de la RAM a uno de los registros, sumar y restar valores, realizar un bucle en las instrucciones y demas instrucciones que le programemos. 
-- 

    --|HLT|OUT_IN|OUT_OUT|ALU_OP_EN|ALU_EN|PC_EN|PC_IN|PC_OUT|
    --|16 |  15  |   14  |    13   |  12  |  11 | 10  |  9   |
    --|MAR_IN|RAM_IN|RAM_OUT|A_IN|A_OUT|B_IN|B_OUT|instr_I|instr_OUT|
    --|  8   |  7   |   6   |  5 |  4  |  3 |  2  |   1  |    0   |

    do <= "00000001100000000" when counter = "0000" else -- PC_OUT - MAR_IN (9 - 8)   300
          "00000100001000010" when counter = "0001" else -- PC_EN - RAM_OUT - instr_I (11 - 6 - 1)   842
          
          -- LDA
          "00000000000000001" when (counter = "0010" and instr = "0000") else -- instr_OUT (0)   1
          "00000000100000001" when (counter = "0011" and instr = "0000") else -- MAR_IN - instr_OUT (8 - 0)    101
          "00000000001100000" when (counter = "0100" and instr = "0000") else -- RAM_OUT - A_IN (6 - 5)     60
          "00000000000000000" when (counter = "0101" and instr = "0000") else
          "00000000000000000" when (counter = "0110" and instr = "0000") else
          
          -- STA 
          "00000000000000001" when (counter = "0010" and instr = "0001") else   -- instr_OUT
          "00000000100000001" when (counter = "0011" and instr = "0001") else   -- MAR_IN + instr_OUT
          "00000000010010000" when (counter = "0100" and instr = "0001") else   -- A_OUT + RAM_IN
          
          -- ADD         
          "00000000000000001" when (counter = "0010" and instr = "0010") else -- instr_OUT (0)
          "00000000100000001" when (counter = "0011" and instr = "0010") else -- MAR_IN - instr_OUT (8 - 0)
          "00000000001001000" when (counter = "0100" and instr = "0010") else -- RAM_OUT - B_IN (6 - 3)
          "00001000000000000" when (counter = "0101" and instr = "0010") else -- ALU_EN (12)
          "00001000000100000" when (counter = "0110" and instr = "0010") else -- ALU_EN - A_IN (12 - 5)
          
          -- SUB         
          "00000000000000001" when (counter = "0010" and instr = "0011") else -- instr_OUT (0)
          "00000000100000001" when (counter = "0011" and instr = "0011") else -- MAR_IN - instr_OUT (8 - 0)
          "00000000001001000" when (counter = "0100" and instr = "0011") else -- RAM_OUT - B_IN (6 - 3)
          "00010000000000000" when (counter = "0101" and instr = "0011") else -- ALU_OP_EN (13)
          "00011000000100000" when (counter = "0110" and instr = "0011") else -- ALU_OP_EN - ALU_EN - A_IN (13 - 12 - 5)
          
          -- JMP         
          "00000000000000001" when (counter = "0010" and instr = "0100") else -- instr_OUT (0)
          "00000010000000001" when (counter = "0011" and instr = "0100") else -- MAR_IN - instr_OUT (10 - 0)
          "00000000000000000" when (counter = "0100" and instr = "0100") else    
          "00000000000000000" when (counter = "0101" and instr = "0100") else    
          "00000000000000000" when (counter = "0110" and instr = "0100") else
          
          -- OUT         
          "00000000000000001" when (counter = "0010" and instr = "0101") else -- instr_OUT (0)
          "00000000000010000" when (counter = "0011" and instr = "0101") else -- A_OUT (4)
          "01000000000010000" when (counter = "0100" and instr = "0101") else -- OUT_IN - A_OUT (15 - 4)
          "00100000000000000" when (counter = "0110" and instr = "0101") else -- OUT_OUT (14)
          "00100000000000000" when (counter = "0110" and instr = "0101") else -- OUT_OUT (14)
          
          -- HLT         
          "10000000000000000" when (counter = "0010" and instr = "0110") else    
          "10000010000000000" when (counter = "0011" and instr = "0110") else
          "00000000000000000" when (counter = "0100" and instr = "0110") else    
          "00000000000000000" when (counter = "0101" and instr = "0110") else    
          "00000000000000000" when (counter = "0110" and instr = "0110");

end behave;
