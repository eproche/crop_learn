for i = 1:100
for k = 1:size(workspace_entry_event_logs{i},1)
if isempty(workspace_entry_event_logs{i}{k,4})
	workspace_entry_event_logs{i}{k,4} = 0;
end
workspace_entry_event_logs{i}{k,1} = workspace_entry_event_logs{i}{k,1} + sum(cell2mat(workspace_entry_event_logs{i}(1:k,4)));
end
end

tote = []
for i = 1:100
% indx = find(cell2mat(workspace_entry_event_logs{i}(:,5)) == 1);
tote = [tote;cell2mat(workspace_entry_event_logs{i}(:,4))]
end

for i = 1:21
	disp(i)
	for k = 1:2
		class_name = svm_model{i}.ClassNames{k}
		if class_name == '1';
			change = 'centered';
		elseif class_name == '2'
			change = 'up';
		elseif class_name == '3'
			change = 'down';
		elseif class_name == '4'
			change = 'left';
		elseif class_name == '5'
			change = 'right';
		elseif class_name == '6'
			change = 'expand';
		elseif class_name == '7'
			change = 'contract';
		svm_model{i}.ClassNames{k} = change
	end
	end 
end
