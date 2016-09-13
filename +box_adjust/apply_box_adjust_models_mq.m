function [output_box_xywh, cur_iteration] = apply_box_adjust_models_mq( box_adjust_model, object_label, im, input_box_xywh, num_adjustment_iterations, ground)
% output_box_xywh = 0;
base255  = im2uint8(im);
im = base255;

% alignments_in_indexing_order: {'centered'    'up'    'down'    'left'    'right'    'expand'    'contract'    'background'}
% number encodings              {1              2       3         4          5         6           7             8}

% class_pairs = 

%     'cent'      'up'        [ 1]
%     'cent'      'down'      [ 2]
%     'cent'      'right'     [ 3]
%     'cent'      'left'      [ 4]
%     'cent'      'shrink'    [ 5]
%     'cent'      'expand'    [ 6]
%     'up'        'down'      [ 7]
%     'up'        'right'     [ 8]
%     'up'        'left'      [ 9]
%     'up'        'shrink'    [10]
%     'up'        'expand'    [11]
%     'down'      'right'     [12]
%     'down'      'left'      [13]
%     'down'      'shrink'    [14]
%     'down'      'expand'    [15]
%     'right'     'left'      [16]
%     'right'     'shrink'    [17]
%     'right'     'expand'    [18]
%     'left'      'shrink'    [19]
%     'left'      'expand'    [20]
%     'shrink'    'expand'    [21]


    % figure out what object index we have based on the interest
    object_index = find(strcmp(box_adjust_model.objects_in_indexing_order, object_label ));

    % grab the current crop
    c0 = input_box_xywh(1);
    r0 = input_box_xywh(2);
    w  = input_box_xywh(3);
    h  = input_box_xywh(4);
    rf = r0 + h - 1;
    cf = c0 + w - 1;
    
    % correct boxes for image edges
    r0 = round(max(r0,1));
    rf = round(min(rf,size(im,1)));
    c0 = round(max(c0,1));
    cf = round(min(cf,size(im,2)));
    
%max and min percentage for primary shift factor, decreases slightly for each call to up, down, left, and right
    shift_max = 0.4; 
    shift_min = 0.3;
%counts up, down, left, and right translations, expands box after 5, not in
%use currently
    t_count = 0;
%scale factor for contract and expand, decreases slightly when called
    s3 = 0.1;
  
% checks to see if there's a current figure to draw over  
    vis = 1;
    fig = get(groot,'CurrentFigure');
    if isempty(fig)
        vis = 0;
    end
    if vis == 1
        set(0, 'currentfigure', fig);  %# for figures
        set(fig, 'currentaxes', fig.Children(end)); 
        I = im;
        B0 = insertShape(I,'Rectangle',input_box_xywh,'Color','blue','LineWidth',3);
        B = insertShape(B0,'Rectangle',ground,'Color','red','LineWidth',3);
    end

% main search loop
    for cur_iteration = 1:num_adjustment_iterations
        s = (shift_max - shift_min) * rand + shift_min;
        %secondary shift, for example a small up or down with a primary right or left
        %movement
        s2 = 0.3 * rand - 0.15;
