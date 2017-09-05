%% PicoScope 2000 Series (A API) Instrument Driver Oscilloscope Streaming Data Capture Example
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
% PS4000_ID_Streaming_Example, at the MATLAB command prompt.
% 
% The file, PS4000_ID_STREAMING_EXAMPLE.M must be on your MATLAB PATH. For
% additional information on setting your MATLAB PATH, type 'help addpath'
% at the MATLAB command prompt.
%
% *Example:*
%     PS4000_ID_Streaming_Example;
%
% *Description:*
%     Demonstrates how to set properties and call functions in order
%     to capture data in streaming mode from a PicoScope 4000 Series
%     Oscilloscope.
%
% *Note:* Not all device and group object functions used in this example
% are compatible with the Test and Measurement Tool.
%
% *See also:* <matlab:doc('icdevice') |icdevice|> | <matlab:doc('instrument/invoke') |invoke|>
%
% *Copyright:* © 2015-2017 Pico Technology Ltd. See LICENSE file for terms.

%% Suggested Input Test Signals
% This example was published using the following test signals:
%
% * Channel A: 3 Vpp, 1 Hz Sine wave
% * Channel B: 2 Vpp, 4 Hz Square wave 

%% Clear Command Window and Close any Figures

clc;
close all;

%% Load Configuration Information

PS4000Config;

%% Parameter Definitions
% Define any parameters that might be required throughout the script.

channelA = ps4000Enuminfo.enPS4000Channel.PS4000_CHANNEL_A;
channelB = ps4000Enuminfo.enPS4000Channel.PS4000_CHANNEL_B;

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

% Create device -  specify serial number if required
% Specify serial number as 2nd argument if required.
ps4000DeviceObj = icdevice('picotech_ps4000_generic', ''); 

% Connect device
connect(ps4000DeviceObj);

%% Display Unit Information From Shared Library

[infoStatus, unitInfo] = invoke(ps4000DeviceObj, 'getUnitInfo');

disp(unitInfo);

%% Channel Setup
% All channels are enabled by default - switch off all except Channels A and B.

numChannels = get(ps4000DeviceObj, 'channelCount');

% Channel A
channelSettings(1).enabled = PicoConstants.TRUE;
channelSettings(1).coupling = 1;
channelSettings(1).range = ps4000Enuminfo.enPS4000Range.PS4000_2V;

channelARangeMV = PicoConstants.SCOPE_INPUT_RANGES(channelSettings(1).range + 1);

% Channel B
channelSettings(2).enabled = PicoConstants.TRUE;
channelSettings(2).coupling = 1;
channelSettings(2).range = ps4000Enuminfo.enPS4000Range.PS4000_2V;

channelBRangeMV = PicoConstants.SCOPE_INPUT_RANGES(channelSettings(2).range + 1);

if (numChannels == PicoConstants.QUAD_SCOPE)

    % Channel C
    channelSettings(3).enabled = PicoConstants.FALSE;
    channelSettings(3).coupling = 1;
    channelSettings(3).range = ps4000Enuminfo.enPS4000Range.PS4000_2V;


    % Channel D
    channelSettings(4).enabled = PicoConstants.FALSE;
    channelSettings(4).coupling = 1;
    channelSettings(4).range = ps4000Enuminfo.enPS4000Range.PS4000_2V;

end

% Keep the status values returned from the driver.
for ch = 1:numChannels
   
    status.setChannelStatus(ch) = invoke(ps4000DeviceObj, 'ps4000SetChannel', ...
        (ch - 1), channelSettings(ch).enabled, ...
        channelSettings(ch).coupling, channelSettings(ch).range);
    
end

% Obtain the maximum ADC Count from the driver
maxADCCount = double(get(ps4000DeviceObj, 'maxADCValue'));

%% Trigger Setup
% Turn off trigger
% If a trigger is set and the |autoStop| property of the Instrument
% Driver's Streaming group object is set to '1', the device will stop
% collecting data once the number of post trigger samples have been
% collected.

% Trigger properties and functions are located in the Instrument
% Driver's Trigger group.

triggerGroupObj = get(ps4000DeviceObj, 'Trigger');
triggerGroupObj = triggerGroupObj(1);

[status.setTriggerOff] = invoke(triggerGroupObj, 'setTriggerOff');

