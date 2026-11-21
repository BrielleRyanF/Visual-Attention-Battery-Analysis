%--------------------------------------------------------------------------
%readAnalyzePlotBehData_adjustTTL
%By: Brielle Ferguson
%Date: 1/10/18
%Function that will take serial monitor data collected from the arduino
%"OperantTaskMasterScript" sketch. It will read in that
%data, and then plot it onto a figure. The graph 
%will use the animalID the user has provided, and then will also display
% descriptive information read from the data (session length, left, 
% right, correct and incorrect trials). The plot will show trial
% initiation, and left and right choices over time. Correct choices will be in 
%green, while incorrect will be in red.
%Assumptions:
% - the variable behData (output from the arduino serial monitor) is already loaded into matlab
%Inputs:
% - data: cell array of text data from arduino serial monitor (behData)
% - animalID: string of animal ID
% - sessionType: 'SSC', 'varCue'/'VarCL'/'4CL','varDL'/'VDST','DT',
%   'DT-VDST','SCL' or training sessions listed below (line 78)
% - optoStim: boolean, true if function should search for opto trials in data
%Outputs:
% - summary: structure with accuracy at each cue length, omissions, and other
%   descriptives about session
% - trials: structure with each trial including the fields, trial number,
%   accuracy, choice, cue length, response time, and opto.
%--------------------------------------------------------------------------

function [summary, trials] = readAnalyzePlotBehData_adjustTTL(data, animalID, sessionType, optoStim, correctionTime)
%% Set up processing, plotting, and analysis parameters

%cue parameters
cueLength = 5; %if cueLengthVariable = false, will use this value to analyze data
plotCueLengthData = true; %will plot accuracy at each cue length if cueLengthVariable = true

%delay parameters 
delayLength = 0; %if delayLengthVariable = false, will use this value to analyze data 
plotDelayLengthData = true; %will plot accuracy at each delay length if delayLengthVariable = true

%distractor task parameters
plotDistractorData = true;

%crossmodal analysis parameters
crossmodalTrials = false; %true if using visual and auditory trials

%include omissions in determing accuracy
calculateOmissions = true; %trials where animal takes longer than omissionThreshold to make choice will count as omissions
omissionThreshold = 5; %in seconds

%reaction time
%code may send a TTL pulse to mark trial initiation of a certain length. If
%sendtrialInitiationTTL is set to true in the Arduino sketch, then set value
%below to true and input the length of the ttl pulse. All data collected prior to
%11/7/23 should be .500, after is .200 to correct for this delay
adjustForTTL = true; 
if adjustForTTL
    ttlLength = correctionTime; %length of ttl in seconds
else
    ttlLength = 0;
end

%calculate sensitivity and bias
sigDetectAnalysis = true;

%plotting data
noPlots = false; 
plotAllTrials = true; %create plot of all trials and descriptive session information  
plotToExternalFigure = true; %set to true if will be calling repeatedly from an outside script to generate multiple subplots
plotAccuracyandRTOverlay = false; 

%opto parameters, if optoStim = true, will use these variables for plotting
%and analysis
optoStimThisTrial = false; %variable will be updated as matlab reads each trial, don't need to update
optoStimBlocks  = false; %set to true if opto stim is in fixed length blocks
optoStimRandom = true; %set to true if opto stim occurs randomly
plotOptoData = true; %will generate plots of accuracy in opto vs no opto trials

%% update session type based on user input
if strcmp(sessionType, 'varCue')|| strcmp(sessionType, '4CL') || strcmp(sessionType, 'VarCL')
    cueLengthVariable = true;
    delayLengthVariable = false;
    distractorCues = false;
    blockSize = 8;
elseif strcmp(sessionType, 'VDST Training') || strcmp(sessionType, 'VDSTTraining')
    cueLengthVariable = false;
    cueLength = 1;
    delayLengthVariable = false;
    delayLength = 2; 
    distractorCues = false;  
    blockSize = 10;
elseif strcmp(sessionType, 'VDST') || strcmp(sessionType, 'VarDL')
    cueLengthVariable = false;
    cueLength = 0.5;
    delayLengthVariable = true;
    distractorCues = false;
    blockSize = 6;
elseif strcmp(sessionType, 'DT')
    cueLengthVariable = false;
    cueLength = .5;
    delayLengthVariable = false;
    distractorCues = true;
    blockSize = 16;
elseif strcmp(sessionType, 'DTTraining') || strcmp(sessionType, 'DT Training')
    cueLengthVariable = false;
    cueLength = .5;
    delayLengthVariable = false;
    distractorCues = true;
    blockSize = 10;
elseif strcmp(sessionType, 'DT-VDST Training') || strcmp(sessionType, 'DT-VDSTTraining')
    cueLengthVariable = false;
    delayLengthVariable = false;
    distractorCues = false;  
    blockSize = 10;
elseif strcmp(sessionType, 'DT-VDST') %this analysis is not ready yet
    cueLengthVariable = false;
    delayLengthVariable = true;
    plotCueLengthData = false;
    plotDelayLengthData = false;
    distractorCues = true;
    blockSize = 8;
elseif strcmp(sessionType, 'SSC')
    cueLengthVariable = false;
    cueLength = 5; 
    delayLengthVariable = false;
    distractorCues = false;  
    blockSize = 10;
elseif strcmp(sessionType, 'SCL')
    cueLengthVariable = true;
    delayLengthVariable = false;
    distractorCues = false;
    blockSize = 8;
elseif strcmp(sessionType, 'TITraining') || strcmp(sessionType, 'TI Training')
    cueLengthVariable = false;
    delayLengthVariable = false;
    distractorCues = false;  
    blockSize = 10;
    calculateOmissions = false;
end



%% clean up data file, find time stamps, choices, and accuracy for each trial

%pre-allocating variables for analysis
portEntry = {};
correctTrials = {};
incorrectTrials = {};
accuracy = []; 

%get rid of any extra trials, returns to center port, and the clean
%ports trials. 
[data] = cleanUpOperantData(data);
if length(data) > 1
%pull out time of each entry in the log 
for i = 1: length(data)
stringTime = char(data(i));
stringTime = stringTime(1:12);
timeString = datetime(stringTime, 'Format', 'HH:mm:ss.SSS');
smTime(i) = timeString;     
end

%find all the choices 
for i = 1: length(data)
stringEntry = char(data(i));
portEntry(i) = {stringEntry(17)};
end

%find whether the choice was correct or incorrect 
if strcmp(sessionType,'TITraining')
for i = 1: length(data)
stringReward = char(data(i));
    if contains(stringReward, 'Dispensing')
    allChoices{i} = {stringReward(17)};
    allChoiceIndex(i) = i; 
    end     
end
allChoiceIndex(allChoiceIndex == 0) = [];
 allChoices = allChoices(~cellfun('isempty',allChoices));
else
for i = 1: length(data)
stringAccuracy = char(data(i));
    if contains(stringAccuracy, ' Correct')
    correctTrials(i) = {stringAccuracy(17)};
    end
    if contains(stringAccuracy, ' Incorrect')
    incorrectTrials(i) = {stringAccuracy(17)};
    end        
