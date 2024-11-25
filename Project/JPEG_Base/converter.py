from PIL import Image
import os

def convert_images_to_png(input_folder, output_folder):
    """
    Convert .bmp or .tif images in the input folder to .png format and save them to the output folder.
    :param input_folder: Path to the folder containing .bmp or .tif images.
    :param output_folder: Path to the folder where .png images will be saved.
    """
    # Ensure the output folder exists
    if not os.path.exists(output_folder):
        os.makedirs(output_folder)

    # Process each image in the input folder
    for file_name in os.listdir(input_folder):
        if file_name.lower().endswith(('.bmp', '.tif')):  # Check for .bmp or .tif files
            input_path = os.path.join(input_folder, file_name)
            output_name = os.path.splitext(file_name)[0] + ".png"  # Change extension to .png
            output_path = os.path.join(output_folder, output_name)

            try:
                # Open the image and save it as .png
                with Image.open(input_path) as img:
                    img.convert("RGB").save(output_path, "PNG")
                print(f"Converted: {file_name} -> {output_name}")
            except Exception as e:
                print(f"Failed to convert {file_name}: {e}")

# Example usage
input_folder = "../images/images"  # Replace with the path to your input folder
output_folder = "../images"  # Replace with the path to your output folder
convert_images_to_png(input_folder, output_folder)
