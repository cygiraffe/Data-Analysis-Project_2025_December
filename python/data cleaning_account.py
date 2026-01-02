import pandas as pd
from verification_functions import *
'''
singup_date -> 날짜 검증
seats: 값 0 이상 검증'''
# Load data
accounts = pd.read_csv('raw_data/ravenstack_accounts.csv')

# Check basic information
print("Data Basic Information")
print(accounts.info())
print("\n First 5 Rows")
print(accounts.head())

# Check data types
print("\n=== Data Types of Each Column ===")
print(accounts.dtypes)

# change column name for 'churn_flag'
accounts.rename(columns={'churn_flag':'churned'},inplace=True)

# Check data validity by column
# account_id: check duplicates and null values
print("\n account id validation")
print(f"Null values: {accounts['account_id'].isnull().sum()}")
print(f"Duplicate values: {accounts['account_id'].duplicated().sum()}")

# account name: check duplicates and null values
print("\n account name validation")
print(f"Null values: {accounts['account_name'].isnull().sum()}")
print(f"Duplicate values: {accounts['account_name'].duplicated().sum()}")

# industry : check null values
print("\n industry validation")
print(f"Null values: {accounts['industry'].isnull().sum()}")

# country : check null values only
print("\n country validation")
print(f"Null values: {accounts['country'].isnull().sum()}")

# sign up date: check null values and check if dates are in correct format
print("\n sign up date null check")
print(f"Null values: {accounts['signup_date'].isnull().sum()}")
print("date format validity :") 
print(validate_date_format(accounts,'signup_date'))

#referral source: check null values only
print("\n referral source validation")
print(f"Null values: {accounts['referral_source'].isnull().sum()}")

#plan tier: check null values only 
print("\n plan tier validation")
print(f"Null values: {accounts['plan_tier'].isnull().sum()}")

#seats: check null values and if values are equal to or greater than zero
print("\n seats validation")
print(f"Null values: {accounts['seats'].isnull().sum()}")
#print(f"Data type: {accounts['seats'].dtype}")
print("\n seats: non-negative value check")
print(validate_non_negative_int(accounts,'seats'))

#is_trial: check if values are only TRUE/FALSE and check null values 
print("\n is trial validation")
print(f"Null values: {accounts['is_trial'].isnull().sum()}")
#print(f"Unique values: {accounts['is_trial'].unique()}")
#print(f"Data type: {accounts['is_trial'].dtype}")

#churned: check if values are only TRUE/FALSE and check null values
print("\n churned validation")
print(f"Null values: {accounts['churned'].isnull().sum()}")
#print(f"Unique values: {accounts['churned'].unique()}")
#print(f"Data type: {accounts['churned'].dtype}")

# Save cleaned data
accounts.to_csv('cleaned_data/accounts_cleaned.csv', index=False)
print("\n=== Data Cleaning Completed and cleaned data file is made===")
