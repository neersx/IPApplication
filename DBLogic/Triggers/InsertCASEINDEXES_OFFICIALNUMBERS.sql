if exists (select * from sysobjects where type='TR' and name = 'InsertCASEINDEXES_OFFICIALNUMBERS')
begin
	PRINT 'Refreshing trigger InsertCASEINDEXES_OFFICIALNUMBERS...'
	DROP TRIGGER InsertCASEINDEXES_OFFICIALNUMBERS
end
go

Create trigger InsertCASEINDEXES_OFFICIALNUMBERS on OFFICIALNUMBERS for INSERT NOT FOR REPLICATION as
Begin
-- TRIGGER:	InsertCASEINDEXES_OFFICIALNUMBERS    
-- VERSION:	7
-- DESCRIPTION:	

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 			8883 	1	Created
-- 24-OCT-2006	MF	13706	2	Insert addition row with non alpha numerics stripped out
-- 11-FEB-2008	MF	RFC6191	3	Store generic index in UPPER case.
-- 27-MAY-2009	MF	17730	4	Numeric only version of official number is now stored.
--					Also remove restriction for IP Office number types.
-- 05-Jun-2009	MF	17766	5	Strip leading and trailing spaces
-- 23-Jun-2015	MZ	47863	6	Convert new PCT new format to old short format
-- 23-Aug-2016	MF	65601	7	Check for existing CASEINDEXES row with leading and trailing spaces removed.
	Insert  into CASEINDEXES (GENERICINDEX, CASEID, SOURCE)
	Select 	rtrim(ltrim(UPPER(i.OFFICIALNUMBER))), i.CASEID, 5 
	from 	inserted i
	left join CASEINDEXES CI on (CI.CASEID=i.CASEID
				 and CI.GENERICINDEX=rtrim(ltrim(UPPER(i.OFFICIALNUMBER)))
				 and CI.SOURCE=5)
	where i.OFFICIALNUMBER is not null
	and  CI.CASEID is null
	UNION
	Select 	dbo.fn_StripNonAlphaNumerics(UPPER(i.OFFICIALNUMBER)), i.CASEID, 5 
	from 	inserted i
	left join CASEINDEXES CI on (CI.CASEID=i.CASEID
				 and CI.GENERICINDEX=dbo.fn_StripNonAlphaNumerics(UPPER(i.OFFICIALNUMBER))
				 and CI.SOURCE=5)
	where i.OFFICIALNUMBER is not null
	and  CI.CASEID is null
	UNION
	Select 	dbo.fn_StripNonNumerics(i.OFFICIALNUMBER), i.CASEID, 5 
	from 	inserted i
	left join CASEINDEXES CI on (CI.CASEID=i.CASEID
				 and CI.GENERICINDEX=dbo.fn_StripNonNumerics(i.OFFICIALNUMBER)
				 and CI.SOURCE=5)
	where len(dbo.fn_StripNonNumerics(i.OFFICIALNUMBER))>0
	and  CI.CASEID is null
	UNION
	Select 	dbo.fn_ConvertToPctShortFormat(i.OFFICIALNUMBER), i.CASEID, 5 
	from 	inserted i
	left join CASEINDEXES CI on (CI.CASEID=i.CASEID
				 and CI.GENERICINDEX=dbo.fn_ConvertToPctShortFormat(i.OFFICIALNUMBER)
				 and CI.SOURCE=5)
	where len(dbo.fn_ConvertToPctShortFormat(i.OFFICIALNUMBER))>0
	and  CI.CASEID is null
End
go
