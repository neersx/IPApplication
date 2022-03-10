if exists (select * from sysobjects where type='TR' and name = 'DeleteCASEINDEXES_RELATEDCASE')
begin
	PRINT 'Refreshing trigger DeleteCASEINDEXES_RELATEDCASE...'
	DROP TRIGGER DeleteCASEINDEXES_RELATEDCASE
end
go
	
Create trigger DeleteCASEINDEXES_RELATEDCASE on RELATEDCASE for DELETE NOT FOR REPLICATION as
Begin
-- TRIGGER:	DeleteCASEINDEXES_RELATEDCASE    
-- VERSION:	1
-- DESCRIPTION:	

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 27 May 2016	MF	60784	1	Created

	-------------------------------------------
	-- Only delete the row from CASEINDEXES if 
	-- there is no other RELATEDCASE row for 
	-- the Case that generated the same index
	-------------------------------------------
	
	Delete CASEINDEXES
	from CASEINDEXES CI
	join deleted d		    on (d.CASEID=CI.CASEID
				    and rtrim(ltrim(d.OFFICIALNUMBER))=CI.GENERICINDEX)
	left join RELATEDCASE N on (N.CASEID=CI.CASEID
				    and rtrim(ltrim(N.OFFICIALNUMBER))=CI.GENERICINDEX)
	where CI.SOURCE=7
	and N.CASEID is null
	
	Delete CASEINDEXES
	from CASEINDEXES CI
	join deleted d		    on (d.CASEID=CI.CASEID
				    and dbo.fn_StripNonAlphaNumerics(d.OFFICIALNUMBER)=CI.GENERICINDEX)
	left join RELATEDCASE N on (N.CASEID=CI.CASEID
				    and dbo.fn_StripNonAlphaNumerics(N.OFFICIALNUMBER)=CI.GENERICINDEX)
	where CI.SOURCE=7
	and N.CASEID is null
	
	Delete CASEINDEXES
	from CASEINDEXES CI
	join deleted d		    on (d.CASEID=CI.CASEID
				    and dbo.fn_StripNonNumerics(d.OFFICIALNUMBER)=CI.GENERICINDEX)
	left join RELATEDCASE N on (N.CASEID=CI.CASEID
				    and dbo.fn_StripNonNumerics(N.OFFICIALNUMBER)=CI.GENERICINDEX)
	where CI.SOURCE=7
	and N.CASEID is null

	Delete CASEINDEXES
	from CASEINDEXES CI
	join deleted d		    on (d.CASEID=CI.CASEID
				    and dbo.fn_ConvertToPctShortFormat(d.OFFICIALNUMBER)=CI.GENERICINDEX)
	left join RELATEDCASE N on (N.CASEID=CI.CASEID
				    and dbo.fn_ConvertToPctShortFormat(N.OFFICIALNUMBER)=CI.GENERICINDEX)
	where CI.SOURCE=7
	and N.CASEID is null
End
go
