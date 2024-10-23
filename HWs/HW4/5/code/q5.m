clear; close all;
tic;

train_set = [];
train_sub = [];
test_set = [];
test_sub = [];


for i = 1:32
    imagefiles = dir("./ORL/s" + num2str(i) + "/*.pgm");

    for ii = 1:length(imagefiles)
        currentfilename = imagefiles(ii).folder + "/" + imagefiles(ii).name;
        currentimage = im2double(imread(currentfilename));

        if (ii <= 6)
            train_set = cat(2, train_set, currentimage(:));
            train_sub = cat(2, train_sub, i);

        else
            test_set = cat(2, test_set, currentimage(:));
            test_sub = cat(2, test_sub, i);
        end
    end
end


for i = 33:40
    imagefiles = dir("./ORL/s" + num2str(i) + "/*.pgm");

    for ii = 7:length(imagefiles)
        currentfilename = imagefiles(ii).folder + "/" + imagefiles(ii).name;
        currentimage = im2double(imread(currentfilename));

        test_set = cat(2, test_set, currentimage(:));
        test_sub = cat(2, test_sub, -1);
    end
end


n_train = size(train_set, 2);
n_test = size(test_set, 2);
mean_vector = mean(train_set, 2);

X = train_set - mean_vector;
Y = test_set - mean_vector;


[U, S, V] = svd(X);

k = 75;
threshold_values = linspace(70, 300, 100);
best_score = 0;
best_threshold = 0;
true_positives = 0;
false_positives = 0;
true_negatives = 0;
false_negatives = 0;
recognition_rate = 0;

for threshold_index = 1:length(threshold_values)
    threshold = threshold_values(threshold_index);
    % threshold = 100;
    true_negative_count = 0;
    false_negative_count = 0;

    true_positive_count = 0;
    false_positive_count = 0;

    eigen_space = U(:, 1:k);
    eigen_coef = (eigen_space') * X;
    test_coef = (eigen_space') * Y;
    recognition_count = 0;

    for j = 1:n_test
        error = sum((eigen_coef - test_coef(:, j)).^2);
        [m, index] = min(error);

        if (m > threshold)
            % This means there are no matching eigen faces
            if (test_sub(j) == -1)
                true_negative_count = true_negative_count + 1;
            else
                false_negative_count = false_negative_count + 1;
            end

        else
            % This means there are matching eigen faces
            if (test_sub(j) == -1)
                false_positive_count = false_positive_count + 1;
            else
                true_positive_count = true_positive_count + 1;

                if train_sub(index) == test_sub(j)
                    recognition_count = recognition_count + 1;
                end
            end
        end
    end

    specificity = true_negative_count / (true_negative_count + false_positive_count);
    accuracy = (true_positive_count + true_negative_count) / n_test;
    f1_score = true_positive_count / (true_positive_count + 0.5 * (false_positive_count + false_negative_count));
    recall = true_positive_count / (true_positive_count + false_negative_count);
    score = false_positive_count + false_negative_count;



    if (recall > best_score)
        best_score = recall;
        accuracy_ = accuracy;
        f1_score_ = f1_score;
        specificity_ = specificity;
        recall_ = recall;
        best_threshold = threshold;
        false_positives = false_positive_count;
        false_negatives = false_negative_count;
        true_positives = true_positive_count;
        true_negatives = true_negative_count;
        recognition_rate = recognition_count / n_test;
    end
end


fprintf("Accuracy: %f\n", accuracy_);
fprintf("F1 Score: %f\n", f1_score_);
fprintf("Recall: %f\n", recall_);
fprintf("Best Threshold: %f\n", best_threshold);
fprintf("Confusion matrix:\n");
fprintf("TP: %d\tFP: %d\n", true_positives, false_positives);
fprintf("FN: %d\tTN: %d\n", false_negatives, true_negatives);
fprintf("Recognition rate: %f\n", recognition_rate);
toc;
