library IEEE;
library STD;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.STD_LOGIC_TEXTIO.ALL;
use STD.TEXTIO.ALL;

entity mem is
    port(
        clock: in STD_LOGIC; -- Señal de reloj
        load: in STD_LOGIC; -- Señal de carga (escritura)
        oe: in STD_LOGIC; -- Señal de habilitación de salida (lectura)
        data_in: in STD_LOGIC_VECTOR(7 downto 0); -- Datos de entrada (8 bits)
        addr_in: in STD_LOGIC_VECTOR(3 downto 0); -- Dirección de entrada (4 bits)
        data_out: out STD_LOGIC_VECTOR(7 downto 0) -- Datos de salida (8 bits)
    );
end entity;

-- Arquitectura --
architecture behave of mem is -- Aquí está la implementación de cómo funciona este módulo
    type mem_type is array(0 to 15) of STD_LOGIC_VECTOR(7 downto 0); -- Tipo de datos definido como un arreglo de 16 palabras de 8 bits cada una, simulando una memoria con 16 ubicaciones
    signal do_i: STD_LOGIC_VECTOR(7 downto 0); -- Señal interna para gestionar la salida de datos antes de asignarlos a data_out
    signal mem_obj: mem_type; -- Señal que actúa como la memoria de datos
	
begin

    -- SUMA
    -- ubi (0000)0E = 0000 1110 LDA
    -- ubi (0001)2F = 0010 1111 ADD
    -- ubi (0010)5E = 0101 1110 OUT
    -- ubi (0011)60 = 0110 0000 HLT

    -- RESTA 
    -- ubi (0000)0E = 0000 1110 LDA
    -- ubi (0001)3F = 0011 1111 SUB
    -- ubi (0010)5E = 0101 1110 OUT
    -- ubi (0011)60 = 0110 0000 HLT

    -- CONTADOR
    -- ubi (0000)0E = 0000 1110 LDA
    -- ubi (0001)2F = 0010 1111 ADD
    -- ubi (0010)1E = 0001 1110 instr REG
    -- ubi (0011)5E = 0101 1110 OUT
    -- ubi (0100)41 = 0100 0001 JMP

    -- Escritura en memoria
    process(clock)
    begin
        if rising_edge(clock) then
            if load = '1' then
                mem_obj(to_integer(UNSIGNED(addr_in))) <= data_in;
            end if;
        end if;
    end process;

    -- Lectura combinacional
    do_i <= mem_obj(to_integer(UNSIGNED(addr_in)));
    -- Salida controlada por oe
    data_out <= do_i when oe = '1' else (others => 'Z');

end behave;

-- Este módulo mem actúa como una memoria simple de 16 ubicaciones, donde cada ubicación puede almacenar un dato de 8 bits. La escritura ocurre en el flanco de subida del reloj cuando load está activado, y la lectura depende de la señal oe.
