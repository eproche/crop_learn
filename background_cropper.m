
%CROPPER makes datasets of cropped images, double scale_factor, double orig_factor, fli(-1,0,1),big_switch(0,1)
Path = '/stash/mm-group/evan/crop_learn/data/PortlandSimpleDogWalking';
rng('shuffle');
imgType = '*.jpg'; 
labelType = '*.labl';
imgFolder  = dir(fullfile(Path,imgType));
labelFolder = dir(fullfile(Path,labelType)); 
len_folder = length(imgFolder);

training_split = 0.8;
a = 0.0; %range for translation, proportional to original bounding box
b = 1.0;
split = (b-a).*rand(len_folder,1)+a; 

if ~exist('images','var')
    for i = 1:len_folder
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
end


for i = 312%cropping
    disp(i);
    dim = size(images{i});
    im_x = dim(2);
    im_y = dim(1);
    folder = '/stash/mm-group/evan/crop_learn/data/fullset/training/';
    if split(i) > training_split
        folder = '/stash/mm-group/evan/crop_learn/data/fullset/test/';
    end
    num_objects = record(i).num_obs;
    baseFile = num2str(i);
    boxes = cell(1,num_objects);
    for k = 1:num_objects
        box = strcat('obj',num2str(k),'_bbox');
        x = record(i).(box)(1);
        y = record(i).(box)(2);
        w = record(i).(box)(3);
        h = record(i).(box)(4);
        boxes{k} = [x y w h];
    end

    for k = 1:num_objects
        ob_num = strcat('obj',num2str(k));
        ob_name = record(i).(ob_num);
        gen = strsplit(ob_name,'-');

        if strcmp(gen{1},'leash') == 1
            object = 'leash/';
        elseif strcmp(gen{1},'dog') == 1
            object = 'dog/';
            if strcmp(gen{2},'walker') == 1
                object = 'walker/';
            end
        else 
            continue
        end


        % width_max = min(3*boxes{k}(3),im_x*0.4);
        % height_max = min(3*boxes{k}(4),im_y*0.4);
        % width_min = min(boxes{k}(3)*0.5,im_x*0.05);
        % height_min = min(boxes{k}(4)*0.5,im_y*0.05);
        width_max = 100;
        width_min = 50;
        height_max = 100;
        height_min = 50;
        x_range = (1400-800).*rand(500,1) + 800;
        y_range = (400).*rand(500,1);
        % x_range = (im_x-(im_x*0.41)).*rand(500,1);
        % y_range = (im_y-(im_y*0.41)).*rand(500,1); 
        w_range = (width_max-width_min).*rand(500,1)+width_min;
        h_range = (height_max-height_min).*rand(500,1)+height_min;

        crops = 1;
        idx = 1;
        while crops < 7
            crop_box = [x_range(idx),y_range(idx),w_range(idx),h_range(idx)];
            overlap = 0;
            for ii = 1:numel(boxes)
                if bboxOverlapRatio(crop_box,boxes{ii}) ~= 0
                    overlap = 1;
                    continue
                end

            end
            if overlap == 0
                crop = imcrop(images{i},crop_box);
                filename = fullfile(folder,strcat(object,'background/',baseFile,'-background',num2str(crops),'.jpg'));
                imwrite(crop,filename);
                idx = idx +1;
                crops = crops + 1;
            end
            idx = idx +1;
            if idx == 500;
                x_range = (im_x-(im_x*0.41)).*rand(500,1);
                y_range = (im_y-(im_y*0.41)).*rand(500,1); 
                w_range = (width_max-width_min).*rand(500,1)+width_min;
                h_range = (height_max-height_min).*rand(500,1)+height_min;
                idx = 1;
            end

        end

    end
end

