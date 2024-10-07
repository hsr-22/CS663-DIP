% MATLAB code to compute the Fourier transform
I = zeros(201, 201); % Create a 201x201 black image
I(:, 101) = 255; % Set the central column to 255

% Compute the 2D Fourier transform and shift zero-frequency to center
F = fft2(I);
log_F = log(abs(F) + 1);
% Plot the result
figure;
imagesc(log_F);
colorbar;
title('Logarithm of Fourier Magnitude (fft2)');

F_shifted = fftshift(F);

% Compute the logarithm of the magnitude
log_magnitude = log(abs(F_shifted) + 1);

% Plot the result
figure;
imagesc(log_magnitude);
colorbar;
title('Logarithm of Fourier Magnitude');