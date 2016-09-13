
function crop = num2move(class_guess)
	class_guess = str2num(class_guess);
	if class_guess == 0;
        return
    elseif class_guess == 1 % down
        crop = 'up';
    elseif class_guess == 2 % up
        crop = 'down';
    elseif class_guess == 3 % left
        crop = 'right';
    elseif class_guess == 4 % right
        crop = 'left';           
    elseif class_guess == 5 % shrink
        crop = 'expand';
    elseif class_guess == 6 % expand
        crop = 'shrink';
    elseif class_guess == 8; % background
        crop = 'expand';
    end
end