end
end
%% creating indexes of correct and incorrect choices with side information 
    
%at this point have an array the size of all the choices, empty except for 
%where there was a choice, either correct or incorrect. This will find each
%of those positions and save the index into a new array. 
correctTrialIndex = find(~cellfun(@isempty,correctTrials));
incorrectTrialIndex = find(~cellfun(@isempty,incorrectTrials));

%create index of all the trials  
allTrialIndex = sort([correctTrialIndex incorrectTrialIndex]);

%take those correct and incorrect indexes and separate them into left and right choices 
leftCorrect = correctTrialIndex(all(ismember(char(portEntry(correctTrialIndex)),'L'),2));
rightCorrect = correctTrialIndex(all(ismember(char(portEntry(correctTrialIndex)),'R'),2));

leftIncorrect = incorrectTrialIndex(all(ismember(char(portEntry(incorrectTrialIndex)),'L'),2));
rightIncorrect = incorrectTrialIndex(all(ismember(char(portEntry(incorrectTrialIndex)),'R'),2));

%calculate the percentage of correct total trials of all types  
percentCorrect = round(((length(correctTrialIndex)/(length(correctTrialIndex) + length(incorrectTrialIndex))) * 100),1);

%determine the total amount of choices made on each side 
numLeftChoices = length(leftCorrect) + length(leftIncorrect);
numRightChoices = length(rightCorrect) + length(rightIncorrect);

%find the start of all trials and get sum to get the total number of
%trials
trialAvailable = find(all(ismember(char(portEntry),'T'),2));
numTrials = length(trialAvailable); 

%find the trial initiation point (always the next point in array after the trial is available)
centerChoices = trialAvailable + 1;
if centerChoices(end) > length(smTime)
    centerChoices(end) = [];
end

%useful if the animal has multiple sessions or had to restart the session
beginSession = find(all(ismember(char(portEntry), 'B'), 2)); 

%% calculate time and speed information about the session

%convert time data from time of day to absolute time elapsed from start and
%convert to seconds
smTime = smTime - smTime(1); 
smTime.Format = 's';

%find beginning and end of the session and total session length in seconds
%and minutes 
beginTime = smTime(1);
endTime = smTime(end) + minutes(1);
sessionLength = smTime(end) - smTime(1);
[h,m,~] = hms(sessionLength);
sessionMinutes = (h * 60) + m; 

%find amount of trials per minute 
speed = round(numTrials/sessionMinutes,1); 

%% create a structure with information about each trial 
%analysis trial initiation training just calculating left and right choices
if strcmp(sessionType,'TITraining')  
   for i = 1:length(allChoiceIndex) 
       trials(i).number = i; 
       trials(i).choice = allChoices{i};
       if strcmp(allChoices{i},{'L'})
           leftChoiceIndex(i) = allChoiceIndex(i);
       else
           rightChoiceIndex(i) = allChoiceIndex(i);
       end
   end
   allTrialIndex = allChoiceIndex; %copy variable name so training can be analyzed for response time below
   leftChoiceIndex(leftChoiceIndex == 0) = [];
   rightChoiceIndex(rightChoiceIndex == 0) = [];
   numLeftChoices = length(leftChoiceIndex);
   numRightChoices = length(rightChoiceIndex);

%analysis for training and testing sessions where there are correct and
%incorrect trials 
else
for i = 1:length(allTrialIndex) 
   trials(i).number = i; 
   
   %find whether the choice was correct and which side
   if ismember(allTrialIndex(i),correctTrialIndex) 
        trials(i).accuracy = 'Correct';
        
        if ismember(allTrialIndex(i),leftCorrect)
            trials(i).choice = 'L';
        else
            trials(i).choice = 'R';
        end
        
   else %find whether the choice was incorrect and what side 
        trials(i).accuracy = 'Incorrect'; 
        
        if ismember(allTrialIndex(i),leftIncorrect)
            trials(i).choice = 'L';
        else
            trials(i).choice = 'R';
        end        
   end     
end
end


%for training sessions 
if ~cueLengthVariable && ~delayLengthVariable
%update trial structure with response time  
for i = 1:length(allTrialIndex) 
    
   %will find the time between the trial initiation and the choice
   %once cue length is determined will account for the cue time
   trials(i).initiationTime = seconds(smTime(centerChoices(i))); 
   responseTime = smTime(allTrialIndex(i)); %time after trial inititiation that animal makes a response
   s = seconds(responseTime) - trials(i).initiationTime; %convert from duration to double   

   trials(i).responseTime = s - (cueLength + delayLength +ttlLength);
   
   if trials(i).responseTime < 0 %account for data acquisition glitch where response time ends up negative and discards these trials 
        trials(i).accuracy = 'Discard';        
   end
        
end

end



%% plot all trials 

%plot all trials and accuracy of with descriptive information about the session  
if plotToExternalFigure == false && noPlots == false
    figure;
end

if plotAllTrials == true && crossmodalTrials == false
%set x axis as the length of the session, and plot it as blank so the other
%data has values it can be plotted it against 
xAxis = zeros(size(smTime));
plot(smTime, xAxis, 'Linestyle', 'none') 
hold on 

%add lines to demarcate if the session mode was changed or there was a
%break between sessions in that day 
for i = 1: length(beginSession)
line([smTime(beginSession(i)) smTime(beginSession(i))], [-2 2]);
end

%plot all the left choices 
plot(smTime(leftIncorrect), 1.5 * ones(size(leftIncorrect)), 'o', 'color', [0.5020    0.5020    0.5020]);
plot(smTime(leftCorrect), ones(size(leftCorrect)), 'o', 'color', 'g');

%plot all the trial availability and center choices to initiate trials
plot(smTime(centerChoices), zeros(size(centerChoices)), '>', 'color', 'k');

%plot all of the right choices
plot(smTime(rightIncorrect), -1.5 * (ones(size(rightIncorrect))), 'o', 'color', [0.5020    0.5020    0.5020]);
plot(smTime(rightCorrect), -1 * ones(size(rightCorrect)), 'o', 'color', 'g');

%plot title, descriptive data, and set axes 
title({[animalID, ', Session Length: ' num2str(sessionMinutes) 'min' '        Trials: ' num2str(numTrials) '      %Correct:  ' num2str(percentCorrect)], ['Correct: ' num2str(length(correctTrialIndex)) '     Incorrect: ' num2str(length(incorrectTrialIndex)) '      Left: ' num2str(numLeftChoices) '     Right: ' num2str(numRightChoices)]}, 'FontSize', 9) 
set(gca,'ylim',[-2 2]);
set(gca, 'xlim', [beginTime endTime])
yticks([-1 0 1])
yticklabels({'right', 'center', 'left'})

if strcmp(sessionType,'TITraining')
%plot all the left and right choices 
plot(smTime(leftChoiceIndex), ones(size(leftChoiceIndex)), 'o', 'color', 'm');
plot(smTime(rightChoiceIndex), -1 * ones(size(rightChoiceIndex)), 'o', 'color', 'm');
end

