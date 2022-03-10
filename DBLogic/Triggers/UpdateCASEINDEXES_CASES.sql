if exists (select * from sysobjects where type='TR' and name = 'UpdateCASEINDEXES_CASES')
begin
	PRINT 'Refreshing trigger UpdateCASEINDEXES_CASES...'
	DROP TRIGGER UpdateCASEINDEXES_CASES
end
go

Create trigger UpdateCASEINDEXES_CASES on CASES for UPDATE NOT FOR REPLICATION as
-- TRIGGER:	UpdateCASEINDEXES_CASES    
-- VERSION:	10
-- DESCRIPTION:	

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 			8883 	1	Created
-- 11-FEB-2008	MF	RFC6191	2	Generic Index stored as UPPER case.
-- 17-SEP-2008	MF	16930	3	Change of IRN should Insert and Delete rather than Update as
--					there may not be a CASEINDEXES row in existence already.
-- 17 Mar 2009	MF	17490	4	Ignore if trigger is being fired as a result of the audit details being updated
-- 24 Jun 2009	MF	17490	5	Revisit. Need to explicitly test if column values have changed before changing CASEINDEXES.
-- 22 Sep 2009	DL	18079	6	Fixed bug - new IRN is not inserted if audit triggers are enabled on CASES table.
-- 21 Jun 2010	MF	R9296	7	Change of COUNTRYCODE or PROPERTYTYPE should trigger recalculation of Case standing instructions.
-- 06-Mar-2014	MF	R31402	8	Include STEM in the CASEINDEX.  Also remove UPPER as databases must now  be case insensitive.
-- 11 Oct 2016	MF	R54101	9	A change to the IRN should also flow through to the BILLLINE table where a snapshot of the IRN is held.
-- 03-Jul-2019	MF	DR-50036 10	Include FAMILYTITLE associated with CaseFamily only when different to FAMILY.

If UPDATE ( IRN ) and NOT UPDATE(LOGDATETIMESTAMP)
Begin
	-- Insert the modified IRN
	Insert into CASEINDEXES (GENERICINDEX, CASEID, SOURCE)
	Select distinct i.IRN, i.CASEID, 1 
	from inserted i
	join deleted d on (d.CASEID=i.CASEID)
	left join CASEINDEXES CI on (CI.CASEID=i.CASEID
								and CI.SOURCE=1
								and CI.GENERICINDEX = i.IRN)
	where i.IRN<>'<Generate Reference>'
	and i.IRN<>d.IRN
	and CI.CASEID is null
	
	-- Remove CASEINDEXES where IRN no longer matches
	Delete CI
	from CASEINDEXES CI
	join inserted i on (i.CASEID=CI.CASEID)
	where CI.SOURCE = 1
	and CI.GENERICINDEX<>i.IRN
	
	-------------------------------------------
	-- Now also update the BILLLINE table as it
	-- is holding the IRN as at the time that
	-- WIP was being billed for the Case.
	-------------------------------------------
	Update B
	Set IRN=i.IRN
	from inserted i
	join deleted  d on (d.CASEID=i.CASEID)
	join BILLLINE B on (B.IRN=d.IRN)
	where d.IRN<>i.IRN
End
If UPDATE ( TITLE ) and NOT UPDATE(LOGDATETIMESTAMP)
Begin
	-- Delete the nulls, update the non-nulls and add the missing ones
	Delete CASEINDEXES 
	from CASEINDEXES CI
	join inserted i on (i.CASEID=CI.CASEID)
	where CI.SOURCE = 2
	and i.TITLE is null
	-- Update values
	Update CASEINDEXES
	Set GENERICINDEX = i.TITLE
	from CASEINDEXES CI
	join inserted i on (i.CASEID=CI.CASEID)
	join deleted  d on (d.CASEID=i.CASEID)
	where CI.SOURCE = 2
	and i.TITLE<>isnull(d.TITLE,'')
	--Insert values with TITLE.
	Insert into CASEINDEXES (GENERICINDEX, CASEID, SOURCE)
	Select distinct i.TITLE, i.CASEID, 2 
	from inserted i
	left join CASEINDEXES CI on (CI.CASEID=i.CASEID
				 and CI.SOURCE=2)
	where i.TITLE is not null
	and CI.CASEID is null
