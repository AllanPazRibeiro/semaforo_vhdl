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


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
USE IEEE.NUMERIC_STD.ALL;  

entity controle_de_semaforo is
 port ( 
        clk  : in STD_LOGIC; -- clock 
        sensor  : in STD_LOGIC; -- Sensor 
        reset: in STD_LOGIC; -- reset
        R1,Y1,G1,R2,Y2,G2: OUT STD_LOGIC -- saidas
      );
end controle_de_semaforo;
architecture semaforo of controle_de_semaforo is
signal counter_1s: std_logic_vector(27 downto 0):= x"0000000";
signal delay_count:std_logic_vector(3 downto 0):= x"0";
signal delay_25s, delay_3s_RS,delay_3s_RP, RED_LUZ_ENABLE, YELLOW_LUZ1_ENABLE,YELLOW_LUZ2_ENABLE: std_logic:='0';
signal clk_1s_enable: std_logic; -- Primeiro clock de enable 
type FSM_States is (RPGREEN_RSRED, RPYELLOW_RSRED, RPRED_RSGREEN, RPRED_RSYELLOW);
-- Estados de combinação para os semaforos
-- RPGREEN_RSRED : Rua principal verde e rua secundaria vermelho
-- RPYELLOW_RSRED : Rua principal amarelo e rua secundaria vermelho
-- RPRED_RSGREEN : Rua principal vermelho e rua secundaria verde
-- RPRED_RSYELLOW : Rua principal vermelho e rua secundaria amarelo
signal current_state, next_state: FSM_States;
begin
-- contador para setar o estado atual
process(clk,reset) 
begin
if(reset='0') then
 current_state <= RPGREEN_RSRED;
elsif(rising_edge(clk)) then 
 current_state <= next_state; 
end if; 
end process;
-- logica do fluxo de transito
process(current_state,sensor,delay_3s_RS,delay_3s_RP,delay_25s)
begin
case current_state is 
when RPGREEN_RSRED => -- Quando a luz é verde na rua principal e vermelha na rua secundaria
 RED_LUZ_ENABLE <= '0';-- disabilita o contador de luz vermelha
 YELLOW_LUZ1_ENABLE <= '0';-- disabilita o contador de luz amarela da rua principal
 YELLOW_LUZ2_ENABLE <= '0';-- disabilita o contador de luz amarela da rua secundaria
 R1 <= '0';
 Y1 <= '0';
 G1 <= '1';-- Luz verde para rua principal
 R2 <= '1';-- Luz vermelha para rua secundaria
 Y2 <= '0';
 G2 <= '0';
 if(sensor = '1') then -- se um carro for detectado pelo sensor
  next_state <= RPYELLOW_RSRED; 
  -- o proximo estado determinara que a luz da rua principal sera amarela 
 else 
  next_state <= RPGREEN_RSRED; 
  -- Caso contrario, a rua principal permanece em verde
 end if;
when RPYELLOW_RSRED => -- Quando a luz esta amarela na rua principal a luz permanece vermelha na rua secundaria
 R1 <= '0';
 Y1 <= '1';-- Luz amarela para rua principal
 G1 <= '0';
 R2 <= '1';-- Luz vermelha para rua secundaria
 Y2 <= '0';
 G2 <= '0'; 
 RED_LUZ_ENABLE <= '0';
 YELLOW_LUZ1_ENABLE <= '1';
 YELLOW_LUZ2_ENABLE <= '0';
 if(delay_3s_RP='1') then 
 -- if Yellow light delay counts to 3s, 
 -- turn Highway to RED, 
 -- Farm way to green light 
  next_state <= RPRED_RSGREEN; 
 else 
  next_state <= RPYELLOW_RSRED; 
  -- Remains Yellow on highway and Red on Farm way 
  -- if Yellow light not yet in 3s 
 end if;
when RPRED_RSGREEN => 
 R1 <= '1';-- Luz vermelha para rua principal
 Y1 <= '0';
 G1 <= '0';
 R2 <= '0';
 Y2 <= '0';
 G2 <= '1';-- Luz verde para rua secundaria 
 RED_LUZ_ENABLE <= '1';
 YELLOW_LUZ1_ENABLE <= '0';
 YELLOW_LUZ2_ENABLE <= '0';
 if(delay_25s='1') then
 -- Se a luz da rua principal esta vermelha na rua principal, a rua secundaria vai para amarelo
  next_state <= RPRED_RSYELLOW;
 else 
  next_state <= RPRED_RSGREEN; 
  -- Caso contrario, a luz fica vermelha na rua principal, e a rua secundaria permanece verde
 end if;
when RPRED_RSYELLOW =>
 R1 <= '1';-- Luz vermelha para rua principal
 Y1 <= '0';
 G1 <= '0';
 R2 <= '0';
 Y2 <= '1';-- Luz amarela para rua secundaria
 G2 <= '0';
 RED_LUZ_ENABLE <= '0';
 YELLOW_LUZ1_ENABLE <= '0';
 YELLOW_LUZ2_ENABLE <= '1';
 if(delay_3s_RS='1') then 
 -- Se o delay da luz amarela chega a 3s
 -- Luz verde para rua principal
 -- Luz vermelha para a rua secundaria
 next_state <= RPGREEN_RSRED;
 else 
 next_state <= RPRED_RSYELLOW;
 -- Caso contrario, tudo permanece o estado atual
 end if;
when others => next_state <= RPGREEN_RSRED;
end case;
end process;
-- Contador de delay para luz amarela e vermelha 
process(clk)
begin
if(rising_edge(clk)) then 
if(clk_1s_enable='1') then
 if(RED_LUZ_ENABLE='1' or YELLOW_LUZ1_ENABLE='1' or YELLOW_LUZ2_ENABLE='1') then
  delay_count <= delay_count + x"1";
  if((delay_count = x"24") and RED_LUZ_ENABLE ='1') then 
   delay_25s <= '1';
   delay_3s_RP <= '0';
   delay_3s_RS <= '0';
   delay_count <= x"0";
  elsif((delay_count = x"2") and YELLOW_LUZ1_ENABLE= '1') then
   delay_25s <= '0';
   delay_3s_RP <= '1';
   delay_3s_RS <= '0';
   delay_count <= x"0";
  elsif((delay_count = x"2") and YELLOW_LUZ2_ENABLE= '1') then
   delay_25s <= '0';
   delay_3s_RP <= '0';
   delay_3s_RS <= '1';
   delay_count <= x"0";
  else
   delay_25s <= '0';
   delay_3s_RP <= '0';
   delay_3s_RS <= '0';
  end if;
 end if;
 end if;
end if;
end process;
end semaforo;