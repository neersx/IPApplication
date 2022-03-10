if exists (select * from sysobjects where type='TR' and name = 'InsertCASEINDEXES_RELATEDCASE')
begin
	PRINT 'Refreshing trigger InsertCASEINDEXES_RELATEDCASE...'
	DROP TRIGGER InsertCASEINDEXES_RELATEDCASE
end
go

Create trigger InsertCASEINDEXES_RELATEDCASE on RELATEDCASE for INSERT NOT FOR REPLICATION as
Begin
-- TRIGGER:	InsertCASEINDEXES_RELATEDCASE    
-- VERSION:	2
-- DESCRIPTION:	

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 27 May 2016	MF	60784	1	Created
-- 21 Jul 2016	MF	64531	2	Strip leading and trailing spaces from Official Number when
--					checking for existing CASEINDEXES row.

	Insert  into CASEINDEXES (GENERICINDEX, CASEID, SOURCE)
	Select 	rtrim(ltrim(i.OFFICIALNUMBER)), i.CASEID, 7 
	from 	inserted i
	left join CASEINDEXES CI on (CI.CASEID=i.CASEID
				 and CI.GENERICINDEX=rtrim(ltrim(i.OFFICIALNUMBER))
				 and CI.SOURCE=7)
	where i.OFFICIALNUMBER is not null
	and  CI.CASEID is null
	UNION
	Select 	dbo.fn_StripNonAlphaNumerics(i.OFFICIALNUMBER), i.CASEID, 7 
	from 	inserted i
	left join CASEINDEXES CI on (CI.CASEID=i.CASEID
				 and CI.GENERICINDEX=dbo.fn_StripNonAlphaNumerics(i.OFFICIALNUMBER)
				 and CI.SOURCE=7)
	where i.OFFICIALNUMBER is not null
	and  CI.CASEID is null
	UNION
	Select 	dbo.fn_StripNonNumerics(i.OFFICIALNUMBER), i.CASEID, 7 
	from 	inserted i
	left join CASEINDEXES CI on (CI.CASEID=i.CASEID
				 and CI.GENERICINDEX=dbo.fn_StripNonNumerics(i.OFFICIALNUMBER)
				 and CI.SOURCE=7)
	where len(dbo.fn_StripNonNumerics(i.OFFICIALNUMBER))>0
	and  CI.CASEID is null
	UNION
	Select 	dbo.fn_ConvertToPctShortFormat(i.OFFICIALNUMBER), i.CASEID, 7 
	from 	inserted i
	left join CASEINDEXES CI on (CI.CASEID=i.CASEID
				 and CI.GENERICINDEX=dbo.fn_ConvertToPctShortFormat(i.OFFICIALNUMBER)
				 and CI.SOURCE=7)
	where len(dbo.fn_ConvertToPctShortFormat(i.OFFICIALNUMBER))>0
	and  CI.CASEID is null
End
go
