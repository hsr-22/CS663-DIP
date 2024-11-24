
import numpy as np
from scipy.fftpack import dct, idct
from PIL import Image
import heapq
import math
from collections import defaultdict
import argparse
import os

Q = 50

class BitBuffer:
    def __init__(self):
        self.buffer = 0  # Store bits temporarily
        self.size = 0    # Number of bits currently stored
        self.bytes = bytearray()  # Store complete bytes
    
    def add_bits(self, value, num_bits=None):
        """Add an integer value (signed or unsigned) to the buffer.
        
        If num_bits is not provided, it defaults to the minimum number of bits
        required to store the value, including handling for signed integers.
        """
        req_bits = 0
        if value < 0:
            req_bits = value.bit_length() + 1
        else:
            req_bits = value.bit_length() if value != 0 else 1
            
        if num_bits is None:
            num_bits = req_bits
            
        if(num_bits < req_bits):
            raise ValueError("Number of bits is less than the required bits.")

        # If value is negative, represent it using two's complement
        if value < 0:
            # Convert to two's complement with num_bits bits
            value = (1 << num_bits) + value

        for i in range(num_bits - 1, -1, -1):
            bit = (value >> i) & 1  # Extract the bit
            self.buffer = (self.buffer << 1) | bit  # Shift buffer and add bit
            self.size += 1
            if self.size == 8:
                self._flush_buffer()  # If we have a full byte, flush it
    
    def add_bit(self, bit):
        """Add a single bit (0 or 1) to the buffer."""
        self.add_bits(bit, 1)
    
    def _flush_buffer(self):
        """Flush buffer contents to the byte array."""
        self.bytes.append(self.buffer)
        self.buffer = 0
        self.size = 0
    
    def write_to_file(self, filename):
        """Write the buffered bytes to a file."""
        # Flush remaining bits, if any (pad with zeros)
        if self.size > 0:
            self.buffer <<= (8 - self.size)  # Pad with zeros
            self._flush_buffer()
        with open(filename, 'ab') as file:
            file.write(self.bytes)

bit_buffer = BitBuffer()

zigzag_indices = [0, 1, 8, 16, 9, 2, 3, 10, 17, 24, 32, 25, 18, 11, 4, 5, 12, 19, 26, 33, 40, 48, 41, 34, 27, 20, 13, 6, 7, 14, 21, 28, 35, 42, 49, 56, 57, 50, 43, 36, 29, 22, 15, 23, 30, 37, 44, 51, 58, 59, 52, 45, 38, 31, 39, 46, 53, 60, 61, 54, 47, 55, 62, 63]

quantization_matrix = np.array([
    [16, 11, 10, 16, 24, 40, 51, 61],
    [12, 12, 14, 19, 26, 58, 60, 55],
    [14, 13, 16, 24, 40, 57, 69, 56],
    [14, 17, 22, 29, 51, 87, 80, 62],
    [18, 22, 37, 56, 68, 109, 103, 77],
    [24, 35, 55, 64, 81, 104, 113, 92],
    [49, 64, 78, 87, 103, 121, 120, 101],
    [72, 92, 95, 98, 112, 100, 103, 99]
]) * (50 / Q)

freq_dict = {}
DC_freq_dict = {}

def pad_image(image_array):
    height, width = image_array.shape
    pad_height = (8 - height % 8) if height % 8 != 0 else 0
    pad_width = (8 - width % 8) if width % 8 != 0 else 0
    padded_image_array = np.pad(image_array, ((0, pad_height), (0, pad_width)), mode='constant', constant_values=0)    
    return padded_image_array


def dct_and_quantize(image):
    image = pad_image(image)
    h, w = image.shape
    quantised_blocks = np.zeros_like(image, dtype=int)
    previous_dc = 0
    
    for i in range(0, h, 8):
        for j in range(0, w, 8):
            block = image[i:i+8, j:j+8]
            dct_block = dct(dct(block.T, type=2, norm='ortho').T, type=2, norm='ortho')
            quantised_block = np.round(dct_block/quantization_matrix).astype(int)
            quantised_blocks[i:i+8, j:j+8] = quantised_block
            quantised_blocks[i,j] -= previous_dc
            previous_dc = quantised_block[0,0]
     
     
    for i in range(h):
        for j in range(w):
            pixel_value = quantised_blocks[i,j]
            if(pixel_value==0):
                continue
            
            if(i%8==0 and j%8==0):
                if(i==0 and j==0):
                    continue
                if pixel_value in DC_freq_dict:
                    DC_freq_dict[pixel_value] += 1
                else:
                    DC_freq_dict[pixel_value] = 1       
            else:
                if pixel_value in freq_dict:
                    freq_dict[pixel_value] += 1
                else:
                    freq_dict[pixel_value] = 1       
    
    return quantised_blocks


class HuffmanNode:
    def __init__(self, char, freq):
        self.char = char
        self.freq = freq
        self.left = None
        self.right = None
    
    def __lt__(self, other):
        return self.freq < other.freq
    