End
If UPDATE ( FAMILY ) and NOT UPDATE(LOGDATETIMESTAMP)
Begin
	-- Delete if the FAMILY has been removed
	Delete CASEINDEXES 
	from CASEINDEXES CI
	join inserted i on (i.CASEID=CI.CASEID)
	where CI.SOURCE = 3
	and i.FAMILY is null

	-- Delete if the FAMILY has been changed
	Delete CASEINDEXES 
	from CASEINDEXES CI
	join inserted i     on (i.CASEID=CI.CASEID)
	join CASEFAMILY CF1 on (CF1.FAMILY=i.FAMILY)
	join deleted  d     on (d.CASEID=CI.CASEID)
	join CASEFAMILY CF2 on (CF2.FAMILY=d.FAMILY)
	where CI.SOURCE = 3
	and i.FAMILY <> d.FAMILY

	-- Insert values
	Insert into CASEINDEXES (GENERICINDEX, CASEID, SOURCE)
	Select i.FAMILY, i.CASEID, 3 
	from inserted i
	left join CASEINDEXES CI on (CI.CASEID=i.CASEID
				 and CI.SOURCE=3)
	where i.FAMILY is not null
	and CI.CASEID is null
	UNION
	Select CF.FAMILYTITLE, i.CASEID, 3 
	from inserted i
	join CASEFAMILY CF       on (CF.FAMILY=i.FAMILY)
	left join CASEINDEXES CI on (CI.CASEID=i.CASEID
				 and CI.SOURCE=3)
	where CF.FAMILY <> CF.FAMILYTITLE
	and CI.CASEID is null
End
If UPDATE ( STEM ) and NOT UPDATE(LOGDATETIMESTAMP)
Begin
	-- Delete the nulls and update the non-nulls
	Delete CASEINDEXES 
	from CASEINDEXES CI
	join inserted i on (i.CASEID=CI.CASEID)
	where CI.SOURCE = 6
	and (i.STEM is null or i.STEM like '~%')
	-- Update values
	Update CASEINDEXES
	Set GENERICINDEX = LEFT(i.STEM,CASE WHEN(PATINDEX('%~%',i.STEM)>1) THEN PATINDEX('%~%',i.STEM)-1 ELSE LEN(i.STEM) END )
	from CASEINDEXES CI
	join inserted i on (i.CASEID=CI.CASEID)
	join deleted  d on (d.CASEID=CI.CASEID)
	where CI.SOURCE = 6
	and i.STEM<>isnull(d.STEM,'')
	and i.STEM not like '~%'  -- first character of stem is not tilde
	-- Insert values
	Insert into CASEINDEXES (GENERICINDEX, CASEID, SOURCE)
	Select distinct LEFT(i.STEM,CASE WHEN(PATINDEX('%~%',i.STEM)>1) THEN PATINDEX('%~%',i.STEM)-1 ELSE LEN(i.STEM) END ), i.CASEID, 6
	from inserted i
	left join CASEINDEXES CI on (CI.CASEID=i.CASEID
				 and CI.SOURCE=6)
	where i.STEM not like '~%'  -- first character of stem is not tilde
	and CI.CASEID is null
End
If NOT UPDATE(LOGDATETIMESTAMP)
and (  UPDATE(COUNTRYCODE) OR UPDATE(PROPERTYTYPE) )
Begin
	-----------------------------------------------
	-- Change of either CountryCode or PropertyType
	-- should trigger the recalculation of of
	-- Case level Standing Instructions.
	-----------------------------------------------
	Insert into CASEINSTRUCTIONSRECALC(CASEID, ONHOLDFLAG)
	select i.CASEID, 0
	from inserted i
	join deleted  d on (d.CASEID=i.CASEID)
	left join CASEINSTRUCTIONSRECALC CI	on (CI.CASEID=i.CASEID
						and CI.ONHOLDFLAG=0)
	where(i.COUNTRYCODE <>d.COUNTRYCODE
	or    i.PROPERTYTYPE<>d.PROPERTYTYPE)
	AND  CI.CASEID is null
End
go
