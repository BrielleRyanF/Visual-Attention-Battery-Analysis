%--------------------------------------------------------------------------
%findTrials
%By: Brielle Ferguson
%Date: 8/7/19
%Will separate continuous data into trials 
%Inputs
%- data: a continuous numerical array 
%- trialInitiationIndex: indeces within data that represent the beginning of each trial 
%- trialSU: desired length of trial in sample units
%- timePrior: time prior to index of trial start to collect in sample
%  units
%Output
%- allTrials: cell array of indidual trials of continuous data
%--------------------------------------------------------------------------
function allTrials = findTrials(data, trialInitiationIndex, trialSU, timePrior)
allTrials = {}; 

%loop through and find trials based on user parameters
for i = 1:length(trialInitiationIndex) 
    trialBegin = trialInitiationIndex(i) - timePrior;
    if trialBegin < 1 
        trialBegin = 1; 
    end
     trialEnd = trialBegin + trialSU; 
     if trialEnd > length(data)
         break
     end
     allTrials{i} = data(trialBegin:trialEnd); 
end
end