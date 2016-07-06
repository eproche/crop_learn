function [] = cropper(scale_factor,orig_factor,fli,big_switch)
%CROPPER makes datasets of cropped images, double scale_factor, double orig_factor, fli(-1,0,1),big_switch(0,1)
Path = 'PortlandSimpleDogWalking';
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



for i = 1:len_folder%cropping
    folder = '/stash/mm-group/evan/crop_learn/data/fullset/training/';
    if split(i) > training_split
        folder = '/stash/mm-group/evan/crop_learn/data/fullset/test/';
    end
    num_objects = record(i).num_obs;
    baseFile = num2str(i);
    for k = 1:num_objects
        ob_num = strcat('obj',num2str(k));
        ob_name = record(i).(ob_num);
        gen = strsplit(ob_name,'-');

        if strcmp(gen{1},'leash') == 1
            object = 'leash/'
        elseif strcmp(gen{1},'dog') == 1
            idx = 0;
            object = 'dog/';
            if strcmp(gen{2},'walker') == 1
                idx = 1;
                object = 'walker/';
            end
            % if strcmp(gen{2+idx},'front') == 1
            %     ori = 'front/';
            % elseif strcmp(gen{2+idx},'back') == 1
            %     ori = 'back/' ;
            % elseif strcmp(gen{3+idx},'right') == 1
            %     ori = 'right/';
            % elseif strcmp(gen{3+idx},'left') == 1
            %     ori = 'left/';
            % end 
        else 
            continue
        end
        
        box = strcat('obj',num2str(k),'_bbox');
        x = record(i).(box)(1);
        y = record(i).(box)(2);
        w = record(i).(box)(3);
        h = record(i).(box)(4);
        a = 0.3;
        b = 0.5;
        if big_switch == 0
            a = 0.3;
            b = 0.5;
            shift_size = '-small';
        elseif big_switch == 1   
            a = 0.5; %range for translation, proportional to original bounding box
            b = 0.7;
            shift_size = '-big';
        end
        c = 0.1; %optional secondary shift 
        d = 0.2;
        r = (b-a).*rand(4,1)+a; 
        r2 = (d-c).*rand(4,1)+c;

        if fli == 0
            neg = '';
        elseif fli == 1
            neg = '-n';
        elseif fli == -1
            neg = '-p';
        end
            
        detail = strcat(shift_size,neg);
        detail1 = strcat('-',num2str(scale_factor));
        detail2 = strcat(neg,'-',num2str(orig_factor));

        rightcrop = imcrop(images{i},[x+(w*r(1)),y+(h*r2(1)*fli),w,h]);
        leftcrop = imcrop(images{i},[x-(w*r(2)),y+(h*r2(2)*fli),w,h]);
        downcrop = imcrop(images{i},[x+(w*r2(3)*fli),y+(h*r(3)),w,h]);
        upcrop = imcrop(images{i},[x+(w*r2(4)*fli),y-(h*r(4)),w,h]);

        big_w = w*(1+scale_factor);
        big_h = h*(1+scale_factor);
        small_w = w*(1-scale_factor);
        small_h = h*(1-scale_factor);
        orig_w = w*(1+orig_factor);
        orig_h = h*(1+orig_factor);

        origcrop = imcrop(images{i},[x+(w/2)-orig_w/2,y+(h/2)-orig_h/2,orig_w,orig_h]);
        expandcrop = imcrop(images{i},[x+(w/2)-big_w/2,y+(h/2)-big_h/2,big_w,big_h]);
        shrinkcrop = imcrop(images{i},[x+(w/2)-small_w/2,y+(h/2)-small_h/2,small_w,small_h]);

        expandname = fullfile(folder,strcat(object,'expand/',baseFile,'-',ob_name,'_s-expand',detail1,'.jpg'));
        shrinkname = fullfile(folder,strcat(object,'shrink/',baseFile,'-',ob_name,'_s-shrink',detail1,'.jpg'));
        origname = fullfile(folder,strcat(object,'orig/',baseFile,'-',ob_name,'_no-change',detail2,'.jpg'));
        downname = fullfile(folder,strcat(object,'down/',baseFile,'-',ob_name,'_t-down',detail,'.jpg'));
        upname = fullfile(folder,strcat(object,'up/',baseFile,'-',ob_name,'_t-up',detail,'.jpg'));
        rightname = fullfile(folder,strcat(object,'right/',baseFile,'-',ob_name,'_t-right',detail,'.jpg'));
        leftname = fullfile(folder,strcat(object,'left/',baseFile,'-',ob_name,'_t-left',detail,'.jpg'));         
        imwrite(origcrop,origname);
        imwrite(downcrop,downname);
        imwrite(upcrop,upname);
        imwrite(leftcrop,leftname);
        imwrite(rightcrop,rightname);  
        imwrite(expandcrop,expandname);
        imwrite(shrinkcrop,shrinkname);

    end
end

