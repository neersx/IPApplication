	/**********************************************************************************************************/
	/*** 7921 Create DeleteUSERIDENTITY trigger								***/
	/**********************************************************************************************************/     
	if exists (select * from sysobjects where type='TR' and name = 'DeleteUSERIDENTITY')
   		begin
    		 PRINT 'Refreshing trigger DeleteUSERIDENTITY...'
    		 DROP TRIGGER DeleteUSERIDENTITY
   		end
  	go

	create trigger DeleteUSERIDENTITY on USERIDENTITY for DELETE NOT FOR REPLICATION as
		begin
		 /* USERIDENTITY R/1170 QUERYDEFAULT ON PARENT DELETE CASCADE */
		 delete QUERYDEFAULT
		 from 	QUERYDEFAULT,deleted
		 where	QUERYDEFAULT.IDENTITYID = deleted.IDENTITYID		
		end
	go
