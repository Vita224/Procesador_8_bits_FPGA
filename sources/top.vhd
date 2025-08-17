library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity top is
    port(
        clock_in : in std_logic;
        reset : in std_logic;
        program_selector : in std_logic_vector(1 downto 0);
        Anode_Activate : out std_logic_vector(3 downto 0);
        LED_out : out std_logic_vector(6 downto 0);
        RxD: in STD_LOGIC
    );
end top;

architecture Behavioral of top is
    signal cpu_op : std_logic_vector(7 downto 0);
    signal refresh_counter : std_logic_vector(19 downto 0) := (others => '0');
    signal LED_BCD : std_logic_vector(3 downto 0);
    signal LED_activating_counter : std_logic_vector(1 downto 0);

    component cpu is
        port(
            clock : in std_logic;
            reset : in std_logic;
            RxD: in STD_LOGIC;
            op: out STD_LOGIC_VECTOR(7 downto 0)
        );
    end component;

begin
    cpu_inst: cpu
        port map(
            clock => clock_in,
            reset => reset,
            RxD => RxD,
            op => cpu_op
        );

    process(clock_in)
    begin
        if rising_edge(clock_in) then
            refresh_counter <= refresh_counter + 1;
        end if;
    end process;

    LED_activating_counter <= refresh_counter(19 downto 18);

    process(LED_activating_counter)
    begin
        case LED_activating_counter is
            when "00" =>
                Anode_Activate <= "0111";
                LED_BCD <= "0000";
            when "01" =>
                Anode_Activate <= "1011";
                LED_BCD <= "0000";
            when "10" =>
                Anode_Activate <= "1101";
                LED_BCD <= cpu_op(7 downto 4);
            when "11" =>
                Anode_Activate <= "1110";
                LED_BCD <= cpu_op(3 downto 0);
            when others =>
                Anode_Activate <= "1111";
                LED_BCD <= "0000";
        end case;
    end process;

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
            when "1010" => LED_out <= "0000010"; -- A
            when "1011" => LED_out <= "1100000"; -- B
            when "1100" => LED_out <= "0110001"; -- C
            when "1101" => LED_out <= "1000010"; -- D
            when "1110" => LED_out <= "0110000"; -- E
            when "1111" => LED_out <= "0111000"; -- F
            when others => LED_out <= "1111111"; -- OFF
        end case;
    end process;

end Behavioral;
