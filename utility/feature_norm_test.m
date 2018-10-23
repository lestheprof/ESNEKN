function [ data_normlized] = feature_norm_test( data, std_feature,mean_features )


no_features=size(data,2);


for i=1 : no_features

    temp=data(:,i);
    data_normlized(:,i)=(temp-mean_features(i))/std_feature(i);
    
end


end
