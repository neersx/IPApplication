-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ip_PolicePriorArtDistributions
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[ip_PolicePriorArtDistributions]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.ip_PolicePriorArtDistributions.'
	drop procedure dbo.ip_PolicePriorArtDistributions
end
print '**** Creating procedure dbo.ip_PolicePriorArtDistributions...'
print ''
go

set QUOTED_IDENTIFIER off
go
set ANSI_NULLS on
go

create procedure dbo.ip_PolicePriorArtDistributions
			@pnDebugFlag		tinyint
as
-- PROCEDURE :	ip_PolicePriorArtDistributions
-- VERSION :	8
-- DESCRIPTION:	Cater for requests to distribute Prior Art across the extended Case family 
--		determined from RelatedCases. The potential for large volumes of Cases
--		that can be impacted has required this to run as a separate asynchronous 
--		process from the triggering activity.

-- MODIFICATION
-- Date		Who	SQA	Version
-- ====         ===	=== 	=======
-- 10 Jun 2015	MF	45361	1	Procedure created
-- 24 Jun 2015	MF	48992	2	Where multiple Cases have requested Prior Art Distribution, it was possible to cause a 
--					duplicate key error on the #TEMPRELATEDCASES table. This has been corrected with a change
--					of index.
-- 16 Jul 2016	MF	63843	3	If COUNTRY.PRIORARTFLAG is null it should default to 0.
-- 18 Aug 2016	MF	65449	4	When 2 cases related to each other have each separately triggered Policing to distribute
--					prior art, then the system was failing to share the prior art directly between those 2 cases.
-- 19 Aug 2016	MF	65449	5	Rework. Also need to change the primary key on #TEMPRELATEDCASES to incorporate DEPTH.
-- 27 Mar 2018	MF	73696	6	When two cases were related to each other at the same time, and the Status of at least one of those
--					cases was such that Prior Art was no longer being associated (PRIORARTFLAG=0), then the full set of 
--					prior art for the new extended network of Cases was not flowing to all cases.
-- 14 Nov 2018  AV	DR-45358 7	Date conversion errors when creating cases and opening names in Chinese DB
-- 03 Jul 2019	MF	DR-50048 8	When a Case does not have a Status, then the PRIORARTFLAG should be assumed to be set to 1, otherwise
--					if the PRIORARTFLAG for the STATUS is null, then it should be treated as 0.
--		

set nocount on

Create table #TEMPRELATEDCASES
	(	MAINCASEID	int		not null,
		RELATEDCASEID	int		not null,
		DEPTH		int		not null,
		STATUSFLAG	bit		not null,
		COUNTRYFLAG	bit		not null
	)

Create Unique Index XAK1TEMPRELATEDCASES ON #TEMPRELATEDCASES
(
	MAINCASEID,
	RELATEDCASEID,
	DEPTH
)

Declare	@ErrorCode	int
Declare @sSQLString	nvarchar(max)

Declare @nRowCount		int
Declare @nRowTotal		int
Declare	@nDepth			int

-- Initialise the errorcode and then set it after each SQL Statement

Set @ErrorCode = 0
Set @nRowTotal = 0
Set @nRowCount = 0
Set @nDepth    = 1

