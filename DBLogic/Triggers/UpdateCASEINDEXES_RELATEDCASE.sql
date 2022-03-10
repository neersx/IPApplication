if exists (select * from sysobjects where type='TR' and name = 'UpdateCASEINDEXES_RELATEDCASE')
begin
	PRINT 'Refreshing trigger UpdateCASEINDEXES_RELATEDCASE...'
	DROP TRIGGER UpdateCASEINDEXES_RELATEDCASE
end
go
	
Create trigger UpdateCASEINDEXES_RELATEDCASE on RELATEDCASE for UPDATE NOT FOR REPLICATION as
-- TRIGGER:	UpdateCASEINDEXES_RELATEDCASE    
-- VERSION:	2
-- DESCRIPTION:	

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 27 May 2016	MF	60784	1	Created
-- 21 Jul 2016	MF	64531	2	Strip leading and trailing spaces from Official Number when
--					checking for existing CASEINDEXES row.

Begin
	If UPDATE ( OFFICIALNUMBER )
	Begin
		------------------------------------------------------------
		-- Remove the old CASEINDEXES for the updated Relatedcase
		-- if there is no other OfficialNumber requiring this index
		------------------------------------------------------------
		Delete CASEINDEXES
		from CASEINDEXES CI
		join deleted d	on (d.CASEID=CI.CASEID
				and rtrim(ltrim(d.OFFICIALNUMBER))=CI.GENERICINDEX)
		left join RELATEDCASE N on (N.CASEID=CI.CASEID
					    and rtrim(ltrim(N.OFFICIALNUMBER))=CI.GENERICINDEX)
		where CI.SOURCE=7
		and N.CASEID is null
		
		Delete CASEINDEXES
		from CASEINDEXES CI
		join deleted d	on (d.CASEID=CI.CASEID
				and dbo.fn_StripNonAlphaNumerics(d.OFFICIALNUMBER)=CI.GENERICINDEX)
		left join RELATEDCASE N on (N.CASEID=CI.CASEID
					    and dbo.fn_StripNonAlphaNumerics(N.OFFICIALNUMBER)=CI.GENERICINDEX)
		where CI.SOURCE=7
		and N.CASEID is null
		
		Delete CASEINDEXES
		from CASEINDEXES CI
		join deleted d	on (d.CASEID=CI.CASEID
				and dbo.fn_StripNonNumerics(d.OFFICIALNUMBER)=CI.GENERICINDEX)
		left join RELATEDCASE N on (N.CASEID=CI.CASEID
					    and dbo.fn_StripNonNumerics(N.OFFICIALNUMBER)=CI.GENERICINDEX)
		where CI.SOURCE=7
		and N.CASEID is null

		Delete CASEINDEXES
		from CASEINDEXES CI
		join deleted d	on (d.CASEID=CI.CASEID
				and dbo.fn_ConvertToPctShortFormat(d.OFFICIALNUMBER)=CI.GENERICINDEX)
		left join RELATEDCASE N on (N.CASEID=CI.CASEID
						and dbo.fn_ConvertToPctShortFormat(N.OFFICIALNUMBER)=CI.GENERICINDEX)
		where CI.SOURCE=7
		and N.CASEID is null
		------------------------------------------------------------
		-- Insert the new CASEINDEXES for the updated OfficialNumber
		-- if there is no available matching CASEINDEX already
		------------------------------------------------------------
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
End
go
