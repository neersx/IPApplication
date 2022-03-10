-----------------------------------------------------------------------------------------------------------------------------
-- Creation of cr_ListCriteriaTree
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[cr_ListCriteriaTree]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.cr_ListCriteriaTree.'
	drop procedure dbo.cr_ListCriteriaTree
end
print '**** Creating procedure dbo.cr_ListCriteriaTree...'
print ''
go

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

CREATE PROCEDURE dbo.cr_ListCriteriaTree
(
	@pnRowCount			int 		= null	OUTPUT,
	@pnUserIdentityId		int		= null,	
	@psCulture			nvarchar(10)	= null, -- the language in which output is to be expressed
	@pnCriteriaKey			int		= null,	-- a single Criteria whose tree structure is to be returned
	@psGlobalTempTable		nvarchar(32)	= null	-- a temporary table of CriteriaNo whose tree structure is required

)
AS
-- PROCEDURE :	cr_ListCriteriaTree
-- VERSION :	2
-- DESCRIPTION:	Lists the CHILDCRITERIANO Cases and their direct PARENTCRITERIANO Case
-- SCOPE:	CPA.net, InPro.net
-- CALLED BY :	DataAccess directly
-- COPYRIGHT:	Copyright 1993 - 2004 CPA Software Solutions (Australia) Pty Limited
-- MODIFICTIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 24 Oct 2003	MF		1	Procedure created
-- 05 Aug 2004	AB	8035	2	Add collate database_default to temp table definitions

set nocount on
SET CONCAT_NULL_YIELDS_NULL OFF

-- NOTE : Using a table variable.  This means that dynamic SQL methods are not able 
--        to be used.  Testing has shown that this approach is still faster than 
--        using a temporary table with sp_executesql.

Create table #TempCriteriaTree 
		      (	TREENO			SMALLINT	not null,
			DEPTH			smallint	not null,
			PARENTCRITERIANO	int		null,
			CHILDCRITERIANO		int		null
			)

declare @ErrorCode	int
declare @nDepth		smallint
declare @nFirstDepth	smallint
declare @nLastDepth	smallint
declare @nNewRows	smallint
declare	@nTreeNo	smallint
declare @sSQLString	nvarchar(4000)

set @ErrorCode=0
set @nTreeNo=0

-- Multiple Criteria may need to be expanded.  Get the first Criteria to expand.

If @psGlobalTempTable is not null
Begin
	Set @sSQLString="
	Select @pnCriteriaKey=min(CRITERIANO)
	from "+@psGlobalTempTable

	exec @ErrorCode=sp_executesql @sSQLString,
				N'@pnCriteriaKey	int	output',
				  @pnCriteriaKey=@pnCriteriaKey	output
End

-- Loop through the Criteria to be expanded

