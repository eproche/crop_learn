function crop = num2move(class_guess)
%translates predicted alignment number from Qtable to the corresponding correcting action
	class_guess = str2num(class_guess);
	if class_guess == 0;
        return
    elseif class_guess == 1 % no change
        crop = 'no change';
    elseif class_guess == 2 % up
        crop = 'down';
    elseif class_guess == 3 % down
        crop = 'up';
    elseif class_guess == 4 % right
        crop = 'left';           
    elseif class_guess == 5 % left
        crop = 'right';
    elseif class_guess == 6 % shrink
        crop = 'expand';
    elseif class_guess == 7; % expand
        crop = 'shrink';  
    elseif class_guess == 8;
        crop = 'background'     
    end
end

