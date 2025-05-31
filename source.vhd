library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity Integrated_Top is
    Port (
clk  : in STD_LOGIC;                      -- 100 MHz system clock
        -- DHT11 connections
dht_pin  :inout STD_LOGIC;                   -- DHT11 data pin
        -- Digital Clock connections
center  : in STD_LOGIC;                      -- center button for clock mode selection
        right            : in STD_LOGIC;                      -- toggle between minutes and hours
        left             : in STD_LOGIC;                      -- toggle between minutes and hours
        up               : in STD_LOGIC;                      -- increment hours or minutes
        down             : in STD_LOGIC;                      -- decrement hours or minutes
        -- Output connections
        seg              : out STD_LOGIC_VECTOR(6 downto 0);  -- 7-segment display segments
an  : out STD_LOGIC_VECTOR(3 downto 0);  -- 7-segment display anodes
dp  : out STD_LOGIC;                     -- Decimal point
AMPM_indicator  : out STD_LOGIC;                     -- PM indicator for clock
clock_mode_led  : out STD_LOGIC;                     -- Clock mode indicator
        -- Selection switch
mode_select  : in STD_LOGIC;                      -- 0: DHT11, 1: Digital Clock
dht_temp_humid  : in STD_LOGIC;                      -- DHT11 switch: 0: Humidity, 1: Temperature
        -- 8-bit temperature/humidity output
dht_value_out  : out STD_LOGIC_VECTOR(7 downto 0)   -- 8-bit value output for LEDs or other display
    );
end Integrated_Top;

architecture Behavioral of Integrated_Top is

    -- Component declaration for DHT11_Top
    component DHT11_Top is
        generic (
c_clkfreq  : integer := 100_000_000;
c_sendtime  : integer := 50_000_000;
            WAIT_TIME   : integer := 2000000
        );
        Port (
clk  : in std_logic;
dht_pin  :inout std_logic;
temp_out  : out std_logic_vector(7 downto 0);
            seg         : out std_logic_vector(6 downto 0);
an  : out std_logic_vector(3 downto 0);
sw_sel  : in std_logic
        );
    end component;

    -- Component declaration for DigitalClock_12hrFormat
    component DigitalClock_12hrFormat is
        Port (
clk  : in STD_LOGIC;
center  : in STD_LOGIC;
            right                   : in STD_LOGIC;
            left                    : in STD_LOGIC;
            up                      : in STD_LOGIC;
            down                    : in STD_LOGIC;
            seg                     : out STD_LOGIC_VECTOR(6 downto 0);
an  : out STD_LOGIC_VECTOR(3 downto 0);
dp  : out STD_LOGIC;
AMPM_indicator_led  : out STD_LOGIC;
clock_mode_indicator_led: out STD_LOGIC 
        );
    end component;

    -- Internal signals
    signal dht_seg  : STD_LOGIC_VECTOR(6 downto 0);
    signal dht_an  : STD_LOGIC_VECTOR(3 downto 0);
    signal clock_seg  : STD_LOGIC_VECTOR(6 downto 0);
    signal clock_an  : STD_LOGIC_VECTOR(3 downto 0);
    signal clock_dp  : STD_LOGIC;
    signal temp_out  : STD_LOGIC_VECTOR(7 downto 0);

begin

    -- Instantiate the DHT11_Top module
    DHT11_inst: DHT11_Top
        generic map (
c_clkfreq  => 100_000_000,
c_sendtime => 50_000_000,
            WAIT_TIME  => 2000000
        )
        port map (
clk         =>clk,
dht_pin     =>dht_pin,
temp_out    =>temp_out,   -- This is the 8-bit output from DHT11
            seg         =>dht_seg,
            an          =>dht_an,
sw_sel      =>dht_temp_humid
        );

    -- Instantiate the DigitalClock_12hrFormat module
Clock_inst: DigitalClock_12hrFormat
        port map (
clk                     =>clk,
center                  =>center,
            right                   => right,
            left                    => left,
            up                      => up,
            down                    => down,
            seg                     =>clock_seg,
            an                      =>clock_an,
dp                      =>clock_dp,
AMPM_indicator_led      =>AMPM_indicator,
clock_mode_indicator_led=>clock_mode_led
        );

    -- Mode selection multiplexer