def build_huffman_tree(freq_map):
    heap = [HuffmanNode(char, freq) for char, freq in freq_map.items()]
    heapq.heapify(heap)
    
    while len(heap) > 1:
        left = heapq.heappop(heap)
        right = heapq.heappop(heap)
        
        merged = HuffmanNode(None, left.freq + right.freq)
        merged.left = left
        merged.right = right
        
        heapq.heappush(heap, merged)
    
    return heap[0] 

def generate_huffman_codes(node, prefix='', codebook=None):
    if codebook is None:
        codebook = {}
    
    if node is not None:
        if node.char is not None:
            codebook[node.char] = prefix
        generate_huffman_codes(node.left, prefix + '0', codebook)
        generate_huffman_codes(node.right, prefix + '1', codebook)
    
    return codebook

def huffman_encode_image(freq_map):
    huffman_tree_root = build_huffman_tree(freq_map)
    huffman_codes = generate_huffman_codes(huffman_tree_root)
    return huffman_codes


def encode_quantized_block_zigzag(block, huffman_map, DC_map, first=False):
    last_non_zero_index = -1
    block = block.flatten()
    
    flattened_block = [block[i] for i in zigzag_indices]
    
    for i, value in enumerate(flattened_block):
        if(i==0 and first):
            continue
        
        if value != 0:
            zeros = flattened_block[max(0,last_non_zero_index):i].count(0)
            code = ""
            if(i==0):
                code = DC_map.get(value,"")
            else:
                code = huffman_map.get(value, "")
                
            while(zeros > 15):
                bit_buffer.add_bits(15,4)
                bit_buffer.add_bits(0,4)
                zeros-=15
                
            bit_buffer.add_bits(zeros,4)
            bit_buffer.add_bits(len(code),4)
            bit_buffer.add_bits(int(code,2),len(code))
            
            last_non_zero_index = i 
    
    bit_buffer.add_bits(0,8)
    

def write_to_file(img_dim, quantized_blocks, filename, huffman_map, DC_map):
    h, w = quantized_blocks.shape
    reversed_huffman_dict = {v: k for k, v in huffman_map.items()}
    reversed_DC_dict = {v: k for k, v in DC_map.items()}
    
    print(reversed_DC_dict)
    with open(filename, 'wb') as file:
        file.write(f'{img_dim[0]}:{img_dim[1]}:{quantized_blocks[0,0]}:{Q}:{len(huffman_map)}:{len(DC_map)}\n'.encode('utf-8'))
            
        for key, value in reversed_huffman_dict.items():
            # bit_buffer.add_bits(len(key),4)
            # bit_buffer.add_bits(int(key,2),len(key))
            
            # if(value<0):
            #     bit_buffer.add_bit(1)
            # else:
            #     bit_buffer.add_bit(0)
            
            # value = math.fabs(value)
            # num_bits = int(value).bit_length() if value != 0 else 1
                
            # bit_buffer.add_bits(num_bits,4)
            # bit_buffer.add_bits(int(value),num_bits)
            file.write(f'{key}:{value}\n'.encode('utf-8'))
        for key, value in reversed_DC_dict.items():
            # bit_buffer.add_bits(len(key),4)
            # bit_buffer.add_bits(int(key,2),len(key))
            
            # if(value<0):
            #     bit_buffer.add_bit(1)
            # else:
            #     bit_buffer.add_bit(0)
            
            # value = math.fabs(value)
            # num_bits = int(value).bit_length() if value != 0 else 1
            # bit_buffer.add_bits(num_bits,4)
            # bit_buffer.add_bits(int(value),num_bits)
            file.write(f'{key}:{value}\n'.encode('utf-8'))

    for i in range(0, h, 8):
        for j in range(0, w, 8):
            block = quantized_blocks[i:i+8, j:j+8]
            if(i==0 and j==0):
                encode_quantized_block_zigzag(block, huffman_map, DC_map, True)
            else:
                encode_quantized_block_zigzag(block, huffman_map, DC_map)
                

def main():
    parser = argparse.ArgumentParser(description="JPEG Encoder with Huffman encoding")
    parser.add_argument("image_path", type=str, help="Path to the input image")
    args = parser.parse_args()
    image_path = args.image_path
    
    image_pil = Image.open(image_path)
    if image_pil is None:
        print("Error: Image could not be loaded.")
        return
    
    image = np.array(image_pil.convert('L'))
    
    quantized_blocks = dct_and_quantize(image)

    huffman_map = huffman_encode_image(freq_dict)
    DC_map = huffman_encode_image(DC_freq_dict)  
    
    file_name_without_extension = os.path.splitext(image_path)[0]
    filename = file_name_without_extension + '.sts'
    
    write_to_file(image.shape, quantized_blocks, filename, huffman_map, DC_map)
    bit_buffer.write_to_file(filename)

if __name__ == "__main__":
    main()