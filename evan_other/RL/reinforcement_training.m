%% Q-learning framework for box adjust 
%% trains on episodes, where each episode contains the following information

    % episodes.impath = base image
    % episodes.object = which object to look for
    % episodes.ground = ground truth box
    % episodes.start = starting crop for the trajectory

% the settings for starting points can be altered in generate_episodes.m

global dog_svm_model walker_svm_model leash_svm_model net layer Qtab;
%% load the models 
if isempty(dog_svm_model)
    load('/stash/mm-group/evan/situate_learned_stuff/learned_stuff_noleash.mat');
    dog_svm_model = learned_stuff.box_adjust_models.box_adjustment_models_1v1(2,:);
    walker_svm_model = learned_stuff.box_adjust_models.box_adjustment_models_1v1(1,:);
	% leash_svm_model = learned_stuff.box_adjust_models.box_adjustment_models_1v1(3,:);
    clearvars learned_stuff % might fill up memory
end

%% load the CNN
if isempty(net)
here = pwd;
cd '/stash/mm-group/evan/cnn/matconvnet-1.0-beta20/';
disp('Starting MatConvNet');
run matlab/vl_setupnn;
net = vl_simplenn_tidy(load('imagenet-vgg-f.mat'));
layer = 18;
net.layers = net.layers(1:layer);
cd (here);  
end

%% discretized state space
move1 = [2,3,4,5,6,7]; % six alignment classes, "no change" not included
act1 = linspace(0.1,.5,5); % shift factor from 0.1 to 0.5
iou1 = [0,1];
move2 = [2,3,4,5,6,7];
act2 = linspace(0.1,.5,5);
iou2 = [0,1];
curmove = [2,3,4,5,6,7];
actions = linspace(0.1,.5,5);

% only need to generate the Qtable once
load ;
if isempty(Qtab)
	try
		load('/stash/mm-group/evan/qtab.mat')   
	catch
		disp('Generating Qtab table'); 
		% all unique combinations of states
		statespace = combvector(move1,act1,iou1,move2,act2,iou2,curmove,actions); 
		disp(length(statespace))
		key = cell(length(statespace),1);
		value = zeros(length(statespace),1);
		for i = 1:length(statespace)
			disp(i)
			% keys stored as a string, each state value separated by commas
			key{i} = strcat(num2str(statespace(i,1)),',',num2str(statespace(i,2)),',',num2str(statespace(i,3)),',',...
			num2str(statespace(i,4)),',',num2str(statespace(i,5)),',',num2str(statespace(i,6)),',',num2str(statespace(i,7)),...
			',',num2str(statespace(i,8)));
			% initialize with small random value
			value(i) = 0.1*rand+0.001;
		end
		Qtab = containers.Map(key,value);    
		save('')
end

discount = 0.9;
learning_rate = 1;
%%

%% load the pre-generated episodes
if ~exist('episodes','var')
	load('/stash/mm-group/evan/matlab/episodes.mat','episodes');
end

%% This would be the probability of using apprentice at each iteration of one episode. 
% 1 defaults to apprentice
apprentice_switch = [1,1,1,1,1,1,1,1,1,1];

% index for apprentice switch
apid = 1;

for i = 1:length(episodes)
    
	% updated image location
	episodes{i}.impath = strrep(episodes{i}.impath,'crop_learn/','');
	base_image = imread(episodes{i}.impath);
	object = episodes{i}.object;
	ground_truth = episodes{i}.ground;
	starting_box = episodes{i}.start;
    
    B0 = insertShape(base_image,'Rectangle',ground_truth,'Color','red','LineWidth',3);
	B = insertShape(B0,'Rectangle',starting_box,'Color','blue','LineWidth',3);
	%IOU of starting point
	orig_IOU = bboxOverlapRatio(starting_box,ground_truth);
    

    % do the first two moves to estabilish state history
    topmove = 0; topshift = 0;
    if apprentice_switch(apid)
        [topmove, topshift] = apprentice(starting_box,ground_truth);
    end
	[movement,IOU,new_crop,shift] = environment_update(base_image,object,ground_truth,starting_box,topmove, topshift);

    if movement == 1
    	B1 = insertShape(B,'Rectangle',new_crop,'Color','magenta','LineWidth',4);
    	imshow(B1);
    	disp('first move is no change')
        continue;
        close
    end
    % initialize the first state entry
	state{1}.movement = movement;
	% IOUdiff = 1 for positive change, otherwise 0
	state{1}.IOU = IOUdiff(IOU - orig_IOU);
	% keep track of actual IOU value
	old = IOU;
	state{1}.shift = shift;

    B1 = insertShape(B,'Rectangle',new_crop,'Color','green','LineWidth',4);
	% initialize second state entry
    topmove = 0; topshift = 0;
    if apprentice_switch(apid)
        [topmove, topshift] = apprentice(new_crop,ground_truth);
    end
	[movement,IOU,new_crop,shift] = environment_update(base_image,object,ground_truth,new_crop,topmove, topshift);
	state{2}.movement = movement;
	state{2}.IOU = IOUdiff(IOU - old);
	old = IOU; 
	state{2}.shift = shift;
    if movement == 1
    	B2 = insertShape(B,'Rectangle',new_crop,'Color','magenta','LineWidth',5);
    	imshow(B2);
    	disp('second move is no change')
        continue;
        close
    end
    B2 = insertShape(B1,'Rectangle',new_crop,'Color','yellow','LineWidth',5);