% obsolete code for crossmodal version of the task. Not updated to account
% for new plotting styles and analysis
elseif plotAllTrials == true && crossmodalTrials == true
%will fill arrays with the choice made at each type of trial for each cue
%modality
dataAuditory = {}; 
dataVisual = {}; 

for i = 1: length(data) - 3 %will loop through the data until the last available trial
    stringTrialModality = char(data(i));
    stringChoice = char(data(i+2)); 

    if contains(stringTrialModality, ' Auditory') 
        dataAuditory(i+2) = {stringChoice(17)};
    end
    
    if contains(stringTrialModality, ' Visual') 
        dataVisual(i+2) = {stringChoice(17)};   
    end
    
end
        
%will find the positions of the trials of each cue modality
dataAuditoryIndex = find(~cellfun(@isempty,dataAuditory));
dataVisualIndex = find(~cellfun(@isempty,dataVisual));

%will take the indexes of each trial type and see which were correct or
%incorrect by comparing to the correct and incorrect trial index. 
leftCorrectA = dataAuditoryIndex(ismember(dataAuditoryIndex,leftCorrect));
leftIncorrectA = dataAuditoryIndex(ismember(dataAuditoryIndex,leftIncorrect));

rightCorrectA = dataAuditoryIndex(ismember(dataAuditoryIndex,rightCorrect));
rightIncorrectA = dataAuditoryIndex(ismember(dataAuditoryIndex,rightIncorrect));

leftCorrectV = dataVisualIndex(ismember(dataVisualIndex,leftCorrect));
leftIncorrectV = dataVisualIndex(ismember(dataVisualIndex,leftIncorrect));

rightCorrectV = dataVisualIndex(ismember(dataVisualIndex,rightCorrect));
rightIncorrectV = dataVisualIndex(ismember(dataVisualIndex,rightIncorrect));
        
        
%set x axis as the length of the session, and plot it as blank so the other
%data has values it can be plotted it against 
xAxis = zeros(size(smTime));
plot(smTime, xAxis, 'Linestyle', 'none') 
hold on 

%add lines to demarcate if the session mode was changed or there was a
%break between sessions in that day 
for i = 1: length(beginSession)
line([smTime(beginSession(i)) smTime(beginSession(i))], [-2 2]);
end

%plot all the left choices 
plot(smTime(leftIncorrectV), 1.5 * ones(size(leftIncorrectV)), 'o', 'color', 'r'); %visual 
plot(smTime(leftCorrectV), ones(size(leftCorrectV)), 'o', 'color', 'g');
plot(smTime(leftIncorrectA), 1.5 * ones(size(leftIncorrectA)), '^', 'color', 'r'); %auditory
plot(smTime(leftCorrectA), ones(size(leftCorrectA)), '^', 'color', 'g');

%plot all the trial availability and center choices to initiate trials
plot(smTime(centerChoices), zeros(size(centerChoices)), '>', 'color', 'k');

%plot all of the right choices
plot(smTime(rightIncorrectV), -1.5 * (ones(size(rightIncorrectV))), 'o', 'color', 'r'); %visual
plot(smTime(rightCorrectV), -1 * ones(size(rightCorrectV)), 'o', 'color', 'g');
plot(smTime(rightIncorrectA), -1.5 * (ones(size(rightIncorrectA))), '^', 'color', 'r'); %auditory
plot(smTime(rightCorrectA), -1 * ones(size(rightCorrectA)), '^', 'color', 'g');

%plot title and descriptive data, and set axes. 
title({[animalID, ', Session Length: ' num2str(sessionMinutes) 'min' '        Trials: ' num2str(numTrials) '      %Correct:  ' num2str(percentCorrect)], ['Correct: ' num2str(length(correctTrialIndex)) '     Incorrect: ' num2str(length(incorrectTrialIndex)) '      Left: ' num2str(numLeftChoices) '     Right: ' num2str(numRightChoices)]}, 'FontSize', 9) 
set(gca,'ylim',[-2 2]);
set(gca, 'xlim', [beginTime endTime])
yticks([-1 0 1])
yticklabels({'right', 'center', 'left'})     


%update summary structure with crossmodal session trial information 
summary.percentCorrectA = ((length(leftCorrectA)+length(rightCorrectA))/(length(leftCorrectA) + length(leftIncorrectA) + length(rightCorrectA) + length(rightIncorrectA))) * 100;
summary.percentCorrectV = ((length(leftCorrectV)+length(rightCorrectV))/(length(leftCorrectV) + length(leftIncorrectV) + length(rightCorrectV) + length(rightIncorrectV))) * 100;

end
%% if cue length is variable will extract data about cue lengths, accuracy, and choices

if cueLengthVariable == true

data50ms = {};
data100ms = {};
data500ms = {};
data1000ms = {};
data2000ms = {};
data5000ms = {}; 
dataOpto = {};

%will fill arrays with the choice made at each type of trial of the various
%cue lengths listed below. 
for i = 1: length(data) - 2 %will loop through the data until the last available trial %previously had as length(data) - 3 as 2 caused a bug but can't remember what it was, if error try that to fix it. 
    stringCueLength = char(data(i));
    if contains(stringCueLength, 'Cue Length') %will pull out section of string with cue length
    idx = strfind(stringCueLength,'Cue Length');
    endPos = length(stringCueLength);
    if endPos > 60
    stringCueLength = stringCueLength(idx:(idx+16));
    else
    stringCueLength = stringCueLength(idx:end);
    end
    end

    %will look for opto stim, if an opto stim session
    if optoStimRandom
        if i+3 > length(data)
        stringChoice = char(data(i+2)); 
        elseif i+4 <= length(data)
        stringChoice = char(data(i+2:i+4)); 
        else
        stringChoice = char(data(i+2:i+3));     
        end

        optoStringFound = ~cellfun('isempty',strfind(cellstr(stringChoice),'Optogenetic'));
        optoStringPosition = find(optoStringFound == true);
        if length(optoStringPosition)>=1
            
        optoStimThisTrial = true; 
            if optoStringPosition == 3
                stringChoice = stringChoice(1,:);
            elseif optoStringPosition == 1
            stringChoice = stringChoice(2,:);
            end

        else
        optoStimThisTrial = false;
            stringChoice = stringChoice(1,:);
        end        
    else
        stringChoice = char(data(i+2)); 
    end
    