--------------------------------------------------------
-- We need to consider the extended set of related Cases 
-- to ensure all Prior Art is distributed across all of 
-- those Cases where Prior Art is reportable.
--------------------------------------------------------
If @ErrorCode=0
Begin	
	-------------------------------------------------------
	-- For each Case that is being related to another Case 
	-- we need to find every other Case that is related 
	-- either directly or indirectly via RELATEDCASE, and 
	-- ensure its prior art is inserted.
	-------------------------------------------------------
	
	--------------------------------------------
	-- Only rows being loaded that do not have
	-- the ISCASERELATIONSHIP flag set to 1 are
	-- to trigger the inclusion of related cases
	-- and Case Event insertion.
	-- This is because when a CASESEARCHRESULT
	-- row is deleted, the delete trigger will
	-- remove and reinsert CASESEARCHRESULT rows
	-- that do not need to be processed here.
	--------------------------------------------
	Set @sSQLString="
	insert into #TEMPRELATEDCASES(MAINCASEID,RELATEDCASEID,DEPTH, STATUSFLAG, COUNTRYFLAG)
	select distinct P.CASEID, P.CASEID, @nDepth, CASE WHEN(C.STATUSCODE is null) THEN 1 ELSE isnull(S.PRIORARTFLAG,0) END, isnull(CT.PRIORARTFLAG,0)
	from #TEMPPOLICING P
	join CASES C		on (C.CASEID=P.CASEID)
	join COUNTRY CT		on (CT.COUNTRYCODE=C.COUNTRYCODE)
	left join STATUS S	on (S.STATUSCODE  =C.STATUSCODE)
	where P.TYPEOFREQUEST=9"
	
	exec @ErrorCode=sp_executesql @sSQLString,
					N'@nDepth	int',
					  @nDepth=@nDepth

	Set @nRowCount=@@Rowcount
	Set @nRowTotal=@nRowTotal+@nRowCount

	--------------------------------------------
	-- Now loop through each row just added and 
	-- get all of the cases related in any way.
	--------------------------------------------
	While @nRowCount>0
	and @ErrorCode=0
	Begin
		Set @sSQLString="
		insert into #TEMPRELATEDCASES(MAINCASEID, RELATEDCASEID,DEPTH, STATUSFLAG, COUNTRYFLAG)
		select T.MAINCASEID, R.RELATEDCASEID, @nDepth+1, CASE WHEN(C.STATUSCODE is null) THEN 1 ELSE isnull(S.PRIORARTFLAG,0) END, isnull(CT.PRIORARTFLAG,0)
		from #TEMPRELATEDCASES T
		join RELATEDCASE R	on (R.CASEID=T.RELATEDCASEID)
		join CASERELATION CR	on (CR.RELATIONSHIP=R.RELATIONSHIP
					and CR.PRIORARTFLAG=1)
		join CASES C		on (C.CASEID=R.RELATEDCASEID)
		join COUNTRY CT		on (CT.COUNTRYCODE=C.COUNTRYCODE)
		left join STATUS S	on (S.STATUSCODE  =C.STATUSCODE)						
		left join #TEMPRELATEDCASES T1
					on (T1.MAINCASEID   =T.MAINCASEID
					and T1.RELATEDCASEID=R.RELATEDCASEID)
		where T.DEPTH=@nDepth
		and T1.MAINCASEID is null
		and R.RELATEDCASEID is not null
		UNION
		select T.MAINCASEID, R.CASEID, @nDepth+1, CASE WHEN(C.STATUSCODE is null) THEN 1 ELSE isnull(S.PRIORARTFLAG,0) END, isnull(CT.PRIORARTFLAG,0)
		from #TEMPRELATEDCASES T
		join RELATEDCASE R	on (R.RELATEDCASEID=T.RELATEDCASEID)
		join CASERELATION CR	on (CR.RELATIONSHIP=R.RELATIONSHIP
					and CR.PRIORARTFLAG=1)
		join CASES C		on (C.CASEID=R.CASEID)
		join COUNTRY CT		on (CT.COUNTRYCODE=C.COUNTRYCODE)
		left join STATUS S	on (S.STATUSCODE  =C.STATUSCODE)
		left join #TEMPRELATEDCASES T1
					on (T1.MAINCASEID   =T.MAINCASEID
					and T1.RELATEDCASEID=R.CASEID)
		where T.DEPTH=@nDepth
		and T1.MAINCASEID is null"
	
		exec @ErrorCode=sp_executesql @sSQLString,
					N'@nDepth	int',
					  @nDepth=@nDepth

		Set @nRowCount=@@ROWCOUNT
		Set @nRowTotal=@nRowTotal+@nRowCount

		set @nDepth=@nDepth+1
	End

	-----------------------------------------------
	-- Now for each different MAINCASEID we need to
	-- find one CASESEARCHRESULT row attached to
	-- any other Case in the same tree that can 
	-- then be inserted into one other Case in that
	-- tree.
	-----------------------------------------------
	If  @nRowTotal>0
	and @ErrorCode=0
	Begin
		Set @sSQLString="
		With PriorArt (MAINCASEID, PRIORARTID, FAMILYPRIORARTID, CASELISTPRIORARTID, NAMEPRIORARTID)
			    ----------------------------------
			    -- Get a complete unique set of 
			    -- prior art referenced by any
			    -- case within the extended family
			    ----------------------------------
			as (Select distinct T.MAINCASEID, CS.PRIORARTID, CS.FAMILYPRIORARTID, CS.CASELISTPRIORARTID, CS.NAMEPRIORARTID
			    from #TEMPRELATEDCASES T
			    join CASESEARCHRESULT CS on (CS.CASEID=T.RELATEDCASEID)
			    )
		Insert into #TEMPCASESEARCHRESULT(FAMILYPRIORARTID,CASEID,PRIORARTID,STATUS,UPDATEDDATE,CASEFIRSTLINKEDTO,CASELISTPRIORARTID,NAMEPRIORARTID,ISCASERELATIONSHIP)
		select Distinct PA.FAMILYPRIORARTID,RC.RELATEDCASEID,PA.PRIORARTID,null,getdate(),0,PA.CASELISTPRIORARTID,PA.NAMEPRIORARTID,1
			    ------------------------------------
			    -- For the extended family of cases.
			    ------------------------------------
		from #TEMPRELATEDCASES RC
			    ----------------------------------
			    -- Find the full set of Prior
			    -- Art associated with the family.
			    ----------------------------------
		join PriorArt PA	  on (PA.MAINCASEID =RC.MAINCASEID)
			    ----------------------------------
			    -- Now check to see if all prior
			    -- art has been associated with
			    -- each case in the family.
			    ----------------------------------
		left join CASESEARCHRESULT CSR
					  on (CSR.PRIORARTID=PA.PRIORARTID
					  and CSR.CASEID    =RC.RELATEDCASEID)
		Where RC.COUNTRYFLAG=1
		and   RC.STATUSFLAG =1
		and   CSR.CASEID is null"
	
		exec @ErrorCode=sp_executesql @sSQLString
	End
End

If  @pnDebugFlag>0 
and @ErrorCode=0
Begin
	declare @sTimeStamp	nvarchar(24)
	set 	@sTimeStamp=convert(nvarchar,getdate(),126)
	RAISERROR ('%s ip_PolicePriorArtDistributions',0,1,@sTimeStamp ) with NOWAIT

	If @pnDebugFlag>2
	Begin
		Set @sSQLString="
		Select	*
		from	#TEMPCASESEARCHRESULT T
		order by CASEID, PRIORARTID"

		Exec @ErrorCode=sp_executesql @sSQLString
	End
End

--------------------------------------
-- Drop the temporary table created in
-- this stored procedure.
--------------------------------------
If @ErrorCode=0
Begin
	drop table #TEMPRELATEDCASES
End

return @ErrorCode
go

grant execute on dbo.ip_PolicePriorArtDistributions  to public
go
