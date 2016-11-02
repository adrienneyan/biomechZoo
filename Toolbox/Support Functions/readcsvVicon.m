function r = readcsvVicon(fl)

% reads csv files generated by the Vicon Nexus "Export data to ASCII file" function
%
% VICON PROCESSING NOTES
% - all outputs should be checked in "ASCII Dump options"
% - "Invalid co-ordinate value" in "ASCII Dump options" should be left blank
%
% OTHER NOTES
% - Gait events identified in Nexus will appear under the event branch of the
%   SACR channel if it exists, otherwise, they will appear in the the first channel
%   in the video channel list
%
%
% Created by Philippe C. Dixon October 2012
%
% Updated by Philippe C. Dixon November 2013
% - event bug fixed



% Read csv file and clean up
%
txt= readtext(fl);                      % very slow
txt(cellfun(@isempty,txt)) = {NaN};     % clean

% Setup export variablres
%
r = struct;


% Find indices of each data types in csv file
%
INDXANALYSIS =[];
INDXEVENTS = [];                        % some events define in Vicon
INDXTRAJ = [];                          % the markers and model outputs
INDXANALOG = [];                        % analog data e.g. EMG
INDXFP = [];                            % force plate data

for j = 1:length(txt(:,1))
    
    if strcmp('ANALYSIS',txt{j,1});
        INDXANALYSIS = j;
    elseif strcmp('EVENTS',txt{j,1});
        INDXEVENTS = j;
    elseif  strcmp('TRAJECTORIES',txt{j,1});
        INDXTRAJ = j;
    elseif strcmp('ANALOG',txt{j,1});
        INDXANALOG = j;
    elseif strcmp('FORCE PLATES',txt{j,1});
        INDXFP = j;
    end
end

INDXALL = [INDXANALYSIS; INDXEVENTS; INDXTRAJ; INDXANALOG; INDXFP];


% Extract sampling rates
%
vidfreq = txt(INDXTRAJ+1);
vidfreq = vidfreq{1};

if ischar(vidfreq)
    vidfreq = str2double(vidfreq);
end

if ~isempty(INDXANALOG)
    analfreq = txt(INDXANALOG+1);
elseif ~isempty(INDXFP)
    analfreq = txt(INDXFP+1);
else
    analfreq = {[]};
end
analfreq = analfreq{1};



% Extract header information
%
% - Header is all information before first data section in capitals

header = txt(1:INDXALL(1)-2,1:2);

for i = 1:length(header)
    field = header{i,1};
    field = makevalidfield(field);
    r.Header.(field) = header{i,2};
end

% Extract event information
%
if ~isempty(INDXEVENTS)
    INDXNEXT = find(INDXALL>INDXEVENTS,1,'first');
    INDXNEXT = INDXALL(INDXNEXT);
    
    sframe = cell2mat(txt(INDXNEXT+4));
    nevents = INDXNEXT-INDXEVENTS-3;
    
    LeftFS = [];
    LeftFO = [];
    RightFS = [];
    RightFO = [];
    
    for i=1:nevents
        
        basename = [txt{INDXEVENTS+1+i,2} txt{INDXEVENTS+1+i,3}];
        basename = strrep(basename,' ','');
        val = txt{INDXEVENTS+1+i,4};
        val = val*vidfreq - sframe+1;
        val = round(val); % simply removes .000 from end of event
        
        if isin(basename,'LeftFootStrike')
            LeftFS = [LeftFS;val]; %#ok<AGROW>
            
        elseif isin(basename,'LeftFootOff')
            LeftFO = [LeftFO;val];%#ok<AGROW>
            
        elseif isin(basename,'RightFootStrike')
            RightFS = [RightFS;val];%#ok<AGROW>
            
        elseif isin(basename,'RightFootOff');
            RightFO = [RightFO;val];%#ok<AGROW>
            
        else
            disp('event name not found')
        end
        
    end
    
    LeftFS = sort(LeftFS);
    LeftFO = sort(LeftFO);
    RightFS = sort(RightFS);
    RightFO = sort(RightFO);
    
    for j = 1:length(LeftFS);
        r.Events.(['LeftFS',num2str(j)]) = [LeftFS(j) 0 0];
    end
    
    for k = 1:length(LeftFO);
        r.Events.(['LeftFO',num2str(k)]) = [LeftFO(k) 0 0];
    end
    
    for l = 1:length(RightFS);
        r.Events.(['RightFS',num2str(l)]) = [RightFS(l) 0 0];
    end
    
    for m = 1:length(RightFO);
        r.Events.(['RightFO',num2str(m)]) = [RightFO(m) 0 0];
    end
    
end

% Extract trajectory data
%
vch = txt(INDXTRAJ+2,:);

INDXNEXT = find(INDXALL>INDXTRAJ,1,'first');
INDXNEXT = INDXALL(INDXNEXT);

r.Video.data = cell2mat(txt(INDXTRAJ+4:INDXNEXT-2,:)); % all marker data

istk = ones(length(vch),1);
chstk = cell(length(vch),1);
for i = 1:length(vch)
    ch = vch{i};
    
    if ~isnan(ch)
        istk(i) = i;
        chstk{i} = ch;
    end
end

chstk(cellfun(@isempty,chstk)) = [];
r.Video.Channels = chstk; % overwrite vch with final video channels
r.Video.Freq = vidfreq;


% Extract Analog channels
%
if ~isempty(INDXANALOG)
    
    INDXNEXT = find(INDXALL>INDXANALOG,1,'first');
    INDXNEXT = INDXALL(INDXNEXT);
    
    r.Analog.data = cell2mat(txt(INDXANALOG+4:INDXNEXT-2,:)); % all marker data
    
    ach = txt(INDXANALOG+2,2:end);  % removes the first column (sample num
    
    chstk = cell(length(ach),1);
    for i = 1:length(ach)
        if ~isnan(ach{i})
            chstk{i} = ach{i};
        end
    end
    
    chstk(cellfun(@isempty,chstk)) = [];
    
    r.Analog.Channels = ['frames';chstk];
    r.Analog.Freq = analfreq;
end



% Extract force plate information
%
if ~isempty(INDXFP)
    
    subtxt = (txt(INDXFP:end,1));
    
    rr = zeros(length(subtxt),1,'single');
    for i = 1:length(subtxt)
        rr(i)= isin(subtxt{i},'Sample #');
    end
    INDXFPch = find(rr==1,1,'first');
    INDXFPch = INDXFP+INDXFPch-1;
    
    
    fpch = txt(INDXFPch,2:end); % remove column 1
    r.Forces.data = cell2mat(txt(INDXFPch+2:end,:)); % all marker data
    
    chstk = cell(length(fpch),1);
    for i = 1:length(fpch)
        if ~isnan(fpch{i})
            chstk{i} =fpch{i};
        end
    end
    
    chstk(cellfun(@isempty,chstk)) = [];
    fpch = chstk(1:end);
    
    r.Forces.Freq = analfreq;
    r.Forces.Channels = fpch;
    r.Forces.data = r.Forces.data(:,1:length(fpch)+1);   % all fpch columns + the index column
end





