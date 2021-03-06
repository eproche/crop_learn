function [guess,class_calls] = predict_crop(svm_modelm,icrop,)
	global net layer;

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


	for i = 1:21
		predictions = predict(svm_model{i},data);
		predictions = str2num(char(predictions));
        vote_count(predictions) = vote_count(predictions) +1;
        vote_mat(1,i) = predictions;
        if max(vote_count) == 6
            guess = find(vote_count == 6);
            class_calls =  i;
            return

    end
    guess = mode(vote_mat,2);
end
