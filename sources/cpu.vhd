library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity cpu is 
    port(
        clock : in  STD_LOGIC;
        reset : in  STD_LOGIC;
        RxD   : in  STD_LOGIC;
        op    : out STD_LOGIC_VECTOR(7 downto 0)
    );
end entity;

architecture behave of cpu is

    --------------------------------------------------------------------------
    -- COMPONENTES
    --------------------------------------------------------------------------
    component pc is
        port(
            clock  : in  STD_LOGIC;
            reset  : in  STD_LOGIC;
            en     : in  STD_LOGIC;
            oe     : in  STD_LOGIC;
            ld     : in  STD_LOGIC;
            input  : in  STD_LOGIC_VECTOR(3 downto 0);
            output : out STD_LOGIC_VECTOR(3 downto 0)
        );
    end component;

    component reg is
        port(
            clock      : in  STD_LOGIC;
            reset      : in  STD_LOGIC;
            out_en     : in  STD_LOGIC;
            load       : in  STD_LOGIC;
            input      : in  STD_LOGIC_VECTOR(7 downto 0);
            output     : out STD_LOGIC_VECTOR(7 downto 0);
            output_alu : out STD_LOGIC_VECTOR(7 downto 0)
        );
    end component;

    component mem is
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
    end component;

    component mar is
        port(
            clock  : in  STD_LOGIC;
            reset  : in  STD_LOGIC;
            load   : in  STD_LOGIC;
            input  : in  STD_LOGIC_VECTOR(3 downto 0);
            output : out STD_LOGIC_VECTOR(3 downto 0)
        );
    end component;

    component alu is
        port(
            en        : in  STD_LOGIC;
            op        : in  STD_LOGIC;
            reg_a_in  : in  STD_LOGIC_VECTOR(7 downto 0);
            reg_b_in  : in  STD_LOGIC_VECTOR(7 downto 0);
            carry_out : out STD_LOGIC;
            zero_flag : out STD_LOGIC;
            result_out: out STD_LOGIC_VECTOR(7 downto 0)
        );
    end component;

    component control_unit is
        port(
            clock : in  STD_LOGIC;
            reset : in  STD_LOGIC;
            instr : in  STD_LOGIC_VECTOR(3 downto 0);
            do    : out STD_LOGIC_VECTOR(16 downto 0)
        );
    end component;

    --------------------------------------------------------------------------
    -- SEÑALES INTERNAS
    --------------------------------------------------------------------------
    signal main_bus              : STD_LOGIC_VECTOR(7 downto 0);
    signal cu_out_sig            : STD_LOGIC_VECTOR(16 downto 0);
    signal instr_out_sig         : STD_LOGIC_VECTOR(7 downto 0);
    signal instr_out             : STD_LOGIC_VECTOR(3 downto 0);

    signal pc_en_sig, pc_oe_sig, pc_ld_sig         : STD_LOGIC;
    signal mar_ld_sig                               : STD_LOGIC;
    signal mem_ld_sig, mem_oe_sig                   : STD_LOGIC;
    signal reg_a_ld_sig, reg_a_oe_sig               : STD_LOGIC;
    signal reg_b_ld_sig, reg_b_oe_sig               : STD_LOGIC;
    signal reg_op_ld_sig, reg_op_oe_sig             : STD_LOGIC;
    signal instr_ld_sig, instr_oe_sig               : STD_LOGIC;
    signal alu_en_sig, alu_op_sig                   : STD_LOGIC;

    signal mar_mem_sig    : STD_LOGIC_VECTOR(3 downto 0);
    signal mem_in_bus     : STD_LOGIC_VECTOR(7 downto 0);
    signal mem_addr       : STD_LOGIC_VECTOR(3 downto 0);
    signal reg_a_alu      : STD_LOGIC_VECTOR(7 downto 0);
    signal reg_b_alu      : STD_LOGIC_VECTOR(7 downto 0);

    -- Señales para modo lento y programa cargado
    signal slow_mode_sig     : STD_LOGIC;
    signal program_ready_sig : STD_LOGIC;

    -- Divisor de reloj
    signal slow_counter : integer := 0;
    signal slow_clk     : STD_LOGIC := '0';
    signal cpu_clk      : STD_LOGIC;

