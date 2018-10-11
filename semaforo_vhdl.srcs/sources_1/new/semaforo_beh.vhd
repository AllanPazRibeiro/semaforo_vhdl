----------------------------------------------------------------------------------
-- Company:
-- Engineer:
--
-- Create Date: 09.10.2018 19:25:23
-- Design Name:
-- Module Name: semaforo_beh - Behavioral
-- Project Name:
-- Target Devices:
-- Tool Versions:
-- Description:
--
-- Dependencies:
--
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
--
----------------------------------------------------------------------------------
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_UNSIGNED.ALL;
USE IEEE.NUMERIC_STD.ALL; 

ENTITY controle_de_semaforo IS
	PORT (
		clk : IN STD_LOGIC; -- clock
		sensor : IN STD_LOGIC; -- Sensor
		reset : IN STD_LOGIC; -- reset
		R1, Y1, G1, R2, Y2, G2 : OUT STD_LOGIC -- saidas
	);
END controle_de_semaforo;
ARCHITECTURE semaforo OF controle_de_semaforo IS
	SIGNAL counter_1s : std_logic_vector(27 DOWNTO 0) := x"0000000";
	SIGNAL delay_count : std_logic_vector(3 DOWNTO 0) := x"0";
	SIGNAL delay_25s, delay_3s_RS, delay_3s_RP, RED_LUZ_ENABLE, YELLOW_LUZ1_ENABLE, YELLOW_LUZ2_ENABLE : std_logic := '0';
	SIGNAL clk_1s_enable : std_logic; -- Primeiro clock de enable
	TYPE FSM_States IS (RPGREEN_RSRED, RPYELLOW_RSRED, RPRED_RSGREEN, RPRED_RSYELLOW);
	-- Estados de combinação para os semaforos
	-- RPGREEN_RSRED : Rua principal verde e rua secundaria vermelho
	-- RPYELLOW_RSRED : Rua principal amarelo e rua secundaria vermelho
	-- RPRED_RSGREEN : Rua principal vermelho e rua secundaria verde
	-- RPRED_RSYELLOW : Rua principal vermelho e rua secundaria amarelo
	SIGNAL current_state, next_state : FSM_States;
