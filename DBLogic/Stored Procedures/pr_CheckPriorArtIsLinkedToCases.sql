-----------------------------------------------------------------------------------------------------------------------------
-- Creation of pr_CheckPriorArtIsLinkedToCases
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[pr_CheckPriorArtIsLinkedToCases]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.pr_CheckPriorArtIsLinkedToCases.'
	drop procedure dbo.pr_CheckPriorArtIsLinkedToCases
end
print '**** Creating procedure dbo.pr_CheckPriorArtIsLinkedToCases...'
print ''
go

set QUOTED_IDENTIFIER off
go
set ANSI_NULLS on
go

Create Procedure dbo.pr_CheckPriorArtIsLinkedToCases
			@pnRowCount		int		= null output,
			@pnUserIdentityId	int,		-- Mandatory
			@psCulture		nvarchar(10) 	= null,
			@pbCopyPriorArtToCases	bit		= 0
as 
-- PROCEDURE :	pr_CheckPriorArtIsLinkedToCases
-- VERSION :	4
-- DESCRIPTION:	Construct a list of the extended family of Cases that are related
--		in a manner that allows Prior Art to flow between those Cases. For 
--		each family, get the full set of Prior Art and then determine 
--		if any Cases within the family that are eligible to receive the 
--		art are missing any of it.
-- CALLED BY :	

-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 10 Mar 2015	MF	45361	1	Procedure created
-- 14 Mar 2015	MF	45361	2	Rework to improve performance for large families with large amount of prior art.
-- 16 Jul 2016	MF	63843	3	If COUNTRY.PRIORARTFLAG is null it should default to 0.	
-- 28 Mar 2018	MF	73696	4	When updating the Prior Art only apply a single Family of cases at a time so as to 
--					reduce the length of the database transaction. 
--					Also change the temporary table name to #TEMPCASEFAMILY to avoid clash with temporary
--					table in the the InsertCASESEARCHRESULT_ids trigger.				

-- disable row counts
set nocount on

-------------------------------------------------------
-- For each Case that is being related to another Case 
-- we need to find every other Case that is related 
-- either directly or indirectly via RELATEDCASE, and 
-- ensure its prior art is inserted.
-------------------------------------------------------

CREATE TABLE #TEMPCASEFAMILY (
	CASEID			int	not null,
	FAMILYID		int	not null,
	DEPTH			int	not null,
	STATUSFLAG		bit	not null,
	COUNTRYFLAG		bit	not null
	)

CREATE CLUSTERED INDEX XPKTEMPCASEFAMILY ON #TEMPCASEFAMILY
	(
	CASEID
	)

CREATE INDEX XIE1TEMPCASEFAMILY ON #TEMPCASEFAMILY
	 (
	 FAMILYID,
	 DEPTH
	 )
	
declare	@sSQLString	nvarchar(max)

declare	@ErrorCode	int
declare	@TranCountStart	int

declare	@nCaseId	int
declare	@nFamilyId	int
declare @nCurrentFamily	int

declare @nRowCount	int
declare @nRowTotal	int
declare	@nDepth		int

Set	@ErrorCode=0
Set	@nRowCount =0
Set	@nFamilyId=0

If @ErrorCode=0
Begin
	------------------------------
	-- Get the first Property type
	-- case for which the extended
	-- family is to be found.
	------------------------------
	Set @sSQLString="
	Select	@nCaseId=min(CASEID)
	from	CASES
	where	CASETYPE='A'"
	
	exec @ErrorCode=sp_executesql @sSQLString,
				N'@nCaseId	int	OUTPUT',
				  @nCaseId=@nCaseId	OUTPUT
End

