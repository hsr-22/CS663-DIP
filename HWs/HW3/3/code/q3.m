% % Set the path for images
% image_path = fullfile('..', 'images');

% % Load the images
% barbara = imread(fullfile(image_path, 'barbara256.png'));
% kodak = imread(fullfile(image_path, 'kodak24.png'));

% % Gaussian noise with σ = 5 
% sigma_noise = 5;
% noisy_barbara = imnoise(barbara, 'gaussian', 0, (sigma_noise/255)^2);
% imshow(noisy_barbara);
% imwrite(noisy_barbara, 'Noisy Barbara_sigma 5.png');

% noisy_kodak = imnoise(kodak, 'gaussian', 0, (sigma_noise/255)^2);
% imshow(noisy_kodak);
% imwrite(noisy_kodak, 'Noisy kodak_sigma 5.png');

% % Define parameter configurations
% configurations = [
%     struct('sigma_s', 2, 'sigma_r', 2);
%     struct('sigma_s', 15, 'sigma_r', 3);
%     struct('sigma_s', 3, 'sigma_r', 15)
% ];

% % Apply mean shift filter for each configuration
% filtered_images_barbara = cell(length(configurations), 1);
% filtered_images_kodak = cell(length(configurations), 1);

% for i = 1:length(configurations)
%     sigma_s = configurations(i).sigma_s;
%     sigma_r = configurations(i).sigma_r;
    
%     % Apply mean shift filter
%     filtered_images_barbara{i} = myMeanShift(noisy_barbara, sigma_s, sigma_r, 31);
%     filtered_images_kodak{i} = myMeanShift(noisy_kodak, sigma_s, sigma_r, 31);
% end

% imshow(filtered_images_barbara{1});
% title(['Filtered Barbara - \sigma_s = ', num2str(configurations(1).sigma_s), ', \sigma_r = ', num2str(configurations(1).sigma_r)]);
% imwrite(filtered_images_barbara{1},"barbara_sigma_5_sigmas_sigmar_2.png");

% imshow(filtered_images_barbara{2});
% title(['Filtered Barbara - \sigma_s = ', num2str(configurations(2).sigma_s), ', \sigma_r = ', num2str(configurations(2).sigma_r)]);
% imwrite(filtered_images_barbara{2},"barbara_sigma_5_sigmas_sigmar_0.1.png");

% imshow(filtered_images_barbara{3});
% title(['Filtered Barbara - \sigma_s = ', num2str(configurations(3).sigma_s), ', \sigma_r = ', num2str(configurations(3).sigma_r)]);
% imwrite(filtered_images_barbara{3},"barbara_sigma_5_sigmas_3_sigmar_15.png");
 
% imshow(filtered_images_kodak{1});
% title(['Filtered kodak - \sigma_s = ', num2str(configurations(1).sigma_s), ', \sigma_r = ', num2str(configurations(1).sigma_r)]);
% imwrite(filtered_images_kodak{1},"kodak_sigma_5_sigmas_sigmar_2.png");

% imshow(filtered_images_kodak{2});
% title(['Filtered kodak - \sigma_s = ', num2str(configurations(2).sigma_s), ', \sigma_r = ', num2str(configurations(2).sigma_r)]);
% imwrite(filtered_images_kodak{2},"kodak_sigma_5_sigmas_sigmar_0.1.png");

% imshow(filtered_images_kodak{3});
% title(['Filtered kodak - \sigma_s = ', num2str(configurations(3).sigma_s), ', \sigma_r = ', num2str(configurations(3).sigma_r)]);
% imwrite(filtered_images_kodak{3},"kodak_sigma_5_sigmas_3_sigmar_15.png");

% % Gaussian noise with σ = 10
% sigma_noise = 10;
% noisy_barbara = imnoise(barbara, 'gaussian', 0, (sigma_noise/255)^2);
% imshow(noisy_barbara);
% imwrite(noisy_barbara, 'Noisy Barbara_sigma 10.png');

% noisy_kodak = imnoise(kodak, 'gaussian', 0, (sigma_noise/255)^2);
% imshow(noisy_kodak);
% imwrite(noisy_kodak, 'Noisy kodak_sigma 10.png');

% % Define parameter configurations
% configurations = [
%     struct('sigma_s', 2, 'sigma_r', 2);
%     struct('sigma_s', 15, 'sigma_r', 3);
%     struct('sigma_s', 3, 'sigma_r', 15)
% ];

