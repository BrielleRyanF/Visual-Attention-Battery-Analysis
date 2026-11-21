%--------------------------------------------------------------------------
%checkOutliersNormAndVariance
%By: Brielle
%Date: 4/1/24
%General Description: will check for outliers, normality, and variance in
%2 sets of data prior to additional statistical comparisons. Will print results
%in the command window and return them as function outputs
%Assumptions: 
% -       data has the format described below. 
% -       there aren't more than two groups, can look for outliers and normality
% -       for more than 2, but will only compare variance for 2. 
%Inputs: 
% -     data: 1 x 2 cell array where each cell contains n x 1 double array of data in
%       each group. 
%Outputs: 
% -     outlierIndex: cell array where each cell contains indexes for each group
% -     normResult: cell array where each cell contains the normality result for each group
% -     F: structure with the F statstic (F.stat) and p value (F.p).
%--------------------------------------------------------------------------

function [outlierIndex,normResult,F] = checkOutliersNormAndVariance(data)
outlierThreshold = 3; 
%check outliers and normality within each group
for i = 1:length(data)
    thisGroup = data{i};
    outlierIndex{i} = checkOutlierOverThreshold(thisGroup, outlierThreshold, 1);
    normResult{i} = D_AgostinoPearson(thisGroup,1);

end

%check whether your groups have equal variance
[~,F.p,~,stats] = vartest2(data{1},data{2});
F.stat = stats.fstat;
disp(['F test value for equal variance F Statistic: ', num2str(F.stat), ' P: ' num2str(F.p)]);
end