if exists (select * from sysobjects where type='TR' and name = 'UpdateCASEINDEXES_CASEFAMILY')
begin
	PRINT 'Refreshing trigger UpdateCASEINDEXES_CASEFAMILY...'
	DROP TRIGGER UpdateCASEINDEXES_CASEFAMILY
end
go

Create trigger UpdateCASEINDEXES_CASEFAMILY on CASEFAMILY for UPDATE NOT FOR REPLICATION as
-- TRIGGER:	UpdateCASEINDEXES_CASEFAMILY    
-- VERSION:	10
-- DESCRIPTION:	

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 03-Jul-2019	MF	DR-50036 1	Created


If UPDATE ( FAMILYTITLE ) and NOT UPDATE(LOGDATETIMESTAMP)
Begin
	----------------------------------------------=
	-- Update the CASEINDEXES where the FAMILYTITLE 
	-- has changed to a different value
	------------------------------------=----------
	Update CI
	Set GENERICINDEX=i.FAMILYTITLE
	From inserted i
	join deleted d  on (d.FAMILY=i.FAMILY
			and d.FAMILYTITLE<>i.FAMILYTITLE)
	join CASEINDEXES CI on (CI.GENERICINDEX=d.FAMILYTITLE
			    and CI.SOURCE=3)
	where i.FAMILY<>i.FAMILYTITLE
	and   d.FAMILY<>i.FAMILYTITLE
	and exists
	(select 1
	 from CASEINDEXES CI2
	 where CI2.CASEID=CI.CASEID
	 and   CI2.SOURCE=CI.SOURCE
	 and   CI2.GENERICINDEX=i.FAMILY)

	----------------------------------------------=
	-- Delete the CASEINDEXES where the FAMILYTITLE 
	-- has been cleared out or now matches FAMILY
	------------------------------------=----------
	Delete CI
	from inserted i
	join deleted d  on (d.FAMILY=i.FAMILY
			and d.FAMILYTITLE<>d.FAMILY)
	join CASEINDEXES CI on (CI.GENERICINDEX=d.FAMILYTITLE
			    and CI.SOURCE=3)
	where (i.FAMILYTITLE is null
	    or i.FAMILYTITLE=i.FAMILY)
	and exists
	(select 1
	 from CASEINDEXES CI2
	 where CI2.CASEID=CI.CASEID
	 and CI2.SOURCE=CI.SOURCE
	 and CI2.GENERICINDEX=i.FAMILY)

	----------------------------------------------=
	-- Insert into CASEINDEXES where the FAMILYTITLE 
	-- has changed to a different value from FAMILY
	-- or is no longer NULL
	------------------------------------=----------
	Insert into CASEINDEXES (GENERICINDEX, CASEID, SOURCE)
	Select i.FAMILYTITLE, CI.CASEID, 3 
	from inserted i
	join deleted d  on (d.FAMILY=i.FAMILY
			and(d.FAMILYTITLE=d.FAMILY OR d.FAMILYTITLE is null))
	join CASEINDEXES CI on (CI.GENERICINDEX=i.FAMILY
			    and CI.SOURCE=3)
	left join CASEINDEXES CI2 on (CI2.CASEID=CI.CASEID
			          and CI2.GENERICINDEX=i.FAMILYTITLE
			          and CI2.SOURCE=3)
	where i.FAMILYTITLE<>i.FAMILY
	and CI2.CASEID is null
End

go
