function guess = predict_crop(svm_model,icrop)
	global net layer;
    im_ = single(icrop) ; % note: 0-255 range
    im_ = imresize(im_, net.meta.normalization.imageSize(1:2)) ;
    im_ = bsxfun(@minus, im_, net.meta.normalization.averageImage) ;
    % run the CNN
    res = vl_simplenn(net, im_) ;
    data = res(layer).x(:);
    data = transpose(data);
	vote_mat = zeros(1,21);
	for i = 1:21
		predictions = predict(svm_model{i},data);
		predictions = str2num(char(predictions));
        vote_mat(1,i) = predictions;
    end
    guess = mode(vote_mat,2);
