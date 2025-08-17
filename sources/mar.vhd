library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity mar is 
    port(
        clock: in STD_LOGIC; -- Señal de reloj de entrada
        reset: in STD_LOGIC; -- Señal de reset
        load: in STD_LOGIC; -- Señal de carga
        input: in STD_LOGIC_VECTOR(3 downto 0); -- Entrada de 4 bits que representa la dirección de memoria a almacenar
        output: out STD_LOGIC_VECTOR(3 downto 0) -- Salida de 4 bits que refleja el valor actualmente almacenado en el registro
    );
end entity;

-- Arquitectura --
architecture behave of mar is
    signal stored_value: STD_LOGIC_VECTOR(3 downto 0) := (others => 'Z'); -- Almacena el valor que se encuentra en el registro
	
begin

    process(clock, reset)
    begin
        if reset = '1' then
            stored_value <= (others => 'Z');
        elsif rising_edge(clock) then
            if load = '1' then
                stored_value <= input;
            end if;    
        end if;
    end process;
	
    output <= stored_value; -- La salida output siempre refleja el valor de stored_value
end behave;
