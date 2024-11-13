% Set image directory path
image_dir = '../images/';

% Read the original image
image = imread(fullfile(image_dir, 'kodak24.png'));
image = double(image);  % Convert to double for DCT
size_of_image = size(image);
blockSize = [8 8];

% DCT
dct_image = blockproc(image, blockSize, @(block) dct2(block.data));

% Quantization
quantization_matrix = [
    16, 11, 10, 16, 24, 40, 51, 61;
    12, 12, 14, 19, 26, 58, 60, 55;
    14, 13, 16, 24, 40, 57, 69, 56;
    14, 17, 22, 29, 51, 87, 80, 62;
    18, 22, 37, 56, 68, 109, 103, 77;
    24, 35, 55, 64, 81, 104, 113, 92;
    49, 64, 78, 87, 103, 121, 120, 101;
    72, 92, 95, 98, 112, 100, 103, 99
];

% quantization_matrix = quantization_matrix * 2;
quantized_image = blockproc(dct_image, blockSize, @(block) round(block.data ./ quantization_matrix));

% Huffman Encoding

% Flatten quantized image for Huffman encoding
symbols = unique(quantized_image(:));
counts = histcounts(quantized_image(:), [symbols; max(symbols)+1]);

% Create Huffman dictionary
[dict, avglen] = huffmandict(symbols, counts / numel(quantized_image));

% Huffman encode the image
huff_encoded_image = huffmanenco(quantized_image(:), dict);

save('compressed_image.mat', 'huff_encoded_image', 'quantization_matrix', 'dict', 'size_of_image', '-v7.3');

% Huffman Decoding
decoded_data = huffmandeco(huff_encoded_image, dict);
quantized_image = reshape(decoded_data, size_of_image);

% Dequantization
dequantized_image = blockproc(quantized_image, blockSize, @(block) block.data .* quantization_matrix);

% Inverse DCT
reconstructed_image = blockproc(dequantized_image, blockSize, @(block) idct2(block.data));
reconstructed_image = uint8(reconstructed_image); % Convert back to uint8 for display

% Display the reconstructed image
imshow(reconstructed_image);
title('Reconstructed Image');

% Calculate RMSE
rmse = sqrt(mean((double(image) - double(reconstructed_image)).^2, 'all'));

% Calculate BPP
bpp = numel(huff_encoded_image) / numel(image);  % bits per pixel

quality_factors = 10:10:100;
rmse_values = zeros(length(quality_factors), 1);
bpp_values = zeros(length(quality_factors), 1);

for idx = 1:length(quality_factors)
    % Adjust quantization matrix based on the quality factor
    quality_factor = quality_factors(idx);
    scaled_quantization_matrix = round(quantization_matrix * (100 / quality_factor));

    % Step 1: Apply DCT
    dct_image = blockproc(image, blockSize, @(block) dct2(block.data));

    % Step 2: Quantize using the scaled quantization matrix
    quantized_image = blockproc(dct_image, blockSize, @(block) round(block.data ./ scaled_quantization_matrix));

    % Step 3: Huffman encoding
    symbols = unique(quantized_image(:));
    counts = histcounts(quantized_image(:), [symbols; max(symbols)+1]);
    [dict, avglen] = huffmandict(symbols, counts / numel(quantized_image));
    huff_encoded_image = huffmanenco(quantized_image(:), dict);

    % Calculate BPP (Bits Per Pixel)
    compressed_size_in_bits = numel(huff_encoded_image); % Number of bits in Huffman encoded data
    bpp_values(idx) = compressed_size_in_bits / numel(image);  % Bits per pixel (BPP)

    % Step 4: Huffman Decoding
    decoded_data = huffmandeco(huff_encoded_image, dict);
    decoded_quantized_image = reshape(decoded_data, size_of_image);

    % Step 5: Dequantize
    dequantized_image = blockproc(decoded_quantized_image, blockSize, ...
        @(block) block.data .* scaled_quantization_matrix);

    % Step 6: Apply inverse DCT
    reconstructed_image = blockproc(dequantized_image, blockSize, @(block) idct2(block.data));
    reconstructed_image = uint8(reconstructed_image);  % Convert back to uint8 for display

    % Calculate RMSE
    rmse_values(idx) = sqrt(mean((double(image) - double(reconstructed_image)).^2, 'all'));
end

% Create a new figure for the second plot
figure;
plot(bpp_values, rmse_values, '-o');
xlabel('Bits Per Pixel (BPP)');
ylabel('RMSE');
title('RMSE vs. BPP');