clear; close all;

function [tp_count, fn_count, tnc_count, fpc_count, tnw_count, fpw_count] = compute_confusion_matrix(eigen_coef, test_coef, fake_coef, train_index, test_index, threshold)
    n_test = size(test_coef, 2);
    n_fake = size(fake_coef, 2);
    
    tp_count = 0;
    fn_count = 0;
    tnc_count = 0;
    fpc_count = 0;
    tnw_count = 0;
    fpw_count = 0;
    
    % Iterate over test set (true negatives and false positives)
    for j = 1:n_test
        [m, idx] = min(sum((eigen_coef - test_coef(:, j)).^2));
        if (m < threshold)
            if (train_index(idx) == test_index(j))
                tnc_count = tnc_count + 1;
            else
                tnw_count = tnw_count + 1;
            end
        else
            if (train_index(idx) == test_index(j))
                fpc_count = fpc_count + 1;
            else
                fpw_count = fpw_count + 1;
            end
        end
    end
    
    % Iterate over fake set (true positives and false negatives)
    for j = 1:n_fake
        [m, ~] = min(sum((eigen_coef - fake_coef(:, j)).^2));
        if (m < threshold)
            fn_count = fn_count + 1;
        else
            tp_count = tp_count + 1;
        end
    end
end

tic;

train_set = [];
train_index = [];
test_set = [];
test_index = [];

for i = 1:32
    image = dir("../../ImageDatabase/ORL/s" + num2str(i) + "/*.pgm");

    for j = 1:length(image)
        file = image(j).folder + "/" + image(j).name;
        img = im2double(imread(file));

        if (j <= 6)
            train_set = cat(2, train_set, img(:));
            train_index = cat(2, train_index, i);
        else
            test_set = cat(2, test_set, img(:));
            test_index = cat(2, test_index, i);
        end

    end

end

fake_set = [];

for i = 33:40
    image = dir("../../ImageDatabase/ORL/s" + num2str(i) + "/*.pgm");
    for j = 7:length(image)
        file = image(j).folder + "/" + image(j).name;
        img = im2double(imread(file));
        fake_set = cat(2, fake_set, img(:));
    end
end

n_train = size(train_set, 2);
n_test = size(test_set, 2);
n_fake = size(fake_set, 2);
mean_vector = mean(train_set, 2);

X = train_set - mean_vector;
Y = test_set - mean_vector;
Z = fake_set - mean_vector;
k = 50; % Number of eigenfaces to use

%% Get eigen space and eigen coefficients using SVD
[U, S, V] = svds(X, k);

% Normalizing the eigen vectors
for i = 1:size(U, 2)
    U(:, i) = U(:, i) / norm(U(:, i));
end

eigen_space = U(:, 1:k);
eigen_coef = (eigen_space') * X; 
test_coef = (eigen_space') * Y; % Test set coefficients
fake_coef = (eigen_space') * Z; % Fake set coefficients

% Variables to store best F1 score and corresponding threshold
best_f1 = 0;
best_accuracy = 0;
best_recall = 0;
best_threshold = 0;

% Range of threshold values to try
threshold_range = 50:1:200;

% Loop over different threshold values
for threshold = threshold_range
    % Get the confusion matrix counts using the function
    [tp_count, fn_count, tnc_count, fpc_count, tnw_count, fpw_count] = compute_confusion_matrix(eigen_coef, test_coef, fake_coef, train_index, test_index, threshold);

    % Calculate the confusion matrix counts
    tn_count = tnc_count + tnw_count;
    % tn_count = tnc_count;
    fp_count = fpc_count + fpw_count;
    % fp_count = fpc_count;

    % Calculate the performance metrics
    specificity = tn_count / (tn_count + fp_count);
    accuracy = (tp_count + tn_count) / (tp_count + tn_count + fp_count + fn_count);
    recall = tp_count / (tp_count + fn_count);
    f1_score = tp_count / (tp_count + 0.5 * (fp_count + fn_count));
    
    fprintf("Threshold: %d, F1 Score: %f\n", threshold, f1_score);
    % fprintf("Threshold: %d, Accuracy: %f\n", threshold, accuracy);
    % fprintf("Threshold: %d, Recall: %f\n", threshold, recall);

    % Update the best threshold if current F1 score is better
    if f1_score > best_f1 %accuracy > best_accuracy %recall > best_recall
        best_f1 = f1_score;
        best_threshold = threshold;
        best_specificity = specificity;
        best_accuracy = accuracy;
        best_recall = recall;
        best_tp_count = tp_count;
        best_tn_count = tn_count;
        best_fp_count = fp_count;
        best_fn_count = fn_count;
    end
end

% Output the best threshold and F1 score
fprintf("Best Threshold: %d, Best F1 Score: %f\n", best_threshold, best_f1);
% fprintf("Best Threshold: %d, Best Accuracy: %f\n", best_threshold, best_accuracy);
% fprintf("Best Threshold: %d, Best Recall: %f\n", best_threshold, best_recall);
fprintf("Best Specificity: %f\n", best_specificity);
% fprintf("Best F1 Score: %f\n", best_f1);
fprintf("Best Accuracy: %f\n", best_accuracy);
fprintf("Best Recall: %f\n", best_recall);
fprintf("Best Confusion matrix:\n");
fprintf("TP: %d\tFP: %d\n", best_tp_count, best_fp_count);
fprintf("FN: %d\tTN: %d\n", best_fn_count, best_tn_count);

toc;