function [ data_normlized, std_feature, mean_features ] = feature_norm_train( data )



no_features=size(data,2);

data_normlized=[];
std_feature=[];
mean_features=[];
for i=1 : no_features

    temp=data(:,i);
    %std_feature(i)=range(temp); % Needs the Statistics Toolbox
    std_feature(i)=max(temp)-min(temp);
    mean_features(i)=mean(temp);
    data_normlized(:,i)=(temp-mean_features(i))/std_feature(i);
    
end





end