%search through trial for each cue length
    if contains(stringCueLength, ' 50') && ~contains(stringCueLength, ' 500') && ~contains(stringCueLength, ' 5000') && ~contains(stringCueLength, ' Reward') && ~contains(stringCueLength, ' Completed')                  
        if optoStimThisTrial
            dataOpto(i+2) = {'true'};
            
            if optoStringPosition == 3
            data50ms(i+2) = {stringChoice(17)}; 
            elseif optoStringPosition == 1
            data50ms(i+3) = {stringChoice(17)}; 
            end

        else
            dataOpto(i+2) = {'false'};  
            data50ms(i+2) = {stringChoice(17)}; 
        end
    end


    if contains(stringCueLength, ' 100') && ~contains(stringCueLength, ' 1000') && ~contains(stringCueLength, ' Reward') && ~contains(stringCueLength, ' Completed') && ~contains(stringCueLength, ' Initiated')                     
        if optoStimThisTrial
            dataOpto(i+2) = {'true'};

            if optoStringPosition == 3
            data100ms(i+2) = {stringChoice(17)}; 
            elseif optoStringPosition == 1
            data100ms(i+3) = {stringChoice(17)}; 
            end

        else
            dataOpto(i+2) = {'false'};  
            data100ms(i+2) = {stringChoice(17)}; 
        end
    end
    
    if contains(stringCueLength, ' 500') && ~contains(stringCueLength, ' 5000') && ~contains(stringCueLength, ' Reward') 
        if optoStimThisTrial
            dataOpto(i+2) = {'true'};
            
            if optoStringPosition == 3
            data500ms(i+2) = {stringChoice(17)}; 
            elseif optoStringPosition == 1
            data500ms(i+3) = {stringChoice(17)}; 
            end

        else
            dataOpto(i+2) = {'false'};    
            data500ms(i+2) = {stringChoice(17)};
        end   
    end
    
    if contains(stringCueLength, ' 1000') && ~contains(stringCueLength, ' Reward') 
        if optoStimThisTrial
            dataOpto(i+2) = {'true'};

            if optoStringPosition == 3
            data1000ms(i+2) = {stringChoice(17)}; 
            elseif optoStringPosition == 1
            data1000ms(i+3) = {stringChoice(17)}; 
            end
            
        else
            dataOpto(i+2) = {'false'};    
            data1000ms(i+2) = {stringChoice(17)};
        end   
    end
    
    if contains(stringCueLength, ' 2000') && ~contains(stringCueLength, ' Reward') 
        if optoStimThisTrial
            dataOpto(i+2) = {'true'};

            if optoStringPosition == 3
            data2000ms(i+2) = {stringChoice(17)}; 
            elseif optoStringPosition == 1
            data2000ms(i+3) = {stringChoice(17)}; 
            end
            
        else
            dataOpto(i+2) = {'false'}; 
            data2000ms(i+2) = {stringChoice(17)};
        end   
    end
    
    if contains(stringCueLength, ' 5000') && ~contains(stringCueLength, ' Reward') 
        if optoStimThisTrial
            dataOpto(i+2) = {'true'};

            if optoStringPosition == 3
            data5000ms(i+2) = {stringChoice(17)}; 
            elseif optoStringPosition == 1
            data5000ms(i+3) = {stringChoice(17)}; 
            end
           
        else
            dataOpto(i+2) = {'false'}; 
            data5000ms(i+2) = {stringChoice(17)};
        end   
    
    end

end

%will find the positions of the trials of each cue length
data50msIndex = find(~cellfun(@isempty,data50ms));
data100msIndex = find(~cellfun(@isempty,data100ms));
data500msIndex = find(~cellfun(@isempty,data500ms));
data1000msIndex = find(~cellfun(@isempty,data1000ms));
data2000msIndex = find(~cellfun(@isempty,data2000ms));
data5000msIndex = find(~cellfun(@isempty,data5000ms));

%will find the positions of trials with opto stim 
if optoStimRandom 
    dataOptoIndex = find(~cellfun(@isempty,dataOpto));
    dataOpto = dataOpto(dataOptoIndex);
end


%will take the indexes of each trial type and see which were correct or
%incorrect by comparing to the correct and incorrect trial index. 
correct50ms = data50msIndex(ismember(data50msIndex,correctTrialIndex));
incorrect50ms = data50msIndex(~ismember(data50msIndex,correctTrialIndex));

correct100ms = data100msIndex(ismember(data100msIndex,correctTrialIndex));
incorrect100ms = data100msIndex(~ismember(data100msIndex,correctTrialIndex));

correct500ms = data500msIndex(ismember(data500msIndex,correctTrialIndex));
incorrect500ms = data500msIndex(~ismember(data500msIndex,correctTrialIndex));

correct1000ms = data1000msIndex(ismember(data1000msIndex,correctTrialIndex));
incorrect1000ms = data1000msIndex(~ismember(data1000msIndex,correctTrialIndex));

correct2000ms = data2000msIndex(ismember(data2000msIndex,correctTrialIndex));
incorrect2000ms = data2000msIndex(~ismember(data2000msIndex,correctTrialIndex));

correct5000ms = data5000msIndex(ismember(data5000msIndex,correctTrialIndex));
incorrect5000ms = data5000msIndex(~ismember(data5000msIndex,correctTrialIndex));

%will calculate the number of trials of each type 
numTrials50ms = length(data50msIndex); 
numTrials100ms = length(data100msIndex); 
numTrials500ms = length(data500msIndex);
numTrials1000ms = length(data1000msIndex);
numTrials2000ms = length(data2000msIndex);
numTrials5000ms = length(data5000msIndex);

%will calculate the percent correct to each trial type 
percentCorrect50ms = 100* (length(correct50ms)/(length(correct50ms) + length(incorrect50ms))); 
percentCorrect100ms = 100* (length(correct100ms)/(length(correct100ms) + length(incorrect100ms))); 
percentCorrect500ms = 100 * (length(correct500ms)/(length(correct500ms) + length(incorrect500ms))); 
percentCorrect1000ms = 100 * (length(correct1000ms)/(length(correct1000ms) + length(incorrect1000ms))); 
percentCorrect2000ms = 100 * (length(correct2000ms)/(length(correct2000ms) + length(incorrect2000ms))); 
percentCorrect5000ms = 100 * (length(correct5000ms)/(length(correct5000ms) + length(incorrect5000ms))); 

%will create an accuracy table of performance at each cue length
accuracy = [percentCorrect5000ms percentCorrect2000ms percentCorrect1000ms percentCorrect500ms percentCorrect100ms  percentCorrect50ms]; 
cueValsIndex = ~isnan(accuracy);
accuracy = accuracy(~isnan(accuracy));

%if optoStim is true, will get rid of any extra trials that don't have
%corresponding trial information. Placed here to catch a bug, but can't remember
%exactly what the bug was. May be that if analyzing blocks of optostim the code rounds up the
%size of a pre-defined block that may be greater than where the user stopped the
%behavioral session
if optoStim
    if length(allTrialIndex) > length(dataOpto)
        dataOpto{length(allTrialIndex)} = 'false';
    end
end