%         s2 = 0;

        cur_crop = im(r0:rf,c0:cf,:);
        cur_feature_vect = box_adjust_model.feature_extraction_function( cur_crop );

        % initialize votes
        votes = [];
        for ai = 1:length(box_adjust_model.alignments_in_indexing_order)
            cur_alignment = box_adjust_model.alignments_in_indexing_order{ai};
            votes.(cur_alignment) = 0;
        end

        % get the alignment prediction from each model
        % add to the vote counts
        posteriors = zeros(length(box_adjust_model.box_adjustment_models_1v1(object_index,:)),2); % not currently used at all
        for mi = 1:length( box_adjust_model.box_adjustment_models_1v1(object_index,:) )

           [class_prediction,posteriors(mi,:)] = predict(  box_adjust_model.box_adjustment_models_1v1{object_index,mi}, cur_feature_vect  );
            for idx = 1:length(class_prediction)
                if strcmp(class_prediction{idx}, '1') == 1;
                    class_prediction{idx} ='centered';
                    adjust = 'no change';
                elseif strcmp(class_prediction{idx}, '2') == 1;
                    class_prediction{idx} ='up';
                    adjust = 'down';
                elseif strcmp(class_prediction{idx},  '3') == 1;
                    class_prediction{idx} ='down';
                    adjust = 'up';
                elseif strcmp(class_prediction{idx},  '4') == 1;  
                    class_prediction{idx} ='right';
                    adjust = 'left';
                elseif strcmp(class_prediction{idx},  '5') == 1;
                    class_prediction{idx} ='left';
                    adjust = 'right';
                elseif strcmp(class_prediction{idx},  '6') == 1;
                    class_prediction{idx} ='contract';
                    adjust = 'expand';
                elseif strcmp(class_prediction{idx},  '7') == 1;
                    class_prediction{idx} ='expand';
                    adjust = 'contract';
                end
            end
            
        
           votes.(class_prediction{:}) = votes.(class_prediction{:}) + 1;
        end



        alignments  = fieldnames(votes);
        [~,winning_ind] = max(struct2array(votes));
        predicted_alignment = alignments{winning_ind};
        previous = [c0,r0,w,h];
        switch predicted_alignment
            case 'centered'
                % should break and return the current box
                if vis == 1
                   B3 = insertShape(B,'Rectangle',[c0,r0,w,h],'Color','magenta','LineWidth',3);
                   fig; imshow(B3);

                   k = waitforbuttonpress;
                   fig; imshow(I)
                end
                r0 = round(max(r0,1));
                rf = round(min(rf,size(im,1)));
                c0 = round(max(c0,1));
                cf = round(min(cf,size(im,2)));
                output_box_xywh = [c0, r0, cf-c0+1, rf-r0+1];
                return
            case 'up'
                % move down a little
                if strcmp(object_label,'dogwalker') == 1
                     r0 = r0 + (s/2)*h;
                     rf = rf + (s/2)*h;
                else    
                    r0 = r0 + s*h;
                    rf = rf + s*h;
                    c0 = c0 + s2*w;
                    cf = cf + s2*w;
                end
                shift_max = shift_max - 0.025;
                shift_min = shift_min - 0.025;
                t_count = t_count + 1;
            case 'down'
                % move up a little
                if strcmp(object_label,'dogwalker') == 1
                     r0 = r0 - (s/2)*h;
                     rf = rf - (s/2)*h;
                else    
                    r0 = r0 - s*h;
                    rf = rf - s*h;
                    c0 = c0 + s2*w;
                    cf = cf + s2*w;
                end
                shift_max = shift_max - 0.025;
                shift_min = shift_min - 0.025;
                t_count = t_count + 1;
            case 'left'
                % move right alittle
                c0 = c0 + s*w;
                cf = cf + s*w;
                r0 = r0 + s2*h;
                rf = rf + s2*h;
                shift_max = shift_max - 0.025;
                shift_min = shift_min - 0.025;
                t_count = t_count + 1;
            case 'right'
                % move left a little
                c0 = c0 - s*w;
                cf = cf - s*w;
                r0 = r0 + s2*h;
                rf = rf + s2*h;
                shift_max = shift_max - 0.025;
                shift_min = shift_min - 0.025;
                t_count = t_count + 1;
            case 'expand'
                % contract a little
                r0 = r0 + s3*h;
                rf = rf - s3*h;
                c0 = c0 + s3*w;
                cf = cf - s3*w;
                s3 = s3 - 0.025;
            case 'contract'
                % expand a little
                r0 = r0 - s3*h;
                rf = rf + s3*h;
                c0 = c0 - s3*w;
                cf = cf + s3*w;
                s3 = s3 - 0.025;
            case 'background'
%                 % don't know...break?
%                 break
            otherwise
                error('unrecognized alignment prediciton');
        end

        if s3 < 0.05
            s3 = 0.2;
        end
        if shift_max <= 0.05;
            shift_max = 0.3;
            shift_min = 0.2;
        end

% aspect ratio adjustment based on number of iterations. Resize to square for dog and rectangle for walker
%         if t_count == 5
%             shift_max = 0.4;
%             shift_min = 0.3;
%             t_count = 0;
%             if strcmp(object_label,'dogwalker') == 1
%                 w1 = size(im,1)/8;
%                 h1 = size(im,1)/4;
%                 h_ratio = h/h1;
%                 w_ratio = w/w1;
%                 r0 = r0 - h_ratio * h;
%                 rf = rf + h_ratio * h;
%                 c0 = c0 - w_ratio * w;
%                 cf = cf + w_ratio * w;
%             else
%                 w1 = size(im,1)/12;
%                 h1 = w1;
%                 h_ratio = h1/h;
%                 w_ratio = w1/w;
%                 r0 = r0 - h_ratio * h;
%                 rf = rf + h_ratio * h;
%                 c0 = c0 - w_ratio * w;
%                 cf = cf + w_ratio * w;
%             end
%         end
        
        % make small, random adjustment to the box center
        r_delta = .1 * h * randn(1)/3;
        c_delta = .1 * w * randn(1)/3;
        r0 = r0 + r_delta;
        rf = rf + r_delta;
        c0 = c0 + c_delta;
        cf = cf + c_delta;
        
        % correct boxes for image edges
        r0 = round(max(r0,1));
        rf = round(min(rf,size(im,1)));
        c0 = round(max(c0,1));
        cf = round(min(cf,size(im,2)));
        
        % update width and height
        w = cf-c0+1;
        h = rf-r0+1;
        if vis == 1
            B3 = insertShape(B,'Rectangle',previous,'Color','green','LineWidth',3);
            B4 = insertShape(B3,'Rectangle',[c0,r0,w,h],'Color','yellow','LineWidth',3);
            positions = [1 1; 1 25; 1 50; 1 75; 1 100; 1 125; 250 1; 250 25];
            values = {'previous',strcat('IOU: ',num2str(1)),predicted_alignment,strcat('move_amount: ',num2str(s)),...
            strcat('scale:',num2str(s3)),num2str(cur_iteration),'searching',object_label};
            B5 = insertText(B4,positions,values,'AnchorPoint','LeftTop','FontSize',18);
            fig; imshow(B5);
            k = waitforbuttonpress;
            fig; imshow(I);
        end
        

    end
    output_box_xywh = [c0, r0, cf-c0+1, rf-r0+1];
    
end










