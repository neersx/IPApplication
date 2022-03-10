	/******************************************************************************************************************/
	/*** 7921 Create DeleteNAME trigger										***/
	/******************************************************************************************************************/     
	if exists (select * from sysobjects where type='TR' and name = 'DeleteNAME')
   		begin
    		 PRINT 'Refreshing trigger DeleteNAME...'
    		 DROP TRIGGER DeleteNAME
   		end
  	go

	create trigger DeleteNAME on NAME for DELETE NOT FOR REPLICATION as
		begin

    		 /* NAME in relation to ACTIVITY ON PARENT DELETE CASCADE */
    		 delete ACTIVITY
      		 from 	ACTIVITY, deleted
      		 where	ACTIVITY.RELATEDNAME = deleted.NAMENO

    		 /* NAME R/180 BILLFORMAT ON PARENT DELETE CASCADE */
    		 delete BILLFORMAT
      		 from 	BILLFORMAT,deleted
      		 where 	BILLFORMAT.EMPLOYEENO = deleted.NAMENO

    		 /* NAME R/60 DISCOUNT ON PARENT DELETE CASCADE */
    		 delete DISCOUNT
      		 from 	DISCOUNT,deleted
      		 where 	DISCOUNT.EMPLOYEENO = deleted.NAMENO

    		 /* NAME R/170 MARGIN ON PARENT DELETE CASCADE */
    		 delete MARGIN
      		 from MARGIN,deleted
      		 where MARGIN.DEBTOR = deleted.NAMENO

		end
	go

