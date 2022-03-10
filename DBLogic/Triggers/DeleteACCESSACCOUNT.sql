	/**********************************************************************************************************/
	/*** 7921 Create DeleteACCESSACCOUNT trigger								***/
	/**********************************************************************************************************/     
	if exists (select * from sysobjects where type='TR' and name = 'DeleteACCESSACCOUNT')
   		begin
    		 PRINT 'Refreshing trigger DeleteACCESSACCOUNT...'
    		 DROP TRIGGER DeleteACCESSACCOUNT
   		end
  	go

	create trigger DeleteACCESSACCOUNT on ACCESSACCOUNT for DELETE NOT FOR REPLICATION as
		begin
		 /* ACCESSACCOUNT R/1030 USERIDENTITY ON PARENT DELETE CASCADE */
		 delete USERIDENTITY
		 from 	USERIDENTITY,deleted
		 where  USERIDENTITY.ACCOUNTID = deleted.ACCOUNTID
		end
	go
