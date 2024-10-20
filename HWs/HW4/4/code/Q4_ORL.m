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

n_train = size(train_set, 2);
n_test = size(test_set, 2);
mean_vector = mean(train_set, 2);

X = train_set - mean_vector;
Y = test_set - mean_vector;
k = [1, 2, 3, 5, 10, 15, 20, 30, 50, 75, 100, 150, 170];

%% Get eigen space and eigen coefficients
%% using svd
[U, S, V] = svds(X,k(end));

%% using eig
% L = X' * X;
% [V, D] = eig(L, 'vector');
% [D, ind] = sort(D, 'descend');
% V = V(:, ind);
% U = X * V;

% Normalizing the eigen vectors
for i = 1:size(U, 2)
    U(:, i) = U(:, i) / norm(U(:, i));
end

%--------------------------------------------------------------

recog_rate = zeros(size(k));

for i = 1:length(k)
    eigen_space = U(:, 1:k(i));
    eigen_coef = (eigen_space') * X; 
    test_coef = (eigen_space') * Y; % test set coefficients
    recog_count = 0;

    for j = 1:n_test
        [m, index] = min(sum((eigen_coef - test_coef(:, j)).^2));

        if train_index(index) == test_index(j)
            recog_count = recog_count + 1;
        end

    end

    recog_rate(i) = recog_count / n_test;
end

% Plotting the recognition rate
figure;
plot(k, recog_rate, 'o-', 'LineWidth', 2, 'MarkerSize', 8, 'MarkerFaceColor', 'blue');
grid on;
title('Recognition Rate (ORL)', 'FontSize', 18, 'FontWeight', 'bold');
xlabel('Number of Eigenfaces (k)', 'FontSize', 15, 'FontWeight', 'bold');
ylabel('Recognition Rate', 'FontSize', 15, 'FontWeight', 'bold');
set(gca, 'FontSize', 12, 'FontWeight', 'bold');

toc;
