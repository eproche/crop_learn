%% Test a model's accuracy on the test set, displays confusion matrix
%% Currently set for 7 alignment classes, to test background as 8th class change commented values
%% Assumes same number of images in each test class

load('path to model you want to test'); %% assumes variable named svm_model

path_var = 'dog';
res_var = 'path to results file'

if ~exist('data3','var')
    down = image_files(strcat('/stash/mm-group/evan/data/fullset/test/',path_var,'/down/'));
    up = image_files(strcat('/stash/mm-group/evan/data/fullset/test/',path_var,'/up/'));
    left = image_files(strcat('/stash/mm-group/evan/data/fullset/test/',path_var,'/left/'));
    right = image_files(strcat('/stash/mm-group/evan/data/fullset/test/',path_var,'/right/'));
    shrink = image_files(strcat('/stash/mm-group/evan/data/fullset/test/',path_var,'/shrink/'));
    expand = image_files(strcat('/stash/mm-group/evan/data/fullset/test/',path_var,'/expand/'));
    orig = image_files(strcat('/stash/mm-group/evan/data/fullset/test/',path_var,'/orig/'));
    back = image_files(strcat('/stash/mm-group/evan/data/fullset/test/',path_var,'/background/'));
    %%
    examples = numel(down)*7; %8

    filenames = [orig(:),up(:),down(:),right(:),left(:),shrink(:),expand(:)]; %for faster testing load slices
	data = load_cnn_data(filenames); %data = load_hog_data(filenames);
	y = size(data);
	x = size(down(1));
	rows = x(1); % number of images for each alignment, assumed to be constant
	block = y(2)/7; %8
	data2 = mat2cell(data,[rows],[block,block,block,block,block,block,block]); 
    data3 = cell2mat(transpose(data2));
end
%%  
vote_mat = zeros(examples,21); %28 
count_mat = zeros(examples,21); %28
score_mat = zeros(examples,21); %28
counts = zeros(7,7); %(8,8)

%% alignment predictions for all classifiers
for i = 1:21 %28
    disp(i);
	[predictions,scores] = predict(svm_model{i},data3);
    predictions = str2num(char(predictions));
    vote_mat(:,i) = predictions; 
    score_mat(:,i) = scores(:,1); % posteriors
end

%% count the votes received for each alignment per image
for i = 1:7 %8
    row = vote_mat(i,:);
    [a,b] = hist(row,unique(row));
    for k = 1:numel(b)
        count_mat(i,b(k)) = a(k);
    end
end

%% 
%% each block represents a section of the data matrix corresponding to alignment
% for each block count the votes and display as row in confusion matrix
m = mode(vote_mat,2);
blocks = mat2cell(m,[rows,rows,rows,rows,rows,rows,rows]);
for i = 1:numel(blocks)
    [a,b] = hist(blocks{i},unique(blocks{i}));
    for k = 1:numel(b)
        counts(i,b(k)) = a(k);
    end
end
counts
save(res_var,'counts','count_mat','vote_mat','score_mat')
