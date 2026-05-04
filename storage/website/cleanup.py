import os
import shutil

print("🧹 CLEANING UP EVERYTHING...")

# Files to remove
files_to_remove = [
    'fixcity.db',
    'test.db',
    'app.py',
    'models.py', 
    'forms.py',
    'config.py',
    'requirements.txt'
]

# Folders to remove
folders_to_remove = [
    '__pycache__',
    'uploads',
    'migrations',
    'venv'
]

# Remove files
for file in files_to_remove:
    if os.path.exists(file):
        os.remove(file)
        print(f"✅ Removed {file}")

# Remove folders
for folder in folders_to_remove:
    if os.path.exists(folder):
        shutil.rmtree(folder)
        print(f"✅ Removed {folder} folder")

print("🎉 CLEANUP COMPLETE!")
print("Now create fresh files as shown below...")