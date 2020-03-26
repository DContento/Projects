setwd("C:/Users/dcontento/Desktop/Weekly/Weekly EEX pipeline Data")
library(RODBC)
library(XLConnect)
#create a script that pulls sql data, cleans it up, and sends to through mail (automating data pulls into table like OLB)
#automate using windows task scheduler 
dbconnection <- odbcConnect('sqlprd-anl')
df <- sqlQuery(dbconnection,paste("use MarketData 
                                  select replicate('0',4-len(branch#))+SUBSTRING(branch#, CHARINDEX(' ',branch#)+1, 3) branch#
                                  , cast(AppInitiatedDate as date) Appcreationdate, a.Appnbr, b.Name, Emp#, [Employee Name],appstatus,
                                  CASE WHEN NbrLoanReview = 1 THEN LnAmtReview
                                  WHEN NbrConditionalApproval = 1 THEN ConditionalAppAmt
                                  WHEN NbrFinalApproved = 1 THEN LnAmtFinalApproved
                                  ELSE 'Error' end as Amount
                                  INTO #temp --inserting into temp table to filter on case when columns later. 
                                  FROM LnApplication a
                                  
                                  LEFT JOIN lnapplicant b ON a.appnbr=b.appnbr 
                                  LEFT JOIN (SELECT appnbr, [Employee Name], Emp# from (
                                  SELECT appnbr, CASE WHEN len(SellerEmpNbr) = 4 THEN '0' + SellerEmpNbr
                                  ELSE SellerEmpNbr end as Emp# from LnApplication) x LEFT JOIN (select [Empl ID] Sell#,
                                  CASE WHEN [Preferred Name] = '' THEN ([First Name]+ ' ' + [Last Name])
                                  ELSE ([Preferred Name] + ' ' + [Last Name]) end as [Employee Name]
                                  from Retail.dbo.CL_emp) y on x.Emp#=y.Sell# ) z ON z.AppNbr=a.AppNbr
                                  LEFT JOIN (select appnbr, RIGHT(distributionchannel,(CHARINDEX('-',REVERSE(distributionchannel),0))-1) branch# FROM LnApplication) v
                                  on v.appnbr=a.appnbr
                                  
                                  WHERE VendorProductCode = 108 
                                  AND AppInitiatedDate >= '2013-01-01'
                                  AND SourceChannel not in ('Consumer Loans - 2400','Commercial Loans - 2700')
                                  AND (NbrFinalApproved = '1'
                                  OR NbrLoanReview = '1'
                                  OR NbrConditionalApproval = '1') 
                                  AND appinitiateddate >= dateadd(day,-120,getdate()) -- Loan Applications only exist 120 days after created
                                  AND (sellerempnbr != 0 OR sellerempnbr IS NULL)
                                  AND relationship='Primary Applicant'
                                  AND branch != 'Commercial Banking Center'
                                  ORDER BY Appnbr ASC"))
                                  
                                  
df <- sqlQuery(dbconnection,paste("SELECT CASE WHEN branch# in ('007','009','010','028','031','038','052','053','067','069','071','075','083') THEN 'East Oahu Region' 
                                  WHEN branch# in ('002','055','017','051','016') THEN 'Hawaii Region'
                                  WHEN branch# in ('012','013','063','092') THEN 'Kauai Region'
                                  WHEN branch# in ('020','021','022','023','024','025','101','105') THEN 'Maui/Molokai Region' 
                                  WHEN branch# in ('004','005','006','029','039','060','065','066','068','076','081','082','103') THEN 'Metro Oahu Region'
                                  WHEN branch# in ('008','026','033','035','037','056','057','062','073','077','078','084','087','104') THEN 'West Oahu Region'
                                  ELSE 'NULL' end as Region, branch#,
                                  CASE WHEN branch# IN ('002') THEN 'Hilo'
                                  WHEN branch# IN ('005','065') THEN 'Kapiolani'
                                  WHEN branch# IN ('006') THEN 'Waikiki'
                                  WHEN branch# IN ('007') THEN 'Windward City'
                                  WHEN branch# IN ('008') THEN 'Mililani SC'
                                  WHEN branch# IN ('009','071') THEN 'Kaimuki SC'
                                  WHEN branch# IN ('010') THEN 'Campus'
                                  WHEN branch# IN ('013') THEN 'Hanapepe'
                                  WHEN branch# IN ('016') THEN 'Kealakekua'
                                  WHEN branch# IN ('017') THEN 'Kailua-Kona'
                                  WHEN branch# IN ('020') THEN 'Pukalani'
                                  WHEN branch# IN ('021','101') THEN 'Kahului'
                                  WHEN branch# IN ('022') THEN 'Wailuku'
                                  WHEN branch# IN ('023') THEN 'Lahaina'
                                  WHEN branch# IN ('024') THEN 'Molokai'
                                  WHEN branch# IN ('025') THEN 'Kihei'
                                  WHEN branch# IN ('026') THEN 'Wahiawa'
                                  WHEN branch# IN ('028') THEN 'Kailua'
                                  WHEN branch# IN ('029') THEN 'Pearlridge'
                                  WHEN branch# IN ('031') THEN 'Hawaii Kai'
                                  WHEN branch# IN ('033') THEN 'Ewa'
                                  WHEN branch# IN ('035') THEN 'Pearl City'
                                  WHEN branch# IN ('037') THEN 'Waipahu'
                                  WHEN branch# IN ('038') THEN 'Makiki'
                                  WHEN branch# IN ('039') THEN 'Salt Lake'
                                  WHEN branch# IN ('051') THEN 'Waimea'
                                  WHEN branch# IN ('052') THEN 'Main'
                                  WHEN branch# IN ('053') THEN 'Manoa'
                                  WHEN branch# IN ('055') THEN 'Prince Kuhio'
                                  WHEN branch# IN ('056') THEN 'Haleiwa'
                                  WHEN branch# IN ('057') THEN 'Mililani TC'
                                  WHEN branch# IN ('060') THEN 'Liliha'
                                  WHEN branch# IN ('062') THEN 'Kapolei'
                                  WHEN branch# IN ('063','012') THEN 'Hokulei Village'
                                  WHEN branch# IN ('066') THEN 'Chinatown'
                                  WHEN branch# IN ('067') THEN 'Kahala'
                                  WHEN branch# IN ('068','04') THEN 'Kamehameha SC'
                                  WHEN branch# IN ('069') THEN 'Kaneohe'
                                  WHEN branch# IN ('073') THEN 'Laie'
                                  WHEN branch# IN ('075') THEN 'Market City Fdld'
                                  WHEN branch# IN ('076') THEN 'McCully'
                                  WHEN branch# IN ('078','104') THEN 'Pearl City'
                                  WHEN branch# IN ('081') THEN 'Queen Ward'
                                  WHEN branch# IN ('082') THEN 'Stadium SnS'
                                  WHEN branch# IN ('083') THEN 'UH Campus'
                                  WHEN branch# IN ('084','077') THEN 'Waianae'
                                  WHEN branch# IN ('087') THEN 'Waipio Gentry Fdld'
                                  WHEN branch# IN ('092') THEN 'Waipouli Fdld'
                                  WHEN branch# IN ('103') THEN 'Honolulu Walmart'
                                  WHEN branch# IN ('105') THEN 'Kehalani Fdld'
                                  ELSE 'ERROR' end as [Branch Name],appcreationdate,Appnbr, Name, Emp#, [Employee Name], appstatus, Amount  FROM #temp
                                  where amount is not null --picking up some nulls
                                  order by appnbr ASC
                                  
                                  DROP TABLE #temp"))
close(dbconnection)

#df$`branch#`=sprintf("%03d",df$`branch#`)

wb=loadWorkbook("yyyymmdd_EEX Pipeline Report.xlsx", create = TRUE)
writeWorksheet(wb,df,"Detail",startRow = 4, startCol = 1, header = FALSE)
saveWorkbook(wb,"yyyymmdd_EEX Pipeline Report (auto).xlsx")