process(mode_select, dht_seg, dht_an, clock_seg, clock_an, clock_dp)
    begin
        if mode_select = '1' then
            -- Digital Clock mode
            seg <= clock_seg;
            an <= clock_an;
dp<= clock_dp;
        else
            -- DHT11 Sensor mode
            seg <= dht_seg;
            an <= dht_an;
dp<= '1';  -- Decimal point off for DHT11 display
        end if;
    end process;

    -- Always output the 8-bit temperature/humidity value
    -- This will be continuously updated regardless of display mode
dht_value_out<= temp_out;

end Behavioral;



library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity DHT11_Top is
    generic (
c_clkfreq  : integer := 100_000_000;


c_sendtime : integer := 50_000_000;
        WAIT_TIME  : integer := 2000000
    );
    Port (
clk  : in std_logic;
dht_pin :inout std_logic;
temp_out : out std_logic_vector(7 downto 0);
        seg     : out std_logic_vector(6 downto 0);
an  : out std_logic_vector(3 downto 0);
sw_sel  : in std_logic
    );
end DHT11_Top;

architecture Behavioral of DHT11_Top is

component  DHT11_Reader is
    generic (
c_clkfreq : integer := 100_000_000;
        WAIT_TIME : integer := 2000000
    );
    Port (
clk  : in std_logic;
dht_pin  :inout std_logic;
data_buffer : out std_logic_vector(39 downto 0);
data_ready  : out std_logic
    );
end component;

component Seven_Segment_Display is
    Port (
clk  : in std_logic;
data_to_display : in std_logic_vector(7 downto 0);
        seg             : out std_logic_vector(6 downto 0);
an  : out std_logic_vector(3 downto 0)
    );
end component;



    signal data_buffer_internal :std_logic_vector(39 downto 0);
    signal data_ready_internal :std_logic;
    signal send_timer : integer range 0 to 50_000_000 := 0;
    signal data_to_display :std_logic_vector(7 downto 0);

begin
    DHT11_reader_inst : DHT11_Reader
        port map (
clk =>clk,
dht_pin =>dht_pin,
data_buffer =>data_buffer_internal,
data_ready =>data_ready_internal
        );
Seven_Segment_Display_inst :Seven_Segment_Display
        port map (
clk =>clk,
data_to_display =>data_to_display,
            seg => seg,
            an => an
        );

    process(clk)
    begin
        if rising_edge(clk) then
            if send_timer = c_sendtime - 1 then
send_timer<= 0;

            else
send_timer<= send_timer + 1;

            end if;
        end if;

       if sw_sel = '1' then
data_to_display<= data_buffer_internal(23 downto 16); -- Temperature Integer
else
data_to_display<= data_buffer_internal(39 downto 32); -- Humidity Integer
end if;



temp_out<= data_to_display;

    end process;



end Behavioral;

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity DHT11_Reader is
    generic (
c_clkfreq : integer := 100_000_000;
        WAIT_TIME : integer := 2000000 -- 2sn
    );
    Port (
clk  : in std_logic;
dht_pin  :inout std_logic;
data_buffer : out std_logic_vector(39 downto 0);
data_ready  : out std_logic
    );
end DHT11_Reader;

architecture Behavioral of DHT11_Reader is
    type state_type_dht is (START, LEAVE_HIGH, DATA, LOW_DELAY, WAIT_BEFORE_RESTART);
    signal state_dht :state_type_dht := START;

    constant clk_divider : integer := 100;
    signal counter : integer := 0;
    signal clk_div : integer := 0;
    signal dht_data :std_logic := '1';
    signal buffer_index : integer := 0;
    signal last_state :std_logic := '0';
    signal bit_counter : integer range 0 to 79 := 0;
    signal bit_counter_high : integer range 0 to 39 := 0;
    signal bit_counter_low : integer range 0 to 39 := 0;
    signal j : integer range 0 to 39 := 0;
    signal high_time_r : UNSIGNED(7 DOWNTO 0) := (OTHERS => '0');
    signal low_time_r : UNSIGNED(7 DOWNTO 0) := (OTHERS => '0');

    TYPE std_logic_vector_array IS ARRAY (0 TO 39) OF std_logic_vector(7 DOWNTO 0);
    SIGNAL buffer_internal_high :std_logic_vector_array; -- 20 20 70 72 22 
    SIGNAL buffer_internal_low :std_logic_vector_array; -- 50 51 52 50 

    signal data_ready_internal :std_logic := '0';

