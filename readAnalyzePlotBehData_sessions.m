%--------------------------------------------------------------------------
%readAnalyzePlotBehData_sessions
%By: Brielle Ferguson
%Date: 1/10/19, updated 1/28/2020
%Can be used to read in data from an excel sheet or from a Matlab file into
%a cell array. If matlab files, will crawl through a directory, if excel, 
%is set up where a sheet contains all the data from one day, and each
%column is an animal. Will pass the data into readAndPlotBehData,
%which will read the data and plot into onto individual subplots. Will also
%return a table with summary data from each animal. 
%modified on 5/10 to analyze distractor task, but not complete yet, need to
%adjust omissions and then the final quantification table. BF 
%Assumptions:
% - if readFromFolder set to true, must run function from the parent folder.
%Inputs:
% - sessionType: 'SSC', 'varCue'/'VarCL'/'4CL', 'varDL'/'VDST','DT','DT-VDST'
% - correctionTime: .2 (.5 before 11/17/2023), the length of your ttl pulse in
%   arduino
%Outputs:
% - summary: structure with accuracy at each cue length, omissions, and other
%   descriptives about session
% - trials: structure with each trial including the fields, trial number,
%   accuracy, choice, cue length, response time, and opto.
% - will also plot several overview graphs, e.g., accuracy, reaction time                                                                                                                                               
%--------------------------------------------------------------------------
function [summary] = readAnalyzePlotBehData_sessions(sessionType,correctionTime)
%% set up paramaters for processing data
close all

%loading data
readFromExcel = false; %true if data is contained in excel file with each column representing behData from one session
readFromFolder = true; %true if each folder in a parent folder controls data from a session
oneAnimal = true; %true if crawling through parent directory where each folder is session from same animal, false if parent folder has data from many animals

%session type information
optoStim = false; %true if optoStim during session

%analysis add-ons
calcRT = true; %will calculate time between the end of cue and the choice
calcBlockAccuracy = true;
sigDetectAnalysis = true; 
calcOmissions = true; %standard analysis will calculate trials with omissions as part of it, so will run even if false (need to update) 
trialInteractionAnalysis = true; %will look at the interaction between trials across all trials and by cue length, need to update for delayLength

%plotting
plotAllTrials = true; %true if want to see plot of each of trial over time in the session
plotPerformanceTrends = true; %will plot reaction time across each session
plotDistractorData = true; 
plotCorrelations = false;

%saving
parentFolder = cd; %folder where containing folders with each session, must run function from this folder
saving = true; %will save summary structure in the parentFolder
askUserSaveDatabase = false; %set to false if not working with database

%% get your data

%create variables for storing filenames and animal IDs from each behavioral
%session
baseFileName = 'x'; 
animalIDs = 'animal ID';
animalID = 'animal ID';

%read in data from excel spreadsheet, note has not been used with recent
%versions of analysis script
if readFromExcel
filename = 'yourFilename';
sheet = 'M3';
dataRange = 'E3:G500';
[a,data] = xlsread(filename,sheet,dataRange); 
numToAnalyze = size(data,2);
dateRange = 'E1:G1';
[a,animalIDs] = xlsread(filename,sheet,dateRange);
end

%read in data from a folder containing .mat files
if readFromFolder
    data = {}; 
    animalIDs = {};
    dirToSearch = cd;
    folderList = dir;
    
    if oneAnimal
    for i = 3:length(folderList)
    thisFolder = strcat(dirToSearch,'/', folderList(i).name); 
    if isfolder(folderList(i).name)
    if  contains(thisFolder, 'D1') | contains(thisFolder, 'D2') | contains(thisFolder, 'D3') |  contains(thisFolder, 'D4') ...
            ||  contains(thisFolder, 'D5') |  contains(thisFolder, 'D6') |  contains(thisFolder, 'D7') | contains(thisFolder, 'D8')| contains(thisFolder, 'D9')| contains(thisFolder, 'D10')| contains(thisFolder, 'D11')...
            | contains(thisFolder, 'D12')| contains(thisFolder, 'D13')| contains(thisFolder, 'D14')| contains(thisFolder, 'D15')| contains(thisFolder, 'D16')...
            | contains(thisFolder, 'D17')
    cd(thisFolder)
    load behData
        if length(behData) > 50
        data{i} = behData;
        animalIDs{i} =  baseFileName;
        end
    cd(dirToSearch)
    end
    end
      
    end

    else 
        for i = 3:length(folderList)
            thisFolder = strcat(dirToSearch,'/', folderList(i).name); 
            if isfolder(folderList(i).name)
            cd(thisFolder)
            load behData
            if length(behData) > 50
            data{i} = behData;
            animalIDs{i} = baseFileName;
            end
            cd(dirToSearch)
            end
  
        end    
    
    end
    
    data = data(find(~cellfun(@isempty,data)));
    animalIDs = animalIDs(find(~cellfun(@isempty,animalIDs)));
    if ~isempty(animalIDs)
    animalID = animalIDs{1}(1:2);
    end

end

%% update session type based on user input
if strcmp(sessionType, 'varCue')
    cueLengthVariable = true;
    delayLengthVariable = false;
    distractorCues = false;
    totalSessions = 3;
elseif strcmp(sessionType, 'varCue') || strcmp(sessionType, '4CL') || strcmp(sessionType, 'VarCL')
    cueLengthVariable = true;
    delayLengthVariable = false;
    distractorCues = false;
    totalSessions = 3;
    responseTypeAnalysis = true;
elseif strcmp(sessionType, 'VDST') || strcmp(sessionType, 'VarDL')
    cueLengthVariable = false;
    delayLengthVariable = true;
    distractorCues = false;
    totalSessions = 2;
    responseTypeAnalysis = true;  
elseif strcmp(sessionType, 'DT')
    cueLengthVariable = false;
    delayLengthVariable = false;
    distractorCues = true;
    totalSessions = 3;
    responseTypeAnalysis = false;
elseif strcmp(sessionType, 'DT-VDST') %note this analysis is not final or tested
    cueLengthVariable = false;
    delayLengthVariable = true; 
    distractorCues = true;
    totalSessions = 2;
    responseTypeAnalysis = false;
elseif strcmp(sessionType, 'SCL')
    cueLengthVariable = true;
    delayLengthVariable = false;
    distractorCues = false;
    totalSessions = 2;
    blockSize = 8;
    responseTypeAnalysis = false;
elseif strcmp(sessionType, 'SSC')
    cueLengthVariable = false;
    delayLengthVariable = false;
    distractorCues = false;    
    responseTypeAnalysis = false;
end

%% loop through data, arrays of operant data from the arduino, analyze using readAnalyzePlotBehData, make summary graphs, and store summary info from each session

numToAnalyze = size(data,2);
if numToAnalyze == 0
warning('Check that the current directory is the correct parent folder.')
return
end
%loop through each data array containing a training or testing session
updatedSummary = []; %create table structure to store summary data from each session

