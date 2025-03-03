classdef Esn
  % written by A Alshemubarak, for his PhD
  % comments added by LSS August 2018.
    
    properties
        
        reservoirSize % number of units in reservoir
        inputDimensions % number of inputs to the reservoir (dimensionality of input)
        memoryLeakage % 
        wres % square matrix of internal weights for the reservoir
        win % matrix reservoir size by (inputDimensions + 1) of input weights
        winScaler % used to scale the input weights (initially between -0.5 and + 0.5)
        wresScaler % used to scale the reservopir weights (initially between -0.5 and + 0.5)
        
        end
    
    methods
        % create the reservoir and the weights associated with it
        function obj=Esn(reservoirSize,memoryLeakage,inputDimensions,winScaler,wresScaler)
        
            obj.reservoirSize=reservoirSize;  % set the class properties to the paramater values
            obj.memoryLeakage=memoryLeakage;
            obj.inputDimensions=inputDimensions;
            obj.winScaler=winScaler;
            obj.wresScaler=wresScaler;
            % set up randomised internal weights
            obj.win = (rand(obj.reservoirSize,1+obj.inputDimensions)-0.5) .* obj.winScaler;
            success = 0 ;                                               
           while success == 0
              try,
                  opt.disp = 0;
                  obj.wres = rand(obj.reservoirSize,obj.reservoirSize)-0.5; 
                  rhoW = abs(eigs(obj.wres,1,'LM',opt)); % returns largest eigenvalue
                  success = 1;
           
              catch exception % occurs only if obj.wres is singular. Unlikely. 
                  success = 0 ; 
                  disp(exception.message);
                  fprintf('Erorr in finding the eigs \n');
              end
   
           end

          obj.wres =  obj.wres .*(obj.wresScaler/rhoW); % scale by wresScaler / largest absolute eigenvalue
        end % constructor
            
            
            
            
        
        function[ reservoirState ]  =runReservoir(obj,data,ontrain)
            
            noOfSample=length(data); % logically sample rate is 1 per data value. Seems to assume constant timin (as wopuld be for e.g. FFT values or cepstrum etc.
            state_n = zeros(obj.reservoirSize,1); % initialise column vector of length reservoirSize to 0
            reservoirState=zeros(noOfSample,(obj.reservoirSize));   % initialise a state vector with zeros, for all of the time of the simulation (!)
            start_time = clock(); % used to get system timings
               for j = 1:noOfSample % for each timestep
                   datapoint=data{j}; % the data arrives as a cell array
                    duraition=size(datapoint,2);
                     for i=1 :duraition
                      state_n = (1-obj.memoryLeakage)*state_n + obj.memoryLeakage*sigmoid( obj.win*[1;datapoint(:,i)]+ obj.wres*state_n);
                     end


                 reservoirState(j,:)=[state_n];
                 state_n= zeros(obj.reservoirSize,1);

                 
                  
                  

               end
           final_time = etime(clock(), start_time);
          %fprintf('it took %d seconds\n', final_time);
           
           
           if ontrain == true
               
               
               [reservoirState s_train_ESN m_train_ESN]=feature_norm_train(reservoirState);
               

              save('filtered-data/norm_ESN_Response','s_train_ESN','m_train_ESN');
               
               
          
            else
               
               norm_ESN_Response=load('filtered-data/norm_ESN_Response');
               s_train_ESN=norm_ESN_Response.s_train_ESN;
               m_train_ESN=norm_ESN_Response.m_train_ESN;
               [reservoirState]=feature_norm_test(reservoirState, s_train_ESN, m_train_ESN);
               
    
           end            
%            reservoirState(isnan(reservoirState)) = 0 ;
   %        reservoirState(isinf(reservoirState)) = 0 ;
        
        
        end
    end
    
    
    
    
    
    
end