%update trial structure with cue information 
for i = 1:length(allTrialIndex) 
    
   %will find the time between the trial initiation and the choice
   %once cue length is determined will account for the cue time
   trials(i).initiationTime = seconds(smTime(centerChoices(i))); 
   responseTime = smTime(allTrialIndex(i)); %time after trial inititiation that animal makes a response
   s = seconds(responseTime) - trials(i).initiationTime; %convert from duration to double
   
   if ismember(allTrialIndex(i),data100msIndex)
        trials(i).cuelength = 100;
        trials(i).responseTime = s - .100 - ttlLength;
   elseif ismember(allTrialIndex(i),data50msIndex)
        trials(i).cuelength = 50;
        trials(i).responseTime = s - .050 - ttlLength;
   elseif ismember(allTrialIndex(i),data500msIndex)
        trials(i).cuelength = 500;
        trials(i).responseTime = s - .500 - ttlLength;
   elseif ismember(allTrialIndex(i),data1000msIndex)
        trials(i).cuelength = 1000;
        trials(i).responseTime = s - 1 - ttlLength;
   elseif ismember(allTrialIndex(i),data2000msIndex)
        trials(i).cuelength = 2000;
        trials(i).responseTime = s - 2 - ttlLength;
   elseif ismember(allTrialIndex(i),data5000msIndex)
        trials(i).cuelength = 5000;   
        trials(i).responseTime = s - 5 - ttlLength;
   end    

   if isfield(trials, 'responseTime') 
   if trials(i).responseTime < 0 
        trials(i).accuracy = 'Discard';        
   end
   end
   
   if optoStim
       
   if contains(char(dataOpto(i)),'true')
      trials(i).opto =  'true';
   else
       trials(i).opto = 'false';
   end
   end
     
end

%catch for bug where training session was analyzed as a testing session 
if ~isfield(trials,'responseTime')
       disp(['Warning: Check again that session is the correct type' ...
           ' and not a SSC or other training session without cue length information.']);
end

[numCues,vals] = getCueLengths(trials);
vals = string(vals(~isnan(vals)));

%pull accuracy values table and convert to string so values can be plotted on graph
for i = 1: numCues 
    currentDataPoint = num2str(accuracy(i)); 
    dataPointsA(i) = {currentDataPoint};
end

%plot line graph with accuracy at each cue length
if plotCueLengthData == true
    figure; 
    plot(accuracy, '-o');
    xAxis = 1:numCues;
    xticks(xAxis);
    xticklabels(vals);  
    xlabel('Cue Length (ms)');
    yticks([25 50 75 100]);
    yAxis = accuracy + 3;
    text(xAxis, yAxis, dataPointsA); 
    yline(50, '--k');
    title([ 'Accuracy,  ', animalID ]);
    ylabel('Percent correct');
    set(gca,'ylim',[20 120]);
end

%add accuracy values to summary structure
summary.accuracy = accuracy; 

end


%% will only execute if the delay length is variable (delayLengthVariable defined as true). 

if delayLengthVariable == true

data3000ms = {};
data4000ms = {};
data5000ms = {};
dataOpto = {};

%will fill arrays with the choice made at each type of trial of the various
%cue lengths listed below. 
for i = 1: length(data) - 3 %will loop through the data until the last available trial
    stringCueLength = char(data(i));
    if optoStimRandom
        stringChoice = char(data(i+2:i+3)); 
        if contains(stringChoice(1,:), 'Optogenetic')
        optoStimThisTrial = true; 
            %dataOpto(i+2) = {'true'};
        stringChoice = stringChoice(2,:);
        else
        optoStimThisTrial = false;
            %dataOpto(i+2) = {'false'};
            stringChoice = stringChoice(1,:);
        end        
    else
        if strcmp(sessionType,'VDST')
        stringChoice = char(data(i+2)); 
        elseif strcmp(sessionType,'DT-VDST')
        stringChoice = char(data(i+3)); 
        end
    end
    

    if contains(stringCueLength, ' 3000') && ~contains(stringCueLength, ' Reward') && ~contains(stringCueLength, ' Completed')                  
        if optoStimThisTrial
            dataOpto(i+2) = {'true'};
            data3000ms(i+3) = {stringChoice(17)}; 
        else
            dataOpto(i+2) = {'false'};  
            data3000ms(i+2) = {stringChoice(17)}; 
        end
    end
    
    if contains(stringCueLength, ' 4000') && ~contains(stringCueLength, ' Reward') 
        if optoStimThisTrial
            dataOpto(i+2) = {'true'};
            data4000ms(i+3) = {stringChoice(17)};
        else
            dataOpto(i+2) = {'false'};    
            data4000ms(i+2) = {stringChoice(17)};
        end   
    end
    
    if contains(stringCueLength, ' 5000') && ~contains(stringCueLength, ' Reward') 
        if optoStimThisTrial
            dataOpto(i+2) = {'true'};
            data5000ms(i+3) = {stringChoice(17)};
        else
            dataOpto(i+2) = {'false'};    
            data5000ms(i+2) = {stringChoice(17)};
        end   
    end   

end

%will find the positions of the trials of each cue length
data3000msIndex = find(~cellfun(@isempty,data3000ms));
data4000msIndex = find(~cellfun(@isempty,data4000ms));
data5000msIndex = find(~cellfun(@isempty,data5000ms));

if strcmp(sessionType, 'DT-VDST')
data3000msIndex = data3000msIndex + 1; 
data4000msIndex = data4000msIndex + 1; 
data5000msIndex = data5000msIndex + 1; 
centerChoices = centerChoices + 1; 
end

if optoStimRandom 
    dataOptoIndex = find(~cellfun(@isempty,dataOpto));
    dataOpto = dataOpto(dataOptoIndex);
end


%will take the indexes of each trial type and see which were correct or
%incorrect by comparing to the correct and incorrect trial index. 
correct3000ms = data3000msIndex(ismember(data3000msIndex,correctTrialIndex));
incorrect3000ms = data3000msIndex(~ismember(data3000msIndex,correctTrialIndex));

correct4000ms = data4000msIndex(ismember(data4000msIndex,correctTrialIndex));
incorrect4000ms = data4000msIndex(~ismember(data4000msIndex,correctTrialIndex));

correct5000ms = data5000msIndex(ismember(data5000msIndex,correctTrialIndex));
incorrect5000ms = data5000msIndex(~ismember(data5000msIndex,correctTrialIndex));

%will calculate the number of trials of each type 
numTrials3000ms = length(data3000msIndex);
numTrials4000ms = length(data4000msIndex);
numTrials5000ms = length(data5000msIndex);

%will calculate the percent correct to each trial type 
percentCorrect3000ms = 100 * (length(correct3000ms)/(length(correct3000ms) + length(incorrect3000ms))); 
percentCorrect4000ms = 100 * (length(correct4000ms)/(length(correct4000ms) + length(incorrect4000ms))); 
percentCorrect5000ms = 100 * (length(correct5000ms)/(length(correct5000ms) + length(incorrect5000ms))); 

%place accuracy values into an array
accuracy = [percentCorrect3000ms percentCorrect4000ms percentCorrect5000ms]; 

if optoStim
    if length(allTrialIndex) > length(dataOpto)
        dataOpto{length(allTrialIndex)} = 'false';
    end
end