for i = 1:numToAnalyze
    
    if readFromExcel
    if isempty(find(cellfun('isempty', data(1:end,i))))
        singleSessionData = data(1:end, i);      
    elseif ~isempty(find(cellfun('isempty', data(1:end,i))))    
        emptyArray = find(cellfun('isempty', data(1:end,i)));
        endArray = emptyArray(1)-1;
        singleSessionData = data(1:endArray, i);
    end
    
    end
    
    if readFromFolder
    singleSessionData = data{i};
    end
    
    if ~readFromFolder && ~readFromExcel
        singleSessionData = data(1:end, i);  
        if isempty(find(cellfun('isempty', data(1:end,i))))
        singleSessionData = data(1:end, i);      
    elseif ~isempty(find(cellfun('isempty', data(1:end,i))))    
        emptyArray = find(cellfun('isempty', data(1:end,i)));
        endArray = emptyArray(1)-1;
        singleSessionData = data(1:endArray, i);
        end
    if length(singleSessionData) == 1 
        singleSessionData = singleSessionData{1};        
    end
    end 
    
    %plot it on a subplot
    if plotAllTrials
    figure(101)
    subplot(numToAnalyze, 1, i); 
    end
    
    if length(cleanUpOperantData(singleSessionData)) > 1
    [summary, trials] = readAnalyzePlotBehData_adjustTTL(singleSessionData, animalIDs{i},sessionType, optoStim, correctionTime);   
    dailyTrials{i} = trials;
    end

    %calculate accuracy within trial blocks as defined above
    if calcBlockAccuracy
         updatedblockAccuracy.values{i} = summary.blockAccuracy.values;
    end

    if i == 1 
        
        updatedSummary = summary; 

         if strcmp(sessionType,'SSC') 
         allTrials = trials;
         updatedPersScore = calcPerseveration(trials);
         updatedAccuracy = summary.percentCorrect; 
         updatedOmissions = summary.percentOmissions;
         meanRT = mean(getFieldFromTrialStructure(trials, 'responseTime'));
         [corrRT, incRT] = getFieldFromTrialStructure_byAccuracy(trials, 'responseTime');
         corrRT = mean(corrRT); incRT = mean(incRT);
         updatedRT = [meanRT,corrRT,incRT];
         end

    elseif i > 1
      updatedSummary = [updatedSummary summary];   

         if strcmp(sessionType,'SSC') 
         allTrials = [allTrials trials];
         updatedPersScore = [updatedPersScore calcPerseveration(trials)];
         updatedAccuracy = [updatedAccuracy; summary.percentCorrect]; 
         updatedOmissions = [updatedOmissions; summary.percentOmissions];
         meanRT = mean(getFieldFromTrialStructure(trials, 'responseTime'));
         [corrRT, incRT] = getFieldFromTrialStructure_byAccuracy(trials, 'responseTime');
         corrRT = mean(corrRT); incRT = mean(incRT);
         updatedRT = [updatedRT; meanRT,corrRT,incRT];
         end
    end
    

    %for testing sessions, will do additional calculations around reaction time,
    %omissions, and perseveration
    if cueLengthVariable || delayLengthVariable || distractorCues

        if i == 1 
           
            allTrials = trials;
            updatedPersScore = calcPerseveration(trials);

            if cueLengthVariable || delayLengthVariable 
            updatedAccuracy = summary.accuracy; 
            if calcRT
                if cueLengthVariable
                    updatedRT = sepCueLengthAccuracyResponseTime(trials);
                end
                if delayLengthVariable
                    updatedRT = sepDelayLengthAccuracyResponseTime(trials);  
                end
             
            end

            end 
            if distractorCues           
                for j = 1:length(summary.matchedTrials_distCueIntensity)
                    updatedMatchedAccuracy(j) = summary.matchedTrials_distCueIntensity{j}.accuracy;                 
                    updatedUnmatchedAccuracy(j) = summary.unmatchedTrials_distCueIntensity{j}.accuracy;

                    if calcRT
                    updatedRTMatched(j) = summary.matchedTrials_distCueIntensity{j}.reactionTime.mean;
                    updatedRTUnmatched(j) = summary.unmatchedTrials_distCueIntensity{j}.reactionTime.mean;
                    end
                end
            updatedDistractorTable{i} = summary.distractorTable;
            end
            
            if cueLengthVariable || delayLengthVariable
            updatedOmissions = (summary.percentOmissions(~isnan(summary.percentOmissions))); 
            else
            updatedOmissions = summary.percentOmissions;
            end
            
            if optoStim 
            updatedOptoOn = summary.optoOnAccuracy;
            updatedOptoOff = summary.optoOffAccuracy;
            [optoOff, optoOn] = sepByOptoStim(trials);
            updatedPersScoreOptoOff = calcPerseveration(optoOff);
            updatedPersScoreOptoOn = calcPerseveration(optoOn);
            if calcRT
                if cueLengthVariable
                updatedRTOptoOff = sepCueLengthAccuracyResponseTime(optoOff).aveRT; 
                updatedRTOptoOn = sepCueLengthAccuracyResponseTime(optoOn).aveRT; 
                end
                if delayLengthVariable   
                updatedRTOptoOff = sepDelayLengthAccuracyResponseTime(optoOff).aveRT; 
                updatedRTOptoOn = sepDelayLengthAccuracyResponseTime(optoOn).aveRT; 
                end
            end
            end

        elseif i > 1
                   
            allTrials = [allTrials trials];
            updatedPersScore = [updatedPersScore calcPerseveration(trials)];

            if cueLengthVariable || delayLengthVariable 
            updatedAccuracy = [updatedAccuracy; summary.accuracy]; 
            if calcRT
                if cueLengthVariable
                updatedRT = [updatedRT; sepCueLengthAccuracyResponseTime(trials)];
                end
                if delayLengthVariable
                updatedRT = [updatedRT; sepDelayLengthAccuracyResponseTime(trials)];    
                end
            end
            updatedOmissions = [updatedOmissions; (summary.percentOmissions(~isnan(summary.percentOmissions)))];
       
            end
            if distractorCues
                for j = 1:length(summary.matchedTrials_distCueIntensity)
                matchedAccuracy(j) = summary.matchedTrials_distCueIntensity{j}.accuracy;
                unmatchedAccuracy(j) = summary.unmatchedTrials_distCueIntensity{j}.accuracy;
                if calcRT
                RTMatched(j) = summary.matchedTrials_distCueIntensity{j}.reactionTime.mean;
                RTUnmatched(j) = summary.unmatchedTrials_distCueIntensity{j}.reactionTime.mean;
                end
                end

                updatedMatchedAccuracy = [updatedMatchedAccuracy; matchedAccuracy];
                updatedUnmatchedAccuracy = [updatedUnmatchedAccuracy; unmatchedAccuracy];
                if calcRT
                updatedRTMatched = [updatedRTMatched; RTMatched];
                updatedRTUnmatched = [updatedRTUnmatched; RTUnmatched];
                end

                updatedDistractorTable{i} = summary.distractorTable;

                updatedOmissions = [updatedOmissions; summary.percentOmissions];

            end
            if optoStim
            updatedOptoOn = [updatedOptoOn; summary.optoOnAccuracy];
            updatedOptoOff = [updatedOptoOff; summary.optoOffAccuracy];
            [optoOff, optoOn] = sepByOptoStim(trials);
            updatedPersScoreOptoOff = [updatedPersScoreOptoOff;  calcPerseveration(optoOff)];
            updatedPersScoreOptoOn = [updatedPersScoreOptoOn; calcPerseveration(optoOn)];
            if calcRT
                if cueLengthVariable
                updatedRTOptoOff = [updatedRTOptoOff; sepCueLengthAccuracyResponseTime(optoOff).aveRT]; 
                updatedRTOptoOn = [updatedRTOptoOn; sepCueLengthAccuracyResponseTime(optoOn).aveRT]; 
                end
                if delayLengthVariable
                updatedRTOptoOff = [updatedRTOptoOff; sepDelayLengthAccuracyResponseTime(optoOff).aveRT]; 
                updatedRTOptoOn = [updatedRTOptoOn; sepDelayLengthAccuracyResponseTime(optoOn).aveRT]; 
                end
            end
            end
        end
        
    end
    
        