While @pnCriteriaKey is not null
and   @ErrorCode=0
Begin
	Set @nTreeNo=@nTreeNo+1
	-- Start at a DEPTH=1 where the root Criteria(s) for which the stored procedure has been
	-- called is the PARENTCRITERIANO.
	
	if @ErrorCode = 0
	begin
		Set @sSQLString="
		insert into #TempCriteriaTree(TREENO, DEPTH, PARENTCRITERIANO, CHILDCRITERIANO)
		select @nTreeNo, 1, C.CRITERIANO, I.CRITERIANO
		from CRITERIA C
		left join INHERITS I  on (I.FROMCRITERIA=C.CRITERIANO)
		where C.CRITERIANO=@pnCriteriaKey
		and not exists
		(select * from #TempCriteriaTree T
		 where T.PARENTCRITERIANO=C.CRITERIANO
		 or    T.CHILDCRITERIANO =C.CRITERIANO)"
	
		exec @ErrorCode=sp_executesql @sSQLString,
					N'@pnCriteriaKey	int,
					  @nTreeNo		smallint',
					  @pnCriteriaKey=@pnCriteriaKey,
					  @nTreeNo	=@nTreeNo
	
		Set @pnRowCount=@@Rowcount
		
		Set @nLastDepth=0
	End

	-- Now expand each Parent entry to load any Child criteria.
	
	WHILE	@pnRowCount>0
	and	@ErrorCode=0
	begin
		-- Keept track of the highest depth inserted so far
		Set @nLastDepth=@nLastDepth+1
	
		Set @sSQLString="
		insert into #TempCriteriaTree(TREENO, DEPTH, PARENTCRITERIANO, CHILDCRITERIANO)
		select distinct @nTreeNo, T.DEPTH+1, I.FROMCRITERIA, I.CRITERIANO
		from #TempCriteriaTree T
		join INHERITS I		on (I.FROMCRITERIA=T.CHILDCRITERIANO)
		where T.DEPTH=(select max(DEPTH) from #TempCriteriaTree)
		and not exists
		(select * from #TempCriteriaTree T
		 where T.PARENTCRITERIANO=I.CRITERIANO
		 or    T.CHILDCRITERIANO =I.CRITERIANO)"
	
		exec @ErrorCode=sp_executesql @sSQLString, 
					N'@nTreeNo	smallint',
					  @nTreeNo=@nTreeNo
	
		Select  @pnRowCount=@@Rowcount,
			@ErrorCode =@@Error
	end

	-- Now we are going to work in reverse and try and find the parentage of the
	-- root CRITERIA Starting at DEPTH=0 and working back.
	
	if @ErrorCode = 0
	begin
		Set @sSQLString="
		insert into #TempCriteriaTree(TREENO, DEPTH, PARENTCRITERIANO, CHILDCRITERIANO)
		select @nTreeNo, 0, I.FROMCRITERIA, I.CRITERIANO
		from INHERITS I
		where I.CRITERIANO=@pnCriteriaKey
		and not exists
		(select * from #TempCriteriaTree T
		 where T.PARENTCRITERIANO=I.FROMCRITERIA
		 or    T.CHILDCRITERIANO =I.FROMCRITERIA)"
	
		exec @ErrorCode=sp_executesql @sSQLString,
					N'@pnCriteriaKey	int,
					  @nTreeNo		smallint',
					  @pnCriteriaKey=@pnCriteriaKey,
					  @nTreeNo=@nTreeNo
	
		select	@pnRowCount=@@Rowcount,
			@ErrorCode =@@Error
	
		Set @nFirstDepth=1
	End

	WHILE	@pnRowCount>0
	and	@ErrorCode=0
	begin
		-- Keep track of the first root depth level inserted so far
		Set @nFirstDepth=@nFirstDepth-1
	
		Set @sSQLString="
		insert into #TempCriteriaTree(TREENO, DEPTH, PARENTCRITERIANO, CHILDCRITERIANO)
		select distinct @nTreeNo, T.DEPTH-1, I.FROMCRITERIA, I.CRITERIANO
		from #TempCriteriaTree T
		join INHERITS I		on (I.CRITERIANO=T.PARENTCRITERIANO)
		where T.DEPTH=(select min(DEPTH) from #TempCriteriaTree)
		and not exists
		(select * from #TempCriteriaTree T
		 where T.PARENTCRITERIANO=I.FROMCRITERIA
		 or    T.CHILDCRITERIANO =I.FROMCRITERIA)"
	
		exec @ErrorCode=sp_executesql @sSQLString,
					N'@nTreeNo	smallint',
					  @nTreeNo=@nTreeNo
	
		Select  @pnRowCount=@@Rowcount,
			@ErrorCode =@@Error
	end

	-- Now start at the highest point in the tree and load any other Child Criteria
	-- that have not yet been loaded
	Set @nDepth=@nFirstDepth
	
	While (@nDepth<=@nLastDepth or @nNewRows>0)
	and    @ErrorCode=0
	Begin
		-- Insert any child rows that an existing parent is missing
		Set @sSQLString="
		insert into #TempCriteriaTree(TREENO, DEPTH, PARENTCRITERIANO, CHILDCRITERIANO)
		select distinct @nTreeNo, T.DEPTH, I.FROMCRITERIA, I.CRITERIANO
		from #TempCriteriaTree T
		join INHERITS I			on (I.FROMCRITERIA=T.PARENTCRITERIANO)
		left join #TempCriteriaTree T1	on (T1.CHILDCRITERIANO=I.CRITERIANO)
		where T.DEPTH=@nDepth
		and T1.CHILDCRITERIANO is null"
	
		exec @ErrorCode=sp_executesql @sSQLString,
					N'@nDepth	smallint,
					  @nTreeNo	smallint',
					  @nDepth=@nDepth,
					  @nTreeNo=@nTreeNo
	
		Select  @nNewRows =@@Rowcount,
			@ErrorCode=@@Error
	
		-- Insert any parent rows at the next depth level for where the Child
		-- just inserted at the current level (previous Insert statement) is a Parent
		-- that has not previously been inserted.
		Set @sSQLString="
		insert into #TempCriteriaTree(TREENO, DEPTH, PARENTCRITERIANO, CHILDCRITERIANO)
		select distinct @nTreeNo, T.DEPTH+1, I.FROMCRITERIA, I.CRITERIANO
		from #TempCriteriaTree T
		join INHERITS I			on (I.FROMCRITERIA=T.CHILDCRITERIANO)
		left join #TempCriteriaTree T1	on (T1.PARENTCRITERIANO=I.FROMCRITERIA)
		where T.DEPTH=@nDepth
		and T1.PARENTCRITERIANO is null"
	
		exec @ErrorCode=sp_executesql @sSQLString,
					N'@nDepth	smallint, 
					  @nTreeNo	smallint',
					  @nDepth=@nDepth,
					  @nTreeNo=@nTreeNo
	
		Select  @pnRowCount=@@Rowcount,
			@ErrorCode =@@Error
	
		Set @nNewRows  =@nNewRows  +@pnRowCount
	
		-- Increment the pointer through the tree levels to ensure each
		-- level is examined for missing children
		Set @nDepth=@nDepth+1
	End

	-- Get the next Criteria to process if we are working from the Temporary Tabld

	If @psGlobalTempTable is null
	Begin
		Set @pnCriteriaKey=NULL
	End
	Else Begin
		Set @sSQLString="
		Select @pnCriteriaKeyOUT=min(CRITERIANO)
		from "+@psGlobalTempTable+"
		where CRITERIANO>@pnCriteriaKey"
	
		exec @ErrorCode=sp_executesql @sSQLString,
					N'@pnCriteriaKeyOUT	int	output,
					  @pnCriteriaKey	int',
					  @pnCriteriaKeyOUT=@pnCriteriaKey output,
					  @pnCriteriaKey   =@pnCriteriaKey
	End
End 	-- end of loop through Criteria to be expanded

-- Clean up.  Remove any entries that have no Child but are a Child themselves.

If @ErrorCode=0
Begin
	set @sSQLString="
	Delete #TempCriteriaTree
	from #TempCriteriaTree T
	join (select CHILDCRITERIANO 	-- Derived table used because of Abiguous table error
	      from #TempCriteriaTree) T1 on (T1.CHILDCRITERIANO=T.PARENTCRITERIANO)
	where T.CHILDCRITERIANO is null"
	
	exec @ErrorCode=sp_executesql @sSQLString
End

-- Now we need to level the Depth against the results.  If there are multiple trees
-- then we want them all to start at the same depth and each child to be one depth 
-- greater

If @ErrorCode=0
Begin
	-- The starting point in the chain can be identified where the Parent
	-- Criteriano is not the Child of any other Criteria
	Set @sSQLString="
	Update #TempCriteriaTree
	set DEPTH=0
	from #TempCriteriaTree T
	where not exists
	(select * from #TempCriteriaTree T1
	 where T1.CHILDCRITERIANO=T.PARENTCRITERIANO)"

	exec @ErrorCode=sp_executesql @sSQLString
End

-- Now update the Depth to be one greater than its parent
If @ErrorCode=0
Begin
	Set @sSQLString="
	Update #TempCriteriaTree
	set DEPTH=T1.DEPTH+1
	from #TempCriteriaTree T
	join (select CHILDCRITERIANO, DEPTH	-- using Derived table because of Ambiguous table error
	      from #TempCriteriaTree) T1 on (T1.CHILDCRITERIANO=T.PARENTCRITERIANO)"

	exec @ErrorCode=sp_executesql @sSQLString
End

-- Now return the result set of the Parent and Child Criteria
If @ErrorCode=0
Begin
		select  P.CRITERIANO		as ParentCriteriaNo,
			P.CASETYPE		as ParentCaseType,
			P.ACTION 		as ParentAction,
			P.CHECKLISTTYPE 	as ParentCheckListType,
			P.PROGRAMID		as ParentProgramId,
			P.PROPERTYTYPE		as ParentPropertyType,
			P.COUNTRYCODE		as ParentCountryCode,
			P.CASECATEGORY		as ParentCaseCategory,
			P.SUBTYPE		as ParentSubType,
			P.BASIS			as ParentBasis,
			P.REGISTEREDUSERS	as ParentRegisteredUsers,
			P.LOCALCLIENTFLAG	as ParentLocalClientFlag,
			P.TABLECODE		as ParentTableCode,
			P.RATENO		as ParentRateNo,
			P.DATEOFACT		as ParentDateOfAct,
			P.USERDEFINEDRULE	as ParentUserDefinedRule,
			P.RULEINUSE		as ParentRuleInUse,
			P.DESCRIPTION		as ParentDescription,
			C.CRITERIANO		as ChildCriteriaNo,
			C.CASETYPE		as ChildCaseType,
			C.ACTION 		as ChildAction,
			C.CHECKLISTTYPE 	as ChildCheckListType,
			C.PROGRAMID		as ChildProgramId,
			C.PROPERTYTYPE		as ChildPropertyType,
			C.COUNTRYCODE		as ChildCountryCode,
			C.CASECATEGORY		as ChildCaseCategory,
			C.SUBTYPE		as ChildSubType,
			C.BASIS			as ChildBasis,
			C.REGISTEREDUSERS	as ChildRegisteredUsers,
			C.LOCALCLIENTFLAG	as ChildLocalClientFlag,
			C.TABLECODE		as ChildTableCode,
			C.RATENO		as ChildRateNo,
			C.DATEOFACT		as ChildDateOfAct,
			C.USERDEFINEDRULE	as ChildUserDefinedRule,
			C.RULEINUSE		as ChildRuleInUse,
			C.DESCRIPTION		as ChildDescription
		from #TempCriteriaTree T
		     join CRITERIA P	on (P.CRITERIANO=T.PARENTCRITERIANO)
		left join CRITERIA C	on (C.CRITERIANO=T.CHILDCRITERIANO)
		order by TREENO, DEPTH, P.CRITERIANO, C.DESCRIPTION, C.CRITERIANO
	
		Select  @pnRowCount=@@Rowcount,
			@ErrorCode =@@Error
End

RETURN @ErrorCode
go

grant execute on dbo.cr_ListCriteriaTree  to public
go
