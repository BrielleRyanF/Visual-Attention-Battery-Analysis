%--------------------------------------------------------------------------
%cell2num
%By: Brielle Ferguson
%Date: 7/13/18
%Function that will take a cell array and populate each cell into
%subsequent rows in a numerical array 
%--------------------------------------------------------------------------

function numArray = cell2num(cellArray)
if iscell(cellArray)
numArray = cellArray{1};
for i = 2:length(cellArray)
  numArray = [numArray;cellArray{i}];   
end

else
    numArray = cellArray;
end

end