end



%get rid of any error trials where cue length or delay length isn't stored 

%will store additional calculations in tables for easy cut and pasting into
%graphpad prism or excel
if cueLengthVariable || delayLengthVariable || distractorCues || strcmp(sessionType, 'SSC')
    updatedPersScore = transpose(updatedPersScore);
    if cueLengthVariable   
    [numVals,vals] = getCueLengths(trials);
    vals = string(vals(~isnan(vals)));
    end

    if delayLengthVariable
    [numVals,vals] = getDelayLengths(trials);
    vals = string(vals(~isnan(vals)));
    end

    %if an opto session, separate date by opto on and opto off trials
    if optoStim
        allOptoPers = [updatedPersScoreOptoOn updatedPersScoreOptoOff];
        
        if cueLengthVariable
        aveAccuracy = sepCueLengthandAccuracy(allTrials);
        [optoOff, optoOn] = sepByOptoStim(allTrials);
        aveOptoOffAccuracy = sepCueLengthandAccuracy(optoOff);
        aveOptoOnAccuracy = sepCueLengthandAccuracy(optoOn);
        
        
        allTrialsSummary = [aveAccuracy.Correct; aveOptoOffAccuracy.Correct; aveOptoOnAccuracy.Correct];
        end
        
        if delayLengthVariable

        aveAccuracy = sepDelayLengthandAccuracy(allTrials);
        [optoOff, optoOn] = sepByOptoStim(allTrials);
        aveOptoOffAccuracy = sepDelayLengthandAccuracy(optoOff);
        aveOptoOnAccuracy = sepDelayLengthandAccuracy(optoOn);
        
        
        allTrialsSummary = [aveAccuracy.Correct; aveOptoOffAccuracy.Correct; aveOptoOnAccuracy.Correct];
        end
        
        dailySummary = [updatedAccuracy; updatedOptoOff; updatedOptoOn];
        
        if calcRT
        if delayLengthVariable
        optoOffRT = sepDelayLengthAccuracyResponseTime(optoOff);
        optoOnRT = sepDelayLengthAccuracyResponseTime(optoOn);
        end
        if cueLengthVariable
        optoOffRT = sepCueLengthAccuracyResponseTime(optoOff);
        optoOnRT = sepCueLengthAccuracyResponseTime(optoOn);
        end
        optoOffRTSummary = [optoOffRT.aveRT; optoOffRT.aveRTCorrect ;optoOffRT.aveRTIncorrect ];
        optoOnRTSummary = [optoOnRT.aveRT; optoOnRT.aveRTCorrect ;optoOnRT.aveRTIncorrect ];
        
        optoRTSummary = [optoOffRTSummary; optoOnRTSummary];
        end
        
        if calcOmissions
        omissionsSummary = [aveAccuracy.Omissions; aveOptoOffAccuracy.Omissions; aveOptoOnAccuracy.Omissions];
        end
    
        
    end
    
    reactionTime = {};
    if calcRT
        %use to be for bugs caused by removing NaNs, but not having NaNs can
        %also cause issue with cell2num function below, so will leave this
        %old code here for now in case its useful in the future
%        for i = 1:length(updatedRT)
%         aveRT{i} = (updatedRT(i).aveRT(~isnan(updatedRT(i).aveRT)));
%         aveRTCorrect{i} = (updatedRT(i).aveRTCorrect(~isnan(updatedRT(i).aveRTCorrect)));
%         aveRTIncorrect{i} = (updatedRT(i).aveRTIncorrect(~isnan(updatedRT(i).aveRTIncorrect)));
%        end 
       if ~distractorCues && ~strcmp(sessionType, 'SSC')
       %pull values from structure and place into cell array 
       for i = 1:length(updatedRT)
        aveRT{i} = updatedRT(i).aveRT;
        aveRTCorrect{i} = updatedRT(i).aveRTCorrect;
        aveRTIncorrect{i} = updatedRT(i).aveRTIncorrect;
       end 
       
       aveRT = cell2num(aveRT);
       reactionTime.aveRT = reshape(aveRT(~isnan(aveRT)),[],numVals);
       aveRTCorrect = cell2num(aveRTCorrect);
       reactionTime.aveRTCorrect = reshape(aveRTCorrect(~isnan(aveRT)),[],numVals);
       %reactionTime.aveRTIncorrect = cell2num(aveRTIncorrect);
        end
    
    end

    
    if calcBlockAccuracy
   
    blockAccuracy.values = updatedblockAccuracy.values;    
        %get max number of blocks
        maxNumBlocks = 1; 
        for j = 1:length(blockAccuracy.values)
            if length(blockAccuracy.values{1,j}) > maxNumBlocks
                maxNumBlocks = length(blockAccuracy.values{1,j});
            end
        end

        %add NaNs to each array to make them the same length
        for k = 1:length(blockAccuracy.values)
            if length(blockAccuracy.values{1,k}) < maxNumBlocks
                numToAdd = (maxNumBlocks - length(blockAccuracy.values{1,k}))-1;
                blockAccuracy.values{1,k}((maxNumBlocks - numToAdd):maxNumBlocks) = NaN;              
   
            end
        end

        %put the cell arrays into a table
        blockAccuracyTable = cell2num(blockAccuracy.values);

        %plot block data 
        figure; plotAveandSE(blockAccuracyTable,(1:maxNumBlocks),'b')
        title('Block performance across sessions')
        yticks([25 50 75 100]);
        yline(50, '--k');
        ylabel('Percent correct');
        xlabel('Block');
        set(gca,'ylim',[20 120]);

    end
    
    
    if ~distractorCues && ~strcmp(sessionType,'SSC')
    figure(10);
    if optoStim 

    avgOptoOff = mean(updatedOptoOff);
    avgOptoOn = mean(updatedOptoOn);
    plotAveAndSE_cueLength(transpose(updatedOptoOff),'k')
    hold on
    plotAveAndSE_cueLength(transpose(updatedOptoOn),'b')
        legend('Light Off','Light On');
        legend('boxoff'); 
    else  
    %plot accuracy over data set
    subplot(1,2,1);
    avgAccuracy = mean(updatedAccuracy,1);
    plotAveAndSE_cueLength(transpose(updatedAccuracy),'k')
    title('Average performance across sessions')
    yticks([25 50 75 100]);
    yline(50, '--k');
    ylabel('Percent correct');
    set(gca,'ylim',[20 120]);
    end

    
    %create summary plots of average performance across trial types over
    %sessions
    
    if cueLengthVariable
    xAxis = 1:numVals;
    xticks(xAxis);
    xticklabels(vals);  
    for i = 1: numVals 
    currentDataPoint = num2str(avgAccuracy(i)); 
    dataPointsA(i) = {currentDataPoint};
    end
    yAxis = avgAccuracy + 10;
    text(xAxis, yAxis, dataPointsA); 
    xlabel('Cue Length (ms)');

    end

    if delayLengthVariable
    xAxis = 1:numVals;
    xticks(xAxis);
    xticklabels(vals);  
    for i = 1: numVals 
    currentDataPoint = num2str(avgAccuracy(i)); 
    dataPointsA(i) = {currentDataPoint};
    end
    yAxis = avgAccuracy + 10;
    text(xAxis, yAxis, dataPointsA); 
    xlabel('Delay Length (ms)');

    end

    end

