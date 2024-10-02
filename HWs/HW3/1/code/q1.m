cutoff_frequency = 80;

img = imread('./../images/barbara256.png');

% Casting Image to Double
img_pro = im2double(img);
figure; imshow(img_pro); colormap("gray"); title('Original Image');

% Pad the image to make the dimensions twice as large
img_padded = padarray(img_pro, [size(img_pro, 1) / 2, size(img_pro, 2) / 2]);

% Get Ideal Low pass filtered image
img_filtered_ideal = IdealLowPass(img_padded, cutoff_frequency);
img_filtered_ideal = img_filtered_ideal(size(img, 1) / 2 + 1:size(img, 1) / 2 + size(img, 1), size(img, 2) / 2 + 1:size(img, 2) / 2 + size(img, 2));
figure; imshow(img_filtered_ideal); colormap("gray"); title('Ideal Low Pass Filter Image');
saveas(gcf, './../images/Filtered_Image_80.png');

% Gaussian Low Pass filtered image
img_filtered_gaussian = GaussianLowPass(img_padded, cutoff_frequency);

% Extract the central part of the image
img_filtered_gaussian = img_filtered_gaussian(size(img, 1) / 2 + 1:size(img, 1) / 2 + size(img, 1), size(img, 2) / 2 + 1:size(img, 2) / 2 + size(img, 2));
figure; imshow(img_filtered_gaussian); colormap("gray"); title('Gaussian Low Pass Filter Image');
saveas(gcf, './../images/Gaussian_Filtered_Image_80.png');

function img_filtered = IdealLowPass(img, cutoff_freq)
    %% Compute the Fourier transform of the image along with shift
    F = fftshift(fft2(img));
    log_F = log(abs(F) + 1);
    figure; imshow(log_F, [min(log_F(:)) max(log_F(:))]); colormap("jet"); colorbar; title('Fourier Transform of the Image');
    saveas(gcf, './../images/Fourier_Transform.png');

    % Apply the low pass filter of cutoff frequency
    Filter = zeros(size(F));
    [x, y] = meshgrid(-size(Filter, 1) / 2:size(Filter, 1) / 2 - 1, -size(Filter, 2) / 2:size(Filter, 2) / 2 - 1);
    valid_indices = (x.^2 + y.^2) <= cutoff_freq^2;
    Filter(valid_indices) = 1;
    figure; imshow(log(1 + Filter), [min(log(1 + Filter(:))) max(log(1 + Filter(:)))]); colormap("jet"); colorbar; title('Ideal Low Pass Filter');
    saveas(gcf, './../images/Ideal_Low_Pass_Filter_80.png');

    %% Display the magnitude of the Fourier transform of the filtered image
    F_filtered = F .* Filter;
    log_F_filtered = log(abs(F_filtered) + 1);
    figure; imshow(log_F_filtered, [min(log_F_filtered(:)) max(log_F_filtered(:))]); colormap("jet"); colorbar; title('Fourier Transform of the Filtered Image');
    saveas(gcf, './../images/Fourier_Transform_Filtered_80.png');
    img_filtered = ifft2(ifftshift(F_filtered));
end

function img_filtered = GaussianLowPass(img, sigma)
    %% Compute the Fourier transform of the image along with shift
    F = fftshift(fft2(img));
    log_F = log(abs(F) + 1); 
    figure; imshow(log_F, [min(log_F(:)) max(log_F(:))]); colormap("jet"); colorbar; title('Fourier Transform of the Image');

    % Apply the low pass filter of cutoff frequency
    Filter = zeros(size(F));
    [x, y] = meshgrid(-size(Filter, 1) / 2:size(Filter, 1) / 2 - 1, -size(Filter, 2) / 2:size(Filter, 2) / 2 - 1);
    Filter = exp(-((x.^2 + y.^2) / (2 * sigma^2)));
    figure; imshow(log(1 + Filter), [min(log(1 + Filter(:))) max(log(1 + Filter(:)))]); colormap("jet"); colorbar; title('Gaussian Low Pass Filter');
    saveas(gcf, './../images/Gaussian_Low_Pass_Filter_80.png');

    %% Display the magnitude of the Fourier transform of the filtered image
    F_filtered = F .* Filter;
    log_F_filtered = log(abs(F_filtered) + 1);
    figure; imshow(log_F_filtered, [min(log_F_filtered(:)) max(log_F_filtered(:))]); colormap("jet"); colorbar; title('Fourier Transform of the Filtered Image');
    saveas(gcf, './../images/Gaussian_Fourier_Transform_Filtered_80.png');
    img_filtered = ifft2(ifftshift(F_filtered));
end