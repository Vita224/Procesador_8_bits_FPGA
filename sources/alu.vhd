library IEEE;
use IEEE.STD_LOGIC_1164.ALL; -- Manejo de señales lógicas
use IEEE.NUMERIC_STD.ALL; -- Funciones para operaciones aritméticas en VHDL
use IEEE.STD_LOGIC_UNSIGNED.ALL; -- Trabajar operaciones aritméticas y vectores sin signo
use IEEE.STD_LOGIC_ARITH.ALL; -- Trabajar operaciones aritméticas y vectores sin signo

entity alu is
    port(
        en: in STD_LOGIC; -- Habilita la salida de la ALU
        op: in STD_LOGIC; -- Operación a realizar (0 para suma, 1 para resta)
        reg_a_in: in STD_LOGIC_VECTOR(7 downto 0); -- Operando A (8 bits)
        reg_b_in: in STD_LOGIC_VECTOR(7 downto 0); -- Operando B (8 bits)
        carry_out: out STD_LOGIC; -- Indicador de acarreo en la operación
        zero_flag: out STD_LOGIC; -- Indica si el resultado es 0
        result_out: out STD_LOGIC_VECTOR(7 downto 0) -- El resultado de la operación (8 bits)
    );
end entity;

-- Aquí se define el tipo de arquitectura "behave" que describe el comportamiento de la ALU
architecture behave of alu is 
    signal result: STD_LOGIC_VECTOR(8 downto 0); -- Señal interna de 9 bits para incluir carry
	
begin    
    -- Proceso de operación: Se activa cuando reg_a_in, reg_b_in u op cambian
    process(reg_a_in, reg_b_in, op)
    begin
        if op = '0' then
            result <= ext(reg_a_in, 9) + ext(reg_b_in, 9);
        elsif op = '1' then
            result <= ext(reg_a_in, 9) - ext(reg_b_in, 9);
        end if;
    end process;

    -- Salidas
    carry_out <= result(8); -- Muestra el bit más significativo de result (posición 8) lo que indica si hubo un acarreo en la operación
    zero_flag <= '1' when result(7 downto 0) = "00000000" else '0'; -- Activa la señal a 1 si el resultado (sin considerar el bit de acarreo) es 00000000
    result_out <= result(7 downto 0) when en = '1' else (others => 'Z'); -- Muestra el resultado (los 8 bits menos significativos de result) si "en" es "1"; de lo contrario la salida se pone en alta impedancia.  
end behave;
