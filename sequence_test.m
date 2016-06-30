Path = 'PortlandNonProtoDogWalking';
rng('shuffle');
imgType = '*.jpg'; 
labelType = '*.labl';
imgFolder  = dir(fullfile(Path,imgType));
labelFolder = dir(fullfile(Path,labelType)); 
len_folder = length(imgFolder);
% svm_model = load('cnn/matconvnet-1.0-beta20/svm_dog.mat');

for i = 1:10
    images{i} = imread(fullfile(Path,imgFolder(i).name));
    temp = fopen(fullfile(Path,labelFolder(i).name));
    temp2 = textscan(temp,'%s','delimiter','|');
    temp2{1} = strrep(temp2{1},'/','');
    temp2{1} = strrep(temp2{1},' ','-');
    record(i).id = i;
    record(i).width = str2num(temp2{1}{1});
    record(i).height = str2num(temp2{1}{2});
    num_objects = str2num(temp2{1}{3});
    record(i).num_obs = num_objects;
    for k = 1:num_objects
        ob_num = strcat('obj',num2str(k));
        bbox = strcat(ob_num,'_bbox');
        record(i).(ob_num) = temp2{1}{(num_objects*4)+3+k}; %get object name
        x = str2num(temp2{1}{4+((k-1)*4)}); %get bounding box
        y = str2num(temp2{1}{5+((k-1)*4)});
        w = str2num(temp2{1}{6+((k-1)*4)});
        h = str2num(temp2{1}{7+((k-1)*4)});
        record(i).(bbox) = [x y w h];
    end 
    fclose(temp);
end

start_list = {{'right','down'},{'right','up'},{'right','expand'},{'right','shrink'},...
{'left','down'},{'left','up'},{'right','expand'},{'right','shrink'},...
{'down','expand'},{'down','shrink'},{'up','expand'},{'up','shrink'}};
scale_factor = 0.4;
a = 0.4;
b = 0.6;
c = 0.1; %optional secondary shift 
d = 0.2;

for i = 1:10 %cropping
    num_objects = record(i).num_obs;
    for k = 1:num_objects
        ob_num = strcat('obj',num2str(k));
        ob_name = record(i).(ob_num);
        gen = strsplit(ob_name,'-');

        % if strcmp(gen{1},'leash') == 1
        %     object = 'leash';
        if strcmp(gen{1},'dog') == 1
            object = 'dog';
            if strcmp(gen{2},'walker') == 1
                continue
            end
        else 
            continue
        end
        
        box = strcat('obj',num2str(k),'_bbox');
        x = record(i).(box)(1);
        y = record(i).(box)(2);
        w = record(i).(box)(3);
        h = record(i).(box)(4);
        % r = (b-a).*rand(4,1)+a; 
        % r2 = (d-c).*rand(4,1)+c;
        r = [0.4 0.4 0.4 0.4]
        r2 = [0.1 0.1 0.1 0.1]
        fli = 1;
        big_w = w*(1+scale_factor);
        big_h = h*(1+scale_factor);
        small_w = w*(1-scale_factor);
        small_h = h*(1-scale_factor);
        orig_box = [x y w h];

        for j = 1:numel(start_list)
            I = images{i};
            B = insertShape(I,'Rectangle',orig_box,'Color','red','LineWidth',5);
            first = start_list{j}{1}
            fh = str2func(first);
            seco = start_list{j}{2}
            fh2 = str2func(seco);

            % new_w = big_w;
            % new_h = big_h;
            % if strcmp(first,'shrink') == 1
            %     new_w = small_w;
            %     new_h = small_h;
            %end
            temp = fh(x,y,w,h,r,r2,fli,new_w,new_h);
            x1 = temp(1); y1 = temp(2); w1 = temp(3); h1 = temp(4);

            new_w = big_w;
            new_h = big_h;
            if strcmp(seco,'shrink') == 1
                new_w = small_w;
                new_h = small_h;
            end
            crop = fh2(x1,y1,w1,h1,r,r2,fli,new_w,new_h);
            B2 = insertShape(B,'Rectangle',crop,'Color','blue','LineWidth',3);
            imshow(B2);
            k = waitforbuttonpress;
            % start_crop = imcrop(images{i}[crop])
        end


    end
end

