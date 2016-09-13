%% quick detection curve plot for list of situate result files

fn = {};

%% paths to files, ex,
% fn{end+1} = '/stash/mm-group/evan/results/box_350_split_01_2016.07.20.18.50.16.mat';     

curv = zeros(1000,1);
for i = 1:6
	load (fn{i});
	res = zeros(50,1);
	for k = 1:50
		res(k) = workspace_entry_event_logs{k}{end,1};
	end
	batch = zeros(1000,1);
	for j =1:1000
		batch(j) = length(find(res < j));
	end 
	curv = curv + batch;
end