%updating quantification tables and plottin gfor the distractor task 
if distractorCues

    accuracy = [updatedMatchedAccuracy; updatedUnmatchedAccuracy];

    %pull out other values    
    updatedDistractorTable = transpose(reshape(transpose(cell2num_horizontal(updatedDistractorTable)),4, []));
    disPosArray = [1:numToAnalyze:size(updatedDistractorTable,1)];

    %slot into subtables for each trial type
    updatedRTMatchedCorrect = updatedDistractorTable(disPosArray(5):disPosArray(5)+(numToAnalyze-1),:);
    updatedRTUnmatchedCorrect = updatedDistractorTable(disPosArray(6):disPosArray(6)+(numToAnalyze-1),:);
    updatedRTMatchedIncorrect = updatedDistractorTable(disPosArray(7):disPosArray(7)+(numToAnalyze-1),:);
    updatedRTUnmatchedIncorrect = updatedDistractorTable(disPosArray(8):disPosArray(8)+(numToAnalyze-1),:);
    
    if plotDistractorData == true

    %get the values used and sort from low to high
    [numVals,distIntensityValues] = listTrialTypes(trials, 'distCueIntensity');
    distIntensityValues = sort(distIntensityValues);

    figure; subplot(2,2,1); hold on
    plotAveAndSE_cueLength(transpose(updatedMatchedAccuracy),'b')
    plotAveAndSE_cueLength(transpose(updatedUnmatchedAccuracy),'m') 
    yline(50, '--k');
    ylabel('Percent correct');
    title([ 'Accuracy,  ', animalID ]);
    set(gca,'ylim',[0 120]);
    yticks([25 50 75 100]);

    subplot(2,2,2); hold on
    plotAveAndSE_cueLength(transpose(updatedRTMatched),'b')
    plotAveAndSE_cueLength(transpose(updatedRTUnmatched),'m') 
    set(gca,'ylim',[0 1.5]);
    ylabel('Reaction time (s)');
    title([ 'Mean Reaction Time,  ', animalID ]);
   
    for i = 1:2
    subplot(2,2,i) 
    xAxis = 1:length(distIntensityValues);
    xticks(xAxis);
    xlabel('Cue Intensity');
    xticklabels(distIntensityValues);
    end

    legend('matched', 'unmatched')

    %plot the reaction time by accuracy 
    subplot(2,2,3); hold on
%     plotAveAndSE_cueLength(transpose(updatedRTMatchedCorrect),'b')
%     plotAveAndSE_cueLength(transpose(updatedRTMatchedIncorrect),'c') 
%     title('Matched Trials');
% 
%     subplot(2,2,4); hold on
%     plotAveAndSE_cueLength(transpose(updatedRTUnmatchedCorrect),'m')
%     plotAveAndSE_cueLength(transpose(updatedRTUnmatchedIncorrect),'r') 
%     title('Unmatched Trials');

    for i = 3:4
    subplot(2,2,i) 
    xAxis = 1:length(distIntensityValues);
    xticks(xAxis);
    xlabel('Cue Intensity');
    xticklabels(distIntensityValues);
    set(gca,'ylim',[0 2]);
    ylabel('Reaction time (s)');
    end
    

    end
end

