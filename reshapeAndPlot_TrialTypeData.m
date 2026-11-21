%--------------------------------------------------------------------------
%reshapeAndPlot_TrialTypeData
%By: Brielle Ferguson
%Date: 3/5/24, updated name from plotAveAndSE_grouped on 11/16/26
%General Description: Will reshape values for prism and plot quant values as mean and SE 
% along with individual data points by trial type by group
%Assumptions: 
% -      data is a double array, and every value in the reshapeValue + 1 position is a Nan 
%        pulled from the quantification table (allQuant) is generated in readAnalyzePlotBehData_sessions
%Inputs: 
% -     allData: a 1 x number of groups cell array where each cell is a double array of 
%       values (pulled from allQuant) representing one feature repeated over by the length of trial types 
%       for each animal (e.g., cue length). Number of rows in double array is number of days
% -     sessionType: 'SSC', 'varCue'/'VarCL'/'4CL','varDL'/'VDST','DT',
%       'DT-VDST','SCL' or training sessions listed below (line 38)
%Outputs: 
% -     figHandle: your figure
% -     reshapedData: a structure with the following fields
% -         normPValues: a structure with your test statistics and p values from
%           the D_AgostinoPearson normality test 
% -         values : your average values for each trial type (cue length) for
%           each animal where each row is a trial type and each column is an
%           animal. 
% -         groupSize: The table split points for analysis are represented by an
%           array
% -         outlierIndex: if any outlers were detected, their index
%--------------------------------------------------------------------------

function [figHandle,reshapedData] = reshapeAndPlot_TrialTypeData(allData,sessionType)
colors = {[0 0 0],[1 0 1],[0 1 0],[0 0 1]};
groups = ['Group 1', 'Group 2', 'Group 3', 'Group 4'];
outlierThreshold = 3; 
takeAbsValue = false; %only for bias set to true, for everything else set to false

% update session type based on user input to get reshape value
if strcmp(sessionType, 'varCue') || strcmp(sessionType, 'VarCL') || strcmp(sessionType, '4CL')
 reshapeValue = 5; 
 vals = [2000,1000,500,50];
elseif strcmp(sessionType, 'VDST') || strcmp(sessionType, 'VarDL') 
 reshapeValue = 4; 
 vals = [3000,4000,5000];
elseif strcmp(sessionType, 'DT')
 reshapeValue = 5; 
  vals = [0,5,15,45];
elseif strcmp(sessionType, 'DT-VDST') %session type analysis not complete
 reshapeValue = 5; 
  vals = [0,5,15,45];
elseif strcmp(sessionType, 'SCL')
 reshapeValue = 5; 
 vals = [2000,1000,500,50];
end

numTrialTypes = reshapeValue - 1;
xAxis = 1:numTrialTypes;
figHandle = figure; 

for i = 1:length(allData)
thisGroup = nanmean(allData{i},1);
values{i} = plotAveAndSE_trialType(thisGroup,reshapeValue, colors{i});
groupSize(i) = size(values{i},2);
reshapedData.normResults{i} = D_AgostinoPearson(values{i},1);
reshapedData.normPValues{i} = reshapedData.normResults{i}.P;
end

xticks(xAxis);
xticklabels(vals);  
title('Average performance across sessions')
% yticks([25 50 75 100]);
% yline(50, '--k');
% ylabel('Percent correct');
%  set(gca,'ylim',[20 120]);

 reshapedData_combined = values{1};
 for i = 2:length(values)
     reshapedData_combined = [reshapedData_combined, values{i}];
 end

 if takeAbsValue
 reshapedData.values = abs(reshapedData_combined);
 else
 reshapedData.values = reshapedData_combined;  
 end

 reshapedData.groupSize = groupSize;
 reshapedData.normPValues = cell2num(reshapedData.normPValues);

 %check for animals that are outliers in each row (e.g., cue or delay length, distractor intensity) 
 reshapedData.outlierIndex = checkOutlierOverThreshold(reshapedData.values,outlierThreshold,1);

end

        