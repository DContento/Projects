These files are some examples of tasks/reports which were automated using R and SQL.

BizBankingMonday-
Uses some packages that allows R to connect to our EDW sql server using an ODBC connection. This allows me to use SQL in my
R script to pull data and store the results as variables. I am then able to use the XLConnect package and paste this data into a template and rename it. The query used in the R script is dynamic and pulls data from the previous Monday to last Friday. This job is intiated by a batchfile which is set to run using windows task scheduler.

EEXPULL & OLB-
Are SQL queries that are imbedded in an r script which are set to run from a batch file. These queries pull data from our EDW and store them in specific tables. These were used temporarily as a way to capture daily changes in online banking (OLB) preferences for our
customers. The EEXPULL data was used to pull EEX applications and their status daily so that we could monitor the progression of our home 
equity applications.

Example of Batch- Text file which shows the command that was used to execute the R script which was located in the batch file. 
