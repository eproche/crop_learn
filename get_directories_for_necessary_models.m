function model_directories_struct = get_directories_for_necessary_models( p_conditions )

    model_directories_struct = [];

    if any(strcmp([ p_conditions.classification_method ],'CNN-SVM'))
        possible_paths_cnn_svm_models = { ...
            '/Users/Max/Documents/MATLAB/data/situate_saved_models/cnn_svm/', ...
            'saved_models_cnn_svm/', ...
            '+cnn/'};
        existing_model_path_ind = find(cellfun(@(x) exist(x,'dir'),possible_paths_cnn_svm_models), 1, 'first' );
        model_directories_struct.cnn_svm = possible_paths_cnn_svm_models{ existing_model_path_ind };
    end

    if any([ p_conditions.use_box_adjust ])
        possible_paths_box_adjust_models = {...
            '/stash/mm-group/evan/saved_models_box_adjust' ...
            '/Users/Max/Documents/MATLAB/data/situate_saved_models/box_adjust/', ...
            'saved_models_box_adjust/', ...
            '+box_adjust/'};
        existing_model_path_ind = find(cellfun(@(x) exist(x,'dir'),possible_paths_box_adjust_models), 1, 'first' );
        model_directories_struct.box_adjust = possible_paths_box_adjust_models{ existing_model_path_ind };
    end

    if any(strcmp([ p_conditions.classification_method ],'HOG-SVM'))
        possible_paths_hog_svm_models = {...
            '/Users/Max/Documents/MATLAB/data/situate_saved_models/hog_svm/', ...
            'saved_models_hog_svm/', ...
            '+hog_svm/'};
        existing_model_path_ind = find(cellfun(@(x) exist(x,'dir'),possible_paths_cnn_svm_models), 1, 'first' );
        model_directories_struct.hog_svm = possible_paths_cnn_svm_models{ existing_model_path_ind };
    end

end
