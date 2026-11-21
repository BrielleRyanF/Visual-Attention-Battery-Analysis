%--------------------------------------------------------------------------
%checkOutlierOverThreshold
%By: Brielle Ferguson
%Date: 1/4/24
%Can be used to check whether value in an array that represents a value
%that is greater than distance "threshold" from other values, through taking the
%zscores of the max distances between values in each group of values
%Inputs:
% - data: double array with independent values (animals, cells) organized by
%   row or column
% - threshold: the zscore over which the distance is considered an outlier.
%   note, I'd suggest 1.5 for replicate observations, and 3 if you're using this 
%   function to compare independent observations. 
% - dim: which dimension (rows vs. columns) in your array to test for outliers 
%Outputs:
% - outlierIndex: the columns which have distances between values where the
%   zscore is over the threshold
%-------------------------------------------------------------------------

function outlierIndex = checkOutlierOverThreshold(data,threshold,dim)

%get the max distance between values for each value
if size(data,1) > 1 && size(data,2) > 1

for i = 1:size(data,dim)
    if dim == 1
    thisSet = data(i,:);
    elseif dim == 2
    thisSet = data(:,i);
    end
    zScore{i} = zscore(thisSet);
end

else
    zScore = zscore(data);
end

%find index of which columns have distances between values that are over the
%threshold
zScore = cell2num(zScore);
outlierIndex = find(abs(zScore) >= threshold);

if isempty(outlierIndex)
disp('No Outliers Detected')
else
   disp('Outliers Detected') 
   transpose(data(outlierIndex))
end

end



