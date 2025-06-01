library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity cpu is 
    port(
        clock: in STD_LOGIC; -- Señal de reloj de la CPU
        reset: in STD_LOGIC; -- Señal de reinicio de la CPU
        mem_prog: in STD_LOGIC; -- Señal que indica si se está en modo de programación de memoria
        ext_mem_clock: in STD_LOGIC; -- Reloj externo para la memoria cuando se usa mem_prog
        ext_mem_addr: in STD_LOGIC_VECTOR(3 downto 0); -- Dirección externa de la memoria
        ext_mem_bus: in STD_LOGIC_VECTOR(7 downto 0); -- Bus de datos externo
        op: out STD_LOGIC_VECTOR(7 downto 0) -- Salida que contiene el resultado de la operación de la ALU
    );
end entity;

architecture behave of cpu is
    -- Declaración de Componentes --
    component pc is -- (Contador de Programa): Mantiene la dirección de la próxima instrrucción.
        port(
            clock: in STD_LOGIC;
            reset: in STD_LOGIC;
            en: in STD_LOGIC;
            oe: in STD_LOGIC;
            ld: in STD_LOGIC;
            input: in STD_LOGIC_VECTOR(3 downto 0);
            output: out STD_LOGIC_VECTOR(3 downto 0)
        );
    end component;

    component reg is -- (Registro): Se utiliza para almacenar datos. Este componente también tiene una salida output_alu para enviar datos a la ALU.
        port(
            clock: in STD_LOGIC;
            reset: in STD_LOGIC;
            out_en: in STD_LOGIC;
            load: in STD_LOGIC;
            input: in STD_LOGIC_VECTOR(7 downto 0);
            output: out STD_LOGIC_VECTOR(7 downto 0);
            output_alu: out STD_LOGIC_VECTOR(7 downto 0)
        );
    end component;

    component mem is -- (Memoria): Almacena instrrucciones y datos
        port(
            clock: in STD_LOGIC;
            load: in STD_LOGIC;
            oe: in STD_LOGIC;
            data_in: in STD_LOGIC_VECTOR(7 downto 0);
            addr_in: in STD_LOGIC_VECTOR(3 downto 0);
            data_out: out STD_LOGIC_VECTOR(7 downto 0)
        );
    end component;

    component mar is -- (Registro de Dirección de Memoria): Mantiene la dirección de memoria
        port(
            clock: in STD_LOGIC;
            reset: in STD_LOGIC;
            load: in STD_LOGIC;
            input: in STD_LOGIC_VECTOR(3 downto 0);
            output: out STD_LOGIC_VECTOR(3 downto 0)
        );
    end component;

    component alu is -- (Unidad Aritmética Lógica): Realiza operaciones aritméticas y lógicas
        port(
            en: in STD_LOGIC;
            op: in STD_LOGIC;
            reg_a_in: in STD_LOGIC_VECTOR(7 downto 0);
            reg_b_in: in STD_LOGIC_VECTOR(7 downto 0);
            carry_out: out STD_LOGIC;
            zero_flag: out STD_LOGIC;
            result_out: out STD_LOGIC_VECTOR(7 downto 0)
        );
    end component;

    component control_unit is -- Genera señales de control para coordinar las operaciones de la CPU
        port(
            clock: in STD_LOGIC;
            reset: in STD_LOGIC;
            instr: in STD_LOGIC_VECTOR(3 downto 0);
            do: out STD_LOGIC_VECTOR(16 downto 0)
        );
    end component;

    -- Señales Internas -- 
    signal clock_sig: STD_LOGIC;
    signal main_bus: STD_LOGIC_VECTOR(7 downto 0);
    signal hlt_sig: STD_LOGIC := '0';
	signal halt_sig: STD_LOGIC; -- Señal de control (16)

	-- Control Unit --
    signal instr_out: STD_LOGIC_VECTOR(3 downto 0);
    signal cu_out_sig: STD_LOGIC_VECTOR(16 downto 0);
	
	-- mar --
    signal mar_ld_sig: STD_LOGIC := '0'; -- Señal de control (8)
    signal mar_mem_sig: STD_LOGIC_VECTOR(3 downto 0);

	-- Program Counter --
    signal pc_en_sig: STD_LOGIC; -- Señal de control (11)
    signal pc_oe_sig: STD_LOGIC; -- Señal de control (9)
    signal pc_ld_sig: STD_LOGIC; -- Señal de control (10)

	-- mem --
	signal mem_clock: STD_LOGIC;
    signal mem_write_en: STD_LOGIC := '0';
	signal mem_oe_sig: STD_LOGIC := '0'; -- Señal de control (6)
	signal mem_in_bus: STD_LOGIC_VECTOR(7 downto 0);
    signal mem_addr: STD_LOGIC_VECTOR(3 downto 0);

	-- Microcontrolador --
	signal mem_ld_sig: STD_LOGIC := '0'; -- Señal de control (7)
	
	-- reg instr --
    signal instr_ld_sig: STD_LOGIC; -- Señal de control (1)
    signal instr_oe_sig: STD_LOGIC; -- Señal de control (0)
	signal instr_out_sig: STD_LOGIC_VECTOR(7 downto 0);
	
	-- reg a --
    signal reg_a_ld_sig: STD_LOGIC; -- Señal de control (5)
    signal reg_a_oe_sig: STD_LOGIC; -- Señal de control (4)
	
	-- reg b --
    signal reg_b_ld_sig: STD_LOGIC; -- Señal de control (3)
    signal reg_b_oe_sig: STD_LOGIC; -- Señal de control (2)
	
	-- reg op --
    signal reg_op_ld_sig: STD_LOGIC; -- Señal de control (15)
    signal reg_op_oe_sig: STD_LOGIC; -- Señal de control (14)
	
	-- alu --
    signal alu_en_sig: STD_LOGIC; -- Señal de control (12)
    signal alu_op_sig: STD_LOGIC; -- Señal de control (13)
	
	-- alu reg a y reg b --
	signal reg_a_alu: STD_LOGIC_VECTOR(7 downto 0);
    signal reg_b_alu: STD_LOGIC_VECTOR(7 downto 0);

