-----------------------------------------------------------------------------------------------------------------------------
-- Creation of csw_LoadSortedResult
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[csw_LoadSortedResult]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.csw_LoadSortedResult.'
	drop procedure dbo.csw_LoadSortedResult
end
print '**** Creating Stored Procedure dbo.csw_LoadSortedResult...'
print ''
go

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

CREATE PROCEDURE dbo.csw_LoadSortedResult
	@pnRowCount			int		= null	OUTPUT,
	@psWhereFilter			nvarchar(max)	= null, -- the constructed filter for the Cases to return
	@psTempTableName		nvarchar(60)	= null, -- temporary table name that may be referred to in SELECT list
	@pbGetInstructions		bit		= null, -- flag to indicate that Cases eligible for user entered Instructions are being extracted.
	@pnUserIdentityId		int,			-- Mandatory
	@pbExternalUser			bit,			-- Mandatory. Flag to indicate if user is external.  Default on as this is the lowest security level
	@pbPrintSQL			bit		= null	-- When set to 1, the executed SQL statement is printed out.

AS
-- PROCEDURE :	csw_LoadSortedResult
-- VERSION :	8
-- DESCRIPTION:	The constructed SELECT statement is to be executed to load the sorted Cases into
--		a temporary table.  Only the Cases that are required to be displayed will be
--		loaded so the extraction of extended Case details will only be made for the actual
--		Cases that are eligible to be displayed.
-- CALLED BY :	
-- COPYRIGHT:	Copyright 1993 - 2007 CPA Software Solutions (Australia) Pty Limited
-- MODIFICTIONS :
-- Date         Who	Number	Version	Change
-- ------------ ---- 	------	-------	------------------------------------------ 
-- 13 Feb 2007	MF  		1	Procedure created
-- 16 Jul 2007	MF	14957	2	SQL Error on Due Date enquiry with Alerts and user defined column.  Required the
--					temporary table name of case results to be replaced.  Also found problem in
--					pagination.
-- 23 Oct 2007	MF	15498	3	SQL Error when external user executes a multi level boolean query.
-- 09 Sep 2009	MF	18024	4	SQL error when external user running budget list. Caused becaues length of data 
--					provided in @psWhereFilter had changed.
-- 24 Jun 2011	MF	10859	5	When the ALERT table has replaced the EVENTDUEDATE then the ORDER BY clause may
--					need to have its column references changed.
-- 22 Apr 2015	MS	R46603	6	Set size of some variables to nvarchar(max)
-- 14 Jul 2016	MF	62317	7	Performance improvement using a CTE to get the minimum SEQUENCE by Caseid and NameType. 
-- 07 Sep 2018	AV	74738	8	Set isolation level to read uncommited.

SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

create table #TEMPEXTERNALUSERCASES(CASEID	int	not null)

-- A table holding the interim list of Cases to be reported on
-- in the sequence that the user user has elected
-- This table may initially be loaded with duplicate Cases because
-- the DISTINCT clause cannot be used if an ORDER BY another column
-- is inlcuded.
Create table #TEMPSORTEDCASES	(CASEID		int	not null,
				 SEQUENCENO	int	identity(1,1))

declare @ErrorCode		int
declare @nStart			smallint
declare	@sSQLString		nvarchar(4000)

Declare	@sSelectList		nvarchar(4000)
Declare @sUnionSelect		nvarchar(4000)
Declare @sFromTempTable		nvarchar(4000)
Declare @sUnionFromTempTable	nvarchar(4000)
Declare	@sFrom1			nvarchar(4000)	-- the SQL to list tables and joins
Declare	@sFrom2			nvarchar(4000)
Declare	@sFrom3			nvarchar(4000)
Declare	@sFrom4			nvarchar(4000)
Declare	@sFrom5			nvarchar(4000)	-- the SQL to list tables and joins
Declare	@sFrom6			nvarchar(4000)
Declare	@sFrom7			nvarchar(4000)
Declare	@sFrom8			nvarchar(4000)
Declare	@sFrom9			nvarchar(4000)	-- the SQL to list tables and joins
Declare	@sFrom10		nvarchar(4000)
Declare	@sFrom11		nvarchar(4000)
Declare	@sFrom12		nvarchar(4000)
Declare @sWhere			nvarchar(4000) 	-- the SQL to filter (To store the output "Where" from the csw_ConstructCaseSelect)
Declare @sGroupBy		nvarchar(4000)	-- the SQL for grouping columns of like values

