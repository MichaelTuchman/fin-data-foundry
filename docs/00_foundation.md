Step 0 - Foundation Checklist

□ AWS account exists
□ User has S3 permissions
□ User has Athena permissions
□ S3 bucket exists : 


□ Athena database exists

Within Athena, in a query window, execute the query "create database "finances", although it does not literally need to be called this.  But whatever
name you choose, specify it is the default database to AThena.  This means you don't need to put the dependency in your
source files.

□ Repository cloned
□ Raw data location created

Then within the bucket set up raw, then a sub-bucket for each bank, then a sub-bucket of each bank for each account

□ Metadata files uploaded

- accounts.csv 
- layouts.csv 
- layout_cols.csv 

□ Metadata tables created 

- metadata_accounts 
- metadata_layouts 
- metadata_layout_cols 




