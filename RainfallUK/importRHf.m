function Station_RH = importRHf(station,fileaddress,StationRec)
%% importRHf	import hourly rainfall data of Met stations in London
%   Station_RH = importRHf(station,fileaddress): 
%       Import hourly rainfall data of selected station from original
%       files, station is the serial number of the stationl;fileaddress is
%       the location of original data files, which will be used when invoke
%       the subfunction.
%   Station_RH = importRHf(station,fileaddress,StationRec):
%       StationRec conveys information of hourly recorded met stations in London.       
%   Original data files was downloaded from MIDAS
%
% Created by Ming on 2015-11-24
% Renewed by Ming on 2015-11-26
%   See also importRDf.

%%
%fileaddress = 'C:\SheldonDocument\RH\yearly_files\';
if nargin==1
    load('StationRec_RH.mat','StationRec'); %load information of hourly recorded met stations in London    
end
%information of the selected station
m = find(StationRec.src_id==station); %met station: m th station in 'StationRec' 
StationID = StationRec(m).src_id; % srd_id of the met station
RecYears = StationRec(m).RecYear; % recorded years in this Met station

%% variables to be import
PRCP_AMT = zeros(2,1); %Precipitation amount, Units = 1mm
OB_HOUR_COUNT = PRCP_AMT; %Observation hour count
OB_END_TIME = cell(2,1); %Date and time at end of observation
PRCP_DUR = OB_END_TIME; %Precipitation duration (<24 hr) minutes
tic
n = 1; %sequence of records in variables newly defined above

%% scan yearly orginal data files and extract records of the selected station
for i = 1:length(RecYears) %import data year by year       
    y = RecYears(i); % years when the station has data recorded 
    
    % yearly data file is scanned by every ReadRows as a year file is two
    % large to be processed
    startRow = 1;
    ReadRows = 50000; % rows once scanning     
    
    % invoke function
    RH = importRHtxt(y,fileaddress,startRow,startRow+ReadRows);
    while (~isempty(RH.ID))       
        ind = find(RH.SRC_ID==StationID);
        if ~isempty(ind)                             
            OB_END_TIME(n:n+length(ind)-1) = RH.OB_END_TIME(ind);
            PRCP_AMT(n:n+length(ind)-1) = RH.PRCP_AMT(ind);
            PRCP_DUR(n:n+length(ind)-1) = RH.PRCP_DUR(ind);
            OB_HOUR_COUNT(n:n+length(ind)-1) = RH.OB_HOUR_COUNT(ind);    
            n = n+length(ind);
            disp(['Progress so sar: ', OB_END_TIME{end}])
        else
            disp(['No records between ',RH.OB_END_TIME{1},' to ', RH.OB_END_TIME{end}])
        end
        startRow = startRow+ReadRows;
        RH = importRHtxt(y,fileaddress,startRow,startRow+ReadRows);
    end
    
end
disp([StationRec(m).Name ': all recored rainfall data are extracted!'])
Station_RH = {PRCP_AMT, OB_HOUR_COUNT, OB_END_TIME, PRCP_DUR};
toc
end

%% subfunction for file scanning
function  RH = importRHtxt(year,fileaddress,startRow,endRow)
%Import numeric data from a text file as column vectors.
%   [OB_END_TIME,ID,ID_TYPE,OB_HOUR_COUNT,VERSION_NUM,MET_DOMAIN_NAME,SRC_ID,REC_ST_IND,PRCP_AMT,PRCP_DUR,PRCP_AMT_Q,PRCP_DUR_Q,METO_STMP_TIME,PRCP_AMT_J]
%   = IMPORTFILE1(FILENAME) Reads data from text file FILENAME for the
%   default selection.
%
%   [OB_END_TIME,ID,ID_TYPE,OB_HOUR_COUNT,VERSION_NUM,MET_DOMAIN_NAME,SRC_ID,REC_ST_IND,PRCP_AMT,PRCP_DUR,PRCP_AMT_Q,PRCP_DUR_Q,METO_STMP_TIME,PRCP_AMT_J]
%   = IMPORTFILE1(FILENAME, STARTROW, ENDROW) Reads data from rows STARTROW
%   through ENDROW of text file FILENAME.
%
% Example:
%   [OB_END_TIME,ID,ID_TYPE,OB_HOUR_COUNT,VERSION_NUM,MET_DOMAIN_NAME,SRC_ID,REC_ST_IND,PRCP_AMT,PRCP_DUR,PRCP_AMT_Q,PRCP_DUR_Q,METO_STMP_TIME,PRCP_AMT_J] = importfile1('midas_rainhrly_201401-201412.txt',1, 2590680);
%
%    See also TEXTSCAN.