----------------------------------
-- Loop through each Case and then
-- determine the extended family
-- for that Case.
----------------------------------
While @nCaseId is not null
and   @ErrorCode=0
Begin
	------------------------------
	-- Starting a new family of
	-- extended cases so increment
	-- the FamilyId and reset the
	-- counters.
	------------------------------
	Set @nFamilyId=@nFamilyId+1
	
	Set @nRowTotal=0
	Set @nRowCount=0
	Set @nDepth   =1
	--------------------------------------------
	-- Only rows being loaded that do not have
	-- the ISCASERELATIONSHIP flag set to 1 are
	-- to trigger the inclusion of related cases
	-- and Case Event insertion.
	-- This is because when a CASESEARCHRESULT
	-- row is deleted it the delete trigger will
	-- remove and reinsert CASESEARCHRESULT rows
	-- that do not need to be processed here.
	--------------------------------------------
	insert into #TEMPCASEFAMILY(FAMILYID, CASEID, DEPTH, STATUSFLAG, COUNTRYFLAG)
	select distinct @nFamilyId, C.CASEID, @nDepth, isnull(S.PRIORARTFLAG,1), isnull(CT.PRIORARTFLAG,0)
	from CASES C
	join COUNTRY CT		on (CT.COUNTRYCODE=C.COUNTRYCODE)
	left join STATUS S	on (S.STATUSCODE  =C.STATUSCODE)
	where C.CASEID=@nCaseId

	set @nRowCount=@@Rowcount
	Set @nRowTotal=@nRowTotal+@nRowCount

	--------------------------------------------
	-- Now loop through each row just added and 
	-- get all of the cases related in any way.
	--------------------------------------------
	While @nRowCount>0
	Begin
		Set @sSQLString="
		insert into #TEMPCASEFAMILY(FAMILYID, CASEID,DEPTH, STATUSFLAG, COUNTRYFLAG)
		select @nFamilyId, R.RELATEDCASEID, @nDepth+1, isnull(S.PRIORARTFLAG,1), isnull(CT.PRIORARTFLAG,0)
		from #TEMPCASEFAMILY T
		join RELATEDCASE R	on (R.CASEID=T.CASEID)
		join CASERELATION CR	on (CR.RELATIONSHIP=R.RELATIONSHIP
					and CR.PRIORARTFLAG=1)
		join CASES C		on (C.CASEID=R.RELATEDCASEID
					and C.CASETYPE='A')
		join COUNTRY CT		on (CT.COUNTRYCODE=C.COUNTRYCODE)
		left join STATUS S	on (S.STATUSCODE  =C.STATUSCODE)						
		left join #TEMPCASEFAMILY T1
					on (T1.CASEID=R.RELATEDCASEID)
		where T.FAMILYID=@nFamilyId
		and   T.DEPTH   =@nDepth
		and  T1.CASEID is null
		UNION
		select @nFamilyId, R.CASEID, @nDepth+1, isnull(S.PRIORARTFLAG,1), isnull(CT.PRIORARTFLAG,0)
		from #TEMPCASEFAMILY T
		join RELATEDCASE R	on (R.RELATEDCASEID=T.CASEID)
		join CASERELATION CR	on (CR.RELATIONSHIP=R.RELATIONSHIP
					and CR.PRIORARTFLAG=1)
		join CASES C		on (C.CASEID=R.CASEID
					and C.CASETYPE='A')
		join COUNTRY CT		on (CT.COUNTRYCODE=C.COUNTRYCODE)
		left join STATUS S	on (S.STATUSCODE  =C.STATUSCODE)
		left join #TEMPCASEFAMILY T1
					on (T1.CASEID=R.CASEID)
		where T.FAMILYID=@nFamilyId
		and   T.DEPTH   =@nDepth
		and  T1.CASEID is null"
		
		exec @ErrorCode=sp_executesql @sSQLString,
					N'@nFamilyId	int,
					  @nDepth	int',
					  @nFamilyId=@nFamilyId,
					  @nDepth   =@nDepth

		Set @nRowCount=@@ROWCOUNT
		Set @nRowTotal=@nRowTotal+@nRowCount

		set @nDepth=@nDepth+1
	End
		
	If @ErrorCode=0
	Begin
		------------------------------
		-- Get the next Property type
		-- case for which the extended
		-- family is yet to be found.
		------------------------------
		Set @sSQLString="
		Select	@nCaseId=min(C.CASEID)
		from	CASES C
		left join
			#TEMPCASEFAMILY T on (T.CASEID=C.CASEID)
		where	C.CASETYPE='A'
		and	C.CASEID>@nCaseId
		and	T.CASEID is null"
		
		exec @ErrorCode=sp_executesql @sSQLString,
				N'@nCaseId	int	OUTPUT',
				  @nCaseId=@nCaseId	OUTPUT
	End
End
-----------------------------------------
-- Now that all Cases have been grouped
-- into their extended family, check that
-- the full set of Prior Art has been
-- linked to all of the Cases in the 
-- extended family that are eligible to
-- receive prior art.
-----------------------------------------
IF  @ErrorCode=0
and @pbCopyPriorArtToCases=0
Begin
	Set @sSQLString="
	With PriorArt (FAMILYID, PRIORARTID)
		    ----------------------------------
		    -- Get a complete unique set of 
		    -- prior art referenced by any
		    -- case within the extended family
		    ----------------------------------
		as (Select distinct T.FAMILYID, CS.PRIORARTID
		    from #TEMPCASEFAMILY T
		    join CASESEARCHRESULT CS on (CS.CASEID=T.CASEID)
		    )			  
	select C.IRN, PA.PRIORARTID
		    ----------------------------------
		    -- For each Case in the extended 
		    -- family of Cases.
		    ----------------------------------
	from #TEMPCASEFAMILY RC
	join CASES C              on (C.CASEID      =RC.CASEID)
		    ----------------------------------
		    -- Find the full set of Prior
		    -- Art linked to the family.
		    ----------------------------------
	join PriorArt PA	  on (PA.FAMILYID   =RC.FAMILYID)
		    ----------------------------------
		    -- Now check to see if the prior
		    -- art has in fact been associated
		    -- with the case.
		    ----------------------------------
	left join CASESEARCHRESULT CSR
	                          on (CSR.PRIORARTID=PA.PRIORARTID
	                          and CSR.CASEID    =RC.CASEID)
	Where RC.COUNTRYFLAG=1
	and   RC.STATUSFLAG =1
	and   CSR.CASEID is null
	order by 1, 2"
	
	execute @ErrorCode=sp_executesql @sSQLString
	
	Set @pnRowCount=@@Rowcount
