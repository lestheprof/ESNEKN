


% clear all ;clc;


%%%%%%%%%%%%% Reading Training Files %%%%%%%%%%%%%%%%%
alldata=load('/dataset/SAD_data_tr.mat');
data=load('dataset/test12.mat');
training_Data=data.outdatacells(:, 1) ; %data.SAD_data_tr(:  ,1);
training_label=data.outdatacells(:,2) ; %data.SAD_data_tr(: ,2);
training_label=cell2mat(training_label(:));
clear data;

%%%%%%%%%%%%%%% test %%%%%%%%%%%%%%
% data=load('/TestSet/SAD_data_ts.mat','SAD_data_ts');
data=load('TestSet/0004filestest.mat','outdatacells');
testing_Data=data.outdatacells(:,1) ; % SAD_data_ts(: ,1);
testing_label=data.outdatacells(:, 2) ; % SAD_data_ts(:,2);
testing_label=cell2mat(testing_label(:));
clear data ;

%%%%%%%%%%%%%%%%%% Parameters ESN (needs to optimised for the task at hand)  %%%%%%%%%%%%%%%%%%%%%%
re_size=[52];
leakage_rate=[0.01];
win_scl=[0.5];
w_scl=[10];

%%%%%%%%%%%%%%%%%% Parameters  Data %%%%%%%%%%%%%%%%%%%%%%
no_input_dimensions=size(training_Data{1}, 1) ;
no_classes=2;
clear data;
%%%%%%%%%%%%%%%%%% Parameters EKMs (needs to optimised for the task at hand) %%%%%%%%%%%%%%%%%%%%%%
c_sent=[10000];
g_sent=[5];


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Write result to %%%%%%%%%%%%%%%%%
outputfile='outputfile';

%%%%%%%%%%%%%%%%%% Printing format %%%%%%%%%%%%%%%%%%%%%%
newline=double(sprintf('\n'));

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
                            
                            
                            
                            
                            net = Esn( re_size(i) , leakage_rate(c) , no_input_dimensions , win_scl(d_win) ,  w_scl(c_w))
                            
                            
                            disp(['====================ESN===========================' newline]);
                            
                            disp(['Reservoir Size = ' num2str(re_size(i)) '   Leakage Rate = ' num2str(leakage_rate(c)) newline 'Input dimensions = '  num2str(no_input_dimensions) ...
                                ' Win Scaler =  '  num2str(win_scl(d_win)) ' Wreservoir Scaler = ' num2str(w_scl(c_w))  ]);
                            
                            
                            disp(['=================================================' newline]);
                            
                            
                            %%%%%%%%%%%%%% Passing the training Data to the Network and Collecting the reservoir's responce on reservoirrResponceTraining %%%%%%%%%%%%
                            
                            
                            
                            
                            disp([newline 'Feeding the training data to the network' newline]);
                            istrain=true;
                            [reservoirrResponceTraining]=net.runReservoir(training_Data,istrain);
                            
                            
                            %%%%%%%%%%%%%% Passing the Test Data to the Network and Collecting the reservoir's responce on reservoirrResponceTest %%%%%%%%%%%%
                            disp([newline 'Feeding the Test data to the network ' newline]);
                            
                            istrain=false;
                            [reservoirrResponceTest]=net.runReservoir(testing_Data,istrain);
                            
   
                            %%%%%%%%%%%%%%%%%%%%%% ESNEKMs  %%%%%%%%%%%%%%%
                       
     
                            
                           
                            
                            disp([newline '====================ESNEKMs===========================' newline]);
                            
                            dlmwrite('train_Data_extreme.csv', [training_label reservoirrResponceTraining]);
                            dlmwrite('test_Data_extreme.csv', [testing_label reservoirrResponceTest]);
                            
                            
                            [ accuracyTraining_ESNEKMs, accuracyTesting_ESNEKMs] = ...
                                elm_kernel('train_Data_extreme.csv', 'test_Data_extreme.csv', 1, c_sent(cos), 'RBF_kernel',g_sent(g));
                            
                            disp([' ESNEKMs on Training =     ' num2str(accuracyTraining_ESNEKMs)]);
                            disp([' ESNEKMs on Testing =     ' num2str(accuracyTesting_ESNEKMs)]);
                            disp([' Kernel type =     RBF_kernel ']);
                            disp([' Kernel Parameters:']);
                            disp([' C =     ' num2str(c_sent(cos))]);
                            disp([' g =     ' num2str(g_sent(g))]);
                            
                            
                             disp([newline '==================== Run : ' num2str(b) ' / '  num2str(numberOfRuns) '    Ends ===========================' newline]);
                            result(b,1:2)=[accuracyTraining_ESNEKMs,accuracyTesting_ESNEKMs];
                        end
                        

                  %%%%%%%%%%%%%%%%%%% EKMs %%%%%%%%%%%%%%%%%%%%%%%%%%%%


                         

                                                   
                
                
                
                
                %%%%%%%%%%%%%%%%%%% Saving the Result %%%%%%%%%%%%%%
                average_train_EKM=mean(result(:,1));
                std_train_EKM=std(result(:,1));
                average_test_EKM=mean(result(:,2));
                std_test_EKM=std(result(:,2));
                
                filename=sprintf('Result/%s_%d_.dat',outputfile,  numberOfRuns);
                fid = fopen(filename, 'a');
                
                disp([ newline 'Writing the reuslt to:' newline  filename  newline ] );
                
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

