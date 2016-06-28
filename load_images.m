function images = load_images( path )
%LOAD_IMAGES Loads all jpeg images in a given directory.
    files = dir([path '*.jpg']);
    images = map(files, @(x) imread([path x.name]));
end
