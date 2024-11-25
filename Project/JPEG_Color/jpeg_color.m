function jpeg_compression_engine_color(images_folder, compressed_folder, recovered_folder, quality_factors)
% Main driver function to process color images and simulate JPEG-like compression.
% Input:
% images_folder - Folder containing BMP images
% compressed_folder - Folder to save compressed files
% recovered_folder - Folder to save recovered images
% quality_factors - Array of quality factors for quantization

% Get list of image files in the folder
image_files = dir(fullfile(images_folder, '*.bmp')); % Update for BMP images
if isempty(image_files)
    error('No BMP images found in the specified folder: %s', images_folder);
end

% Loop through each image
for imgIdx = 1:length(image_files)
    % Load the image
    image_path = fullfile(image_files(imgIdx).folder, image_files(imgIdx).name);
    original_image = imread(image_path);

    % Convert the image to YCrCb color space
    ycbcr_image = rgb2ycbcr(original_image);
    Y_channel = double(ycbcr_image(:,:,1));
    Cb_channel = double(ycbcr_image(:,:,2));
    Cr_channel = double(ycbcr_image(:,:,3));

    [rows, cols] = size(Y_channel);

    fprintf('Processing image: %s', image_files(imgIdx).name);

    RMSE = []; % Store RMSE for each quality factor
    BPP = [];  % Store bits-per-pixel for each quality factor

    % Loop through quality factors
    for q = quality_factors
        % Step 1: Apply 2D DCT block-by-block to Y, Cb, and Cr channels
        dct_Y = block_dct(Y_channel, 8);
        dct_Cb = block_dct(Cb_channel, 8);
        dct_Cr = block_dct(Cr_channel, 8);

        % Step 2: Quantize the DCT coefficients
        quantized_Y = quantize_dct(dct_Y, q);
        quantized_Cb = quantize_dct(dct_Cb, q);
        quantized_Cr = quantize_dct(dct_Cr, q);

        % Step 3: Apply Run-Length Encoding (RLE) to Y, Cb, and Cr channels
        rle_encoded_Y = run_length_encode(quantized_Y(:));
        rle_encoded_Cb = run_length_encode(quantized_Cb(:));
        rle_encoded_Cr = run_length_encode(quantized_Cr(:));

        % Step 4: Compute Huffman Encoding for each channel
        symbols_Y = unique(rle_encoded_Y);
        probabilities_Y = histc(rle_encoded_Y, symbols_Y) / numel(rle_encoded_Y);
        huffman_dict_Y = huffmandict(symbols_Y, probabilities_Y);
        encoded_data_Y = huffmanenco(rle_encoded_Y, huffman_dict_Y);

        symbols_Cb = unique(rle_encoded_Cb);
        probabilities_Cb = histc(rle_encoded_Cb, symbols_Cb) / numel(rle_encoded_Cb);
        huffman_dict_Cb = huffmandict(symbols_Cb, probabilities_Cb);
        encoded_data_Cb = huffmanenco(rle_encoded_Cb, huffman_dict_Cb);

        symbols_Cr = unique(rle_encoded_Cr);
        probabilities_Cr = histc(rle_encoded_Cr, symbols_Cr) / numel(rle_encoded_Cr);
        huffman_dict_Cr = huffmandict(symbols_Cr, probabilities_Cr);
        encoded_data_Cr = huffmanenco(rle_encoded_Cr, huffman_dict_Cr);

        % Step 5: Calculate compression size and bits per pixel
        compressed_size_bits = length(encoded_data_Y) + length(encoded_data_Cb) + length(encoded_data_Cr); % Total size in bits
        bits_per_pixel = compressed_size_bits / (rows * cols * 3);
        BPP = [BPP; bits_per_pixel];

        % Step 6: Decode Huffman and Run-Length for each channel
        decoded_data_Y = huffmandeco(encoded_data_Y, huffman_dict_Y);
        quantized_reconstructed_Y = run_length_decode(decoded_data_Y, size(quantized_Y));

        decoded_data_Cb = huffmandeco(encoded_data_Cb, huffman_dict_Cb);
        quantized_reconstructed_Cb = run_length_decode(decoded_data_Cb, size(quantized_Cb));

        decoded_data_Cr = huffmandeco(encoded_data_Cr, huffman_dict_Cr);
        quantized_reconstructed_Cr = run_length_decode(decoded_data_Cr, size(quantized_Cr));

        % Step 7: Dequantize and apply inverse DCT block-by-block
        reconstructed_Y = inverse_quantize_dct(quantized_reconstructed_Y, q, [rows, cols]);
        reconstructed_Cb = inverse_quantize_dct(quantized_reconstructed_Cb, q, [rows, cols]);
        reconstructed_Cr = inverse_quantize_dct(quantized_reconstructed_Cr, q, [rows, cols]);

        % Combine the reconstructed Y, Cb, and Cr channels
        ycbcr_reconstructed = cat(3, reconstructed_Y, reconstructed_Cb, reconstructed_Cr);

        % Convert back to RGB
        reconstructed_image = ycbcr2rgb(uint8(ycbcr_reconstructed));

        % Step 8: Compute RMSE
        error = sqrt(mean((double(original_image(:)) - double(reconstructed_image(:))).^2));
        RMSE = [RMSE; error];

        % Save compressed data to a file with .compressed extension
        [~, name, ~] = fileparts(image_files(imgIdx).name); % Extract base filename
        write_compressed_file([encoded_data_Y(:); encoded_data_Cb(:); encoded_data_Cr(:)], q, fullfile(compressed_folder, [name, '.hps'])); % hps = harsh, pranav, swayam

        % Save the decoded image to BMP format
        decoded_image_filename = fullfile(recovered_folder, [name, '_decoded.bmp']);
        imwrite(reconstructed_image, decoded_image_filename);

        % Display the reconstructed image
        figure;
        imshow(reconstructed_image);
        title(sprintf('Reconstructed Image (Quality Factor: %d)', q));
    end

    % Plot RMSE vs. BPP
    figure;
    plot(BPP, RMSE, 'o-');
    xlabel('Bits Per Pixel (BPP)');
    ylabel('Root Mean Square Error (RMSE)');
    title(sprintf('RMSE vs BPP for Color JPEG Compression - %s', image_files(imgIdx).name));

    % Save the plot
    plot_filename = fullfile(images_folder, sprintf('%s_color_rmse_vs_bpp.png', name));
    saveas(gcf, plot_filename);
    close(gcf); % Clear the figure from MATLAB
