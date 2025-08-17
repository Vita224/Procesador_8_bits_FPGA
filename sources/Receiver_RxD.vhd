library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity Receiver_RxD is
    Port (
        clk_fpga : in std_logic;                    -- 100 MHz clock
        reset    : in std_logic;                    -- reset
        RxD      : in std_logic;                    -- serial input
        RxData   : out std_logic_vector(7 downto 0);-- received byte
        RxD_done : out std_logic                    -- indicates new byte received
    );
end Receiver_RxD;

architecture Behavioral of Receiver_RxD is

    constant clk_freq    : integer := 100_000_000;
    constant baud_rate   : integer := 9600;
    constant oversample  : integer := 16;
    constant baud_counter_max : integer := clk_freq / (baud_rate * oversample);

    type state_type is (idle, start_bit, data_bits, stop_bit);
    signal state       : state_type := idle;

    signal baud_counter : integer range 0 to baud_counter_max := 0;
    signal sample_tick  : std_logic := '0';
    signal sample_count : integer range 0 to oversample-1 := 0;
    signal bit_index    : integer range 0 to 7 := 0;
    signal data_reg     : std_logic_vector(7 downto 0) := (others => '0');
    signal RxD_sync     : std_logic_vector(1 downto 0) := (others => '1');

    signal RxD_done_int : std_logic := '0';

begin

    -- Salida sincronizada
    RxD_done <= RxD_done_int;

    -- Synchronize RxD to clk_fpga
    process(clk_fpga)
    begin
        if rising_edge(clk_fpga) then
            RxD_sync <= RxD_sync(0) & RxD;
        end if;
    end process;

    -- Baud rate generator
    process(clk_fpga)
    begin
        if rising_edge(clk_fpga) then
            if baud_counter = baud_counter_max - 1 then
                baud_counter <= 0;
                sample_tick <= '1';
            else
                baud_counter <= baud_counter + 1;
                sample_tick <= '0';
            end if;
        end if;
    end process;

    -- UART Receiver FSM
    process(clk_fpga)
    begin
        if rising_edge(clk_fpga) then
            if reset = '1' then
                state <= idle;
                RxData <= (others => '0');
                data_reg <= (others => '0');
                sample_count <= 0;
                bit_index <= 0;
                RxD_done_int <= '0';

            elsif sample_tick = '1' then
                RxD_done_int <= '0'; -- limpiar la señal al comienzo del ciclo

                case state is
                    when idle =>
                        if RxD_sync(1) = '0' then -- Start bit detected
                            state <= start_bit;
                            sample_count <= 0;
                        end if;

                    when start_bit =>
                        if sample_count = oversample/2 then
                            if RxD_sync(1) = '0' then
                                sample_count <= 0;
                                bit_index <= 0;
                                state <= data_bits;
                            else
                                state <= idle; -- False start bit
                            end if;
                        else
                            sample_count <= sample_count + 1;
                        end if;

                    when data_bits =>
                        if sample_count = oversample - 1 then
                            data_reg(bit_index) <= RxD_sync(1);
                            if bit_index = 7 then
                                state <= stop_bit;
                            else
                                bit_index <= bit_index + 1;
                            end if;
                            sample_count <= 0;
                        else
                            sample_count <= sample_count + 1;
                        end if;

                    when stop_bit =>
                        if sample_count = oversample - 1 then
                            state <= idle;
                            RxData <= data_reg;
                            RxD_done_int <= '1';  -- <<== Aquí marcamos que se recibió
                            sample_count <= 0;
                        else
                            sample_count <= sample_count + 1;
                        end if;
                end case;
            end if;
        end if;
    end process;

end Behavioral;