begin
dht_pin<= '0' when dht_data = '0' else 'Z';
data_ready<= data_ready_internal;

    process(clk)
    begin
        if rising_edge(clk) then
            if clk_div<clk_divider then
clk_div<= clk_div + 1;
            else
clk_div<= 0;
                case state_dht is

                    when START =>
dht_data<= '0';
                        if counter < 18000 then
                            counter <= counter + 1;
                        else
                            counter <= 0;
state_dht<= LEAVE_HIGH;
dht_data<= '1';
                        end if;
                    when LEAVE_HIGH =>
                        if dht_pin = '0' then
                            counter <= counter + 1;
elsif counter > 80 then
state_dht<= LOW_DELAY;
                            counter <= 0;
                        end if;
                    when LOW_DELAY =>
                        if dht_pin = '1' then
                            counter <= counter + 1;
elsif counter > 80 then
state_dht<= DATA;
bit_counter<= 0;
buffer_index<= 0;
                            counter <= 0;
                        end if;
                    when DATA =>
                        IF bit_counter< 79 THEN -- 40 bit high 40 bit low 
                            IF dht_pin = '1' THEN
                                IF last_state = '0' THEN
buffer_internal_high(bit_counter_high) <= std_logic_vector(high_time_r); -- 20 70 20 20
high_time_r<= (OTHERS => '0');
bit_counter<= bit_counter + 1;
bit_counter_high<= bit_counter_high + 1;
                                    IF buffer_internal_high(j+1) > 50 THEN
data_buffer(j) <= '1'; -- 1 0 1 1 0
                                        j <= j + 1;
                                    ELSE
data_buffer(j) <= '0';
                                        j <= j + 1;
                                    END IF;
                                ELSE
high_time_r<= high_time_r + 1;
                                END IF;
                            ELSE
                                IF last_state = '1' THEN
buffer_internal_low(bit_counter_low) <= std_logic_vector(low_time_r);
low_time_r<= (OTHERS => '0');
bit_counter<= bit_counter + 1;
bit_counter_low<= bit_counter_low + 1;
                                ELSE
low_time_r<= low_time_r + 1;
                                END IF;
                            END IF;
last_state<= dht_pin;
                        ELSE
bit_counter<= 0;
bit_counter_low<= 0;
bit_counter_high<= 0;
                            j <= 0;
state_dht<= WAIT_BEFORE_RESTART;
data_ready_internal<= '1';
                        end if;
                    when WAIT_BEFORE_RESTART =>
                        if counter < WAIT_TIME then
                            counter <= counter + 1;
                        else
                            counter <= 0;
state_dht<= START;
data_ready_internal<= '0';
                        end if;
                end case;
            end if;
        end if;
    end process;
end Behavioral;

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity Seven_Segment_Display is
    Port (
clk  : in std_logic;
data_to_display : in std_logic_vector(7 downto 0);
        seg             : out std_logic_vector(6 downto 0);
an  : out std_logic_vector(3 downto 0)
    );
end Seven_Segment_Display;

architecture Behavioral of Seven_Segment_Display is
    signal active_digit :std_logic_vector(3 downto 0) := "1110";
    signal units_digit  :std_logic_vector(3 downto 0);
    signal tens_digit  :std_logic_vector(3 downto 0);
    signal hundreds_digit :std_logic_vector(3 downto 0);
    signal num_value  : integer range 0 to 255;
    signal scan_index  : integer range 0 to 2 := 0;
    signal scan_counter : integer range 0 to 1_000_000 := 0;
    signal div_counter  : integer range 0 to 100000 := 0;
    signal scan_clk  :std_logic := '0';

begin
    an <= active_digit;
num_value<= to_integer(unsigned(data_to_display));

