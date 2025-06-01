library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity top is
    port(
        clock_in: in STD_LOGIC; -- Reloj principal de la Basys3
        reset: in STD_LOGIC; -- Señal de reinicio
        mem_prog: in STD_LOGIC; -- Señal para habilitar la carga de memoria
        ext_mem_clock: in STD_LOGIC; -- Señal para habilitar la carga de memoria
        ext_mem_addr: in STD_LOGIC_VECTOR(3 downto 0); -- Direcciones y datos de entrada externos.
        ext_mem_bus: in STD_LOGIC_VECTOR(7 downto 0); -- Direcciones y datos de entrada externos.
        Anode_Activate: out STD_LOGIC_VECTOR(3 downto 0); -- Controla cuál de los 4 dígitos del display se activa 
        LED_out: out STD_LOGIC_VECTOR(6 downto 0) -- Controla los segmentos del display de 7 segmentos.
    );
end entity;

-- Arquitectura --
architecture behave of top is  
    signal reset_db: STD_LOGIC;
    signal mem_prog_db: STD_LOGIC;
    signal ext_mem_clock_db: STD_LOGIC;
    signal clock_10Hz: STD_LOGIC; -- Reloj principal de todo el microprocesador
    signal count: STD_LOGIC_VECTOR(20 downto 0) := (others => '0'); 
    signal refresh_counter: STD_LOGIC_VECTOR(19 downto 0) := (others => '0');
    signal displayed_number: STD_LOGIC_VECTOR(15 downto 0);
    signal LED_activating_counter: STD_LOGIC_VECTOR(1 downto 0);
    signal LED_BCD: STD_LOGIC_VECTOR(3 downto 0);
    signal cpu_op: STD_LOGIC_VECTOR(7 downto 0);

    -- instrancia de Componentes -- 
    component cpu is
        port(
            clock: in STD_LOGIC;
            reset: in STD_LOGIC;
            mem_prog: in STD_LOGIC;
            ext_mem_clock: in STD_LOGIC;
            ext_mem_addr: in STD_LOGIC_VECTOR(3 downto 0);
            ext_mem_bus: in STD_LOGIC_VECTOR(7 downto 0);
            op: out STD_LOGIC_VECTOR(7 downto 0)        
        );
    end component;

    component debounce is
        port(
            clock: in STD_LOGIC; 
            button: in STD_LOGIC; 
            result: out STD_LOGIC
        );
    end component;
	
begin
    debounce_reset: debounce port map(
        clock => clock_in,
        button => reset, 
        result => reset_db
    );

    debounce_mem_prog: debounce port map(
        clock => clock_in,
        button => mem_prog, 
        result => mem_prog_db
    );

    debounce_ext_mem_clock: debounce port map(
        clock => clock_in,
        button => ext_mem_clock, 
        result => ext_mem_clock_db
    );

    cpu_obj: cpu port map(
        clock => clock_10Hz,
        reset => reset_db, 
        mem_prog => mem_prog_db, 
        ext_mem_clock => ext_mem_clock_db, 
        ext_mem_addr => ext_mem_addr, 
        ext_mem_bus => ext_mem_bus, 
        op => cpu_op
    );

    -- Procesos de Control de Reloj para Microprocesador -- 
    process(clock_in)
    begin
        if rising_edge(clock_in) then
            if reset_db = '1' then
                count <= (others => '0');
            else
                count <= count + 1;
            end if;
        end if;
    end process;

    clock_10Hz <= count(20); -- Se utiliza el count(20) para reducir la frecuencia de operación en comparación al reloj de nuestro FPGA, al cambiar el valor podemos modificar la velocidad de ejecución de las instrrucciones. 

    process(clock_in, reset_db)
    begin 
        if reset_db = '1' then
            refresh_counter <= (others => '0');
        elsif rising_edge(clock_in) then
            refresh_counter <= refresh_counter + 1;
        end if;
    end process;

    -- Multiplexor de 4 a 1 para Activar los Dígitos del Display --
    LED_activating_counter <= refresh_counter(19 downto 18);
    -- 4-to-1 MUX to generate anode activating signals for 4 LEDs 

    process(LED_activating_counter)
    begin
        case LED_activating_counter is
            when "00" =>
                Anode_Activate <= "0111"; 
                -- activate LED1 and Deactivate LED2, LED3, LED4
                LED_BCD <= displayed_number(15 downto 12);
                -- the fireset hex digit of the 16-bit number
            when "01" =>
                Anode_Activate <= "1011"; 
                -- activate LED2 and Deactivate LED1, LED3, LED4
                LED_BCD <= displayed_number(11 downto 8);
                -- the second hex digit of the 16-bit number
            when "10" =>
                Anode_Activate <= "1101"; 
                -- activate LED3 and Deactivate LED2, LED1, LED4
                LED_BCD <= displayed_number(7 downto 4);
                -- the third hex digit of the 16-bit number
            when "11" =>
                Anode_Activate <= "1110"; 
                -- activate LED4 and Deactivate LED2, LED3, LED1
                LED_BCD <= displayed_number(3 downto 0);
                -- the fourth hex digit of the 16-bit number    
        end case;
    end process;

    -- Decodificación de LED_BCD para el Display de 7 Segmentos --
    process(LED_BCD)
    begin
        case LED_BCD is
            when "0000" => LED_out <= "0000001"; -- 0     
            when "0001" => LED_out <= "1001111"; -- 1 
            when "0010" => LED_out <= "0010010"; -- 2 
            when "0011" => LED_out <= "0000110"; -- 3 
            when "0100" => LED_out <= "1001100"; -- 4 
            when "0101" => LED_out <= "0100100"; -- 5 
            when "0110" => LED_out <= "0100000"; -- 6 
            when "0111" => LED_out <= "0001111"; -- 7 
            when "1000" => LED_out <= "0000000"; -- 8     
            when "1001" => LED_out <= "0000100"; -- 9
            when "1010" => LED_out <= "0000010"; -- a
            when "1011" => LED_out <= "1100000"; -- b
            when "1100" => LED_out <= "0110001"; -- C
            when "1101" => LED_out <= "1000010"; -- d
            when "1110" => LED_out <= "0110000"; -- E
            when "1111" => LED_out <= "0111000"; -- F
        end case;
    end process;

    displayed_number(15 downto 8) <= ext_mem_addr & "0000" when mem_prog_db = '1' else (others => '0');
    displayed_number(7 downto 0) <= ext_mem_bus when mem_prog_db = '1' else cpu_op;

end behave;

-- En este módulo unimos el modulo cpu con el modulo debounce y los elementos externos que utilizamos para ver al salida de los valores.
