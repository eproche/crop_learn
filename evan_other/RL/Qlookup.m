function value = Qlookup(move1,act1,iou1,move2,act2,iou2,cur_move,cur_action)
	global Qtab
	key = strcat(num2str(move1),',',num2str(act1),',',num2str(iou1),',',...
		num2str(move2),',',num2str(act2),',',num2str(iou2),',',num2str(cur_move),',',num2str(cur_action));
	% disp(key)
	value = Qtab(key)


