	/******************************************************************************************************************/
	/*** 7021 Create DeleteQUERY trigger										***/
	/******************************************************************************************************************/     
	if exists (select * from sysobjects where type='TR' and name = 'DeleteQUERY')
   		begin
    		 PRINT 'Refreshing trigger DeleteQUERY...'
    		 DROP TRIGGER DeleteQUERY
   		end
  	go

	create trigger DeleteQUERY on QUERY for DELETE NOT FOR REPLICATION as
		begin
		 /* QUERY R/1171 QUERYDEFAULT ON PARENT DELETE CASCADE */
		 delete QUERYDEFAULT
		 from 	QUERYDEFAULT,deleted
		 where	QUERYDEFAULT.QUERYID = deleted.QUERYID
		end
	go

