-- This SQL query attempts to mirror the current Weekly Loan App Reports from Cognos and includes credit card application data.

-- Checking Loan App tables latest date
select cast(max(lnappdate) as date) MaxRetailLoan from lnapplication
select max(submitteddate) MaxBizLoan from B2BReport

-- Setting date variables
/* Last Week Start */ declare @sdate as date = cast(getdate() - datepart((dw),getdate()) - 7 as date)
/* Last Week End   */ declare @enddate as date = cast(dateadd((dd),-3,dateadd((wk),datediff((wk),0,getdate()),0) ) as date)
-- select @sdate
-- select @enddate

select RetailBizLoans.AppNbr,
	   RetailBizLoans.CustomerName,
	   RetailBizLoans.[DBA PlaceHolder] DBA,
	   RetailBizLoans.VendorProductCode,
			case when RetailBizLoans.VendorProductCode = 108 then 1 else 0 end as EEXCount,
			case when RetailBizLoans.VendorProductCode = 107 then 1 else 0 end as PULCount,
			case when RetailBizLoans.VendorProductCode in (131,134) then 1 else 0 end as CleanEnergyCount,
			case when RetailBizLoans.VendorProductCode = 110 then 1 else 0 end as PCLCount,
			case when RetailBizLoans.VendorProductCode = 112 then 1 else 0 end as SavingsSecuredCount,
			case when RetailBizLoans.VendorProductCode > 9999999 then 1 else 0 end as BizCount,
			case when RetailBizLoans.VendorProductCode = 9999 then 1 else 0 end as CCCount,
			case when (RetailBizLoans.VendorProductCode not in (107,108,110,112,131,134,9999) and RetailBizLoans.VendorProductCode < 9999999) then 1 else 0 end as OtherCount,
	   RetailBizLoans.VendorProductDesc,
	   RetailBizLoans.AmtRequested,
	   RetailBizLoans.LnAmtFunded,
	   RetailBizLoans.Region,
	   RetailBizLoans.Branch,
	   RetailBizLoans.SellerEmpNbr,
	   case when SellerEmpNbr = 99999 then 'Credit Card Seller'
		    else seller.FirstName + ' ' + seller.LastName
			end as [SellerName],
	   RetailBizLoans.AppInputByCode,
	   case when AppInputByCode = 99999 then 'Credit Card Referrer'
		    else inputby.FirstName + ' ' + inputby.LastName 
			end as [InputBy],
	   RetailBizLoans.AppInitiatedDate,
	   RetailBizLoans.DecisionStatusName,
	   RetailBizLoans.AppStatus,
			case when RetailBizLoans.AppStatus in ('Denied','Decline') then 1 else 0 end as DeclinedCount,
			case when RetailBizLoans.AppStatus in ('In Review','Counteroffer') then 1 else 0 end as InReviewCount,
			case when (RetailBizLoans.AppStatus in ('Funded', 'Final Approved', 'Conditional Approval', 'Approve') 
					  or (RetailBizLoans.AppStatus in ('Withdrawn') and RetailBizLoans.DecisionStatusName = 'Aprvd. Rejected by Applicant')) then 1 else 0 end as ApprovedCount,
			case when RetailBizLoans.AppStatus in ('Funded') then 1 else 0 end as FundedCount,
	   case when RetailBizLoans.AppStatus = 'Funded' then RetailBizLoans.LnAccountNumber else '' end as LnAccountNumber,
	   case when coalesce(ReAcStat.accountstatus, BizAcStat.accountstatus) is null then '' else coalesce(ReAcStat.accountstatus, BizAcStat.accountstatus) end as AccountStatus,						  
	   RetailBizLoans.DeclineReason1
