if exists (select * from sysobjects where type='TR' and name = 'InsertCASENAME_ids')
begin
	PRINT 'Refreshing trigger InsertCASENAME_ids...'
	DROP TRIGGER InsertCASENAME_ids
end
go

Create trigger InsertCASENAME_ids on CASENAME for INSERT NOT FOR REPLICATION as
Begin
-- TRIGGER:	InsertCASENAME_ids
-- VERSION:	4
-- DESCRIPTION:	

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 03 Mar 2011	MF	6563 	1	Created
-- 29 Mar 2011	MF	10407	2	Failed testing on RFC6563. Correction of coding error.
-- 03 Apr 2011	MF	10431	3	Use the PRIORARTFLAG to determine the Cases to link.
-- 03 May 2011	MF	10548	4	Insert the CASESEARCHRESULT row even if the Case is already
--					linked to the Prior Art as a related Case.
	---------------------------------------------------------
	-- Cases may be linked to a Name by adding to a CaseName. 
	-- If the CaseName is associated with a Search Result
	-- (Source Document or Prior Art) then the Case should be 
	-- linked to the Prior Art.
	---------------------------------------------------------
	Insert into CASESEARCHRESULT(NAMEPRIORARTID, CASEID, PRIORARTID, STATUS, UPDATEDDATE,ISCASERELATIONSHIP)
	Select distinct N.NAMEPRIORARTID, i.CASEID, N.PRIORARTID, CASE WHEN(CS1.STATUS=-999999999) THEN NULL ELSE CS1.STATUS END, getdate(),0
	From inserted i
	join NAMESEARCHRESULT N	on (N.NAMENO=i.NAMENO
				and i.NAMETYPE=isnull(N.NAMETYPE,i.NAMETYPE))
	join SEARCHRESULTS S	on (S.PRIORARTID=N.PRIORARTID)
	left join TABLECODES T	on (T.TABLECODE=S.SOURCE)
			---------------------------------------------
			-- Get Case added to the CaseName
			---------------------------------------------
	join CASES C		on (C.CASEID    =i.CASEID)
			---------------------------------------------
			-- If the Case already has been linked to the
			-- search result as a result of some other
			-- relationship, then use the existing Status
			---------------------------------------------
	left join (	select  CASEID, PRIORARTID, max(isnull(STATUS,-999999999)) as STATUS
			from CASESEARCHRESULT
			group by CASEID, PRIORARTID) CS1
				on (CS1.CASEID=i.CASEID
				and CS1.PRIORARTID=N.PRIORARTID)
			---------------------------------------------
			-- Do not insert the row if it already exists
			---------------------------------------------
	left join CASESEARCHRESULT CS2 
				on (CS2.NAMEPRIORARTID=N.NAMEPRIORARTID
				and CS2.CASEID=i.CASEID
				and CS2.PRIORARTID=N.PRIORARTID
				and isnull(CS2.ISCASERELATIONSHIP,0)=0)
			---------------------------------------------
			-- Only interested in Cases flagged to report
			---------------------------------------------
	     join COUNTRY CN	on (CN.COUNTRYCODE=C.COUNTRYCODE)
	left join STATUS ST	on (ST.STATUSCODE=C.STATUSCODE)
	where (T.BOOLEANFLAG=1 OR isnull(S.ISSOURCEDOCUMENT,0)=0)
	and  CS2.CASEID is null
	and   CN.PRIORARTFLAG=1
	and ( ST.STATUSCODE is null OR ST.PRIORARTFLAG=1)

	-------------------------------------------------------
	-- Case added to a CaseName associated with Source Doc.
	-- A Source Document may bundle together any number of
	-- cited Search Results (prior art). When a Case is 
	-- is added to a CaseName that is  associated with a 
	-- Source Document it should create links for that Case
	-- to the Prior Art linked to the Source Document.
	-- NOTE: The Source Document itself has already 
	--       been linked directly to the Case in the
	--       previous Insert.
	-------------------------------------------------------
	Insert into CASESEARCHRESULT(NAMEPRIORARTID, CASEID, PRIORARTID, STATUS, UPDATEDDATE,ISCASERELATIONSHIP)
	Select distinct N.NAMEPRIORARTID, i.CASEID, R.CITEDPRIORARTID, CASE WHEN(CS1.STATUS=-999999999) THEN NULL ELSE CS1.STATUS END, getdate(),0
	From inserted i
	join NAMESEARCHRESULT N	on (N.NAMENO=i.NAMENO
				and i.NAMETYPE=isnull(N.NAMETYPE,i.NAMETYPE))
	join SEARCHRESULTS S	on (S.PRIORARTID=N.PRIORARTID)
			---------------------------------------------
			-- Find prior art cited in Source Document
			---------------------------------------------
	join REPORTCITATIONS R	on (R.SEARCHREPORTID=S.PRIORARTID)
			---------------------------------------------
			-- Get Case added to the CaseList
			---------------------------------------------
	join CASES C		on (C.CASEID    =i.CASEID)
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
				on (CS2.NAMEPRIORARTID=N.NAMEPRIORARTID
				and CS2.CASEID=i.CASEID
				and CS2.PRIORARTID=R.CITEDPRIORARTID
				and isnull(CS2.ISCASERELATIONSHIP,0)=0)
			---------------------------------------------
			-- Only interested in Cases flagged to report
			---------------------------------------------
	     join COUNTRY CN	on (CN.COUNTRYCODE=C.COUNTRYCODE)
	left join STATUS ST	on (ST.STATUSCODE=C.STATUSCODE)
	where S.ISSOURCEDOCUMENT=1
	and  CS2.CASEID is null
	and   CN.PRIORARTFLAG=1
	and ( ST.STATUSCODE is null OR ST.PRIORARTFLAG=1)
End
go
