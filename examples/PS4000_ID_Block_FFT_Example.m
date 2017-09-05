%% PicoScope 4000 Series Instrument Driver Oscilloscope Block Data Capture with FFT Example
% This is an example of an instrument control session using a device 
% object. The instrument control session comprises all the steps you 
% are likely to take when communicating with your instrument. 
%
% These steps are:
%    
% # Create a device object   
% # Connect to the instrument 
% # Configure properties 
% # Invoke functions 
% # Disconnect from the instrument 
%
% To run the instrument control session, type the name of the file,
% PS4000_ID_Block_FFT_Example, at the MATLAB command prompt.
% 
% The file, PS4000_ID_BLOCK_FFT_EXAMPLE.M must be on your MATLAB PATH. For
% additional information on setting your MATLAB PATH, type 'help addpath'
% at the MATLAB command prompt.
%
% *Example:*
%     PS4000_ID_Block_FFT_Example;
%
% *Description:*
%     Demonstrates how to set properties and call functions in order to
%     capture a block of data from a PicoScope 4000 Series oscilloscope
%     and calculate a Fast Fourier Transform (FFT) on the data collected.
%
% *See also:* <matlab:doc('fft') |fft|> | <matlab:doc('icdevice') |icdevice|> | <matlab:doc('instrument/invoke') |invoke|>
% 
% *Copyright:* © 2014-2017 Pico Technology Ltd. See LICENSE file for terms.

%% Suggested Input Test Signal
% This example was published using the following test signal:
%
% * Channel A: 4 Vpp, 1 kHz Square wave

%% Clear Command Window and Close any Figures

clc;
close all;

%% Load Configuration Information

PS4000Config;

%% Device Connection

% Check if an Instrument session using the device object |ps4000DeviceObj|
% is still open, and if so, disconnect if the User chooses 'Yes' when prompted.
if (exist('ps4000DeviceObj', 'var') && ps4000DeviceObj.isvalid && strcmp(ps4000DeviceObj.status, 'open'))
    
    openDevice = questionDialog(['Device object ps4000DeviceObj has an open connection. ' ...
        'Do you wish to close the connection and continue?'], ...
        'Device Object Connection Open');
    
    if (openDevice == PicoConstants.TRUE)
        
        % Close connection to device
        disconnect(ps4000DeviceObj);
        delete(ps4000DeviceObj);
        
    else

        % Exit script if User selects 'No'
        return;
        
    end
    
end

% Create a device object. 
% The serial number can be specified as a second input parameter.
ps4000DeviceObj = icdevice('picotech_ps4000_generic.mdd');

% Connect device object to hardware.
connect(ps4000DeviceObj);

%% Set Channels
% Default driver settings applied to channels are listed below - use the
% Instrument Driver's |ps4000SetChannel() | to turn channels on or off and
% set voltage ranges, coupling, as well as analog offset.

% In this example, data is only collected on channel A so default settings
% are used and channel B is switched off. If the PicoScope is a
% 4-channel model, channels C and D will also be switched off.

% Channels       : 1 - 3 (ps4000Enuminfo.enPS4000Channel.PS4000_CHANNEL_B - PS4000_CHANNEL_D)
% Enabled        : 0
% Type           : 1 (DC)
% Range          : 8 (ps4000Enuminfo.enPS4000Range.PS4000_5V)

% Execute device object function(s).
[status.setChB] = invoke(ps4000DeviceObj, 'ps4000SetChannel', 1, 0, 1, 8, 0.0,0);

if (ps4000DeviceObj.channelCount == PicoConstants.QUAD_SCOPE)

	[status.setChC] = invoke(ps4000DeviceObj, 'ps4000SetChannel', 2, 0, 1, 8, 0.0,0);
	[status.setChD] = invoke(ps4000DeviceObj, 'ps4000SetChannel', 3, 0, 1, 8, 0.0,0);
	
end

%% Verify Timebase Index and Maximum Number of Samples
% Use the |ps4000GetTimebase2()| function to query the driver as to the
% suitability of using a particular timebase index and the maximum number
% of samples available in the segment selected, then set the |timebase|
% property if required.
%
% To use the fastest sampling interval possible, enable one or two channels
% and in the case of the PicoScope 4424, turn off all other channels.
%
% Use a while loop to query the function until the status indicates that a
% valid timebase index has been selected. In this example, the timebase
% index of 2 is valid.

% Initial call to ps4000GetTimebase2() with parameters:
%
% timebase     : 2 
% segment index: 0

status.getTimebase2 = PicoStatus.PICO_INVALID_TIMEBASE;
timebaseIndex = 2;

while (status.getTimebase2 == PicoStatus.PICO_INVALID_TIMEBASE)
    
    [status.getTimebase2, timeIntervalNanoseconds, maxSamples] = invoke(ps4000DeviceObj, ...
                                                                    'ps4000GetTimebase2', timebaseIndex, 0);
    
    if (status.getTimebase2 == PicoStatus.PICO_OK)
       
        break;
        
    else
        
        timebaseIndex = timebaseIndex + 1;
        
    end    
    
