%% PS4000Config Configure path information
% Configures paths according to platforms and loads information from
% prototype files for PicoScope 4000 Series Oscilloscopes. The folder 
% that this file is located in must be added to the MATLAB path.
%
% Platform Specific Information:-
%
% Microsoft Windows: Download the Software Development Kit installer from
% the <a href="matlab: web('https://www.picotech.com/downloads#t3')">Pico Technology Download software and manuals for oscilloscopes and data loggers</a> page.
% 
% Linux: Follow the instructions to install the libps4000 and libpswrappers
% packages from the <a href="matlab:
% web('https://www.picotech.com/downloads/linux')">Pico Technology Linux Software & Drivers for Oscilloscopes and Data Loggers</a> page.
%
% Apple Mac OS X: Follow the instructions to install the PicoScope 6
% application from the <a href="matlab: web('https://www.picotech.com/downloads#t3')">Pico Technology Download software and manuals for oscilloscopes and data loggers</a> page.
% Optionally, create a 'maci64' folder in the same directory as this file
% and copy the libps4000.dylib, libps4000Wrap.dylib and libpicoipp.dylib files
% into it. Contact our Technical Support team via the <a href="matlab: web('https://www.picotech.com/tech-support/')">Technical Enquiries form</a> for further assistance.
%
% Run this script in the MATLAB environment prior to connecting to the 
% device.
%
% This file can be edited to suit application requirements.

%% Set Path to Shared Libraries
% Set paths to shared library files according to the operating system and
% architecture.

% Identify working directory
ps4000ConfigInfo.workingDir = pwd;

% Find file name
ps4000ConfigInfo.configFileName = mfilename('fullpath');

% Only require the path to the config file
[ps4000ConfigInfo.pathStr] = fileparts(ps4000ConfigInfo.configFileName);

% Identify architecture e.g. 'win64'
ps4000ConfigInfo.archStr = computer('arch');
ps4000ConfigInfo.archPath = fullfile(ps4000ConfigInfo.pathStr, ps4000ConfigInfo.archStr);

% Add path to Prototype and Thunk files if not already present
if (isempty(strfind(path, ps4000ConfigInfo.archPath)))

	try

		addpath(strcat(ps4000ConfigInfo.pathStr, '/', ps4000ConfigInfo.archStr, '/'));
		
	catch err
		
		error('PS4000Config:OperatingSystemNotSupported', 'Operating system not supported - please contact support@picotech.com');
		
	end
	
end

% Set the path to drivers according to operating system.

% Define possible paths for drivers - edit to specify location of drivers

ps4000ConfigInfo.macDriverPath = '/Applications/PicoScope6.app/Contents/Resources/lib';
ps4000ConfigInfo.linuxDriverPath = '/opt/picoscope/lib/';

ps4000ConfigInfo.winSDKInstallPath = 'C:\Program Files\Pico Technology\SDK';
ps4000ConfigInfo.winDriverPath = fullfile(ps4000ConfigInfo.winSDKInstallPath, 'lib');

% Windows 32-bit version of MATLAB on Windows 64-bit
ps4000ConfigInfo.woW64SDKInstallPath = 'C:\Program Files (x86)\Pico Technology\SDK'; 
ps4000ConfigInfo.woW64DriverPath = fullfile(ps4000ConfigInfo.woW64SDKInstallPath, 'lib');

