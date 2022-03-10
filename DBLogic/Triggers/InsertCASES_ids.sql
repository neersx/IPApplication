if exists (select * from sysobjects where type='TR' and name = 'InsertCASES_ids')
begin
	PRINT 'Refreshing trigger InsertCASES_ids...'
	DROP TRIGGER InsertCASES_ids
end
go

Create trigger InsertCASES_ids on CASES for INSERT NOT FOR REPLICATION as
Begin
-- TRIGGER:	InsertCASES_ids    
-- VERSION:	3
-- DESCRIPTION:	

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 03 Mar 2011	MF	6563 	1	Created
-- 03 Apr 2011	MF	10431	2	Use the PRIORARTFLAG to determine the Cases to link.
-- 03 May 2011	MF	10548	3	Insert the CASESEARCHRESULT row even if the Case is already
--					linked to the Prior Art as a related Case.
	-------------------------------------------------------
	-- Cases may be inserted that are linked to a Family.
	-- If the Family is associated with a Search Result
	-- (Source Document or Prior Art) then the Case should
	-- be linked to the Prior Art.
	-------------------------------------------------------
	Insert into CASESEARCHRESULT(FAMILYPRIORARTID, CASEID, PRIORARTID, STATUS, UPDATEDDATE,ISCASERELATIONSHIP)
	Select distinct F.FAMILYPRIORARTID, i.CASEID, F.PRIORARTID, CASE WHEN(CS1.STATUS=-999999999) THEN NULL ELSE CS1.STATUS END, getdate(),0
	From inserted i
	join FAMILYSEARCHRESULT F
				on (F.FAMILY=i.FAMILY)
	join SEARCHRESULTS S	on (S.PRIORARTID=F.PRIORARTID)
	left join TABLECODES T	on (T.TABLECODE=S.SOURCE)
			---------------------------------------------
			-- If the Case already has been linked to the
			-- search result as a result of some other
			-- relationship, then use the existing Status
			---------------------------------------------
	left join (	select  CASEID, PRIORARTID, max(isnull(STATUS,-999999999)) as STATUS
			from CASESEARCHRESULT
			group by CASEID, PRIORARTID) CS1
				on (CS1.CASEID=i.CASEID
				and CS1.PRIORARTID=F.PRIORARTID)
			---------------------------------------------
			-- Do not insert the row if it already exists
			---------------------------------------------
	left join CASESEARCHRESULT CS2 
				on (CS2.FAMILYPRIORARTID=F.FAMILYPRIORARTID
				and CS2.CASEID=i.CASEID
				and CS2.PRIORARTID=F.PRIORARTID
				and isnull(CS2.ISCASERELATIONSHIP,0)=0)
			---------------------------------------------
			-- Only interested in Cases flagged to report
			---------------------------------------------
	     join COUNTRY CN	on (CN.COUNTRYCODE=i.COUNTRYCODE)
	left join STATUS ST	on (ST.STATUSCODE =i.STATUSCODE)
	where (T.BOOLEANFLAG=1 OR isnull(S.ISSOURCEDOCUMENT,0)=0)
	and  CS2.CASEID is null
	and   CN.PRIORARTFLAG=1
	and ( ST.STATUSCODE is null OR ST.PRIORARTFLAG=1)

	-------------------------------------------------------
	-- Case linked to a Family associated with Source Doc.
	-- A Source Document may bundle together any number of
	-- cited Search Results (prior art). When a Family is
	-- associated with a Source Document it should create
	-- links for Cases belonging to the Family to each
	-- Search Result linked to the Source Document.
	-- If a Case is inserted with such a Family then the
	-- Case must be linked to all of the cited Prior Art.
	-- NOTE: The Source Document itself has already 
	--       been linked directly to the Case in the
	--       previous Insert.
	-------------------------------------------------------
	Insert into CASESEARCHRESULT(FAMILYPRIORARTID, CASEID, PRIORARTID, STATUS, UPDATEDDATE,ISCASERELATIONSHIP)
	Select distinct F.FAMILYPRIORARTID, i.CASEID, R.CITEDPRIORARTID, CASE WHEN(CS1.STATUS=-999999999) THEN NULL ELSE CS1.STATUS END, getdate(),0
	From inserted i
	join FAMILYSEARCHRESULT F
				on (F.FAMILY=i.FAMILY)
	join SEARCHRESULTS S	on (S.PRIORARTID=F.PRIORARTID)
			---------------------------------------------
			-- Find prior art cited in Source Document
			---------------------------------------------
	join REPORTCITATIONS R	on (R.SEARCHREPORTID=S.PRIORARTID)
			---------------------------------------------
			---------------------------------------------
			-- If the Case already has been linked to the
			-- search result as a result of some other
			-- relationship, then use the existing Status
			---------------------------------------------
	left join (	select  CASEID, PRIORARTID, max(isnull(STATUS,-999999999)) as STATUS
			from CASESEARCHRESULT
			group by CASEID, PRIORARTID) CS1
				on (CS1.CASEID=i.CASEID
				and CS1.PRIORARTID=R.CITEDPRIORARTID)
			---------------------------------------------
			-- Do not insert the row if it already exists
			---------------------------------------------
	left join CASESEARCHRESULT CS2 
				on (CS2.FAMILYPRIORARTID=F.FAMILYPRIORARTID
				and CS2.CASEID=i.CASEID
				and CS2.PRIORARTID=R.CITEDPRIORARTID
				and isnull(CS2.ISCASERELATIONSHIP,0)=0)
			---------------------------------------------
			-- Only interested in Cases flagged to report
			---------------------------------------------
	     join COUNTRY CN	on (CN.COUNTRYCODE=i.COUNTRYCODE)
	left join STATUS ST	on (ST.STATUSCODE =i.STATUSCODE)
	where S.ISSOURCEDOCUMENT=1
	and  CS2.CASEID is null
	and   CN.PRIORARTFLAG=1
	and ( ST.STATUSCODE is null OR ST.PRIORARTFLAG=1)
End
go
