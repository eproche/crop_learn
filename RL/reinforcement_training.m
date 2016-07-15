global dog_svm_model walker_svm_model leash_svm_model net layer;
load(strcat('/stash/mm-group/evan/crop_learn/models/svm_','dog','.mat'),'svm_model');
dog_svm_model = svm_model;
load(strcat('/stash/mm-group/evan/crop_learn/models/svm_','walker','.mat'),'svm_model');
walker_svm_model = svm_model;
load(strcat('/stash/mm-group/evan/crop_learn/models/svm_','leash','.mat'),'svm_model');
leash_svm_model = svm_model;
here = pwd;
cd '/u/eroche/matlab/cnn/matconvnet-1.0-beta20/';
disp('Starting MatConvNet');
run matlab/vl_setupnn;
cnn_net = vl_simplenn_tidy(load('imagenet-vgg-f.mat'));
cnn_layer = 18;
cnn_net.layers = cnn_net.layers(1:cnn_layer);
cd (here);  

move1 = [1,2,3,4,5,6,7,8];
act1 = linspace(0.1,1,10);
iou1 = linspace(-0.5,0.5,11);
move2 = [1,2,3,4,5,6,7,8];
act2 = linspace(0.1,1,10);
iou2 = linspace(-0.5,0.5,11);
curmove = [1,2,3,4,5,6,7,8];
statespace = combvector(move1,act1,iou1,move2,act2,iou2,curmove);

key = cell(length(statespace),1);
value = zeros(length(statespace),1);
for i = 1:length(statespace)
	key{i} = strcat(num2str(statespace(i,1)),',',num2str(statespace(i,2)),',',num2str(statespace(i,3)),',',...
	num2str(statespace(i,4)),',',num2str(statespace(i,5)),',',num2str(statespace(i,6)),',',num2str(statespace(i,7)));
	value(i) = 0.1*rand+0.001;
end

Qtab = containers.Map(key,value)


cd '../../cnn/matconvnet-1.0-beta20/';
disp('Starting MatConvNet');
run matlab/vl_setupnn
net = vl_simplenn_tidy(load('imagenet-vgg-f.mat'));
layer = 18;
net.layers = net.layers(1:layer);
cd '../../crop/sequencer/'

for i = 1:length(episodes)
	base_image = imread(episodes{i}.impath);
	object = episodes{i}.object;
	ground_truth = episodes{i}.ground;
	starting_box = episodes{i}.start;

	start_IOU = round(bboxOverlapRatio(starting_box,ground_truth),-1);
	shift = rand;
	[movement,IOU,new_crop] = environment(base_image,object,ground_truth,starting_box,shift);

	hid  = 1;
	state{hid}.movement = movement;
	state{hid}.IOU = IOU - start_IOU;
	old = IOU;
	state{hid}.shift = shift;
	hid = hid +1 
	while movement ~= 7
		shift = rand;
		[movement,IOU,new_crop] = environment(base_image,object,ground_truth,new_crop,shift);
		state{hid}.movement = movement;
		state{hid}.IOU = IOU - old;
		old = IOU; 
		state{hid}.shift = shift;
		peek = zeros(10,6)
		for k = 1:length(actions)
			[movement,IOU,new_crop] = environment(base_image,object,ground_truth,new_crop,actions(k));
			peek(k,1) = movement;
			peek(k,2) = IOU - old;
			peek(k,3:6) = new_crop;
		end
		best = find(peek(:,2) == max(peek(:,2)));
		Q



