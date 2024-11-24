% File: jpeg_compression_engine.m

function jpeg_compression_engine(images_folder, quality_factors)
    % Main driver function to process images and simulate JPEG-like compression.
    % Input: 
    % images_folder - Folder containing grayscale BMP images
    % quality_factors - Array of quality factors for quantization
    
    % Get list of image files in the folder
    image_files = dir(fullfile(images_folder, '*.bmp')); % Update for BMP images
    if isempty(image_files)
        error('No BMP images found in the specified folder: %s', images_folder);
    end
    
    RMSE = []; % Store RMSE for each image and quality factor
    BPP = [];  % Store bits-per-pixel for each image and quality factor

    % Loop through each image
    for imgIdx = 1:length(image_files)
        % Load the image as double for calculations
        image_path = fullfile(image_files(imgIdx).folder, image_files(imgIdx).name);
        original_image = double(imread(image_path)); % Ensure image is read as double
        [rows, cols] = size(original_image);
        
        fprintf('Processing image: %s\n', image_files(imgIdx).name);
        
        % Loop through quality factors
        for q = quality_factors
            % Step 1: Apply 2D DCT block-by-block
            dct_coeffs = block_dct(original_image, 8); 
            
            % Step 2: Quantize the DCT coefficients
            quantized = quantize_dct(dct_coeffs, q);
            
            % Step 3: Apply Run-Length Encoding (RLE)
            rle_encoded = run_length_encode(quantized(:));
            
            % Step 4: Compute Huffman Encoding
            symbols = unique(rle_encoded);
            probabilities = histc(rle_encoded, symbols) / numel(rle_encoded);
            huffman_dict = huffmandict(symbols, probabilities);
            encoded_data = huffmanenco(rle_encoded, huffman_dict);
            
            % Step 5: Calculate compression size and bits per pixel
            compressed_size_bits = length(encoded_data) * 8; % Convert to bits
            bits_per_pixel = compressed_size_bits / (rows * cols);
            BPP = [BPP; bits_per_pixel];
            
            % Step 6: Decode Huffman and Run-Length
            decoded_data = huffmandeco(encoded_data, huffman_dict); % Ensure `encoded_data` is a vector
            quantized_reconstructed = run_length_decode(decoded_data, size(quantized));
            
            % Step 7: Dequantize and apply inverse DCT block-by-block
            reconstructed_image = inverse_quantize_dct(quantized_reconstructed, q, [rows, cols]);
            
            % Step 8: Compute RMSE
            error = sqrt(mean((original_image(:) - double(reconstructed_image(:))).^2));
            RMSE = [RMSE; error];
            
            % Save compressed data to a file with .compressed extension
            [~, name, ~] = fileparts(image_files(imgIdx).name); % Extract base filename
            write_compressed_file(encoded_data, q, fullfile(images_folder, [name, '.compressed']));
            
            % Save the decoded image to BMP format
            decoded_image_filename = fullfile(images_folder, [name, '_decoded.bmp']);
            imwrite(uint8(reconstructed_image), decoded_image_filename);
            
            % Display the reconstructed image
            figure;
            imshow(uint8(reconstructed_image)); % Convert to uint8 for display
            title(sprintf('Reconstructed Image (Quality Factor: %d)', q));
        end
    end
    
    % Plot RMSE vs. BPP
    figure;
    plot(BPP, RMSE, 'o-');
    xlabel('Bits Per Pixel (BPP)');
    ylabel('Root Mean Square Error (RMSE)');
    title('RMSE vs BPP for JPEG Compression');
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

% % Huffman Encoding and Decoding
% function encoded = huffman_encode(data)
%     symbols = unique(data);
%     probabilities = histc(data, symbols) / numel(data);
%     huffman_dict = huffmandict(symbols, probabilities);
%     encoded = huffmanenco(data, huffman_dict);
% end

% function decoded = huffman_decode(encoded_data, original_data)
%     symbols = unique(original_data);
%     probabilities = histc(original_data, symbols) / numel(original_data);
%     huffman_dict = huffmandict(symbols, probabilities);
%     decoded = huffmandeco(encoded_data, huffman_dict);
% end

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


images_folder = '../images'; % Path to the folder containing images
quality_factors = [10, 20, 50, 75, 90]; % Example quality factors

jpeg_compression_engine(images_folder, quality_factors);