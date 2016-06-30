global path_var model_var res_var

load(model_var,'svm_model');
svm_model
down = image_files(strcat('/stash/mm-group/evan/crop_learn/data/non_proto/test/',path_var,'/down/'));
up = image_files(strcat('/stash/mm-group/evan/crop_learn/data/non_proto/test/',path_var,'/up/'));
left = image_files(strcat('/stash/mm-group/evan/crop_learn/data/non_proto/test/',path_var,'/left/'));
right = image_files(strcat('/stash/mm-group/evan/crop_learn/data/non_proto/test/',path_var,'/right/'));
shrink = image_files(strcat('/stash/mm-group/evan/crop_learn/data/non_proto/test/',path_var,'/shrink/'));
expand = image_files(strcat('/stash/mm-group/evan/crop_learn/data/non_proto/test/',path_var,'/expand/'));
orig = image_files(strcat('/stash/mm-group/evan/crop_learn/data/non_proto/test/',path_var,'/orig/'));

examples = numel(down)*7;

filenames = [down,up,left,right,shrink,expand,orig];
	hogs = load_cnn_data(filenames);
	y = size(hogs);
	x = size(down);
	rows = x(1);
	block = y(2)/7;
	hogs2 = mat2cell(hogs,[rows],[block,block,block,block,block,block,block]);
    hogs3 = cell2mat(transpose(hogs2));
%%  
labels = [map(1:size(down, 1), @(x) 'down') map(1:size(up, 1), @(x) 'up')... 
map(1:size(left, 1), @(x) 'left') map(1:size(right, 1), @(x) 'right') ...
map(1:size(shrink, 1), @(x) 'shrink') map(1:size(expand, 1), @(x) 'expand') ...
map(1:size(orig, 1), @(x) 'orig')];
labels = transpose(labels);
%%
vote_mat = zeros(examples,21);
count_mat = zeros(examples,7);
score_mat = zeros(examples,21);
counts = zeros(7,7);
for i = 1:21
	[predictions,scores] = predict(svm_model{i},hogs3);
    predictions = str2num(char(predictions));
    vote_mat(:,i) = predictions;
    score_mat(:,i) = scores(:,1);
end
for i = 1:length(vote_mat)
    row = vote_mat(i,:);
    [a,b] = hist(row,unique(row));
    for k = 1:numel(b)
        count_mat(i,b(k)) = a(k);
    end
end
    
m = mode(vote_mat,2);
blocks = mat2cell(m,[rows,rows,rows,rows,rows,rows,rows]);
for i = 1:numel(blocks)
    [a,b] = hist(blocks{i},unique(blocks{i}));
    for k = 1:numel(b)
        counts(i,b(k)) = a(k);
    end
end

save(res_var,'counts','count_mat','vote_mat','score_mat')
