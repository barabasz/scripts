from openpyxl import load_workbook

"""Get headers from Excel's table"""

headers_row = 1 # row number with headers
sheet_num = 0 # sheet index
file_name = 'filename.xlsx'

# select workbook / Excel file
workbook = load_workbook(filename=file_name)
# select sheet
sheet = workbook.worksheets[sheet_num]
# select row with headers
row = sheet[headers_row]
# make list with headers
headers = [cell.value for cell in row]
print(headers)