if responseTypeAnalysis

    %separate the trial types and then pull out response time in each trial
     trials_CorrectCorrect = allTrials(findResponseType('Correct before Correct', allTrials));
     trials_CorrectIncorrect = allTrials(findResponseType('Correct before Incorrect', allTrials));
     trials_IncorrectIncorrect = allTrials(findResponseType('Incorrect before Incorrect', allTrials));
     trials_IncorrectCorrect = allTrials(findResponseType('Incorrect before Correct', allTrials));

     if cueLengthVariable
     responseTypeSummary.allRT.RT_CorrectCorrect = sepCueLengthAccuracyResponseTime(trials_CorrectCorrect);
     responseTypeSummary.allRT.RT_CorrectIncorrect = sepCueLengthAccuracyResponseTime(trials_CorrectIncorrect);
     responseTypeSummary.allRT.RT_IncorrectIncorrect = sepCueLengthAccuracyResponseTime(trials_IncorrectIncorrect); %sometimes there are not example of this from each cue length, so will leave NaNs in so can create tables for graphing   
     responseTypeSummary.allRT.RT_IncorrectCorrect = sepCueLengthAccuracyResponseTime(trials_IncorrectCorrect);
     end

     if delayLengthVariable
     responseTypeSummary.allRT.RT_CorrectCorrect = sepDelayLengthAccuracyResponseTime(trials_CorrectCorrect);
     responseTypeSummary.allRT.RT_CorrectIncorrect = sepDelayLengthAccuracyResponseTime(trials_CorrectIncorrect);
     responseTypeSummary.allRT.RT_IncorrectIncorrect = sepDelayLengthAccuracyResponseTime(trials_IncorrectIncorrect); %sometimes there are not example of this from each cue length, so will leave NaNs in so can create tables for graphing   
     responseTypeSummary.allRT.RT_IncorrectCorrect = sepDelayLengthAccuracyResponseTime(trials_IncorrectCorrect);  
     end
     
     %first, find positions in array where RT should be, each session should have correct correct trials, so can use this to pull following response types (previously used isNan but not all cue length will have all trial types so ran into issue concatenating the arrays ) 
     rtPositions = ~isnan(responseTypeSummary.allRT.RT_CorrectCorrect.aveRT); 
     responseTypeSummary.RT_CorrectCorrect = responseTypeSummary.allRT.RT_CorrectCorrect.aveRT(rtPositions);
     responseTypeSummary.RT_CorrectIncorrect = responseTypeSummary.allRT.RT_CorrectIncorrect.aveRT(rtPositions);
     responseTypeSummary.RT_IncorrectIncorrect = responseTypeSummary.allRT.RT_IncorrectIncorrect.aveRT(rtPositions);
     responseTypeSummary.RT_IncorrectCorrect = responseTypeSummary.allRT.RT_IncorrectCorrect.aveRT(rtPositions);


    %pull out response times to table that can be used for plots
    responseTypeRTtable = {};
    responseTypeRTtable{1} = responseTypeSummary.RT_CorrectCorrect;
    responseTypeRTtable{2} = responseTypeSummary.RT_IncorrectCorrect;
    responseTypeRTtable{3} = responseTypeSummary.RT_CorrectIncorrect; 
    responseTypeRTtable{4} = responseTypeSummary.RT_IncorrectIncorrect;
    

    responseTypeSummary.responseTypeRTtable = transpose(cell2num(responseTypeRTtable));

    %plot line graph with reaction time for each trial type
    trialTypesString = {'Correct following Correct', 'Correct following Error', 'Error following Correct','Error following Error'};
    
    colors = [0.1608 0.5490 0.5490; 0.6235 0.7843 0.7843; 0.7216  0.5176 0.7216; 0.5020  0  0.4549];
    

    figure; hold on
    subplot(2,2,1);plot(responseTypeSummary.responseTypeRTtable, '-o'); 
    legend(trialTypesString)
    legend('Location','southeast')
    xAxis = 1:numVals;
    xticks(xAxis);
    xticklabels(vals);  
    title([ 'Reaction Time,  ', animalID ]);
    ylabel('Seconds');
    set(gca,'ylim',[-1 3]);
    yticks([0 1 2 3]);
    ax = gca; 
    ax.ColorOrder = colors;


    %get number of each response type (eg., CC, EC) for each trial type (cue length/delay length), note this analysis is not set up for the Distractor task  

    %pull out response times to table that can be plotted on graph

    if cueLengthVariable
    for i = 1:numVals
    responseTypeSummary.allRT.RT_CorrectCorrect.numTrials(i) = length(findTrialType('cuelength', str2double(vals(i)), trials_CorrectCorrect));
    responseTypeSummary.allRT.RT_CorrectIncorrect.numTrials(i) = length(findTrialType('cuelength', str2double(vals(i)), trials_CorrectIncorrect));
    responseTypeSummary.allRT.RT_IncorrectIncorrect.numTrials(i) = length(findTrialType('cuelength', str2double(vals(i)), trials_IncorrectIncorrect));
    responseTypeSummary.allRT.RT_IncorrectCorrect.numTrials(i) = length(findTrialType('cuelength', str2double(vals(i)), trials_IncorrectCorrect));
    end
    elseif delayLengthVariable
    for i = 1:numVals
    responseTypeSummary.allRT.RT_CorrectCorrect.numTrials(i) = length(findTrialType('delayLength', str2double(vals(i)), trials_CorrectCorrect));
    responseTypeSummary.allRT.RT_CorrectIncorrect.numTrials(i) = length(findTrialType('delayLength', str2double(vals(i)), trials_CorrectIncorrect));
    responseTypeSummary.allRT.RT_IncorrectIncorrect.numTrials(i) = length(findTrialType('delayLength', str2double(vals(i)), trials_IncorrectIncorrect));
    responseTypeSummary.allRT.RT_IncorrectCorrect.numTrials(i) = length(findTrialType('delayLength', str2double(vals(i)), trials_IncorrectCorrect));
    end
    end

    numResponseTypeTable = {};
    numResponseTypeTable{1} = responseTypeSummary.allRT.RT_CorrectCorrect.numTrials;
    numResponseTypeTable{2} = responseTypeSummary.allRT.RT_IncorrectCorrect.numTrials;
    numResponseTypeTable{3} = responseTypeSummary.allRT.RT_CorrectIncorrect.numTrials; 
    numResponseTypeTable{4} = responseTypeSummary.allRT.RT_IncorrectIncorrect.numTrials;
    

    %get numbers of each response type
    numResponseTypeTable = transpose(cell2num(numResponseTypeTable));
    totalResponseTypes = sum(numResponseTypeTable,1);
    responseTypeSummary.numResponseTypeTable_plusTotal = [totalResponseTypes; numResponseTypeTable];
    numAllTrials = sum(totalResponseTypes); %numAllTrials = length(allTrials); %changed calculation from inlcluding to excluding omissions
    responseTypeSummary.percentResponseTypeTable = numResponseTypeTable/numAllTrials;
 
    %plot percentage of each response type on average across trials 
    subplot(2,2,2);
    colormap([0.1608 0.5490 0.5490; %change colors to match defaults for other graphs
        0.6235 0.7843 0.7843; 
        0.7216  0.5176 0.7216; 
        0.5020  0  0.4549]);
    pie(totalResponseTypes)
    title([ 'Percent Each Response Type,  ', animalID ]);

    %plot percent of each response type by trial type in stacked bargraph
    subplot(2,2,3);
    xAxis = 1:length(vals);
    bar(responseTypeSummary.percentResponseTypeTable,'stacked');
    xticks(xAxis);
    xticklabels(vals);  
    title([ 'Trials Each Response Type,  ', animalID ]);
    ylabel('Percent of Trials');
    set(gca,'ylim',[0 .25]);
    ax = gca; 
    ax.ColorOrder = colors;

    if cueLengthVariable
    xlabel('Cue Length (ms)');
    elseif delayLengthVariable
    xlabel('Delay Length (ms)');
    end

    %plot the legend in the fourth subplot
    subplot(2,2,4);
    bar(0,0); 
    hold on 
    bar( 0,0);
    bar( 0,0);
    bar( 0,0);
    set(gca,'ylim',[0 .25]);
    axis off
    legend(trialTypesString, 'FontSize',14)
    legend('boxoff'); 
    ax = gca; 
    ax.ColorOrder = colors;
    
    if saving
    save responseTypeSummary  responseTypeSummary
    saveas(gcf, 'Response Type Metrics', 'pdf'); %save figure as a pdf
    end

    %calculate post-error accuracy and compare to general accuracy
    %find post-error and general accuracy across session
    postErrorAcc = totalResponseTypes(2)/(totalResponseTypes(2)+totalResponseTypes(4));
    genAcc = (totalResponseTypes(1)+totalResponseTypes(2))/numAllTrials;
    errorMod = postErrorAcc - genAcc;

    %find post-error and general accuracy by trial type 
    postErrorAcc_trialType = numResponseTypeTable(:,2)./(numResponseTypeTable(:,2)+numResponseTypeTable(:,4));
    genAcc_trialType = (numResponseTypeTable(:,1)+numResponseTypeTable(:,2))./sum(numResponseTypeTable,2);
    errorMod_trialType = postErrorAcc_trialType - genAcc_trialType;

    postErrorTable = [postErrorAcc,genAcc,errorMod;postErrorAcc_trialType,genAcc_trialType,errorMod_trialType];


end