if (ismac())
    
    % Libraries (including wrapper libraries) are stored in the PicoScope
    % 6 App folder. Add locations of library files to environment variable.
    
    setenv('DYLD_LIBRARY_PATH', ps4000ConfigInfo.macDriverPath);
    
    if (strfind(getenv('DYLD_LIBRARY_PATH'), ps4000ConfigInfo.macDriverPath))
        
        % Add path to drivers if not already on the MATLAB path
        if (isempty(strfind(path, ps4000ConfigInfo.macDriverPath)))
        
            addpath(ps4000ConfigInfo.macDriverPath);
            
        end
        
    else
        
        warning(PS4000Config:LibraryPathNotFound','Locations of libraries not found in DYLD_LIBRARY_PATH');
        
    end
    
elseif (isunix())
	    
    % Add path to drivers if not already on the MATLAB path
    if (isempty(strfind(path, ps4000ConfigInfo.linuxDriverPath)))
        
        addpath(ps4000ConfigInfo.linuxDriverPath);
            
    end
		
elseif (ispc())
    
    % Microsoft Windows operating system
    
    % Set path to dll files if the Pico Technology SDK Installer has been
    % used or place dll files in the folder corresponding to the
    % architecture. Detect if 32-bit version of MATLAB on 64-bit Microsoft
    % Windows.
    if (strcmp(ps4000ConfigInfo.archStr, 'win32') && exist('C:\Program Files (x86)\', 'dir') == 7)
    
		% Add path to drivers if not already on the MATLAB path
        if (isempty(strfind(path, ps4000ConfigInfo.woW64DriverPath)))
        
			try 
				
				addpath(ps4000ConfigInfo.woW64DriverPath);
				
			catch err
			   
				warning('PS4000Config:DirectoryNotFound', ['Folder C:\Program Files (x86)\Pico Technology\SDK\lib\ not found. '...
					'Please ensure that the location of the library files are on the MATLAB path.']);
				
			end
			
		end
        
    else
        
        % 32-bit MATLAB on 32-bit Windows or 64-bit MATLAB on 64-bit
        % Windows operating systems
		
		% Add path to drivers if not already on the MATLAB path
        if (isempty(strfind(path, ps4000ConfigInfo.winDriverPath)))
            
            try 

                addpath(ps4000ConfigInfo.winDriverPath);
            
			catch err
           
				warning('PS4000Config:DirectoryNotFound', ['Folder C:\Program Files\Pico Technology\SDK\lib\ not found. '...
					'Please ensure that the location of the library files are on the MATLAB path.']);
            
			end
			
		end
        
    end
    
else
    
    error('PS4000Config:OperatingSystemNotSupported', 'Operating system not supported - please contact support@picotech.com');
    
end

%% Set Path for PicoScope Support Toolbox Files if Not Installed
% Set MATLAB Path to include location of PicoScope Support Toolbox
% Functions and Classes if the Toolbox has not been installed. Installation
% of the toolbox is only supported in MATLAB 2014b and later versions.

% Check if PicoScope Support Toolbox is installed - using code based on
% <http://stackoverflow.com/questions/6926021/how-to-check-if-matlab-toolbox-installed-in-matlab How to check if matlab toolbox installed in matlab>

ps4000ConfigInfo.psTbxName = 'PicoScope Support Toolbox';
ps4000ConfigInfo.v = ver; % Find installed toolbox information

if (~any(strcmp(ps4000ConfigInfo.psTbxName, {ps4000ConfigInfo.v.Name})))
   
    warning('PS4000Config:PSTbxNotInstalled', 'PicoScope Support Toolbox not installed, searching on MATLAB Path.');
    
    % If the PicoScope Support Toolbox has not been installed, check to see
    % if the folder is on the MATLAB path, having been downloaded via zip
    % file.

    ps4000ConfigInfo.psTbxFound = strfind(path(), ps4000ConfigInfo.psTbxName);
   
    if (isempty(ps4000ConfigInfo.psTbxFound))

        warning('PS4000Config:PSTbxDirNotFound', 'PicoScope Support Toolbox directory not found - please ensure files are added to the MATLAB path.');
            
    end
    
end

% Change back to the folder where the script was called from.
cd(ps4000ConfigInfo.workingDir);

%% Load Enumerations and Structure Information
% Enumerations and structures are used by certain Intrument Driver functions.

% Find prototype file names based on architecture

ps4000ConfigInfo.ps4000MFile = str2func(strcat('ps4000MFile_', ps4000ConfigInfo.archStr));

[ps4000Methodinfo, ps4000Structs, ps4000Enuminfo, ps4000ThunkLibName] = ps4000ConfigInfo.ps4000MFile(); 
