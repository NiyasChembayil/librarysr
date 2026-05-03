import os
import re

def replace_in_file(file_path):
    with open(file_path, 'r') as f:
        content = f.read()
    
    # Matches .withOpacity(0.5) or .withOpacity(some_variable)
    # We want to replace it with .withValues(alpha: 0.5)
    new_content = re.sub(r'\.withOpacity\((.*?)\)', r'.withValues(alpha: \1)', content)
    
    if content != new_content:
        with open(file_path, 'w') as f:
            f.write(new_content)
        return True
    return False

def process_directory(directory):
    count = 0
    for root, dirs, files in os.walk(directory):
        for file in files:
            if file.endswith('.dart'):
                if replace_in_file(os.path.join(root, file)):
                    count += 1
                    print(f"Updated: {file}")
    print(f"Total files updated: {count}")

if __name__ == "__main__":
    process_directory('lib')
