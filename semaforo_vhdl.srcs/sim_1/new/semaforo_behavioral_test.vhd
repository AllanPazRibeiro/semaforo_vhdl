LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
ENTITY tb_controle_de_semaforo_tb IS
END tb_controle_de_semaforo_tb;

ARCHITECTURE behavior OF tb_controle_de_semaforo_tb IS
	COMPONENT controle_de_semaforo
		PORT (
			clk : IN STD_LOGIC; -- clock
			sensor : IN STD_LOGIC; -- Sensor
			reset : IN STD_LOGIC; -- reset
			R1, Y1, G1, R2, Y2, G2 : OUT STD_LOGIC -- saidas
		);
	END COMPONENT;
	SIGNAL sensor : std_logic := '0';
	SIGNAL clk : std_logic := '0';
	SIGNAL reset : std_logic := '0';
	--Outputs
	SIGNAL R1, Y1, G1, R2, Y2, G2 : std_logic; -- saidas
	CONSTANT clk_period : TIME := 80ns;
BEGIN
	controledesemaforotb : controle_de_semaforo
	PORT MAP(
		sensor => sensor, 
		clk => clk, 
		reset => reset, 
		R1 => R1, 
		Y1 => Y1, 
		G1 => G1, 
		R2 => R2, 
		Y2 => Y2, 
		G2 => G2
	);
	-- Clock process definitions
	clk_process : PROCESS
	BEGIN
		clk <= '0';
		WAIT FOR clk_period/2;
		clk <= '1';
		WAIT FOR clk_period/2;
	END PROCESS;
 
	stimulation_proc : PROCESS
	BEGIN
	    reset <= '0';
        sensor <= '0';
        wait for clk_period*1;
        sensor <= '1';
        reset <= '0';
        wait for clk_period*8;
        reset <= '1';
        sensor <= '0';
        wait for clk_period*1;
        sensor <= '1';
        reset <= '0';
        wait for clk_period*8;
        reset <= '1';
        sensor <= '0';        
        wait;
	END PROCESS;

END;