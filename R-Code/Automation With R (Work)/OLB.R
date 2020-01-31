#Script to run andrews daily OLB 
setwd("C:/Users/dcontento/Desktop/Weekly/AndrewOLB")
library(RODBC)
#create a script that pulls sql data, cleans it up, and sends to through mail (automating data pulls into table like OLB)
#automate using windows task scheduler 
dbconnection <-odbcDriverConnect('driver={SQL Server Native Client 11.0};server=sqlprd-anl;database=Retail;trusted_connection=yes') 
df <- sqlQuery(dbconnection,paste("insert into retail.dbo.af_olbcurrent
                                    
                                    select new.*
                                    from
                                    (
                                    	select *
                                    	from
                                    		(
                                    		select customernumber,
                                    			   datefromparts(left(rowprocessedthru,4),substring(rowprocessedthru,5,2),right(rowprocessedthru,2)) OLBDate, -- convert rowprocesseddate to a date format
                                    			   case when UF03L05 in ('B01','B02','B03','C01','C02','C03','H01') then 1 else 0 end as [OLBFlag]
                                    		from marketdata.dbo.customeruserdefinedfielddaily
                                    		) final
                                    		where olbflag = 1
                                    	) new
                                    	left join retail.dbo.af_olbcurrent cur
                                    	on cur.customernumber = new.customernumber
                                    where cur.customernumber is null -- new customers with the olbflag that did not already exist in the olbcurrent table"), as.is=T)
close(dbconnection)   

