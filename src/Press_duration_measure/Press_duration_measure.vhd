--------------------- Title ------------------------
-- Project Name: HA_System
-- File Name: Press_duration_measure.vhd
-- Author: Roni Shifrin
-- Ver: 0
-- Created Date: 23/11/25
----------------------------------------------------


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity Duration_measure is
    generic(
        PULSE_LENGTH : INTEGER := 2
    );
    port (
        clk : in std_logic;
        Rst : in std_logic;
        btn_in : in std_logic;
        enable : in std_logic;
        bit_out : out std_logic;
        Bit_valid : out std_logic
    );
end Duration_measure;

architecture behavior of Duration_measure is

    Signal clock_counter : integer := 0;
    Signal pulse_flag : integer := 0;
    Signal bit_result : std_logic := '0';
    
begin
    debouncer_door_process : process(Clk, Rst)
begin
    -- Asynchronous Reset
    if Rst = '1' then
        bit_out <= '0';
        Bit_valid <= '0';
        clock_counter <= 0;
        pulse_counter <= '0';
    end if;


    if enable = '1' then
        if RISING_EDGE(Clk) then
            -- On button release - reset counter
            if btn_in = '0' then
                -- if clock_counter > 3 => create a pulse
                if clock_counter > PULSE_LENGTH then
                  pulse_flag <= pulse_flag + 1;
                end if := 
                clock_counter <= '0';
            
            if (pulse_flag = '1') then
                -- Send pulse outwards
                pulse_flag <= '0';
                bit_out <= -- long press\short press
                valid <= '1';


            end if;

            -- Button pressed/hold

            -- 
            








    -- Synchronous Clock Edge
    elsif RISING_EDGE(Clk) then
        
        -- Check if the raw input matches the current clean state
        if door_sens = door_int then
            count_door <= (others => '0'); -- door sensor data is the same as the output => we can reset the door counter
        else
            -- Signal has changed: start/continue counting
            if count_door < DEBOUNCE_THRESHOLD then
                count_door <= count_door + 1;
            else
                -- Counter reached threshold: update the output`s state
                door_int <= door_sens;
                count_door <= (others => '0'); -- Reset after update
            end if;
        end if;
    end if;
end process debouncer_door_process;


    
end architecture behavior;