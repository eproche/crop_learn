for i = 1:numel(filenames{7,:})
	I = imread(filenames{i,1});
	I2 = padarray(I,[150,150]);
	file = filenames{i,1}(end-15:end);
	value = count_mat(i,:);
	value2 = score_mat(i,:);
	position = [161 1; 161 20; 161 40; 161 60; 161 80; 161 100; 161 120];
	RGB = insertText(I2,position,value,'AnchorPoint','RightTop');
	position2 = [70 1; 70 20; 70 40; 70 60; 70 80; 70 100; 70 120; ...
	70 140; 70 160; 70 180; 70 200; 70 220; 70 240; 70 260; ...
	70 280; 70 300; 70 320; 70 340; 70 360; 70 380; 70 400];

	RGB1 = insertText(RGB,position2,score_mat(i,:),'AnchorPoint','LeftTop');
	labels = [12 13 14 15 16 17 23 24 25 26 27 34 35 36 37 45 46 47 56 57 67]
	position3 = [1 1; 1 20; 1 40; 1 60; 1 80; 1 100; 1 120; ...
	1 140; 1 160; 1 180; 1 200; 1 220; 1 240; 1 260; ...
	1 280; 1 300; 1 320; 1 340; 1 360; 1 380; 1 400];
	RGB2 = insertText(RGB1,position3,labels,'AnchorPoint','LeftTop');
	figure
	imshow(RGB2),title(file);
	% score_mat(i,:)
	k = waitforbuttonpress
	close
end