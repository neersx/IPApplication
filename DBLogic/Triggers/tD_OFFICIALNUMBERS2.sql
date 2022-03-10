	/**********************************************************************************************************/
	/*** Creation of trigger tD_OFFICIALNUMBERS2 								***/
	/**********************************************************************************************************/     
	if exists (select * from sysobjects where type='TR' and name = 'tD_OFFICIALNUMBERS2')
	begin
    	 	PRINT 'Refreshing trigger tD_OFFICIALNUMBERS2...'
    		DROP TRIGGER tD_OFFICIALNUMBERS2
	end
	go
	
	CREATE TRIGGER tD_OFFICIALNUMBERS2 on OFFICIALNUMBERS for DELETE NOT FOR REPLICATION as
	-- TRIGGER :	tD_OFFICIALNUMBERS2
	-- VERSION :	2
	-- DESCRIPTION:	Whenever an official number is modified if there is a corresponding CPA Format 
	--		of that official number then the CPA Format will be deleted.  This then triggers 
	--		CPA into providing an updated official number in a subsequent update.

	-- MODIFICATIONS :
	-- Date		Who	Change	Version	Description
	-- -----------	-------	------	-------	----------------------------------------------- 
	--			8365 		Trigger Created
	-- 28 Jul 2004	MF	10273	2	Poorly written trigger was inefficient and also causing the same trigger 
	--					to fire which resulted in an error
	Begin
		if (select count(*) from deleted where NUMBERTYPE in ('A','C','P','R')) >0
		Begin
			delete OFFICIALNUMBERS
			from OFFICIALNUMBERS O
			join deleted D	on (D.CASEID=O.CASEID)
			where O.NUMBERTYPE=	CASE(D.NUMBERTYPE)
							WHEN('A') THEN '6' -- Application No
							WHEN('C') THEN '7' -- Acceptance No
							WHEN('P') THEN '8' -- Publication No
							WHEN('R') THEN '9' -- Registration No
						END
		End
	End
	go