End

If  @ErrorCode=0
and @pbCopyPriorArtToCases=1
Begin
	----------------------------------
	-- Associate the Prior Art that is
	-- missing from Cases in the same 
	-- extended family to those other
	-- member Cases.
	----------------------------------
	Set @nCurrentFamily=1

	While @nCurrentFamily <= @nFamilyId
	and   @ErrorCode = 0
	Begin
		Select @TranCountStart = @@TranCount
		BEGIN TRANSACTION
	
		Set @sSQLString="
		With PriorArt (FAMILYID, PRIORARTID)
			    ----------------------------------
			    -- Get a complete unique set of 
			    -- prior art referenced by any
			    -- case within the extended family
			    ----------------------------------
			as (Select distinct T.FAMILYID, CS.PRIORARTID
			    from #TEMPCASEFAMILY T
			    join CASESEARCHRESULT CS on (CS.CASEID=T.CASEID)
			    where FAMILYID=@nCurrentFamily
			    )		
		Insert into CASESEARCHRESULT(FAMILYPRIORARTID,CASEID,PRIORARTID,STATUS,UPDATEDDATE,CASEFIRSTLINKEDTO,CASELISTPRIORARTID,NAMEPRIORARTID,ISCASERELATIONSHIP)
		select distinct null,RC.CASEID,PA.PRIORARTID,null,getdate(),0,null,null,1
			    ----------------------------------
			    -- For each Case in the extended 
			    -- family of Cases.
			    ----------------------------------
		from #TEMPCASEFAMILY RC
		join CASES C              on (C.CASEID      =RC.CASEID)
			    ----------------------------------
			    -- Find the full set of Prior
			    -- Art linked to the family.
			    ----------------------------------
		join PriorArt PA	  on (PA.FAMILYID   =RC.FAMILYID)
			    ----------------------------------
			    -- Now check to see if the prior
			    -- art has in fact been associated
			    -- with the case.
			    ----------------------------------
		left join CASESEARCHRESULT CSR
					  on (CSR.PRIORARTID=PA.PRIORARTID
					  and CSR.CASEID    =RC.CASEID)
		Where RC.COUNTRYFLAG=1
		and   RC.STATUSFLAG =1
		and   RC.FAMILYID   = @nCurrentFamily
		and   CSR.CASEID is null"
	
		execute @ErrorCode=sp_executesql @sSQLString,
						N'@nCurrentFamily	int',
						  @nCurrentFamily=@nCurrentFamily
	
		Set @pnRowCount=@@Rowcount

		-- Commit or Rollback the transaction

		If @@TranCount > @TranCountStart
		Begin
			If @ErrorCode = 0
			Begin
				COMMIT TRANSACTION
			End
			Else Begin
				ROLLBACK TRANSACTION
			End
		End

		Set @nCurrentFamily = @nCurrentFamily + 1
	End -- Loop through @nFamilyId
	-----------------------------------------
	-- Now rerun the query to see if there
	-- are still missing Prior Art from Cases
	-- belonging to an extended family.
	-----------------------------------------
	IF @ErrorCode=0
	Begin
		Set @sSQLString="
		With PriorArt (FAMILYID, PRIORARTID)
			    ----------------------------------
			    -- Get a complete unique set of 
			    -- prior art referenced by any
			    -- case within the extended family
			    ----------------------------------
			as (Select distinct T.FAMILYID, CS.PRIORARTID
			    from #TEMPCASEFAMILY T
			    join CASESEARCHRESULT CS on (CS.CASEID=T.CASEID)
			    )			  
		select C.IRN, PA.PRIORARTID
			    ----------------------------------
			    -- For each Case in the extended 
			    -- family of Cases.
			    ----------------------------------
		from #TEMPCASEFAMILY RC
		join CASES C              on (C.CASEID      =RC.CASEID)
			    ----------------------------------
			    -- Find the full set of Prior
			    -- Art linked to the family.
			    ----------------------------------
		join PriorArt PA	  on (PA.FAMILYID   =RC.FAMILYID)
			    ----------------------------------
			    -- Now check to see if the prior
			    -- art has in fact been associated
			    -- with the case.
			    ----------------------------------
		left join CASESEARCHRESULT CSR
					  on (CSR.PRIORARTID=PA.PRIORARTID
					  and CSR.CASEID    =RC.CASEID)
		Where RC.COUNTRYFLAG=1
		and   RC.STATUSFLAG =1
		and   CSR.CASEID is null
		order by 1, 2"
		
		execute @ErrorCode=sp_executesql @sSQLString
		
		Set @pnRowCount=@@Rowcount
	End
End

Return @ErrorCode
go 

grant execute on dbo.pr_CheckPriorArtIsLinkedToCases to public
go
