import pyexcel
from openpyxl import load_workbook

filename = "test.xls"
records = pyexcel.iget_records(file_name=filename)
names = [record['name'] for record in records]
print(type(names), names)

filename = "test.xlsx"
book = load_workbook(filename=filename)
sheet = book['Sheet1']
column = sheet['B2:B4']
names = [cell[0].value for cell in column]
print(type(names), names)
