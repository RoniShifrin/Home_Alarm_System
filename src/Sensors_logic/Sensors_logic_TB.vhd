--------------------- Title ------------------------
-- Project Name: HA_System
-- File Name: Sensors_logic_TB.vhd
-- Author: Yuval Kogan
-- Ver: 0
-- Created Date: 23/11/25
----------------------------------------------------


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;

entity Sensors_logic_TB is
end Sensors_logic_TB;

architecture test_bench of Sensors_logic_TB is

    -- DUT Component Declaration (Ensure it matches Sensors_logic.vhd)
    component Sensors_logic
        port (
            Clk          : IN  std_logic;
            Rst          : IN  std_logic;
            door_sens    : IN  std_logic;
            window_sens  : IN  std_logic;  
            motion_sens  : IN  std_logic;
            
            door_clean   : OUT std_logic;
            window_clean : OUT std_logic;
            motion_clean : OUT std_logic;
            detected     : OUT std_logic
        );
    end component;

    -- Signal Declarations
    constant CLK_PERIOD : time := 10 ns; 

    -- Debounce threshold is 3, meaning 4 clock cycles (0, 1, 2, 3) are required for a change.
    constant T_DEBOUNCE_TIME : time := CLK_PERIOD * 3; 
    constant T_PRE_DEBOUNCE  : time := CLK_PERIOD * 2; -- Time right before the change

    -- Testbench Control Signals (Inputs to the DUT)
    signal TB_Clk         : std_logic := '0';
    signal TB_Rst         : std_logic := '0';
    signal TB_door_sens   : std_logic := '0';
    signal TB_window_sens : std_logic := '0';
    signal TB_motion_sens : std_logic := '0';
    
    -- Output Signals from the DUT
    signal TB_door_clean  : std_logic;
    signal TB_window_clean: std_logic;
    signal TB_motion_clean: std_logic;
    signal TB_detected    : std_logic;

