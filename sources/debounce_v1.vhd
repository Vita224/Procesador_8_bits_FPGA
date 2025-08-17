library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity debounce is
    generic(
        counter_size: INTEGER := 19 -- Un valor de 19 bits produce un tiempo de debounce de 10.5 ms con un reloj de 50 MHz
    );
    port(
        clock: in STD_LOGIC;  -- Reloj de entrada
        button: in STD_LOGIC;  -- Entrada de la señal que necesita debounce
        result: out STD_LOGIC -- Salida de la señal limpia (sin rebotes)
    );
end entity;

architecture logic of debounce is
    signal flipflops: STD_LOGIC_VECTOR(1 downto 0); -- Vector de dos flip-flops 
    signal counter_set: STD_LOGIC; -- Señal que indica cuándo reiniciar el contador
    signal counter_out: STD_LOGIC_VECTOR(counter_size downto 0) := (others => '0'); -- Incrementa con cada pulso de reloj hasta que la señal de entrada esté estable

begin
    counter_set <= flipflops(0) xor flipflops(1); -- Se activa cuando hay un cambio en la señal del botón
  
    process(clock)
    begin
        if (clock'EVENT and clock = '1') then
            flipflops(0) <= button; -- Se actualiza con la señal button
            flipflops(1) <= flipflops(0); -- Esto crea un retardo en el que se detectan cambios en button

            if (counter_set = '1') then 
                counter_out <= (others => '0');
            elsif (counter_out(counter_size) = '0') then 
                counter_out <= counter_out + 1;
            else 
                result <= flipflops(1);
            end if;    
        end if;
    end process;

end logic;