%update trial structure with delay information 
for i = 1:length(allTrialIndex) 
    
   %will find the time between the trial initiation and the choice
   %once cue length is determined will account for the cue time
   trials(i).initiationTime = seconds(smTime(centerChoices(i))); 
   responseTime = smTime(allTrialIndex(i)); %time after trial inititiation that animal makes a response
   s = seconds(responseTime) - trials(i).initiationTime; %convert from duration to double
   
   if ismember(allTrialIndex(i),data3000msIndex)
        trials(i).delayLength = 3000;
        trials(i).responseTime = s - 3;
   elseif ismember(allTrialIndex(i),data4000msIndex)
        trials(i).delayLength = 4000;
        trials(i).responseTime = s - 4;
   elseif ismember(allTrialIndex(i),data5000msIndex)
        trials(i).delayLength = 5000;   
        trials(i).responseTime = s - 5;
   end    

   if trials(i).responseTime < 0 
        trials(i).accuracy = 'Discard';        
   end
      
   if optoStim
       
   if contains(char(dataOpto(i)),'true')
      trials(i).opto =  'true';
   else
       trials(i).opto = 'false';
   end
   end
     
end

%pull accuracy values to plot on graph
for i = 1: length(accuracy) 
    currentDataPoint = num2str(accuracy(i)); 
    dataPointsA(i) = {currentDataPoint};
end

if plotDelayLengthData == true
    figure; 
    %subplot(3,1,2);
    plot(accuracy, '-o');

    xAxis = 1:3;
    xticks(xAxis);
    xticklabels({'3s', '4s', '5s'});  

    yticks([25 50 75 100]);
    yAxis = accuracy + 3;
    text(xAxis, yAxis, dataPointsA); 
    yline(50, '--k');
    title([ 'Accuracy,  ', animalID ]);
    ylabel('Percent correct');
    set(gca,'ylim',[20 120]);
end

summary.accuracy = accuracy; 

end

%catch bug where sometimes last trial doesn't have responseTime info and delete
%it
if isempty(trials(end).responseTime)
    trials(end) =[];    
end

%% pull omissions at each trial type
 if calculateOmissions

    numOmissions = 0;
    for i = 1:length(trials) 
        
    if trials(i).responseTime > omissionThreshold
        numOmissions = numOmissions +1;
        trials(i).accuracy = 'Omission';    
    end
        
    end
    
    %note uses functions for pulling data by trial type and accuracy that
    %could be used to update the above sections. Doesn't change output, but
    %will update to clean up code one day. 
    if numOmissions > 0 
        if cueLengthVariable || delayLengthVariable
        if delayLengthVariable
            omissionSummary = sepDelayLengthandAccuracy(trials);
        end
        if cueLengthVariable
        omissionSummary = sepCueLengthandAccuracy(trials);
        end
        summary.percentOmissions = omissionSummary.Omissions; 
        end
        if strcmp(sessionType, 'SSC') || distractorCues
        summary.percentOmissions = numOmissions/numTrials;
        end
    else
        if cueLengthVariable || delayLengthVariable
        summary.percentOmissions = zeros(1,length(summary.accuracy(~isnan(summary.accuracy))));
        elseif strcmp(sessionType, 'SSC') || distractorCues
        summary.percentOmissions = 0;
        end
    end
    
 end

%% distractor task

if distractorCues == true
stringDistractorInfo = char(data(1));

if contains(stringDistractorInfo,'Vis')
    visDistractors = true;
else
    audDistractors = true; %code set up for future use of auditory distractors. Has not been tested yet. 
end

for i = 1: length(data) - 2 %will loop through the data until the last available trial %previously had as length(data) - 3 as 2 caused a bug but can't remember what it was, if error try that to fix it. 
   
    
    stringDistractorInfo = char(data(i));

    if contains(stringDistractorInfo,'Dist')
    %find distractor cue intensity 
    distCueIntensity(i) = str2num(stringDistractorInfo(end-3:end));
    %find whether cue is matched or not
    if contains(stringDistractorInfo,'Unmatched')
    matched{i} = 'false';
    else
    matched{i} = 'true';
    end
    else
    distCueIntensity(i) = NaN; 
    end

end

%remove empty elements
distCueIntensity = abs(distCueIntensity(~isnan(distCueIntensity)));
matched = matched(find(~cellfun(@isempty,matched)));

%add distractor cue intensity and whether it was matched/unmatched (congruent/incongruent) to the trial structure
for i = 1:length(trials)
    trials(i).distCueIntensity = distCueIntensity(i);
    trials(i).matched = matched{i};
end

%separate into matched and unmatched (congruent/incongruent)
%analyze separately for accuracy at each distractor cue intensity
matchedTrials = trials(findTrialType('matched','true',trials));
unmatchedTrials = trials(findTrialType('matched','false',trials));

%remove omissions
matchedTrials(findTrialType('accuracy','Omission',matchedTrials)) = [];
unmatchedTrials(findTrialType('accuracy','Omission',unmatchedTrials)) = [];

%get the values used and sort from low to high
[~,distIntensityValues] = listTrialTypes(trials, 'distCueIntensity');
distIntensityValues = sort(distIntensityValues);

