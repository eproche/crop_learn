global path_var model_var res_var;

pathlist = {'dog/front','dog/back','dog/right','dog/left',...
			'walker/front','walker/back','walker/right','walker/left'};

modellist = {'svm_dog_front.mat','svm_dog_back.mat','svm_dog_right.mat','svm_dog_left.mat',...
			'svm_walker_front.mat','svm_walker_back.mat','svm_walker_right.mat','svm_walker_left.mat'};

reslist = {'res_dog_front.mat','res_dog_back.mat','res_dog_right.mat','res_dog_left.mat',...
			'res_walker_front.mat','res_walker_back.mat','res_walker_right.mat','res_walker_left.mat'};

for i = 3:8
	path_var = pathlist{i};
	model_var = modellist{i};
	res_var = reslist{i};

	all_pairs_cnn
	clearvars -except pathlist modellist reslist path_var model_var res_var
	test_model
	clearvars -except pathlist modellist reslist path_var model_var res_var
end


