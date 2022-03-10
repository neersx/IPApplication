	/******************************************************************************************************************/
	/*** 10040 Create DeleteLETTER trigger										***/
	/******************************************************************************************************************/     
	if exists (select * from sysobjects where type='TR' and name = 'DeleteLETTER')
   		begin
    		 PRINT 'Refreshing trigger DeleteLETTER...'
    		 DROP TRIGGER DeleteLETTER
   		end
  	go

	create trigger DeleteLETTER on LETTER for DELETE NOT FOR REPLICATION as
		begin
    		 /* LETTER changed to LETTERSUBSTITUTE ON PARENT DELETE CASCADE */
    		 delete LETTERSUBSTITUTE
      		 from 	LETTERSUBSTITUTE,deleted
      		 where 	LETTERSUBSTITUTE.ALTERNATELETTER = deleted.LETTERNO
		end
	go

