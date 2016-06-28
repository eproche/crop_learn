function data = to_hog_data( images )
%LOAD_HOG_DATA Converts a list of images to a matrix of hog data.
    resized_images = map(images, @(x) imresize(x, [120 120]));
    hogs = map(resized_images, @(x) extractHOGFeatures(x));
    data = cell2mat(hogs);
end
