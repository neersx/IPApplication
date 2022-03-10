if exists (select * from sysobjects where type='TR' and name = 'InsertNAMESEARCHRESULT_ids')
begin
	PRINT 'Refreshing trigger InsertNAMESEARCHRESULT_ids...'
	DROP TRIGGER InsertNAMESEARCHRESULT_ids
end
go

Create trigger InsertNAMESEARCHRESULT_ids on NAMESEARCHRESULT for INSERT NOT FOR REPLICATION as
Begin
-- TRIGGER:	InsertNAMESEARCHRESULT_ids    
-- VERSION:	3
-- DESCRIPTION:	

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 03 Mar 2011	MF	6563 	1	Created
-- 03 Apr 2011	MF	10431	2	Use the PRIORARTFLAG to determine the Cases to link.
-- 03 May 2011	MF	10548	3	Insert the CASESEARCHRESULT row even if the Case is already
--					linked to the Prior Art as a related Case.

	--------------------------------------------------------
	-- For each Case that is associated with a Name that has
	-- been linked to a Search Result, we need to generate
	-- the link between the Case and the Search Result.
	-- These links will be generated if SearchResult is not
	-- a source document OR if it is a source document that
	-- is required to also be reported.
	--------------------------------------------------------
	Insert into CASESEARCHRESULT(NAMEPRIORARTID, CASEID, PRIORARTID, STATUS, UPDATEDDATE,ISCASERELATIONSHIP)
	Select distinct i.NAMEPRIORARTID, C.CASEID, i.PRIORARTID, CASE WHEN(CS1.STATUS=-999999999) THEN NULL ELSE CS1.STATUS END, getdate(),0
	From inserted i
	join SEARCHRESULTS S	on (S.PRIORARTID=i.PRIORARTID)
	left join TABLECODES T	on (T.TABLECODE=S.SOURCE)
			---------------------------------------------
			-- Get Cases associated with the NameNo
			---------------------------------------------
	join CASENAME CN	on (CN.NAMENO=i.NAMENO
				and CN.NAMETYPE=isnull(i.NAMETYPE,CN.NAMETYPE)  -- NameType may optionally be specified
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
				and CS1.PRIORARTID=i.PRIORARTID)
			---------------------------------------------
			-- Do not insert the row if it already exists
			---------------------------------------------
	left join CASESEARCHRESULT CS2 
				on (CS2.NAMEPRIORARTID=i.NAMEPRIORARTID
				and CS2.CASEID=C.CASEID
				and CS2.PRIORARTID=i.PRIORARTID
				and isnull(CS2.ISCASERELATIONSHIP,0)=0)
			---------------------------------------------
			-- Only interested in Cases flagged to report
			---------------------------------------------
	     join COUNTRY CT	on (CT.COUNTRYCODE=C.COUNTRYCODE)
	left join STATUS ST	on (ST.STATUSCODE =C.STATUSCODE)
	where (T.BOOLEANFLAG=1 OR isnull(S.ISSOURCEDOCUMENT,0)=0)
	and  CS2.CASEID is null
	and   CT.PRIORARTFLAG=1
	and ( ST.STATUSCODE is null OR ST.PRIORARTFLAG=1)

	-------------------------------------------------------
	-- Name linked to Source Document
	-- A Source Document may bundle together any number of
	-- cited Search Results (prior art). When a Name is
	-- associated with a Source Document it should create
	-- links for Cases associated to the Name, to each
	-- Search Result linked to the Source Document.
	-- NOTE: The Source Document itself has already 
	--       been linked directly to the Cases in the
	--       previous Insert.
	-------------------------------------------------------
	Insert into CASESEARCHRESULT(NAMEPRIORARTID, CASEID, PRIORARTID, STATUS, UPDATEDDATE,ISCASERELATIONSHIP)
	Select distinct i.NAMEPRIORARTID, C.CASEID, R.CITEDPRIORARTID, CASE WHEN(CS1.STATUS=-999999999) THEN NULL ELSE CS1.STATUS END, getdate(),0
	From inserted i
	join SEARCHRESULTS S	on (S.PRIORARTID=i.PRIORARTID)
			---------------------------------------------
			-- Find prior art cited in Source Document
			---------------------------------------------
	join REPORTCITATIONS R	on (R.SEARCHREPORTID=S.PRIORARTID)
			---------------------------------------------
			-- Get Cases associated with the NameNo
			---------------------------------------------
	join CASENAME CN	on (CN.NAMENO=i.NAMENO
				and CN.NAMETYPE=isnull(i.NAMETYPE,CN.NAMETYPE)  -- NameType may optionally be specified
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
				and CS1.PRIORARTID=R.CITEDPRIORARTID)
			---------------------------------------------
			-- Do not insert the row if it already exists
			---------------------------------------------
	left join CASESEARCHRESULT CS2 
				on (CS2.NAMEPRIORARTID=i.NAMEPRIORARTID
				and CS2.CASEID=C.CASEID
				and CS2.PRIORARTID=R.CITEDPRIORARTID
				and isnull(CS2.ISCASERELATIONSHIP,0)=0)
			---------------------------------------------
			-- Only interested in Cases flagged to report
			---------------------------------------------
	     join COUNTRY CT	on (CT.COUNTRYCODE=C.COUNTRYCODE)
	left join STATUS ST	on (ST.STATUSCODE =C.STATUSCODE)
	where S.ISSOURCEDOCUMENT=1
	and  CS2.CASEID is null
	and   CT.PRIORARTFLAG=1
	and ( ST.STATUSCODE is null OR ST.PRIORARTFLAG=1)


End
go
