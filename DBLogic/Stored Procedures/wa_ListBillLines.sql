-----------------------------------------------------------------------------------------------------------------------------
-- Creation of dbo.wa_ListBillLines
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[wa_ListBillLines]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.wa_ListBillLines'
	drop procedure [dbo].[wa_ListBillLines]
end
print '**** Creating procedure dbo.wa_ListBillLines...'
print ''
go

CREATE PROCEDURE [dbo].[wa_ListBillLines]
			@iRowCount	int output, /* the number of rows available */
			@iPage		int,
			@iPageSize	int,
			@pnItemEntityNo	int,
			@pnItemTransNo	int
AS
-- PROCEDURE :	wa_ListBillLines
-- DESCRIPTION:	List billing print lines that are to be displayed for a particular Open Item.
--				Note that these are the presentation lines not the actual WorkHistory rows
--				that have been billed.
-- CALLED BY :	

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 16/07/2001	MF			Procedure created
-- 1/8/2001	AF  			Add ITEMLINENO to the selection
-- 16/08/2001	MF			Allow all rows to be returned if @iPageSize is zero.
-- 16/10/2001	MF			Format the values returned as currency.
-- 06 Aug 2004	AB	8035	5	Add collate database_default to temp table definitions

	-- set server options
	set NOCOUNT on
	set CONCAT_NULL_YIELDS_NULL off

	-- declare variables
	declare	@ErrorCode	int	-- declare variables
	declare @iStart		int	-- start record
	declare @iEnd		int	-- end record
	declare @iPageCount	int	-- total number of pages

	-- initialise variables
	set @ErrorCode=0

	-- create the temporary table and populate it
	create table #pagedBillLine
	(
		ID			int		IDENTITY,
		ITEMLINENO  		smallint,
		PRINTCHARGECURRNCY	varchar(3)	collate database_default NULL,
		IRN			varchar(20)	collate database_default NULL,
		VALUE			decimal(11,2)	NULL,
		FOREIGNVALUE		decimal(11,2)	NULL,
		PRINTDATE		datetime	NULL,
		PRINTNAME		varchar(60)	collate database_default NULL,
		PRINTCHARGEOUTRATE	decimal(11,2)	NULL,
		PRINTTIMECHARGED	varchar(5)	collate database_default NULL,
		NARRATIVE		text		collate database_default NULL
	)

	insert into #pagedBillLine
	       (ITEMLINENO, PRINTCHARGECURRNCY, IRN, VALUE, FOREIGNVALUE, PRINTDATE,
		PRINTNAME, PRINTCHARGEOUTRATE, PRINTTIMECHARGED, NARRATIVE)
	SELECT	ITEMLINENO, PRINTCHARGECURRNCY,
		IRN,
		VALUE,
		FOREIGNVALUE,
		PRINTDATE,
		PRINTNAME,
		PRINTCHARGEOUTRATE,
		CASE WHEN (PRINTTOTALUNITS>0 and UNITSPERHOUR>0)
			THEN convert(varchar,ROUND((PRINTTOTALUNITS/UNITSPERHOUR), 0))+":"+REPLICATE("0",2-datalength(convert(varchar,(PRINTTOTALUNITS*(60/UNITSPERHOUR))-(60*ROUND((PRINTTOTALUNITS/UNITSPERHOUR), 0)))))+convert(varchar,(PRINTTOTALUNITS*(60/UNITSPERHOUR))-(60*ROUND((PRINTTOTALUNITS/UNITSPERHOUR), 0)))
		END,
		isnull(SHORTNARRATIVE, isnull(LONGNARRATIVE, N.NARRATIVETEXT))
		FROM  BILLLINE B
		left join NARRATIVE N	on (N.NARRATIVENO=B.NARRATIVENO)
		WHERE B.ITEMENTITYNO = @pnItemEntityNo 
		AND   B.ITEMTRANSNO  = @pnItemTransNo
		ORDER BY  B.DISPLAYSEQUENCE

		Select @ErrorCode=@@Error

	-- work out how many pages there are in total
	SELECT	@iRowCount = COUNT(*)
	FROM 	#pagedBillLine

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
	SELECT	ITEMLINENO, PRINTCHARGECURRNCY, 
		IRN, 
		VALUE		=CONVERT(VARCHAR(20), CAST(VALUE        as MONEY), 1), 
		FOREIGNVALUE	=CONVERT(VARCHAR(20), CAST(FOREIGNVALUE as MONEY), 1), 
		PRINTDATE,
		PRINTNAME, 
		PRINTCHARGEOUTRATE=CONVERT(VARCHAR(20), CAST(PRINTCHARGEOUTRATE as MONEY), 1), 
		PRINTTIMECHARGED, 
		NARRATIVE
	FROM	#pagedBillLine
	WHERE	ID > @iStart
	AND	ID < @iEnd
	order by ID

	DROP TABLE #pagedBillLine

	-- Return the number of records left
	RETURN @iPageCount

go

grant execute on [dbo].[wa_ListBillLines] to public
go

