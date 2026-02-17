-- TestBench Template 

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY uart_lab_tb IS
END uart_lab_tb;

ARCHITECTURE behavior OF uart_lab_tb IS 

  -- Component Declaration
  COMPONENT uart_lab
    Port ( clk  : in std_logic;     -- system clock
           btnC : in std_logic;     -- reset button
           RsRx : in std_logic;     -- UART RS2323 Rx
           seg  : out std_logic_vector(6 downto 0);   -- 7-seg, segments
           dp   : out std_logic;                      -- 7-seg, decimal point
           an : out std_logic_vector (3 downto 0));   -- 7-seg, anode
  END COMPONENT;

  SIGNAL clk : std_logic := '0';
  SIGNAL clear : std_logic := '0';
  signal RsRx : std_logic := '1';
  SIGNAL seg : std_logic_vector(6 downto 0);
  SIGNAL an :  std_logic_vector(3 downto 0);
  SIGNAL tb_running : boolean := true;
  -- alla bitar för 1234
  SIGNAL RsRx_data :  unsigned(0 to 39) := "0100011001001001100101100110010001011001";
BEGIN

  -- Component Instantiation
  uut: uart_lab PORT MAP(
    clk => clk,
    btnC => clear,
    RsRx => RsRx,
    seg => seg,
    an => an);


  clk_gen : process
  begin
    while tb_running loop
      clk <= '0';
      wait for 5 ns;
      clk <= '1';
      wait for 5 ns;
    end loop;
    wait;
  end process;

  

  stimuli_generator : process
    variable i : integer;
  begin
    -- Aktivera reset ett litet tag.
    clear <= '1';
    wait for 500 ns;

    wait until rising_edge(clk);        -- se till att reset släpps synkront
                                        -- med klockan
    clear <= '0';
    report "Reset released" severity note;
    wait for 1 us;
    
    for i in 0 to 39 loop
      RsRx <= RsRx_data(i);
      wait for 8.68 us;
    end loop;  -- i
    
    for i in 0 to 50000000 loop         -- Vänta ett antal klockcykler
      wait until rising_edge(clk);
    end loop;  -- i
    
    tb_running <= false;                -- Stanna klockan (vilket medför att inga
                                        -- nya event genereras vilket stannar
                                        -- simuleringen).
    wait;
  end process;
      
END;
