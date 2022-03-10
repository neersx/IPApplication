if exists (select * from sysobjects where type='TR' and name = 'UpdateCASEINDEXES_OFFICIALNUMBERS')
begin
	PRINT 'Refreshing trigger UpdateCASEINDEXES_OFFICIALNUMBERS...'
	DROP TRIGGER UpdateCASEINDEXES_OFFICIALNUMBERS
end
go
	
Create trigger UpdateCASEINDEXES_OFFICIALNUMBERS on OFFICIALNUMBERS for UPDATE NOT FOR REPLICATION as
-- TRIGGER:	UpdateCASEINDEXES_OFFICIALNUMBERS    
-- VERSION:	7
-- DESCRIPTION:	

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 			8883 	1	Created
-- 24-OCT-2006	MF	13706	2	Remove additional row with non alpha numerics stripped out
-- 11-FEB-2008	MF	RFC6191	3	Generic Index stored as UPPER case.
-- 27-MAY-2009	MF	17730	4	Numeric only version of official number is now stored. 
--					Also remove restriction for IP Office number types.
-- 05-Jun-2009	MF	17766	5	Strip leading and trailing spaces
-- 23-Jun-2015	MZ	47863	6	Convert new PCT new format to old short format
-- 23-Aug-2016	MF	65601	7	Check for existing CASEINDEXES row with leading and trailing spaces removed.

Begin
	If UPDATE ( OFFICIALNUMBER )
	Begin
		------------------------------------------------------------
		-- Remove the old CASEINDEXES for the updated OfficialNumber
		-- if there is no other OfficialNumber requiring this index
		------------------------------------------------------------
		Delete CASEINDEXES
		from CASEINDEXES CI
		join deleted d	on (d.CASEID=CI.CASEID
				and rtrim(ltrim(UPPER(d.OFFICIALNUMBER)))=CI.GENERICINDEX)
		left join OFFICIALNUMBERS N on (N.CASEID=CI.CASEID
					    and rtrim(ltrim(UPPER(N.OFFICIALNUMBER)))=CI.GENERICINDEX)
		where CI.SOURCE=5
		and N.CASEID is null
		
		Delete CASEINDEXES
		from CASEINDEXES CI
		join deleted d	on (d.CASEID=CI.CASEID
				and dbo.fn_StripNonAlphaNumerics(UPPER(d.OFFICIALNUMBER))=CI.GENERICINDEX)
		left join OFFICIALNUMBERS N on (N.CASEID=CI.CASEID
					    and dbo.fn_StripNonAlphaNumerics(UPPER(N.OFFICIALNUMBER))=CI.GENERICINDEX)
		where CI.SOURCE=5
		and N.CASEID is null
		
		Delete CASEINDEXES
		from CASEINDEXES CI
		join deleted d	on (d.CASEID=CI.CASEID
				and dbo.fn_StripNonNumerics(d.OFFICIALNUMBER)=CI.GENERICINDEX)
		left join OFFICIALNUMBERS N on (N.CASEID=CI.CASEID
					    and dbo.fn_StripNonNumerics(N.OFFICIALNUMBER)=CI.GENERICINDEX)
		where CI.SOURCE=5
		and N.CASEID is null

		Delete CASEINDEXES
		from CASEINDEXES CI
		join deleted d	on (d.CASEID=CI.CASEID
				and dbo.fn_ConvertToPctShortFormat(d.OFFICIALNUMBER)=CI.GENERICINDEX)
		left join OFFICIALNUMBERS N on (N.CASEID=CI.CASEID
						and dbo.fn_ConvertToPctShortFormat(N.OFFICIALNUMBER)=CI.GENERICINDEX)
		where CI.SOURCE=5
		and N.CASEID is null
		------------------------------------------------------------
		-- Insert the new CASEINDEXES for the updated OfficialNumber
		-- if there is no available matching CASEINDEX already
		------------------------------------------------------------
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
End
go