units_digit<= std_logic_vector(to_unsigned(num_value mod 10, 4));
tens_digit<= std_logic_vector(to_unsigned((num_value / 10) mod 10, 4));
hundreds_digit<= std_logic_vector(to_unsigned((num_value / 100) mod 10, 4));

    process(scan_index)
    begin
        case scan_index is
            when 0 =>active_digit<= "1110";
            when 1 =>active_digit<= "1101";
            when 2 =>active_digit<= "1011";
            when others =>active_digit<= "1110";
        end case;
    end process;

    process (active_digit, units_digit, tens_digit, hundreds_digit)
    begin
        case active_digit is
            when "1110" =>
                case units_digit is
                    when "0000" => seg <= "1000000"; -- 0
                    when "0001" => seg <= "1111001"; -- 1
                    when "0010" => seg <= "0100100"; -- 2
                    when "0011" => seg <= "0110000"; -- 3
                    when "0100" => seg <= "0011001"; -- 4
                    when "0101" => seg <= "0010010"; -- 5
                    when "0110" => seg <= "0000010"; -- 6
                    when "0111" => seg <= "1111000"; -- 7
                    when "1000" => seg <= "0000000"; -- 8
                    when "1001" => seg <= "0010000"; -- 9
                    when others => seg <= "1000000";
                end case;
            when "1101" =>
                case tens_digit is
                    when "0000" => seg <= "1000000";
                    when "0001" => seg <= "1111001";
                    when "0010" => seg <= "0100100";
                    when "0011" => seg <= "0110000";
                    when "0100" => seg <= "0011001";
                    when "0101" => seg <= "0010010";
                    when "0110" => seg <= "0000010";
                    when "0111" => seg <= "1111000";
                    when "1000" => seg <= "0000000";
                    when "1001" => seg <= "0010000";
                    when others => seg <= "1000000";
                end case;
            when "1011" =>
                case hundreds_digit is
                    when "0000" => seg <= "1000000";
                    when "0001" => seg <= "1111001";
                    when "0010" => seg <= "0100100";
                    when "0011" => seg <= "0110000";
                    when "0100" => seg <= "0011001";
                    when "0101" => seg <= "0010010";
                    when "0110" => seg <= "0000010";
                    when "0111" => seg <= "1111000";
                    when "1000" => seg <= "0000000";
                    when "1001" => seg <= "0010000";
                    when others => seg <= "1000000";
                end case;
            when others => seg <= "1000000";
        end case;
    end process;

    process(clk)
    begin
        if rising_edge(clk) then
            if div_counter = 100000 - 1 then 
div_counter<= 0;
scan_clk<= not scan_clk; 
            else
div_counter<= div_counter + 1;
            end if;

            if scan_clk = '1' then 
                if scan_counter< 1000 then 
scan_counter<= scan_counter + 1;
                else
scan_counter<= 0;
scan_index<= (scan_index + 1) mod 3; 
                end if;
            end if;
        end if;
    end process;

end Behavioral;

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity DigitalClock_12hrFormat is
    Port (
clk : in STD_LOGIC;                      -- system clock 100 MHz
center : in STD_LOGIC;                   -- center button for clock mode selection
right : in STD_LOGIC;                    -- toggle between minutes and hours
left : in STD_LOGIC;                     -- toggle between minutes and hours
up : in STD_LOGIC;                       -- increment hours or minutes
down : in STD_LOGIC;                     -- decrement hours or minutes
seg : out STD_LOGIC_VECTOR(6 downto 0);  -- 7-segment display
an : out STD_LOGIC_VECTOR(3 downto 0);   -- enable 4 seven-segment displays
dp : out STD_LOGIC;
AMPM_indicator_led : out STD_LOGIC;      -- PM indicator
clock_mode_indicator_led : out STD_LOGIC -- Clock mode indicator
    );
end DigitalClock_12hrFormat;

architecture Behavioral of DigitalClock_12hrFormat is
    -- Clock divider
    signal counter : unsigned(31 downto 0) := (others => '0');
    constant max_count : integer := 100000000; -- 1Hz timing

    -- Time registers
    signal hrs : unsigned(5 downto 0) := to_unsigned(12, 6);
    signal min : unsigned(5 downto 0) := (others => '0');
    signal sec : unsigned(5 downto 0) := (others => '0');

    signal min_ones : STD_LOGIC_VECTOR(3 downto 0) := (others => '0');
    signal min_tens : STD_LOGIC_VECTOR(3 downto 0) := (others => '0');
    signal hrs_ones : STD_LOGIC_VECTOR(3 downto 0) := (others => '0');
    signal hrs_tens : STD_LOGIC_VECTOR(3 downto 0) := (others => '0');

    signal toggle : STD_LOGIC := '0'; -- 0: Minutes mode, 1: Hours mode

    -- Indicator LEDs
    signal pm : STD_LOGIC := '0';
    signal clock_mode : STD_LOGIC := '0';

    -- Clock modes
    constant display_time : STD_LOGIC := '0';
    constant set_time : STD_LOGIC := '1';
    signal current_mode : STD_LOGIC := set_time;

    -- Component declaration for Seven_Segment_Module
    component Seven_Segment_Module is
        Port (
clk : in STD_LOGIC;
min_ones : in STD_LOGIC_VECTOR(3 downto 0);
min_tens : in STD_LOGIC_VECTOR(3 downto 0);
hrs_ones : in STD_LOGIC_VECTOR(3 downto 0);
hrs_tens : in STD_LOGIC_VECTOR(3 downto 0);
seg : out STD_LOGIC_VECTOR(6 downto 0);
an : out STD_LOGIC_VECTOR(3 downto 0);
dp : out STD_LOGIC
        );
    end component;