Declare	@sUnionFrom1		nvarchar(4000)	-- the SQL to list tables and joins for the UNION
Declare	@sUnionFrom2		nvarchar(4000)
Declare	@sUnionFrom3		nvarchar(4000)
Declare	@sUnionFrom4		nvarchar(4000)
Declare	@sUnionFrom5		nvarchar(4000)	-- the SQL to list tables and joins for the UNION
Declare	@sUnionFrom6		nvarchar(4000)
Declare	@sUnionFrom7		nvarchar(4000)
Declare	@sUnionFrom8		nvarchar(4000)
Declare	@sUnionFrom9		nvarchar(4000)	-- the SQL to list tables and joins for the UNION
Declare	@sUnionFrom10		nvarchar(4000)
Declare	@sUnionFrom11		nvarchar(4000)
Declare	@sUnionFrom12		nvarchar(4000)
Declare @sUnionWhere		nvarchar(4000) 	-- the SQL to filter (To store the output "Where" from the csw_ConstructCaseSelect) for the UNION
Declare @sUnionFilter		nvarchar(4000) 	-- the SQL to filter (To store the output "Where" from the csw_FilterCases) for the UNION
Declare @sUnionGroupBy		nvarchar(4000)	-- the SQL for grouping columns of like values for the UNION
Declare @sOrder			nvarchar(4000)	-- the SQL sort order
Declare @sCountSelect		nvarchar(4000)	-- A part of the Select statement required to calculate the @pnSearchSetTotalRows - Potential number of rows in the search result set
Declare @sCTE			nvarchar(1000)

-- Initialisation
set @ErrorCode=0
 
If @ErrorCode=0
Begin
	Set @sSQLString="
	Select 	@sFrom       =replace(F.SavedString,'Join '+@psTempTableName+' TT on (TT.CASEID=C.CASEID)',''),
		@sWhere      =W.SavedString,
		@sUnionFrom  =replace(V.SavedString,'Join '+@psTempTableName+' TT on (TT.CASEID=C.CASEID)',''),
		@sUnionWhere =X.SavedString,
		@sOrder      =C.SavedString
	from #TempConstructSQL W	
	left join #TempConstructSQL F	on (F.ComponentType='F'
					and F.Position=(select min(F1.Position)
							from #TempConstructSQL F1
							where F1.ComponentType=F.ComponentType))
	left join #TempConstructSQL C	on (C.ComponentType='C') -- get the Order By that uses the raw columns
	left join #TempConstructSQL U	on (U.ComponentType='U'
					and patindex('%Union All%',U.SavedString)>0)							
	left join #TempConstructSQL V	on (V.ComponentType='V'
					and V.Position=(select min(V1.Position)
							from #TempConstructSQL V1
							where V1.ComponentType=V.ComponentType))
	left join #TempConstructSQL X	on (X.ComponentType='X')	-- there will only be 1 Union Where row
	Where W.ComponentType='W'"				-- there will only be 1 Select row

	Exec @ErrorCode=sp_executesql @sSQLString,
					N'@sFrom		nvarchar(4000)	OUTPUT,
					  @sWhere		nvarchar(4000)	OUTPUT,
					  @sUnionFrom		nvarchar(4000)	OUTPUT,
					  @sUnionWhere		nvarchar(4000)	OUTPUT,
					  @sOrder		nvarchar(4000)	OUTPUT,
					  @psTempTableName	nvarchar(60)',
					  @sFrom	=@sFrom1		OUTPUT,
					  @sWhere	=@sWhere		OUTPUT,
					  @sUnionFrom	=@sUnionFrom1		OUTPUT,
					  @sUnionWhere	=@sUnionWhere		OUTPUT,
					  @sOrder	=@sOrder		OUTPUT,
					  @psTempTableName=@psTempTableName
