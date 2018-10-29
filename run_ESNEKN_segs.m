function run_ESNEKN_segs(indatafile, trainingfraction, segdir, re_size, leakage_rate, win_scl, w_scl, ...
    varargin)
%   function-based running for ESNEKN. Adapted from Abdulrahman
%   Ashekmubarak's work. Replaces terminal_n.m script. 
%   2nd version: uses segmented data
%
%   indatafile: name of .mat file with the input data
%   Trainingfraction: fraction to use for training
%   insegmentfile: file with the segmentation information
%   re_size: reservoir size (vector of sizes)
%   leakage_rate: leakage rate for elements in reservoir (vector of rates)
%   win_scl: scaling for inp0ut weights (vector)
%   w_scl: scaling for internal weights in reservoir (vector)
%   no_classes: number of classes
%   

% values below can be changed using varargin
%%%%%%%%%%%%%%%%%% Parameters EKMs (needs to optimised for the task at hand) %%%%%%%%%%%%%%%%%%%%%%
% default values
c_sent=[10000];
g_sent=[7];
verbose = false ;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Write result to %%%%%%%%%%%%%%%%%
outputfileprefix = 'outputfile_' ;


i = 1 ;
while(i<=size(varargin,2))
    switch lower(varargin{i})
        case 'c_sent'
            c_sent = varargin{i+1};
            i=i+1 ;
        case 'g_sent'
            g_sent =  varargin{i+1};
            i=i+1 ;
        case 'outputfileprefix'
            outputfileprefix =  varargin{i+1};
            i=i+1 ;
        case 'verbose'
            verbose =  varargin{i+1};
            i=i+1 ;
         otherwise
            error('runESNEKN: Unknown argument %s given',varargin{i});
    end
    i=i+1 ;
end
outputfile=[outputfileprefix date] ;

% load the dataset
alldata = load(indatafile) ;
% trainingfraction = 0.75 ; % now a parameter
testfraction = 1-trainingfraction ;
%%%%%%%%%%%%% Reading Training Files %%%%%%%%%%%%%%%%%
% alldata=load('dataset/allfiles_dt_05_parcel_2.mat');
% data=load('dataset/test12.mat');
datalength = length(alldata.outdatacells(:, 1)) ;
traindatalength = floor(trainingfraction * datalength) ;
testdatalength = datalength - traindatalength ;
% use the segmenttion data to create the training data sets
% get the segments
traindataindex = 1 ;
training_Data = cell(1,traindatalength * 50) ;
training_label = cell(1,traindatalength * 50) ;
for (trainindex = 1:traindatalength)
    fname = alldata.filelist{trainindex} ;
    % get the stem of the file name
    filenameelements =  strsplit(fname, '.') ;
    currentsegs = load([segdir '/' filenameelements{1} '_segs.mat']) ;
    % for each segment
    for segno=1:size(currentsegs.segments,1)
        segmentsamples = floor(currentsegs.segments(segno,:)/alldata.deltaT) ;
        if (segmentsamples(1) == 0) % can happen...
            segmentsamples(1) = 1 ;
        end
        trainingsegment = alldata.outdatacells{trainindex}(:, segmentsamples(1): segmentsamples(2)) ;
        % add this segment and its label to the training data
        training_Data{traindataindex} = trainingsegment ;
        training_label(traindataindex) = alldata.outdatacells(trainindex,2) ;
        traindataindex = traindataindex + 1 ;
    end % for
    

end % for
% shorten cell arrays
training_Data = training_Data(1:traindataindex - 1) ;
training_label = training_label(1:traindataindex - 1) ;
% training_Data=alldata.outdatacells(1:traindatalength, 1) ; %data.SAD_data_tr(:  ,1);
% training_label=alldata.outdatacells(1:traindatalength,2) ; %data.SAD_data_tr(: ,2);
training_label=cell2mat(training_label(:));
% clear data;

%%%%%%%%%%%%%%% test %%%%%%%%%%%%%%
% data=load('/TestSet/SAD_data_ts.mat','SAD_data_ts');
% data=load('TestSet/0004filestest.mat','outdatacells');
testdataindex = 1 ;
testing_Data = cell(1,testdatalength * 50) ;
testing_label = cell(1,testdatalength * 50) ;
testing_soundfilename = cell(1,testdatalength ) ;
for (testindex = traindatalength + 1:datalength)
    fname = alldata.filelist{testindex} ;
    % get the stem of the file name
    filenameelements =  strsplit(fname, '.') ;
    currentsegs = load([segdir '/' filenameelements{1} '_segs.mat']) ;
    % for each segment
    for segno=1:size(currentsegs.segments,1)
        segmentsamples = floor(currentsegs.segments(segno,:)/alldata.deltaT) ;
        if (segmentsamples(1) == 0) % can happen...
            segmentsamples(1) = 1 ;
        end
        testingsegment = alldata.outdatacells{testindex}(:, segmentsamples(1): segmentsamples(2)) ;
        % add this segment and its label to the testing data
        testing_Data{testdataindex} = testingsegment ;
        testing_label(testdataindex) = alldata.outdatacells(testindex,2) ;
        testing_soundfilename{testdataindex} = filenameelements{1} ;
        testdataindex = testdataindex + 1 ;
    end % for
