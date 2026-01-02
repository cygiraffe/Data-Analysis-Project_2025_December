'''non-null은 info()함수에서 나오기 때문에 할 필요가 없고, 
data type도 bool로 나오기 때문에 할 필요가 없음. 
duplicate()이랑, unique() 정도만 하면 된다.'''

import pandas as pd
from verification_functions import *
churn = pd.read_csv('raw_data/ravenstack_churn_events.csv')

# check basic information
print("Data Basic Information")
print(churn.info())
print("\n First 5 Rows")
print(churn.head())

#check data types
print("\nData Types of Each Column")
print(churn.dtypes)

# change column names for 'upgrade_flag, downgrade_flag, churn_flag'
churn.rename(columns={'churn_event_id':'churn_id',
                              'reason_code':'reason',
                              'refund_amount_usd':'refund',
                              'preceding_upgrade_flag':'preceding_upgrade',
                              'preceding_downgrade_flag':'preceding_downgrade',
                              'is_reactivation':'reactivated'}, inplace=True)


#check data validity by column
# churn_id : check duplicates
print("\n churn id validation")
print(f"Duplicate values: {churn['churn_id'].duplicated().sum()}")

#validity date validity check for churn_date
print("\n validity check for columns with dates")
print("churn_date validity :") 
print(validate_date_format(churn,'churn_date'))

#reason: check values in the column
print("\n reason code validation")
print(f"list of reasons: {churn['reason'].unique()}")

#refund: check if values or equal to or bigger than zero
print("\n refund non-negative value check")
print(validate_non_negative_int(churn, 'refund'))

# Save cleaned data
churn.to_csv('cleaned_data/churn_cleaned.csv', index=False)
print("\n=== Data Cleaning Completed and cleaned data file is made===")
