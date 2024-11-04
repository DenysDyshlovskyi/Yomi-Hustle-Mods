import os
import shutil
import sys
from tkinter import Tk
from tkinter.filedialog import askdirectory

def main():

    # Open a dialog to select the directory
    Tk().withdraw()  # Hides the main window
	#print("Select your Mod's folder (NOT THE IMPORT FOLDER. ONLY RUN THIS FROM YOUR GODOT INSTALLATION)"
    os.chdir(os.path.dirname(os.path.abspath(__file__)))
    search_directory = askdirectory(title='Select Mod Folder (ONLY RUN THIS IN YOUR YOMI GODOT ROOT FOLDER)', initialdir=os.getcwd())  # Open the folder selection dialog
    
    if not search_directory:
        print("No directory selected. Exiting...")
        return

    # Destination folder to copy files to
    destination_folder = 'ModImport'
    
    # Find all files listed in .import files
    file_paths = find_import_files(search_directory)
    
    # Print the array of file paths
    print("Files listed in .import files:")
    print(file_paths)
    
    # Copy files to the destination folder
    copy_files(file_paths, destination_folder)
    
    print("Files copied successfully.")
	
def find_import_files(directory):
    # Array to store file paths
    file_paths = []
    
    # Walk through the directory
    for root, dirs, files in os.walk(directory):
        for file in files:
            if file.endswith('.import'):
                # Construct full file path
                import_file = os.path.join(root, file)
                
                # Read the file to find the path line
                with open(import_file, 'r') as f:
                    for line in f:
                        if line.startswith('path='):
                            # Extract the file path from the line
                            file_path = line.split('=')[1].strip().strip('"')
                            
                            # Adjust the path if it uses the "res://" format
                            if file_path.startswith("res://"):
                                file_path = file_path.replace("res://", "")
								
                            file_paths.append(file_path)
                            pathhash = file_path.rsplit( ".", 1 )[ 0 ]
                            pathhash += ".md5"
                            file_paths.append(pathhash)
                            break  # Stop after finding the path line
    
    return file_paths

def copy_files(file_paths, destination_folder):
    # Clear the destination folder if it exists
    if os.path.exists(destination_folder):
        shutil.rmtree(destination_folder)
    os.makedirs(destination_folder)
    
    # Copy each file to the destination folder
    for file_path in file_paths:
        if os.path.isfile(file_path):
            shutil.copy(file_path, destination_folder)
        else:
            print(f"File not found: {file_path}")

if __name__ == "__main__":
    main()