end % for
testing_Data = testing_Data(1:testdataindex - 1) ;
testing_label = testing_label(1:testdataindex - 1) ;
testing_label=cell2mat(testing_label(:));

clear alldata ;

%%%%%%%%%%%%%%%%%% Parameters ESN (needs to optimised for the task at hand)  %%%%%%%%%%%%%%%%%%%%%%
%   now parameters
% re_size=[400];
% leakage_rate=[0.02 ];
% win_scl=[1.0 10 100];
% w_scl=[25];

%%%%%%%%%%%%%%%%%% Parameters  Data %%%%%%%%%%%%%%%%%%%%%%
no_input_dimensions=size(training_Data{1}, 1) ;
% no_classes=5; % now a parameter

%%%%%%%%%%%%%%%%%% Printing format %%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Number of runs %%%%%%%%%%%%%%%%%%%%%%%%%
numberOfRuns=5;

result=zeros(numberOfRuns,2);

for i=1 : length(re_size)
    for c=1 : length(leakage_rate)
        for d_win=1:length(win_scl)
            for c_w=1:length(w_scl)
                for cos=1 : length (c_sent)
                    for g=1 : length (g_sent)
                        for b=1 : numberOfRuns
                        
                            
                            %%%%%%%%%%%%%% Constructing the Network %%%%%%%%%%%% 
                            net = Esn( re_size(i) , leakage_rate(c) , no_input_dimensions , win_scl(d_win) ,  w_scl(c_w)) ;
                            if verbose
                                disp(['====================ESN===========================' newline]);
                                
                                disp(['Reservoir Size = ' num2str(re_size(i)) '   Leakage Rate = ' num2str(leakage_rate(c)) newline 'Input dimensions = '  num2str(no_input_dimensions) ...
                                    ' Win Scaler =  '  num2str(win_scl(d_win)) ' Wreservoir Scaler = ' num2str(w_scl(c_w))  ]);
                                disp(['=================================================' newline]);
                                
                                %%%%%%%%%%%%%% Passing the training Data to the Network and Collecting the reservoir's responce on reservoirrResponceTraining %%%%%%%%%%%%
                                disp([newline 'Feeding the training data to the network' newline]);
                            end
                            istrain=true;
                            [reservoirrResponceTraining]=net.runReservoir(training_Data,istrain);
                            if verbose
                                %%%%%%%%%%%%%% Passing the Test Data to the Network and Collecting the reservoir's responce on reservoirrResponceTest %%%%%%%%%%%%
                                disp([newline 'Feeding the Test data to the network ' newline]);
                            end
                            istrain=false;
                            [reservoirrResponceTest]=net.runReservoir(testing_Data,istrain);
                            
                            %%%%%%%%%%%%%%%%%%%%%% ESNEKMs  %%%%%%%%%%%%%%%
                            if verbose
                                disp([newline '====================ESNEKMs===========================' newline]);
                            end
                            dlmwrite('train_Data_extreme.csv', [training_label reservoirrResponceTraining]);
                            dlmwrite('test_Data_extreme.csv', [testing_label reservoirrResponceTest]);
                            
                            [ accuracyTraining_ESNEKMs, accuracyTesting_ESNEKMs, conf_matrix] = ...
                                elm_kernel('train_Data_extreme.csv', 'test_Data_extreme.csv', 1, c_sent(cos), 'RBF_kernel',g_sent(g));
                            if verbose
                                disp([' ESNEKMs on Training =     ' num2str(accuracyTraining_ESNEKMs)]);
                                disp([' ESNEKMs on Testing =     ' num2str(accuracyTesting_ESNEKMs)]);
                                disp(' Kernel type =     RBF_kernel ');
                                disp(' Kernel Parameters:');
                                disp([' C =     ' num2str(c_sent(cos))]);
                                disp([' g =     ' num2str(g_sent(g))]);
                            end
                            % temporary
                            % conf_matrix
                             disp([newline '==================== Run : ' num2str(b) ' / '  num2str(numberOfRuns) '    Ends ===========================' newline]);
                            result(b,1:2)=[accuracyTraining_ESNEKMs,accuracyTesting_ESNEKMs];
                        end
                        

                  %%%%%%%%%%%%%%%%%%% EKMs %%%%%%%%%%%%%%%%%%%%%%%%%%%%
                %%%%%%%%%%%%%%%%%%% Saving the Result %%%%%%%%%%%%%%
                average_train_EKM=mean(result(:,1));
                std_train_EKM=std(result(:,1));
                average_test_EKM=mean(result(:,2));
                std_test_EKM=std(result(:,2));
                
                filename=sprintf('Result/%s_%d_.txt',outputfile,  numberOfRuns);
                fid = fopen(filename, 'a');
                
                disp([ newline 'Appending the result to:' newline  filename  newline ] );
                
                fprintf (fid, '%4.4f %4.4f %4.4f %4.4f %4.4f %4.4f %4.4f %4.4f %4.4f %4.4f \n',...
                    average_train_EKM,std_train_EKM,average_test_EKM,std_test_EKM,...
                   re_size(i),leakage_rate(c),win_scl(d_win),w_scl(c_w),c_sent(cos),g_sent(g));

                fclose(fid);
                
                result=zeros(numberOfRuns,2);

                    end
                end
            end
        end
    end
end

