library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.NUMERIC_STD.ALL;

entity mem is
    Port (
        reset         : in  STD_LOGIC;
        clock         : in  STD_LOGIC;
        load          : in  STD_LOGIC;
        oe            : in  STD_LOGIC;
        addr_in       : in  STD_LOGIC_VECTOR(3 downto 0);
        data_in       : in  STD_LOGIC_VECTOR(7 downto 0);
        data_out      : out STD_LOGIC_VECTOR(7 downto 0);
        RxD           : in  STD_LOGIC;
        slow_mode     : out STD_LOGIC;
        program_ready : out STD_LOGIC
    );
end mem;

architecture Behavioral of mem is

    type memory_array is array (0 to 15) of STD_LOGIC_VECTOR(7 downto 0);
    signal mem_data : memory_array := (others => (others => '0'));

    component Receiver_RxD is
        Port (
            clk_fpga      : in  STD_LOGIC;
            reset         : in  STD_LOGIC;
            RxD           : in  STD_LOGIC;
            RxData        : out STD_LOGIC_VECTOR(7 downto 0);
            RxD_done      : out STD_LOGIC
        );
    end component;

    signal RxD_data  : STD_LOGIC_VECTOR(7 downto 0);
    signal RxD_done  : STD_LOGIC;
    signal RxD_done_sync : STD_LOGIC_VECTOR(1 downto 0) := "00";
    signal RxD_done_rise : STD_LOGIC := '0';

    -- Estados para carga UART
    type state_type is (IDLE, LOAD_DATA, LOAD_FLAG, WAIT_END);
    signal state : state_type := IDLE;
    signal byte_counter : integer range 0 to 15 := 0;

    -- Registros de salida
    signal slow_mode_reg     : STD_LOGIC := '0';
    signal program_ready_reg : STD_LOGIC := '0';

begin

    uart_rx: Receiver_RxD
        port map (
            clk_fpga => clock,
            reset    => reset,
            RxD      => RxD,
            RxData   => RxD_data,
            RxD_done => RxD_done
        );

    -- Flanco de subida de RxD_done
    process(clock)
    begin
        if rising_edge(clock) then
            RxD_done_sync <= RxD_done_sync(0) & RxD_done;
            if RxD_done_sync = "01" then
                RxD_done_rise <= '1';
            else
                RxD_done_rise <= '0';
            end if;
        end if;
    end process;

    -- Máquina de estados para cargar 16 bytes + flag + fin
    process(clock, reset)
    begin
        if reset = '1' then
            mem_data          <= (others => (others => '0'));
            byte_counter      <= 0;
            state             <= IDLE;
            slow_mode_reg     <= '0';
            program_ready_reg <= '0';

        elsif rising_edge(clock) then
            if RxD_done_rise = '1' then
                case state is
                    when IDLE =>
                        program_ready_reg <= '0';
                        if RxD_data = x"AA" then
                            byte_counter      <= 0;
                            slow_mode_reg     <= '0';
                            state             <= LOAD_DATA;
                        end if;

                    when LOAD_DATA =>
                        mem_data(byte_counter) <= RxD_data;
                        if byte_counter = 15 then
                            state <= LOAD_FLAG;
                        else
                            byte_counter <= byte_counter + 1;
                        end if;

                    when LOAD_FLAG =>
                        if RxD_data = x"01" then
                            slow_mode_reg <= '1';
                        else
                            slow_mode_reg <= '0';
                        end if;
                        state <= WAIT_END;

                    when WAIT_END =>
                        if RxD_data = x"FF" then
                            program_ready_reg <= '1';
                        end if;
                        state <= IDLE;
                end case;
            end if;

            -- Escritura desde CPU (memoria normal)
            if load = '1' then
                mem_data(to_integer(unsigned(addr_in))) <= data_in;
            end if;
        end if;
    end process;

    -- Lectura hacia CPU
    data_out <= mem_data(to_integer(unsigned(addr_in))) when oe = '1' else (others => 'Z');

    slow_mode     <= slow_mode_reg;
    program_ready <= program_ready_reg;

end Behavioral;
