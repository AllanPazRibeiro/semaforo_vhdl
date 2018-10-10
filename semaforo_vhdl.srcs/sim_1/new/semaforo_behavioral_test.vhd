
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
ENTITY tb_controle_de_semaforo_tb IS
END tb_controle_de_semaforo_tb;

ARCHITECTURE behavior OF tb_controle_de_semaforo_tb IS 
    COMPONENT controle_de_semaforo
     port ( 
           clk  : in STD_LOGIC; -- clock 
           sensor  : in STD_LOGIC; -- Sensor 
           reset: in STD_LOGIC; -- reset
           R1,Y1,G1,R2,Y2,G2: OUT STD_LOGIC -- saidas
         );
    END COMPONENT;
   signal sensor : std_logic := '0';
   signal clk : std_logic := '0';
   signal reset : std_logic := '0';
  --Outputs
   signal R1,Y1,G1,R2,Y2,G2: std_logic; -- saidas
   constant clk_period : time := 1 ns;
BEGIN
 controledesemaforotb: controle_de_semaforo PORT MAP (
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
  clk_process :process
   begin
    clk <= '0';
    wait for clk_period/2;
    clk <= '1';
    wait for clk_period/2;
  end process;
  
  stimulation_proc: process
     begin    
      reset <= '0';
      sensor <= '0';
      wait for clk_period*10;
      reset <= '1';
      wait for clk_period*2;
      sensor <= '1';
      wait for clk_period*10;
      sensor <= '0';
      wait for clk_period*2;
      sensor <= '1';
      wait for clk_period*120;
      sensor <= '0';
      wait for clk_period*2;
      sensor <= '1';
      
   end process;

END;