SDTTable = [];
if sigDetectAnalysis
    SDTFields = fields(updatedSummary(1).SDT);
    %will pull the calculation for each day and put in a table
    for i = 1:length(dailyTrials)
        for j = 1:length(SDTFields)
        SDTTable(i,j) = abs(updatedSummary(i).SDT.(SDTFields{j}));
        end
    end

    %will find that calculation across trial types for the pooled trial set 
    if cueLengthVariable
    for i = 1:numVals
        trials_cueLength = allTrials(findTrialType('cuelength', str2double(vals(i)), allTrials));
        SDT_cueLength{i} = calcSensitivityAndBias(trials_cueLength);
        for j = 1:length(SDTFields)
        SDTTable_cueLength(i,j) = SDT_cueLength{i}.(SDTFields{j});
        end
    end
    end

    if delayLengthVariable
    for i = 1:numVals
        trials_delayLength = allTrials(findTrialType('delayLength', str2double(vals(i)), allTrials));
        SDT_delayLength{i} = calcSensitivityAndBias(trials_delayLength);
        for j = 1:length(SDTFields)
        SDTTable_delayLength(i,j) = SDT_delayLength{i}.(SDTFields{j});
        end
    end
    end

    if distractorCues
        matchedTrials = allTrials(findTrialType('matched','true',allTrials));
        unmatchedTrials = allTrials(findTrialType('matched','false',allTrials));

       for i = 1:length(distIntensityValues)
        SDT_distIntensityMatched{i} = calcSensitivityAndBias(matchedTrials(findTrialType('distCueIntensity', distIntensityValues(i), matchedTrials)));
        SDT_distIntensityUnmatched{i} = calcSensitivityAndBias(unmatchedTrials(findTrialType('distCueIntensity', distIntensityValues(i), unmatchedTrials)));
        for j = 1:length(SDTFields)
            SDTTable_distIntensityMatched(i,j) = SDT_distIntensityMatched{i}.(SDTFields{j});
            SDTTable_distIntensityUnmatched(i,j) = SDT_distIntensityUnmatched{i}.(SDTFields{j});
        end
       end

       SDTTable_combined = [SDTTable_distIntensityMatched;SDTTable_distIntensityUnmatched];
       SDTTable_combined(:,2) = abs(SDTTable_combined(:,2));

    end


    if cueLengthVariable
    figure(10);subplot(1,2,2);   
    bar(SDTTable_cueLength);
    hold on
    xlabel('Cue Length (ms)');
    xticks(xAxis);
    xticklabels(vals);  
    SDTTable_cueLength = abs(SDTTable_cueLength);
    SDTTable = [SDTTable;SDTTable_cueLength];
    end

    if delayLengthVariable
    figure(10);subplot(1,2,2);
    bar(SDTTable_delayLength);
    hold on
    xlabel('Delay Length (ms)');
    xticks(xAxis);
    xticklabels(vals); 
    SDTTable_delayLength = abs(SDTTable_delayLength);
    SDTTable = [SDTTable;SDTTable_delayLength];
    end

    if distractorCues
    figure;
    subplot(1,2,1);
    bar(SDTTable_distIntensityMatched);
    title('Matched Trials');
    hold on
    subplot(1,2,2);
    bar(SDTTable_distIntensityUnmatched);
    title('Unmatched Trials');
    hold on

    for i=1:2
    subplot(1,2,i);
    xlabel('Cue Intensity');
    xAxis = 1:length(distIntensityValues);
    xticks(xAxis);
    xticklabels(distIntensityValues); 
    yline(0, '--k');
    set(gca,'ylim',[-3 5]);
    yticks(-3:5)
    legend('Sensitivity','Bias (L+, R-)');      
    end
    
    end

    saveas(gcf, 'Accuracy by trial type, SDT', 'pdf'); %save figure as a pdf
end