BEGIN
	-- contador para setar o estado atual
	PROCESS (clk, reset)
	BEGIN
		IF (reset = '1') THEN
			current_state <= RPGREEN_RSRED;
		ELSIF (rising_edge(clk)) THEN
			current_state <= next_state;
		END IF;
	END PROCESS;
	-- logica do fluxo de transito
	PROCESS (current_state, sensor, delay_3s_RS, delay_3s_RP, delay_25s)
		BEGIN
			CASE current_state IS
				WHEN RPGREEN_RSRED => -- Quando a luz é verde na rua principal e vermelha na rua secundaria
					RED_LUZ_ENABLE <= '0';-- disabilita o contador de luz vermelha
					YELLOW_LUZ1_ENABLE <= '0';-- disabilita o contador de luz amarela da rua principal
					YELLOW_LUZ2_ENABLE <= '0';-- disabilita o contador de luz amarela da rua secundaria
					R1 <= '0';
					Y1 <= '0';
					G1 <= '1';-- Luz verde para rua principal
					R2 <= '1';-- Luz vermelha para rua secundaria
					Y2 <= '0';
					G2 <= '0';
					IF (sensor = '1') THEN -- se um carro for detectado pelo sensor
						next_state <= RPYELLOW_RSRED;
						-- o proximo estado determinara que a luz da rua principal sera amarela
					ELSE
						next_state <= RPGREEN_RSRED;
						-- Caso contrario, a rua principal permanece em verde
					END IF;
				WHEN RPYELLOW_RSRED => -- Quando a luz esta amarela na rua principal a luz permanece vermelha na rua secundaria
					R1 <= '0';
					Y1 <= '1';-- Luz amarela para rua principal
					G1 <= '0';
					R2 <= '1';-- Luz vermelha para rua secundaria
					Y2 <= '0';
					G2 <= '0';
					RED_LUZ_ENABLE <= '0';
					YELLOW_LUZ1_ENABLE <= '1';
					YELLOW_LUZ2_ENABLE <= '0';
					IF (delay_3s_RP = '1') THEN
						-- Se o delay da luz amarela chegar a 3 segundos,
						-- Rua principal luz vermelha,
						-- Rua secundaria luz verde
						next_state <= RPRED_RSGREEN;
					ELSE
						next_state <= RPYELLOW_RSRED;
						-- Caso contrario a luz permanece amarela na Rua principal e vermelha na rua secundaria
						-- se a luz amarela n chegar ao delay de 3s
					END IF;
				WHEN RPRED_RSGREEN => 
					R1 <= '1';-- Luz vermelha para rua principal
					Y1 <= '0';
					G1 <= '0';
					R2 <= '0';
					Y2 <= '0';
					G2 <= '1';-- Luz verde para rua secundaria
					RED_LUZ_ENABLE <= '1';
					YELLOW_LUZ1_ENABLE <= '0';
					YELLOW_LUZ2_ENABLE <= '0';
					IF (delay_25s = '1') THEN
						-- Se a luz da rua principal esta vermelha na rua principal, a rua secundaria vai para amarelo
						next_state <= RPRED_RSYELLOW;
					ELSE
						next_state <= RPRED_RSGREEN;
						-- Caso contrario, a luz fica vermelha na rua principal, e a rua secundaria permanece verde
					END IF;
				WHEN RPRED_RSYELLOW => 
					R1 <= '1';-- Luz vermelha para rua principal
					Y1 <= '0';
					G1 <= '0';
					R2 <= '0';
					Y2 <= '1';-- Luz amarela para rua secundaria
					G2 <= '0';
					RED_LUZ_ENABLE <= '0';
					YELLOW_LUZ1_ENABLE <= '0';
					YELLOW_LUZ2_ENABLE <= '1';
					IF (delay_3s_RS = '1') THEN
						-- Se o delay da luz amarela chega a 3s
						-- Luz verde para rua principal
						-- Luz vermelha para a rua secundaria
						next_state <= RPGREEN_RSRED;
					ELSE
						next_state <= RPRED_RSYELLOW;
						-- Caso contrario, tudo permanece o estado atual
					END IF;
				WHEN OTHERS => next_state <= RPGREEN_RSRED;
			END CASE;
		END PROCESS;
		-- Contador de delay para luz amarela e vermelha
		PROCESS (clk)
			BEGIN
				IF (rising_edge(clk)) THEN
					IF (clk_1s_enable = '1') THEN
						IF (RED_LUZ_ENABLE = '1' OR YELLOW_LUZ1_ENABLE = '1' OR YELLOW_LUZ2_ENABLE = '1') THEN
							delay_count <= delay_count + x"1";
							IF ((delay_count = x"24") AND RED_LUZ_ENABLE = '1') THEN
								delay_25s <= '1';
								delay_3s_RP <= '0';
								delay_3s_RS <= '0';
								delay_count <= x"0";
							ELSIF ((delay_count = x"2") AND YELLOW_LUZ1_ENABLE = '1') THEN
								delay_25s <= '0';
								delay_3s_RP <= '1';
								delay_3s_RS <= '0';
								delay_count <= x"0";
							ELSIF ((delay_count = x"2") AND YELLOW_LUZ2_ENABLE = '1') THEN
								delay_25s <= '0';
								delay_3s_RP <= '0';
								delay_3s_RS <= '1';
								delay_count <= x"0";
							ELSE
								delay_25s <= '0';
								delay_3s_RP <= '0';
								delay_3s_RS <= '0';
							END IF;
						END IF;
					END IF;
				END IF;
			END PROCESS;
END semaforo;