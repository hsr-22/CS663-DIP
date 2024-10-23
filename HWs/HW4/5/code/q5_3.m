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
    for j = 1:length(image)
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

% Initialize cell arrays to store the errors for boxplots
failed_recog_errors = cell(size(k));
success_recog_errors = cell(size(k));
fake_recog_errors = cell(size(k));

for i = 1:length(k)
    eigen_space = U(:, 1:k(i));
    eigen_coef = (eigen_space') * X; 
    test_coef = (eigen_space') * Y; % test set coefficients
    recog_count = 0;
    failed_recog_error = zeros(1, n_test);  % Array to capture individual errors
    success_recog_error = zeros(1, n_test);
    fake_recog_error = zeros(1, n_fake);

    % Iterate over test set
    for j = 1:n_test
        [m, index] = min(sum((eigen_coef - test_coef(:, j)).^2));
        
        if train_index(index) == test_index(j)
            recog_count = recog_count + 1;
            success_recog_error(recog_count) = m;  % Store the error
        else
            failed_recog_error(j - recog_count) = m;  % Store the error
        end
    end
    
    % Iterate over fake set
    for j = 1:n_fake
        fake_img = fake_set(:, j) - mean_vector;
        fake_coef = (eigen_space') * fake_img;
        [m, index] = min(sum((eigen_coef - fake_coef).^2));
        fake_recog_error(j) = m;
    end

    % Store recog rate
    recog_rate(i) = recog_count / n_test;
    
    % Store all error values for box plots
    failed_recog_errors{i} = failed_recog_error(1:(n_test - recog_count));
    success_recog_errors{i} = success_recog_error(1:recog_count);
    fake_recog_errors{i} = fake_recog_error;
end

% Exclude the first point from recog_rate if needed to match sizes
if length(recog_rate) ~= length(failed_recog_errors)
    recog_rate = recog_rate(2:end);  % Remove the first point from recog_rate
    k_recog = k(2:end);              % Adjust corresponding k values
else
    k_recog = k;
end

% Create a new figure for the combined plot
figure;

% Plotting the recognition rate on the left y-axis
yyaxis left;
plot(k_recog, recog_rate, 'o-', 'LineWidth', 2, 'MarkerSize', 8, 'MarkerFaceColor', 'blue');
ylabel('Recognition Rate', 'FontSize', 15, 'FontWeight', 'bold');
ylim([0 1]);  % Since recog_rate is between 0 and 1
set(gca, 'FontSize', 12, 'FontWeight', 'bold');
grid on;

% Title and x-axis label
title('Recognition Rate and Error Distribution (ORL)', 'FontSize', 18, 'FontWeight', 'bold');
xlabel('Number of Eigenfaces (k)', 'FontSize', 15, 'FontWeight', 'bold');

% Second y-axis for the boxplots of errors
yyaxis right;
hold on;

% Plot boxplots for failed recognition errors
for i = 1:length(k)
    if ~isempty(failed_recog_errors{i})  % Ensure there are values to plot
        boxplot(failed_recog_errors{i}, 'Positions', k(i), 'Widths', 0.1, 'PlotStyle', 'compact');
        % set(h, 'red');  % Change color of the box plot lines
    end
end

% Plot boxplots for successful recognition errors
for i = 1:length(k)
    if ~isempty(success_recog_errors{i})  % Ensure there are values to plot
        boxplot(success_recog_errors{i}, 'Positions', k(i), 'Widths', 0.1, 'PlotStyle', 'compact');
        % set(h, 'green');  % Change color of the box plot lines
    end
end

% Plot boxplots for fake recognition errors
for i = 1:length(k)
    if ~isempty(fake_recog_errors{i})  % Ensure there are values to plot
        boxplot(fake_recog_errors{i}, 'Positions', k(i), 'Widths', 0.1, 'PlotStyle', 'compact');
        % set(h, 'magenta');  % Change color of the box plot lines
    end
end

ylabel('Recognition Errors', 'FontSize', 15, 'FontWeight', 'bold');

% Additional formatting
ylim([0 250]);  % Adjust this based on the range of your error values
legend({'Recognition Rate', 'Failed Recognition Error', 'Successful Recognition Error', 'Fake Recognition Error'}, 'Location', 'best');

set(gca, 'FontSize', 12, 'FontWeight', 'bold');
hold off;

toc;