%% Set Data Buffers
% Data buffers for channels A and B - buffers should be set with the driver,
% and these MUST be passed with application buffers to the wrapper driver
% in order to ensure data is correctly copied.

overviewBufferSize  = 250000; % Size of the buffer to collect data from buffer.
segmentIndex        = 0;   
ratioMode 			= ps4000Enuminfo.enRatioMode.RATIO_MODE_NONE;

% Buffers to be passed to the driver
pDriverBufferChA = libpointer('int16Ptr', zeros(overviewBufferSize, 1));
pDriverBufferChB = libpointer('int16Ptr', zeros(overviewBufferSize, 1));

status.setDataBufferChA = invoke(ps4000DeviceObj, 'ps4000SetDataBufferWithMode', ...
    channelA, pDriverBufferChA, overviewBufferSize, segmentIndex, ratioMode);

status.setDataBufferChB = invoke(ps4000DeviceObj, 'ps4000SetDataBufferWithMode', ...
   channelB, pDriverBufferChB, overviewBufferSize, segmentIndex, ratioMode);

% Application Buffers - these are for copying from the driver into temporarily.
pAppBufferChA = libpointer('int16Ptr', zeros(overviewBufferSize, 1));
pAppBufferChB = libpointer('int16Ptr', zeros(overviewBufferSize, 1));

% Streaming properties and functions are located in the Instrument
% Driver's Streaming group.

streamingGroupObj = get(ps4000DeviceObj, 'Streaming');
streamingGroupObj = streamingGroupObj(1);

% Register application buffer and driver buffers (with the wrapper).

status.setAppAndDriverBuffersA = invoke(streamingGroupObj, 'setAppAndDriverBuffers', channelA, ...
    pAppBufferChA, pDriverBufferChA, overviewBufferSize);

status.setAppAndDriverBuffersB = invoke(streamingGroupObj, 'setAppAndDriverBuffers', channelB, ...
   pAppBufferChB, pDriverBufferChB, overviewBufferSize);

%% Start Streaming and Collect Data
% Use default value for streaming interval which is 1e-6 for 1 MS/s
% Collect data for 1 second with auto stop - maximum array size will depend
% on the PC's resources - type <matlab:doc('memory') |memory|> at the MATLAB command prompt for further
% information.

% To change the sample interval e.g 5 us for 200 kS/s. The call to
% |ps4000RunStreaming()| will output the actual sampling interval used by the 
% driver.
%set(streamingGroupObj, 'streamingInterval', 5e-6);

% For 10 MS/s, specify 100 ns
%set(streamingGroupObj, 'streamingInterval', 100e-9);

% Set the number of pre- and post-trigger samples
% If no trigger is set the library will still store the
% |numPreTriggerSamples| + |numPostTriggerSamples|.
set(ps4000DeviceObj, 'numPreTriggerSamples', 0);
set(ps4000DeviceObj, 'numPostTriggerSamples', 2000000);

% autoStop parameter can be set to false (0)
%set(streamingGroupObj, 'autoStop', PicoConstants.FALSE);

% Set other streaming parameters
downSampleRatio     = 1;

% Defined buffers to store data collected from the channels. If capturing
% data without using the autoStop flag, or if using a trigger with the
% autoStop flag, allocate sufficient space (1.5 times the sum of the number of
% pre-trigger and post-trigger samples is shown below) to allow for
% additional pre-trigger data. Pre-allocating the array is more efficient
% than using <matlab:doc('vertcat') |vertcat|> to combine data.

maxSamples = get(ps4000DeviceObj, 'numPreTriggerSamples') + ...
    get(ps4000DeviceObj, 'numPostTriggerSamples');

% Take into account the downSampleRatioMode - required if collecting data
% without a trigger and using the autoStop flag.
% finalBufferLength = round(1.5 * maxSamples / downSampleRatio);

pBufferChAFinal = libpointer('int16Ptr', zeros(maxSamples, 1, 'int16'));
pBufferChBFinal = libpointer('int16Ptr', zeros(maxSamples, 1, 'int16'));

% Prompt User to indicate if they wish to plot live streaming data.
plotLiveData = questionDialog('Plot live streaming data?', 'Streaming Data Plot');

if (plotLiveData == PicoConstants.TRUE)
   
    disp('Live streaming data collection with second plot on completion.');
    
else
    
    disp('Streaming data plot on completion.');
    
end

