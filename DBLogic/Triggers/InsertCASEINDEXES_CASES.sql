if exists (select * from sysobjects where type='TR' and name = 'InsertCASEINDEXES_CASES')
begin
	PRINT 'Refreshing trigger InsertCASEINDEXES_CASES...'
	DROP TRIGGER InsertCASEINDEXES_CASES
end
go

Create trigger InsertCASEINDEXES_CASES on CASES	for INSERT NOT FOR REPLICATION as
	Begin
-- TRIGGER:	InsertCASEINDEXES_CASES    
-- VERSION:	6
-- DESCRIPTION:	

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 			8883 	1	Created
-- 11-FEB-2008	MF	R6191	2	Store generic index in UPPER case.
-- 17-APR-2008	MF	S16272	3	Check for existence of CASEINDEXES row
-- 05-Feb-2010	MF	R8881	4	Change <GENERATE REFERENCE> to <Generate Reference>
-- 06-Mar-2014	MF	R31402	5	Include STEM in the CASEINDEX.  Also remove UPPER as databases
--					must now  be case insensitive.
-- 03-Jul-2019	MF	DR-50036 6	Include FAMILYTITLE associated with CaseFamily only when different to FAMILY.
	
		-- SQA9650: (tI_UniqueCaseReference)
		Insert into CASEINDEXES (GENERICINDEX, CASEID, SOURCE)
	  	Select distinct i.IRN, i.CASEID, 1 
		from inserted i
		left join CASEINDEXES CI on (CI.CASEID=i.CASEID
					and  CI.SOURCE=1)
		where i.IRN<>'<Generate Reference>'
		and CI.CASEID is null
		
		-- SQA9650: No check required as it is only possible to have one title per case
		Insert into CASEINDEXES (GENERICINDEX, CASEID, SOURCE)
  		Select i.TITLE, i.CASEID, 2 
		from inserted i
		left join CASEINDEXES CI on (CI.CASEID=i.CASEID
					and  CI.SOURCE=2) 
		where i.TITLE is not null
		and CI.CASEID is null

		-- SQA9650: No check required as it is only possible to have one family per case
		Insert into CASEINDEXES (GENERICINDEX, CASEID, SOURCE)
  		Select i.FAMILY, i.CASEID, 3
		from inserted i
		left join CASEINDEXES CI on (CI.CASEID=i.CASEID
					and  CI.SOURCE=3) 
		where i.FAMILY is not null
		and CI.CASEID is null
		UNION
  		Select CF.FAMILYTITLE, i.CASEID, 3
		from inserted i
		join CASEFAMILY CF	 on (CF.FAMILY=i.FAMILY
					and  CF.FAMILY<>CF.FAMILYTITLE)
		left join CASEINDEXES CI on (CI.CASEID=i.CASEID
					and  CI.SOURCE=3) 
		where i.FAMILY is not null
		and CF.FAMILYTITLE<>CF.FAMILY
		and CI.CASEID is null

		-- RFC31402: Insert the STEM up to the ~ delimiter
		Insert into CASEINDEXES (GENERICINDEX, CASEID, SOURCE)
  		Select LEFT(i.STEM,CASE WHEN(PATINDEX('%~%',i.STEM)>1) THEN PATINDEX('%~%',i.STEM)-1 ELSE LEN(i.STEM) END ), i.CASEID, 6
		from inserted i
		left join CASEINDEXES CI on (CI.CASEID=i.CASEID
					and  CI.SOURCE=6) 
		where i.STEM not like '~%'  -- first character of stem is not tilde
		and CI.CASEID is null
	End
go
