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
clear
% initialize a figure for future outputs
fig = uifigure('Name','DAVE Update via git');
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
    msg = {'A problem occured when accessing git.',...
        'Make sure git is installed and the specified path is correct.'};
    title = 'Git error';
    options = {'Select a new path','Disable git update','Skip to DAVE','View Error Output'};
    selection = uiconfirm(fig,msg,title,...
        'Icon','Error','Options',options);
    switch selection
        case options{1} %update the git path, save it and continue the update
            [file,path] = uigetfile('*.exe',...
               'Select your git executable','git.exe');
            config.GitPath = [path,file];
            writeConfig(config);
        case options{2} %set the opt out flag, save then skip ahead to DAVE
            config.Optout = true;
            writeConfig(config);
            msg = {'You disabled updates via git.',...
                'You might re-enable them by editing the "OptOut" value in "DAVEgit.cfg".'};
            title = 'Updates via git disabled';
            s = uiconfirm(fig,msg,title,'Icon','Info',...
                'Options',{'Continue to DAVE'});
            close(fig)
            return
        case options{3} %clsoe teh figure and continue to DAVE
            close(fig)
            return
        case options{4} %print the error output
            msg = cmdout;
            title = 'Git error message';
            s = uiconfirm(fig,msg,title,'Icon','Error',...
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

[stat,cmdout] = gitHelper(config.GitPath,'fetch','--verbose');
if isempty(cmdout)
    msg = 'Everything is already up to date with the remote repository.';
    title = 'No Update required';
    s = uiconfirm(fig,msg,title,'Icon','Success',...
        'Options',{'Continue to DAVE'});
    close(fig)
    return
else
    % split the output of the fetch command
    fetchOut = strsplit(cmdout);
    % find the local and remote branch pairs by locating the arrows first
    hasArrow = cellfun(@(x) strcmp(x,'->'),fetchOut);
%     hasArrow = horzcat(hasArrow{:});
    % select neighbours of arrow locations to get branch pairs
    i = 3;
    while i < size(hasArrow,2)
        if hasArrow(i) %arrow location found
            % set direct neighbours
            hasArrow(i-1) = 1;
            hasArrow(i+1) = 1;
            i = i+1; %skip direct neighbour
        end
        i = i+1; %advance to the next index
    end
    branchPairs = fetchOut(hasArrow);
    branchPairs = reshape(branchPairs,3,[])';
    msg = {'Updates for the following branches were found on the remote repository:',...
        strjoin(branchPairs(:,1),', '),'','How would you like to proceed?'};
    title = 'Updates found';
    if any(cellfun(@(x) strcmp(x,branch),branchPairs(:,1)))
        options = {'Update all',['Update current only: ',branch],'Do not update'};
    else
        options = {'Update all','Do not update'};
    end
    s = uiconfirm(fig,msg,title,'Icon','Question',...
        'Options',options);
    switch s
        case options{1} %mark all found branches for an update
            updateSel = true(size(branchPairs,1),1);    
        case branch %mark only the current branch for an update
            updateSel = cellfun(@(x) strcmp(x,branch),branchPairs(:,1));
        case options{end} %close the figure and continue to DAVE
            close(fig)
            return
    end
end

% ask for confirmation to update code if available
% "do not ask again"-Flag stored in "DAVEgit.cfg" 
if config.AskAgain
    title = 'Confirm git updates';
    msg = {'Please confirm that you are willing to update the following branches form the remote repository:',...
        strjoin(branchPairs(updateSel,1),', '),'',...
        'This might damage your local code base and will overwrite any unsaved changes.',...
        'Proceed only if you accept that possibility!'};
    options = {'Yes, update.','Yes, update. Never ask again.','No, abort.'};
    s = uiconfirm(fig,msg,title,'Icon','Warning','Options',options,...
        'DefaultOption',3);
    switch s
        case options{1} %ask for final confirmation, update
            title = 'Final confirmation';
            msg = {'Are you really sure you want to update now?',...
                'There is no turning back!'};
            finalOpt = {'Yes, I am sure.','No, I changed my mind.'};
            conf = uiconfirm(fig,msg,title,'Icon','Warning','Options',finalOpt,...
                    'DefaultOption',2);
            switch conf
                case finalOpt{1} %now really do the update
                    try %updating all selected branches
                        log = performGitUpdates(branchPairs(updateSel,:),branch,config.GitPath);
                        fileID = fopen('DAVEgit.log','w');
                        fprintf(fileID,'%s',log);
                        fclose(fileID);
                        msg = {'Everything is now up to date with the remote repository.','',...
                            'Confirmations are still enabled.',...
                            'You might disable them by editing the "AskAgain" value in "DAVEgit.cfg".'};
                        title = 'Update completed';
                        s = uiconfirm(fig,msg,title,'Icon','Success',...
                            'Options',{'Continue to DAVE'});
                        close(fig)
                        return
                    catch ME %handle errors
                        msg = {'An error occured while updating!',...
                            'You should inspect your code base, to confirm its integrity!','',...
                            'Confirmations are still enabled.',...
                            'You might disable them by editing the "AskAgain" value in "DAVEgit.cfg".'};
                        title = 'Update error';
                        errorOpt = {'Ok, continue to DAVE','View Error Output'};
                        cont = uiconfirm(fig,msg,title,'Icon','Error',...
                            'Options',errorOpt);
                        switch cont
                            case errorOpt{1} %continue to DAVE
                                close(fig)
                                return
                            case errorOpt{2} %print the error output
                                msg = ME.message;
                                title = 'Git error message';
                                errWindow = uiconfirm(fig,msg,title,'Icon','Error',...
                                    'Options',{'Continue to DAVE'});
                                close(fig)
                                return
                        end
                    end
                case finalOpt{2} %display a message and continue to DAVE
                    msg = {'No updates where applied.',...
                        'You will be asked to update again on next start.'};
                    title = 'No Update applied';
                    cont = uiconfirm(fig,msg,title,'Icon','Success',...
                        'Options',{'Continue to DAVE'});
                    close(fig)
                    return
            end
        case options{2} %ask for final confirmation, update, set the flag
            title = 'Final confirmation';
            msg = {'Are you really sure you want to update now?',...
                'There will also be no further confirmations in the future.',...
                'There is no turning back!'};
            finalOpt = {'Yes, I am sure.','No, I changed my mind.'};
            conf = uiconfirm(fig,msg,title,'Icon','Warning','Options',finalOpt,...
                    'DefaultOption',2);
            switch conf
                case finalOpt{1} %now really do the update and set the flag
                    try %updating all selected branches
                        log = performGitUpdates(branchPairs(updateSel,:),branch,config.GitPath);
                        fileID = fopen('DAVEgit.log','w');
                        fprintf(fileID,'%s',log);
                        fclose(fileID);
                        msg = {'Everything is now up to date with the remote repository.','',...
                            'Confirmations will be disabled now.',...
                            'You might re-enable them by editing the "AskAgain" value in "DAVEgit.cfg".'};
                        title = 'Update completed';
                        s = uiconfirm(fig,msg,title,'Icon','Success',...
                            'Options',{'Continue to DAVE'});
                        config.AskAgain = false;
                        writeConfig(config);
                        close(fig)
                        return
                    catch ME %handle errors
                        msg = {'An error occured while updating!',...
                            'You should inspect your code base, to confirm its integrity!','',...
                            'Confirmations are still enabled.',...
                            'You might disable them by editing the "AskAgain" value in "DAVEgit.cfg".'};
                        title = 'Update error';
                        errorOpt = {'Ok, continue to DAVE','View Error Output'};
                        cont = uiconfirm(fig,msg,title,'Icon','Error',...
                            'Options',errorOpt);
                        switch cont
                            case errorOpt{1} %continue to DAVE
                                close(fig)
                                return
                            case errorOpt{2} %print the error output
                                msg = ME.message;
                                title = 'Git error message';
                                errWindow = uiconfirm(fig,msg,title,'Icon','Error',...
                                    'Options',{'Continue to DAVE'});
                                close(fig)
                                return
                        end
                    end
                case finalOpt{2} %display a message and continue to DAVE
                    msg = {'No updates where applied.','',...
                        'You will be asked to update again on next start.',...
                        'The confirmations will also be required in the future.'};
                    title = 'No Update applied';
                    cont = uiconfirm(fig,msg,title,'Icon','Success',...
                        'Options',{'Continue to DAVE'});
                    close(fig)
                    return
            end
        case options{3} %display a message and continue to DAVE
            msg = {'No updates where applied.','',...
                'You will be asked to update again on next start.'};
            title = 'No Update applied';
            s = uiconfirm(fig,msg,title,'Icon','Success',...
                'Options',{'Continue to DAVE'});
            close(fig)
            return
    end
else %just update without confirmation
    try %updating all selected branches
        log = performGitUpdates(branchPairs(updateSel,:),branch,config.GitPath);
        fileID = fopen('DAVEgit.log','w');
        fprintf(fileID,'%s',log);
        fclose(fileID);
        msg = {'Everything is now up to date with the remote repository.','',...
            'Confirmations are disabled.',...
            'You might re-enable them by editing the "AskAgain" value in "DAVEgit.cfg".'};
        title = 'Update completed';
        s = uiconfirm(fig,msg,title,'Icon','Success',...
            'Options',{'Continue to DAVE'});
        close(fig)
        return
    catch ME %handle errors
        msg = {'An error occured while updating!',...
            'You should inspect your code base, to confirm its integrity!','',...
            'Confirmations are disabled.',...
            'You might re-enable them by editing the "AskAgain" value in "DAVEgit.cfg".'};
        title = 'Update error';
        errorOpt = {'Ok, continue to DAVE','View Error Output'};
        cont = uiconfirm(fig,msg,title,'Icon','Error',...
            'Options',errorOpt);
        switch cont
            case errorOpt{1} %continue to DAVE
                close(fig)
                return
            case errorOpt{2} %print the error output
                msg = ME.message;
                title = 'Git error message';
                errWindow = uiconfirm(fig,msg,title,'Icon','Error',...
                    'Options',{'Continue to DAVE'});
                close(fig)
                return
        end
    end
end

% Define the update process via git
function log = performGitUpdates(branchPairs,ogBranch,GitPath)
    %TODO
    log = '';
    for b = 1:size(branchPairs,1)
       branch = branchPairs{b,1};
       destination = branchPairs{b,3};
       destination = strsplit(destination,'/');
       remoteName = destination{1};
       remoteBranch = destination{2};
       
       [stat,cmdout] = gitHelper(GitPath,'checkout',branch,'--force');
       log = [log,cmdout];
       [stat,cmdout] = gitHelper(GitPath,'pull',remoteName,remoteBranch,'--force','--commit');
       log = [log,cmdout];
    end
    [stat,cmdout] = gitHelper(GitPath,'checkout',ogBranch,'--force');
    log = [log,cmdout];
end
% Define read/write functionality for the config file
function config = readConfig(fig)
    % read the standard config "DAVEgit.cfg"
    fileID = fopen('DAVEgit.cfg');
    % if there was no config file, ask how to proceed
    if fileID == -1
%         fig = uifigure;
        msg = {'Git update integration is not configured.','',...
            'How would you like to proceed?'};
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
                msg = {'A new default config was created.','',...
                    'You might need to adjust your git path in "DAVEgit.cfg".'};
                title = 'Default config created';
                s = uiconfirm(fig,msg,title,'Icon','Warning',...
                    'Options',{'Ok'});
            case options{2} %select git path
                config = struct();
                config.AskAgain = true;
                config.OptOut = false;
                [file,path] = uigetfile('*.exe',...
                    'Select your git executable','git.exe');
                config.GitPath = [path,file];
                writeConfig(config);
            case options{3} %opt out of git
                config = struct();
                config.AskAgain = true;
                config.GitPath = 'C:\Program Files\Git\bin\git.exe';
                config.OptOut = true;
                writeConfig(config);
                msg = {'You disabled updates via git.','',...
                    'You might enable them by editing "DAVEgit.cfg".'};
                title = 'Updates via git disabled';
                s = uiconfirm(fig,msg,title,'Icon','Warning',...
                    'Options',{'Ok'});
            case options{4} %return empty to skip straight to DAVE
                config = [];
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
function varargout = gitHelper(GitPath,varargin)
% THIS FUNCTION WAS ADAPTED FROM
% https://stackoverflow.com/a/42272702
%
% GIT Execute a git command.
%
% GITHELPER <ARGS>, when executed in command style, executes the git command and
% displays the git outputs at the MATLAB console.
% ARG1 needs to be the path to a git executable.
%
% STATUS = GITHELPER(ARG1, ARG2,...), when executed in functional style, executes
% the git command and returns the output status STATUS.
% ARG1 needs to be the path to a git executable.
%
% [STATUS, CMDOUT] = GITHELPER(ARG1, ARG2,...), when executed in functional
% style, executes the git command and returns the output status STATUS and
% the git output CMDOUT.
% ARG1 needs to be the path to a git executable.

% Check output arguments.
nargoutchk(0,2)

% Construct the git command. Surround the provided path with double
% quotation marks to comply with Windows policy.
winExePath = ['"',GitPath,'"'];
cmdstr = strjoin([winExePath, varargin]);

% Execute the git command.
[status, cmdout] = system(cmdstr);

switch nargout
    case 0
        disp(cmdout)
    case 1
        varargout{1} = status;
    case 2
        varargout{1} = status;
        varargout{2} = cmdout;
end
end