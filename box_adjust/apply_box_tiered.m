function [output_box_xywh, cur_iteration] = apply_box_tiered( box_adjust_model, object_label, im, input_box_xywh, num_adjustment_iterations, ground, doublemove)
% output_box_xywh = 0;
base255  = im2uint8(im);
im = base255;



% output_box_xywh = apply_box_adjust_models_mq( box_adjust_model, object_label, im, input_box_xywh, num_adjustment_iterations )
%
% box_adjust_model = 
% 
%                  objects_in_indexing_order: {'dogwalker'  'dog'  'leash'}
%               alignments_in_indexing_order: {'centered'    'up'    'down'    'left'    'right'    'expand'    'contract'    'background'}
%                  box_adjustment_models_1v1: {3x28 cell} ( of 1x1 Classification SVMs )
%     box_adjustment_models_1v1_descriptions: {3x28 cell}
%                            fnames_lb_train: {1x10 cell}
%                                          p: [1x1 struct]

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
    shift_max = 0.2; 
    shift_min = 0.2;
%counts up, down, left, and right translations, expands box after 5, not in
%use currently

%scale factor for contract and expand, decreases slightly when called
    s3 = 0.1;
    
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
    %initialize flags
    rflag = 0; lflag = 0; uflag = 0; dflag = 0; sflag = 0; eflag = 0;
    allsvm = linspace(1,21,21);
    lrc_svm = 16;
    udc_svm = 7;
    sec_svm = 21;
    track_1 = [0,16,16,16,7,7,7,21,21,21];
    track_2 = [0,7,7,7,16,16,16,21,21,21];
    track_3 = [0,21,21,21,7,7,7,16,16,16];

    for cur_iteration = 1:num_adjustment_iterations
        s = (shift_max - shift_min) * rand + shift_min;
        %secondary shift, for example a small up or down with a primary right or left
        %movement
%         s2 = 0.3 * rand - 0.15;
        s2 = 0;

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
        if cur_iteration == 1
            svm_indices = allsvm;
        else
            svm_indices = [cur_track(cur_iteration) 1 2 3 4 5 6];            
        end
        posteriors = zeros(length(box_adjust_model.box_adjustment_models_1v1(object_index,:)),2); % not currently used at all
        for mi = svm_indices

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
            if mi == 1 && cur_iteration ~= 1
                forced_choice = class_prediction{idx};
            else
                votes.(class_prediction{:}) = votes.(class_prediction{:}) + 1;
            end
           
        end

        alignments  = fieldnames(votes);
        [vote_counts,winning_inds] = sort(struct2array(votes),'descend');
        if cur_iteration == 1
            predicted_alignment = alignments{winning_inds(1)};
        elseif vote_counts(1) == 6 && winning_inds(1) == 1
            predicted_alignment = alignments{1};
        else
            predicted_alignment = forced_choice;
        end
            
        if cur_iteration == 1
            if strcmp(predicted_alignment,'left') == 1|| strcmp(predicted_alignment,'right') == 1
                cur_track = track_1;
            elseif strcmp(predicted_alignment,'up') == 1 || strcmp(predicted_alignment,'down') == 1
                cur_track = track_1;
            elseif strcmp(predicted_alignment,'expand') == 1 || strcmp(predicted_alignment,'contract') == 1
                cur_track = track_1;
            end
        end 
                
%         disp(predicted_alignment{1});
%         if (rflag && lflag && (strcmp(predicted_alignment{1},'right') == 1 || strcmp(predicted_alignment{1},'left') == 1)) || ...
%            (dflag && uflag && (strcmp(predicted_alignment{1},'up') == 1 || strcmp(predicted_alignment{1},'down') == 1))
%             redundant = 1;
%         else
%             redundant = 0;
%         end
%         if redundant && vote_counts(2) >= 4 && ~reverse
%             predicted_alignment{1} = alignments{winning_inds(2)};
% %             disp(predicted_alignment{2});
%         end
%         disp(votes);


            previous = [c0,r0,w,h];
            r = 1;
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
                        if dflag
                            r = 0.5;
                        elseif uflag && dflag
                            r = 0.2;
                        end
                        r0 = r0 + s*r*h;
                        rf = rf + s*r*h;
                        c0 = c0 + s2*w;
                        cf = cf + s2*w;
                        uflag = 1;
                case 'down'
                        if uflag
                            r = 0.5;
                        elseif uflag && dflag
                            r = 0.2;
                        end
                        r0 = r0 - s*r*h;
                        rf = rf - s*r*h;
                        c0 = c0 + s2*w;
                        cf = cf + s2*w;
                        dflag = 1;
                case 'left'
                    if rflag
                        r = 0.5;
                    elseif rflag && lflag
                        r = 0.2;
                    end
                    c0 = c0 + s*r*w;
                    cf = cf + s*r*w;
                    r0 = r0 + s2*h;
                    rf = rf + s2*h;
                    lflag = 1;
                case 'right'
                    if lflag
                        r = 0.5;
                    elseif rflag && lflag
                        r = 0.2;
                    end
                    c0 = c0 - s*r*w;
                    cf = cf - s*r*w;
                    r0 = r0 + s2*h;
                    rf = rf + s2*h;
                    rflag = 1;
                case 'expand'
                    if sflag
                        r = 0.5;
                    elseif sflag && eflag
                        r = 0.2;
                    end
                    r0 = r0 + s3*h;
                    rf = rf - s3*h;
                    c0 = c0 + s3*w;
                    cf = cf - s3*w;
                    eflag = 1;
                case 'contract'
                    if eflag
                        r = 0.5;
                    elseif sflag && eflag
                        r = 0.2;
                    end
                    r0 = r0 - s3*h;
                    rf = rf + s3*h;
                    c0 = c0 - s3*w;
                    cf = cf + s3*w;
                    sflag = 1;
                case 'background'
    %                 % don't know...break?
    %                 break
                otherwise
                    error('unrecognized alignment prediciton');
            end

            end_ex = 0.05;
                r0 = r0 - end_ex*h;
                rf = rf + end_ex*h;
                c0 = c0 - end_ex*w;
                cf = cf + end_ex*w;
                
            
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