begin
    -- Instantiate 7-segment display module
    SSM: Seven_Segment_Module
        port map (
clk =>clk,
min_ones =>min_ones,
min_tens =>min_tens,
hrs_ones =>hrs_ones,
hrs_tens =>hrs_tens,
            seg => seg,
            an => an,
dp =>dp
        );

    -- Assign indicator LEDs
AMPM_indicator_led<= pm;
clock_mode_indicator_led<= clock_mode;

    -- Main process
    process(clk)
        variable min_value : integer;
        variable hr_value : integer;
    begin
        if rising_edge(clk) then
            case current_mode is
                when display_time =>
                    if center = '1' then
clock_mode<= '0';
current_mode<= set_time;
                        counter <= (others => '0');
                        sec <= (others => '0');
                        toggle <= '0';
                    end if;

                    if counter <max_count then
                        counter <= counter + 1;
                    else
                        counter <= (others => '0');
                        sec <= sec + 1;
                    end if;

                when set_time =>
                    if center = '1' then
clock_mode<= '1';
current_mode<= display_time;
                    end if;

                    if counter < 25000000 then
                        counter <= counter + 1;
                    else
                        counter <= (others => '0');
                        -- Toggle selection between minutes and hours
                        if left = '1' or right = '1' then
                            toggle <= not toggle;
                        end if;

                        if toggle = '0' then -- Minutes mode
                            if up = '1' then
                                if min < 59 then
                                    min <= min + 1;
                                else
                                    min <= (others => '0');
                                end if;
                            end if;

                            if down = '1' then
                                if min > 0 then
                                    min <= min - 1;
                                else
                                    min <= to_unsigned(59, 6);
                                    if hrs > 1 then
                                        hrs <= hrs - 1;
                                    else
                                        hrs <= to_unsigned(12, 6);
                                    end if;
                                end if;
                            end if;
                        else -- Hours mode
                            if up = '1' then
                                if hrs = 12 then
                                    hrs <= to_unsigned(1, 6);
                                else
                                    hrs <= hrs + 1;
                                end if;
                            end if;

                            if down = '1' then
                                if hrs = 1 then
                                    hrs <= to_unsigned(12, 6);
                                else
                                    hrs <= hrs - 1;
                                end if;
                            end if;
                        end if;
                    end if;

                when others =>
current_mode<= set_time;
            end case;

            -- Time increment logic
            if sec >= 60 then
                sec <= (others => '0');
                min <= min + 1;
            end if;

            if min >= 60 then
                min <= (others => '0');
                if hrs = 12 then
                    hrs <= to_unsigned(1, 6);
                else
                    hrs <= hrs + 1;
                end if;
            end if;

            -- Convert time to 12-hour format
min_value := to_integer(min);
hr_value := to_integer(hrs);

min_ones<= std_logic_vector(to_unsigned(min_value mod 10, 4));
min_tens<= std_logic_vector(to_unsigned((min_value / 10) mod 10, 4));

            if hr_value< 12 then
hrs_ones<= std_logic_vector(to_unsigned(hr_value mod 10, 4));
hrs_tens<= std_logic_vector(to_unsigned(hr_value / 10, 4));
                pm <= '0';
            else
                if hr_value = 12 then
hrs_ones<= std_logic_vector(to_unsigned(2, 4));
hrs_tens<= std_logic_vector(to_unsigned(1, 4));
                else