%loop through each intensity to get correct and incorrect trials 
    for j = 1:length(distIntensityValues)
        
        %save trials for each intensity
        matchedTrials_distCueIntensity{j}.trials = matchedTrials(findTrialType('distCueIntensity',distIntensityValues(j),matchedTrials));
        unmatchedTrials_distCueIntensity{j}.trials = unmatchedTrials(findTrialType('distCueIntensity',distIntensityValues(j),unmatchedTrials));

        %pull out correct and incorrect 

        %matched trials
         correct = matchedTrials_distCueIntensity{j}.trials(findTrialAccuracy('Correct',matchedTrials_distCueIntensity{j}.trials));
         incorrect = matchedTrials_distCueIntensity{j}.trials(findTrialAccuracy('Incorrect', matchedTrials_distCueIntensity{j}.trials));

         %get percent correct
         matchedTrials_distCueIntensity{j}.accuracy = (length(correct)/(length(correct)+length(incorrect)))*100;
         matchedTrials_distCueIntensity{j}.reactionTime.mean = mean(getFieldFromTrialStructure(matchedTrials_distCueIntensity{j}.trials, 'responseTime'));
         if ~isempty(correct)
         matchedTrials_distCueIntensity{j}.reactionTime.correct = mean(getFieldFromTrialStructure(correct, 'responseTime'));
         else
         matchedTrials_distCueIntensity{j}.reactionTime.correct = nan;    
         end
         if ~isempty(incorrect)
         matchedTrials_distCueIntensity{j}.reactionTime.incorrect = mean(getFieldFromTrialStructure(incorrect, 'responseTime'));
         else
         matchedTrials_distCueIntensity{j}.reactionTime.incorrect = nan;  
         end

         %unmatched trials 
         correct = unmatchedTrials_distCueIntensity{j}.trials(findTrialAccuracy('Correct',unmatchedTrials_distCueIntensity{j}.trials));
         incorrect = unmatchedTrials_distCueIntensity{j}.trials(findTrialAccuracy('Incorrect', unmatchedTrials_distCueIntensity{j}.trials));

         %get percent correct
         unmatchedTrials_distCueIntensity{j}.accuracy = (length(correct)/(length(correct)+length(incorrect)))*100;
         unmatchedTrials_distCueIntensity{j}.reactionTime.mean = mean(getFieldFromTrialStructure(unmatchedTrials_distCueIntensity{j}.trials, 'responseTime'));
         if ~isempty(correct)
         unmatchedTrials_distCueIntensity{j}.reactionTime.correct = mean(getFieldFromTrialStructure(correct, 'responseTime'));
         else
         unmatchedTrials_distCueIntensity{j}.reactionTime.correct = nan;  
         end
         if ~isempty(incorrect)
         unmatchedTrials_distCueIntensity{j}.reactionTime.incorrect = mean(getFieldFromTrialStructure(incorrect, 'responseTime'));
         else
        unmatchedTrials_distCueIntensity{j}.reactionTime.incorrect = nan;  
         end
      
    end

    %pull values into table to save and plot 
    for j = 1:length(distIntensityValues)
        matchedAccuracy(j) = matchedTrials_distCueIntensity{j}.accuracy;
        unmatchedAccuracy(j) = unmatchedTrials_distCueIntensity{j}.accuracy;
        matchedAveRT(j) = matchedTrials_distCueIntensity{j}.reactionTime.mean;
        unmatchedAveRT(j) = unmatchedTrials_distCueIntensity{j}.reactionTime.mean;
        matchedCorrRT(j) = matchedTrials_distCueIntensity{j}.reactionTime.correct;
        unmatchedCorrRT(j) = unmatchedTrials_distCueIntensity{j}.reactionTime.correct;
        matchedIncRT(j) = matchedTrials_distCueIntensity{j}.reactionTime.incorrect;
        unmatchedIncRT(j) = unmatchedTrials_distCueIntensity{j}.reactionTime.incorrect;
    end

%plotting data 

%pull accuracy values table and convert to string so can be plotted on graph
for i = 1: length(distIntensityValues)
    dataPointsMatchedA{i} = num2str(matchedAccuracy(i));
    dataPointsUnmatchedA{i} = num2str(unmatchedAccuracy(i));
end

%plot line graph with accuracy at each cue length
if plotDistractorData == true
    figure; subplot(1,2,1); hold on
    plot(matchedAccuracy, '-o');
    plot(unmatchedAccuracy, '-o');
    xAxis = 1:length(distIntensityValues);
    xticks(xAxis);
    yAxis = matchedAccuracy + 3;
    text(xAxis, yAxis, dataPointsMatchedA); 
    yAxis = unmatchedAccuracy + 3;
    text(xAxis, yAxis, dataPointsUnmatchedA);
    yline(50, '--k');
    ylabel('Percent correct');
    title([ 'Accuracy,  ', animalID ]);
    set(gca,'ylim',[0 120]);
    yticks([25 50 75 100]);

    subplot(1,2,2); hold on
    plot(matchedAveRT, '-o');
    plot(unmatchedAveRT, '-o');
    plot(matchedCorrRT, '-o');
    plot(unmatchedCorrRT, '-o');
    plot(matchedIncRT, '-o');
    plot(unmatchedIncRT, '-o');
    xAxis = 1:length(distIntensityValues);
    xticks(xAxis);
    set(gca,'ylim',[0 1]);
    ylabel('Reaction time (s)');
    title([ 'Mean Reaction Time,  ', animalID ]);
    
    for i = 1:2
    subplot(1,2,i) 
    xlabel('Cue Intensity');
    xticklabels(distIntensityValues);
    end

    legend('matched', 'unmatched', 'matched correct', 'unmatched correct', 'matched incorrect', 'unmatched incorrect')
    legend('Location', 'southeast')

end
summary.distractorTable = [matchedAccuracy;unmatchedAccuracy;matchedAveRT;unmatchedAveRT; matchedCorrRT; unmatchedCorrRT;  matchedIncRT; unmatchedIncRT];

%add quantifications and trials organized by cue intensity to the trial structure
summary.matchedTrials_distCueIntensity = matchedTrials_distCueIntensity;
summary.unmatchedTrials_distCueIntensity = unmatchedTrials_distCueIntensity;

end 

%% will only execute if there is optogenetic stim (optoStim is
% defined as true above). 
 if optoStim
 if optoStimBlocks
     %create an index for the number of trials of 5 alternating opto off
     %opto on trials
    blockLength = 5; 
    i = 1;
    optoIndex = [];
    while i < length(trials)   
        if (i+5) < length(trials)    
            optoIndex(i:(i+blockLength)) = 0;    
            i = i+blockLength;
        else
            numToAdd = length(trials) - i;
            optoIndex(i:(i+numToAdd)) = 0;    
            i = i+numToAdd;
            break
        end
        if (i+5) < length(trials)    
            optoIndex(i:(i+blockLength)) = 1;    
            i = i+blockLength;
        else
            numToAdd = length(trials) - i;
            optoIndex(i:(i+numToAdd)) = 1;    
            i = i+numToAdd;
            break
        end
          
    end
    
    
    for i = 1:length(optoIndex)
        if optoIndex(i) == 0
            optoOff(i) = trials(i);
        end
        if optoIndex(i) == 1 
            optoOn(i) = trials(i);
        end     
    end
    
 end
 
 %find index of optoOn vs optoOff trials if optoStimRandom = true. 
 if optoStimRandom
     for i = 1:length(trials)
        if contains(trials(i).opto, 'true')
            optoOn(i) = trials(i);
        elseif contains(trials(i).opto, 'false')
            optoOff(i) = trials(i);
        end
     end
     
     
 end
  
 %delete empty elements in the array   
 optoOff = optoOff(find(arrayfun(@(optoOff) ~isempty(optoOff.number),optoOff)));
 optoOn = optoOn(find(arrayfun(@(optoOn) ~isempty(optoOn.number),optoOn)));
   
 %find percent correct at each cue length for light on vs light off trials
 if cueLengthVariable
 optoOffAccuracy = sepCueLengthandAccuracy(optoOff);
 optoOffAccuracy.Correct = optoOffAccuracy.Correct(cueValsIndex);
 optoOnAccuracy = sepCueLengthandAccuracy(optoOn);
 optoOnAccuracy.Correct = optoOnAccuracy.Correct(cueValsIndex);
 end
 
 if delayLengthVariable
 optoOffAccuracy = sepDelayLengthandAccuracy(optoOff);
 optoOnAccuracy = sepDelayLengthandAccuracy(optoOn);    
 end
 
 
 %store opto data in trial structure only for block opto stim, if random, this
 %was done already
 if optoStimBlocks
 for i = 1:length(allTrialIndex) 
   trials(i).opto = optoIndex(i);   
 end
 end
 
 %plotting opto data 
 if plotOptoData == true
  
  %create character arrays of the accuracy data to be plotted over the data
  %points in the figure
  for i = 1: length(accuracy) 
    currentDataPoint = num2str(optoOffAccuracy.Correct(i)); 
    dataPointsA(i) = {currentDataPoint};
  end
 
  for i = 1: length(accuracy) 
    currentDataPoint = num2str(optoOnAccuracy.Correct(i)); 
    dataPointsB(i) = {currentDataPoint};
  end
         
     
    figure; hold on 
    
    xAxis = 1:length(accuracy);
    
    plot(optoOffAccuracy.Correct, '-o');
    yAxis = optoOffAccuracy.Correct + 3;
    text(xAxis, yAxis, dataPointsA); 
    
    plot(optoOnAccuracy.Correct, '-o');
    yAxis = optoOnAccuracy.Correct + 3;
    text(xAxis, yAxis, dataPointsB); 
    
    xticks(xAxis);
    xticklabels(vals);  
    xlabel('Cue Length (ms)');
    yticks([25 50 75 100]);
    yline(50, '--k');
    title([ 'Optogenetic Stimulation  ', animalID ]);
    ylabel('Percent correct');
    set(gca,'ylim',[20 120]);
 
    
    legend('Light Off','Light On');
    legend('boxoff'); 
 end

