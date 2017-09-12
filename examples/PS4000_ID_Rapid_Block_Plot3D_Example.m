%% PicoScope 4000 Series Instrument Driver Oscilloscope Rapid Block Data Capture Example
% This is an example of an instrument control session using a device
% object. The instrument control session comprises all the steps you are
% likely to take when communicating with your instrument.
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
% PS4000_ID_Rapid_Block_Plot3D_Example, at the MATLAB command prompt.
% 
% The file, PS4000_ID_RAPID_BLOCK_PLOT3D_EXAMPLE.M must be on your MATLAB
% PATH. For additional information on setting your MATLAB PATH, type 'help
% addpath' at the MATLAB command prompt.
%
% *Example:*
%     PS4000_ID_Rapid_Block_Plot3D_Example;
%   
% *Description:*
%     Demonstrates how to set properties and call functions in order to
%     capture data in rapid block mode from a PicoScope 4000 Series
%     Oscilloscope.
%   
% *See also:* <matlab:doc('icdevice') |icdevice|> | <matlab:doc('instrument/invoke') |invoke|>
%
% *Copyright:* © 2015-2017 Pico Technology Ltd. See LICENSE file for terms.

%% Suggested Input Test Signal
% This example was published using the following test signal:
%
% * Channel A: 4 Vpp Swept Sine wave (Start: 200 Hz, Stop: 1 kHz, Sweep type: Up, Increment: 100 Hz, Increment Time: 8 ms)

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
% |ps4000SetChannel()| function to turn channels on or off and set voltage
% ranges, coupling, as well as analog offset.

% In this example, data is only collected on channel A so default channel
% settings are used and all other channels are switched off.

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

%% Set Memory Segments
% Configure the number of memory segments and query |ps4000MemorySegments()|
% to find the maximum number of samples for each segment.

% numSegments : 16

numSegments = 16;
[status.memorySegments, nMaxSamples] = invoke(ps4000DeviceObj, 'ps4000MemorySegments', numSegments);

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
% index of 4 is valid.

% Initial call to ps4000GetTimebase2() with parameters:
%
% timebase     : 4 
% segment index: 0

status.getTimebase2 = PicoStatus.PICO_INVALID_TIMEBASE;
timebaseIndex = 4;

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
% Set a trigger on channel A, with an auto timeout - the default value for
% delay is used.

% Trigger properties and functions are located in the Instrument
% Driver's Trigger group.

triggerGroupObj = get(ps4000DeviceObj, 'Trigger');
triggerGroupObj = triggerGroupObj(1);

% Set device to trigger automatically after 1 second.
set(triggerGroupObj, 'autoTriggerMs', 1000);

% Channel     : 0 (ps4000Enuminfo.enPS4000Channel.PS4000_CHANNEL_A)
% Threshold   : 500 (mV)
% Direction   : 2 (ps4000Enuminfo.enPS4000ThresholdDirection.PS4000_RISING)

[status.setSimpleTrigger] = invoke(triggerGroupObj, 'setSimpleTrigger', 0, 500, 2);

%% Setup Rapid Block Parameters and Capture Data

% Rapid Block specific properties and functions are located in the Instrument
% Driver's Rapidblock group.

rapidBlockGroupObj = get(ps4000DeviceObj, 'Rapidblock');
rapidBlockGroupObj = rapidBlockGroupObj(1);

% Set the number of waveforms to captures

% numCaptures : 10

numCaptures = 10;
[status.setNoOfCaptures] = invoke(rapidBlockGroupObj, 'ps4000SetNoOfCaptures', numCaptures);

% Set number of samples to collect pre- and post-trigger. Ensure that the
% total does not exceeed nMaxSamples above.

set(ps4000DeviceObj, 'numPreTriggerSamples', 2500);
set(ps4000DeviceObj, 'numPostTriggerSamples', 7500);

% Block specific properties and functions are located in the Instrument
% Driver's Block group.

blockGroupObj = get(ps4000DeviceObj, 'Block');
blockGroupObj = blockGroupObj(1);

% Capture the blocks of data

% segmentIndex : 0 

[status.runBlock, timeIndisposedMs] = invoke(blockGroupObj, 'runBlock', 0);

% Retrieve Rapid Block Data

% numCaptures : 10
% ratio       : 1
% ratioMode   : 0 (ps4000Enuminfo.enPS4000RatioMode.PS4000_RATIO_MODE_NONE)

[numSamples, overflow, chA] = invoke(rapidBlockGroupObj, 'getRapidBlockData', numCaptures, 1, 0);

%% Process data
% Plot data values in 3D showing history.

% Calculate time (nanoseconds) and convert to milliseconds. Use
% |timeIntervalNanoseconds| output from |ps4000GetTimebase2()| or calculate
% from Programmer's Guide.

timeNs = double(timeIntervalNanoseconds) * double(0:numSamples - 1);

% Channel A
figure1 = figure('Name','PicoScope 4000 Series Example - Rapid Block Mode Capture', ...
    'NumberTitle', 'off');
axes1 = axes('Parent', figure1);
view(axes1, [-15 24]);
grid(axes1, 'on');
hold(axes1, 'all');

for i = 1:10
    
    plot3(timeNs, i * (ones(numSamples, 1)), chA(:, i));
    
end

title(axes1, 'Rapid Block Data Acquisition - Channel A');
xlabel(axes1, 'Time (ns)');
ylabel(axes1, 'Capture');
zlabel(axes1, 'Voltage (mV)');

hold(axes1, 'off');

%% Stop the Device
[status.stop] = invoke(ps4000DeviceObj, 'ps4000Stop');

%% Disconnect Device
% Disconnect device object from hardware.

disconnect(ps4000DeviceObj);
delete(ps4000DeviceObj);