import pandas as pd
import os

input_filename = 'apollo-accounts-export (1).csv'

print("🔄 Step 1: Loading your Apollo file...")
if not os.path.exists(input_filename):
    print(f"❌ Error: Could not find '{input_filename}' in this folder. Make sure the file name matches perfectly!")
    exit()

raw_df = pd.read_csv(input_filename)
print(f"✅ Loaded {len(raw_df)} accounts successfully.")

print("⚙️ Step 2: Cleaning account profile data...")
dim_accounts = raw_df[[
    'Apollo Account Id', 'Company Name', 'Account Stage', 
    'Industry', 'Founded Year', 'Website', 
    'Company Country', 'Company State', 'Company City'
]].drop_duplicates()

print("⚙️ Step 3: Extracting and cleaning financial metrics...")
fact_account_metrics = raw_df[[
    'Apollo Account Id', '# Employees', 'Annual Revenue', 
    'Total Funding', 'Latest Funding Amount'
]].copy()
fact_account_metrics.rename(columns={'# Employees': 'employee_count'}, inplace=True)

def extract_bridge_tables(dataframe, source_column, new_name):
    unique_items = set()
    mappings = []
    for _, row in dataframe.iterrows():
        acc_id = row['Apollo Account Id']
        raw_text = row[source_column]
        if pd.notna(raw_text):
            items_list = [item.strip() for item in str(raw_text).split(',') if item.strip()]
            for item in items_list:
                unique_items.add(item)
                mappings.append({'apollo_account_id': acc_id, f'{new_name}_name': item})
    dim_df = pd.DataFrame({f'{new_name}_name': sorted(list(unique_items))})
    dim_df[f'{new_name}_id'] = dim_df.index + 1
    bridge_df = pd.DataFrame(mappings)
    bridge_df = bridge_df.merge(dim_df, on=f'{new_name}_name')[['apollo_account_id', f'{new_name}_id']]
    return dim_df, bridge_df

print("⚙️ Step 4: Normalizing messy 'Technologies' column...")
dim_technologies, bridge_account_tech = extract_bridge_tables(raw_df, 'Technologies', 'tech')

print("⚙️ Step 5: Normalizing messy 'Keywords' column...")
dim_keywords, bridge_account_keywords = extract_bridge_tables(raw_df, 'Keywords', 'keyword')

print("💾 Step 6: Saving structured spreadsheets...")
dim_accounts.to_csv('sql_dim_accounts.csv', index=False)
fact_account_metrics.to_csv('sql_fact_metrics.csv', index=False)
dim_technologies.to_csv('sql_dim_technologies.csv', index=False)
bridge_account_tech.to_csv('sql_bridge_account_tech.csv', index=False)
dim_keywords.to_csv('sql_dim_keywords.csv', index=False)
bridge_account_keywords.to_csv('sql_bridge_account_keywords.csv', index=False)

print("\n🎉 ALL DONE! Check your folder for the 6 new, clean data files.")