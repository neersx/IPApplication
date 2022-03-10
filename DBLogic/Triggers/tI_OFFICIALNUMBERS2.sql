	/**********************************************************************************************************/
	/*** Creation of trigger tI_OFFICIALNUMBERS2 								***/
	/**********************************************************************************************************/     
	if exists (select * from sysobjects where type='TR' and name = 'tI_OFFICIALNUMBERS2')
	begin
  		PRINT 'Refreshing trigger tI_OFFICIALNUMBERS2...'
		DROP TRIGGER tI_OFFICIALNUMBERS2
	end
	go

	CREATE TRIGGER tI_OFFICIALNUMBERS2 on OFFICIALNUMBERS for INSERT NOT FOR REPLICATION as
	-- TRIGGER :	tI_OFFICIALNUMBERS2
	-- VERSION :	3
	-- DESCRIPTION:	Whenever an official number is modified if there is a corresponding CPA Format 
	--		of that official number then the CPA Format will be deleted.  This then triggers 
	--		CPA into providing an updated official number in a subsequent update.

	-- MODIFICATIONS :
	-- Date		Who	Change	Version	Description
	-- -----------	-------	------	-------	----------------------------------------------- 
	--			8365 		Trigger Created
	-- 28 Jul 2004	MF	10273	2	Poorly written trigger was inefficient and also causing the same trigger 
	--					to fire which resulted in an error
	-- 10 Feb 2006	MF	12291	3	Only attempt delete if rows exist.
	Begin
		if exists
		   (	select 1 
			from inserted I
			join OFFICIALNUMBERS O	on (O.CASEID=I.CASEID
						and O.NUMBERTYPE=CASE(I.NUMBERTYPE)
									WHEN('A') THEN '6' -- Application No
									WHEN('C') THEN '7' -- Acceptance No
									WHEN('P') THEN '8' -- Publication No
									WHEN('R') THEN '9' -- Registration No
								END)
			)
		Begin
			delete OFFICIALNUMBERS
			from OFFICIALNUMBERS O
			join inserted I	on (I.CASEID=O.CASEID)
			where O.NUMBERTYPE=	CASE(I.NUMBERTYPE)
							WHEN('A') THEN '6' -- Application No
							WHEN('C') THEN '7' -- Acceptance No
							WHEN('P') THEN '8' -- Publication No
							WHEN('R') THEN '9' -- Registration No
						END
		End
	End
	go