% Auto-generated by MATLAB on 2015/05/25 17:54:08

%% Initialize variables.

filehead = 'midas_rainhrly_';
filetail = '.txt';
filename = [fileaddress, filehead, num2str(year),'01-',num2str(year),'12',filetail];
delimiter = ',';
if nargin<=2
    startRow = 1;
    endRow = 10000;
end

%% Read columns of data as strings:
% For more information, see the TEXTSCAN documentation.
formatSpec = '%s%s%s%s%s%s%s%s%s%s%[^\n\r]';

%% Open the text file.
fileID = fopen(filename);

%% Read columns of data according to format string.
% This call is based on the structure of the file used to generate this
% code. If an error occurs for a different file, try regenerating the code
% from the Import Tool.
dataArray = textscan(fileID, formatSpec,endRow(1)-startRow(1)+1, 'Delimiter', delimiter,'HeaderLines', startRow(1)-1, 'ReturnOnError', false);

%fclose(fileID);
%% Convert the contents of columns containing numeric strings to numbers.
% Replace non-numeric strings with NaN.
raw = repmat({''},length(dataArray{1}),length(dataArray)-1);
for col=1:length(dataArray)-1
    raw(1:length(dataArray{col}),col) = dataArray{col};
end
numericData = NaN(size(dataArray{1},1),size(dataArray,2));

for col=[2,4,5,7,8,9]
    % Converts strings in the input cell array to numbers. Replaced non-numeric
    % strings with NaN.
    rawData = dataArray{col};
    for row=1:size(rawData, 1);
        % Create a regular expression to detect and remove non-numeric prefixes and
        % suffixes.
        regexstr = '(?<prefix>.*?)(?<numbers>([-]*(\d+[\,]*)+[\.]{0,1}\d*[eEdD]{0,1}[-+]*\d*[i]{0,1})|([-]*(\d+[\,]*)*[\.]{1,1}\d+[eEdD]{0,1}[-+]*\d*[i]{0,1}))(?<suffix>.*)';
        try
            result = regexp(rawData{row}, regexstr, 'names');
            numbers = result.numbers;
            
            % Detected commas in non-thousand locations.
            invalidThousandsSeparator = false;
            if any(numbers==',');
                thousandsRegExp = '^\d+?(\,\d{3})*\.{0,1}\d*$';
                if isempty(regexp(thousandsRegExp, ',', 'once'));
                    numbers = NaN;
                    invalidThousandsSeparator = true;
                end
            end
            % Convert numeric strings to numbers.
            if ~invalidThousandsSeparator;
                numbers = textscan(strrep(numbers, ',', ''), '%f');
                numericData(row, col) = numbers{1};
                raw{row, col} = numbers{1};
            end
        catch me
        end
    end
end


%% Split data into numeric and cell columns.
rawNumericColumns = raw(:, [2,4,5,7,8,9]);
rawCellColumns = raw(:, [1,3,6,10]);


%% Replace non-numeric cells with NaN
R = cellfun(@(x) ~isnumeric(x) && ~islogical(x),rawNumericColumns); % Find non-numeric cells
rawNumericColumns(R) = {NaN}; % Replace non-numeric cells

%% Allocate imported array to column variable names
RH.OB_END_TIME = rawCellColumns(:, 1);
RH.ID = cell2mat(rawNumericColumns(:, 1));
RH.ID_TYPE = rawCellColumns(:, 2);
RH.OB_HOUR_COUNT = cell2mat(rawNumericColumns(:, 2));
RH.VERSION_NUM = cell2mat(rawNumericColumns(:, 3));
RH.MET_DOMAIN_NAME = rawCellColumns(:, 3);
RH.SRC_ID = cell2mat(rawNumericColumns(:, 4));
RH.REC_ST_IND = cell2mat(rawNumericColumns(:, 5));
RH.PRCP_AMT = cell2mat(rawNumericColumns(:, 6));
RH.PRCP_DUR = rawCellColumns(:, 4);


% For code requiring serial dates (datenum) instead of datetime, uncomment
% the following line(s) below to return the imported dates as datenum(s).

% OB_END_TIME=datenum(OB_END_TIME);
% METO_STMP_TIME=datenum(METO_STMP_TIME);
end