End

-------------------------------------------------------
-- RFC
-- If the ALERT table has replaced the CASEEVENT table
-- to return due dates then any references in the Order
-- By to CASEEVENT columns will need to be changed.
-------------------------------------------------------
If  @ErrorCode=0
and @sFrom1 like '%Join ALERT DD%'
and @sOrder like '%DD.EVENTDUEDATE%'
Begin
	Set @sOrder=replace(@sOrder,'DD.EVENTDUEDATE','DD.DUEDATE')
End

-- Now get the additial FROM clause components.  
-- A fixed number have been provided for at this point however this can 
-- easily be increased

If  @sFrom1 is not null
and @ErrorCode=0
Begin
	Set @sSQLString="
	Select @sFrom=replace(F.SavedString,'Join '+@psTempTableName+' TT on (TT.CASEID=C.CASEID)','')
	from #TempConstructSQL F
	where F.ComponentType='F'
	and (	select count(*)
		from #TempConstructSQL F1
		where F1.ComponentType=F.ComponentType
		and F1.Position<F.Position)=1"

	exec @ErrorCode=sp_executesql @sSQLString,
					N'@sFrom		nvarchar(4000)	OUTPUT,
					  @psTempTableName	nvarchar(60)',
					  @sFrom=@sFrom2			OUTPUT,
					  @psTempTableName=@psTempTableName
End

If  @sFrom2 is not null
and @ErrorCode=0
Begin
	Set @sSQLString="
	Select @sFrom=replace(F.SavedString,'Join '+@psTempTableName+' TT on (TT.CASEID=C.CASEID)','')
	from #TempConstructSQL F
	where F.ComponentType='F'
	and (	select count(*)
		from #TempConstructSQL F1
		where F1.ComponentType=F.ComponentType
		and F1.Position<F.Position)=2"

	exec @ErrorCode=sp_executesql @sSQLString,
					N'@sFrom		nvarchar(4000)	OUTPUT,
					  @psTempTableName	nvarchar(60)',
					  @sFrom=@sFrom3			OUTPUT,
					  @psTempTableName=@psTempTableName
End

If  @sFrom3 is not null
and @ErrorCode=0
Begin
	Set @sSQLString="
	Select @sFrom=replace(F.SavedString,'Join '+@psTempTableName+' TT on (TT.CASEID=C.CASEID)','')
	from #TempConstructSQL F
	where F.ComponentType='F'
	and (	select count(*)
		from #TempConstructSQL F1
		where F1.ComponentType=F.ComponentType
		and F1.Position<F.Position)=3"

	exec @ErrorCode=sp_executesql @sSQLString,
					N'@sFrom		nvarchar(4000)	OUTPUT,
					  @psTempTableName	nvarchar(60)',
					  @sFrom=@sFrom4			OUTPUT,
					  @psTempTableName=@psTempTableName
End

If  @sFrom4 is not null
and @ErrorCode=0
Begin
	Set @sSQLString="
	Select @sFrom=replace(F.SavedString,'Join '+@psTempTableName+' TT on (TT.CASEID=C.CASEID)','')
	from #TempConstructSQL F
	where F.ComponentType='F'
	and (	select count(*)
		from #TempConstructSQL F1
		where F1.ComponentType=F.ComponentType
		and F1.Position<F.Position)=4"

	exec @ErrorCode=sp_executesql @sSQLString,
					N'@sFrom		nvarchar(4000)	OUTPUT,
					  @psTempTableName	nvarchar(60)',
					  @sFrom=@sFrom5			OUTPUT,
					  @psTempTableName=@psTempTableName
End

If  @sFrom5 is not null
and @ErrorCode=0
Begin
	Set @sSQLString="
	Select @sFrom=replace(F.SavedString,'Join '+@psTempTableName+' TT on (TT.CASEID=C.CASEID)','')
	from #TempConstructSQL F
	where F.ComponentType='F'
	and (	select count(*)
		from #TempConstructSQL F1
		where F1.ComponentType=F.ComponentType
		and F1.Position<F.Position)=5"

	exec @ErrorCode=sp_executesql @sSQLString,
					N'@sFrom		nvarchar(4000)	OUTPUT,
					  @psTempTableName	nvarchar(60)',
					  @sFrom=@sFrom6			OUTPUT,
					  @psTempTableName=@psTempTableName
