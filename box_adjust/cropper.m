% function [] = cropper(fnames)
% make crop directories: rewrites at each call

    fnames = '/stash/mm-group/evan/fnames/box_adjust_fnames_split_01_test.txt';
    Path = '/stash/mm-group/evan/data/PortlandSimpleDogWalking/';
    rng('shuffle');
    label_list = dataread('file',fnames,'%s','delimiter','\n')
    split_type = 'test';
    
    len_list = length(label_list);
    here = pwd;
    cd '/stash/mm-group/evan/data/fullset2'

    mkdir(split_type);
    cd (split_type);

    mkdir('dog','down');
    mkdir('dog','up');
    mkdir('dog','left');
    mkdir('dog','right');
    mkdir('dog','shrink');
    mkdir('dog','expand');
    mkdir('dog','orig');
    mkdir('dog','background');

    mkdir('walker','down');
    mkdir('walker','up');
    mkdir('walker','left');
    mkdir('walker','right');
    mkdir('walker','shrink');
    mkdir('walker','expand');
    mkdir('walker','orig');
    mkdir('walker','background');

    mkdir('leash','down');
    mkdir('leash','up');
    mkdir('leash','left');
    mkdir('leash','right');
    mkdir('leash','shrink');
    mkdir('leash','expand');
    mkdir('leash','orig');
    mkdir('leash','background');
    cd (here);

    if ~exist('record','var')
    for i = 1:len_list
        image_path = strcat(Path,strrep(label_list(i),'.labl','.jpg'));
        images{i} = imread(image_path{1});
        label_list(i) = strrep(label_list(i),'.jpg','.labl');
        temp = fopen(fullfile(Path,label_list{i}));
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


    for i = 1:len_list
        disp(i)
        if strcmp(split_type,'train') == 1
            folder = '/stash/mm-group/evan/data/fullset2/train/';
        elseif strcmp(split_type,'test') == 1
            folder = '/stash/mm-group/evan/data/fullset2/test/';
        end
        num_objects = record(i).num_obs;
        baseFile = num2str(i);
        for k = 1:num_objects
        box = strcat('obj',num2str(k),'_bbox');
            x = record(i).(box)(1);
            y = record(i).(box)(2);
            w = record(i).(box)(3);
            h = record(i).(box)(4);
            boxes{k} = [x y w h];
        end
        
        obid = 1;
        for k = 1:num_objects
            ob_num = strcat('obj',num2str(k));
            ob_name = record(i).(ob_num);
            gen = strsplit(ob_name,'-');
            % if strcmp(gen{1},'dog') == 1
            % elseif strcmp(gen{1},'pedestrian') == 1
            % else 
            %     continue
            % end
            box = strcat('obj',num2str(k),'_bbox');
                x = record(i).(box)(1);
                y = record(i).(box)(2);
                w = record(i).(box)(3);
                h = record(i).(box)(4);
                obboxes{obid} = [x y w h];
                obid = obid + 1; 
        end

        for k = 1:num_objects
            ob_num = strcat('obj',num2str(k));
            ob_name = record(i).(ob_num);
            gen = strsplit(ob_name,'-');
            ob_name = strcat('',ob_name,num2str(i),'_',num2str(k));

            if strcmp(gen{1},'leash') == 1
                object = 'leash/';
            % elseif strcmp(gen{1},'pedestrian') == 1
            %     object = 'walker/';
            % elseif strcmp(gen{1},'person') == 1
            %     object = 'walker/';
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
            
            % overlap = 0;
            % if k < length(obboxes);
            %     for ii = k+1:numel(obboxes)
            %         x2 = obboxes{ii}(1); y2 = obboxes{ii}(2); w2 = obboxes{ii}(3); h2 = obboxes{ii}(4);
            %         if (x < x2 + w2 && x + w >x2 && y < y2 + h2 && y + h > y2); 
            %             overlap = 1;
            %             break
            %         end
            %     end
            % end
            % if overlap == 1
            %     continue
            % end

            %% generate 6 background crops per object on first parameter run
            %background_cropper(ob_name,object,images{i},x,y,w,h,folder,boxes)
            scale_factor = [0.3 0.4 0.5 0.6 0.7 0.8];
            orig_factor = [0 0.05 0.1 -0.05 -0.1 -0.15];
            fli = [0 1 -1 0 1 -1];
            big_switch = [0 0 0 1 1 1];
%             background_cropper(ob_name,object,images{i},x,y,w,h,folder,boxes)
%             scale_factor = [0.3 0.4 0.5 0.6];
%             orig_factor = [0 0.05 0.1 -0.05];
%             fli = [1 -1 1 -1];
%             big_switch = [0 0 1 1];
            for ii = 1:length(scale_factor)
                a = 0.3;
                b = 0.5;
                if big_switch(ii) == 0
                    a = 0.3;
                    b = 0.5;
                    shift_size = '-small';
                elseif big_switch(ii) == 1   
                    a = 0.5; %range for translation, proportional to original bounding box
                    b = 0.7;
                    shift_size = '-big';
                end
                c = 0.05; %optional secondary shift 
                d = 0.1;
                r = (b-a).*rand(4,1)+a; 
                r2 = (d-c).*rand(4,1)+c;

                if fli(ii) == 0
                    neg = '';
                elseif fli(ii) == 1
                    neg = '-n';
                elseif fli(ii) == -1
                    neg = '-p';
                end
                    
                detail = strcat(shift_size,neg);
                detail1 = strcat('-',num2str(scale_factor(ii)));
                detail2 = strcat(neg,'-',num2str(orig_factor(ii)));

                rightcrop = imcrop(images{i},[x+(w*r(1)),y+(h*r2(1)*fli(ii)),w,h]);
                leftcrop = imcrop(images{i},[x-(w*r(2)),y+(h*r2(2)*fli(ii)),w,h]);
                downcrop = imcrop(images{i},[x+(w*r2(3)*fli(ii)),y+(h*r(3)),w,h]);
                upcrop = imcrop(images{i},[x+(w*r2(4)*fli(ii)),y-(h*r(4)),w,h]);

                big_w = w*(1+scale_factor(ii));
                big_h = h*(1+scale_factor(ii));
                small_w = w*(1-scale_factor(ii));
                small_h = h*(1-scale_factor(ii));
                orig_w = w*(1+orig_factor(ii));
                orig_h = h*(1+orig_factor(ii));

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
    end
    clear