% % Apply mean shift filter for each configuration
% filtered_images_barbara = cell(length(configurations), 1);
% filtered_images_kodak = cell(length(configurations), 1);

% for i = 1:length(configurations)
%     sigma_s = configurations(i).sigma_s;
%     sigma_r = configurations(i).sigma_r;
    
%     % Apply mean shift filter
%     filtered_images_barbara{i} = myMeanShift(noisy_barbara, sigma_s, sigma_r, 31);
%     filtered_images_kodak{i} = myMeanShift(noisy_kodak, sigma_s, sigma_r, 31);
% end

% imshow(filtered_images_barbara{1});
% title(['Filtered Barbara - \sigma_s = ', num2str(configurations(1).sigma_s), ', \sigma_r = ', num2str(configurations(1).sigma_r)]);
% imwrite(filtered_images_barbara{1},"barbara_sigma_10_sigmas_sigmar_2.png");

% imshow(filtered_images_barbara{2});
% title(['Filtered Barbara - \sigma_s = ', num2str(configurations(2).sigma_s), ', \sigma_r = ', num2str(configurations(2).sigma_r)]);
% imwrite(filtered_images_barbara{2},"barbara_sigma_10_sigmas_sigmar_0.1.png");

% imshow(filtered_images_barbara{3});
% title(['Filtered Barbara - \sigma_s = ', num2str(configurations(3).sigma_s), ', \sigma_r = ', num2str(configurations(3).sigma_r)]);
% imwrite(filtered_images_barbara{3},"barbara_sigma_10_sigmas_3_sigmar_15.png");
 
% imshow(filtered_images_kodak{1});
% title(['Filtered kodak - \sigma_s = ', num2str(configurations(1).sigma_s), ', \sigma_r = ', num2str(configurations(1).sigma_r)]);
% imwrite(filtered_images_kodak{1},"kodak_sigma_10_sigmas_sigmar_2.png");

% imshow(filtered_images_kodak{2});
% title(['Filtered kodak - \sigma_s = ', num2str(configurations(2).sigma_s), ', \sigma_r = ', num2str(configurations(2).sigma_r)]);
% imwrite(filtered_images_kodak{2},"kodak_sigma_10_sigmas_sigmar_0.1.png");

% imshow(filtered_images_kodak{3});
% title(['Filtered kodak - \sigma_s = ', num2str(configurations(3).sigma_s), ', \sigma_r = ', num2str(configurations(3).sigma_r)]);
% imwrite(filtered_images_kodak{3},"kodak_sigma_10_sigmas_3_sigmar_15.png");

rng(10);
kodak = double(imread('../images/kodak24.png'));
size(kodak);
barbara = double(imread('../images/barbara256.png'));
noise1 = random('normal',0,5,size(kodak));
noise2 = random('normal', 0, 5, size(barbara));
noise3 = random('normal',0,10,size(kodak));
noise4 = random('normal', 0, 10, size(barbara));

kodak1 = kodak+noise1;
barbara1 = barbara + noise2;
kodak2 = kodak+noise3;
barbara2 = barbara + noise4;

a = [2,2;15,3;3,15];
imwrite(kodak1/255, "../images/kodak_5.png");
imwrite(kodak2/255, "../images/kodak_10.png");
imwrite(barbara1/255, "../images/barbara_5.png");
imwrite(barbara2/255, "../images/barbara_10.png");

for i=1:3
    k1 = myMeanShift(kodak1, a(i,1), a(i,2), 15, 5, 45, 100);
    imshow(k1/255);
    imwrite(k1/255, "../images/kodak_5_"+i+".png");
end
for i=1:3
    k1 = myMeanShift(kodak2, a(i,1), a(i,2), 15, 5, 45, 100);
    imshow(k1/255);
    imwrite(k1/255, "../images/kodak_10_"+i+".png");
end
for i=1:3
    b1 = myMeanShift(barbara1, a(i,1), a(i,2), 15, 5, 45, 100);
    imshow(b1/255);
    imwrite(b1/255, "../images/barbara_5_"+i+".png");
end
for i=1:3
    b1 = myMeanShift(barbara2, a(i,1), a(i,2), 15, 5, 45, 100);
    imshow(b1/255);
    imwrite(b1/255, "../images/barbara_10_"+i+".png");
end