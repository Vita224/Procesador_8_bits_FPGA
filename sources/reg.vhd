library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity reg is 
    port(
        clock: in STD_LOGIC; -- Señal de reloj
        reset: in STD_LOGIC; -- Señal de reinicio
        out_en: in STD_LOGIC; -- Señal para habilitar la salida
        load: in STD_LOGIC; -- Señal para cargar el valor de entrada
        input: in STD_LOGIC_VECTOR(7 downto 0); -- Entrada de datos de 8 bits
        output: out STD_LOGIC_VECTOR(7 downto 0); -- Salida habilitable de 8 bits
        output_alu: out STD_LOGIC_VECTOR(7 downto 0) -- Salida directa a la ALU de 8 bits
    );
end entity;

architecture behave of reg is
    signal stored_value: STD_LOGIC_VECTOR(7 downto 0) := (others => 'Z'); -- Declara una señal stored_value de 8 bits, que representa el valor almacenado en el registro

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

    output <= stored_value when out_en = '1' else (others => 'Z');
    output_alu <= stored_value;

end behave;
