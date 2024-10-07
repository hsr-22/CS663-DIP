function im2 = myMeanShift(im1, ss, sr, kernel_size, dist_weight, intens_weight, thresh)
% Get the size of the input image
a = size(im1);

count = 0;

% Initialize the output image with zeros
im2 = zeros(a);

% Pad the input image to handle border pixels
im1_pad = padarray(im1, [floor(kernel_size/2), floor(kernel_size/2)], 0, 'both');

% Create a mesh grid for spatial distances
mesh = zeros(1, kernel_size);
for i = 1:size(mesh, 2)
    mesh(1, i) = abs(i - floor(kernel_size/2));
end
[X, Y] = meshgrid(mesh, mesh);
sp = X.^2 + Y.^2;

% Compute the spatial Gaussian kernel
Gss = (1/(ss*sqrt(2*pi))) * exp(-0.5 * sp / ss^2);

% Create a mesh grid for intensity distances
mesh1 = zeros(1, kernel_size);
for i = 1:size(mesh, 2)
    mesh1(1, i) = i - ceil(kernel_size/2);
end
[X1, Y1] = meshgrid(mesh1);

% Iterate over each pixel in the padded image
for i = floor(kernel_size/2) + 1 : a(1) + floor(kernel_size/2)
    for j = floor(kernel_size/2) + 1 : a(2) + floor(kernel_size/2)
        % Initialize the current pixel location and intensity
        x2 = i;
        y2 = j;
        I2 = im1_pad(x2, y2);
        x1 = x2 + 2;
        y1 = y2 + 2;
        I1 = I2 + 5;

        % Mean Shift iteration until convergence
        while ~(abs(x2 - x1) <= 1 && abs(y2 - y1) <= 1 && abs(I1 - I2) <= 3)
            count = count+1;
            x1 = x2;
            y1 = y2;
            I1 = I2;

            % Extract the local region around the current pixel
            intensity = im1_pad(x1 - floor(kernel_size/2) : x1 + floor(kernel_size/2), y1 - floor(kernel_size/2) : y1 + floor(kernel_size/2));

            % Compute the range Gaussian kernel
            Gsr = (1/(sr*sqrt(2*pi))) * exp(-0.5 * (I1 - intensity).^2 / sr^2);

            % Compute the new pixel location and intensity
            x = X1 + x1;
            y = Y1 + y1;
            x2 = max(min(floor(sum(x .* Gss .* Gsr, 'all') / sum(Gss .* Gsr, 'all')), a(1) + floor(kernel_size/2)), floor(kernel_size/2) + 1);
            y2 = max(min(floor(sum(y .* Gss .* Gsr, 'all') / sum(Gss .* Gsr, 'all')), a(2) + floor(kernel_size/2)), floor(kernel_size/2) + 1);
            I2 = sum(intensity .* Gss .* Gsr, 'all') / sum(Gss .* Gsr, 'all');
            if mod(count, 100) == 0
                %current_std = std(im2(:));
                fprintf('Iteration: %d, %.4f, %.4f, %.4f\n', count, y2-y1, x2-x1, I2-I1);
            end
        end

        % Assign the converged intensity to the output image
        im2(i - floor(kernel_size/2), j - floor(kernel_size/2)) = I2;
        fprintf('Pixel at (%d, %d) has converged to intensity %.2f\n', i - floor(kernel_size/2), j - floor(kernel_size/2), I2);
    end
    % Print the iteration number and current standard deviation at intervals of 100
end
end