End

If  @sFrom6 is not null
and @ErrorCode=0
Begin
	Set @sSQLString="
	Select @sFrom=replace(F.SavedString,'Join '+@psTempTableName+' TT on (TT.CASEID=C.CASEID)','')
	from #TempConstructSQL F
	where F.ComponentType='F'
	and (	select count(*)
		from #TempConstructSQL F1
		where F1.ComponentType=F.ComponentType
		and F1.Position<F.Position)=6"

	exec @ErrorCode=sp_executesql @sSQLString,
					N'@sFrom		nvarchar(4000)	OUTPUT,
					  @psTempTableName	nvarchar(60)',
					  @sFrom=@sFrom7			OUTPUT,
					  @psTempTableName=@psTempTableName
End

If  @sFrom7 is not null
and @ErrorCode=0
Begin
	Set @sSQLString="
	Select @sFrom=replace(F.SavedString,'Join '+@psTempTableName+' TT on (TT.CASEID=C.CASEID)','')
	from #TempConstructSQL F
	where F.ComponentType='F'
	and (	select count(*)
		from #TempConstructSQL F1
		where F1.ComponentType=F.ComponentType
		and F1.Position<F.Position)=7"

	exec @ErrorCode=sp_executesql @sSQLString,
					N'@sFrom		nvarchar(4000)	OUTPUT,
					  @psTempTableName	nvarchar(60)',
					  @sFrom=@sFrom8			OUTPUT,
					  @psTempTableName=@psTempTableName
End

If  @sFrom8 is not null
and @ErrorCode=0
Begin
	Set @sSQLString="
	Select @sFrom=replace(F.SavedString,'Join '+@psTempTableName+' TT on (TT.CASEID=C.CASEID)','')
	from #TempConstructSQL F
	where F.ComponentType='F'
	and (	select count(*)
		from #TempConstructSQL F1
		where F1.ComponentType=F.ComponentType
		and F1.Position<F.Position)=8"

	exec @ErrorCode=sp_executesql @sSQLString,
					N'@sFrom		nvarchar(4000)	OUTPUT,
					  @psTempTableName	nvarchar(60)',
					  @sFrom=@sFrom9			OUTPUT,
					  @psTempTableName=@psTempTableName
End

If  @sFrom9 is not null
and @ErrorCode=0
Begin
	Set @sSQLString="
	Select @sFrom=replace(F.SavedString,'Join '+@psTempTableName+' TT on (TT.CASEID=C.CASEID)','')
	from #TempConstructSQL F
	where F.ComponentType='F'
	and (	select count(*)
		from #TempConstructSQL F1
		where F1.ComponentType=F.ComponentType
		and F1.Position<F.Position)=9"

	exec @ErrorCode=sp_executesql @sSQLString,
					N'@sFrom		nvarchar(4000)	OUTPUT,
					  @psTempTableName	nvarchar(60)',
					  @sFrom=@sFrom10			OUTPUT,
					  @psTempTableName=@psTempTableName
End

If  @sFrom10 is not null
and @ErrorCode=0
Begin
	Set @sSQLString="
	Select @sFrom=replace(F.SavedString,'Join '+@psTempTableName+' TT on (TT.CASEID=C.CASEID)','')
	from #TempConstructSQL F
	where F.ComponentType='F'
	and (	select count(*)
		from #TempConstructSQL F1
		where F1.ComponentType=F.ComponentType
		and F1.Position<F.Position)=10"

	exec @ErrorCode=sp_executesql @sSQLString,
					N'@sFrom		nvarchar(4000)	OUTPUT,
					  @psTempTableName	nvarchar(60)',
					  @sFrom=@sFrom11			OUTPUT,
					  @psTempTableName=@psTempTableName
End

