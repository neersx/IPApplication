-----------------------------------------------------------------------------------------------------------------------------
-- Creation of dbo.wa_ListDebtorOpenItems
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[wa_ListDebtorOpenItems]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.wa_ListDebtorOpenItems'
	drop procedure [dbo].[wa_ListDebtorOpenItems]
end
print '**** Creating procedure dbo.wa_ListDebtorOpenItems...'
print ''
go

CREATE PROCEDURE [dbo].[wa_ListDebtorOpenItems]
			@iRowCount	int output, /* the number of rows available */
			@iPage		int,
			@iPageSize	int,
			@pnEntityNo	int,
			@pnDebtorNo	int	=NULL,
			@pnItemTransNo	int	=NULL
AS
-- PROCEDURE :	wa_ListDebtorOpenItems
-- DESCRIPTION:	List details of debtor open items for a specific Entity and Debtor.
-- CALLED BY :	

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 16/07/2001	MF		1	Procedure created
-- 03/08/2001	MF		2	Returns additional details to about the Open Item
-- 16/08/2001	MF		3	Allow all rows to be returned if @iPageSize is zero.
-- 16/10/2001	AF		4	Format currency fields
-- 06/11/2001	MF		5	Allow a specific transaction number to be passed as a parameter and return
--					details of that item.  Also return the ITEMTYPE code as well as the description.
-- 06 Aug 2004	AB	8035	6	Add collate database_default to temp table definitions

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
	if @ErrorCode=0
	begin
		create table #pagedOpenItems
		(
			ID		int		IDENTITY,
			ITEMENTITYNO	int		NOT NULL, 
			ITEMTRANSNO	int		NOT NULL,   
			OPENITEMNO	varchar(12)	collate database_default NOT NULL
		)
		set @ErrorCode=@@Error
	end

	if  @ErrorCode=0
	and @pnItemTransNo is null
	Begin
		insert into #pagedOpenItems 
		       (ITEMENTITYNO, ITEMTRANSNO, OPENITEMNO)
		SELECT	O.ITEMENTITYNO, 
			O.ITEMTRANSNO,   
			O.OPENITEMNO
		FROM  OPENITEM O
		WHERE O.ACCTENTITYNO = @pnEntityNo 
		AND   O.ACCTDEBTORNO = @pnDebtorNo 
		AND   O.STATUS = 1 
		AND   O.CLOSEPOSTPERIOD = 999999 
		ORDER BY  O.OPENITEMNO
	
		Select @ErrorCode=@@Error
	End
	Else if  @ErrorCode=0
	and  @pnItemTransNo is not null
	Begin
		insert into #pagedOpenItems 
		       (ITEMENTITYNO, ITEMTRANSNO, OPENITEMNO)
		SELECT	O.ITEMENTITYNO, 
			O.ITEMTRANSNO,   
			O.OPENITEMNO
		FROM  OPENITEM O
		WHERE O.ITEMENTITYNO = @pnEntityNo 
		AND   O.ITEMTRANSNO  = @pnItemTransNo
		AND   O.STATUS = 1 
		AND   O.CLOSEPOSTPERIOD = 999999 
		ORDER BY  O.OPENITEMNO
	
		Select @ErrorCode=@@Error
	End

	-- work out how many pages there are in total
	SELECT	@iRowCount = COUNT(*)
	FROM 	#pagedOpenItems

	If @iPageSize>0
	Begin
		SELECT @iPageCount = CEILING(@iRowCount / @iPageSize) + 1
	End
	Else Begin
		If @iRowCount>0
		begin
		 	SELECT @iPageCount=1
		end
		else begin
			SELECT @iPageCount=0
		end
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

	-- select only those records that fall within our page and also get some additional
	-- information to display
	SELECT	O.ITEMENTITYNO,
		O.ITEMTRANSNO,
		O.OPENITEMNO,
		O.ITEMDATE,
		O.BILLPERCENTAGE,
		LOCALVALUE	=CONVERT(VARCHAR(20), CAST(O.LOCALVALUE   as MONEY), 1), 
		LOCALBALANCE	=CONVERT(VARCHAR(20), CAST(O.LOCALBALANCE as MONEY), 1), 
		O.CURRENCY,
		O.EXCHRATE,
		FOREIGNVALUE	=O.CURRENCY+CONVERT(VARCHAR(20), CAST(O.FOREIGNVALUE   as MONEY), 1), 
		FOREIGNBALANCE	=O.CURRENCY+CONVERT(VARCHAR(20), CAST(O.FOREIGNBALANCE as MONEY), 1), 
		O.REFERENCETEXT,
		O.LONGREFTEXT,
		O.REGARDING,
		O.LONGREGARDING,
		O.SCOPE,
		NOOFDAYSOLD	=datediff(dd,O.ITEMDATE,getdate()), 
		DEBTORTYPEDESC	=DT.DESCRIPTION,
		O.ITEMTYPE,
		RAISEDBYNAME	=convert(varchar(254),	CASE WHEN EMP.TITLE IS NOT NULL THEN EMP.TITLE + ' ' ELSE '' END  +
				 			CASE WHEN EMP.FIRSTNAME IS NOT NULL THEN EMP.FIRSTNAME  + ' ' ELSE '' END +
				 			EMP.NAME),
		NS.FORMATTEDNAME, 
		NS.FORMATTEDADDRESS, 
		NS.FORMATTEDATTENTION  
	FROM #pagedOpenItems P
	     join OPENITEM O		on (O.ITEMENTITYNO=P.ITEMENTITYNO
					and O.ITEMTRANSNO =P.ITEMTRANSNO)
	     join DEBTOR_ITEM_TYPE DT	on (DT.ITEM_TYPE_ID=O.ITEMTYPE)
	left join NAME EMP  		on (EMP.NAMENO=O.EMPLOYEENO)
	left join NAMEADDRESSSNAP NS	on (NS.NAMESNAPNO = O.NAMESNAPNO)  
	WHERE	ID > @iStart
	AND	ID < @iEnd
	order by ID

	DROP TABLE #pagedOpenItems

	-- Return the number of records left
	RETURN @iPageCount

go

grant execute on [dbo].[wa_ListDebtorOpenItems]  to public
go

