%--------------------------------------------------------------------------
%linePlotGroupedData_indPoints
%By: Brielle Ferguson
%Date: 9/1/24
%Will take grouped data and make line plots for each group with error bars and individual aniimal points.
%and save data in current directory if saving set to true. 
%Inputs:
% - sessionType: 'SSC', 'varCue'/'VarCL'/'4CL','varDL'/'VDST','DT',
%   'DT-VDST','SCL' or training sessions listed below (line 34)
% - groupedData : 1 x group cell array, where each cell holds a table of your average values
%   for each trial type and animal. Each row is a trial type and each column is an
%   animal. 
%Outputs:figure, saved if saving set to true below 
%-------------------------------------------------------------------------

function  linePlotGroupedData_indPoints(groupedData,sessionType)

%select color set
%colors = {'#4ecb8d', '#c701ff','#ff9d3a'}; %teal, magenta, orange, currently
%using for graphs of dev groups (combined males and females)
%colors = {'#008dff', '#4ecb8d'}; %light blue and teal, currently using for adol
%colors = {'#ff73b6', '#c701ff'}; %thistle and magenta, currently using for yAdult
colors = {'#f9e858','#ff9d3a'}; %yellow and orange, currently usingbya for aAdult
%colors = {'#4ecb8d', '#ff9d3a'}; %teal and orange, using for DT comparison between adol and aAdult%
%colors = {'#000000','#c701ff','#4ecb8d', }; %black, magenta, and teal, using for CNTNAP
%colors = {'#5757f9',  '#595a5a'}; %purple and gray, for Emma APP figs

yAxis = [0 60]; %set based on type of data, see template
saving = true;
figFilename = 'VarCL yAdult Omissions Implant vs Non';
%trialTypeSet = {'CC', 'EC', 'CE', 'EE'};

%update axes labels based on session type
if strcmp(sessionType, 'varCue') || strcmp(sessionType, 'VarCL') || strcmp(sessionType, '4CL') 
    trialTypeSet = {'2s', '1s', '.5s', '.05ms'};
elseif strcmp(sessionType, 'VDST') || strcmp(sessionType, 'VarDL') 
    trialTypeSet = {'3s', '4s', '5s'};
elseif strcmp(sessionType, 'DT')
    trialTypeSet = {'0', '5', '15', '45'};
elseif strcmp(sessionType, 'DT-VDST')
    trialTypeSet = {'3s', '4s', '5s'};
elseif strcmp(sessionType, 'SCL')
    trialTypeSet = {'2s', '1s', '.5s', '.05ms'};
end

%take mean and standard error across subjects
for i = 1:length(groupedData)
    avgMeasure{i} = nanmean(transpose(groupedData{i}));
    stdError{i} = std(transpose(groupedData{i}),"omitnan")/sqrt(length(transpose(groupedData{i})));
end

%update scatter positions based on number of groups
if length(groupedData) == 2
pointAdjustment = [-0.20, 0.20];
elseif length(groupedData) == 3
pointAdjustment = [-0.20, 0,  0.20];    
end

%plot measure by trial type as line graph with mean and SE
figure(101); 
hold off
% code for closed circles
for i = 1:length(groupedData)
plot(avgMeasure{i}, '-o', 'Color', colors{i}, 'MarkerFaceColor', colors{i},  'MarkerSize', 20, 'LineWidth',3);
hold on
errorbar(avgMeasure{i}, stdError{i}, '-o', 'Color', colors{i}, 'CapSize',25, 'LineWidth',3);    
end

%code for open circles
%for i = 1:length(groupedData)
%plot(avgMeasure{i}, '-o', 'Color', colors{i}, 'MarkerEdgeColor', colors{i},  'MarkerSize', 20, 'LineWidth',3);
%hold on
%errorbar(avgMeasure{i}, stdError{i}, '-o', 'Color', colors{i}, 'CapSize',25, 'LineWidth',3);    
%end
    
xAxis = 1:length(trialTypeSet);
xticks(xAxis);
set(gca,'TickLength',[0 0])
xticklabels(trialTypeSet);    
yticks([0 1 2 3 4]);
set(gca,'TickLength',[0 0])
set(gca,'ylim',yAxis);

% plot individual points with line graph
for i = 1:length(groupedData) %loop through group
    data = transpose(groupedData{i});    
    for j = 1:size(data,2) %loop through each trial type
    
        %code for closed circles
   scatter(repmat(j+pointAdjustment(i), size(data)), data(:,j),...
   'MarkerFaceColor', colors{i}, 'MarkerFaceAlpha',0.25, 'MarkerEdgeColor', 'none'); 

%code for open circles
%scatter(repmat(j+pointAdjustment(i), size(data)), data(:,j),...
%'MarkerEdgeColor',colors{i}); 

    end
end

if saving
saveas(gcf, figFilename, 'pdf'); %save figure as a pdf
end

end
 
   