If  @sFrom11 is not null
and @ErrorCode=0
Begin
	Set @sSQLString="
	Select @sFrom=replace(F.SavedString,'Join '+@psTempTableName+' TT on (TT.CASEID=C.CASEID)','')
	from #TempConstructSQL F
	where F.ComponentType='F'
	and (	select count(*)
		from #TempConstructSQL F1
		where F1.ComponentType=F.ComponentType
		and F1.Position<F.Position)=11"

	exec @ErrorCode=sp_executesql @sSQLString,
					N'@sFrom		nvarchar(4000)	OUTPUT,
					  @psTempTableName	nvarchar(60)',
					  @sFrom=@sFrom12			OUTPUT,
					  @psTempTableName=@psTempTableName
End

-- Now get the additial FROM clause components used in the UNION.

If  @sUnionFrom1 is not null
and @ErrorCode=0
Begin
	Set @sSQLString="
	Select @sUnionFrom=replace(V.SavedString,'Join '+@psTempTableName+' TT on (TT.CASEID=C.CASEID)','')
	from #TempConstructSQL V
	where V.ComponentType='V'
	and (	select count(*)
		from #TempConstructSQL V1
		where V1.ComponentType=V.ComponentType
		and V1.Position<V.Position)=1"

	exec @ErrorCode=sp_executesql @sSQLString,
					N'@sUnionFrom	nvarchar(4000)	OUTPUT,
					  @psTempTableName	nvarchar(60)',
					  @sUnionFrom=@sUnionFrom2	OUTPUT,
					  @psTempTableName=@psTempTableName
End

If  @sUnionFrom2 is not null
and @ErrorCode=0
Begin
	Set @sSQLString="
	Select @sUnionFrom=replace(V.SavedString,'Join '+@psTempTableName+' TT on (TT.CASEID=C.CASEID)','')
	from #TempConstructSQL V
	where V.ComponentType='V'
	and (	select count(*)
		from #TempConstructSQL V1
		where V1.ComponentType=V.ComponentType
		and V1.Position<V.Position)=2"

	exec @ErrorCode=sp_executesql @sSQLString,
					N'@sUnionFrom	nvarchar(4000)	OUTPUT,
					  @psTempTableName	nvarchar(60)',
					  @sUnionFrom=@sUnionFrom3	OUTPUT,
					  @psTempTableName=@psTempTableName
End

If  @sUnionFrom3 is not null
and @ErrorCode=0
Begin
	Set @sSQLString="
	Select @sUnionFrom=replace(V.SavedString,'Join '+@psTempTableName+' TT on (TT.CASEID=C.CASEID)','')
	from #TempConstructSQL V
	where V.ComponentType='V'
	and (	select count(*)
		from #TempConstructSQL V1
		where V1.ComponentType=V.ComponentType
		and V1.Position<V.Position)=3"

	exec @ErrorCode=sp_executesql @sSQLString,
					N'@sUnionFrom	nvarchar(4000)	OUTPUT,
					  @psTempTableName	nvarchar(60)',
					  @sUnionFrom=@sUnionFrom4	OUTPUT,
					  @psTempTableName=@psTempTableName
End

If  @sUnionFrom4 is not null
and @ErrorCode=0
Begin
	Set @sSQLString="
	Select @sUnionFrom=replace(V.SavedString,'Join '+@psTempTableName+' TT on (TT.CASEID=C.CASEID)','')
	from #TempConstructSQL V
	where V.ComponentType='V'
	and (	select count(*)
		from #TempConstructSQL V1
		where V1.ComponentType=V.ComponentType
		and V1.Position<V.Position)=4"

	exec @ErrorCode=sp_executesql @sSQLString,
					N'@sUnionFrom		nvarchar(4000)	OUTPUT,
					  @psTempTableName	nvarchar(60)',
					  @sUnionFrom=@sUnionFrom5	OUTPUT,
					  @psTempTableName=@psTempTableName
End

