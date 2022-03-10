-----------------------------------------------------------------------------------------------------------------------------
-- Creation of cs_CheckEarliestPriorityDate
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[cs_CheckEarliestPriorityDate]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.cs_CheckEarliestPriorityDate.'
	drop procedure dbo.cs_CheckEarliestPriorityDate
end
print '**** Creating procedure dbo.cs_CheckEarliestPriorityDate...'
print ''
go

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

CREATE PROCEDURE dbo.cs_CheckEarliestPriorityDate
(
	@pnRowCount			int		= null	OUTPUT,
	@pnUserIdentityId		int		= null, 
	@psCulture			nvarchar(10)	= null, -- the language in which output is to be expressed
	@psRelationship			nvarchar(3)	= 'BAS',-- optional Case Relationship to be used as basis of check
	@psCaseCategory			nvarchar(2)	= 'I',	-- Category for Continuation In Part which checks direct Parent.
	@pnCaseId			int		= null	-- optional. Null if all Cases are required
)
AS
-- PROCEDURE :	cs_CheckEarliestPriorityDate
-- VERSION :	4
-- DESCRIPTION: Considers a family of Cases by Relationship and validates the Priority Dates.
--		If a CaseId has been provided then the family of that Case will be the starting point.
--		For each family the hierarchy is established by considering how the Cases relate to each other.
--		Continuation in Part cases (determined from Case Category) will check against the direct parent
--		case to determine what should be the priority date.

-- MODIFICTIONS :
-- Date         Who	Number	Version	Change
-- ------------ ----	------	-------	------------------------------------------- 
-- 01 Sep 2009	MF	18018	1	Procedure created
-- 09 Sep 2009	MF	18018	2	Remove some test code
-- 05 Jul 2013	vql	R13629	3	Remove string length restriction and use nvarchar on datetime conversions using 106 format.
-- 14 Nov 2018  AV  75198/DR-45358	4   Date conversion errors when creating cases and opening names in Chinese DB

set nocount on
SET CONCAT_NULL_YIELDS_NULL OFF

Create table #TEMPCASETREE (
			FAMILYID		int		not null,
			DEPTH			smallint	not null,
			PARENTCASE		int		null,
			PARENTOFFICIALNO	nvarchar(36)	collate database_default null,
			CHILDCASE		int		null,
			RELATIONSHIP		nvarchar(3)	collate database_default  null,
			COUNTRYCODE		nvarchar(3)	collate database_default null,
			PRIORITYDATE		datetime	null,
			ROWNUMBER		int		identity(1,1)
			)
Create index XIE1TEMPCASETREE on #TEMPCASETREE (FAMILYID   ASC,
                                                DEPTH      ASC)
Create index XIE2TEMPCASETREE on #TEMPCASETREE (PARENTCASE ASC)
Create index XIE3TEMPCASETREE on #TEMPCASETREE (CHILDCASE  ASC)

declare @ErrorCode	int
declare @nTotalRows	int
declare	@nFamilyId	int
declare @nCaseId	int
declare @sSQLString	nvarchar(4000)

Declare @sLookupCulture nvarchar(10)

set @ErrorCode =0
set @nTotalRows=0
set @nFamilyId =0
set @nCaseId   =@pnCaseId

---------------------------------------------
-- Loop through Cases that are at the lowest
-- point in the hierarchy. These will be 
-- pointing to a Parent Case but will not have
-- any child Cases.
-- Note: 
--    Cases must be pointing to a parent
--    that is also a child Case otherwise
--    there is no complex hierarchy and do 
--    not need to be considered until after
--    the multi level hierarchy is Cases have
--    been considered.
---------------------------------------------
If  @ErrorCode=0
and @nCaseId is null
Begin
	Set @sSQLString="
	Select @nCaseId=min(P.CASEID)
	from RELATEDCASE P
	join RELATEDCASE G on (G.CASEID=P.RELATEDCASEID
			   and G.RELATIONSHIP=P.RELATIONSHIP)
	Where P.RELATIONSHIP=@psRelationship
	and not exists
	(select 1 from RELATEDCASE C
	 where C.RELATEDCASEID=P.CASEID
	 and C.RELATIONSHIP=P.RELATIONSHIP)"

	exec @ErrorCode=sp_executesql @sSQLString,
				N'@nCaseId		int	OUTPUT,
				  @psRelationship	nvarchar(3)',
				  @nCaseId       =@nCaseId	OUTPUT,
				  @psRelationship=@psRelationship
