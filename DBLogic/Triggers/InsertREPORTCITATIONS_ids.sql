if exists (select * from sysobjects where type='TR' and name = 'InsertREPORTCITATIONS_ids')
begin
	PRINT 'Refreshing trigger InsertREPORTCITATIONS_ids...'
	DROP TRIGGER InsertREPORTCITATIONS_ids
end
go

Create trigger InsertREPORTCITATIONS_ids on REPORTCITATIONS for INSERT NOT FOR REPLICATION as
Begin
-- TRIGGER:	InsertREPORTCITATIONS_ids    
-- VERSION:	4
-- DESCRIPTION:	

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 03 Mar 2011	MF	6563 	1	Created
-- 03 Apr 2011	MF	10431	2	Use the PRIORARTFLAG to determine the Cases to link.
-- 03 May 2011	MF	10548	3	Insert the CASESEARCHRESULT row even if the Case is already
--					linked to the Prior Art as a related Case.
-- 13 Apr 2015	MF	46423	4	Reversal of RFC10548.

	-------------------------------------------------------
	-- When a REPORTCITATION is inserted it is linking a
	-- SearchResult Source Document to a SearchResult cited
	-- Prior Art reference.
	-- When this occurs, all of the Cases that are directly
	-- or indirectly linked to the Source Document must
	-- now be linked to the newly cited Prior Art.
	-------------------------------------------------------
	Insert into CASESEARCHRESULT(FAMILYPRIORARTID, CASELISTPRIORARTID, NAMEPRIORARTID, CASEID, PRIORARTID, STATUS, UPDATEDDATE,ISCASERELATIONSHIP)
	----------------------
	-- Family relationship
	----------------------
	Select F.FAMILYPRIORARTID, null, null, C.CASEID, i.CITEDPRIORARTID, CASE WHEN(CS1.STATUS=-999999999) THEN NULL ELSE CS1.STATUS END, getdate(),0
	From inserted i
	join FAMILYSEARCHRESULT F
				on (F.PRIORARTID=i.SEARCHREPORTID)
			---------------------------------------------
			-- Get Cases belonging to Family
			---------------------------------------------
	join CASES C		on (C.FAMILY=F.FAMILY)
			---------------------------------------------
			-- If the Case already has been linked to the
			-- search result as a result of some other
			-- relationship, then use the existing Status
			---------------------------------------------
	left join (	select  CASEID, PRIORARTID, max(isnull(STATUS,-999999999)) as STATUS
			from CASESEARCHRESULT
			group by CASEID, PRIORARTID) CS1
				on (CS1.CASEID=C.CASEID
				and CS1.PRIORARTID=i.CITEDPRIORARTID)
			---------------------------------------------
			-- Do not insert the row if it already exists
			---------------------------------------------
	left join CASESEARCHRESULT CS2 
				on (CS2.FAMILYPRIORARTID=F.FAMILYPRIORARTID
				and CS2.CASEID=C.CASEID
				and CS2.PRIORARTID=i.CITEDPRIORARTID)
			---------------------------------------------
			-- Only interested in Cases flagged to report
			---------------------------------------------
	     join COUNTRY CN	on (CN.COUNTRYCODE=C.COUNTRYCODE)
	left join STATUS ST	on (ST.STATUSCODE =C.STATUSCODE)
	where CS2.CASEID is null
	and ( ST.STATUSCODE is null OR (ST.LIVEFLAG=1 and ST.REGISTEREDFLAG=0)) -- pending
	------------------------
	-- CaseList relationship
	------------------------
	UNION
	Select null, CL.CASELISTPRIORARTID, null, C.CASEID, i.CITEDPRIORARTID, CASE WHEN(CS1.STATUS=-999999999) THEN NULL ELSE CS1.STATUS END, getdate(),0
	From inserted i
	join CASELISTSEARCHRESULT CL
				on (CL.PRIORARTID=i.SEARCHREPORTID)
			---------------------------------------------
			-- Get Cases belonging to CaseList
			---------------------------------------------
	join CASELISTMEMBER L	on (L.CASELISTNO=CL.CASELISTNO)
	join CASES C		on (C.CASEID    =L.CASEID)
			---------------------------------------------
			-- If the Case already has been linked to the
			-- search result as a result of some other
			-- relationship, then use the existing Status
			---------------------------------------------
	left join (	select  CASEID, PRIORARTID, max(isnull(STATUS,-999999999)) as STATUS
			from CASESEARCHRESULT
			group by CASEID, PRIORARTID) CS1
				on (CS1.CASEID=C.CASEID
				and CS1.PRIORARTID=i.CITEDPRIORARTID)
			---------------------------------------------
			-- Do not insert the row if it already exists
			---------------------------------------------
	left join CASESEARCHRESULT CS2 
				on (CS2.CASELISTPRIORARTID=CL.CASELISTPRIORARTID
				and CS2.CASEID=C.CASEID
				and CS2.PRIORARTID=i.CITEDPRIORARTID)
			---------------------------------------------
			-- Only interested in Cases flagged to report
			---------------------------------------------
	     join COUNTRY CN	on (CN.COUNTRYCODE=C.COUNTRYCODE)
	left join STATUS ST	on (ST.STATUSCODE =C.STATUSCODE)
	where CS2.CASEID is null
	and   CN.PRIORARTFLAG=1
	and ( ST.STATUSCODE is null OR ST.PRIORARTFLAG=1)
	------------------------
	-- Name relationship
	------------------------
	UNION
	Select null, null, N.NAMEPRIORARTID, C.CASEID, i.CITEDPRIORARTID, CASE WHEN(CS1.STATUS=-999999999) THEN NULL ELSE CS1.STATUS END, getdate(),0
	From inserted i
	join NAMESEARCHRESULT N
				on (N.PRIORARTID=i.SEARCHREPORTID)
			---------------------------------------------
			-- Get Cases associated with the NameNo
			---------------------------------------------
	join CASENAME CN	on (CN.NAMENO=N.NAMENO
				and CN.NAMETYPE=isnull(N.NAMETYPE,CN.NAMETYPE)  -- NameType may optionally be specified
				and CN.EXPIRYDATE is null)
	join CASES C		on (C.CASEID =CN.CASEID)
			---------------------------------------------
			-- If the Case already has been linked to the
			-- search result as a result of some other
			-- relationship, then use the existing Status
			---------------------------------------------
	left join (	select  CASEID, PRIORARTID, max(isnull(STATUS,-999999999)) as STATUS
			from CASESEARCHRESULT
			group by CASEID, PRIORARTID) CS1
				on (CS1.CASEID=C.CASEID
				and CS1.PRIORARTID=i.CITEDPRIORARTID)
			---------------------------------------------
			-- Do not insert the row if it already exists
			---------------------------------------------
	left join CASESEARCHRESULT CS2 
				on (CS2.NAMEPRIORARTID=N.NAMEPRIORARTID
				and CS2.CASEID=C.CASEID
				and CS2.PRIORARTID=i.CITEDPRIORARTID)
			---------------------------------------------
			-- Only interested in Cases flagged to report
			---------------------------------------------
	     join COUNTRY CT	on (CT.COUNTRYCODE=C.COUNTRYCODE)
	left join STATUS ST	on (ST.STATUSCODE =C.STATUSCODE)
	where CS2.CASEID is null
	and   CT.PRIORARTFLAG=1
	and ( ST.STATUSCODE is null OR ST.PRIORARTFLAG=1)
	----------------------------------
	-- CASES linked to Source Document
	----------------------------------
	UNION
	Select null, null, null, C.CASEID, i.CITEDPRIORARTID, CASE WHEN(CS1.STATUS=-999999999) THEN NULL ELSE CS1.STATUS END, getdate(),0
	From inserted i
	join CASESEARCHRESULT CSR
				on (CSR.PRIORARTID=i.SEARCHREPORTID
				and CSR.FAMILYPRIORARTID   is null
				and CSR.CASELISTPRIORARTID is null
				and CSR.NAMEPRIORARTID     is null)
			---------------------------------------------
			-- Get Cases linked to Source Document
			---------------------------------------------
	join CASES C		on (C.CASEID =CSR.CASEID)
			---------------------------------------------
			-- If the Case already has been linked to the
			-- search result as a result of some other
			-- relationship, then use the existing Status
			---------------------------------------------
	left join (	select  CASEID, PRIORARTID, max(isnull(STATUS,-999999999)) as STATUS
			from CASESEARCHRESULT
			group by CASEID, PRIORARTID) CS1
				on (CS1.CASEID=C.CASEID
				and CS1.PRIORARTID=i.CITEDPRIORARTID)
			---------------------------------------------
			-- Do not insert the row if it already exists
			---------------------------------------------
	left join CASESEARCHRESULT CS2 
				on (CS2.CASEID=C.CASEID
				and CS2.PRIORARTID=i.CITEDPRIORARTID
				and CS2.FAMILYPRIORARTID   is null
				and CS2.CASELISTPRIORARTID is null
				and CS2.NAMEPRIORARTID     is null)
			---------------------------------------------
			-- Only interested in Cases flagged to report
			---------------------------------------------
	     join COUNTRY CN	on (CN.COUNTRYCODE=C.COUNTRYCODE)
	left join STATUS ST	on (ST.STATUSCODE =C.STATUSCODE)
	where CS2.CASEID is null
	and   CN.PRIORARTFLAG=1
	and ( ST.STATUSCODE is null OR ST.PRIORARTFLAG=1)


End
go
