% File: jpeg_compression_engine_optimized.m

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
            
            % Step 2: Quantize the DCT coefficients with an optimized quantization table
            quantized = quantize_dct(dct_coeffs, q);
            
            % Step 3: Apply Run-Length Encoding (RLE)
            rle_encoded = run_length_encode(zigzag_scan(quantized));
            
            % Step 4: Compute Huffman Encoding
            encoded_data = huffman_encode(rle_encoded);
            
            % Step 5: Calculate compression size and bits per pixel
            compressed_size_bits = length(encoded_data) * 8; % Convert to bits
            bits_per_pixel = compressed_size_bits / (rows * cols);
            BPP = [BPP; bits_per_pixel];
            
            % Step 6: Decode Huffman and Run-Length
            decoded_data = huffman_decode(encoded_data, rle_encoded);
            quantized_reconstructed = zigzag_unscan(run_length_decode(decoded_data, size(quantized)));
            
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

% Optimized quantization function
function quantized = quantize_dct(dct_coeffs, quality_factor)
    % JPEG-like quantization table
    quant_table = [
        16 11 10 16 24 40 51 61;
        12 12 14 19 26 58 60 55;
        14 13 16 24 40 57 69 56;
        14 17 22 29 51 87 80 62;
        18 22 37 56 68 109 103 77;
        24 35 55 64 81 104 113 92;
        49 64 78 87 103 121 120 101;
        72 92 95 98 112 100 103 99;
    ];
    quant_table = quant_table * (100 / quality_factor); % Scale by quality factor
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

% Zigzag scan for RLE
function output = zigzag_scan(blocks)
    % Converts 8x8 blocks to zigzag order
    [rows, cols] = size(blocks);
    output = zeros(1, rows * cols);
    idx = 1;
    for i = 1:rows
        for j = 1:cols
            output(idx) = blocks(i, j);
            idx = idx + 1;
        end
    end
end

function output = zigzag_unscan(data)
    % Converts zigzag order back to blocks of the original size (8x8 blocks assumed)
    block_size = 8; % Assuming 8x8 DCT blocks
    num_blocks = length(data) / (block_size^2); % Total number of blocks
    if mod(length(data), block_size^2) ~= 0
        error('Data length is not divisible by block size. Ensure proper input.');
    end
    
    output = zeros(block_size, block_size, num_blocks); % Preallocate
    idx = 1;
    for b = 1:num_blocks
        % Fill block in a zigzag pattern
        temp_block = zeros(block_size, block_size);
        zigzag_idx = zigzag_order(block_size); % Get zigzag indices
        temp_block(zigzag_idx) = data(idx:idx + block_size^2 - 1);
        output(:, :, b) = temp_block;
        idx = idx + block_size^2;
    end
end

function zigzag_idx = zigzag_order(block_size)
    % Generates the zigzag order for an NxN block
    zigzag_idx = zeros(block_size, block_size);
    idx = 1;
    for d = 1:(2*block_size - 1)
        if mod(d, 2) == 0
            % Even diagonals
            for i = 1:block_size
                j = d - i + 1;
                if j > 0 && j <= block_size
                    zigzag_idx(i, j) = idx;
                    idx = idx + 1;
                end
            end
        else
            % Odd diagonals
            for j = 1:block_size
                i = d - j + 1;
                if i > 0 && i <= block_size
                    zigzag_idx(i, j) = idx;
                    idx = idx + 1;
                end
            end
        end
    end
    zigzag_idx = find(zigzag_idx(:)); % Flatten the indices
end

% Huffman Encoding
function encoded = huffman_encode(data)
    symbols = unique(data);
    probabilities = histc(data, symbols) / numel(data);
    huffman_dict = huffmandict(symbols, probabilities);
    encoded = huffmanenco(data, huffman_dict);
end

% Huffman Decoding
function decoded = huffman_decode(encoded_data, original_data)
    symbols = unique(original_data);
    probabilities = histc(original_data, symbols) / numel(original_data);
    huffman_dict = huffmandict(symbols, probabilities);
    decoded = huffmandeco(encoded_data, huffman_dict);
end

% RLE functions
function encoded = run_length_encode(data)
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
    encoded = [encoded, data(end), count];
end

function decoded = run_length_decode(data, original_size)
    decoded = [];
    for i = 1:2:length(data)
        value = data(i);
        count = data(i+1);
        decoded = [decoded, repmat(value, 1, count)];
    end
    decoded = reshape(decoded, original_size);
end

% Inverse quantization and DCT
function reconstructed = inverse_quantize_dct(quantized, quality_factor, img_size)
    quant_table = [
        16 11 10 16 24 40 51 61;
        12 12 14 19 26 58 60 55;
        14 13 16 24 40 57 69 56;
        14 17 22 29 51 87 80 62;
        18 22 37 56 68 109 103 77;
        24 35 55 64 81 104 113 92;
        49 64 78 87 103 121 120 101;
        72 92 95 98 112 100 103 99;
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