%add opto accuracy to data structure
summary.optoOffAccuracy = optoOffAccuracy.Correct;
summary.optoOnAccuracy = optoOnAccuracy.Correct;

 end



%% finish summary structure with descriptive information about session 
summary.animalID = animalID;
summary.sessionMinutes = sessionMinutes;
summary.numTrials = numTrials;
summary.speed = speed; 
summary.leftChoices = numLeftChoices;
summary.rightChoices = numRightChoices; 

if ~strcmp(sessionType,'TITraining') 
summary.percentCorrect = percentCorrect; 
summary.blockAccuracy = getBlockScore(trials, blockSize);
summary.persScore = calcPerseveration(trials);
summary.bothSidesChosen = getBlockPers(trials, blockSize);

if sigDetectAnalysis
%treating LEFT cue as signal and right cue as noise  
%left cue, correct: Hit, left cue, incorrect: Miss, right cue, incorrect:
%false alarm, right cue, correct: correct rejection, will get sensitivity and
%side bias for the left (inverse is the right)
summary.SDT = calcSensitivityAndBias(trials);
end


end


%% update trial structure with relationship between previous trial and the current one
if ~strcmp(sessionType,'TITraining') && ~strcmp(sessionType,'SSC') 
previousChoiceCorrect = [];
correctBeforeCorrect = [];
inccorrectBeforeCorrect = [];
inccorrectBeforeIncorrect = [];
correctBeforeIncorrect = [];

for i = 2:length(trials) 

        %check for whether previous trial is correct or not
        if strcmp(trials(i -1).accuracy, 'Correct') 
            trials(i).previousChoice = 'Correct';
            previousChoiceCorrect(i) = i;
        else
            trials(i).previousChoice = 'Incorrect';
        end
   
        %Correct then correct
        if strcmp(trials(i).accuracy, 'Correct') && strcmp(trials(i -1).accuracy, 'Correct') 
            trials(i).responseType = 'Correct before Correct';
            correctBeforeCorrect(i) = i;
        end

        %Incorrect then correct
        if strcmp(trials(i).accuracy, 'Correct') && strcmp(trials(i -1).accuracy, 'Incorrect') 
            trials(i).responseType = 'Incorrect before Correct';
            inccorrectBeforeCorrect(i) = i;
        end

        %Incorrect then incorrect
        if strcmp(trials(i).accuracy, 'Incorrect') && strcmp(trials(i -1).accuracy, 'Incorrect') 
            trials(i).responseType = 'Incorrect before Incorrect';
            inccorrectBeforeIncorrect(i) = i;
        end

        %Correct then Incorrect
        if strcmp(trials(i).accuracy, 'Incorrect') && strcmp(trials(i -1).accuracy, 'Correct') 
            trials(i).responseType = 'Correct before Incorrect';
            correctBeforeIncorrect(i) = i;
        end
    
end

%remove 0 elements and store in new structure
responseTypes.previousChoiceCorrect = previousChoiceCorrect(previousChoiceCorrect~=0);
responseTypes.correctBeforeCorrect = correctBeforeCorrect(correctBeforeCorrect ~=0);
responseTypes.inccorrectBeforeCorrect = inccorrectBeforeCorrect(inccorrectBeforeCorrect ~=0);
responseTypes.inccorrectBeforeIncorrect = inccorrectBeforeIncorrect(inccorrectBeforeIncorrect ~=0);
responseTypes.correctBeforeIncorrect = correctBeforeIncorrect(correctBeforeIncorrect ~=0);


%% perform checks we use in our behavior protocol for discarding or looking more closely at a session 
if length(trials) < 56
    disp('Warning trial count is low, consider discarding session');
end

if percentCorrect < 55
    disp('Percentage at or close to chance, should discard session');
end

percBlocksBothChoice = length(summary.bothSidesChosen(summary.bothSidesChosen==1))/length(summary.bothSidesChosen)*100;
if summary.persScore > .3  && percBlocksBothChoice < 70
    disp('Warning perseveration is high, consider discarding session');
end

if summary.persScore > .5  && percBlocksBothChoice < 70
    disp('Warning perseveration is extremely high, should discard session');
end

%% finish summary structure with descriptive information about session for all sessions other than trial initiation training 
summary.responseTypes = responseTypes;


%% add plot overlay with rolling mean of accuracy and response time
if plotAccuracyandRTOverlay

%get fields accuracy and trials as arrays from the trial structure
allAcc = getFieldFromTrialStructure(trials, 'accuracy');
allRT = getFieldFromTrialStructure(trials, 'responseTime');

%if the trial is an omissions remove the accuracy and and response time from
%arrays
for i = 1:length(allAcc)
   if strcmp(allAcc(i), 'Omission')
       allAccDouble(i) = NaN;
       allRT(i) = NaN;
   elseif strcmp(allAcc(i), 'Correct')
        allAccDouble(i) = 1;
   elseif strcmp(allAcc(i), 'Incorrect')
         allAccDouble(i) = 0;
   end
end

%take the moving mean in each block usung the length blockSize, added one to account for the likelyhood
%of one omisison being in each block, but could adjust this. 
allAccDouble = movmean(allAccDouble,blockSize+1, "omitnan");
allRT = movmean(allRT,blockSize+1, "omitnan");

%scale both arrays to axes of current graph 
allAccDouble = rescale(allAccDouble, -2, 2, "InputMin", 0, "InputMax", 1); 
allRT = rescale(allRT, -2, 2, "InputMin", 0, "InputMax", 3);

%find the correct figure to plot on 
allFigs = findobj('Type', 'figure');
figure(allFigs(end).Number)
plot(smTime(centerChoices(1:length(allAccDouble))), allAccDouble);
plot(smTime(centerChoices(1:length(allRT))), allRT);

set(gcf,'Position', [3694 769 688 151])

end

end
end
end