hrs_ones<= std_logic_vector(to_unsigned((hr_value - 12) mod 10, 4));
hrs_tens<= std_logic_vector(to_unsigned((hr_value - 12) / 10, 4));
                end if;
                pm <= '1';
            end if;
        end if;
    end process;
end Behavioral;

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity Seven_Segment_Module is
    Port (
clk : in STD_LOGIC;                            -- 100MHz Basys 3 Board
min_ones : in STD_LOGIC_VECTOR(3 downto 0);    -- 0-9
min_tens : in STD_LOGIC_VECTOR(3 downto 0);    -- 0-5
hrs_ones : in STD_LOGIC_VECTOR(3 downto 0);    -- 0-9
hrs_tens : in STD_LOGIC_VECTOR(3 downto 0);    -- 0-1
seg : out STD_LOGIC_VECTOR(6 downto 0);
an : out STD_LOGIC_VECTOR(3 downto 0);
dp : out STD_LOGIC                            -- Decimal point output
    );
end Seven_Segment_Module;

architecture Behavioral of Seven_Segment_Module is
    signal digit_display : unsigned(1 downto 0) := (others => '0');
    type display_array is array (0 to 3) of STD_LOGIC_VECTOR(6 downto 0);
    signal display :display_array;

    signal counter : unsigned(18 downto 0) := (others => '0');
    constant max_count : integer := 500000;

    type four_bit_array is array (0 to 3) of STD_LOGIC_VECTOR(3 downto 0);
    signal four_bit :four_bit_array;

begin
    -- Assigning values that need to be reflected on the 7-segment display
four_bit(0) <= min_ones;
four_bit(1) <= min_tens;
four_bit(2) <= hrs_ones;
four_bit(3) <= hrs_tens;

    -- 100 Hz slow clock for enabling each segment at refresh rate of 10 ms
    process(clk)
    begin
        if rising_edge(clk) then
            -- Clock display counter
            if counter <max_count then
                counter <= counter + 1;
            else
digit_display<= digit_display + 1;
                counter <= (others => '0');
            end if;

            -- BCD to seven segment display
            case four_bit(to_integer(digit_display)) is
                when "0000" => display(to_integer(digit_display)) <= "1000000"; -- 0
                when "0001" => display(to_integer(digit_display)) <= "1111001"; -- 1
                when "0010" => display(to_integer(digit_display)) <= "0100100"; -- 2
                when "0011" => display(to_integer(digit_display)) <= "0110000"; -- 3
                when "0100" => display(to_integer(digit_display)) <= "0011001"; -- 4
                when "0101" => display(to_integer(digit_display)) <= "0010010"; -- 5
                when "0110" => display(to_integer(digit_display)) <= "0000010"; -- 6
                when "0111" => display(to_integer(digit_display)) <= "1111000"; -- 7
                when "1000" => display(to_integer(digit_display)) <= "0000000"; -- 8
                when "1001" => display(to_integer(digit_display)) <= "0010000"; -- 9
                when "1010" => display(to_integer(digit_display)) <= "0001000"; -- A
                when "1011" => display(to_integer(digit_display)) <= "0000011"; -- b
                when "1100" => display(to_integer(digit_display)) <= "1000110"; -- C
                when "1101" => display(to_integer(digit_display)) <= "0100001"; -- d
                when "1110" => display(to_integer(digit_display)) <= "0000110"; -- E
                when others => display(to_integer(digit_display)) <= "0001110"; -- F
            end case;

            -- Enable each segment and control decimal point
            case to_integer(digit_display) is
                when 0 =>
                    an <= "1110";   -- Rightmost digit (min_ones)
                    seg <= display(0);
dp<= '1';      -- Decimal point off
                when 1 =>
                    an <= "1101";   -- Second from right (min_tens)
                    seg <= display(1);
dp<= '1';      -- Decimal point on (between minutes and hours)
                when 2 =>
                    an <= "1011";   -- Second from left (hrs_ones)
                    seg <= display(2);
dp<= '0';      -- Decimal point on (between minutes and hours)
                when 3 =>
                    an <= "0111";   -- Leftmost digit (hrs_tens)
                    seg <= display(3);
dp<= '1';      -- Decimal point off
                when others =>
                    an <= "1111";
dp<= '1';      -- Decimal point off
            end case;
        end if;
    end process;
end Behavioral;