[status.runStreaming, actualSampleInterval, sampleIntervalTimeUnitsStr] = ...
    invoke(streamingGroupObj, 'ps4000RunStreaming', downSampleRatio, overviewBufferSize);
    
disp('Streaming data...');
fprintf('Click the STOP button to stop capture or wait for auto stop if enabled.\n\n') 

% Variables to be used when collecting the data:

hasAutoStopped      = PicoConstants.FALSE;
newSamples          = 0; % Number of new samples returned from the driver.
previousTotal       = 0; % The previous total number of samples.
totalSamples        = 0; % Total samples captured by the device.
startIndex          = 0; % Start index of data in the buffer returned.
hasTriggered        = 0; % To indicate if trigger has occurred.
triggeredAtIndex    = 0; % The index in the overall buffer where the trigger occurred.

time = zeros(overviewBufferSize / downSampleRatio, 1);	% Array to hold time values

status.getStreamingLatestValues = PicoStatus.PICO_OK; % OK

% Display a 'Stop' button.
[stopFig.h, stopFig.h] = stopButton();             
             
flag = 1; % Use flag variable to indicate if stop button has been clicked (0)
setappdata(gcf, 'run', flag);

% Plot Properties - these are for displaying data as it is collected.

if (plotLiveData == PicoConstants.TRUE)
    
    % Plot on a single figure 
    figure1 = figure('Name','PicoScope 4000 Series Example - Streaming Mode Capture', ...
         'NumberTitle','off');

     axes1 = axes('Parent', figure1);

    % Estimate x-axis limit to try and avoid using too much CPU resources
    % when drawing - use max voltage range selected if plotting multiple
    % channels on the same graph.
    
    xlim(axes1, [0 (actualSampleInterval * maxSamples)]);

    yRange = max(channelARangeMv, channelBRangeMv);
    ylim(axes1,[(-1 * yRange) yRange]);

    hold(axes1,'on');
    grid(axes1, 'on');

    title(axes1, 'Live Streaming Data Capture');
    
    if (strcmp(sampleIntervalTimeUnitsStr, 'us'))
        
        xLabelStr = 'Time (\mus)';
        
    else
       
        xLabelStr = strcat('Time (', sampleIntervalTimeUnitsStr, ')');
        xlabel(axes1, xLabelStr);
        
    end
    
    xlabel(axes1, xLabelStr);
    ylabel(axes1, 'Voltage (mV)');
    
end

% Get data values as long as power status has not changed (check for STOP button push inside loop)
while(hasAutoStopped == PicoConstants.FALSE && status.getStreamingLatestValues == PicoStatus.PICO_OK)
    
    ready = PicoConstants.FALSE;
   
    while (ready == PicoConstants.FALSE)

       status.getStreamingLatestValues = invoke(streamingGroupObj, 'getStreamingLatestValues');
       
       ready = invoke(streamingGroupObj, 'isReady');

       % Give option to abort from here
       flag = getappdata(gcf, 'run');
       drawnow;

       if (flag == 0)

            disp('STOP button clicked - aborting data collection.')
            break;

       end

       drawnow;

    end
    
    % Check for data
    [newSamples, startIndex] = invoke(streamingGroupObj, 'availableData');

    if (newSamples > 0)
        
        % Check if the scope has triggered
        [triggered, triggeredAt] = invoke(streamingGroupObj, 'isTriggerReady');

        if (triggered == PicoConstants.TRUE)

            % Adjust trigger position as MATLAB does not use zero-based
            % indexing
            
            bufferTriggerPosition = triggeredAt + 1;
            
            fprintf('Triggered - index in buffer: %d\n', bufferTriggerPosition);

            hasTriggered = triggered;

            % Adjust by 1 due to driver using zero indexing
            triggeredAtIndex = totalSamples + bufferTriggerPosition;

        end

        previousTotal = totalSamples;
        totalSamples = totalSamples + newSamples;

        % Printing to console can slow down acquisition - use for demonstration
        fprintf('Collected %d samples, startIndex: %d total: %d.\n', newSamples, startIndex, totalSamples);
        
        % Position indices of data in buffer
        firstValuePosn = startIndex + 1;
        lastValuePosn = startIndex + newSamples;
        
        % Convert data values to millivolts from the application buffers
        bufferChAmV = adc2mv(pAppBufferChA.Value(firstValuePosn:lastValuePosn), channelARangeMV, maxADCCount);
        bufferChBmV = adc2mv(pAppBufferChB.Value(firstValuePosn:lastValuePosn), channelBRangeMV, maxADCCount);

        % Process collected data further if required - this example plots
        % the data if the User has selected 'Yes' at the prompt.
        
        % Copy data into the final buffer(s)
        pBufferChAFinal.Value(previousTotal + 1:totalSamples) = bufferChAmV;
        pBufferChBFinal.Value(previousTotal + 1:totalSamples) = bufferChBmV;
        
        if (plotLiveData == PicoConstants.TRUE)
            
            % Time axis
            % Multiply by ratio mode as samples get reduced.
            time = (double(actualSampleInterval) * double(downSampleRatio)) * (previousTotal:(totalSamples - 1));
        
            plot(time, bufferChAmV, time, bufferChBmV);

        end;

        % Clear variables for use again
        clear bufferChAMV;
        clear firstValuePosn;
        clear lastValuePosn;
        clear startIndex;
        clear triggered;
        clear triggerAt;
   
    end
   
    % Check if auto stop has occurred
    hasAutoStopped = invoke(streamingGroupObj, 'autoStopped');

    if (hasAutoStopped == PicoConstants.TRUE)

       disp('AutoStop: TRUE - exiting loop.');
       break;

    end
   
    % Check if 'STOP' button pressed

    flag = getappdata(gcf, 'run');
    drawnow;

    if (flag == 0)

        disp('STOP button clicked - aborting data collection.')
        break;
        
    end
 
