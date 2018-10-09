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

entity traffic_light_controller is
 port ( sensor  : in STD_LOGIC; -- Sensor 
        clk  : in STD_LOGIC; -- clock 
        reset: in STD_LOGIC; -- reset
        luz_rp  : out STD_LOGIC_VECTOR(2 downto 0); -- light outputs of high way
        light_rs:    out STD_LOGIC_VECTOR(2 downto 0)-- light outputs of farm way
        R1,Y1,G1,R2,Y2,G2: OUT STD_LOGIC
   );
end traffic_light_controller;
architecture traffic_light of traffic_light_controller is
signal counter_1s: std_logic_vector(27 downto 0):= x"0000000";
signal delay_count:std_logic_vector(3 downto 0):= x"0";
signal delay_10s, delay_3s_F,delay_3s_H, RED_LIGHT_ENABLE, YELLOW_LUZ1_ENABLE,YELLOW_LUZ2_ENABLE: std_logic:='0';
signal clk_1s_enable: std_logic; -- Primeiro clock de enable 
type FSM_States is (RPGREEN_RSRED, RPYELLOW_RSRED, RPRED_RSGREEN, RPRED_RSYELLOW);
-- Estados de combinação para os semaforos
-- RPGREEN_RSRED : Rua principal verde e rua secundaria vermelho
-- RPYELLOW_RSRED : Rua principal amarelo e rua secundaria vermelho
-- RPRED_RSGREEN : Rua principal vermelho e rua secundaria verde
-- RPRED_RSYELLOW : Rua principal vermelho e rua secundaria amarelo
signal current_state, next_state: FSM_States;
begin

process(clk,reset) 
begin
if(reset='0') then
 current_state <= RPGREEN_RSRED;
elsif(rising_edge(clk)) then 
 current_state <= next_state; 
end if; 
end process;

process(current_state,sensor,delay_3s_F,delay_3s_H,delay_10s)
begin
case current_state is 
when RPGREEN_RSRED => -- Quando a luz é verde na rua principal e vermelha na rua secundaria
 RED_LIGHT_ENABLE <= '0';-- disabilita o contador de luz vermelha
 YELLOW_LUZ1_ENABLE <= '0';-- disabilita o contador de luz amarela da rua principal
 YELLOW_LUZ2_ENABLE <= '0';-- disabilita o contador de luz amarela da rua secundaria
 R1 <= "0";
 Y1 <= "0";
 G1 <= "1";-- Luz verde para rua principal
 R2 <= "1";-- Luz vermelha para rua secundaria
 Y2 <= "0";
 G2 <= "0";
 if(sensor = '1') then -- se um carro for detectado pelo sensor
  next_state <= RPYELLOW_RSRED; 
  -- o proximo estado determinara que a luz da rua principal sera amarela 
 else 
  next_state <= RPGREEN_RSRED; 
  -- Caso contrario, a rua principal permanece em verde
 end if;
when RPYELLOW_RSRED => -- When Yellow light on Highway and Red light on Farm way
 luz_rp <= "010";-- Yellow light on Highway
 light_rs <= "100";-- Red light on Farm way 
 RED_LIGHT_ENABLE <= '0';-- disable RED light delay counting
 YELLOW_LUZ1_ENABLE <= '1';-- enable YELLOW light Highway delay counting
 YELLOW_LUZ2_ENABLE <= '0';-- disable YELLOW light Farmway delay counting
 if(delay_3s_H='1') then 
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
 luz_rp <= "100";-- RED light on Highway 
 light_rs <= "001";-- GREEN light on Farm way 
 RED_LIGHT_ENABLE <= '1';-- enable RED light delay counting
 YELLOW_LUZ1_ENABLE <= '0';-- disable YELLOW light Highway delay counting
 YELLOW_LUZ2_ENABLE <= '0';-- disable YELLOW light Farmway delay counting
 if(delay_10s='1') then
 -- if RED light on highway is 10s, Farm way turns to Yellow
  next_state <= RPRED_RSYELLOW;
 else 
  next_state <= RPRED_RSGREEN; 
  -- Remains if delay counts for RED light on highway not enough 10s 
 end if;
when RPRED_RSYELLOW =>
 luz_rp <= "100";-- RED light on Highway 
 light_rs <= "010";-- Yellow light on Farm way 
 RED_LIGHT_ENABLE <= '0'; -- disable RED light delay counting
 YELLOW_LUZ1_ENABLE <= '0';-- disable YELLOW light Highway delay counting
 YELLOW_LUZ2_ENABLE <= '1';-- enable YELLOW light Farmway delay counting
 if(delay_3s_F='1') then 
 -- if delay for Yellow light is 3s,
 -- turn highway to GREEN light
 -- Farm way to RED Light
 next_state <= RPGREEN_RSRED;
 else 
 next_state <= RPRED_RSYELLOW;
 -- if not enough 3s, remain the same state 
 end if;
when others => next_state <= RPGREEN_RSRED; -- Green on highway, red on farm way 
end case;
end process;
-- Delay counts for Yellow and RED light  
process(clk)
begin
if(rising_edge(clk)) then 
if(clk_1s_enable='1') then
 if(RED_LIGHT_ENABLE='1' or YELLOW_LUZ1_ENABLE='1' or YELLOW_LUZ2_ENABLE='1') then
  delay_count <= delay_count + x"1";
  if((delay_count = x"9") and RED_LIGHT_ENABLE ='1') then 
   delay_10s <= '1';
   delay_3s_H <= '0';
   delay_3s_F <= '0';
   delay_count <= x"0";
  elsif((delay_count = x"2") and YELLOW_LUZ1_ENABLE= '1') then
   delay_10s <= '0';
   delay_3s_H <= '1';
   delay_3s_F <= '0';
   delay_count <= x"0";
  elsif((delay_count = x"2") and YELLOW_LUZ2_ENABLE= '1') then
   delay_10s <= '0';
   delay_3s_H <= '0';
   delay_3s_F <= '1';
   delay_count <= x"0";
  else
   delay_10s <= '0';
   delay_3s_H <= '0';
   delay_3s_F <= '0';
  end if;
 end if;
 end if;
end if;
end process;
-- create delay 1s
process(clk)
begin
if(rising_edge(clk)) then 
 counter_1s <= counter_1s + x"0000001";
 if(counter_1s >= x"0000003") then -- x"0004" is for simulation
 -- change to x"2FAF080" for 50 MHz clock running real FPGA
  counter_1s <= x"0000000";
 end if;
end if;
end process;
clk_1s_enable <= '1' when counter_1s = x"0003" else '0'; -- x"0002" is for simulation
-- x"2FAF080" for 50Mhz clock on FPGA
end traffic_light;