If  @sUnionFrom5 is not null
and @ErrorCode=0
Begin
	Set @sSQLString="
	Select @sUnionFrom=replace(V.SavedString,'Join '+@psTempTableName+' TT on (TT.CASEID=C.CASEID)','')
	from #TempConstructSQL V
	where V.ComponentType='V'
	and (	select count(*)
		from #TempConstructSQL V1
		where V1.ComponentType=V.ComponentType
		and V1.Position<V.Position)=5"

	exec @ErrorCode=sp_executesql @sSQLString,
					N'@sUnionFrom		nvarchar(4000)	OUTPUT,
					  @psTempTableName	nvarchar(60)',
					  @sUnionFrom=@sUnionFrom6		OUTPUT,
					  @psTempTableName=@psTempTableName
End

If  @sUnionFrom6 is not null
and @ErrorCode=0
Begin
	Set @sSQLString="
	Select @sUnionFrom=replace(V.SavedString,'Join '+@psTempTableName+' TT on (TT.CASEID=C.CASEID)','')
	from #TempConstructSQL V
	where V.ComponentType='V'
	and (	select count(*)
		from #TempConstructSQL V1
		where V1.ComponentType=V.ComponentType
		and V1.Position<V.Position)=6"

	exec @ErrorCode=sp_executesql @sSQLString,
					N'@sUnionFrom		nvarchar(4000)	OUTPUT,
					  @psTempTableName	nvarchar(60)',
					  @sUnionFrom=@sUnionFrom7		OUTPUT,
					  @psTempTableName=@psTempTableName
End

If  @sUnionFrom7 is not null
and @ErrorCode=0
Begin
	Set @sSQLString="
	Select @sUnionFrom=replace(V.SavedString,'Join '+@psTempTableName+' TT on (TT.CASEID=C.CASEID)','')
	from #TempConstructSQL V
	where V.ComponentType='V'
	and (	select count(*)
		from #TempConstructSQL V1
		where V1.ComponentType=V.ComponentType
		and V1.Position<V.Position)=7"

	exec @ErrorCode=sp_executesql @sSQLString,
					N'@sUnionFrom		nvarchar(4000)	OUTPUT,
					  @psTempTableName	nvarchar(60)',
					  @sUnionFrom=@sUnionFrom8		OUTPUT,
					  @psTempTableName=@psTempTableName
End

If  @sUnionFrom8 is not null
and @ErrorCode=0
Begin
	Set @sSQLString="
	Select @sUnionFrom=replace(V.SavedString,'Join '+@psTempTableName+' TT on (TT.CASEID=C.CASEID)','')
	from #TempConstructSQL V
	where V.ComponentType='V'
	and (	select count(*)
		from #TempConstructSQL V1
		where V1.ComponentType=V.ComponentType
		and V1.Position<V.Position)=8"

	exec @ErrorCode=sp_executesql @sSQLString,
					N'@sUnionFrom		nvarchar(4000)	OUTPUT,
					  @psTempTableName	nvarchar(60)',
					  @sUnionFrom=@sUnionFrom9		OUTPUT,
					  @psTempTableName=@psTempTableName
End

If  @sUnionFrom9 is not null
and @ErrorCode=0
Begin
	Set @sSQLString="
	Select @sUnionFrom=replace(V.SavedString,'Join '+@psTempTableName+' TT on (TT.CASEID=C.CASEID)','')
	from #TempConstructSQL V
	where V.ComponentType='V'
	and (	select count(*)
		from #TempConstructSQL V1
		where V1.ComponentType=V.ComponentType
		and V1.Position<V.Position)=9"

	exec @ErrorCode=sp_executesql @sSQLString,
					N'@sUnionFrom		nvarchar(4000)	OUTPUT,
					  @psTempTableName	nvarchar(60)',
					  @sUnionFrom=@sUnionFrom10		OUTPUT,
					  @psTempTableName=@psTempTableName
End

If  @sUnionFrom10 is not null
and @ErrorCode=0
Begin
	Set @sSQLString="
	Select @sUnionFrom=replace(V.SavedString,'Join '+@psTempTableName+' TT on (TT.CASEID=C.CASEID)','')
	from #TempConstructSQL V
	where V.ComponentType='V'
	and (	select count(*)
		from #TempConstructSQL V1
		where V1.ComponentType=V.ComponentType
		and V1.Position<V.Position)=10"

	exec @ErrorCode=sp_executesql @sSQLString,
					N'@sUnionFrom		nvarchar(4000)	OUTPUT,
					  @psTempTableName	nvarchar(60)',
					  @sUnionFrom=@sUnionFrom11		OUTPUT,
					  @psTempTableName=@psTempTableName
