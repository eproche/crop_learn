function [class_guess,IOU,new_crop,shift] = environment_update(base,object,ground,crop,topmove,shift)
	global dog_svm_model walker_svm_model leash_svm_model svm_model;
	start_crop = imcrop(base,crop);
    
    if topmove == 0
	    if strcmp(object,'dog') == 1
			class_guess = predict_crop(start_crop,dog_svm_model);
		elseif strcmp(object,'walker') == 1
			class_guess = predict_crop(start_crop,walker_svm_model);
		else
			disp('no matching model');
	    end 
	else
		disp('USING APPRENTICE')
		class_guess = topmove
	end
        
    if topmove
    	shift = min(0.5,shift);
    	shift = max(0.1,shift);
   	else
   		shift = round(0.4*rand,1)+0.1;
    end

    % if (v == 0 && class_guess == 2) || (v == 1 && class_guess == 3)
    %     shift = min(0.5,good_vertical);
    %     shift = max(0.1,shift);
    % elseif (h == 0 && class_guess == 5) || (h == 1 && class_guess == 4)
    %     shift = min(0.5,good_horizontal);
    %     shift = max(0.1,shift);
    % elseif (resize == 0 && class_guess == 6) || (resize == 1 && class_guess == 7)
    %     shift = min(0.5,good_resize);
    %     shift = max(0.1,shift);
    % else
    %     shift = round(0.4*rand,1)+0.1;
    % end
    
    % primary shift amount, passed from reinforcement training
    r3 = [shift,shift,shift,shift];
	% change r4 to add randomized secondary shifting
	r4 = [1,1,1,1];
	% fli determines direction of secondary shifting
	fli = 0;

	% dummy variables
	new_w = 0; new_h = 0;

	%get dimensions
	x2 = crop(1); y2 = crop(2); w2 = crop(3); h2 = crop(4);

	% shift is the only action, so these functions determines how it affects 
	% shrink and expand actions
	bnew_w = w2*(1+shift);
	bnew_h = h2*(1+shift);
	snew_w = w2*(1-shift);
	snew_h = h2*(1-shift);
	
    if class_guess == 1;
        IOU = bboxOverlapRatio(crop,ground);
        new_crop = crop;
        return
    elseif class_guess == 3 % down
        crop = up(x2,y2,w2,h2,r3,r4,fli,new_w,new_h);
    elseif class_guess == 2 % up
        crop = down(x2,y2,w2,h2,r3,r4,fli,new_w,new_h);
    elseif class_guess == 5 % left
        crop = right(x2,y2,w2,h2,r3,r4,fli,new_w,new_h);
    elseif class_guess == 4 % right
        crop = left(x2,y2,w2,h2,r3,r4,fli,new_w,new_h);               
    elseif class_guess == 6 % shrink
        crop = expand(x2,y2,w2,h2,r3,r4,fli,bnew_w,bnew_h);
    elseif class_guess == 7 % expand
        crop = shrink(x2,y2,w2,h2,r3,r4,fli,snew_w,snew_h);
    elseif class_guess == 8; % background, right now this expands by a fixed amount
        crop = expand(x2,y2,w2,h2,r3,r4,fli,w2*1.4,h2*1.4);    
    end

    % return the new crop and IOU, along with predicted movement
    new_crop = crop;
    IOU = bboxOverlapRatio(new_crop,ground);