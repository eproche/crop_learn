function [b,name] = evan2max(a)
	
	if a == 1
        b = 7;
		name = 'No Change';
	elseif a == 2
        b = 2;
		name = 'Down';
	elseif a == 3
        b = 1;
		name = 'Up';
	elseif a == 4
        b = 4;
		name = 'Left';
	elseif a == 5
        b = 3;
		name = 'Right';
	elseif a == 6
        b = 5;
		name = 'Expand';
	elseif a == 7
        b = 6;
		name = 'Shrink';
	elseif a == 0
        b = 0;
		name = 'Past image bounds'
	elseif a == 8
        b = 8;
		name = 'Background';
	end