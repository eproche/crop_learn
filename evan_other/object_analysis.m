dog_log = cell(5,1,100);
walk_log = cell(5,1,100);
leash_log = cell(5,1,100);

for ii = 1:5
di = 1;
wi = 1;
li = 1;
for i = 1:100
	for k = 1:size(workspace_entry_event_logs{ii,i},1)
		if strcmp(workspace_entry_event_logs{ii,i}{k,2},'dog') == 1
			dog_log{ii,di} = workspace_entry_event_logs{ii,i}(k,:);
			di = di + 1;
		elseif strcmp(workspace_entry_event_logs{ii,i}{k,2},'dogwalker') == 1
			walk_log{ii,wi} = workspace_entry_event_logs{ii,i}(k,:);
			wi = wi + 1;
		elseif strcmp(workspace_entry_event_logs{ii,i}{k,2},'leash') == 1
			leash_log{ii,li} = workspace_entry_event_logs{ii,i}(k,:);
			li = li + 1;
		end
	end
end
end

res = zeros(5,305,2);	
for i = 1:5
	for k = 1:305
		if ~isempty(leash_log{i,k})
			res(i,k,1) = leash_log{i,k}{1};
			res(i,k,2) = leash_log{i,k}{3};
		end
	end
end

prov = zeros(5,1000);
final = zeros(5,1000);
res2 = res(:,:,2);
res1 = res(:,:,1);

res3 = res2;
res3(res3 < 0.5) = 0;
res2(res2 >= 0.5) = 0;

for k = 1:5
for i = 1:1000
	pc = find(res2(k,:) ~= 0);
	fc = find(res3(k,:) ~= 0);
	pnum = res1(k,pc);
	fnum = res1(k,fc);
	prov(k,i) = length(find(pnum <= i));
	fin(k,i) = length(find(fnum <= i));
end
end

colors = cool(5);
h2 = figure();
h2.Color = [1 1 1];
hold on;
for i = 1:5
	plot(fin(i,:),'Color',colors(i,:))
end
h_temp = legend(unique_descriptions,'Location','Northeast');

close
h2 = figure();
h2.Color = [1 1 1];
hold on;
for i = 1:5
	plot(prov(i,:),'Color',colors(i,:))
end
h_temp = legend(unique_descriptions,'Location','Northeast');