end
end

% Function to perform block-wise 2D DCT
function dct_blocks = block_dct(image, block_size)
[rows, cols] = size(image);
dct_blocks = zeros(size(image));
for i = 1:block_size:rows
    for j = 1:block_size:cols
        block = image(i:i+block_size-1, j:j+block_size-1);
        dct_blocks(i:i+block_size-1, j:j+block_size-1) = dct2(block);
    end
end
end

% Function for quantization (applies block-by-block)
function quantized = quantize_dct(dct_coeffs, quality_factor)
% Aggressive quantization table
quant_table = [
    32 22 20 32 48 80 102 122;
    24 24 28 38 52 116 120 110;
    28 26 32 48 80 114 138 112;
    28 34 44 58 102 174 160 124;
    36 44 74 112 136 218 206 154;
    48 70 110 128 162 208 226 184;
    98 128 156 174 206 242 240 202;
    144 184 190 196 224 200 206 198;
    ];
quant_table = quant_table * (100 / quality_factor);
[rows, cols] = size(dct_coeffs);
block_size = 8;
quantized = zeros(size(dct_coeffs));
for i = 1:block_size:rows
    for j = 1:block_size:cols
        block = dct_coeffs(i:i+block_size-1, j:j+block_size-1);
        quantized(i:i+block_size-1, j:j+block_size-1) = round(block ./ quant_table);
    end
end
end

% Add the run-length encoding and decoding functions
function encoded = run_length_encode(data)
% Encodes the quantized data using run-length encoding
encoded = [];
count = 1;
for i = 2:length(data)
    if data(i) == data(i-1)
        count = count + 1;
    else
        encoded = [encoded, data(i-1), count];
        count = 1;
    end
end
encoded = [encoded, data(end), count]; % Append last element
end

function decoded = run_length_decode(data, original_size)
% Decodes run-length encoded data
decoded = [];
for i = 1:2:length(data)
    value = data(i);
    count = data(i+1);
    decoded = [decoded, repmat(value, 1, count)];
end
decoded = reshape(decoded, original_size);
end

% Function to perform inverse quantization and inverse DCT
function reconstructed = inverse_quantize_dct(quantized, quality_factor, img_size)
quant_table = [
    32 22 20 32 48 80 102 122;
    24 24 28 38 52 116 120 110;
    28 26 32 48 80 114 138 112;
    28 34 44 58 102 174 160 124;
    36 44 74 112 136 218 206 154;
    48 70 110 128 162 208 226 184;
    98 128 156 174 206 242 240 202;
    144 184 190 196 224 200 206 198;
    ];
quant_table = quant_table * (100 / quality_factor);
[rows, cols] = deal(img_size(1), img_size(2));
reconstructed = zeros(rows, cols);
for i = 1:8:rows
    for j = 1:8:cols
        block = quantized(i:i+7, j:j+7) .* quant_table;
        reconstructed(i:i+7, j:j+7) = idct2(block);
    end
end
reconstructed = uint8(reconstructed);
end

% Write compressed data to file
function write_compressed_file(data, quality, filename)
fileID = fopen(filename, 'wb');
fwrite(fileID, data, 'uint8');
fclose(fileID);
end


images_folder = '../images/images'; % Path to the folder containing images
compressed_folder = '../images/compressed_c'; % Path to the folder to save compressed files
recovered_folder = '../images/recovered_c'; % Path to the folder to save recovered images
quality_factors = [10, 20, 50, 75, 90]; % Example quality factors

jpeg_compression_engine_color(images_folder, compressed_folder, recovered_folder, quality_factors);