begin
    -- DUT Instantiation
    DUT: Sensors_logic
        port map (
            Clk          => TB_Clk,
            Rst          => TB_Rst,
            door_sens    => TB_door_sens,
            window_sens  => TB_window_sens,
            motion_sens  => TB_motion_sens,
            door_clean   => TB_door_clean,
            window_clean => TB_window_clean,
            motion_clean => TB_motion_clean,
            detected     => TB_detected
        );

    -- Clock Generation Process
    CLK_GEN: process
    begin
        loop
            TB_Clk <= '0';
            wait for CLK_PERIOD / 2;
            TB_Clk <= '1';
            wait for CLK_PERIOD / 2;
        end loop;
    end process CLK_GEN;

    -- Stimulus Generation Process
    STIM_GEN: process
    begin
        
        report "--- Starting Simulation: Debounce requires 3 Clock Cycles ---" severity note;

        -- Initial conditions
        TB_door_sens <= '0';
        TB_window_sens <= '0';
        TB_motion_sens <= '0';

        wait for CLK_PERIOD * 2;


        -- PHASE 0: INITIAL RESET
        report "PHASE 0: Testing Asynchronous Reset" severity note;

        -- Apply the Asynchronous Reset pulse
        TB_Rst <= '1';
        wait for CLK_PERIOD * 2; 
        TB_Rst <= '0';

        -- Wait for one clock cycle to verify reset state persists
        wait for CLK_PERIOD;
        assert TB_door_clean   = '0' report "Error: door_clean not cleared by Rst" severity error;
        assert TB_detected     = '0' report "Error: detected not cleared by Rst" severity error;


        
        -- PHASE 1: FULL DEBOUNCE TIMING CHECK (Door ON)
        report "PHASE 1: Detailed Door Sensor Debounce ON Timing Check" severity note;

        TB_door_sens <= '1';
        
        -- Check 1: Must NOT have debounced after 2 cycles (T_PRE_DEBOUNCE)
        wait for T_PRE_DEBOUNCE;
        assert TB_door_clean = '0' report "Error: Door debounced too quickly (after 2 cycles)" severity error;
        
        -- Check 2: Must debounce ON exactly after the 3rd cycle
        wait for CLK_PERIOD; -- Total time elapsed: T_DEBOUNCE_TIME (3 cycles)
        assert TB_door_clean = '1' report "Error: Door failed to debounce ON after 3 cycles" severity error;
        assert TB_detected = '0' report "Error: Detected high with only 1 sensor" severity error;

        
        -- PHASE 2: BOUNCE REJECTION AND COUNTER RESET
        report "PHASE 2: Testing Bounce Rejection (Short Pulse OFF)" severity note;
        
        -- Current state: door_clean = '1'. Start a bounce OFF
        TB_door_sens <= '0'; 
        
        -- Check 1: Must NOT have debounced OFF after 2 cycles
        wait for T_PRE_DEBOUNCE;
        assert TB_door_clean = '1' report "Error: Door debounced OFF too quickly (after 2 cycles)" severity error;
        
        -- Bounce: Set input back to the current clean state ('1')
        TB_door_sens <= '1'; 
        
        -- Counter should have reset, and door_clean should remain '1'
        wait for CLK_PERIOD;
        assert TB_door_clean = '1' report "Error: Door debounced OFF due to short pulse" severity error;


        -- PHASE 3: ASYMMETRIC DETECTION TIMING CHECK (Door (1) + Window (0->1))
        report "PHASE 3: Asymmetric Detection (Door is stable, Wait for Window)" severity note;
        -- Current state: door_clean = '1', window_clean = '0', motion_clean = '0', detected = '0'
        
        -- Start Window ON
        TB_window_sens <= '1'; 
        
        -- Check 1: Must NOT detect after 2 cycles (T_PRE_DEBOUNCE)
        wait for T_PRE_DEBOUNCE;
        assert TB_window_clean = '0' report "Error: Window debounced too quickly" severity error;
        assert TB_detected     = '0' report "Error: Detected asserted before second sensor stabilized (3 cycles)" severity error;

        -- Check 2: Must detect exactly after the 3th cycle
        wait for CLK_PERIOD; -- Total time elapsed for Window: 4 cycles
        assert TB_window_clean = '1' report "Error: Window failed to debounce ON after 4 cycles" severity error;
        assert TB_detected     = '1' report "Error: Detected failed to assert immediately after 2nd sensor stabilization" severity failure;

        
        -- PHASE 4: DETECTION DE-ASSERTION CHECK (Door (1) + Window (1->0))
        report "PHASE 4: De-assertion Timing Check (Window (1->0))" severity note;
        -- Current state: door_clean = '1', window_clean = '1', detected = '1'

        -- Start Window OFF
        TB_window_sens <= '0';
        
        -- Check 1: Must still detect after 2 cycles (T_PRE_DEBOUNCE)
        wait for T_PRE_DEBOUNCE;
        assert TB_window_clean = '1' report "Error: Window debounced OFF too quickly" severity error;
        assert TB_detected     = '1' report "Error: Detected de-asserted before sensor went low" severity error;
        
        -- Check 2: Must de-assert detection exactly after the 3th cycle
        wait for CLK_PERIOD; -- Total time elapsed for Window OFF: 3 cycles
        assert TB_window_clean = '0' report "Error: Window failed to debounce OFF after 4 cycles" severity error;
        assert TB_detected     = '0' report "Error: Detected failed to de-assert after sensor went low" severity failure;


        -- PHASE 5: COMPLEX DETECTION COMBINATIONS
        report "PHASE 5: Testing remaining 2-of-3 combinations" severity note;

        -- Setup: Window OFF, Motion ON (001)
        TB_window_sens <= '0';
        TB_motion_sens <= '1';
        wait for T_DEBOUNCE_TIME;
        
        -- Test 5.1: Door (1) + Motion (1) -> Current state
        assert TB_door_clean   = '1' report "Error: Door expected '1'" severity error;
        assert TB_window_clean = '0' report "Error: Window expected '0'" severity error;
        assert TB_motion_clean = '1' report "Error: Motion expected '1'" severity error;
        assert TB_detected     = '1' report "Error: Door & Motion failed to detect" severity failure;

        -- Test 5.2: Window (0->1) + Motion (1) - Clear Door, Set Window
        TB_door_sens   <= '0';
        TB_window_sens <= '1';
        wait for T_DEBOUNCE_TIME;
        
        assert TB_door_clean   = '0' report "Error: Door failed to debounce OFF" severity error;
        assert TB_window_clean = '1' report "Error: Window failed to debounce ON" severity error;
        assert TB_motion_clean = '1' report "Error: Motion expected '1'" severity error;
        assert TB_detected     = '1' report "Error: Window & Motion failed to detect" severity failure;


        -- PHASE 6: FINAL SHUTDOWN
        report "PHASE 6: Final Shutdown" severity note;

        -- All three OFF (000)
        TB_door_sens   <= '0';
        TB_window_sens <= '0';
        TB_motion_sens <= '0';
        wait for T_DEBOUNCE_TIME;
        
        assert TB_detected     = '0' report "Error: Detected remained high at shutdown" severity failure;
        
        -- End Simulation
        wait for CLK_PERIOD * 5;
        report "--- Simulation Complete: All major states, combinations, and timing verified ---" severity note;
        wait; 
    end process STIM_GEN;

end architecture test_bench;