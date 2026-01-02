import pandas as pd

#verify if columns that have dates have correct format
def validate_date_format(df, date_column, date_format = '%Y-%m-%d'):
  try:
    pd.to_datetime(df[date_column], format=date_format,errors='raise')
    return True
  except: 
    return False
  

'''verify if columns that represent money 
have values equal to or bigger than zero'''
def validate_non_negative_int(df,int_column):
  return (df[int_column]>=0).all()

