	/******************************************************************************************************************/
	/*** 10038 Create Delete COUNTRY trigger									***/
	/******************************************************************************************************************/     
	if exists (select * from sysobjects where type='TR' and name = 'DeleteCOUNTRY')
		begin
	    	 PRINT 'Refreshing trigger DeleteCOUNTRY...'
	    	 DROP TRIGGER DeleteCOUNTRY
	   	end
	go
	
	Create trigger DeleteCOUNTRY on COUNTRY for DELETE NOT FOR REPLICATION as 
		Begin

    		 /* COUNTRY is part of COUNTRYGROUP ON PARENT DELETE CASCADE */
    		 delete COUNTRYGROUP
      		 from 	COUNTRYGROUP,deleted
      		 where	(COUNTRYGROUP.MEMBERCOUNTRY = deleted.COUNTRYCODE
		 	OR COUNTRYGROUP.TREATYCODE = deleted.COUNTRYCODE)

		 delete MARGIN
      		 from 	MARGIN,deleted
      		 where 	MARGIN.DEBTORCOUNTRY = deleted.COUNTRYCODE

	   	End
	go
