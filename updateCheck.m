% This file is part of DAVE, a MATLAB toolbox for data evaluation.
% Copyright (C) 2018-2019 Saarland University, Author: Manuel Bastuck
% Website/Contact: www.lmt.uni-saarland.de, info@lmt.uni-saarland.de
% 
% The author thanks Tobias Baur, Tizian Schneider, and Jannis Morsch
% for their contributions.
% 
% This program is free software: you can redistribute it and/or modify
% it under the terms of the GNU Affero General Public License as published
% by the Free Software Foundation, either version 3 of the License, or
% (at your option) any later version.
% 
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU Affero General Public License for more details.
% 
% You should have received a copy of the GNU Affero General Public License
% along with this program.  If not, see <http://www.gnu.org/licenses/>.


% This Script will check whether there exists a newer version of the source
% code for the DAV^3E program and if so offer to update.
% A setup process needs to be completed on the first use.

% initialize a figure for future outputs
fig = uifigure;
% load the existing configuration from "DAVEgit.cfg"
config = readConfig(fig);
% skip updating if there was no config or the user opted out
if ~isstruct(config) || config.OptOut
    close(fig)
    return
end

% check if git is installed/working if not ask for the
% path and store it for later use in "DAVEgit.cfg"
% offer error text review for debugging
[stat,cmdout] = gitHelper(config.GitPath,'status');
if stat
    msg = ['A problem occured when accessing git.',...
        'Make sure git is installed and the specified path is correct.'];
    title = 'Git error';
    options = {'Select a new path','Disable git update','Skip to DAVE','View Error Output'};
    selection = uiconfirm(fig,msg,title,...
        'Icon','Warning','Options',options);
    switch selection
        case options{1} %update the git path, save it and continue the update
            [file,path] = uigetfile('*.exe',...
               'Select your git executable','git.exe');
            config.GitPath = [path,file];
            writeConfig(config);
        case options{2} %set the opt out flag, save then skip ahead to DAVE
            config.Optout = true;
            writeConfig(config);
            msg = 'You disabled updates via git. You might enable them by editing "DAVEgit.cfg".';
            title = 'Updates via git disabled';
            s = uiconfirm(fig,msg,title,'Icon','Warning',...
                'Options',{'Ok'});
            close(fig)
            return
        case options{3} %do nothing
            close(fig)
            return
        case options{4} %print the error output
            msg = cmdout;
            title = 'Git error message';
            s = uiconfirm(fig,msg,title,'Icon','Warning',...
                'Options',{'Continue to DAVE'});
            close(fig)
            return
    end
end

% check if updates are present on the remote repository
% highlight if updates happened to tracked branch
% allow selective pulling
%TODO
% extract relevant branch from the status output
statusOut = strsplit(cmdout);
branch = statusOut{3};

[stat,cmdout] = gitHelper(config.GitPath,'fetch');
if isempty(cmdout)
    msg = 'Everything is up to date.';
    title = 'Update result';
    s = uiconfirm(fig,msg,title,'Icon','Success',...
        'Options',{'Ok'});
    close(fig)
    return
else
    fetchOut = strsplit(cmdout);
end

% ask for confirmation to update code if available
% allow indefinite suspesion of updates 
% "do not ask again"-Flag stored in "DAVEgit.cfg" 
%TODO

% Define read/write functionality for the config file
function config = readConfig(fig)
    % read the standard config "DAVEgit.cfg"
    fileID = fopen('DAVEgit.cfg');
    % if there was no config file, ask how to proceed
    if fileID == -1
%         fig = uifigure;
        msg = ['Git update integration is not configured.' ...
            'How would you like to proceed?'];
        title = 'Missing config';
        options = {'Create default config','Select git path','Disable git update','Skip to DAVE'};
        selection = uiconfirm(fig,msg,title,...
            'Icon','Warning','Options',options,...
            'DefaultOption',1,'CancelOption',4);
        switch selection
            case options{1} %create default
                config = struct();
                config.AskAgain = true;
                config.GitPath = 'C:\Program Files\Git\bin\git.exe';
                config.OptOut = false;
                writeConfig(config);
                msg = 'A new default config was created. You might need to adjust your git path in "DAVEgit.cfg".';
                title = 'Default config created';
                s = uiconfirm(fig,msg,title,'Icon','Warning',...
                    'Options',{'Ok'});
                return
            case options{2} %select git path
                [file,path] = uigetfile('*.exe',...
                    'Select your git executable','git.exe');
                config.GitPath = [path,file];
                writeConfig(config);
%                 close(fig)
            case options{3} %opt out of git
                config = struct();
                config.AskAgain = true;
                config.GitPath = 'C:\Program Files\Git\bin\git.exe';
                config.OptOut = true;
                writeConfig(config);
                msg = 'You disabled updates via git. You might enable them by editing "DAVEgit.cfg".';
                title = 'Updates via git disabled';
                s = uiconfirm(fig,msg,title,'Icon','Warning',...
                    'Options',{'Ok'});
                return
            case options{4} %return empty to skip straight to DAVE
                config = [];
                return
        end
    else %if we had a config file
        % scan the config file, drop all "=" and close the file
        configCell = textscan(fileID,'%s %s %q');
        configCell(2) = [];
        configCell = horzcat(configCell{:});
        fclose(fileID);
        
        % create a config struct according to the file, keep default options
        % keep default options where the file had none
        % only expected options are copied to the struct
        config = struct();
        config.AskAgain = true;
        config.GitPath = 'C:\Program Files\Git\bin\git.exe';
        config.OptOut = false;
        for i = 1:size(configCell,1)
            switch configCell{i,1}
                case 'AskAgain' %default to true on non false input
                    config.AskAgain = ~strcmp(configCell{i,2},'false');
                case 'GitPath'
                    config.GitPath = configCell{i,2};
                case 'OptOut' %default to false on non true input
                    config.OptOut = strcmp(configCell{i,2},'true');
            end
        end
        % write the config to fill leftout options with default values
        writeConfig(config)
    end
end
function writeConfig(config)
    % prepare the config struct contents for writing
    configCell = cell(3,2);
    configCell(:,1) = {'AskAgain';'GitPath';'OptOut'};
    if config.AskAgain
        configCell{1,2} = 'true';
    else
        configCell{1,2} = 'false';
    end
    configCell{2,2} = config.GitPath;
    if config.OptOut
        configCell{3,2} = 'true';
    else
        configCell{3,2} = 'false';
    end
    configCell = configCell';
    % open the standard config "DAVEgit.cfg" for writing
    fileID = fopen('DAVEgit.cfg','w');
    fprintf(fileID,'%s = "%s"\n',configCell{:});
    fclose(fileID);
end