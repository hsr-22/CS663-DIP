function rle = run_length_encoding(input_vector)
    % Run-length encoding
    rle = [];
    count = 1;
    for i = 2:length(input_vector)
        if input_vector(i) == input_vector(i-1)
            count = count + 1;
        else
            rle = [rle, input_vector(i-1), count];
            count = 1;
        end
    end
    rle = [rle, input_vector(end), count];
end

function rle_decoded = run_length_decoding(rle)
    % Run-length decoding
    rle_decoded = [];
    for i = 1:2:length(rle)
        rle_decoded = [rle_decoded, repmat(rle(i), 1, rle(i+1))];
    end
end

function [reconstructed_image, rmse, bpp] = jpeg_encode_decode(image, quantization_matrix, blockSize)
    % DCT
    dct_image = blockproc(image, blockSize, @(block) dct2(block.data));
    
    % Quantization
    quantized_image = blockproc(dct_image, blockSize, @(block) round(block.data ./ quantization_matrix));
    
    % Zigzag scan and run-length encoding
    zigzag_image = blockproc(quantized_image, blockSize, @(block) zigzag(block.data));
    rle_image = run_length_encoding(zigzag_image(:));
    
    % Define symbols as unique values in rle_image
    symbols = unique(rle_image);
    
    % Ensure symbols is a column vector
    symbols = symbols(:);
    
    % Calculate counts using histcounts
    counts = histcounts(rle_image, [symbols; max(symbols)+1]);
    
    % Huffman Encoding
    [dict, ~] = huffmandict(symbols, counts / numel(rle_image));
    huff_encoded_image = huffmanenco(rle_image, dict);
    
    % Write the data to a file
    fileID = fopen('compressed_image.dat', 'w');
    fwrite(fileID, huff_encoded_image, 'ubit1');
    fclose(fileID);
    
    % Read the data from the file
    fileID = fopen('compressed_image.dat', 'r');
    huff_encoded_image = fread(fileID, '*ubit1');
    fclose(fileID);
    
    % Convert huff_encoded_image to double
    huff_encoded_image = double(huff_encoded_image);
    
    % Huffman Decoding
    decoded_data = huffmandeco(huff_encoded_image, dict);
    
    % Ensure decoded_data has an even number of elements
    if mod(length(decoded_data), 2) ~= 0
        % If the length is odd, remove the last element
        decoded_data = decoded_data(1:end-1);
    end
    
    % Run-length decoding
    rle_decoded_image = run_length_decoding(decoded_data);
    
    % Inverse Zigzag scan
    inv_zigzag_image = blockproc(reshape(rle_decoded_image, size(quantized_image)), blockSize, @(block) inv_zigzag(block.data));
    
    % Dequantization
    dequantized_image = blockproc(inv_zigzag_image, blockSize, @(block) block.data .* quantization_matrix);
    
    % Inverse DCT
    reconstructed_image = blockproc(dequantized_image, blockSize, @(block) idct2(block.data));
    reconstructed_image = uint8(reconstructed_image); % Convert back to uint8 for display
    
    % Calculate RMSE
    rmse = sqrt(mean((double(image) - double(reconstructed_image)).^2, 'all'));
    
    % Calculate BPP
    bpp = numel(huff_encoded_image) / numel(image);  % bits per pixel
end

function output = zigzag(input)
    % Zigzag scan of a matrix
    [rows, cols] = size(input);
    output = zeros(1, rows * cols);
    index = 1;
    for s = 1:(rows + cols - 1)
        if mod(s, 2) == 0
            for i = max(1, s - cols + 1):min(rows, s)
                output(index) = input(i, s - i + 1);
                index = index + 1;
            end
        else
            for i = max(1, s - rows + 1):min(cols, s)
                output(index) = input(s - i + 1, i);
                index = index + 1;
            end
        end
    end
end

function output = inv_zigzag(input)
    % Inverse zigzag scan of a vector
    n = sqrt(length(input));
    output = zeros(n, n);
    index = 1;
    for s = 1:(2 * n - 1)
        if mod(s, 2) == 0
            for i = max(1, s - n + 1):min(n, s)
                output(i, s - i + 1) = input(index);
                index = index + 1;
            end
        else
            for i = max(1, s - n + 1):min(n, s)
                output(s - i + 1, i) = input(index);
                index = index + 1;
            end
        end
    end
end

% Main script to call the jpeg_encode_decode function
% Set image directory path
image_dir = '../images/';

image = imread(fullfile(image_dir, 'kodak24.png')); % Replace with your image file
image = double(image);  % Convert to double for DCT
quantization_matrix = [16 11 10 16 24 40 51 61; 
                       12 12 14 19 26 58 60 55; 
                       14 13 16 24 40 57 69 56; 
                       14 17 22 29 51 87 80 62; 
                       18 22 37 56 68 109 103 77; 
                       24 35 55 64 81 104 113 92; 
                       49 64 78 87 103 121 120 101; 
                       72 92 95 98 112 100 103 99]; % Example quantization matrix
blockSize = [8, 8]; % Define your block size

[reconstructed_image, rmse, bpp] = jpeg_encode_decode(image, quantization_matrix, blockSize);

% Display the original and reconstructed images
figure;
subplot(1, 2, 1);
imshow(uint8(image)); % Convert back to uint8 for display
title('Original Image');

subplot(1, 2, 2);
imshow(reconstructed_image);
title('Reconstructed Image');

% Display RMSE and BPP
disp(['RMSE: ', num2str(rmse)]);
disp(['BPP: ', num2str(bpp)]);