end

% Close the STOP button window
if (exist('stopFig', 'var'))
    
    close('Stop Button');
    clear stopFig;
        
end

if (plotLiveData == PicoConstants.TRUE)
    
    drawnow;
    
    % Take hold off the current figure.
    hold(axes1, 'off');
    movegui(figure1, 'west');
    
end

if (hasTriggered == PicoConstants.TRUE)
   
    fprintf('Triggered at overall index: %d\n', triggeredAtIndex);
    
end

fprintf('\n');

%% Find the Number of Samples.
% This is the number of samples held in the driver itself. The actual
% number of samples collected when using a trigger is likely to be greater.
[status.noOfStreamingValues, numStreamingValues] = invoke(streamingGroupObj, 'ps4000NoOfStreamingValues');

fprintf('Number of samples available from the driver: %u.\n\n', numStreamingValues);

%% Stop the Device
% This function should be called regardless of whether auto stop is enabled
% or not.

status.stop = invoke(ps4000DeviceObj, 'ps4000Stop');

%% Process Data
% Process data post-capture if required - here the data will be plotted.

% Reduce size of arrays if required
if (totalSamples < maxSamples)
    
    pBufferChAFinal.Value(totalSamples + 1:end) = [];
    pBufferChBFinal.Value(totalSamples + 1:end) = [];
 
end

% Retrieve data for the channels.
channelAFinal = pBufferChAFinal.Value();
channelBFinal = pBufferChBFinal.Value();

% Plot total data collected on another figure.
finalFigure = = figure('Name','PicoScope 4000 Series Example - Streaming Mode Capture', ...
    'NumberTitle','off');
	
finalFigureAxes = axes('Parent', finalFigure);
movegui(finalFigure, 'east');
hold on;

title(finalFigureAxes, 'Streaming Data Acquisition (Final)');

if (strcmp(sampleIntervalTimeUnitsStr, 'us'))
        
    xlabel(finalFigureAxes, 'Time (\mus)');

else

    xLabelStr = strcat('Time (', sampleIntervalTimeUnitsStr, ')');
    xlabel(finalFigureAxes, xLabelStr);

end

ylabel(finalFigureAxes, 'Voltage (mV)');

% Find the maximum voltage range
maxYRange = max(channelARangeMV, channelBRangeMV);
ylim(finalFigureAxes,[(-1 * maxYRange) maxYRange]);

% Calculate values for time axis, then plot.
timeAxis = (double(actualSampleInterval) * double(downSampleRatio)) * [0:length(channelAFinal) - 1];
plot(time, channelAFinal, time, channelBFinal);

grid(finalFigureAxes, 'on');
legend(finalFigureAxes, 'Channel A', 'Channel B');
hold(finalFigureAxes, 'off');

%% Disconnect Device
% Disconnect device object from hardware.

disconnect(ps4000DeviceObj);
delete(ps4000DeviceObj);