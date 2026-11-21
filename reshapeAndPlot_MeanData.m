%--------------------------------------------------------------------------
%reshapeAndPlot_MeanData 
%By: Brielle Ferguson
%Date: 3/25/24, updated name from reshapeSessionMeans on 11/16/26
%General Description: Will reshape data for prism, and plot group comparison.
%Assumptions: 
% -      data is a double array, and every value in the reshapeValue + 1 position is a Nan 
%        pulled from the quantification table (allQuant) is generated in readAnalyzePlotBehData_sessions
%Inputs: 
% -     allData: a 1 x N cell array where N represents number of groups
%       each cell array is a session by total feature size  array of quant 
%       values representing one feature repeated  over by the length of 
%       reshapeValue for each animal. Since this is mean data will only have
%       data in every n values where n represents 1 + reshapeValue (e.g., 5 for VarCL, and DT, 4 VarDL) 
% -     sessionType: 'SSC', 'varCue'/'VarCL'/'4CL','varDL'/'VDST','DT',
%       'DT-VDST','SCL' or training sessions listed below (line 31)
% -     addValue: if for some reason your data isn't in position 1, indicate
%       how many numbers to add to your index (position 2, add 1)

%Outputs: 
% -     dailyData: structure with the following fields
%            groupSize: how many are in each group
%            normResults: a structure with your test statistics and p values from the D_AgostinoPearson normality test 
%            normPValues: pulled p values from above testing
%            values: values by day and animal, can paste into prism and see
%            each groups performance trends over multiple sessions
% -     meanData: 
%            descStats: see checkOutliersNormAndVariance for details 
%            values: average values across sessions for each animal
%            organized with each group in column
%--------------------------------------------------------------------------

function [dailyData,meanData] = reshapeAndPlot_MeanData(allData,sessionType,addValue)
outlierThreshold = 3;

% update session type based on user input to get reshape value
if strcmp(sessionType, 'varCue') || strcmp(sessionType, 'VarCL') || strcmp(sessionType, '4CL')
 reshapeValue = 5; 
elseif strcmp(sessionType, 'VDST') || strcmp(sessionType, 'VarDL') 
 reshapeValue = 4; 
elseif strcmp(sessionType, 'DT')
 reshapeValue = 5; 
elseif strcmp(sessionType, 'DT-VDST') %session type analysis not complete
 reshapeValue = 5; 
elseif strcmp(sessionType, 'SCL')
 reshapeValue = 5; 
end

for i = 1:length(allData)
    thisData = allData{i};
    indexes = 1:reshapeValue:length(thisData);
    indexes = indexes + addValue;
    %theseValues = abs(thisData(:,indexes));
    theseValues = thisData(:,indexes);

   % theseValues(theseValues == 0 ) = nan;
    values{i} = theseValues;
    dailyData.groupSize(i) = size(values{i},2);
    dailyData.normResults{i} = D_AgostinoPearson(values{i},1);
    dailyData.normPValues{i} = dailyData.normResults{i}.P;
end

 allValues = values{1};
 for i = 2:length(values)
     allValues = [allValues, values{i}];
 end

 dailyData.values = allValues;
 dailyData.normPValues = transpose(cell2num(dailyData.normPValues));

%check for animals that are outliers in each row (cue length) 
outlierIndex = checkOutlierOverThreshold(dailyData.values,outlierThreshold,1);

 %take average across days
 maxSize = 0;
 for i = 1:length(values)
    meanGroupedData{i} = nanmean(values{i},1) ;
    thisGroupSize = length(meanGroupedData{i});
    if thisGroupSize > maxSize
    maxSize = thisGroupSize;   
    end
 end

  %add NaNs so array sizes match
 for i = 1:length(values)
    if length(meanGroupedData{i}) < maxSize
        meanGroupedData{i} = [meanGroupedData{i},nan(1,(maxSize-length(meanGroupedData{i})))];
    end
 end

%check for outliers in each group 
[descStats.outlierIndex,descStats.normResult,descStats.F] = checkOutliersNormAndVariance(meanGroupedData);
meanData.descStats = descStats;
for i= 1:length(meanData.descStats.normResult)
meanData.normPValues{i} = meanData.descStats.normResult{i}.P;
end
meanData.descStats.normPValues = transpose(cell2num(meanData.normPValues));
meanData.values = transpose(cell2num(meanGroupedData));

figure;

plotBoxChartGroupData(meanData.values);

end