%% examine correlations between accuracy between trials across sessions and between specific trial types 
correlations = struct;
if trialInteractionAnalysis

    for i = 1:length(dailyTrials)
     thisDay = dailyTrials{i};
     [correlations.trialCorrelation_allR(i), correlations.trialCorrelation_allP(i)] = findConsecutiveTrialCorrelation(thisDay);
     
     if cueLengthVariable
        for j = 1:numVals
        thisData.trials = thisDay(findTrialType('cuelength', str2double(vals(j)), thisDay));
        [thisData.trialCorrelation_allR,thisData.trialCorrelation_allP] = findConsecutiveTrialCorrelation(thisData.trials);
        correlations.trialCorrelation_cueLength_R(i,j) =  thisData.trialCorrelation_allR;
        correlations.trialCorrelation_cueLength_P(i,j) =  thisData.trialCorrelation_allP;
        sessionData{i}.trials_cueLength{j} = thisData;
        end
     end

     if delayLengthVariable
         for j = 1:numVals
        thisData.trials = thisDay(findTrialType('delayLength', str2double(vals(j)), thisDay));
        [thisData.trialCorrelation_allR,thisData.trialCorrelation_allP] = findConsecutiveTrialCorrelation(thisData.trials);
        correlations.trialCorrelation_delayLength_R(i,j) =  thisData.trialCorrelation_allR;
        correlations.trialCorrelation_delayLength_P(i,j) =  thisData.trialCorrelation_allP;
        sessionData{i}.trials_delayLength{j} = thisData;
        end
     end

     if distractorCues
        matchedTrials = thisDay(findTrialType('matched', 'true', thisDay));
        unmatchedTrials = thisDay(findTrialType('matched', 'false', thisDay));
        [correlations.trialCorrelation_all_m_R(i), correlations.trialCorrelation_all_m_P(i)] = findConsecutiveTrialCorrelation(matchedTrials);
        [correlations.trialCorrelation_all_um_R(i), correlations.trialCorrelation_all_um_P(i)] = findConsecutiveTrialCorrelation(unmatchedTrials);
        
        for j = 1:length(distIntensityValues)    
        %matched
        thisData.trials = matchedTrials(findTrialType('distCueIntensity', distIntensityValues(j), matchedTrials));
        [thisData.trialCorrelation_allR,thisData.trialCorrelation_allP] = findConsecutiveTrialCorrelation(thisData.trials);
        correlations.trialCorrelation_mDistIntensity_R(i,j) =  thisData.trialCorrelation_allR;
        correlations.trialCorrelation_mDistIntensity_P(i,j) =  thisData.trialCorrelation_allP;
        sessionData{i}.trials_mDistIntensity{j} = thisData;

        %unmatched
        thisData.trials = unmatchedTrials(findTrialType('distCueIntensity', distIntensityValues(j), unmatchedTrials));
        [thisData.trialCorrelation_allR,thisData.trialCorrelation_allP] = findConsecutiveTrialCorrelation(thisData.trials);
        correlations.trialCorrelation_umDistIntensity_R(i,j) =  thisData.trialCorrelation_allR;
        correlations.trialCorrelation_umDistIntensity_P(i,j) =  thisData.trialCorrelation_allP;
        sessionData{i}.trials_umDistIntensity{j} = thisData;
        end
     end
        
    end
    
    %apply a fisher transform to return a mean r value and a p value across
    %all trials and then within trial types
    [correlations.trialCorrelation_all_R_mean.R,correlations.trialCorrelation_all_R_mean.P] = fisherZTransform(correlations.trialCorrelation_allR);

    if cueLengthVariable
    for i = 1:length(vals)   
        [correlations.trialCorrelation_cueLength_mean.R(i),correlations.trialCorrelation_cueLength_mean.P(i)] = fisherZTransform(correlations.trialCorrelation_cueLength_R(:,i));
    end

    %reshape correlations into table 
    dailyCorrelations_R = [transpose(correlations.trialCorrelation_allR),correlations.trialCorrelation_cueLength_R];
    meanCorrelations_R = [correlations.trialCorrelation_all_R_mean.R, correlations.trialCorrelation_cueLength_mean.R];
    meanCorrelations_P = [correlations.trialCorrelation_all_R_mean.P, correlations.trialCorrelation_cueLength_mean.P];

    dailyCorrelations_P = [transpose(correlations.trialCorrelation_allP),correlations.trialCorrelation_cueLength_P];
    end

    if delayLengthVariable
    for i = 1:length(vals)   
        [correlations.trialCorrelation_delayLength_mean.R(i),correlations.trialCorrelation_delayLength_mean.P(i)] = fisherZTransform(correlations.trialCorrelation_delayLength_R(:,i));
    end

    %reshape correlations into table 
    dailyCorrelations_R = [transpose(correlations.trialCorrelation_allR),correlations.trialCorrelation_delayLength_R];
    meanCorrelations_R = [correlations.trialCorrelation_all_R_mean.R, correlations.trialCorrelation_delayLength_mean.R];
    meanCorrelations_P = [correlations.trialCorrelation_all_R_mean.P, correlations.trialCorrelation_delayLength_mean.P];

    dailyCorrelations_P = [transpose(correlations.trialCorrelation_allP),correlations.trialCorrelation_delayLength_P];

    end

    if distractorCues
    for i = 1:length(distIntensityValues)   
        [correlations.trialCorrelation_mDistIntensity_mean.R(i),correlations.trialCorrelation_mDistIntensity_mean.P(i)] = fisherZTransform(correlations.trialCorrelation_mDistIntensity_R(:,i));
        [correlations.trialCorrelation_umDistIntensity_mean.R(i),correlations.trialCorrelation_umDistIntensity_mean.P(i)] = fisherZTransform(correlations.trialCorrelation_umDistIntensity_R(:,i));
    end

    %reshape correlations into table 
    dailyCorrelations_m_R = [transpose(correlations.trialCorrelation_all_m_R),correlations.trialCorrelation_mDistIntensity_R];
    dailyCorrelations_m_P = [transpose(correlations.trialCorrelation_all_m_P),correlations.trialCorrelation_mDistIntensity_P];
    meanCorrelations_m_R = [correlations.trialCorrelation_all_R_mean.R, correlations.trialCorrelation_mDistIntensity_mean.R];
    meanCorrelations_m_P = [correlations.trialCorrelation_all_R_mean.P, correlations.trialCorrelation_mDistIntensity_mean.P];

    dailyCorrelations_um_R = [transpose(correlations.trialCorrelation_all_um_R),correlations.trialCorrelation_umDistIntensity_R];
    dailyCorrelations_um_P = [transpose(correlations.trialCorrelation_all_um_P),correlations.trialCorrelation_umDistIntensity_P];
    meanCorrelations_um_R = [correlations.trialCorrelation_all_R_mean.R, correlations.trialCorrelation_umDistIntensity_mean.R];
    meanCorrelations_um_P = [correlations.trialCorrelation_all_R_mean.P, correlations.trialCorrelation_umDistIntensity_mean.P];
    end


    %combine all correlation values 
    if ~distractorCues && ~strcmp(sessionType,'SSC')
    correlationsTable = [dailyCorrelations_R; meanCorrelations_R; meanCorrelations_P]; 
    correlations.sessionData = sessionData;
    elseif strcmp(sessionType,'SSC')
    correlationsTable = transpose([correlations.trialCorrelation_allR; correlations.trialCorrelation_allP]);
    else
    correlationsTable_m = [dailyCorrelations_m_R; meanCorrelations_m_R; meanCorrelations_m_P]; 
    correlationsTable_um = [dailyCorrelations_um_R; meanCorrelations_um_R; meanCorrelations_um_P]; 
    correlations.sessionData = sessionData;
    end
       
    %display these values in command window
    disp('Trial Correlation across trials:');
    disp(correlations.trialCorrelation_allR);
    figure;
    if cueLengthVariable
    disp('Trial Correlation by cue length:');
    disp(correlations.trialCorrelation_cueLength_R);  
    if plotCorrelations
    plot(transpose(correlations.trialCorrelation_cueLength_R), '-o')
    xlabel('Cue Length (ms)');
    title([ 'Accuracy correlation by cue length,  ', animalID ]);
    end
    end
    if delayLengthVariable
    disp('Trial Correlation by delay length:');
    disp(correlations.trialCorrelation_delayLength_R); 
    if plotCorrelations
    plot(transpose(correlations.trialCorrelation_delayLength_R), '-o')
    xlabel('Delay Length (ms)');
    title([ 'Accuracy correlation by delay length,  ', animalID ]);
    end
    end


    if distractorCues
    disp('Trial Correlation by dist intensity, matched and unmatched:');
    disp(correlations.trialCorrelation_mDistIntensity_R);
    disp(correlations.trialCorrelation_umDistIntensity_R);
    if plotCorrelations
    plot(transpose(correlations.trialCorrelation_mDistIntensity_R), '-o')
    plot(transpose(correlations.trialCorrelation_umDistIntensity_R), '-o')
    xlabel('Dist Cue Intensity');
    title([ 'Accuracy correlation by dist intensity,  ', animalID ]);
    end
    vals = distIntensityValues;
    
    end

    %draft code for plotting correlations, not finished 
    if plotCorrelations
    xticks(xAxis);
    xticklabels(vals); 
    ylabel('Correlation Strength');
    yline(0, '--k');
    yline(0.5, '--k');
    yline(-0.5, '--k');
    set(gca,'ylim',[-1 1]);
    end

    if saving
    save correlations correlations
    end

    %% 
if plotPerformanceTrends && ~strcmp(sessionType,'SSC')

      %pull out reaction time for all trials
     for i = 1:length(dailyTrials)
         thisDay = dailyTrials{i};
         for j = 1:length(thisDay)
            reactionTimeTrends{i}.reactionTime(j) = thisDay(j).responseTime;
         end
     end

     figure; hold on
     for i = 1:length(dailyTrials)
     plot(reactionTimeTrends{i}.reactionTime,'-o');
     end
     legend
     xlabel('Trials');
    title([ 'Reaction Time,  ', animalID ]);
    ylabel('Seconds');

    if saving
    save reactionTimeTrends reactionTimeTrends
    end

end


