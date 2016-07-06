function guess = predict_crop(icrop,net)
	global cnn_svm_model cnn_net cnn_layer;
    net = cnn_net;
    layer = cnn_layer;
    svm_model = cnn_svm_model;

    im_ = single(icrop) ; % note: 0-255 range
    dim_im = size(im_);
    if (dim_im(1) + dim_im(2)) ~= 0
        im_ = imresize(im_, net.meta.normalization.imageSize(1:2)) ;
    else
        warning('Crop out of bounds');
        guess = 0;
        return
    end
    im_ = bsxfun(@minus, im_, net.meta.normalization.averageImage) ;
    % run the CNN
    res = vl_simplenn(net, im_);
    data = res(layer).x(:);
    data = transpose(data);
	vote_mat = zeros(1,21);
    vote_count = [0 0 0 0 0 0 0];
    % classlist = [1 2 3 4 5 6 7];
    % vote_pairs = nchoosek(classlist,2);
    % good_list = [];
    % try_maybe = 0;
    % trys = 0;

	for i = 1:21

		predictions = predict(svm_model{i},data);
		predictions = str2num(char(predictions));
        % vote_count(predictions) = vote_count(predictions) +1;
        vote_mat(1,i) = predictions;
    end
    guess = mode(vote_mat,2);
end

        % if trys > 0
        %     if trys == 4
        %         trys = 0;
        %         try_maybe = 0;
        %         continue
        %     elseif ismember(i,good_list) == 0
        %         continue
        %     end
        % end

                % if max(vote_count) == 6
        %     guess = find(vote_count == 6);
        %     return
        % elseif try_maybe == 0
        %     if max(vote_count) == 4;
        %         maybe = find(vote_count == 4)
        %         [row,col] = find(vote_pairs == maybe);
        %         row(row<=i) = 0;
        %         good_list = nonzeros(row)
        %         try_maybe = 1;
        %         trys = 1
        %     end
        % else
        %     trys = trys + 1  