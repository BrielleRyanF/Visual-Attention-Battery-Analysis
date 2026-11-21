
%--------------------------------------------------------------------------
%plotBoxChartGroupData
%By: Brielle Ferguson
%Date: 3/5/24
%General Description: Will create a box chart with grouped data along with
%individual points
%Inputs: 
% -     data: number of samples x number of group double array
%Outputs: 
% -     Figure with a box chart and individual points comparing group data
%--------------------------------------------------------------------------
function plotBoxChartGroupData(data)
% Create box chart with individual data points
%figHandle = figure;
plotByAccuracy = true;
colors{1} = 'g';
colors{2} = 'k';
colors{3} = 'b';
boxchart(data, 'BoxFaceColor','k', 'MarkerStyle', 'o');
hold on

%add individual data points
for i = 1:size(data,2)
    if plotByAccuracy
    scatter(repmat(i, size(data,1)), data(:,i),[],colors{i}, 'filled'); % Group 1 data
    else
    scatter(repmat(i, size(data,1)), data(:,i), 'filled'); % Group 1 data
    end
end

% Set plot title and axis labels
% xlabel('Group/Accuracy');
% ylabel('Measure');

% Add grid
grid on;
end