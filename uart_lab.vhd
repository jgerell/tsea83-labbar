library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.all;


entity uart_lab is
    Port ( clk  : in std_logic;     -- system clock
           btnC : in std_logic;     -- reset button
           RsRx : in std_logic;     -- UART RS2323 Rx
           seg  : out std_logic_vector(6 downto 0);   -- 7-seg, segments
           dp   : out std_logic;                      -- 7-seg, decimal point
           an : out std_logic_vector (3 downto 0));   -- 7-seg, anode
end uart_lab;

architecture behavioral of uart_lab is
    
  component leddriver
    Port ( clk  : in std_logic;     -- system clock
           seg  : out std_logic_vector(6 downto 0);   -- 7-seg, segments
           dp   : out std_logic;                      -- 7-seg, decimal point
           an : out std_logic_vector(3 downto 0);     -- 7-seg, anode
           hex4 : in std_logic_vector(15 downto 0));  -- four HEX-digits
    end component;

    signal sreg : std_logic_vector(9 downto 0) := B"0_00000000_0";  -- 10 bit shift register
    signal hex4 : std_logic_vector(15 downto 0) := X"0000";  
    signal rx1,rx2 : std_logic;     -- synchronizing flip-flops
    signal sp : std_logic;          -- shift pulse
    signal lp : std_logic;          -- load pulse
    signal pos : unsigned(1 downto 0);                -- HEX-digit position

    signal s1 : std_logic;          -- state of transmission
    signal start, stop : std_logic; -- start/stop transmission
    signal counter : unsigned(13 downto 0);           -- transmission length counter

    signal clear : std_logic;       -- synchronous clear

    -- Control unit signals
    signal bit_count : unsigned(3 downto 0);          -- counts 0..9 (10 bits)

begin

  clear <= btnC;

  -- *****************************
  -- * Synkronisering av RsRx    *
  -- *****************************
  process(clk)
  begin
    if rising_edge(clk) then
      if clear = '1' then
        rx1 <= '1';
        rx2 <= '1';
      else
        rx1 <= RsRx;
        rx2 <= rx1;
      end if;
    end if;
  end process;


  -- *****************************
  -- * Styrenhet (Control Unit)  *
  -- *****************************
  -- Detect falling edge on rx2 → start bit
  -- Count 868 clock cycles per bit; sample at mid-bit (434)
  -- After 10 bits received, assert lp for one cycle
  process(clk)
  begin
    if rising_edge(clk) then
      if clear = '1' then
        s1        <= '0';
        counter   <= (others => '0');
        bit_count <= (others => '0');
        sp        <= '0';
        lp        <= '0';
      elsif s1 = '0' then
        -- IDLE state: wait for falling edge (start bit)
        sp <= '0';
        lp <= '0';
        if rx1 = '0' and rx2 = '1' then
          -- Falling edge detected on synchronized input
          s1        <= '1';
          counter   <= (others => '0');
          bit_count <= (others => '0');
        end if;
      else
        -- RECEIVING state
        sp <= '0';
        lp <= '0';
        if counter = to_unsigned(867, 14) then
          -- End of bit period
          counter <= (others => '0');
          if bit_count = to_unsigned(9, 4) then
            -- All 10 bits received (start + 8 data + stop)
            lp        <= '1';
            s1        <= '0';
            bit_count <= (others => '0');
          else
            bit_count <= bit_count + 1;
          end if;
        elsif counter = to_unsigned(433, 14) then
          -- Mid-bit: generate shift pulse to sample data
          sp      <= '1';
          counter <= counter + 1;
        else
          counter <= counter + 1;
        end if;
      end if;
    end if;
  end process;


  -- *****************************
  -- * 10 bit skiftregister      *
  -- *****************************
  -- Shifts in rx2 from MSB side whenever sp is high
  -- After 10 shifts: sreg = stop & D7 & D6 & ... & D0 & start
  process(clk)
  begin
    if rising_edge(clk) then
      if clear = '1' then
        sreg <= (others => '0');
      elsif sp = '1' then
        sreg <= rx2 & sreg(9 downto 1);
      end if;
    end if;
  end process;


  -- *****************************
  -- * 2  bit positions-register *
  -- *****************************
  -- Increments pos each time a full character is loaded
  process(clk)
  begin
    if rising_edge(clk) then
      if clear = '1' then
        pos <= (others => '0');
      elsif lp = '1' then
        pos <= pos + 1;
      end if;
    end if;
  end process;


  -- *****************************
  -- * 16 bit display-register   *
  -- *****************************
  -- Demuxes the lower nibble of the received ASCII byte
  -- into one of four 4-bit slots in hex4, selected by pos.
  -- Data bits in sreg: sreg(8 downto 1) = D7..D0
  -- Lower nibble of ASCII digit = sreg(4 downto 1) = D3..D0
  process(clk)
  begin
    if rising_edge(clk) then
      if clear = '1' then
        hex4 <= (others => '0');
      elsif lp = '1' then
        case pos is
          when "00"   => hex4(3  downto 0)  <= sreg(4 downto 1);
          when "01"   => hex4(7  downto 4)  <= sreg(4 downto 1);
          when "10"   => hex4(11 downto 8)  <= sreg(4 downto 1);
          when others => hex4(15 downto 12) <= sreg(4 downto 1);
        end case;
      end if;
    end if;
  end process;


  -- *****************************
  -- * Multiplexad display       *
  -- *****************************
  led: leddriver port map (clk=>clk, seg=>seg, dp=>dp, an=>an, hex4=>hex4);
end Behavioral;