End

------------------------------------
-- Loop through each family of Cases
------------------------------------
While @nCaseId is not null
and @ErrorCode=0
Begin
	-----------------------------------------
	-- Increment the FamilyId used to link
	-- all Cases from the one family together
	-----------------------------------------
	Set @nFamilyId=@nFamilyId+1 
	-----------------------------------------
	-- Start at a DEPTH=1 where the root Case
	-- will be the first Case found for the
	-- family
	--
	-- NOTE : The RelatedCase relationship 
	--        describes the relationship from 
	--        the CHILD (CASEID) to the 
	--        PARENT (RELATEDCASEID) case.
	-----------------------------------------

	if @ErrorCode = 0
	begin
		Set @sSQLString="
		insert into #TEMPCASETREE(DEPTH, PARENTCASE, CHILDCASE, RELATIONSHIP, FAMILYID)
		select 1, R1.RELATEDCASEID, R1.CASEID, R1.RELATIONSHIP, @nFamilyId
		from RELATEDCASE R1
		where R1.RELATEDCASEID=@nCaseId	
		and R1.RELATIONSHIP=@psRelationship
		---------------------------------------------
		-- exclude Child cases who have a Parent that
		-- is also a Child case of the current Case
		-- as these will appear at a lower depth.
		---------------------------------------------
		and not exists
		(select 1 
		 from RELATEDCASE R2
		 where R2.CASEID=R1.CASEID
		 and   R2.RELATIONSHIP=R1.RELATIONSHIP
		 and   R2.RELATEDCASEID in (	select R3.CASEID
						from RELATEDCASE R3
						where R3.RELATEDCASEID=R1.RELATEDCASEID
						and R3.RELATIONSHIP=R1.RELATIONSHIP))"

		exec @ErrorCode=sp_executesql @sSQLString,
					N'@nCaseId		int,
					  @nFamilyId		int,
					  @psRelationship	nvarchar(3)',
					  @nCaseId  =@nCaseId,
					  @nFamilyId=@nFamilyId,
					  @psRelationship=@psRelationship

		set @pnRowCount=@@Rowcount

		Set @nTotalRows=@nTotalRows+@pnRowCount
	End
	---------------------------------------
	-- Process down each child Case to load
	-- any children that it may also have.
	---------------------------------------
	WHILE	@pnRowCount>0
	and	@ErrorCode=0
	begin
		Set @sSQLString="
		insert into #TEMPCASETREE(DEPTH, PARENTCASE, CHILDCASE, RELATIONSHIP, FAMILYID)
		select distinct T.DEPTH+1, R1.RELATEDCASEID, R1.CASEID, R1.RELATIONSHIP,T.FAMILYID
		from #TEMPCASETREE T
		join RELATEDCASE R1 on (R1.RELATEDCASEID=T.CHILDCASE
		                    and R1.RELATIONSHIP =T.RELATIONSHIP)
		left join #TEMPCASETREE T1 on (T1.PARENTCASE=R1.CASEID
					   and T1.FAMILYID=T.FAMILYID)	
		where T.FAMILYID=@nFamilyId
		and T.DEPTH=(select max(DEPTH) from #TEMPCASETREE where FAMILYID=@nFamilyId)
		and T1.PARENTCASE is null
		---------------------------------------------
		-- exclude Child cases who have a Parent that
		-- is also a Child case of the current Case
		-- as these will appear at a lower depth.
		---------------------------------------------
		and not exists
		(select 1 
		 from RELATEDCASE R2
		 where R2.CASEID=R1.CASEID
		 and   R2.RELATIONSHIP=R1.RELATIONSHIP
		 and   R2.RELATEDCASEID in (	select R3.CASEID
						from RELATEDCASE R3
						where R3.RELATEDCASEID=R1.RELATEDCASEID
						and R3.RELATIONSHIP=R1.RELATIONSHIP))"

		exec @ErrorCode=sp_executesql @sSQLString,
					N'@nFamilyId		int',
					  @nFamilyId=@nFamilyId

		Set @pnRowCount=@@Rowcount

		Set @nTotalRows=@nTotalRows+@pnRowCount
	end

	------------------------------------------
	-- Now work in reverse and find the parent
	-- of the root Case Starting at DEPTH=0 
	-- and working back.
	--
	-- NOTE : The RelatedCase relationship 
	--        describes the relationship from 
	--        the CHILD (CASEID) to the 
	--        PARENT (RELATEDCASEID) case.
	------------------------------------------

	if @ErrorCode = 0
	begin
		Set @sSQLString="
		insert into #TEMPCASETREE(DEPTH, PARENTCASE, PARENTOFFICIALNO, CHILDCASE, RELATIONSHIP, COUNTRYCODE, PRIORITYDATE, FAMILYID)
		select 0, R1.RELATEDCASEID, R1.OFFICIALNUMBER, R1.CASEID, R1.RELATIONSHIP, R1.COUNTRYCODE,R1.PRIORITYDATE, @nFamilyId
		from RELATEDCASE R1
		where R1.CASEID=@nCaseId	
		and R1.RELATIONSHIP=@psRelationship
		---------------------------------------------
		-- exclude Child cases who have a Parent that
		-- is also a Child case of the current Case
		-- as these will appear at a lower depth.
		---------------------------------------------
		and not exists
		(select 1 
		 from RELATEDCASE R2
		 where R2.CASEID=R1.CASEID
		 and   R2.RELATIONSHIP=R1.RELATIONSHIP
		 and   R2.RELATEDCASEID in (	select R3.CASEID
						from RELATEDCASE R3
						where R3.RELATEDCASEID=R1.RELATEDCASEID
						and R3.RELATIONSHIP=R1.RELATIONSHIP))"

		exec @ErrorCode=sp_executesql @sSQLString,
					N'@nCaseId		int,
					  @nFamilyId		int,
					  @psRelationship	nvarchar(3)',
					  @nCaseId  =@nCaseId,
					  @nFamilyId=@nFamilyId,
					  @psRelationship=@psRelationship

		set @pnRowCount=@@Rowcount

		Set @nTotalRows=@nTotalRows+@pnRowCount
	End

	---------------------------------------
	-- Process up the tree for each parent 
	-- Case to load any parent that it may 
	-- also have.
	---------------------------------------
	WHILE @pnRowCount>0
	and   @ErrorCode=0
	begin
		Set @sSQLString="
		insert into #TEMPCASETREE(DEPTH, PARENTCASE, PARENTOFFICIALNO, CHILDCASE, RELATIONSHIP, COUNTRYCODE, PRIORITYDATE, FAMILYID)
		select distinct T.DEPTH-1, R1.RELATEDCASEID, R1.OFFICIALNUMBER, R1.CASEID, R1.RELATIONSHIP, R1.COUNTRYCODE,R1.PRIORITYDATE, T.FAMILYID
		from #TEMPCASETREE T
		join RELATEDCASE R1        on (R1.CASEID=T.PARENTCASE
		                           and R1.RELATIONSHIP=T.RELATIONSHIP)
		left join #TEMPCASETREE T1 on (T1.FAMILYID=T.FAMILYID
		                           and T1.PARENTCASE=R1.RELATEDCASEID)
		where T.FAMILYID=@nFamilyId
		and T.DEPTH=(select min(DEPTH) from #TEMPCASETREE where FAMILYID=@nFamilyId)
		and T1.PARENTCASE is null
		---------------------------------------------
		-- exclude Child cases who have a Parent that
		-- is also a Child case of the current Case
		-- as these will appear at a lower depth.
		---------------------------------------------
		and not exists
		(select 1 
		 from RELATEDCASE R2
		 where R2.CASEID=R1.CASEID
		 and   R2.RELATIONSHIP=R1.RELATIONSHIP
		 and   R2.RELATEDCASEID in (	select R3.CASEID
						from RELATEDCASE R3
						where R3.RELATEDCASEID=R1.RELATEDCASEID
						and R3.RELATIONSHIP=R1.RELATIONSHIP))"

		exec @ErrorCode=sp_executesql @sSQLString,
					N'@nFamilyId		int',
					  @nFamilyId=@nFamilyId

		Set @pnRowCount=@@Rowcount

		Set @nTotalRows=@nTotalRows+@pnRowCount
	end

	------------------------------------------
	-- If all Cases are being processed then 
	-- get the next Case for the start of the
	-- next family, otherwise terminate 
	-- the loop by setting @nCaseId = null
	------------------------------------------
	If @pnCaseId is not null
	and @ErrorCode=0
	Begin
		Set @nCaseId=null
	End
	Else If @ErrorCode=0
	Begin	
		Set @sSQLString="
		Select @nCaseId=min(P.CASEID)
		from RELATEDCASE P
		join RELATEDCASE G on (G.CASEID=P.RELATEDCASEID
				   and G.RELATIONSHIP=P.RELATIONSHIP)
		Where P.CASEID>@nCaseId
		and P.RELATIONSHIP=@psRelationship
		and not exists
		(select 1 from RELATEDCASE C
		 where C.RELATEDCASEID=P.CASEID
		 and C.RELATIONSHIP=P.RELATIONSHIP)"

		exec @ErrorCode=sp_executesql @sSQLString,
					N'@nCaseId		int	OUTPUT,
					  @psRelationship	nvarchar(3)',
					  @nCaseId       =@nCaseId	OUTPUT,
					  @psRelationship=@psRelationship
	End	
End -- End of family loop

-------------------------------------------
-- As a final safeguard to ensure the 
-- hierarchy is displayed correctly remove 
-- any  entries where the Child Case exists 
-- at a lower depth.
-------------------------------------------
If  @ErrorCode=0
and @nTotalRows>0
begin
	Set @sSQLString="
	delete #TEMPCASETREE
	from #TEMPCASETREE CT
	join (select * from #TEMPCASETREE) CT1
			on (CT1.FAMILYID=CT.FAMILYID
			and CT1.CHILDCASE=CT.CHILDCASE
			and CT1.DEPTH>CT.DEPTH)"

	exec @ErrorCode=sp_executesql @sSQLString
end

If @ErrorCode=0
and @pnCaseId is null
Begin
	------------------------------------------------------
	-- Now also load any other Cases pointing to a Parent.
	-- These are Cases where the hierachy is only a single
	-- level either because the relationship was to a Case
	-- that did not point to its own parent or beacuase 
	-- the parent was to an external official number.
	------------------------------------------------------
	
	Set @sSQLString="
	insert into #TEMPCASETREE(DEPTH, PARENTCASE, PARENTOFFICIALNO, CHILDCASE, RELATIONSHIP, COUNTRYCODE, PRIORITYDATE, FAMILYID)
	select 0, R1.RELATEDCASEID, R1.OFFICIALNUMBER, R1.CASEID, R1.RELATIONSHIP, R1.COUNTRYCODE,R1.PRIORITYDATE, 0
	from RELATEDCASE R1
	left join #TEMPCASETREE T1 on (T1.CHILDCASE=R1.CASEID)
	where R1.RELATIONSHIP=@psRelationship
	and T1.CHILDCASE is null"

	exec @ErrorCode=sp_executesql @sSQLString,
				N'@psRelationship	nvarchar(3)',
				  @psRelationship=@psRelationship

	If @ErrorCode=0
	Begin
		-------------------------------------
		-- Update FAMILYID to a unique number
		-- for the rows just added. Where a
		-- Child Case has multiple rows use
		-- the same FAMILYID for each.
		-------------------------------------
		Set @sSQLString="
		Update T
		Set FAMILYID=T1.ROWNUMBER-@nFamilyId+1
		From #TEMPCASETREE T
		join (	select CHILDCASE, min(ROWNUMBER) as ROWNUMBER
			from #TEMPCASETREE
			where FAMILYID=0
			group by CHILDCASE) T1 on (T1.CHILDCASE=T.CHILDCASE)
		where T.FAMILYID=0"

		exec @ErrorCode=sp_executesql @sSQLString,
				N'@nFamilyId		int',
				  @nFamilyId     =@nFamilyId
	End
End

If @ErrorCode=0
Begin
	-----------------------------------------------------
	-- For each family of Cases report the Filing date of
	-- the earliest ancestor or if this is not a system
	-- Case then report the provided Priority Date.
	-- Then report each Case whose priority date does
	-- not match the earliest Filing Date.
	-- CIP cases will report compare its Priority Date
	-- against its immediate parent.
	-----------------------------------------------------
	Set @sSQLString="
	select	distinct
		CS.IRN as [Child Case],
		convert(nvarchar,    CE1.EVENTDATE,112) as [Filing Date],
		convert(nvarchar,     CE.EVENTDATE,112) as [Existing Priority Date],
		convert(nvarchar, T.EarliestFiling,112) as [Earliest Ancestor Filing],
		convert(nvarchar,T1.EarliestFiling,112) as [CIP Parent Filing]
	from #TEMPCASETREE CT
		-----------------------------------
		-- Find the earliest Filing Date or
		-- Priority Date from the earliest
		-- ancestor of the family.
		-----------------------------------
	join (	select T.FAMILYID, min(isnull(CE.EVENTDATE,T.PRIORITYDATE)) as EarliestFiling
		from #TEMPCASETREE T
		left join CASEEVENT CE	on (CE.CASEID=T.PARENTCASE
					and CE.EVENTNO=-4
					and CE.CYCLE=1)
		where T.DEPTH=(	select min(T1.DEPTH)
				from #TEMPCASETREE T1
				where T1.FAMILYID=T.FAMILYID)
		group by T.FAMILYID) T	on (T.FAMILYID=CT.FAMILYID)
	join CASES CS		on (CS.CASEID=CT.CHILDCASE)
	left join CASEEVENT CE	on (CE.CASEID=CS.CASEID	-- PriorityDate of child Case
				and CE.EVENTNO=-1
				and CE.CYCLE=1)
		-----------------------------------
		-- Filing date of the current child 
		-- Case.
		-----------------------------------
	left join CASEEVENT CE1	on (CE1.CASEID=CT.CHILDCASE
				and CE1.EVENTNO=-4
				and CE1.CYCLE=1)
		-----------------------------------
		-- Find the earliest Filing Date
		-- from the earliest direct parent.
		-- This is used for checking CIP 
		-- Cases.
		-----------------------------------
	left join 
	       (select T.CHILDCASE, min(isnull(CE.EVENTDATE,T.PRIORITYDATE)) as EarliestFiling
		from #TEMPCASETREE T
		left join CASEEVENT CE	on (CE.CASEID=T.PARENTCASE
					and CE.EVENTNO=-4
					and CE.CYCLE=1)
		where T.DEPTH=(	select min(T1.DEPTH)
				from #TEMPCASETREE T1
				where T1.FAMILYID=T.FAMILYID)
		group by T.CHILDCASE) T1 on (T1.CHILDCASE=CT.CHILDCASE
					 and CS.CASECATEGORY=@psCaseCategory) -- Only required for CIP Case
		-----------------------------------
		-- Only report Cases where there is
		-- a potential date discrepancy.
		-----------------------------------
	Where (isnull(CE.EVENTDATE,'')<>T.EarliestFiling and isnull(CS.CASECATEGORY,'')<>isnull(@psCaseCategory,''))
	OR    (isnull(CE.EVENTDATE,'')<>isnull(T1.EarliestFiling,'') and CS.CASECATEGORY=@psCaseCategory)
	Order by CS.IRN"
		
	exec @ErrorCode=sp_executesql @sSQLString,
					N'@psCaseCategory	nvarchar(2)',
					  @psCaseCategory=@psCaseCategory
	
	Set @pnRowCount=@@Rowcount
End

RETURN @ErrorCode
go

grant execute on dbo.cs_CheckEarliestPriorityDate  to public
go