End

If  @sUnionFrom11 is not null
and @ErrorCode=0
Begin
	Set @sSQLString="
	Select @sUnionFrom=replace(V.SavedString,'Join '+@psTempTableName+' TT on (TT.CASEID=C.CASEID)','')
	from #TempConstructSQL V
	where V.ComponentType='V'
	and (	select count(*)
		from #TempConstructSQL V1
		where V1.ComponentType=V.ComponentType
		and V1.Position<V.Position)=11"

	exec @ErrorCode=sp_executesql @sSQLString,
					N'@sUnionFrom		nvarchar(4000)	OUTPUT,
					  @psTempTableName	nvarchar(60)',
					  @sUnionFrom=@sUnionFrom12		OUTPUT,
					  @psTempTableName=@psTempTableName
End

-- If the user is external then the Cases to be reported will be stored in a temporary table.
-- This is a performance improvement because the functions that restrict Cases to external
-- users degrades in performance as the SQL becomes more complex.
If @pbExternalUser=1
and @ErrorCode=0
Begin
	-- Modify the WhereFilter so it can be used to load Cases 
	-- directly into a temporary table.
	Set @nStart=patindex('%CASES XC%',@psWhereFilter)

	If @nStart>0
	Begin
		Set @nStart=@nStart+22
		Set @sSQLString=replace(substring(@psWhereFilter,@nStart,len(@psWhereFilter)),'and XC.CASEID=C.CASEID)','')

		-- SQA15498
		-- If the filter includes a global temporary table then we know
		-- that a multi part query with a Boolean connection has occurred.
		-- Need to strip out filter from the UNION containing the first
		-- part of the query in preparation for loading the Cases from
		-- the entire filter into a temporary table.
		If patindex('%from ##SEARCHCASE%',@sSQLString)>0
		Begin
			Set @sSQLString=replace(@sSQLString,'and XC.CASEID=C.CASEID','')
			Set @sSQLString=replace(@sSQLString,'where TC.CASEID=C.CASEID)','')
		End
	
		Set @sSQLString='Insert into #TEMPEXTERNALUSERCASES(CASEID)'+char(10)+
				'Select distinct XC.CASEID'+char(10)+
				'from CASES XC'+
				CASE WHEN(@pbGetInstructions=1)
					THEN char(10)+
					     'cross join INSTRUCTIONDEFINITION IND'+char(10)+
					     'join CASENAME CN	on (CN.CASEID=XC.CASEID'+char(10)+
					     '			and CN.NAMETYPE=IND.INSTRUCTNAMETYPE)'+char(10)+
					     'join dbo.fn_FilterUserNames('+convert(varchar,@pnUserIdentityId)+',1) INUN on (INUN.NAMENO=CN.NAMENO)'
				END
				+char(10)+@sSQLString
	
		If @pbPrintSQL = 1
		Begin
			Print ''
			Print @sSQLString
		End
	
		exec @ErrorCode=sp_executesql @sSQLString
	
		-- The Where filter can be cleared out because the 
		-- results are now held in #TEMPEXTERNALUSERCASES
		Set @psWhereFilter=null
	
		-- The interim temporary table of Cases will be added to the FROM clause
		Set @sFromTempTable=char(10)+'join #TEMPEXTERNALUSERCASES TXUS on (TXUS.CASEID=C.CASEID)'
	End
End

