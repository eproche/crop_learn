function [agent_pool,d] = agent_evaluate_scout( agent_pool, agent_index, im, im_label, d, p, workspace )     
    global cnn_svm_model dog_svm_model walker_svm_model leash_svm_model cnn_net cnn_layer sub_counts;
    interest = agent_pool(agent_index).interest;
    
    % figure out which distribution index is associated with our current interest
    di = find(strcmp({d.interest},interest)); 
    [d(di), sampled_box_r0rfc0cf,w,h,rc,cc] = situate_sample_box( d(di), p );

    % adjust sampled box to fit within the image bounds
    %   the sampled location will already be inhibited by the
    %   situate_sample_box call, so all we need to do is adjust the box
    %   bounds for display, IOU calculation, and sending to the classifier
        r0 = max(sampled_box_r0rfc0cf(1), 1);
        rf = min(sampled_box_r0rfc0cf(2), d(di).image_size(1) );
        c0 = max(sampled_box_r0rfc0cf(3), 1);
        cf = min(sampled_box_r0rfc0cf(4), d(di).image_size(2) );
        r0 = round(r0);
        rf = round(rf);
        c0 = round(c0);
        cf = round(cf);
        sampled_box_r0rfc0cf = [r0 rf c0 cf];
        w = cf-c0+1;
        h = rf-r0+1;
        rc = r0 + h/2;
        cc = c0 + h/2;
    
    agent_pool(agent_index).theta{3} = sampled_box_r0rfc0cf;    % sampled in [r0,rf,c0,cf]
    agent_pool(agent_index).theta{2} = [w,h];                   % the sampled box width/height
    agent_pool(agent_index).theta{1} = [rc,cc];                 % the center point of the box [row,column]
  
    % figure out the internal support

        switch interest
            case 'dog'
                switch p.classification_method
                    case 'HOG-SVM'
                        model_ind = find( strcmp( 'dog', {p.classifier.data.target_label} ) );
                        [~,internal_support] = p.classifier.apply( im(r0:rf,c0:cf,:), p.classifier.data(model_ind) );
                    case 'IOU-oracle'
                        agent_box_xywh      = [ c0 r0 w h ];
                        intersection_scores = intersection_over_union_xywh( agent_box_xywh, im_label.boxes );
                        % limit to 2 sig figs so behavior matches display
                        intersection_scores = round(intersection_scores * 100) / 100;
                        internal_support = intersection_scores(im_label.is_dog);
                        internal_support = internal_support(1);% in case there are several, which there should not be, just use the first
                        orientation = im_label.orientations{im_label.is_dog};
                    otherwise
                        error('unrecognized p.classification_method');
                end
                
            case 'person'
                switch p.classification_method
                    case 'HOG-SVM'
                        model_ind = find( strcmp( 'person', {p.classifier.data.target_label} ) );
                        [~,internal_support] = p.classifier.apply( im(r0:rf,c0:cf,:), p.classifier.data(model_ind) );
                    case 'IOU-oracle'
                        agent_box_xywh      = [ c0 r0 w h ];
                        intersection_scores = intersection_over_union_xywh( agent_box_xywh, im_label.boxes );
                        % limit to 2 sig figs so behavior matches display
                        intersection_scores = round(intersection_scores * 100) / 100;
                        internal_support = intersection_scores(im_label.is_ped);
                        internal_support = internal_support(1);% in case there are several, which there should not be, just use the first
                        orientation = im_label.orientations{im_label.is_ped};
                    otherwise
                        error('unrecognized p.classification_method');
                end
                
            case 'leash'
                switch p.classification_method
                    case 'HOG-SVM'
                        model_ind = find( strcmp( 'leash', {p.classifier.data.target_label} ) );
                        [~,internal_support] = p.classifier.apply( im(r0:rf,c0:cf,:), p.classifier.data(model_ind) );
                    case 'IOU-oracle'
                        agent_box_xywh      = [ c0 r0 w h ];
                        intersection_scores = intersection_over_union_xywh( agent_box_xywh, im_label.boxes );
                        % limit to 2 sig figs so behavior matches display
                        intersection_scores = round(intersection_scores * 100) / 100;
                        internal_support = intersection_scores(im_label.is_leash);
                        internal_support = internal_support(1);% in case there are several, which there should not be, just use the first
                        orientation = im_label.orientations{im_label.is_leash};
                    otherwise
                        error('unrecognized p.classification_method');
                end
                
            otherwise
                error('situate_sketch:interest_label_match_failed','agent has an unrecognized interest');
        end