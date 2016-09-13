function net = cnn_init()
%code for Computer Vision, Georgia Tech by James Hays

net = load('imagenet-vgg-f.mat') ;

% remove the final two layers: fc8 and the softmax layer
net.layers(end-1:end) = [];

% constant scalar for the random initial network weights.
f=1/100; 
% Move the last two layers accordingly
net.layers{20} = net.layers{end};
net.layers{19} = net.layers{18};
% insert one dropout layer between fc6 and fc7
net.layers{18} = struct('type', 'dropout','rate',0.5);
% add one dropout layer between fc7 and fc8
net.layers{end+1} = struct('type', 'dropout','rate',0.5);

% add one fully connected layer so that output is depth is 8.
net.layers{end+1} = struct('type', 'conv', ...
                           'weights', {{f*randn(1,1,4096,100, 'single'), zeros(1, 100, 'single')}}, ...
                           'stride', 1, ...
                           'pad', 0, ...
                           'name', 'fc8') ;

net.layers{end+1} = struct('type', 'conv', ...
                           'weights', {{f*randn(1,1,100,8, 'single'), zeros(1, 8, 'single')}}, ...
                           'stride', 1, ...
                           'pad', 0, ...
                           'name', 'fc9') ;

% Loss layer
net.layers{end+1} = struct('type', 'softmaxloss') ;


vl_simplenn_display(net, 'inputSize', [224 224 3 50])


