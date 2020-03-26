#BUSINESS BANKING REPORTS 
setwd("C:/Users/dcontento/Desktop/Weekly/Bbanking")
library(RODBC)
library(XLConnect)
#create a script that pulls sql data, cleans it up, and sends to through mail (automating data pulls into table like OLB)
#automate using windows task scheduler 
dbconnection <-odbcDriverConnect('driver={SQL Server Native Client 11.0};server=sqlprd-anl;database=MarketData;trusted_connection=yes') 
df <- sqlQuery(dbconnection,paste("declare @sdate as date = '",Sys.Date()-9,"' -- inclusive start date
                                   declare @edate as date = '",Sys.Date()-3,"' -- inclusive end date
                                  
                                  
                                  select details.*,
                                  OLBFlag
                                  from
                                  (
                                  
                                  -- Details
                                  
                                  select a360.customernumber,
                                  a360.accountnumber,
                                  cad.customerfullname,
                                  a360.BranchId,
                                  branch.Branch BranchName,
                                  branch.RegionLevel1 Region,
                                  a360.DateOpen,
                                  aad.SellerEmployeeNum,
                                  edw.FirstName + ' ' + edw.LastName SellerName,
                                  a360.productcode,
                                  a360.productdescription,
                                  a360.balance,
                                  case when cad.customerfullname like '%rlt%' then 1 
                                  when cad.customerfullname like '%estate%' then 1 
                                  when cad.customerfullname like '%trust%' then 1 
                                  when cad.customerfullname like '%revocable%' then 1 
                                  when cad.customerfullname like '%rvc%' then 1
                                  when cad.customerfullname like '%rvoc%' then 1
                                  when cad.customerfullname like '%tst%' then 1
                                  when cad.customerfullname like '%livtr%' then 1
                                  when cad.customerfullname like '%revtr%' then 1
                                  else 0 end as TrustEstateFlag
                                  from
                                  (
                                  
                                  select customernumber,
                                  accountnumber,
                                  DateOpen,
                                  BranchID,
                                  ProductCode,
                                  ProductDescription,
                                  Balance
                                  from asb360accountdaily
                                  where majorgrouping in ('20','25')
                                  and dateopen >= @sdate
                                  and dateopen <= @edate
                                  and flagprimary = 1
                                  and flagowner = 1
                                  ) a360
                                  left join accountattributesdaily aad on aad.AccountNumberCore = a360.accountnumber
                                  left join customeruserdefinedfielddaily udf on udf.customernumber = a360.customernumber
                                  left join customerattributesdaily cad on cad.Customer# = a360.customernumber
                                  left join employeeEDW edw on edw.EmployeeNumber*1 = aad.SellerEmployeeNum*1
                                  left join branchedw branch on branch.BranchId = a360.BranchId
                                  ) details
                                  
                                  left join
                                  (
                                  ----------------- ONLINE BANKING ------------------
                                  
                                  select distinct AccountNumber,
                                  case when sum(AnyCustomerOLBFlag) >= 1 then 1
                                  else 0 end as OLBFlag
                                  from
                                  (
                                  select allcustomers.CustomerNumber,
                                  allcustomers.accountnumber,
                                  allcustomers.relationship,
                                  case when udf.UF03L05 in ('B01','B02','B03','C01','C02','C03','H01') then 1
                                  else 0 end as AnyCustomerOLBFlag -- finding all related customers per checking account
                                  from
                                  (
                                  
                                  select distacct.AccountNumber,
                                  cust.CustomerNumber,
                                  cust.relationship
                                  from
                                  (
                                  select distinct accountnumber
                                  from asb360accountdaily
                                  where majorgrouping in ('20','25')
                                  and dateopen >= @sdate
                                  and dateopen <= @edate
                                  and flagprimary = 1
                                  and flagowner = 1
                                  ) distAcct 
                                  left join
                                  (
                                  select distinct customernumber,
                                  accountnumber,
                                  Relationship
                                  from asb360accountdaily
                                  ) cust  
                                  on cust.accountnumber = distacct.accountnumber
                                  ) allcustomers
                                  left join CustomerUserDefinedFieldDaily udf on udf.customernumber = allcustomers.CustomerNumber
                                  ) olbdetails
                                  group by AccountNumber
                                  ) olb
                                  on olb.accountnumber = details.accountnumber
                                  
                                  order by dateopen"), as.is=T)
close(dbconnection)   

wb=loadWorkbook("BusinessBankingChecking_TEMPLATE.xlsx", create = TRUE)
writeWorksheet(wb,df,"Details",startRow = 2, startCol = 1, header = FALSE)
saveWorkbook(wb,"BusinessBankingChecking_xlsx.xlsx")