begin

    --------------------------------------------------------------------------
    -- Divisor de reloj (solo si slow_mode = '1')
    --------------------------------------------------------------------------
    process(clock, reset)
    begin
        if reset = '1' then
            slow_counter <= 0;
            slow_clk     <= '0';
        elsif rising_edge(clock) then
            if slow_mode_sig = '1' then
                if slow_counter = 2_999_999 then
                    slow_counter <= 0;
                    slow_clk     <= not slow_clk;
                else
                    slow_counter <= slow_counter + 1;
                end if;
            else
                slow_clk <= clock;
            end if;
        end if;
    end process;

    -- Selección de reloj
    cpu_clk <= slow_clk when slow_mode_sig = '1' else clock;

    --------------------------------------------------------------------------
    -- INSTANCIAS
    --------------------------------------------------------------------------
    pc_instr: pc port map(
        clock  => cpu_clk,
        reset  => reset,
        en     => pc_en_sig and program_ready_sig,
        oe     => pc_oe_sig,
        ld     => pc_ld_sig,
        input  => main_bus(3 downto 0),
        output => main_bus(3 downto 0)
    );

    cu_instr: control_unit port map(
        clock => not cpu_clk,
        reset => reset,
        instr => instr_out,
        do    => cu_out_sig
    );

    mar_instr: mar port map(
        clock  => cpu_clk,
        reset  => reset,
        load   => mar_ld_sig,
        input  => main_bus(3 downto 0),
        output => mar_mem_sig
    );

    mem_instr: mem port map(
        reset         => reset,
        clock         => clock,
        load          => mem_ld_sig,
        oe            => mem_oe_sig,
        addr_in       => mem_addr,
        data_in       => mem_in_bus,
        data_out      => main_bus,
        RxD           => RxD,
        slow_mode     => slow_mode_sig,
        program_ready => program_ready_sig
    );

    instr_reg_instr: reg port map(
        clock      => cpu_clk,
        reset      => reset,
        out_en     => instr_oe_sig,
        load       => instr_ld_sig,
        input      => main_bus,
        output     => open,
        output_alu => instr_out_sig
    );

    reg_A_instr: reg port map(
        clock      => cpu_clk,
        reset      => reset,
        out_en     => reg_a_oe_sig,
        load       => reg_a_ld_sig,
        input      => main_bus,
        output     => main_bus,
        output_alu => reg_a_alu
    );

    reg_B_instr: reg port map(
        clock      => cpu_clk,
        reset      => reset,
        out_en     => reg_b_oe_sig,
        load       => reg_b_ld_sig,
        input      => main_bus,
        output     => main_bus,
        output_alu => reg_b_alu
    );

    reg_op_instr: reg port map(
        clock      => cpu_clk,
        reset      => reset,
        out_en     => reg_op_oe_sig,
        load       => reg_op_ld_sig,
        input      => main_bus,
        output     => open,
        output_alu => op
    );

    alu_instr: alu port map(
        en         => alu_en_sig,
        op         => alu_op_sig,
        reg_a_in   => reg_a_alu,
        reg_b_in   => reg_b_alu,
        carry_out  => open,
        zero_flag  => open,
        result_out => main_bus
    );

    --------------------------------------------------------------------------
    -- Conexiones internas
    --------------------------------------------------------------------------
    mem_addr        <= mar_mem_sig;
    mem_in_bus      <= main_bus;
    instr_out       <= instr_out_sig(7 downto 4);
    main_bus(3 downto 0) <= instr_out_sig(3 downto 0) when instr_oe_sig = '1' else (others => 'Z');

    -- Señales de control
    pc_en_sig     <= cu_out_sig(11);
    pc_ld_sig     <= cu_out_sig(10);
    pc_oe_sig     <= cu_out_sig(9);
    mar_ld_sig    <= cu_out_sig(8);
    mem_ld_sig    <= cu_out_sig(7);
    mem_oe_sig    <= cu_out_sig(6);
    reg_a_ld_sig  <= cu_out_sig(5);
    reg_a_oe_sig  <= cu_out_sig(4);
    reg_b_ld_sig  <= cu_out_sig(3);
    reg_b_oe_sig  <= cu_out_sig(2);
    instr_ld_sig  <= cu_out_sig(1);
    instr_oe_sig  <= cu_out_sig(0);
    alu_en_sig    <= cu_out_sig(12);
    alu_op_sig    <= cu_out_sig(13);
    reg_op_ld_sig <= cu_out_sig(15);
    reg_op_oe_sig <= cu_out_sig(14);

end behave;