end
    
    %save data
    cd(parentFolder);
    summary = updatedSummary;
    if cueLengthVariable || delayLengthVariable || strcmp(sessionType, 'SSC')
        accuracy = updatedAccuracy;
    end
    omissions = updatedOmissions;
    persScore = updatedPersScore;
    blockAccuracy = transpose(blockAccuracyTable);
    allBehData = data;

    
    if saving
        %blockAccuracy = blockAccuracy.values;
        save summary summary accuracy reactionTime omissions persScore blockAccuracy correlations allTrials SDTTable;
        slash = findSlashDirection;
        behSummaryPath = strcat(parentFolder, slash, 'summary.mat');
        if optoStim
           save summary summary accuracy reactionTime omissions persScore optoOffRTSummary optoOnRTSummary 
        end
        save allBehData allBehData;

    end

    %make table of all quant values
    numDays = length(dailyTrials);
    allQuant = [];

    if cueLengthVariable || delayLengthVariable || distractorCues
    if distractorCues
        updatedMatchedAccuracy = [nan(1,numDays);transpose(updatedMatchedAccuracy)];
        updatedUnmatchedAccuracy = [nan(1,numDays);transpose(updatedUnmatchedAccuracy)];
    if size(updatedMatchedAccuracy,2) < 3
        numToAdd = 3 - size(updatedMatchedAccuracy,2);
        updatedMatchedAccuracy = [updatedMatchedAccuracy,transpose(nan(1,length(updatedMatchedAccuracy)))];
        updatedUnmatchedAccuracy = [updatedUnmatchedAccuracy ,transpose(nan(1,length(updatedUnmatchedAccuracy)))];
    else
        numToAdd = 0;
    end
    
    end
    
    if cueLengthVariable || delayLengthVariable
    accuracy = [nan(1,numDays);transpose(accuracy)];
    if size(accuracy,2) < totalSessions
        numToAdd = totalSessions - size(accuracy,2);
        accuracy = [accuracy,transpose(nan(1,length(accuracy)))];
    else
        numToAdd = 0;
    end
    end

    %reshape SDT quantifications and perseveration for full table
    newSDT_1 = [transpose(SDTTable(1: numDays,1)),nan(1,numToAdd);nan(numVals,totalSessions)];
    newSDT_2 = [transpose(SDTTable(1: numDays,2)),nan(1,numToAdd);nan(numVals,totalSessions)];
    newSDT_3 = [nan(1,2);SDTTable(length(dailyTrials)+1:end,:)];
    newPers = [transpose(persScore),nan(1,numToAdd);nan(numVals,totalSessions)];

    %reaction time and omissions
    if cueLengthVariable || delayLengthVariable
    reactionTimeTable = [nan(1,totalSessions);transpose(reactionTime.aveRT),transpose(nan(numToAdd,numVals))];
    omissions = [nan(1,totalSessions);transpose(omissions),transpose(nan(numToAdd,numVals))];
    end

    if distractorCues
    reactionTimeTable_m = [nan(1,totalSessions);transpose(updatedRTMatched),transpose(nan(numToAdd,numVals))];
    reactionTimeTable_um = [nan(1,totalSessions);transpose(updatedRTUnmatched),transpose(nan(numToAdd,numVals))];
    reactionTimeTable_m_c = [nan(1,totalSessions);transpose(updatedRTMatchedCorrect),transpose(nan(numToAdd,numVals))];
    reactionTimeTable_m_ic = [nan(1,totalSessions);transpose(updatedRTMatchedIncorrect),transpose(nan(numToAdd,numVals))];
    reactionTimeTable_um_c = [nan(1,totalSessions);transpose(updatedRTUnmatchedCorrect),transpose(nan(numToAdd,numVals))];
    reactionTimeTable_um_ic = [nan(1,totalSessions);transpose(updatedRTUnmatchedIncorrect),transpose(nan(numToAdd,numVals))];
    omissions = [transpose(omissions),nan(1,numToAdd);nan(numVals,totalSessions)];
    end
    
    %reshaping trial type analysis (e.g.,CC-CE)
    if cueLengthVariable || delayLengthVariable
    percentResponseType = [nan(1,4);responseTypeSummary.percentResponseTypeTable];
    reactTimeResponseType = [nan(1,4);responseTypeSummary.responseTypeRTtable];
    end

    %reshape correlation values 
    if trialInteractionAnalysis
    if cueLengthVariable || delayLengthVariable
    correlationsTable = transpose(correlationsTable);
    newCorrTable_1 = [(correlationsTable(:,1:numDays)),transpose(nan(numToAdd,numVals+1))];
    if cueLengthVariable
    newCorrTable_2 = [nan(1,totalSessions);transpose([correlations.trialCorrelation_cueLength_P; nan(numToAdd,numVals)])];
    elseif delayLengthVariable
    newCorrTable_2 = [nan(1,totalSessions);transpose([correlations.trialCorrelation_delayLength_P; nan(numToAdd,numVals)])];
    end
    newCorrTable_3 = correlationsTable(:,numDays+1:end);
    end

    if distractorCues
    %reshape senstitivity and bias values
    sensTable_m = [nan(1,(size(SDTTable_distIntensityMatched,2)));SDTTable_distIntensityMatched];
    sensTable_um = [nan(1,(size(SDTTable_distIntensityUnmatched,2)));SDTTable_distIntensityUnmatched];
   
    %correlations    
    correlationsTable_m = transpose(correlationsTable_m);
    newCorrTable_1 = [(correlationsTable_m(:,1:numDays)),transpose(nan(numToAdd,numVals+1))]; 
    newCorrTable_2 = [nan(1,totalSessions);transpose([correlations.trialCorrelation_mDistIntensity_P; nan(numToAdd,numVals)])];
    newCorrTable_3 = correlationsTable_m(:,numDays+1:end);
    newCorrTable_m = [newCorrTable_1,  newCorrTable_2,  newCorrTable_3];

    correlationsTable_um = transpose(correlationsTable_um);
    newCorrTable_1 = [(correlationsTable_um(:,1:numDays)),transpose(nan(numToAdd,numVals+1))]; 
    newCorrTable_2 = [nan(1,totalSessions);transpose([correlations.trialCorrelation_umDistIntensity_P; nan(numToAdd,numVals)])];
    newCorrTable_3 = correlationsTable_um(:,numDays+1:end);
    newCorrTable_um = [newCorrTable_1,  newCorrTable_2,  newCorrTable_3];
    end


    %combine into one table
    if cueLengthVariable || delayLengthVariable
    allQuant = [accuracy,newSDT_1,newSDT_2, newSDT_3, newPers, reactionTimeTable, omissions,...
        percentResponseType, reactTimeResponseType, postErrorTable, newCorrTable_1,  newCorrTable_2,  newCorrTable_3 ];
    end
    
    if distractorCues

        allQuant = [updatedMatchedAccuracy,updatedUnmatchedAccuracy, newSDT_1, newSDT_2, sensTable_m, ...
        sensTable_um, newPers, omissions, reactionTimeTable_m, reactionTimeTable_um, reactionTimeTable_m_c...
       reactionTimeTable_m_ic, reactionTimeTable_um_c, reactionTimeTable_um_ic,...  
       newCorrTable_m,  newCorrTable_um];  

    end

    else
    allQuant = [accuracy,newSDT_1,newSDT_2, newSDT_3, newPers, reactionTimeTable, omissions,...
        percentResponseType, reactTimeResponseType ];
    end
    

    allQuant = transpose(allQuant);

    end

    if strcmp(sessionType, 'SSC')
    reactionTime = updatedRT;
    nansToFill = nan(10-length(accuracy), 10);

    allQuant = transpose([nansToFill; accuracy, reactionTime, omissions, persScore, correlationsTable, SDTTable]);

    end

    save allQuant allQuant
   

  if saving
        if askUserSaveDatabase
        postAnalysisSaveGUI_behavior(parentFolder, behSummaryPath, sessionType)
        end
  end

end

summary = updatedSummary;

end
