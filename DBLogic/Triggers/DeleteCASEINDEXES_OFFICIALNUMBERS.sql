if exists (select * from sysobjects where type='TR' and name = 'DeleteCASEINDEXES_OFFICIALNUMBERS')
begin
	PRINT 'Refreshing trigger DeleteCASEINDEXES_OFFICIALNUMBERS...'
	DROP TRIGGER DeleteCASEINDEXES_OFFICIALNUMBERS
end
go
	
Create trigger DeleteCASEINDEXES_OFFICIALNUMBERS on OFFICIALNUMBERS for DELETE NOT FOR REPLICATION as
Begin
-- TRIGGER:	DeleteCASEINDEXES_OFFICIALNUMBERS    
-- VERSION:	6
-- DESCRIPTION:	

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 			8883 	1	Created
-- 24-OCT-2006	MF	13706	2	Remove additional row with non alpha numerics stripped out
-- 11-FEB-2008	MF	RFC6191	3	Generic Index stored as UPPER case so must join
--					using UPPER()
-- 27-MAY-2009	MF	17730	4	Numeric only version of official number is now stored.
--					Also remove restriction for IP Office number types.
-- 05-Jun-2009	MF	17766	5	Strip leading and trailing spaces
-- 23-Jun-2015	MZ	47863	6	Convert new PCT new format to old short format

	-------------------------------------------
	-- Only delete the row from CASEINDEXES if 
	-- there is no other OFFICIALNUMBER row for 
	-- the Case that generated the same index
	-------------------------------------------
	
	Delete CASEINDEXES
	from CASEINDEXES CI
	join deleted d		    on (d.CASEID=CI.CASEID
				    and rtrim(ltrim(UPPER(d.OFFICIALNUMBER)))=CI.GENERICINDEX)
	left join OFFICIALNUMBERS N on (N.CASEID=CI.CASEID
				    and rtrim(ltrim(UPPER(N.OFFICIALNUMBER)))=CI.GENERICINDEX)
	where CI.SOURCE=5
	and N.CASEID is null
	
	Delete CASEINDEXES
	from CASEINDEXES CI
	join deleted d		    on (d.CASEID=CI.CASEID
				    and dbo.fn_StripNonAlphaNumerics(UPPER(d.OFFICIALNUMBER))=CI.GENERICINDEX)
	left join OFFICIALNUMBERS N on (N.CASEID=CI.CASEID
				    and dbo.fn_StripNonAlphaNumerics(UPPER(N.OFFICIALNUMBER))=CI.GENERICINDEX)
	where CI.SOURCE=5
	and N.CASEID is null
	
	Delete CASEINDEXES
	from CASEINDEXES CI
	join deleted d		    on (d.CASEID=CI.CASEID
				    and dbo.fn_StripNonNumerics(d.OFFICIALNUMBER)=CI.GENERICINDEX)
	left join OFFICIALNUMBERS N on (N.CASEID=CI.CASEID
				    and dbo.fn_StripNonNumerics(N.OFFICIALNUMBER)=CI.GENERICINDEX)
	where CI.SOURCE=5
	and N.CASEID is null

	Delete CASEINDEXES
	from CASEINDEXES CI
	join deleted d		    on (d.CASEID=CI.CASEID
				    and dbo.fn_ConvertToPctShortFormat(d.OFFICIALNUMBER)=CI.GENERICINDEX)
	left join OFFICIALNUMBERS N on (N.CASEID=CI.CASEID
				    and dbo.fn_ConvertToPctShortFormat(N.OFFICIALNUMBER)=CI.GENERICINDEX)
	where CI.SOURCE=5
	and N.CASEID is null
End
go
