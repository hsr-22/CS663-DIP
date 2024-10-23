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



% Normalizing the eigen vectors
for i = 1:size(U, 2)
    U(:, i) = U(:, i) / norm(U(:, i));
end

%--------------------------------------------------------------

recog_rate = zeros(size(k));
failed_recog_hist = zeros(size(k));
success_recog_hist = zeros(size(k));

for i = 1:length(k)
    eigen_space = U(:, 1:k(i));
    eigen_coef = (eigen_space') * X; 
    test_coef = (eigen_space') * Y; % test set coefficients
    recog_count = 0;
    failed_recog_error = 0;
    success_recog_error = 0;

    for j = 1:n_test
        [m, index] = min(sum((eigen_coef - test_coef(:, j)).^2));

        if train_index(index) == test_index(j)
            recog_count = recog_count + 1;
            success_recog_error = success_recog_error + m;
        else
            failed_recog_error = failed_recog_error + m;
        end

    end

    recog_rate(i) = recog_count / n_test;
    failed_recog_hist(i) = failed_recog_error / (n_test-recog_count);
    success_recog_hist(i) = success_recog_error / recog_count;
end

% Plotting the recognition rate
figure;
plot(k, recog_rate, 'o-', 'LineWidth', 2, 'MarkerSize', 8, 'MarkerFaceColor', 'blue');
grid on;
title('Recognition Rate (ORL)', 'FontSize', 18, 'FontWeight', 'bold');
xlabel('Number of Eigenfaces (k)', 'FontSize', 15, 'FontWeight', 'bold');
ylabel('Recognition Rate', 'FontSize', 15, 'FontWeight', 'bold');
set(gca, 'FontSize', 12, 'FontWeight', 'bold');

% Plotting the failed recognition error
figure;
plot(k(2:end), failed_recog_hist(2:end), 'o-', 'LineWidth', 2, 'MarkerSize', 8, 'MarkerFaceColor', 'red');
grid on;

title('Failed Recognition Error (ORL)', 'FontSize', 18, 'FontWeight', 'bold');
xlabel('Number of Eigenfaces (k)', 'FontSize', 15, 'FontWeight', 'bold');
ylabel('Failed Recognition Error', 'FontSize', 15, 'FontWeight', 'bold');
set(gca, 'FontSize', 12, 'FontWeight', 'bold');

% Plotting the successful recognition error
figure;
plot(k(2:end), success_recog_hist(2:end), 'o-', 'LineWidth', 2, 'MarkerSize', 8, 'MarkerFaceColor', 'green');
grid on;

title('Successful Recognition Error (ORL)', 'FontSize', 18, 'FontWeight', 'bold');
xlabel('Number of Eigenfaces (k)', 'FontSize', 15, 'FontWeight', 'bold');
ylabel('Successful Recognition Error', 'FontSize', 15, 'FontWeight', 'bold');
set(gca, 'FontSize', 12, 'FontWeight', 'bold');

% Exclude the first point from recog_rate if needed to match sizes
if length(recog_rate) ~= length(failed_recog_hist)
    recog_rate = recog_rate(2:end);  % Remove the first point from recog_rate
    k_recog = k(2:end);              % Adjust corresponding k values
else
    k_recog = k;
end

% Create a new figure for the combined plot
figure;

% First y-axis for recognition rate
yyaxis left;
plot(k_recog, recog_rate, 'o-', 'LineWidth', 2, 'MarkerSize', 8, 'MarkerFaceColor', 'blue');
ylabel('Recognition Rate', 'FontSize', 15, 'FontWeight', 'bold');
ylim([0 1]);  % Since recog_rate is between 0 and 1
set(gca, 'FontSize', 12, 'FontWeight', 'bold');
grid on;

% Title and x-axis label
title('Recognition and Error Rates (ORL)', 'FontSize', 18, 'FontWeight', 'bold');
xlabel('Number of Eigenfaces (k)', 'FontSize', 15, 'FontWeight', 'bold');

% Second y-axis for failed and successful recognition errors
yyaxis right;
plot(k(2:end), failed_recog_hist(2:end), 'o-', 'LineWidth', 2, 'MarkerSize', 8, 'MarkerFaceColor', 'red');
hold on;
plot(k(2:end), success_recog_hist(2:end), 'o-', 'LineWidth', 2, 'MarkerSize', 8, 'MarkerFaceColor', 'green');
ylabel('Recognition Errors', 'FontSize', 15, 'FontWeight', 'bold');

% Additional formatting
ylim([0 200]);  % Assuming the error rates are in the range of 0 to 100
legend({'Recognition Rate', 'Failed Recognition Error', 'Successful Recognition Error'}, 'Location', 'best');

set(gca, 'FontSize', 12, 'FontWeight', 'bold');
hold off;

toc;