from
(
-- **********************************************************************************
-- ******************* BEGIN THE UNION OF RETAIL AND BUSINESS LOANS *****************
-- **********************************************************************************
select appcust.AppNbr,
	   appcust.CustomerName,
	   '' [DBA PlaceHolder],
	   appcust.VendorProductCode,
	   appcust.VendorProductDesc,
	   appcust.AmtRequested,
	   appcust.LnAmtFunded,
	   case when appcust.branch in ('Windward City SC', 'Kaimuki SC', 'Campus', 'Kailua', 'Hawaii Kai', 'Makiki', 'Main', 'Manoa', 'Kahala', 'Kaneohe', 'Kapahulu', 'Market City Foodland', 'UH Campus') then 'East Oahu Region'
			when appcust.branch in ('Hilo', 'Kealakekua', 'Kailua-Kona', 'WAIMEA', 'Prince Kuhio') then 'Hawaii Region'
			when appcust.branch in ('Lihue', 'Hanapepe', 'Hokulei Village', 'Waipouli Foodland') then 'Kauai Region'
			when appcust.branch in ('Pukalani', 'Kahului', 'Wailuku', 'Lahaina', 'Molokai', 'Kihei', 'Kahului Walmart', 'Kehalani Foodland') then 'Maui/Molokai Region'
			when appcust.branch in ('Kalihi', 'Kapiolani', 'Waikiki', 'Pearlridge', 'Salt Lake SC', 'Liliha', 'Chinatown', 'Kamehameha SC', 'Mccully', 'Queen Ward', 'Stadium Sack N Save', 'Honolulu Walmart') then 'Metro Oahu Region'
			when appcust.branch in ('Mililani SC', 'Wahiawa', 'Ewa', 'Pearl City', 'Wapahu Town Center', 'Haleiwa', 'Mililani Town Center', 'Kapolei', 'Laie Foodland', 'Nanakuli Sack N Save', 'Pearl City Foodland', 'Waianae', 'Waipahu', 'Waipio Gentry Food', 'Pearl City Walmart') then 'West Oahu Region'
			else 'Could Not Find Region - Please Contact Retail Admin'
				 end as Region,
	   appcust.Branch,
	   distinctSeller.SellerEmpNbr,
	   '' [SELLERNAME PLACEHOLDER],
	   distinctSeller.SellerEmpNbr [AppInputByCode],
	   '' [AppInputByUserName PLACEHOLDER],
	   cast(appcust.AppInitiatedDate as date) [AppInitiatedDate],
	   appcust.DecisionStatusName,
	   appcust.AppStatus,
	   case when decline.ReasonName is null then '' else decline.ReasonName end as [DeclineReason1],
	   case when appcust.LnAccountNumber is null then '' else appcust.LnAccountNumber end as LnAccountNumber,
	   '' [ACCOUNT STATUS PLACEHOLDER]
from
	(
	select app.*,
		   cust.CustomerName
	from
		(
	-- Retail Loan Apps 
		select *
		from lnapplication 
		where cast(lnappdate as date) between @sdate and @enddate
			  and DistributionChannel != 'Internet Application'
			  and VendorProductCode != 111
			  and (AppStatus in ('Funded','Final Approved','Conditional Approval','In Review','Denied') or (AppStatus = 'Withdrawn' and DecisionStatusName = 'Aprvd. Rejected by Applicant'))
			  and SourceChannel not in ('Commercial Private Banking - 1800','Consumer Loans - 2400','Internet Application','CBC')
			  and (SellerEmpNbr is null or SellerEmpNbr not in ('08876','04060','10415','10617','06536','08448','07932')) -- 8876 = Chuck Dando,  4060 = Chereen,  10415 = Cyn,  10617 = Jason Laz, 6536 = Lance, 8448 = Lana, 7932 = Kimmie
		) app
	left join
		(
		-- Retail Loan Applicant
		select distinct appnbr,
			   [Name] CustomerName
		from lnapplicant
		where relationship = 'Primary Applicant'
		) cust
	on app.appnbr = cust.appnbr
	) appcust
	-- Will find the correct seller if multiple products are on the same application and seller # is only entered once.
	left join
		(
		select distinct appnbr,
						SellerEmpNbr
			   from lnapplication
			   where sellerempnbr is not null
		) distinctSeller
	on appcust.AppNbr = distinctSeller.AppNbr
left join
	(
	-- Selecting Declination Reason
	select r1.*,
		   r2.ReasonName
	from
		(
		select distinct AppDetailNbr,
						min(reasonid) [FirstReason]
		from LnAppReasonCode
		group by AppDetailNbr
		) r1
	left join 
		(
		select distinct reasonid,
						reason ReasonName
		from LnAppReasonCode
		) r2
	on r1.FirstReason = r2.ReasonID
	) decline
on decline.AppDetailNbr = appcust.AppDetailNbr
where appcust.SellerEmpNbr is not null
	  or (1 = case when (appcust.SellerEmpNbr is null and appcust.AppStatus = 'Funded') then 1 else 0 end) -- See note at the bottom of script.

union all

-- ************************************************************
-- ******************* BUSINESS LOANS *************************
-- ************************************************************

select ApplicationID,
	   LegalName,
	   DBA,
	   b2bdetails.ProductID,
	   B2BProduct,
	   RequestedAmount,
	   case when b2bauthorizedamt.AuthorizedAmount is null then 0 else b2bauthorizedamt.AuthorizedAmount end as AuthorizedAmount, 
	   region,
	   branch,
	   relationshipmanagerUserCode,
	   [RelationshipManagerName Placeholder],
	   inputbyUserCode,
	   [InputByUserName Placeholder],
	   SubmittedDate,
	   AppStatusDetail,
	   Decision,
	   DeclineReason1,
	   CleanLoanNumber,
	   [Account Status Placeholder]
from
(
select b2bAll.ApplicationID,
	   LegalName,
	   DBA,
	   B2BAll.ProductID,
	   B2BProduct,
	   RequestedAmount,
	   0 [AuthorizedAmount Placeholder], -- just a placeholder before the join with B2BProduct
	   region,
	   branch,
	   relationshipmanagerUserCode,
	   '' [RelationshipManagerName Placeholder],
	   inputbyUserCode,
	   '' [InputByUserName Placeholder],
	   SubmittedDate,
	   case when AppStatusDetail = 'No Decision' then 'In Review' else AppstatusDetail end as AppStatusDetail,
	   case when decision is null then 'In Review' else Decision end as Decision,
	   case when b2bReason.DeclineReason1 is null then '' else b2breason.DeclineReason1 end as DeclineReason1,
	   case when b2bAll.CleanLoanNumber is null then '' else b2bAll.CleanLoanNumber end as CleanLoanNumber,
	   '' [Account Status Placeholder]
from
(
select b2bappReport.*,
	   b2bcust.LegalName,
	   b2bcust.DBA
from
(
select B2BReport.*,
	   B2bApp.branch,
	   B2bApp.region,
	   B2bApp.InputByUserCode,
	   B2bApp.RelationshipManagerUserCode
from
	(
	select * 
	from B2BReport 
	where submitteddate between @sdate and @enddate
		  and (BRMvsBranch != 'BRM' or OfficerID in ('12722','13127','11134')) -- 12722 = Trini AbayaWright |  13127 = Johnny He | 11134 = Kassie Zott.  Their loan applications are submitted as referrals from the branch.
	) b2breport
left join
	( 
	select applicationid,
		   CASE WHEN businessunitusercode in ('007','009', '010', '0010','028','031','038','052','053','067','069','071','075','083') THEN 'East Oahu Region' 
				     WHEN businessunitusercode in ('002','055','017','051','016') THEN 'Hawaii Region'
					 WHEN businessunitusercode in ('012','013','063','092') THEN 'Kauai Region'
					 WHEN businessunitusercode in ('020','021','022','023','024','025','101','105') THEN 'Maui/Molokai Region' 
					 WHEN businessunitusercode in ('004','005','006','029','039','060','065','066','068','076','081','082','103') THEN 'Metro Oahu Region'
					 WHEN businessunitusercode in ('008','026','033','035','037','056','057','062','073','077','078','084','087','104') THEN 'West Oahu Region'
					 ELSE 'BBD' end as Region,
		   case when businessUnitUserCode in ('0010','010') then 'CAMPUS'
				when businessUnitUserCode = '002' then 'HILO'
				when businessUnitUserCode = '004' then 'KALIHI'
				when businessUnitUserCode = '005' then 'KAPIOLANI'
				when businessUnitUserCode = '006' then 'WAIKIKI'
				when businessUnitUserCode = '007' then 'WINDWARD CITY SC'
				when businessUnitUserCode = '012' then 'LIHUE'
				when businessUnitUserCode = '013' then 'HANAPEPE'
				when businessUnitUserCode = '016' then 'KEALAKEKUA'
				when businessUnitUserCode = '017' then 'KAILUA-KONA'
				when businessUnitUserCode = '002' then 'HILO'
				when businessUnitUserCode = '020' then 'PUKALANI'
				when businessUnitUserCode = '021' then 'KAHULUI'
				when businessUnitUserCode = '022' then 'WAILUKU'
				when businessUnitUserCode = '023' then 'LAHAINA'
				when BusinessUnitUserCode = '024' then 'MOLOKAI'
				when businessUnitUserCode = '025' then 'KIHEI'
				when businessUnitUserCode = '026' then 'WAHIAWA'
				when businessUnitUserCode = '028' then 'KAILUA'
				when businessUnitUserCode = '029' then 'PEARLRIDGE'
				when businessUnitUserCode = '031' then 'HAWAII KAI'
				when businessUnitUserCode = '033' then 'EWA'
				when businessUnitUserCode = '035' then 'PEARL CITY'
				when businessUnitUserCode = '037' then 'WAIPAHU'
				when businessUnitUserCode = '038' then 'MAKIKI'
				when businessUnitUserCode = '039' then 'SALT LAKE SC'
				when businessUnitUserCode = '004' then 'KALIHI'
				when businessUnitUserCode = '005' then 'KAPIOLANI'
				when businessUnitUserCode = '051' then 'WAIMEA'
				when businessUnitUserCode = '052' then 'MAIN'
				when businessUnitUserCode = '053' then 'MANOA'
				when businessUnitUserCode = '055' then 'PRINCE KUHIO'
				when businessUnitUserCode = '056' then 'HALEIWA'
				when businessUnitUserCode = '057' then 'MILILANI TOWN CENTER'
				when businessUnitUserCode = '006' then 'WAIKIKI'
				when businessUnitUserCode = '060' then 'LILIHA'
				when businessUnitUserCode = '062' then 'KAPOLEI'
				when businessUnitUserCode = '063' then 'HOKULEI VILLAGE'
				when businessUnitUserCode = '065' then 'KAPIOLANI'
				when businessUnitUserCode = '066' then 'CHINATOWN'
				when businessUnitUserCode = '067' then 'KAHALA'
				when businessUnitUserCode = '068' then 'KAMEHAMEHA SC'
				when businessUnitUserCode = '069' then 'KANEOHE'
				when businessUnitUserCode = '007' then 'WINDWARD CITY SC'
				when businessUnitUserCode = '071' then 'KAPAHULU'
				when businessUnitUserCode = '073' then 'LAIE FOODLAND'
				when businessUnitUserCode = '075' then 'MARKET CITY FOODLAND'
				when businessUnitUserCode = '076' then 'MCCULLY'
				when businessUnitUserCode = '077' then 'NANAKULI SACK N SAVE'
				when businessUnitUserCode = '078' then 'PEARL CITY FOODLAND'
				when businessUnitUserCode = '008' then 'MILILANI SC'
				when businessUnitUserCode = '081' then 'QUEEN WARD'
				when businessUnitUserCode = '082' then 'STADIUM SACK N SAVE'
				when businessUnitUserCode = '083' then 'UH CAMPUS'
				when businessUnitUserCode = '084' then 'WAIANAE'
				when businessUnitUserCode = '087' then 'WAIPIO GENTRY FOOD'
				when businessUnitUserCode = '009' then 'KAIMUKI SC'
				when businessUnitUserCode = '092' then 'WAIPOULI FOODLAND'
				when businessUnitUserCode = '101' then 'KAHULUI WALMART'
				when businessUnitUserCode = '103' then 'HONOLULU WALMART'
				when businessUnitUserCode = '104' then 'PEARL CITY WALMART'
				when businessUnitUserCode = '105' then 'KEHALANI FOODLAND' else businessUnitUserCode end branch ,
		   InputByUserCode,
		   RelationshipManagerUserCode
	from b2bapplication 
	) b2bapp
on b2bapp.ApplicationID = b2breport.ApplicationID
) b2bappReport
left join
	(
	select applicationid,
		   legalname,
		   dba
	from B2BBusiness
	) b2bcust
on b2bappreport.applicationid = b2bcust.applicationid
) b2bAll
left join 
(
select distinct productID,
	   DeclineReason1
from B2BProduct
) b2bReason
on b2breason.productID = b2bAll.applicationid
) b2bDetails
left join
(
select productid,
	   authorizedamount
from b2bproduct
) b2bauthorizedamt
on b2bauthorizedamt.productid = b2bdetails.productid
where isnumeric(InputbyUserCode) = 1  -- removes loans from WEBAPPUSER
	  and decision != 'Withdraw'
	  and inputbyusercode not in ('07897', '05856') -- 7897 = Lucy Wong Commercial Private Banking, 5856 = Lucy Hwa Private Banking

union all

-- ************************************************************
-- ******************* CREDIT CARD APPS ***********************
-- ************************************************************
select 0 [AppNbr],
	   'Credit Card Customers' CustomerNamePlaceholder,
	   '' [DBA],
	   9999 [ProductCode], -- Setting Credit Cards = product code # 9999
	   /* 0 [EEX],
	   0 [PUL],
	   0 [CleanEnergy],
	   0 [PCL],
	   0 [SS],
	   0 [Biz],
	   0 [Other],
	   apps [CCAppCount], */
	   CONS_COMM_IND [ProductDesc],
	   app_credit_limit [AmtRequested],
	   app_credit_limit [AmtFunded],
	   CASE WHEN Sub_Agnt_bank_nbr in ('007','009','010','0010','028','031','038','052','053','067','069','071','075','083') THEN 'East Oahu Region' 
		    WHEN Sub_Agnt_bank_nbr  in ('002','055','017','051','016') THEN 'Hawaii Region'
			WHEN Sub_Agnt_bank_nbr  in ('012','013','063','092') THEN 'Kauai Region'
			WHEN Sub_Agnt_bank_nbr  in ('020','021','022','023','024','025','101','105') THEN 'Maui/Molokai Region' 
		    WHEN Sub_Agnt_bank_nbr  in ('004','005','006','029','039','060','065','066','068','076','081','082','103') THEN 'Metro Oahu Region'
			WHEN Sub_Agnt_bank_nbr  in ('008','026','033','035','037','056','057','062','073','077','078','084','087','104') THEN 'West Oahu Region'
			ELSE 'Could Not Find Region - check credit card data' end as Region,
	   CASE WHEN sub_agnt_bank_nbr in ('0010','010') then 'CAMPUS'
				when sub_agnt_bank_nbr = '002' then 'HILO'
				when sub_agnt_bank_nbr = '004' then 'KALIHI'
				when sub_agnt_bank_nbr = '005' then 'KAPIOLANI'
				when sub_agnt_bank_nbr = '006' then 'WAIKIKI'
				when sub_agnt_bank_nbr = '007' then 'WINDWARD CITY SC'
				when sub_agnt_bank_nbr = '012' then 'LIHUE'
				when sub_agnt_bank_nbr = '013' then 'HANAPEPE'
				when sub_agnt_bank_nbr = '016' then 'KEALAKEKUA'
				when sub_agnt_bank_nbr = '017' then 'KAILUA-KONA'
				when sub_agnt_bank_nbr = '002' then 'HILO'
				when sub_agnt_bank_nbr = '020' then 'PUKALANI'
				when sub_agnt_bank_nbr = '021' then 'KAHULUI'
				when sub_agnt_bank_nbr = '022' then 'WAILUKU'
				when sub_agnt_bank_nbr = '023' then 'LAHAINA'
				when sub_agnt_bank_nbr = '024' then 'MOLOKAI'
				when sub_agnt_bank_nbr = '025' then 'KIHEI'
				when sub_agnt_bank_nbr = '026' then 'WAHIAWA'
				when sub_agnt_bank_nbr = '028' then 'KAILUA'
				when sub_agnt_bank_nbr = '029' then 'PEARLRIDGE'
				when sub_agnt_bank_nbr = '031' then 'HAWAII KAI'
				when sub_agnt_bank_nbr = '033' then 'EWA'
				when sub_agnt_bank_nbr = '035' then 'PEARL CITY'
				when sub_agnt_bank_nbr = '037' then 'WAIPAHU'
				when sub_agnt_bank_nbr = '038' then 'MAKIKI'
				when sub_agnt_bank_nbr = '039' then 'SALT LAKE SC'
				when sub_agnt_bank_nbr = '004' then 'KALIHI'
				when sub_agnt_bank_nbr = '005' then 'KAPIOLANI'
				when sub_agnt_bank_nbr = '051' then 'WAIMEA'
				when sub_agnt_bank_nbr = '052' then 'MAIN'
				when sub_agnt_bank_nbr = '053' then 'MANOA'
				when sub_agnt_bank_nbr = '055' then 'PRINCE KUHIO'
				when sub_agnt_bank_nbr = '056' then 'HALEIWA'
				when sub_agnt_bank_nbr = '057' then 'MILILANI TOWN CENTER'
				when sub_agnt_bank_nbr = '006' then 'WAIKIKI'
				when sub_agnt_bank_nbr = '060' then 'LILIHA'
				when sub_agnt_bank_nbr = '062' then 'KAPOLEI'
				when sub_agnt_bank_nbr = '063' then 'HOKULEI VILLAGE'
				when sub_agnt_bank_nbr = '065' then 'KAPIOLANI'
				when sub_agnt_bank_nbr = '066' then 'CHINATOWN'
				when sub_agnt_bank_nbr = '067' then 'KAHALA'
				when sub_agnt_bank_nbr = '068' then 'KAMEHAMEHA SC'
				when sub_agnt_bank_nbr = '069' then 'KANEOHE'
				when sub_agnt_bank_nbr = '007' then 'WINDWARD CITY SC'
				when sub_agnt_bank_nbr = '071' then 'KAPAHULU'
				when sub_agnt_bank_nbr = '073' then 'LAIE FOODLAND'
				when sub_agnt_bank_nbr = '075' then 'MARKET CITY FOODLAND'
				when sub_agnt_bank_nbr = '076' then 'MCCULLY'
				when sub_agnt_bank_nbr = '077' then 'NANAKULI SACK N SAVE'
				when sub_agnt_bank_nbr = '078' then 'PEARL CITY FOODLAND'
				when sub_agnt_bank_nbr = '008' then 'MILILANI SC'
				when sub_agnt_bank_nbr = '081' then 'QUEEN WARD'
				when sub_agnt_bank_nbr = '082' then 'STADIUM SACK N SAVE'
				when sub_agnt_bank_nbr = '083' then 'UH CAMPUS'
				when sub_agnt_bank_nbr = '084' then 'WAIANAE'
				when sub_agnt_bank_nbr = '087' then 'WAIPIO GENTRY FOOD'
				when sub_agnt_bank_nbr = '009' then 'KAIMUKI SC'
				when sub_agnt_bank_nbr = '092' then 'WAIPOULI FOODLAND'
				when sub_agnt_bank_nbr = '101' then 'KAHULUI WALMART'
				when sub_agnt_bank_nbr = '103' then 'HONOLULU WALMART'
				when sub_agnt_bank_nbr = '104' then 'PEARL CITY WALMART'
				when sub_agnt_bank_nbr = '105' then 'KEHALANI FOODLAND' 
				else sub_agnt_bank_nbr end branch ,
			CASE WHEN EMPL_ID is null then 9999
				 WHEN LEN(EMPL_ID) >= 4 THEN EMPL_ID 
				 ELSE 99999 
					END AS [Seller#],
			'' [CC Seller Placeholder],
		    CASE WHEN (LEN(RFRING_EMPL_ID) < 4 and LEN(EMPL_ID) >= 4) THEN EMPL_ID
				 WHEN  LEN(RFRING_EMPL_ID) >= 4 THEN RFRING_EMPL_ID 
				 ELSE 99999 
					END AS [RFRING_EMPL_ID],		
			'' [CC Referring Placeholder],
			cast(ADJDICAT_DT as date) [AppDate],
			CASE WHEN Approved >= 1 then 'Approved'
				 WHEN Rejected >= 1 then 'Declined'
				 WHEN Withdrawn >= 1 then 'Withdrawn'
				 ELSE 'In Review'
					END AS [DecisionStatusName],
			CASE WHEN accounts >= 1 then 'Funded'
				 WHEN approved >= 1 and (accounts is null) then 'Final Approved'
				 WHEN rejected >= 1 then 'Denied'
				 WHEN Withdrawn >= 1 then 'Withdrawn'
				 else 'In Review' 
					END AS [AppStatus],
			'' LNAcctNumberHolder,
			'' AccountStatusHolder,
			'' DeclineReasonHolder
from retail.dbo.af_cc
where cast([sub_agnt_bank_nbr] as int) between 2 and 105
	  and cast(adjdicat_dt as date) >= @sdate
	  and cast(adjdicat_dt as date) <= @enddate



) RetailBizLoans
-- **********************************************************************************
-- ************************ END UNION OF RETAIL AND BUSINESS LOANS ******************
-- **********************************************************************************

left join EmployeeEdw seller on seller.employeenumber*1 = RetailBizLoans.SellerEmpNbr
left join EmployeeEdw inputby on inputby.employeenumber*1 = RetailBizLoans.AppInputByCode
left join AccountAttributesDaily ReAcStat on ReAcStat.AccountNumber = RetailBizLoans.LnAccountNumber
left join AccountAttributesDaily BizAcStat on ReAcStat.AccountNumberCore = RetailBizLoans.LnAccountNumber

order by AppInitiatedDate asc, appnbr desc
;

/* Note:  When a customer applies for multiple Retail products on the same loan application,
		  the SellerEmpNbr only appears once.  There are cases where multiple accounts
		  are opened off of a single application.  In the original Loan App Report, 
		  if a single application results in more than one account being opened, the application
		  is counted as many times as unique accounts are opened.  
		  Example:  Loan app # 254689 resulted in two different accounts being funded: 
				1)  PLOC account # 4000584427
				2)  Savings secured # 4000584450

		  If multiple products are applied for on the same application, but the application
		  is denied, then the application is only counted as one denied application.
*/ 