%     imshow(B2);
%     k = waitforbuttonpress;
	% now that state of history of depth two is initialized, start the update loop
	next = 0;
	for ii = 1:5
        
% 		shift = round(0.4*rand,1)+0.1;
        previous = new_crop;

        topmove = 0; topshift = 0;
        if apprentice_switch(apid)
            [topmove, topshift] = apprentice(new_crop,ground_truth);
        end
        
		[movement,IOU,new_crop,shift] = environment_update(base_image,object,ground_truth,new_crop,topmove, topshift);

        B1 = insertShape(B,'Rectangle',new_crop,'Color','green','LineWidth',4);
        if movement == 1
%             B1 = insertShape(B,'Rectangle',previous,'Color','magenta','LineWidth',4);
%             disp('no change on third crop');
%             imshow(B1);
%             k = waitforbuttonpress;

            break
        end
        state{3}.movement = movement;
		state{3}.IOU = IOUdiff(IOU - old);
		old = IOU;
		state{3}.shift = shift;

		% look up the current Q value, or Q(s,a) for this state action pair
		% state{1}, state{2}, and state{3}.movement constitute the state
		% state{3}.shift is the action
		Q_cur = Qlookup(state{1}.movement,state{1}.shift,state{1}.IOU,state{2}.movement,state{2}.shift,state{2}.IOU,movement,shift);
       
        topmove = 0; topshift = 0;
        if apprentice_switch(apid)    
            [topmove, topshift] = apprentice(new_crop,ground_truth);
%             [peekmovement,peekIOU,peek_crop,peekshift] = environment_update(base_image,object,ground_truth,new_crop,topmove, topshift);
            B2 = insertShape(B1,'Rectangle',peek_crop,'Color','yellow','LineWidth',5);
			if peekmovement == 1
				disp('next move is no change')
% 				B2 = insertShape(B1,'Rectangle',peek_crop,'Color','magenta','LineWidth',5);
				reward = 3;
				Q_update_val = Q_cur + learning_rate * ( reward );
				next = 1;
			else
				reward = IOUdiff(IOU - old);
				Q_max_peek = Qlookup(state{2}.movement,state{2}.shift,state{2}.IOU,state{3}.movement,state{3}.shift,state{3}.IOU,peekmovement,peekshift);
				Q_update_val = Q_cur + learning_rate * ( reward + discount * Q_max_peek - Q_cur);
			end
        else
%       % peek ahead one move, trying each possible action 
    		peek = zeros(5,7);
    		for k = 1:length(actions)
    			[movement,IOU,peek_crop] = environment_update(base_image,object,ground_truth,new_crop,topmove,actions(k));
    			peek(k,1) = movement;
    			peek(k,2) = IOUdiff(IOU - old);
    			peek(k,3:6) = peek_crop; %maybe unnecessary? 
    			peek(k,7) = Qlookup(state{2}.movement,state{2}.shift,state{2}.IOU,state{3}.movement,state{3}.shift,state{3}.IOU,movement,actions(k));
    		end
    
    		% find the index of Q(s',a') that had the highest Q value
    		best = find(peek(:,7) == max(peek(:,7)));
    		% break possible ties by selecting the first one
    		if length(best) > 1
    			best = best(1)
    		end

    		if peek(k,1) == 1
				disp('next move is no change')
% 				B2 = insertShape(B1,'Rectangle',peek_crop,'Color','magenta','LineWidth',5);
				reward = 3;
				Q_update_val = Q_cur + learning_rate * ( reward );
				next = 1;
			else    			
				% Q(s',a') = Q_max_peek
				Q_max_peek = peek(best,7);
				%             reward = 1 for positive IOUdiff, -1 for otherwise
				reward = 2 * peek(best,2) -1;
				Q_update_val = Q_cur + learning_rate * ( reward + discount * Q_max_peek - Q_cur);
			end
        end
% update the value of Q(s,a)
		Qupdate(Q_update_val,state{1}.movement,state{1}.shift,state{1}.IOU,state{2}.movement,state{2}.shift,state{2}.IOU,movement,shift);



% 		positions = [1 1; 1 50; 1 100; 1 150; 1 200; 1 250; 400 1; 400 50];
%                 values = {'current',strcat('IOUdiff: ',num2str(reward)),strcat('movement',num2str(movement)),strcat('shift: ',num2str(shift)),...
%                 strcat('Q_old v new:',num2str(Q_cur),'___',num2str(Q_update_val)),strcat('IOU values: ',num2str(old),'___',num2str(peekIOU)),'iteration',num2str(ii)};
%                 B3 = insertText(B2,positions,values,'AnchorPoint','LeftTop','FontSize',40);
%         
%         imshow(B3);
%         k = waitforbuttonpress;

 		%advance the state history       
		state{1} = state{2};
		state{2} = state{3};        

		%new_crop = peek(best,3:6);
		if next
			break
		end
    end

end
save('-v7.3','/stash/mm-group/evan/qtab.mat','Qtab')




