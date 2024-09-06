clear; 
clc;

% Images
imb = im2double(imread('.\..\images\barbara256.png'));
imk = im2double(imread('.\..\images\kodak24.png'));

% Drawing Original Images
figure(1); imagesc(imb); colormap("gray"); title("Original barbara256"); saveas(gcf, 'barbara256_orig.png');
figure(2); imagesc(imk); colormap("gray"); title("Original kodak24"); saveas(gcf, 'kodak24_orig.png');

% Zero-mean Gaussian noise
sig_1 = 5;
imb_n_1 = imb + sig_1/255*randn(size(imb)); 
imk_n_1 = imk + sig_1/255*randn(size(imk));


% Drawing Images with adding Guassian Noise
figure(3); imagesc(imb_n_1); colormap("gray"); title("Noisy barbara256 with \sigma_n = " + num2str(sig_1)); saveas(gcf, 'barbara256_noise5.png');
figure(4); imagesc(imk_n_1); colormap("gray"); title("Noisy kodak24 with \sigma_n = " + num2str(sig_1)); saveas(gcf, 'kodak24_noise5.png');

% Define the parameter configurations
configurations = [
    struct('sig_s', 2, 'sig_r', 2);
    struct('sig_s', 0.1, 'sig_r', 0.1);
    struct('sig_s', 3, 'sig_r', 15);
];

count = 5;

% Apply the bilateral filter to both images for each configuration
for i = 1:length(configurations)
    config = configurations(i);
    
    bil_fil_bar = mybilateralfilter(imb_n_1,config.sig_s, config.sig_r);
    bil_fil_kod = mybilateralfilter(imk_n_1,config.sig_s, config.sig_r);

    filename = ['barbara256_', num2str(sig_1), '_', num2str(config.sig_s), '_', num2str(config.sig_r), '_', num2str(count), '.png'];
    figure(count); imagesc(bil_fil_bar); colormap("gray"); 
    title("Filtered barbara256 with \sigma_n = " + num2str(sig_1) + ", \sigma_s = " + num2str(config.sig_s) + ", \sigma_r = " + num2str(config.sig_r));
    saveas(gcf, filename);

    filename = ['kodak24_', num2str(sig_1), '_', num2str(config.sig_s), '_', num2str(config.sig_r), '_', num2str(count+1), '.png'];
    figure(count+1); imagesc(bil_fil_kod); colormap("gray");
    title("Filtered kodak24 with \sigma_n = " + num2str(sig_1) + ", \sigma_s = " + num2str(config.sig_s) + ", \sigma_r = " + num2str(config.sig_r));
    saveas(gcf, filename);
    count= count+2;


end


% Adding zero-mean Gaussian noise
sig_1 = 10;
imb_n_1 = imb + sig_1/255*randn(size(imb));
imk_n_1 = imk + sig_1/255*randn(size(imk));

figure(count); imagesc(imb_n_1); colormap("gray"); title("noisy barbara256 with \sigma_n = " + num2str(sig_1));  saveas(gcf, 'barbara256_noise10.png');
figure(count+1); imagesc(imk_n_1); colormap("gray"); title("noisy kodak24 with \sigma_n = " + num2str(sig_1));   saveas(gcf, 'kodak24_noise10.png');

count = count + 2;

% Apply the bilateral filter to both images for each configuration
for i = 1:length(configurations)
    config = configurations(i);
    
    bil_fil_bar = mybilateralfilter(imb_n_1,config.sig_s, config.sig_r);
    bil_fil_kod = mybilateralfilter(imk_n_1,config.sig_s, config.sig_r);

    filename = ['barbara256_', num2str(sig_1), '_', num2str(config.sig_s), '_', num2str(config.sig_r), '_', num2str(count), '.png'];
    figure(count); imagesc(bil_fil_bar); colormap("gray"); 
    title("Filtered barbara256 with \sigma_n = " + num2str(sig_1) + ", \sigma_s = " + num2str(config.sig_s) + ", \sigma_r = " + num2str(config.sig_r));
    saveas(gcf, filename);

    filename = ['kodak24_', num2str(sig_1), '_', num2str(config.sig_s), '_', num2str(config.sig_r), '_', num2str(count+1), '.png'];
    figure(count+1); imagesc(bil_fil_kod); colormap("gray");
    title("Filtered kodak24 with \sigma_n = " + num2str(sig_1) + ", \sigma_s = " + num2str(config.sig_s) + ", \sigma_r = " + num2str(config.sig_r));
    saveas(gcf, filename);
    count= count+2;


end
