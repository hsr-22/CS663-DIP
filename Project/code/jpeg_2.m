function jpeg_compression()
    % Set image directory path
    image_dir = '../images/';
    
    % Read the original image
    image = imread(fullfile(image_dir, 'kodak24.png'));
    image = double(image);  % Convert to double for DCT
    size_of_image = size(image);
    blockSize = [8 8];
    
    % Define the quantization matrix
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
    
    % Perform JPEG compression and decompression
    [reconstructed_image, rmse, bpp] = jpeg_encode_decode(image, quantization_matrix, blockSize);
    
    % Display the reconstructed image
    figure;
    imshow(reconstructed_image);
    title('Reconstructed Image');
    
    % Display RMSE and BPP
    fprintf('RMSE: %.4f\n', rmse);
    fprintf('BPP: %.4f\n', bpp);
    
    % Evaluate performance for different quality factors
    quality_factors = 10:10:100;
    [rmse_values, bpp_values] = evaluate_quality_factors(image, quantization_matrix, blockSize, quality_factors);
    
    % Plot RMSE vs. BPP
    figure;
    plot(bpp_values, rmse_values, '-o');
    xlabel('Bits Per Pixel (BPP)');
    ylabel('RMSE');
    title('RMSE vs. BPP');
end

% function [reconstructed_image, rmse, bpp] = jpeg_encode_decode(image, quantization_matrix, blockSize)
%     % DCT
%     dct_image = blockproc(image, blockSize, @(block) dct2(block.data));
    
%     % Quantization
%     quantized_image = blockproc(dct_image, blockSize, @(block) round(block.data ./ quantization_matrix));
    
%     % Huffman Encoding
%     symbols = unique(quantized_image(:));
%     counts = histcounts(quantized_image(:), [symbols; max(symbols)+1]);
%     [dict, ~] = huffmandict(symbols, counts / numel(quantized_image));
%     huff_encoded_image = huffmanenco(quantized_image(:), dict);
    
%     % Huffman Decoding
%     decoded_data = huffmandeco(huff_encoded_image, dict);
%     quantized_image = reshape(decoded_data, size(image));
    
%     % Dequantization
%     dequantized_image = blockproc(quantized_image, blockSize, @(block) block.data .* quantization_matrix);
    
%     % Inverse DCT
%     reconstructed_image = blockproc(dequantized_image, blockSize, @(block) idct2(block.data));
%     reconstructed_image = uint8(reconstructed_image); % Convert back to uint8 for display
    
%     % Calculate RMSE
%     rmse = sqrt(mean((double(image) - double(reconstructed_image)).^2, 'all'));
    
%     % Calculate BPP
%     bpp = numel(huff_encoded_image) / numel(image);  % bits per pixel
% end

function [rmse_values, bpp_values] = evaluate_quality_factors(image, quantization_matrix, blockSize, quality_factors)
    rmse_values = zeros(length(quality_factors), 1);
    bpp_values = zeros(length(quality_factors), 1);
    
    for idx = 1:length(quality_factors)
        quality_factor = quality_factors(idx);
        scaled_quantization_matrix = round(quantization_matrix * (100 / quality_factor));
        
        [~, rmse, bpp] = jpeg_encode_decode(image, scaled_quantization_matrix, blockSize);
        
        rmse_values(idx) = rmse;
        bpp_values(idx) = bpp;
    end
end
function zigzag_matrix = zigzag(input_matrix)
    % Zigzag scan of an 8x8 matrix
    zigzag_order = [
        1  2  6  7 15 16 28 29;
        3  5  8 14 17 27 30 43;
        4  9 13 18 26 31 42 44;
        10 12 19 25 32 41 45 54;
        11 20 24 33 40 46 53 55;
        21 23 34 39 47 52 56 61;
        22 35 38 48 51 57 60 62;
        36 37 49 50 58 59 63 64
    ];
    zigzag_matrix = input_matrix(zigzag_order);
end

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

function [reconstructed_image, rmse, bpp] = jpeg_encode_decode(image, quantization_matrix, blockSize)
    % DCT
    dct_image = blockproc(image, blockSize, @(block) dct2(block.data));
    
    % Quantization
    quantized_image = blockproc(dct_image, blockSize, @(block) round(block.data ./ quantization_matrix));
    
    % Zigzag scan and run-length encoding
    zigzag_image = blockproc(quantized_image, blockSize, @(block) zigzag(block.data));
    rle_image = run_length_encoding(zigzag_image(:));
    
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
    
    % Huffman Decoding
    decoded_data = huffmandeco(huff_encoded_image, dict);
    
    % Run-length decoding
    rle_decoded_image = [];
    for i = 1:2:length(decoded_data)
        rle_decoded_image = [rle_decoded_image, repmat(decoded_data(i), 1, decoded_data(i+1))];
    end
    
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

function inv_zigzag_matrix = inv_zigzag(input_vector)
    % Inverse zigzag scan of an 8x8 matrix
    zigzag_order = [
        1  2  6  7 15 16 28 29;
        3  5  8 14 17 27 30 43;
        4  9 13 18 26 31 42 44;
        10 12 19 25 32 41 45 54;
        11 20 24 33 40 46 53 55;
        21 23 34 39 47 52 56 61;
        22 35 38 48 51 57 60 62;
        36 37 49 50 58 59 63 64
    ];
    inv_zigzag_matrix = zeros(8, 8);
    inv_zigzag_matrix(zigzag_order) = input_vector;
end

% % Write the data to a file
% fileID = fopen('compressed_image.dat', 'w');
% fwrite(fileID, huff_encoded_image, 'ubit1');
% fclose(fileID);

% % Read the data from the file
% fileID = fopen('compressed_image.dat', 'r');
% huff_encoded_image = fread(fileID, '*ubit1');
% fclose(fileID);

% % Huffman Decoding
% decoded_data = huffmandeco(huff_encoded_image, dict);

% % Run-length decoding
% rle_decoded_image = zeros(1, sum(decoded_data(2:2:end))); % Preallocate size
% index = 1;
% for i = 1:2:length(decoded_data)
%     rle_decoded_image(index:index+decoded_data(i+1)-1) = decoded_data(i);
%     index = index + decoded_data(i+1);
% end

% % Inverse Zigzag scan
% inv_zigzag_image = blockproc(reshape(rle_decoded_image, size(quantized_image)), blockSize, @(block) inv_zigzag(block.data));

% % Dequantization
% dequantized_image = blockproc(inv_zigzag_image, blockSize, @(block) block.data .* quantization_matrix);

% % Inverse DCT
% reconstructed_image = blockproc(dequantized_image, blockSize, @(block) idct2(block.data));
% reconstructed_image = uint8(reconstructed_image); % Convert back to uint8 for display

% % Calculate RMSE
% rmse = sqrt(mean((double(image) - double(reconstructed_image)).^2, 'all'));

% % Calculate BPP
% bpp = numel(huff_encoded_image) / numel(image);  % bits per pixel