clear; close all;

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
k = 50
threshold = 125

%% Get eigen space and eigen coefficients
%% using svd
[U, S, V] = svds(X,k(end));



% Normalizing the eigen vectors
for i = 1:size(U, 2)
    U(:, i) = U(:, i) / norm(U(:, i));
end

%--------------------------------------------------------------


eigen_space = U(:, 1:k);
eigen_coef = (eigen_space') * X; 
test_coef = (eigen_space') * Y; % test set coefficients
fake_coef = (eigen_space') * Z; % fake set coefficients

tn_count = 0;
fn_count = 0;

tp_count = 0;
fp_count = 0;
% Iterate over test set
for j = 1:n_test
    [m, index] = min(sum((eigen_coef - test_coef(:, j)).^2));

    if (m < threshold)
        tn_count = tn_count + 1;
    else
        fp_count = fp_count + 1;
    end
end

% Iterate over fake set
for j = 1:n_fake
    [m, index] = min(sum((eigen_coef - fake_coef(:, j)).^2));
    if (m < threshold)
        fn_count = fn_count + 1;
    else
        tp_count = tp_count + 1;
    end
end

specificity = tn_count / (tn_count + fp_count);
accuracy = (tp_count + tn_count) / n_test;
f1_score = tp_count / (tp_count + 0.5 * (fp_count + fn_count));
recall = tp_count / (tp_count + fn_count);
score = fp_count + fn_count;

fprintf("Accuracy: %f\n", accuracy);
fprintf("F1 Score: %f\n", f1_score);
fprintf("Recall: %f\n", recall);
fprintf("Confusion matrix:\n");
fprintf("TP: %d\tFP: %d\n", tp_count, fp_count);
fprintf("FN: %d\tTN: %d\n", fn_count, tn_count);

toc;