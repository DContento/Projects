Here are some examples of some SQL Queries that I created in order to pull data from our data warehouse. These queries involved the cleaning, scrubbing, and joining of several different data sets. 

1. B2BTableV5: Involves looking at several tables containing small business loan/line application information. Due to the nature of how the B2B application system works (E.G. Counteroffers are coded as separate products) some adjustements have to be made in the tables to account. Missing information such IPV and Vantage scores had to be imputed in some cases. 

2. Loan Application WTD: Takes credit card, business, PUL, PCL, HELOC/EEX, and other consumer production application information from several different sources (some from our EDW and some which is manually uploaded). 
