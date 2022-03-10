if exists (select * from sysobjects where type='TR' and name = 'UpdateCASENAME_ids')
begin
	PRINT 'Refreshing trigger UpdateCASENAME_ids...'
	DROP TRIGGER UpdateCASENAME_ids
end
go

Create trigger UpdateCASENAME_ids on CASENAME for UPDATE NOT FOR REPLICATION as
-- TRIGGER:	UpdateCASENAME_ids
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

Begin
---------------------------------
-- Only changes to the NAMENO or
-- NAMETYPE arerelevant to this 
-- trigger.
---------------------------------
If Update(NAMENO)
or UPDATE(NAMETYPE)
Begin
	---------------------------------------------------------
	-- Cases may be linked to a Name by adding to a CaseName. 
	-- If the CaseName is associated with a Search Result
	-- (Source Document or Prior Art) then the Case should be 
	-- linked to the Prior Art.
	---------------------------------------------------------
	Insert into CASESEARCHRESULT(NAMEPRIORARTID, CASEID, PRIORARTID, STATUS, UPDATEDDATE,ISCASERELATIONSHIP)
	Select distinct N.NAMEPRIORARTID, i.CASEID, N.PRIORARTID, CASE WHEN(CS1.STATUS=-999999999) THEN NULL ELSE CS1.STATUS END, getdate(),0
	From inserted i
			---------------------------------------------
			-- Key of CASENAME must have been updated
			---------------------------------------------
	left join deleted d	on (d.CASEID  =i.CASEID
				and d.NAMENO  =i.NAMENO
				and d.NAMETYPE=i.NAMETYPE)
	join NAMESEARCHRESULT N	on (N.NAMENO  =i.NAMENO
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
	left join STATUS ST	on (ST.STATUSCODE =C.STATUSCODE)
	where d.CASEID is null 
	and (T.BOOLEANFLAG=1 OR isnull(S.ISSOURCEDOCUMENT,0)=0)
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
			---------------------------------------------
			-- Key of CASENAME must have been updated
			---------------------------------------------
	left join deleted d	on (d.CASEID  =i.CASEID
				and d.NAMENO  =i.NAMENO
				and d.NAMETYPE=i.NAMETYPE)
	join NAMESEARCHRESULT N	on (N.NAMENO  =i.NAMENO
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
	left join STATUS ST	on (ST.STATUSCODE =C.STATUSCODE)
	where  d.CASEID is null
	and    S.ISSOURCEDOCUMENT=1
	and  CS2.CASEID is null
	and   CN.PRIORARTFLAG=1
	and ( ST.STATUSCODE is null OR ST.PRIORARTFLAG=1)

	-------------------------------------------------------
	-- If the CASENAME has been updated such that it is no
	-- longer linked to NAMENO or NAMETYPE defined by the
	-- NAMESEARCHRESULT, then the Case needs to be removed 
	-- from PriorArt that was associated with the NAMENO.
	-------------------------------------------------------
	-- NOTE : The removal of the old CASESEARCHRESULT is
	--        after the new changes have been applied.
	--        This is so we can use the existing Status 
	--        if the Case ends up being associated with the
	--        same Prior Art but from the perspective of a
	--        different NAMENO/NAMETYPE.
	-------------------------------------------------------
	Delete CSR
	from deleted d
	left join inserted i	on (i.CASEID=d.CASEID
				and i.NAMENO=d.NAMENO
				and i.NAMETYPE=d.NAMETYPE)
	join NAMESEARCHRESULT N	on (N.NAMENO=d.NAMENO
				and d.NAMETYPE=isnull(N.NAMETYPE, d.NAMETYPE))
	join CASESEARCHRESULT CSR
				on (CSR.NAMEPRIORARTID=N.NAMEPRIORARTID
				and CSR.CASEID=d.CASEID)
	where i.CASEID is null
End
End -- End of Trigger
go
