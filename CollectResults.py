import sys
import os
import shutil
import argparse


def preprocess_folder(folder_name, file_extension, target_folder):
    # Create the destination directory if it doesn't exist
    dest_dir = os.path.join('/data/hongdong.qin/ecmScripts', target_folder, folder_name)
    os.makedirs(dest_dir, exist_ok=True)

    # Copy .txt files from the source directory to the destination directory
    src_dir = os.path.join('/data/hongdong.qin/outputs', folder_name)
    for root, dirs, files in os.walk(src_dir):
        for file in files:
            if file.endswith(file_extension):
                src_file = os.path.join(root, file)
                dest_file = os.path.join(dest_dir, os.path.relpath(src_file, src_dir))
                os.makedirs(os.path.dirname(dest_file), exist_ok=True)
                shutil.copy2(src_file, dest_file)

def main():
    if len(sys.argv) < 2:
        print("Please provide the folder name as a command-line argument.")
        return

    parser = argparse.ArgumentParser()
    parser.add_argument('-l', action = 'store_true', help = 'Collect log files')
    parser.add_argument('-b', action = 'store_true', help = 'Collect binary files')
    parser.add_argument('-s', dest = 'source_dir', help = 'Source directory under /data/hongdong.qin/outputs')

    args = parser.parse_args()

    if args.l:
        preprocess_folder(args.source_dir, '.txt', 'Results')
    if args.b:
        preprocess_folder(args.source_dir, '.bin', 'Bitstreams')

if __name__ == '__main__':
    main()
