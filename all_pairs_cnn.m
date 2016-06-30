global path_var model_var res_var

if 0 == 0
	down = image_files(strcat('/stash/mm-group/evan/crop_learn/data/fullset/training/',path_var,'/down/'));
	up = image_files(strcat('/stash/mm-group/evan/crop_learn/data/fullset/training/',path_var,'/up/'));
	left = image_files(strcat('/stash/mm-group/evan/crop_learn/data/fullset/training/',path_var,'/left/'));
	right = image_files(strcat('/stash/mm-group/evan/crop_learn/data/fullset/training/',path_var,'/right/'));
	shrink = image_files(strcat('/stash/mm-group/evan/crop_learn/data/fullset/training/',path_var,'/shrink/'));
	expand = image_files(strcat('/stash/mm-group/evan/crop_learn/data/fullset/training/',path_var,'/expand/'));
	orig = image_files(strcat('/stash/mm-group/evan/crop_learn/data/fullset/training/',path_var,'/orig/'));
%%	
    filenames = [down,up,left,right,shrink,expand,orig];
	hogs = load_cnn_data(filenames);
    y = size(hogs);
    x = size(down);
    rows = x(1);
    block = y(2)/7;
    hogs2 = mat2cell(hogs,[rows],[block,block,block,block,block,block,block]);
%%
	labels = [map(1:size(down, 1), @(x) '1') map(1:size(up, 1), @(x) '2')...
	map(1:size(left, 1), @(x) '3') map(1:size(right, 1), @(x) '4') ...
	map(1:size(shrink, 1), @(x) '5') map(1:size(expand, 1), @(x) '6') ...
	map(1:size(orig, 1), @(x) '7')];
%	labels = transpose(labels);
    
    labels1 = mat2cell(labels,1,[rows,rows,rows,rows,rows,rows,rows]);
%	clear down up left right shrink expand orig;
end 

%% Train an SVM model
classes = {'1','2','3','4','5','6','7'};
combos = nchoosek(classes,2);
comboshog = nchoosek(hogs2,2);
comboslabel = nchoosek(labels1,2)
for i = 1:21
    first = combos{i,1}
    second = combos{i,2}
    hog_data = [comboshog{i,1}; comboshog{i,2}];
    label_data = [comboslabel{i,1}, comboslabel{i,2}];
	svm_model{i} = fitcsvm(hog_data,label_data,'KernelFunction','linear','Standardize',true,'ClassNames',{first,second});

    clear first second predictions scores label_data hog_data;
end
save(model_var,'svm_model')