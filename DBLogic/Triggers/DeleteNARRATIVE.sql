	/******************************************************************************************************************/
	/*** 10045 Create DeleteNARRATIVE trigger									***/
	/******************************************************************************************************************/     
	if exists (select * from sysobjects where type='TR' and name = 'DeleteNARRATIVE')
   		begin
    		 PRINT 'Refreshing trigger DeleteNARRATIVE...'
    		 DROP TRIGGER DeleteNARRATIVE
   		end
  	go

	create trigger DeleteNARRATIVE on NARRATIVE for DELETE NOT FOR REPLICATION as
		begin
    		 /* NARRATIVE changed to NARRATIVESUBSTITUT ON PARENT DELETE CASCADE */
    		 delete	NARRATIVESUBSTITUT
      		 from 	NARRATIVESUBSTITUT,deleted
      		 where  NARRATIVESUBSTITUT.ALTERNATENARRATIVE = deleted.NARRATIVENO
		end
	go

