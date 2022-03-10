/**********************************************************************************************************/
/*** Creation of trigger tI_CASECATEGORY 								***/
/**********************************************************************************************************/     
if exists (select * from sysobjects where type='TR' and name = 'tI_CASECATEGORY')
begin
	PRINT 'Refreshing trigger tI_CASECATEGORY...'
	DROP TRIGGER tI_CASECATEGORY
end
go

CREATE TRIGGER tI_CASECATEGORY on CASECATEGORY for INSERT NOT FOR REPLICATION as
-- TRIGGER :	tI_CASECATEGORY
-- VERSION :	1
-- DESCRIPTION:	Whenever a CaseCategory is added, check to see if the CaseType has been used
--		with a draft Case Type and if so then automatically insert the CaseCategory
--		for the draft.
-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 19 Oct 2006	MF	12413 		Trigger Created

Begin
	insert into CASECATEGORY(CASETYPE, CASECATEGORY, CASECATEGORYDESC, CONVENTIONLITERAL)
	select CT.CASETYPE, CC.CASECATEGORY, CC.CASECATEGORYDESC, CC.CONVENTIONLITERAL
	from inserted CC
	join CASETYPE CT 		on (CT.ACTUALCASETYPE=CC.CASETYPE)
	left join CASECATEGORY CC1	on (CC1.CASETYPE=CT.CASETYPE
					and CC1.CASECATEGORY=CC.CASECATEGORY)
	where CC1.CASETYPE is null
End
go
