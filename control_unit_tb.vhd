library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity cu_test is
--  Port ( );
end cu_test;

architecture Behavioral of cu_test is

component control_unit is 
	Port ( 
		clock: in std_logic;
		reset: in std_logic;
		instr: in std_logic_vector(3 downto 0);
		do : out std_logic_vector(16 downto 0)
	);
end component;

signal clk_sig: std_logic:='0';
signal inst_sig:std_logic_vector(3 downto 0):="0000";
signal rst_sig:std_logic;
signal control_op:std_logic_vector(16 downto 0);
constant clk_period : time := 10 ns;

signal pc_out:std_logic;
signal mar_in:std_logic;

begin

process
begin
clk_sig<='0';
wait for clk_period/2;
clk_sig<= not clk_sig;
wait for clk_period/2;
end process;

cu_inst: control_unit 
	port map(
		clock => clk_sig,
		reset => rst_sig,
		instr => inst_sig,
		do => control_op
	);

pc_out <= control_op(9);
mar_in <= control_op(8);

process
begin
rst_sig<='1';
wait for clk_period*5;
rst_sig<='0';
wait;
end process;

end Behavioral;
