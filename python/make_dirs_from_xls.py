import os
import pyexcel

# creating folders from list in XLS file using pyexcel
# assuming that folders are in "Folder" column

root_path = os.path.dirname(os.path.realpath(__file__))

datafile = ".\\filename.xls"
records = pyexcel.iget_records(file_name=datafile)
folders = [record['Folder'] for record in records]

for folder in folders:
    os.mkdir(os.path.join(root_path, folder))
