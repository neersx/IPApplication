-----------------------------------------------------------------------------------------------------------------------------
-- Creation of dbo.wa_ListBilledWorkHistory
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[wa_ListBilledWorkHistory]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.wa_ListBilledWorkHistory'
	drop procedure [dbo].[wa_ListBilledWorkHistory]
end
print '**** Creating procedure dbo.wa_ListBilledWorkHistory...'
print ''
go

CREATE PROCEDURE [dbo].[wa_ListBilledWorkHistory]
			@iRowCount	int output, /* the number of rows available */
			@iPage		int,
			@iPageSize	int,
			@pnItemEntityNo	int,
			@pnItemTransNo	int,
			@pnItemLineNo	int = NULL
AS
-- PROCEDURE :	wa_ListBilledWorkHistory
-- DESCRIPTION:	Display the WORKHISTORY included on the OpenItem or if a specific BillLine row
--		is identified then return the WorkHistory included in that BillLine.
-- CALLED BY :	
-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 16/07/2001	MF			Procedure created
-- 16/08/2001	MF			Allow all rows to be returned if @iPageSize is zero.
-- 15/10/2001	MF			WIPTYPE Description was reversed with WIPTEMPLATE description.
-- 16/10/2001	MF			Return the values formatted as currency
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
	create table #pagedWorkHistory
	(
		ID			int		IDENTITY,
		ENTITYNO		int		NOT NULL,
		TRANSNO			int		NOT NULL,
		TRANSDATE		datetime	NULL,
		POSTDATE		datetime	NULL,
		WIPCODE			varchar(6)	collate database_default NULL,
		WIPDESCRIPTION		varchar(30)	collate database_default NULL,
		WIPTYPEDESC		varchar(50)	collate database_default NULL,
		WIPCATGDESC		varchar(50)	collate database_default NULL,
		DEBTORNAME		varchar(254)	collate database_default NULL,
		IRN			varchar(20)	collate database_default NULL,
		CASETITLE		varchar(254)	collate database_default NULL,
		EMPLOYEENAME		varchar(254)	collate database_default NULL,
		SUPPLIERNAME		varchar(254)	collate database_default NULL,
		SUPPLIERINVOICE		varchar(20)	collate database_default NULL,
		TOTALTIME		datetime	NULL,
		CHARGEOUTRATE		decimal(11,2)	NULL,
		FOREIGNCURRENCY		varchar(3)	collate database_default NULL,
		FOREIGNTRANVALUE 	decimal(11,2)	NULL,
		LOCALTRANSVALUE		decimal(11,2)	NULL,
		NARRATIVE		text		collate database_default NULL

	)

	if @pnItemLineNo is null
	begin
		insert into #pagedWorkHistory
		       (ENTITYNO, TRANSNO, TRANSDATE, POSTDATE, WIPCODE, WIPDESCRIPTION,
			WIPTYPEDESC, WIPCATGDESC, DEBTORNAME, IRN, CASETITLE,
			EMPLOYEENAME, SUPPLIERNAME, SUPPLIERINVOICE, TOTALTIME,
			CHARGEOUTRATE, FOREIGNCURRENCY, FOREIGNTRANVALUE, LOCALTRANSVALUE,
			NARRATIVE)
	
		select	WH.ENTITYNO,
			WHORIG.TRANSNO,
			WHORIG.TRANSDATE,
			WH.POSTDATE,
			WH.WIPCODE,
			WT.DESCRIPTION,
			W.DESCRIPTION,
			WC.DESCRIPTION,
			convert( varchar(254), DEBTOR.NAME+ CASE WHEN DEBTOR.FIRSTNAME IS NOT NULL THEN ', ' END +DEBTOR.FIRSTNAME),
			C.IRN,
			C.TITLE,
			convert( varchar(254), STAFF.NAME+ CASE WHEN STAFF.FIRSTNAME IS NOT NULL THEN ', ' END +STAFF.FIRSTNAME),
			convert( varchar(254), ASSOC.NAME+ CASE WHEN ASSOC.FIRSTNAME IS NOT NULL THEN ', ' END +ASSOC.FIRSTNAME),
			WHORIG.INVOICENUMBER,
			WHORIG.TOTALTIME,
			WHORIG.CHARGEOUTRATE,
			WHORIG.FOREIGNCURRENCY,
			WH.FOREIGNTRANVALUE,
			WH.LOCALTRANSVALUE,
			isnull(WHORIG.SHORTNARRATIVE, isnull(WHORIG.LONGNARRATIVE, N.NARRATIVETEXT))
		From WORKHISTORY WH    	
		join WORKHISTORY WHORIG 	on (WHORIG.ENTITYNO   = WH.ENTITYNO       
						and WHORIG.TRANSNO    = WH.TRANSNO      
						and WHORIG.WIPSEQNO   = WH.WIPSEQNO       
						and WHORIG.ITEMIMPACT = 1 )  
		join WIPTEMPLATE WT 		on (WT.WIPCODE  = WH.WIPCODE)  
		join WIPTYPE W  		on (W.WIPTYPEID  = WT.WIPTYPEID)  
		join WIPCATEGORY WC 		on (WC.CATEGORYCODE = W.CATEGORYCODE)      
		left join WORKHISTORY WH2      	on (WH2.ENTITYNO    = WH.ENTITYNO
		       				and WH2.TRANSNO     = WH.TRANSNO
		       				and WH2.WIPSEQNO    = WH.WIPSEQNO
		       				and WH2.REFENTITYNO = WH.REFENTITYNO
		       				and WH2.REFTRANSNO  = WH.REFTRANSNO
		       				and WH2.TRANSTYPE  <>600
		       				and WH2.MOVEMENTCLASS in (3,9))  
		left join REASON R 		on (R.REASONCODE	= WH2.REASONCODE)  
		left join CASES C 		on (C.CASEID		= WH.CASEID)    
		left join NAME DEBTOR 		on (DEBTOR.NAMENO	= WH.ACCTCLIENTNO)  
		left join NAME STAFF 		on (STAFF.NAMENO	= WHORIG.EMPLOYEENO) 
		left join NAME ASSOC 		on (ASSOC.NAMENO	= WHORIG.ASSOCIATENO) 
		left join NARRATIVE N		on (N.NARRATIVENO	= WHORIG.NARRATIVENO)
		where	WH.REFENTITYNO=@pnItemEntityNo
		and	WH.REFTRANSNO =@pnItemTransNo
		and    (WH.MOVEMENTCLASS = 2
		or     (WH.MOVEMENTCLASS = 3          
			and not exists         
			(select * from WORKHISTORY WH3
			 where WH3.ENTITYNO   = WH.ENTITYNO
		 	 and   WH3.TRANSNO     = WH.TRANSNO
			 and   WH3.WIPSEQNO    = WH.WIPSEQNO
			 and   WH3.REFENTITYNO = WH.REFENTITYNO
			 and   WH3.REFTRANSNO  = WH.REFTRANSNO
			 and   WH3.MOVEMENTCLASS=2)      ))
		ORDER BY WC.CATEGORYSORT, WC.CATEGORYCODE, C.IRN, WHORIG.TRANSDATE, STAFF.NAME, STAFF.NAMENO

	End
	Else Begin
		insert into #pagedWorkHistory
		       (ENTITYNO, TRANSNO, TRANSDATE, POSTDATE, WIPCODE, WIPDESCRIPTION,
			WIPTYPEDESC, WIPCATGDESC, DEBTORNAME, IRN, CASETITLE,
			EMPLOYEENAME, SUPPLIERNAME, SUPPLIERINVOICE, TOTALTIME,
			CHARGEOUTRATE, FOREIGNCURRENCY, FOREIGNTRANVALUE, LOCALTRANSVALUE,
			NARRATIVE)
	
		select	WH.ENTITYNO,
			WHORIG.TRANSNO,
			WHORIG.TRANSDATE,
			WH.POSTDATE,
			WH.WIPCODE,
			WT.DESCRIPTION,
			W.DESCRIPTION,
			WC.DESCRIPTION,
			convert( varchar(254), DEBTOR.NAME+ CASE WHEN DEBTOR.FIRSTNAME IS NOT NULL THEN ', ' END +DEBTOR.FIRSTNAME),
			C.IRN,
			C.TITLE,
			convert( varchar(254), STAFF.NAME+ CASE WHEN STAFF.FIRSTNAME IS NOT NULL THEN ', ' END +STAFF.FIRSTNAME),
			convert( varchar(254), ASSOC.NAME+ CASE WHEN ASSOC.FIRSTNAME IS NOT NULL THEN ', ' END +ASSOC.FIRSTNAME),
			WHORIG.INVOICENUMBER,
			WHORIG.TOTALTIME,
			WHORIG.CHARGEOUTRATE,
			WHORIG.FOREIGNCURRENCY,
			WH.FOREIGNTRANVALUE,
			WH.LOCALTRANSVALUE,
			isnull(WHORIG.SHORTNARRATIVE, isnull(WHORIG.LONGNARRATIVE, N.NARRATIVETEXT))
		From WORKHISTORY WH    	
		join WORKHISTORY WHORIG 	on (WHORIG.ENTITYNO   = WH.ENTITYNO       
						and WHORIG.TRANSNO    = WH.TRANSNO      
						and WHORIG.WIPSEQNO   = WH.WIPSEQNO       
						and WHORIG.ITEMIMPACT = 1 )  
		join WIPTEMPLATE WT 		on (WT.WIPCODE  = WH.WIPCODE)  
		join WIPTYPE W  		on (W.WIPTYPEID  = WT.WIPTYPEID)  
		join WIPCATEGORY WC 		on (WC.CATEGORYCODE = W.CATEGORYCODE)      
		left join WORKHISTORY WH2      	on (WH2.ENTITYNO    = WH.ENTITYNO
		       				and WH2.TRANSNO     = WH.TRANSNO
		       				and WH2.WIPSEQNO    = WH.WIPSEQNO
		       				and WH2.REFENTITYNO = WH.REFENTITYNO
		       				and WH2.REFTRANSNO  = WH.REFTRANSNO
		       				and WH2.TRANSTYPE  <>600
		       				and WH2.MOVEMENTCLASS in (3,9))  
		left join REASON R 		on (R.REASONCODE	= WH2.REASONCODE)  
		left join CASES C 		on (C.CASEID		= WH.CASEID)    
		left join NAME DEBTOR 		on (DEBTOR.NAMENO	= WH.ACCTCLIENTNO)  
		left join NAME STAFF 		on (STAFF.NAMENO	= WHORIG.EMPLOYEENO)
		left join NAME ASSOC 		on (ASSOC.NAMENO	= WHORIG.ASSOCIATENO) 
		left join NARRATIVE N		on (N.NARRATIVENO	= WHORIG.NARRATIVENO)
		where	WH.REFENTITYNO=@pnItemEntityNo
		and	WH.REFTRANSNO =@pnItemTransNo
		and	WH.BILLLINENO =@pnItemLineNo
		and    (WH.MOVEMENTCLASS = 2
		or     (WH.MOVEMENTCLASS = 3          
			and not exists         
			(select * from WORKHISTORY WH3
			 where WH3.ENTITYNO  = WH.ENTITYNO
		 	 and   WH3.TRANSNO    = WH.TRANSNO
			 and   WH3.WIPSEQNO    = WH.WIPSEQNO
			 and   WH3.REFENTITYNO = WH.REFENTITYNO
			 and   WH3.REFTRANSNO  = WH.REFTRANSNO
			 and   WH3.MOVEMENTCLASS=2)      )) 
		ORDER BY WC.CATEGORYSORT, WC.CATEGORYCODE, C.IRN, WHORIG.TRANSDATE, STAFF.NAME, STAFF.NAMENO

	End

	Select @ErrorCode=@@Error

	-- work out how many pages there are in total
	SELECT	@iRowCount = COUNT(*)
	FROM 	#pagedWorkHistory

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
	SELECT	ENTITYNO, 
		TRANSNO, 
		TRANSDATE, 
		POSTDATE, 
		WIPCODE, 
		WIPDESCRIPTION,
		WIPTYPEDESC, 
		WIPCATGDESC, 
		DEBTORNAME, 
		IRN, 
		CASETITLE,
		EMPLOYEENAME, 
		SUPPLIERNAME, 
		SUPPLIERINVOICE, 
		TOTALTIME,
		CHARGEOUTRATE	=CONVERT(VARCHAR(20), CAST(CHARGEOUTRATE    as MONEY), 1), 
		FOREIGNCURRENCY, 
		FOREIGNTRANVALUE=CONVERT(VARCHAR(20), CAST(FOREIGNTRANVALUE as MONEY), 1), 
		LOCALTRANSVALUE	=CONVERT(VARCHAR(20), CAST(LOCALTRANSVALUE  as MONEY), 1),
		NARRATIVE
	FROM	#pagedWorkHistory
	WHERE	ID > @iStart
	AND	ID < @iEnd
	order by ID

	DROP TABLE #pagedWorkHistory

	-- turn back on record counts
	SET NOCOUNT OFF

	-- Return the number of records left
	RETURN @iPageCount

go

grant execute on [dbo].[wa_ListBilledWorkHistory] to public
go

