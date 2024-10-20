clear; close all;

tic;

train_set = [];
train_index = [];
test_set = [];
test_index = [];

for i = 1:32
    imagefiles = dir("../../ImageDatabase/ORL/s" + num2str(i) + "/*.pgm");

    for j = 1:length(imagefiles)
        file = imagefiles(j).folder + "/" + imagefiles(j).name;
        images = im2double(imread(file));

        if (j <= 6)
            train_set = cat(2, train_set, images(:));
            train_index = cat(2, train_index, i);
        else
            test_set = cat(2, test_set, images(:));
            test_index = cat(2, test_index, i);
        end

    end

end

% specific image to reconstruct, the first image
image = im2double(imread("../../ImageDatabase/ORL/s2/1.pgm"));
m = size(image, 1); n = size(image, 2);

figure(1);
imagesc(image); colormap("gray"); title("Original Face");

%% eigen vectors, eigen coeff, reconstruction

mean_vector = mean(train_set, 2);
X = train_set - mean_vector;
k = [2, 10, 20, 50, 75, 100, 125, 150, 175];

%[U, S, V] = svds(X,k(end));

L = X' * X;
[V, D] = eig(L, 'vector');
[D, ind] = sort(D, 'descend');
V = V(:, ind);
U = X * V;

% Normalizing the eigen vectors
for i = 1:size(U, 2)
    U(:, i) = U(:, i) / norm(U(:, i));
end

% disp('Matrix X:');
% disp(X(:, 1));

% disp('Matrix U:');
% disp(U);

for i = 1:length(k)
    eigen_space = U(:, 1:k(i));
    eigen_coef = (eigen_space') * (X(:, 7)); % specific image to reconstruct
    recon_image = (eigen_space * eigen_coef) + mean_vector;
    recon_image = reshape(recon_image, m, n);
    figure(i+1);
    imagesc(recon_image); colormap("gray"); title("Reconstructed Image (k = " + num2str(k(i)) + ")");
end

%% 25 eigen faces

eigen_space = U(:, 1:25);
figure(length(k)+2);

for i = 1:25
    eigen_face = reshape(eigen_space(:, i), m, n);
    subplot(5, 5, i); imagesc(eigen_face); colormap("gray");
end

toc;