end

fprintf('Timebase index: %d, sampling interval: %.1f ns\n', timebaseIndex, timeIntervalNanoseconds);

% Configure the device |timebase| property value.
set(ps4000DeviceObj, 'timebase', timebaseIndex);

%% Set Simple Trigger
% Set a trigger on channel A, default values for delay and auto timeout are
% used.

% Trigger properties and functions are located in the Instrument
% Driver's Trigger group.

triggerGroupObj = get(ps4000DeviceObj, 'Trigger');
triggerGroupObj = triggerGroupObj(1);

% Set device to trigger automatically after 1 second
set(triggerGroupObj, 'autoTriggerMs', 1000);

% Channel     : 0 (ps4000Enuminfo.enPS4000Channel.PS4000_CHANNEL_A)
% Threshold   : 500 (mV)
% Direction   : 2 (ps4000Enuminfo.enPS4000ThresholdDirection.PS4000_RISING)

[status.setSimpleTrigger] = invoke(triggerGroupObj, 'setSimpleTrigger', 0, 500, 2);

%% Set Block Parameters and Capture Data
% Capture a block of data and retrieve data values for channel A.

% Block data acquisition properties and functions are located in the 
% Instrument Driver's Block group.

blockGroupObj = get(ps4000DeviceObj, 'Block');
blockGroupObj = blockGroupObj(1);

% Set pre-trigger and post-trigger samples as required - the total of this
% should not exceed the value of |maxSamples| returned from the call to
% |ps4000GetTimebase2()|.

set(ps4000DeviceObj, 'numPreTriggerSamples', 500e3);
set(ps4000DeviceObj, 'numPostTriggerSamples', 500e3);

% Capture a block of data:
%
% segment index: 0 (The buffer memory is not segmented in this example)

%%
% This example uses the |runBlock()| function in order to collect a block of
% data - if other code needs to be executed while waiting for the device to
% indicate that it is ready, use the |ps4000RunBlock()| function and poll
% the |ps4000IsReady()| function.

[status.runBlock] = invoke(blockGroupObj, 'runBlock', 0);

% Retrieve data values:
%
% start index       : 0
% segment index     : 0
% downsampling ratio: 1
% downsampling mode : 0 (ps4000Enuminfo.enPS4000RatioMode.PS4000_RATIO_MODE_NONE)

% Provide additional output arguments for other channels e.g. chC for
% channel C if using a 4-channel PicoScope.
[numSamples, overflow, chA] = invoke(blockGroupObj, 'getBlockData', 0, 0, 1, 0);

% Stop the device
[status.stop] = invoke(ps4000DeviceObj, 'ps4000Stop');

%% Process Data
% Plot data values, calculate FFT and plot

figure1 = figure('Name','PicoScope 4000 Series Example - Block Mode Capture with FFT', ...
    'NumberTitle','off');

% Calculate time (nanoseconds) and convert to milliseconds.
% Use |timeIntervalNanoSeconds| output from the |ps4000GetTimebase2()| 
% function or calculate it using the main Programmer's Guide.
% Take into account the downsampling ratio used.

timeNs = double(timeIntervalNanoSeconds) * downsamplingRatio * double(0:numSamples - 1);
timeMs = timeNs / 1e6;

% Channel A

chAAxes = subplot(2,1,1);
plot(chAAxes,timeMs, chA);
ylim(chAAxes, [-2500 2500]);

title(chAAxes, 'Block Data Acquisition');
xlabel(chAAxes, 'Time (ms)');
ylabel(chAAxes, 'Voltage (mV)');

grid(chAAxes, 'on');
legend(chAAxes, 'Channel A');

% Calculate FFT of Channel A and plot - based on fft help file.
L = length(chA);
n = 2 ^ nextpow2(L); % Next power of 2 from length of chA

Y = fft(chA, n);

% Obtain the single-sided spectrum of the signal.
P2 = abs(Y/n);
P1 = P2(1:n/2+1);
P1(2:end-1) = 2 * P1(2:end-1);

Fs = 1/(timeIntervalNanoSeconds * 1e-9);
f = 0:(Fs/n):(Fs/2 - Fs/n);

chAFFTAxes = subplot(2,1,2);
plot(chAFFTAxes, f, P1(1:n/2)); 

title(chAFFTAxes, 'Single-Sided Amplitude Spectrum of y(t)');
xlabel(chAFFTAxes, 'Frequency (Hz)');
ylabel(chAFFTAxes, '|Y(f)|');
grid(chAFFTAxes, 'on');

%% Disconnect Device
% Disconnect device object from hardware.

disconnect(ps4000DeviceObj);
delete(ps4000DeviceObj);
