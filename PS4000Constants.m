%% PS4000Constants 
%
% The PS4000Constants class defines a number of constant values from the
% ps4000Api.h header file that can be used to define the properties of a
% PicoScope 4000 Series Oscilloscope or for passing as parameters to
% function calls.
%
% The properties in this file are divided into the following
% sub-sections:
%
% * ETS Mode Properties
% * ADC Count Properties
% * Analog offset values
% * Function/Arbitrary Waveform Parameters
% * Maximum/Minimum Waveform Frequencies
% * PicoScope 4000 Series Models using this driver
%
% Ensure that the file is on the MATLAB Path.		
%
% Ensure that the location of this class file is on the MATLAB Path.		
%
% Copyright: © 2014-2017 Pico Technology Ltd. See LICENSE file for terms.	

classdef PS4000Constants
    
    properties (Constant)
        
        % ETS Mode properties
        PS4000_MAX_ETS_CYCLES           = 400;		
        PS4000_MAX_ETS_INTERLEAVE       = 80;
        
        PS4262_MAX_VALUE                = 32767;
		PS4262_MIN_VALUE                = -32767;
        
        PS4000_MAX_VALUE                = 32764;
        PS4000_MIN_VALUE                = -32764;
        
        % External Trigger Input ADC Count
        PS4000_EXT_MAX_VALUE            = 32767;
        PS4000_EXT_MIN_VALUE            = -32767;
        
        MAX_PULSE_WIDTH_QUALIFIER_COUNT = 16777215;
        MAX_DELAY_COUNT                 = 8388607;
		
        % Function/Arbitrary Waveform Parameters
		MIN_SIG_GEN_FREQ                = 0.0;
        MAX_SIG_GEN_FREQ                = 100000.0;
        MAX_SIG_GEN_FREQ_4262           = 20000.0;

        MIN_SIG_GEN_BUFFER_SIZE         = 1;
        MAX_SIG_GEN_BUFFER_SIZE         = PicoConstants.AWG_BUFFER_8KS;
        MIN_DWELL_COUNT                 = 10;
        
        PS4262_SIGGEN_MAXPKTOPK         = 2000000;
        PS4000_SIGGEN_MAXPKTOPK         = 4000000;   
        
        PS4262_MAX_WAVEFORM_BUFFER_SIZE = 4096;
        PS4262_MIN_DWELL_COUNT          = 3;
        
        MAX_SWEEPS_SHOTS				= pow2(30) - 1; 

        % Frequencies
        
        PS4000_SINE_MAX_FREQUENCY		= 20000000;
        PS4000_SQUARE_MAX_FREQUENCY     = 20000000;
        PS4000_TRIANGLE_MAX_FREQUENCY	= 20000000;
        PS4000_SINC_MAX_FREQUENCY		= 20000000
        PS4000_RAMP_MAX_FREQUENCY		= 20000000;
        PS4000_HALF_SINE_MAX_FREQUENCY	= 20000000;
        PS4000_GAUSSIAN_MAX_FREQUENCY   = 20000000;
        PS4000_PRBS_MAX_FREQUENCY		= 1000000;
        PS4000_PRBS_MIN_FREQUENCY		= 0.03;
        PS4000_MIN_FREQUENCY			= 0.03;

    end

end

