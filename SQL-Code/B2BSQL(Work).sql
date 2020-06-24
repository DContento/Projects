use MarketData

if object_id('tempdb..#Temporary') is not null
drop table #Temporary
select distinct app.ApplicationID, 
				rep.B2BProduct, 
				rep.Decision, 
				prod.AuthorizedAmount, 
				prod.ProductID, 
				rep.SubmittedDate,
				Case when (
						(select count(ApplicationID) from B2BBusiness z)>1) 
						      then (select top 1 BBReportPulledDate 
							  from B2BBusiness j 
							  where j.ApplicationID=bus.ApplicationID
							  and j.BUSLIABILITYTYPE LIKE '%bor%'
							  order by collationindex desc)
					else BBReportPulledDate end as bb,  
				rep.AppDecisionDate, 
				rep.AppCompletedDate,
				DATEDIFF(DAY,rep.SubmittedDate,bus.BBReportPulledDate) SubmitToCreditTime,
				DATEDIFF(DAY,bus.BBReportPulledDate,APP.DecisionDate) CreditToDecisionTime,
				DATEDIFF(DAY,APP.DecisionDate,rep.BookedDecisionDate) DecisionToBookTime,
				DATEDIFF(DAY,rep.BookedDecisionDate, rep.AppCompletedDate) BookToCompleteTime, 
				case when (ConsumerScore is null) then (select top 1 ConsumerScore 
														from B2BReport rep2 
														where ConsumerScore is not null 
															  and ApplicationID=rep.ApplicationID 
													    )
					 else ConsumerScore end as ConsumerScore, 
				case when (BusinessScore is Null) then (select top 1 BusinessScore 
														from B2BReport rep2 
														where BusinessScore is not null 
															  and ApplicationID=rep.ApplicationID 
													   )
					 else BusinessScore end as BusinessScore,  
				case when (VantageBand like '%Missing%') then (select top 1 VantageBand 
															 from B2BReport rep2 
															 where VantageBand not like '%Missing%'
																   and rep2.ApplicationID=app.ApplicationID 
															)
					 else VantageBand end as VantageBand,  
				case when (IPV2Band like '%Missing%') then (select top 1 IPV2Band 
														  from B2BReport rep2 
														  where IPV2Band not like '%Missing%'
																and  rep2.ApplicationID=app.ApplicationID 
														  )
					else IPV2Band end as IPV2Band, 
				case when (SICNAICSCodeDescription is Null) then (select top 1 SICNAICSCodeDescription 
														from B2BBusiness bus2 
														where SICNAICSCodeDescription is not null 
															  and NAICSCode=bus.NAICSCode 
													   ) --Possibly add order by collationindex
					 else SICNAICSCodeDescription end as SICNAICSCodeDescription,  
				case when (NAICSCode is Null) then (select top 1 NAICSCode 
														from B2BBusiness bus2 
														where NAICSCode is not null 
															  and bus2.ApplicationID=rep.ApplicationID 
													   ) --Possibly add order by collationindex
					 when app.ApplicationID='1040172' then '999999' 
					 else NAICSCode end as NAICSCode,  
				Case When (DeclineReason1 is Null AND rep.Decision like 'Decline') then (select top 1 DeclineReason1 
																						 from B2BProduct prod2 
																						 where DeclineReason1 is not null 
																							   and ApplicationID=prod.ApplicationID 
																							   and ProductID>prod.ProductID 
																						 order by collationindex asc)
						  else DeclineReason1 end as DeclineReason, 
				prod.CreditPolicyDeclineReason1, 
				prod.ApproveOverrideReason, 
				prod.DeclineOverrideReason,
				prod.BookedDecisionDate,
				CONVERT(nvarchar(2), LEFT(NAICSCode,2)) IndustryCode
INTO #Temporary  --Throwing into Temporary Table to that I can use the case when creditpull statement in a datediff function later
from B2BReport rep

LEFT JOIN B2BApplication app on app.ApplicationID=rep.ApplicationID
LEFT JOIN B2BBusiness bus on bus.ApplicationID=rep.ApplicationID
LEFT JOIN B2BProduct prod on prod.ProductID=rep.ProductID
where rep.submitteddate is not null 
	  and rep.AppDecisionDate >= '2019-01-01' 
	  and rep.AppDecisionDate<= '2019-12-31'
	  and BUSLIABILITYTYPE like '%Bor%' 
	  --	    and app.ApplicationID in ('1040217','1040365','1040366','1040364')
order by app.ApplicationID, prod.ProductID, rep.AppDecisionDate desc

update #Temporary
set NAICSCode = '999999', IndustryCode='99'
where ApplicationID = '1040172'

select distinct ApplicationID, 
	   (B2BProduct) Product, 
	   Decision, 
	   AuthorizedAmount,
	   ProductID, 
	   SubmittedDate, 
	   Convert(varchar(10),bb,23)  CreditPulledDate, 
	   AppDecisionDate,
	   Convert(varchar(10),BookedDecisionDate,23) BookedDecisionDate,
	   AppCompletedDate, 				
	   DATEDIFF(DAY, SubmittedDate, bb) SubmitToCreditTime,
	   DATEDIFF(DAY, bb, AppDecisionDate) CreditToDecisionTime,
	   DATEDIFF(DAY,AppDecisionDate, BookedDecisionDate) DecisionToBookTime,
	   DATEDIFF(DAY, BookedDecisionDate, AppCompletedDate) BookToCompleteTime,
	   ConsumerScore,
	   BusinessScore,
	   VantageBand,
	   IPV2Band,
	   isnull(NAICSCode, 'Missing') NAICSCode,
	   isnull((ret.[desc]),'Missing') GeneralIndustry,
	   isnull(SICNAICSCodeDescription,'Missing') SpecificIndustry,
	   DeclineReason, 
	   CreditPolicyDeclineReason1,
	   ApproveOverrideReason,
	   Case When Decision like 'Approve' then 1 
	   when Decision like 'Decline' then 0
	   else 3 End as ApproveIndicator,
	   Case When B2BProduct in ('Term Loan - Unsecured (Promo)' , 'Term Loan - Unsecured') Then 'Unsecured Term'
	   When B2BProduct in ('Cash Secured Term Loan','Term Loan - Secured','Secured Term Loan') then 'Secured Term'
	   When B2BProduct in ('ProTec Line','Unsecured Line of Credit') Then 'Unsecured LOC'
	   when B2BProduct in ('Secured Line of Credit') Then 'Secured LOC'
	   Else 'SBA' End as GeneralProduct
from #Temporary
	LEFT JOIN Retail.dbo.naics_2017 ret on ret.code=#Temporary.IndustryCode
order by ApplicationID, ProductID, AppDecisionDate asc

--------------- VALIDATION -------------------
declare @app as varchar(7) = '1033040'
select * from b2breport where ApplicationID = @app
select * from b2bapplication where ApplicationID = @app
select * from B2BProduct where ApplicationID = @app
select BBReportPulledDate, * from b2bbusiness where ApplicationID = @app
select * from b2bprincipal where ApplicationID = @app