begin

    -- instranciación de Componentes y Mapeo de Puertos --
    pc_instr: pc port map(
        clock => clock_sig,
        reset => reset,    
        en => pc_en_sig, -- Señal de control (11)
        oe => pc_oe_sig, -- Señal de control (9)
        ld => pc_ld_sig, -- Señal de control (10)
        input => main_bus(3 downto 0),
        output => main_bus(3 downto 0)
    );
------------------------------------------------------------------------------------------------------
    cu_instr: control_unit port map(
        clock => not clock,
        reset => reset,
        instr => instr_out,
        do => cu_out_sig
    );
------------------------------------------------------------------------------------------------------
    mar_instr: mar port map(
        clock => clock_sig,    
        reset => reset,
        load => mar_ld_sig, -- Señal de control (8)
        input => main_bus(3 downto 0),
        output => mar_mem_sig
    );
------------------------------------------------------------------------------------------------------
    mem_instr: mem port map(
        clock => mem_clock,
        load => mem_write_en,
        oe => mem_oe_sig, -- Señal de control (6)
        data_in => mem_in_bus,
        addr_in => mem_addr,
        data_out => main_bus
    );
------------------------------------------------------------------------------------------------------
    instr_reg_instr: reg port map(
        clock => clock_sig,        
        reset => reset,        
        load => instr_ld_sig, -- Señal de control (1)
        out_en => instr_oe_sig, -- Señal de control (0)
        input => main_bus,    
        output_alu => instr_out_sig    
    );
------------------------------------------------------------------------------------------------------
    reg_A_instr: reg port map(
        clock => clock_sig,        
        reset => reset,        
        load => reg_a_ld_sig, -- Señal de control (5)
        out_en => reg_a_oe_sig, -- Señal de control (4)
        input => main_bus,
        output => main_bus,    
        output_alu => reg_a_alu
    );
------------------------------------------------------------------------------------------------------
    reg_B_instr: reg port map(
        clock => clock_sig,        
        reset => reset,        
        load => reg_b_ld_sig, -- Señal de control (3)
        out_en => reg_b_oe_sig, -- Señal de control (2)
        input => main_bus,
        output => main_bus,    
        output_alu => reg_b_alu
    );
------------------------------------------------------------------------------------------------------
    reg_op_instr: reg port map(
        clock => clock_sig,        
        reset => reset,        
        load => reg_op_ld_sig, -- Señal de control (15)
        out_en => reg_op_oe_sig, -- Señal de control (14)
        input => main_bus,
        output => open,    
        output_alu => op
    );
------------------------------------------------------------------------------------------------------
    alu_instr: alu port map(
        en => alu_en_sig, -- Señal de control (12)
        op => alu_op_sig, -- Señal de control (13)
        reg_a_in => reg_a_alu,
        reg_b_in => reg_b_alu,
        carry_out => open,
        zero_flag => open,
        result_out => main_bus
    );
------------------------------------------------------------------------------------------------------
	-- señal clock --
	clock_sig <= clock and (not mem_prog) and (not hlt_sig);
	
	-- señales mem --
    mem_clock <= clock when (mem_prog = '0') else ext_mem_clock;
    mem_addr <= mar_mem_sig when (mem_prog = '0') else ext_mem_addr;
    mem_write_en <= mem_ld_sig when (mem_prog = '0') else '1'; -- Señal de control (7)
    mem_in_bus <= main_bus when (mem_prog = '0') else ext_mem_bus;

	-- señales reg --
    instr_out <= instr_out_sig(7 downto 4);
    main_bus(3 downto 0) <= instr_out_sig(3 downto 0) when instr_oe_sig = '1' else (others => 'Z');
------------------------------------------------------------------------------------------------------
    -- Lógica de Señales de Control --
    halt_sig <= cu_out_sig(16);
    reg_op_ld_sig <= cu_out_sig(15);
    reg_op_oe_sig <= cu_out_sig(14);
    alu_op_sig <= cu_out_sig(13);
    alu_en_sig <= cu_out_sig(12);
    pc_en_sig <= cu_out_sig(11);
    pc_ld_sig <= cu_out_sig(10);
    pc_oe_sig <= cu_out_sig(9);
	mar_ld_sig <= cu_out_sig(8);
	mem_ld_sig <= cu_out_sig(7);
	mem_oe_sig <= cu_out_sig(6);
	reg_a_ld_sig <= cu_out_sig(5);
	reg_a_oe_sig <= cu_out_sig(4);
	reg_b_ld_sig <= cu_out_sig(3);
	reg_b_oe_sig <= cu_out_sig(2);
	instr_ld_sig <= cu_out_sig(1);
	instr_oe_sig <= cu_out_sig(0);

end behave;

-- Aquí de declaran e instancian los componentes realizados.
-- Se crean señales para poder conectar internamente los componentes
-- Lo componentes se unen a traves del bus de datos, lo cual hace que tengan muchas variables en comun al momento de igualar los puertos con las señales internas creadas.
-- 
