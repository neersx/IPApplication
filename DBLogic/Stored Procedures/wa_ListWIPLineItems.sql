-----------------------------------------------------------------------------------------------------------------------------
-- Creation of dbo.wa_ListWIPLineItems
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[wa_ListWIPLineItems]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.wa_ListWIPLineItems'
	drop procedure [dbo].[wa_ListWIPLineItems]
end
print '**** Creating procedure dbo.wa_ListWIPLineItems...'
print ''
go

set QUOTED_IDENTIFIER off
go

CREATE PROCEDURE [dbo].[wa_ListWIPLineItems]
			@iRowCount	int output, /* the number of rows available */
			@iPage		int,
			@iPageSize	int,
			@pnCaseId	int,
			@pnEntityNo	int	  = NULL,
			@psCategoryCode varchar(3)= NULL
AS
-- PROCEDURE :	wa_ListWIPLineItems
-- DESCRIPTION:	List details of debtor open items for a specific Entity and Debtor.
-- CALLED BY :	

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 16/07/2001	MF		1	Procedure created
-- 16/08/2001	MF		2	Allow all rows to be returned if @iPageSize is zero.
-- 06 Aug 2004	AB	8035	3	Add collate database_default to temp table definitions

	-- set server options
	set NOCOUNT on
	set CONCAT_NULL_YIELDS_NULL off

	-- declare variables
	declare	@ErrorCode	int		-- declare variables
	declare @iStart		int		-- start record
	declare @iEnd		int		-- end record
	declare @iPageCount	int		-- total number of pages
	declare @sInsertString	nvarchar(2000)
	declare @sWhereClause	nvarchar(1000)
	declare @sOrderBy	nvarchar(500)

	-- initialise variables
	set @ErrorCode=0

	-- create the temporary table and populate it
	create table #pagedWIP
	(
		ID		int		IDENTITY,
		WIPCATEGORYDESC	nvarchar(50)	collate database_default NOT NULL, 
		WIPDESC		nvarchar(30)	collate database_default NOT NULL, 
		TRANSDATE	datetime	NULL, 
		FORMATTEDTIME	varchar(5)	collate database_default NULL, 
		CHARGEOUTRATE	decimal(11,2)	NULL,
		LOCALVALUE	decimal(11,2)	NULL,
		BALANCE		decimal(11,2)	NULL,  
		FOREIGNVALUE	decimal(11,2)	NULL,
		FOREIGNCURRENCY	nvarchar(3)	collate database_default NULL,
		INVOICENUMBER	nvarchar(30)	collate database_default NULL,  
		STAFFNAME	nvarchar(254)	collate database_default NULL,  
		ASSOCIATENAME	nvarchar(254)	collate database_default NULL,  
		NARRATIVE	ntext		collate database_default NULL
	)

	set @sInsertString="
	insert into #pagedWIP
	       (WIPCATEGORYDESC,WIPDESC,TRANSDATE,FORMATTEDTIME,CHARGEOUTRATE,LOCALVALUE,
		BALANCE,FOREIGNVALUE,FOREIGNCURRENCY,INVOICENUMBER,STAFFNAME,ASSOCIATENAME,
		NARRATIVE)

		select	WC.DESCRIPTION, 
			W.DESCRIPTION,  
			WIP.TRANSDATE, 
			-- Format the time into HOURS : MINUTES
			convert(varchar(2),DATEPART( HOUR, WIP.TOTALTIME ))+
			CASE WHEN(WIP.TOTALTIME is not null) THEN ':' END  +
			replicate('0',2-datalength(convert(varchar(2),DATEPART( MINUTE, WIP.TOTALTIME))))+convert(varchar(2),DATEPART( MINUTE, WIP.TOTALTIME)),
			WIP.CHARGEOUTRATE,  
			WIP.LOCALVALUE,  
			WIP.BALANCE,  
			WIP.FOREIGNVALUE,
			WIP.FOREIGNCURRENCY,
			WIP.INVOICENUMBER, 
			convert( varchar(254), EMP.NAME+ CASE WHEN EMP.FIRSTNAME IS NOT NULL THEN ', ' END +EMP.FIRSTNAME), 
			convert( varchar(254), ASS.NAME+ CASE WHEN ASS.FIRSTNAME IS NOT NULL THEN ', ' END +ASS.FIRSTNAME),
			isnull(WIP.SHORTNARRATIVE, isnull(WIP.LONGNARRATIVE,NA.NARRATIVETEXT))
		from WORKINPROGRESS WIP
		     join WIPTEMPLATE W		on (W.WIPCODE      =WIP.WIPCODE)
		     join WIPTYPE WT		on (WT.WIPTYPEID   =W.WIPTYPEID)
		     join WIPCATEGORY WC	on (WC.CATEGORYCODE=WT.CATEGORYCODE)
		left join NAME EMP		on (EMP.NAMENO     =WIP.EMPLOYEENO)
		left join NAME ASS		on (ASS.NAMENO     =WIP.ASSOCIATENO)
		left join NARRATIVE NA		on (NA.NARRATIVENO =WIP.NARRATIVENO)"		

	set @sWhereClause="		Where	WIP.CASEID="+convert(varchar,@pnCaseId)

	If @pnEntityNo is not NULL
	Begin
		set @sWhereClause = @sWhereClause+char(10)+"		and	WIP.ENTITYNO="+convert(varchar,@pnEntityNo)
	End

	If @psCategoryCode is not NULL
	Begin
		set @sWhereClause=@sWhereClause+char(10)+"		and	WC.CATEGORYCODE='"+@psCategoryCode+"'"
	End

	set @sOrderBy="		order by WC.CATEGORYSORT, WIP.TRANSDATE"

	set @sInsertString=@sInsertString+@sWhereClause+@sOrderBy

	execute @ErrorCode=sp_executesql @sInsertString

	-- work out how many pages there are in total
	SELECT	@iRowCount = COUNT(*)
	FROM 	#pagedWIP

	If @iPageSize>0
	Begin
		SELECT @iPageCount = CEILING(@iRowCount / @iPageSize) + 1
	End
	Else Begin
		SELECT @iPageCount=0
	End

	-- check the page number
	IF @iPage < 1
		SELECT @iPage = 1

	IF @iPage > @iPageCount
		SELECT @iPage = @iPageCount

	-- calculate the start and end records
	If @iPageSize>0
	Begin
		SELECT @iStart = (@iPage - 1) * @iPageSize
		SELECT @iEnd = @iStart + @iPageSize + 1
	End
	Else Begin
		SELECT @iStart=0
		SELECT @iEnd  =@iRowCount
	End

	-- select only those records that fall within our page
	SELECT	WIPCATEGORYDESC,
		WIPDESC,
		TRANSDATE,
		FORMATTEDTIME,
		CHARGEOUTRATE	=CONVERT(VARCHAR(20), CAST(CHARGEOUTRATE   as MONEY), 1),
		LOCALVALUE	=CONVERT(VARCHAR(20), CAST(LOCALVALUE      as MONEY), 1),
		BALANCE		=CONVERT(VARCHAR(20), CAST(BALANCE         as MONEY), 1),
		FOREIGNVALUE	=CONVERT(VARCHAR(20), CAST(FOREIGNVALUE    as MONEY), 1),
		FOREIGNCURRENCY	=CONVERT(VARCHAR(20), CAST(FOREIGNCURRENCY as MONEY), 1),
		INVOICENUMBER,
		STAFFNAME,
		ASSOCIATENAME,
		NARRATIVE
	FROM	#pagedWIP
	WHERE	ID > @iStart
	AND	ID < @iEnd
	order by ID

	DROP TABLE #pagedWIP

	-- Return the number of records left
	RETURN @iPageCount

go

grant execute on [dbo].[wa_ListWIPLineItems]  to public
go