If @ErrorCode=0
Begin				     
	-------------------------------------------------
	-- RFC62317
	-- Add a common table expression (CTE) to get the 
	-- minimum sequence for a CASEID and NAMETYPE
	------------------------------------------------- 	
	Set @sCTE='with CTE_CaseNameSequence (CASEID, NAMETYPE, SEQUENCE)'+CHAR(10)+
		  'as (	select CASEID, NAMETYPE, MIN(SEQUENCE)'+CHAR(10)+
		  '	from CASENAME with (NOLOCK)'+CHAR(10)+
		  '	where EXPIRYDATE is null or EXPIRYDATE>GETDATE()'+CHAR(10)+
		  '	group by CASEID, NAMETYPE)'+CHAR(10)

	Set @sSelectList="Insert into #TEMPSORTEDCASES(CASEID)"+char(10)+
			 "Select C.CASEID"+char(10)

	If @sUnionFrom1 is not null
	Begin
		Set @sUnionSelect="UNION Select C.CASEID"+char(10)
		set @sUnionFromTempTable=@sFromTempTable
		Set @sUnionFilter=@psWhereFilter
		Set @sUnionGroupBy=@sGroupBy
	End

	If @pbPrintSQL = 1
	Begin
		-- Print out the executed SQL statement:
		Print ''
		Print 'SET ANSI_NULLS OFF; '+
		      @sCTE+
		      @sSelectList+
		      @sFrom1+@sFrom2+@sFrom3+@sFrom4+
		      @sFrom5+@sFrom6+@sFrom7+@sFrom8+
		      @sFrom9+@sFrom10+@sFrom11+@sFrom12 +
		      @sFromTempTable+
		      @sWhere+@psWhereFilter+@sGroupBy+
		      @sUnionSelect+
		      @sUnionFrom1+@sUnionFrom2+@sUnionFrom3+@sUnionFrom4+
		      @sUnionFrom5+@sUnionFrom6+@sUnionFrom7+@sUnionFrom8+
		      @sUnionFrom9+@sUnionFrom10+@sUnionFrom11+@sUnionFrom12+
		      @sUnionFromTempTable+
		      @sUnionWhere+@sUnionFilter+
		      @sUnionGroupBy+@sOrder
	End

	exec ( 'SET ANSI_NULLS OFF; '+
	      @sCTE+
	      @sSelectList+
	      @sFrom1+@sFrom2+@sFrom3+@sFrom4+
	      @sFrom5+@sFrom6+@sFrom7+@sFrom8+
	      @sFrom9+@sFrom10+@sFrom11+@sFrom12+
	      @sFromTempTable+
	      @sWhere+@psWhereFilter+@sGroupBy+
	      @sUnionSelect+
	      @sUnionFrom1+@sUnionFrom2+@sUnionFrom3+@sUnionFrom4+
	      @sUnionFrom5+@sUnionFrom6+@sUnionFrom7+@sUnionFrom8+
	      @sUnionFrom9+@sUnionFrom10+@sUnionFrom11+@sUnionFrom12+
	      @sUnionFromTempTable+
	      @sUnionWhere+@sUnionFilter+
	      @sUnionGroupBy+@sOrder)

	Select 	@ErrorCode =@@Error,
		@pnRowCount=@@Rowcount
End

If @ErrorCode=0
and @pnRowCount>0
Begin
	-- Remove any duplicate CASEIDs that were inserted into #TEMPSORTEDCASES
	-- A DISTINCT clause could not be used in the INSERT because
	-- an ORDER BY may have been required on columns other than CASEID
	Set @sSQLString="
	Delete #TEMPSORTEDCASES
	from #TEMPSORTEDCASES T1
	join (select * from #TEMPSORTEDCASES) T2
			on (T2.CASEID=T1.CASEID
			and T2.SEQUENCENO<T1.SEQUENCENO)"

	exec @ErrorCode=sp_executesql @sSQLString

	-- Now load the #TEMPCASES table to get a contiguous
	-- set of SEQUENCENOs
	If @ErrorCode=0
	Begin
		Set @sSQLString="
		insert into #TEMPCASES(CASEID)
		select CASEID
		from #TEMPSORTEDCASES
		order by SEQUENCENO"
	
		exec @ErrorCode=sp_executesql @sSQLString
	
		Set @pnRowCount=@@Rowcount
	End
End

RETURN @ErrorCode
go

grant execute on dbo.csw_LoadSortedResult  to public
go
