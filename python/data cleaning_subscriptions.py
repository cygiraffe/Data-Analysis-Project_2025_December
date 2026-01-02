import pandas as pd
from verification_functions import *
'''
seats, mrr_amount, arr_amount: 값 0 이상 검증
'''
subscriptions = pd.read_csv('raw_data/ravenstack_subscriptions.csv')

# check basic information
print("Data Basic Information")
print(subscriptions.info())
print("\n First 5 Rows")
print(subscriptions.head())

#check data types
print("\nData Types of Each Column")
print(subscriptions.dtypes)

# change column names for 'upgrade_flag, downgrade_flag, churn_flag'
subscriptions.rename(columns={'upgrade_flag':'upgraded',
                              'downgrade_flag':'downgraded',
                              'churn_flag':'churned',
                              'auto_renew_flag':'auto_renewed'}, inplace=True)

#check data validity by column
# subscription_id : check duplicates and null values
print("\n subscription id validation")
print(f"Null values: {subscriptions['subscription_id'].isnull().sum()}")
print(f"Duplicate values: {subscriptions['subscription_id'].duplicated().sum()}")

#account_id : check null values(foreign key to account_id in accounts table)
print("\n account_id validation")
print(f"Null values: {subscriptions['account_id'].isnull().sum()}")

# start_date: check null values and check if dates are in correct format
print("\n start date validation")
print(f"Null values: {subscriptions['start_date'].isnull().sum()}")
print("start_date format validity :") 
print(validate_date_format(subscriptions,'start_date'))

# end_date: check if dates are in correct format
print("end_date format validity :") 
print(validate_date_format(subscriptions,'end_date'))

#plan tier : check null values only
print("\n plan tier validation")
print(f"Null values: {subscriptions['plan_tier'].isnull().sum()}")

#seats: check null values only and if values are equal to or greater than zero
print("\n seats validation")
print(f"Null values: {subscriptions['seats'].isnull().sum()}")
print("\n seats: non-negative value check")
print(validate_non_negative_int(subscriptions,'seats'))

#mrr: check null values only and if values are equal to or greater than zero
print("\n mrr validation")
print(f"Null values: {subscriptions['mrr_amount'].isnull().sum()}")
print("mrr non-negative value check")
print(validate_non_negative_int(subscriptions,'mrr_amount'))

#arr: check null values,check if arr is always greater than mrr, and if values are equal to or greater than zero
print("\n arr validation")
print(f"Null values: {subscriptions['arr_amount'].isnull().sum()}")
invalid_arr = (subscriptions['mrr_amount']>subscriptions['arr_amount']).sum()
print(f"number of rows with invalid arr : {invalid_arr}")
print("arr non-negative value check")
print(validate_non_negative_int(subscriptions,'arr_amount'))

#is_trial, upgraded, downgraded, churned, auto_renewed: check null values
#is trial
print("\n is trial validation")
print(f"Null values: {subscriptions['is_trial'].isnull().sum()}")

#upgraded
print("\n upgrade validation")
print(f"Null values: {subscriptions['upgraded'].isnull().sum()}")

#downgraded
print("\n downgrade validation")
print(f"Null values: {subscriptions['downgraded'].isnull().sum()}")

#churned
print("\n churned validation")
print(f"Null values: {subscriptions['churned'].isnull().sum()}")

#auto_renewed
print("\n auto renewal validation")
print(f"Null values: {subscriptions['auto_renewed'].isnull().sum()}")

#billing_frequency: check null values and check values in the column
print("\n billing frequency validation")
print(f"Null values: {subscriptions['billing_frequency'].isnull().sum()}")
print(f"Unique values: {subscriptions['billing_frequency'].unique()}")

# Save cleaned data
subscriptions.to_csv('cleaned_data/subscriptions_cleaned.csv', index=False)
print("\n=== Data Cleaning Completed and cleaned data file is made===")
