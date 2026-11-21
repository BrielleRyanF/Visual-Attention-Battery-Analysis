%--------------------------------------------------------------------------
%reshapeAndPlot_responseTypeRTData 
%By: Brielle Ferguson
%Date: 12/13/24, name changed from plotFiPQuantFields_responseType 11/16/26
%Can be used to take FiP data analyzed previously with combineAndQuantifyFiPData_responseTypes and
%plot data across animals for each field in subplots withe following dimensions
%rows represent fields, and each column represents a cue length
%Inputs: 
% -     allData: a 1 x number of group cell array of quant values representing one feature repeated 
%       over by the length of the number of values for each animal. Number of rows in double array is number of
%       days
% -     sessionType: 'SSC', 'varCue'/'VarCL'/'4CL','varDL'/'VDST','DT',
%       'DT-VDST','SCL' or training sessions listed below (line 41)
% -     meanValues: boolean, set true if you also want analysis and plotting 
%       of data averaged across trial types (e.g., cue or delay length)
%Outputs: 
% -     groupData: table of data organized by trial type in each row,
%       animal in each column, and repeats for each response type
%       (three-way anova table in prism)
% -     meanGroupedData: table of data organized by response type in each row,
%       animal in each column (two-way anova table in prism)
% -     anova table: will print the results of anova in a separate window 
%-------------------------------------------------------------------------

function [groupData, meanGroupedData] = reshapeAndPlot_responseTypeRTData(allData,sessionType, meanValues)
%define colors below
%colors = [0 0.4470 0.7410; 0.4940 0.1840 0.5560; 0.8500 0.3250 0.0980; 0.9290 0.6940 0.1250;];
colors = [0.1608 0.5490 0.5490; 0.6235 0.7843 0.7843; 0.7216  0.5176 0.7216; 0.5020  0  0.4549];
yLim = [0 2];
numResponseTypes = 4; 
figure;
hold on;

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

%used the following code to shape the response table values into a 1 x n cell array
% of a x b tables where a = numReponseTypes (cue lengths) and b = numAnimals
% and n is the number of trial types
numPlots = length(allData);
for i = 1:length(allData)
%pull out this group
thisData = allData{i};
indexes = 1:reshapeValue:length(thisData);
thisData(:,indexes) = [];


for j = 1:size(thisData,1)
    thisField = thisData(j,:);
    allTables{j} = reshape(thisField,numTrialTypes,[]);
end

groupData{i} = allTables;

% Initialize arrays to store mean and standard deviation data
meanGroupedData = zeros(numTrialTypes, 4); % Mean data for each response type and cue length
stdErrorData = zeros(numTrialTypes, 4);  % Standard deviation data for each response type and cue length

% Calculate mean and standard deviation for each response type and cue length
for j = 1:4 % Iterate over each response type
    % Calculate mean and standard deviation for each cue length across animals
    numSamples = size(allTables{j}, 2);
    meanGroupedData(:, j) = mean(allTables{j}, 2);
    stdErrorData(:, j) = std(allTables{j}, 0, 2) / sqrt(numSamples);
end

% Create a line graph with mean and standard error for each trial type, each
% subplot will have its own trial types
subplot(1,numPlots,i); hold on
for j = 1:4
    thisGroup = allTables{j};
plotAveAndSE_cueLength(thisGroup,colors(j,:));

end


%update axis
title(strcat('Group', i));
xAxis = 1:length(vals);
xticks(xAxis);
xticklabels(vals);  
xlabel('Cue Length (ms)');
ylabel('Reaction Time');
set(gca,'ylim',yLim);
ax = gca; 

end

if numPlots == 3
    set(gcf,'Position', [1404 317 560 359])
end

if meanValues


%take mean across trial types (cue lengths/delay lengths)
for i = 1:length(groupData)
thisGroup = groupData{i};
for j = 1:numResponseTypes
thisGroupMeans{j} = mean(thisGroup{j},1);
end
meanGroupData{i} = cell2num(thisGroupMeans);
end

%take mean and SE across subjects 
clear meanGroupedData
clear stdErrorData
for i = 1:length(meanGroupData)
meanGroupedData(i,:) = mean(meanGroupData{i},2);
stdErrorData(i, :) = std(meanGroupData{i}, 0, 2) / sqrt(size(meanGroupData{i}, 2));  % SEM calculation
end

linePlotGroupedData_indPoints(meanGroupData,sessionType)
set(gcf,'Position', [882 243 188 420])

%reshape data for an anova looking at the effect of group on response type
combined_data = vertcat(meanGroupData{:});
group1_size = size(meanGroupData{1},2); group2_size = size(meanGroupData{2},2);
response_type_group1 = [ones(1,group1_size);2*ones(1,group1_size);3*ones(1,group1_size);4*ones(1,group1_size) ];
response_type_group2 = [ones(1,group2_size);2*ones(1,group2_size);3*ones(1,group2_size);4*ones(1,group2_size) ];
response_type = [response_type_group1;response_type_group2];
group = [ones(size(response_type_group1));2*ones(size(response_type_group2)) ];

combined_data = reshape(combined_data,[],1);
response_type = reshape(response_type,[],1);
group = reshape(group,[],1);

[~,~,stats] = anovan(combined_data,{response_type,group},"Model","interaction", ...
    "Varnames",["Response Type","Group"]);


else


% Combine data from both groups into one matrix and create a variable indicating the response type
responseTable1_combined = [groupData{1}{1}, groupData{1}{2}, groupData{1}{3}, groupData{1}{4}];
responseTable2_combined = [groupData{2}{1}, groupData{2}{2}, groupData{2}{3}, groupData{2}{4}];
combined_data = [responseTable1_combined, responseTable2_combined];
if numTrialTypes == 4
trialType = [ones(1,size(combined_data,2));2*ones(1,size(combined_data,2));3*ones(1,size(combined_data,2));4*ones(1,size(combined_data,2)) ];
elseif numTrialTypes == 5
trialType = [ones(1,size(combined_data,2));2*ones(1,size(combined_data,2));3*ones(1,size(combined_data,2));4*ones(1,size(combined_data,2));5*ones(1,size(combined_data,2)) ];
elseif numTrialTypes == 3
trialType = [ones(1,size(combined_data,2));2*ones(1,size(combined_data,2));3*ones(1,size(combined_data,2))];
end
group1_size = size(groupData{1}{1}); group2_size = size(groupData{2}{1});
response_type_group1 = [ones(group1_size),2*ones(group1_size),3*ones(group1_size),4*ones(group1_size) ];
response_type_group2 = [ones(group2_size),2*ones(group2_size),3*ones(group2_size),4*ones(group2_size) ];
response_type = [response_type_group1,response_type_group2];
group = [ones(size(responseTable1_combined)),2*ones(size(responseTable2_combined)) ];

combined_data = reshape(combined_data,[],1);
trialType = reshape(trialType,[],1);
response_type = reshape(response_type,[],1);
group = reshape(group,[],1);


[~,~,stats] = anovan(combined_data,{trialType,response_type,group},"Model","interaction", ...
    "Varnames",["Cue Length","Response Type","Group"]);

%[results,~,~,gnames] = multcompare(stats,"Dimension",[1 2]);
end
end
