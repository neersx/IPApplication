-----------------------------------------------------------------------------------------------------------------------------
-- Creation of wp_WIPItemMatching
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[wp_WIPItemMatching]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.wp_WIPItemMatching.'
	Drop procedure [dbo].[wp_WIPItemMatching]
End
Print '**** Creating Stored Procedure dbo.wp_WIPItemMatching...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.wp_WIPItemMatching
(
	@pnRowCount		int		output,
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pnProcessType		int,	-- 500: Agent Debit Note, 501: Agent Credit Note, 406:Direct Pay, 516:Client Credit Note
	@pbDefaulting		bit,	-- 1: Use logic required to try and default, 0: Use logic for WIP Item Pick List
	-- details entered by user
	@pnEntityNo		int,
	@pnCaseId 		int,
	@psWIPCode		nvarchar(6),
	@pdtTransDate		datetime,	
	@pnAssociateNo		int		= null,
	@pnLocal		decimal(11,2)	= 0,
	@psCurrency		nvarchar(3)	= null,
	@pnForeign		decimal(11,2)	= 0,
	@psAction		nvarchar(2)	= null,
	@pnRateNo		int		= null,	
	-- previously selected invoice
	@psInvoiceNo		nvarchar(20)	= null,
	@pnTransNo		int		= null,
	@pnWIPSeqNo		int		= null,
	@pnRefEntityNo		int		= null,
	@pnRefTransNo		int		= null,
	-- Filter criteria
	@pbIncMatchedItems	bit		= 0, -- If TRUE (1) do not exclude previously matched items. Not applicable to Direct Pays
	@pbIncAuto		bit		= 0, -- depending on the process include transations of type 406:Direct Pays or 514:Generated Bills
	@pbIncManual		bit		= 0, -- depending on the process include transactions of type 402:WIP Recording or 510: Bill 
	@pbBillInAdvance	bit		= 0,
	@psWIPTypeId		nvarchar(6)	= null,		
	@psWIPCategoryList	nvarchar(254)	= null, -- comma separated, quoted list.
	@pdtFromDate		datetime	= null,
	@pdtToDate		datetime	= null,
	@pbDebug		bit		= 0,
	@plsXMLWIPCodes		ntext		= null
)
as
-- PROCEDURE:	wp_WIPItemMatching
-- VERSION:	15
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	This stored procedure is used to try and match the WIP item being processed 
-- 		with a previously processed transaction. 
--		The type of transaction being processed (indicated by @pnProcessType) 
--		determines the type of transaction the stored procedure will try to match to.
--		Possible matches are returned as a result set. 
--		If trying to default selection and this defaulting is successful a single row will be returned.
--		Used by Client/Server


-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 05 06 2008	CR	16175	1	Procedure created
-- 12 06 2008	CR	16175	2	Extended to include RowCount
-- 13 06 2008	CR	16175	3	Changed sort order for Direct Pays from TRANSDATE to POSTDATE
--					so that time is also taken into account.
--					extended previously matched logic to look for specific transtypes.
-- 16 06 2008	CR	16175	4	Removed "Filter" node from WIPCodes XML filter.
-- 17 06 2008	CR	16175	5	Tightened up the previous matches logic
-- 22 06 2008	CR	16175	6	Added logic to retrieve the selected item - for displaying in the pick list.
-- 26 08 2008	CR	16818	7	Fixed a number of problems.
-- 27 08 2008	DL		8	Correct typo on variable @pnWipSeqNo to compile on SQL Server 2000.
-- 28 08 2008	DL		9	Correct typo on variable @pnWipSeqNo to compile on SQL Server 2000.
-- 21 05 2009	Dw	17705	10	Fixed bug where Direct Pays were matching on WIP that had already been matched.
-- 04 12 2009	Dw	18126	11	Change the Order By for Direct Pays so that matching is on most recent invoice.
-- 04 12 2009	Dw	18129	12	Remove Action from matching logic for Direct Pays.
-- 05 Jul 2013	vql	R13629	13	Remove string length restriction and use nvarchar on datetime conversions using 106 format.
-- 02 Nov 2015	vql	R53910	14	Adjust formatted names logic (DR-15543).
-- 14 Nov 2018  AV  75198/DR-45358	15   Date conversion errors when creating cases and opening names in Chinese DB

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

declare @sWIPAttribute		nvarchar(6)
declare @bEnforceWIPAttrFlag	bit
declare @sSql 			nvarchar(4000)
declare @sSqlSelect		nvarchar(1000)
declare @sSqlFrom 		nvarchar(1000)
declare @sSqlWhere		nvarchar(2000)
declare	@nErrorCode 		int
declare @nTopRow		int
Declare @hDoc 			int
Declare @nWIPCodeRowCount	int

-- Initialise variables
Set @nErrorCode = 0
Set @pnRowCount = 0
Set @nWIPCodeRowCount = 0

If @nErrorCode = 0
Begin
	If (@pbDebug = 1)
	Begin
		If (@pnProcessType = 406) -- :Direct Pay
			print '
			-- ** Proces Type: 406 - Direct Pay ** '
		Else If (@pnProcessType = 516) -- :Client Credit Note
			print '
			-- ** Proces Type: 516 - Client Credit Note ** '
		Else If (@pnProcessType = 501) -- :Agent Credit Note
			print '
			-- ** Proces Type: 501 - Agent Credit Note ** '
		Else If (@pnProcessType = 500) -- :Agent Debit Note
			print '
			-- ** Proces Type: 500 - Agent Debit Note ** '
	End
	
	CREATE TABLE #WIPITEMS (WIPITEMID	INT 		IDENTITY (1,1), 
				WIPENTITYNO	INT		NOT NULL,
				WIPTRANSNO	INT		NOT NULL,
				WIPSEQNO	INT		NOT NULL,
				OIENTITYNO	INT		NULL,
				OITRANSNO	INT		NULL,
				INVOICENO	NVARCHAR(20) 	collate database_default NULL,
				TRANSDATE	DATETIME	NOT NULL,
				NAMENO		INT		NOT NULL,
				FORMATTEDNAME	NVARCHAR(254)	collate database_default NOT NULL,
				CASEID		INT		NOT NULL,
				IRN		NVARCHAR(30)	collate database_default NOT NULL,
				WIPCODE		NVARCHAR(6)	collate database_default NOT NULL,
				LOCALVALUE	DECIMAL(11,2)	NOT NULL,
				LOCALCOST	DECIMAL(11,2)	NULL,
				FOREIGNCURRENCY	NVARCHAR(3)	collate database_default NULL,
				FOREIGNVALUE	DECIMAL(11,2)	NULL,
				FOREIGNCOST	DECIMAL(11,2)	NULL,
				STATUS		SMALLINT	NULL,
				STATUSDESC	NVARCHAR(10)	collate database_default NULL,
				BILLINADVANCE	BIT		NULL)
					
	
	CREATE TABLE #WIPCODES (WIPCODE		NVARCHAR(6)	collate database_default NOT NULL)
	

	If (@plsXMLWIPCodes IS NOT NULL) AND (cast(@plsXMLWIPCodes as nvarchar(4000)) <> '')
	Begin
		Exec sp_xml_preparedocument @hDoc OUTPUT, @plsXMLWIPCodes
		Select @nErrorCode = @@Error
		
		If (@nErrorCode = 0)
		Begin
			Set @sSql = "INSERT INTO #WIPCODES"
			+char(10)+"SELECT sCode"
			+char(10)+"From OPENXML( @hDoc, '/tblWIPTemplates/Row', 2 )"
			+char(10)+"WITH (sCode nvarchar(6) 'sCode/text()')"

			Select @nErrorCode = @@Error, @nWIPCodeRowCount = @@RowCount
		
			Exec @nErrorCode = sp_executesql @sSql, N'@hDoc Int', @hDoc
		
			If (@pbDebug = 1)
			Begin
				print '
				-- ** Populating #WIPCODES table ** '
				print @sSql
				select * from #WIPCODES
			End


			If (@nErrorCode = 0)
			Begin
				Exec sp_xml_removedocument @hDoc
				Select @nErrorCode = @@Error
			End
		End
	End	
	
	If (@nErrorCode = 0)
	Begin
		SET @sSql = "SELECT @sWIPAttribute = WIPATTRIBUTE, @bEnforceWIPAttrFlag = ENFORCEWIPATTRFLAG 
		FROM WIPTEMPLATE
		WHERE WIPCODE = @psWIPCode"
		
		exec @nErrorCode=sp_executesql @sSql,
				      	N'@sWIPAttribute	nvarchar(6)		OUTPUT,
					  @bEnforceWIPAttrFlag	bit			OUTPUT,
					  @psWIPCode		nvarchar(6)',
					  @sWIPAttribute=@sWIPAttribute			OUTPUT,
					  @bEnforceWIPAttrFlag=@bEnforceWIPAttrFlag	OUTPUT,
					  @psWIPCode=@psWIPCode
		If (@pbDebug = 1)
		Begin
			print '
			-- ** WIP Attribute details ** '
			select @psWIPCode AS WIPCODE, @sWIPAttribute AS WIPATTRIBUTE, @bEnforceWIPAttrFlag AS ENFORCEWIPATTRFLAG 
		End
	End
		
	If (@nErrorCode = 0)
	Begin
		If (@pbDefaulting = 1)
		Begin
			set @pbIncAuto = 1
			set @pbIncManual = 1
			set @pbBillInAdvance = 1
		End
		
		-- Ensure the Bill In Advance filter option is only used for Agent Debit Notes
		If (@pnProcessType = 406) -- :Direct Pay
		OR (@pnProcessType = 516) -- :Client Credit Note
		OR (@pnProcessType = 501) -- :Agent Credit Note
			set @pbBillInAdvance = 0	
	
		SET @sSqlSelect = "INSERT INTO #WIPITEMS (WIPENTITYNO, WIPTRANSNO, WIPSEQNO, OIENTITYNO, OITRANSNO, INVOICENO, TRANSDATE, "
		+char(10)+"NAMENO, FORMATTEDNAME, CASEID, IRN, WIPCODE, LOCALVALUE, LOCALCOST, FOREIGNCURRENCY, FOREIGNVALUE, FOREIGNCOST, STATUS, "
		+char(10)+"STATUSDESC, BILLINADVANCE)"
		+char(10)+"SELECT "	
		
		-- ** Derive the FROM clause **
		If (@pnProcessType = 500) --: Agent Debit Note
		OR (@pnProcessType = 406) -- :Direct Pay
		OR (@pnProcessType = 516) -- :Client Credit Note
		begin
			set @sSqlSelect = @sSqlSelect + "WH.ENTITYNO, WH.TRANSNO, WH.WIPSEQNO, OI.ITEMENTITYNO, OI.ITEMTRANSNO, OI.OPENITEMNO, WH.TRANSDATE, "
			+char(10)+"OI.ACCTDEBTORNO, CAST(Case	when N.NAMECODE is NULL then NULL"
			+char(10)+"else ' {' + N.NAMECODE + '}' "
			+char(10)+"end + dbo.fn_FormatNameUsingNameNo(N.NAMENO, COALESCE(N.NAMESTYLE, CF.NAMESTYLE, 7101)) as NVARCHAR(254)) as FORMATTEDNAME, "
			+char(10)+"WH.CASEID, C.IRN, WH.WIPCODE, ABS(WH.LOCALTRANSVALUE), ABS(WH.LOCALCOST), WH.FOREIGNCURRENCY, ABS(WH.FOREIGNTRANVALUE), ABS(WH.FOREIGNCOST),"
			+char(10)+"WH.STATUS, 'Active', CASE WHEN WH.COMMANDID = 2 AND WH.ITEMIMPACT = 1 THEN 1 ELSE 0 END" 
			
			set @sSqlFrom = char(10)+"FROM OPENITEM OI"
			+char(10)+"JOIN WORKHISTORY WH	ON (OI.ITEMTRANSNO = WH.REFTRANSNO"
			+char(10)+"			AND OI.ITEMENTITYNO = WH.REFENTITYNO)"
			+char(10)+"JOIN WIPTEMPLATE WT	ON (WT.WIPCODE = WH.WIPCODE)"
			+char(10)+"JOIN CASES C		ON (C.CASEID = WH.CASEID)"
			+char(10)+"JOIN NAME N		ON (N.NAMENO = OI.ACCTDEBTORNO)"
			+char(10)+"LEFT JOIN COUNTRY CF	ON (CF.COUNTRYCODE = N.NATIONALITY)"
		end
		
		else If (@pnProcessType = 501) --: Agent Credit Note
		begin
			set @sSqlSelect = @sSqlSelect + "WH.ENTITYNO, WH.TRANSNO, WH.WIPSEQNO, NULL, NULL, WH.INVOICENUMBER, WH.TRANSDATE, "
			+char(10)+"WH.ASSOCIATENO, CAST(Case	when N.NAMECODE is NULL then NULL"
			+char(10)+"else ' {' + N.NAMECODE + '}' "
			+char(10)+"end + dbo.fn_FormatNameUsingNameNo(N.NAMENO, COALESCE(N.NAMESTYLE, CF.NAMESTYLE, 7101)) as NVARCHAR(254)) as FORMATTEDNAME, "
			+char(10)+"WH.CASEID, C.IRN, WH.WIPCODE, ABS(WH.LOCALTRANSVALUE), ABS(WH.LOCALCOST), WH.FOREIGNCURRENCY, ABS(WH.FOREIGNTRANVALUE), ABS(WH.FOREIGNCOST),"
			+char(10)+"WH.STATUS, 'Active', " + 
			CAST(@pbBillInAdvance AS VARCHAR)
		
			set @sSqlFrom = char(10)+"FROM WORKHISTORY WH"
			+char(10)+"JOIN WIPTEMPLATE WT	ON (WT.WIPCODE = WH.WIPCODE)"
			+char(10)+"JOIN CASES C		ON (C.CASEID = WH.CASEID)"
			+char(10)+"JOIN NAME N		ON (N.NAMENO = WH.ASSOCIATENO)"
			+char(10)+"LEFT JOIN COUNTRY CF	ON (CF.COUNTRYCODE = N.NATIONALITY)"
		end
		

		-- ** Derive the WHERE clause **
	    	Set @sSqlWhere = char(10)+"WHERE "
	    	+char(10)+"(WH.DISCOUNTFLAG <> 1 or WH.DISCOUNTFLAG is null)"
	    	+char(10)+"AND WH.STATUS = 1"
	    	+char(10)+"AND WH.ENTITYNO = " + CAST(@pnEntityNo AS VARCHAR)
	    	+char(10)+"AND WH.CASEID = " + CAST(@pnCaseId AS VARCHAR)

		If ( (@pnEntityNo IS NOT NULL) AND (@pnTransNo IS NOT NULL) AND (@pnWIPSeqNo IS NOT NULL) )
		Begin
			-- ** Derive the WHERE clause **
		    	Set @sSqlWhere = @sSqlWhere
			+char(10)+"AND WH.TRANSNO = " + CAST(@pnTransNo AS VARCHAR)
			+char(10)+"AND WH.WIPSEQNO = " + CAST(@pnWIPSeqNo AS VARCHAR)
			
			If ((@pnRefEntityNo IS NOT NULL) AND (@pnRefTransNo IS NOT NULL)) 
  		    	Begin
			    Set @sSqlWhere = @sSqlWhere
			    +char(10)+"AND WH.REFENTITYNO = " + cast(@pnRefEntityNo as varchar) 
			    +char(10)+"AND WH.REFTRANSNO = " + cast(@pnRefTransNo as varchar)
			End

			set @sSql = @sSqlSelect + @sSqlFrom + @sSqlWhere 
		    	+char(10)+"ORDER BY WH.POSTDATE ASC"
			
		    	-- Execute @sSql to insert into #WIPITEMS
		    	exec @nErrorCode=sp_executesql @sSql
			
		    	Set @pnRowCount = @@RowCount
			
			If (@pbDebug = 1)
			Begin
			    print '
			    -- ** insert statement - retrieve selected WIP item for display ** '
			    print @sSql
			    print '
			    -- ** matching rows found:' + cast(@pnRowCount as nvarchar) + ' ** '
			End
		End
		Else
		Begin
		    If (@pnProcessType = 500) --: Agent Debit Note
		    begin
			    Set @sSqlWhere = @sSqlWhere + char(10)+
			    "AND WH.TRANSTYPE = 514"
			    -- SQA16818 only look at consumed rows this is applicable 
			    -- regardless of the Bill In Advance and Matched items filter options
			    + char(10)+"AND WH.MOVEMENTCLASS = 2"
			    
			    If (@pbIncMatchedItems = 0)
			    Begin
				    -- Check for both Agent Debit Notes (402) and Direct Pays (406)
				    Set @sSqlWhere = @sSqlWhere + char(10)+
				    +char(10)+"AND NOT EXISTS (SELECT * "
				    +char(10)+"	FROM WORKHISTORY WH1"
				    +char(10)+"	WHERE WH1.MATCHENTITYNO = WH.ENTITYNO"
				    +char(10)+"	AND WH1.MATCHTRANSNO = WH.TRANSNO"
				    +char(10)+"	AND WH1.MATCHWIPSEQNO = WH.WIPSEQNO"
				    +char(10)+"	AND WH1.TRANSTYPE IN (402, 406)"
				    +char(10)+"	AND WH1.MATCHEDFULLY = 1)"
			    End
			    If (@pbBillInAdvance = 1)
			    Begin
				    Set @sSqlWhere = @sSqlWhere +char(10)+"AND WH.COMMANDID  = 2"
				    +char(10)+"AND WH.ITEMIMPACT = 1"
				    +char(10)+"AND WH.HISTORYLINENO = 1"
				    +char(10)+"AND WH.ENTITYNO = WH.REFENTITYNO"
				    +char(10)+"AND WH.TRANSNO = WH.REFTRANSNO"
			    End
		    end
		    else If (@pnProcessType = 501) --: Agent Credit Note
		    begin
			    Set @sSqlWhere = @sSqlWhere +char(10)+"AND WH.LOCALTRANSVALUE > 0"
			    +char(10)+"AND WH.MOVEMENTCLASS = 1"
			    +char(10)+"AND WH.COMMANDID  = 1"
			    +char(10)+"AND WH.ITEMIMPACT = 1"
			    +char(10)+"AND WH.HISTORYLINENO = 1"
    			
			    If (@pbIncMatchedItems = 0)
			    Begin
				    Set @sSqlWhere = @sSqlWhere +char(10)+"AND NOT EXISTS (SELECT *"
				    +char(10)+"	FROM WORKHISTORY WH1"
				    +char(10)+"	WHERE WH1.MATCHENTITYNO = WH.ENTITYNO"
				    +char(10)+"	AND WH1.MATCHTRANSNO = WH.TRANSNO"
				    +char(10)+"	AND WH1.MATCHWIPSEQNO = WH.WIPSEQNO"
				    +char(10)+"	AND WH1.TRANSTYPE = 402"
				    +char(10)+"	AND WH1.MATCHEDFULLY = 1)"
			    End
    			
			    If (@pbIncAuto = 1) AND (@pbIncManual = 1)
			    Begin
				    Set @sSqlWhere = @sSqlWhere 
				    +char(10)+"AND WH.TRANSTYPE in (406, 402)"
			    End
			    Else If (@pbIncAuto = 1)
			    Begin
				    Set @sSqlWhere = @sSqlWhere 
				    +char(10)+"AND WH.TRANSTYPE = 406" 
			    End
			    Else If (@pbIncManual = 1)
			    Begin
				    Set @sSqlWhere = @sSqlWhere 
				    +char(10)+"AND WH.TRANSTYPE = 402" 
			    End
    			
			    If (@pnAssociateNo IS NOT NULL)
			    Begin
				    Set @sSqlWhere = @sSqlWhere 
				    +char(10)+"AND WH.ASSOCIATENO = " 
				    + CAST(@pnAssociateNo as NVARCHAR)
			    End
    	
			    If (@psCurrency is NOT NULL) AND (@psCurrency <> '')
			    Begin
				    Set @sSqlWhere = @sSqlWhere 
				    +char(10)+"AND WH.FOREIGNCURRENCY = "+ CHAR(39) + @psCurrency + CHAR(39)
			    End
		    end
		    else if (@pnProcessType = 406) -- :Direct Pay
		    begin
			    -- When excluding previously matched items also exclude those already matched to a debit note.
			    Set @sSqlWhere = @sSqlWhere 
			    +char(10)+"AND WH.TRANSTYPE = 514"
			    +char(10)+"AND WH.MOVEMENTCLASS = 2"
			    +char(10)+"AND WH.COMMANDID  = 2"
			    +char(10)+"AND WH.ITEMIMPACT = 1"
			    +char(10)+"AND WH.HISTORYLINENO = 1"
			    +char(10)+"AND WH.ENTITYNO = WH.REFENTITYNO"
			    +char(10)+"AND WH.TRANSNO = WH.REFTRANSNO"
			    +char(10)+"AND WH.RATENO = "+ CHAR(39) + CAST(@pnRateNo AS VARCHAR) + CHAR(39)
			    +char(10)+"AND WH.WIPCODE = "+ CHAR(39) + @psWIPCode + CHAR(39)
			    +char(10)+"AND NOT EXISTS (SELECT * "
			    +char(10)+"	FROM WORKHISTORY WH1"
			    +char(10)+"	WHERE WH1.MATCHENTITYNO = WH.ENTITYNO"
			    +char(10)+"	AND WH1.MATCHTRANSNO = WH.TRANSNO"
			    +char(10)+"	AND WH1.MATCHWIPSEQNO = WH.WIPSEQNO)"
			    --+char(10)+"	AND WH1.TRANSTYPE IN (406, 402))"
			    -- 17705 commented out line above
		    end
		    else if (@pnProcessType = 516) -- :Client Credit Note
		    begin
			    Set @sSqlWhere = @sSqlWhere 
			    +char(10)+"AND WH.MOVEMENTCLASS = 2"

			    If (@pbIncMatchedItems = 0)
			    Begin
				    Set @sSqlWhere = @sSqlWhere +char(10)+"AND NOT EXISTS (SELECT *"
				    +char(10)+"	FROM WORKHISTORY WH1"
				    +char(10)+"	WHERE WH1.MATCHENTITYNO = WH.ENTITYNO"
				    +char(10)+"	AND WH1.MATCHTRANSNO = WH.TRANSNO"
				    +char(10)+"	AND WH1.MATCHWIPSEQNO = WH.WIPSEQNO"
				    +char(10)+"	AND WH1.TRANSTYPE = 516"
				    +char(10)+"	AND WH1.MATCHEDFULLY = 1)"
			    End
    			
			    If (@pbIncAuto = 1) AND (@pbIncManual = 1)
			    Begin
				    Set @sSqlWhere = @sSqlWhere 
				    +char(10)+"AND WH.TRANSTYPE in (514, 510)"
			    End
			    Else If (@pbIncAuto = 1)
			    Begin
				    Set @sSqlWhere = @sSqlWhere 
				    +char(10)+"AND WH.TRANSTYPE = 514" 
			    End
			    Else If (@pbIncManual = 1)
			    Begin
				    Set @sSqlWhere = @sSqlWhere 
				    +char(10)+"AND WH.TRANSTYPE = 510" 
			    End
    		
			    If (@psCurrency is NOT NULL) AND (@psCurrency <> '')
			    Begin
				    Set @sSqlWhere = @sSqlWhere 
				    +char(10)+"AND WH.FOREIGNCURRENCY = "+ CHAR(39) + @psCurrency + CHAR(39)
			    End
			    -- Cannot exclude matched items here as the match may be for Agent Debit Notes matched to Invoices.
			    -- the credit amount (foreign amount if a foreign currency, local otherwise) must not be greater than the invoice amount being credited. 			
		    end
    		
    	
		    If (@pbDefaulting = 1)
		    begin
			    If (@pnProcessType = 406) -- :Direct Pay
			    Begin	

				    DELETE
				    FROM #WIPITEMS
    		
				    -- default based on Case, WIP Code and other default criteria.
				    set @sSql = @sSqlSelect + @sSqlFrom + @sSqlWhere 
				    --18126
					+char(10)+"ORDER BY OI.POSTDATE DESC"
    		
				    -- Execute @sSql to insert into #WIPITEMS
				    exec @nErrorCode=sp_executesql @sSql

				    Set @pnRowCount = @@RowCount
    	
				    If (@pbDebug = 1)
				    Begin
					    print '
					    -- ** insert statement - trying to default based on Case, WIPCode specified and other default criteria for a Direct Pay ** '
					    print @sSql
					    print '
					    -- ** Processing Direct Pay, matching rows found:' + cast(@pnRowCount as nvarchar) + ' ** '
				    End
					
				    SELECT @nTopRow = WI.WIPITEMID
				    FROM #WIPITEMS WI
				    JOIN (SELECT TOP 1 * FROM #WIPITEMS) AS WI1	ON (WI1.WIPITEMID = WI.WIPITEMID)

				    -- Remove all rows apart from the most recent one.	
				    DELETE 
				    FROM #WIPITEMS
				    WHERE WIPITEMID <> @nTopRow

				    select @pnRowCount = COUNT(*)
				    FROM #WIPITEMS

				    If (@pbDebug = 1)
				    Begin
					    print '
					    -- ** Processing Direct Pay, removed all rows apart from the oldest (top) one, matching rows found:' + cast(@pnRowCount as nvarchar) + ' ** '
				    End
			    End 
			    Else
			    Begin
				    If ((@psInvoiceNo is not null) AND (@psInvoiceNo <> '')) OR
				    ((@pnRefEntityNo IS NOT NULL) AND (@pnRefTransNo IS NOT NULL))
				    Begin
    					
					    -- If single match NOT already found: Default select Invoice from previous entry, WIP Code and other default criteria.
					    set @sSql = @sSqlSelect + @sSqlFrom + @sSqlWhere
    					

					    If ((@psInvoiceNo is not null) AND (@psInvoiceNo <> ''))
					    Begin
						    If (@pnProcessType = 501) --: Agent Credit Note
						    Begin
							    Set @sSql = @sSql 
							    +char(10)+"AND WH.INVOICENUMBER LIKE "+ CHAR(39) + @psInvoiceNo + "%" + CHAR(39)
						    End
						    Else
						    Begin
							    Set @sSql = @sSql 
							    +char(10)+"AND OI.OPENITEMNO LIKE "+ CHAR(39) + @psInvoiceNo + "%" + CHAR(39)
						    End
					    End
    					
					    If ((@pnRefEntityNo IS NOT NULL) AND (@pnRefTransNo IS NOT NULL)) 
					    AND (@pnProcessType <> 501)
					    Begin
						    Set @sSql = @sSql 
						    +char(10)+"AND WH.REFENTITYNO = " + 
							    cast(@pnRefEntityNo as varchar) 
						    +char(10)+"AND WH.REFTRANSNO = " + 
							    cast(@pnRefTransNo as varchar)
					    End
    	
					    Set @sSql = @sSql 
					    +char(10)+"AND WH.WIPCODE = "+ CHAR(39) + @psWIPCode + CHAR(39)
    		
					    -- Execute @sSql to insert into #WIPITEMS
					    exec @nErrorCode=sp_executesql @sSql
    					
					    Set @pnRowCount = @@RowCount

					    If (@pbDebug = 1)
					    Begin
						    print '
						    -- ** insert statement - trying to default based on Case, InvoiceNo, WIPCode specified and other default criteria ** '
						    print @sSql
					    End
    		
					    -- NOTE: This logic should not be executed for Direct Pays.
					    If (@pbIncMatchedItems = 0)
					    Begin
    						
						    If (@pbDebug = 1)
						    Begin
							    print '
							    -- ** Current list of potential Matching Items ** '
							    SELECT * 
							    FROM #WIPITEMS
						    End
    						
						    If (@pnProcessType = 501) -- :Agent Credit Note
						    OR (@pnProcessType = 516) -- :Client Credit Note
						    Begin
							    If (@psCurrency is NOT NULL) AND (@psCurrency <> '')
							    Begin
								    DELETE 
								    FROM #WIPITEMS
								    WHERE ABS(FOREIGNVALUE) < ISNULL(@pnForeign, 0)
							    End
							    Else
							    Begin
								    DELETE 
								    FROM #WIPITEMS
								    WHERE ABS(LOCALVALUE) < ISNULL(@pnLocal, 0)
							    End
    							
							    If (@pbDebug = 1)
							    Begin
								    print '
								    -- ** Removed WIP Items that are too small anyway ** '
								    SELECT * 
								    FROM #WIPITEMS
							    End
						    End
    						
						    Set @sSql = "DELETE #WIPITEMS"
						    +char(10)+"FROM #WIPITEMS WI"
						    +char(10)+"JOIN (select ISNULL(SUM(ABS(LOCALTRANSVALUE)),0) AS TOTALLOCAL, ISNULL(SUM(ABS(FOREIGNTRANVALUE)),0) AS TOTALFOREIGN, "
						    +char(10)+"	WH.MATCHENTITYNO, WH.MATCHTRANSNO, WH.MATCHWIPSEQNO"
						    +char(10)+"	from WORKHISTORY WH"
						    +char(10)+"	JOIN #WIPITEMS WI1 	ON (WH.MATCHENTITYNO = WI1.WIPENTITYNO"
						    +char(10)+"				AND WH.MATCHTRANSNO = WI1.WIPTRANSNO"
						    +char(10)+"				AND WH.MATCHWIPSEQNO = WI1.WIPSEQNO)"
    						
						    If (@pnProcessType = 516) -- :Client Credit Note
						    Begin
							    Set @sSql = @sSql +char(10)+"	WHERE WH.TRANSTYPE = 516"
						    End
						    Else If (@pnProcessType = 501) -- :Agent Credit Note
						    Begin
							    Set @sSql = @sSql +char(10)+"	WHERE WH.TRANSTYPE = 402"
							    +char(10)+"	AND WH.LOCALTRANSVALUE < 0"
						    End
						    Else If (@pnProcessType = 500) -- :Agent Debit Note
						    Begin
							    Set @sSql = @sSql +char(10)+"	WHERE WH.TRANSTYPE IN (402, 406)"
							    +char(10)+"	AND WH.LOCALTRANSVALUE > 0"
						    End
    						
						    Set @sSql = @sSql +char(10)+  
						    "	GROUP BY WH.MATCHENTITYNO, WH.MATCHTRANSNO, WH.MATCHWIPSEQNO) AS PREVIOUSMATCHES  	ON (PREVIOUSMATCHES.MATCHENTITYNO = WI.WIPENTITYNO"
						    +char(10)+"												AND PREVIOUSMATCHES.MATCHTRANSNO = WI.WIPTRANSNO"
						    +char(10)+"												AND PREVIOUSMATCHES.MATCHWIPSEQNO = WI.WIPSEQNO) "
						    +char(10)+"WHERE" 
    						
						    If (@pnProcessType = 516) OR -- :Client Credit Note
						    (@pnProcessType = 501) -- :Agent Credit Note
						    Begin
							    If (@psCurrency is NOT NULL) AND (@psCurrency <> '')
							    Begin
								    Set @sSql = @sSql +
								    +char(10)+"ISNULL(PREVIOUSMATCHES.TOTALFOREIGN,0) >= ABS(WI.FOREIGNVALUE)"
								    +char(10)+"OR (ISNULL(PREVIOUSMATCHES.TOTALFOREIGN,0) + " + CAST(ISNULL(@pnForeign, 0) AS NVARCHAR) + ") > ABS(WI.FOREIGNVALUE)"
							    End
							    Else
							    Begin
								    Set @sSql = @sSql 
								    +char(10)+"ISNULL(PREVIOUSMATCHES.TOTALLOCAL, 0) >= ABS(WI.LOCALVALUE)"
								    +char(10)+"OR (ISNULL(PREVIOUSMATCHES.TOTALLOCAL, 0) + " + CAST(ISNULL(@pnLocal, 0) AS NVARCHAR) + ") > ABS(WI.LOCALVALUE)"
							    End
						    End
						    Else If (@pnProcessType = 500) -- :Agent Debit Note
						    Begin
							    Set @sSql = @sSql 
							    +char(10)+"ISNULL(PREVIOUSMATCHES.TOTALLOCAL, 0) >= ABS(WI.LOCALVALUE)"
						    --	+char(10)+"OR (ISNULL(PREVIOUSMATCHES.TOTALLOCAL, 0) + " + CAST(ISNULL(@pnLocal, 0) AS NVARCHAR) + ") > ABS(WI.LOCALVALUE)"					
						    End
						    -- Execute @sSql to delete previously matched items into #WIPITEMS
						    exec @nErrorCode=sp_executesql @sSql
    						
						    If (@pbDebug = 1)
						    Begin
							    print '
							    -- ** Delete statement - to remove tems that have been previously matched to the full amount  ** '
							    print @sSql
						    End
    							
					    End
    					
					    select @pnRowCount = COUNT(*)
					    FROM #WIPITEMS
    	
					    If (@pbDebug = 1)
					    Begin
						    print '
						    -- ** matching rows found:' + cast(@pnRowCount as nvarchar) + ' ** '
					    End
    					
					    If (@pnRowCount <> 1)
					    begin
						    DELETE
						    FROM #WIPITEMS
    		
						    -- If single match NOT already found: default based on Case, Client Invoice from previous entry and Action Type for that WIP Code and other default criteria.
						    set @sSql = @sSqlSelect + @sSqlFrom + @sSqlWhere
    			
						    If ((@psInvoiceNo is not null) AND (@psInvoiceNo <> ''))
						    Begin
							    If (@pnProcessType = 501) --: Agent Credit Note
							    Begin
								    Set @sSql = @sSql
								    +char(10)+"AND WH.INVOICENUMBER LIKE "+ CHAR(39) + @psInvoiceNo + "%" + CHAR(39)
							    End
							    Else
							    Begin
								    Set @sSql = @sSql
								    +char(10)+"AND OI.OPENITEMNO LIKE "+ CHAR(39) + @psInvoiceNo + "%" + CHAR(39)
							    End
						    End
    						
						    If ((@pnRefEntityNo IS NOT NULL) AND (@pnRefTransNo IS NOT NULL)) 
						    AND (@pnProcessType <> 501)
						    Begin
							    Set @sSql = @sSql
								    +char(10)+"AND WH.REFENTITYNO = " + 
								    cast(@pnRefEntityNo as varchar)
							    Set @sSql = @sSql
								    +char(10)+"AND WH.REFTRANSNO = " + 
								    cast(@pnRefTransNo as varchar)
						    End
    		
						    If ((@sWIPAttribute is not null) AND (@sWIPAttribute <> ''))
						    Begin
							    Set @sSql = @sSql
							    +char(10)+"AND WT.WIPATTRIBUTE = "+ CHAR(39) + @sWIPAttribute + CHAR(39)
						    End
    		
						    -- Execute @sSql to insert into #WIPITEMS
						    exec @nErrorCode=sp_executesql @sSql
    		
						    Set @pnRowCount = @@RowCount

						    If (@pbDebug = 1)
						    Begin
							    print '
							    -- ** insert statement - trying to default based on Case, InvoiceNo, Action Type (WIPATTRIBUTE) specified and other default criteria **'
							    print @sSql
						    End
    						
						    -- NOTE: This logic should not be executed for Direct Pays.
						    If (@pbIncMatchedItems = 0)
						    Begin
    							
							    If (@pbDebug = 1)
							    Begin
								    print '
								    -- ** Current list of potential Matching Items ** '
								    SELECT * 
								    FROM #WIPITEMS
							    End
    							
							    If (@pnProcessType = 501) -- :Agent Credit Note
							    OR (@pnProcessType = 516) -- :Client Credit Note
							    Begin
								    If (@psCurrency is NOT NULL) AND (@psCurrency <> '')
								    Begin
									    DELETE 
									    FROM #WIPITEMS
									    WHERE ABS(FOREIGNVALUE) < ISNULL(@pnForeign, 0)
								    End
								    Else
								    Begin
									    DELETE 
									    FROM #WIPITEMS
									    WHERE ABS(LOCALVALUE) < ISNULL(@pnLocal, 0)
								    End
    								
								    If (@pbDebug = 1)
								    Begin
									    print '
									    -- ** Removed WIP Items that are too small anyway ** '
									    SELECT * 
									    FROM #WIPITEMS
								    End
							    End
    							
							    Set @sSql = "DELETE #WIPITEMS"
							    +char(10)+"FROM #WIPITEMS WI"
							    +char(10)+"JOIN (select ISNULL(SUM(ABS(LOCALTRANSVALUE)),0) AS TOTALLOCAL, ISNULL(SUM(ABS(FOREIGNTRANVALUE)),0) AS TOTALFOREIGN, "
							    +char(10)+"	WH.MATCHENTITYNO, WH.MATCHTRANSNO, WH.MATCHWIPSEQNO"
							    +char(10)+"	from WORKHISTORY WH"
							    +char(10)+"	JOIN #WIPITEMS WI1 	ON (WH.MATCHENTITYNO = WI1.WIPENTITYNO"
							    +char(10)+"				AND WH.MATCHTRANSNO = WI1.WIPTRANSNO"
							    +char(10)+"				AND WH.MATCHWIPSEQNO = WI1.WIPSEQNO)"

							    If (@pnProcessType = 516) -- :Client Credit Note
							    Begin
								    Set @sSql = @sSql +char(10)+"	WHERE WH.TRANSTYPE = 516"
							    End
							    Else If (@pnProcessType = 501) -- :Agent Credit Note
							    Begin
								    Set @sSql = @sSql +char(10)+"	WHERE WH.TRANSTYPE = 402"
								    +char(10)+"	AND WH.LOCALTRANSVALUE < 0"
							    End
							    Else If (@pnProcessType = 500) -- :Agent Debit Note
							    Begin
								    Set @sSql = @sSql +char(10)+"	WHERE WH.TRANSTYPE IN (402, 406)"
								    +char(10)+"	AND WH.LOCALTRANSVALUE > 0"
							    End
    							
							    Set @sSql = @sSql +char(10)+  
							    "	GROUP BY WH.MATCHENTITYNO, WH.MATCHTRANSNO, WH.MATCHWIPSEQNO) AS PREVIOUSMATCHES  	ON (PREVIOUSMATCHES.MATCHENTITYNO = WI.WIPENTITYNO"
							    +char(10)+"													AND PREVIOUSMATCHES.MATCHTRANSNO = WI.WIPTRANSNO"
							    +char(10)+"													AND PREVIOUSMATCHES.MATCHWIPSEQNO = WI.WIPSEQNO) "
							    +char(10)+"WHERE" 
    							
							    If (@pnProcessType = 516) OR -- :Client Credit Note
							    (@pnProcessType = 501) -- :Agent Credit Note
							    Begin
								    If (@psCurrency is NOT NULL) AND (@psCurrency <> '')
								    Begin
									    Set @sSql = @sSql
									    +char(10)+"ISNULL(PREVIOUSMATCHES.TOTALFOREIGN,0) >= ABS(WI.FOREIGNVALUE)"
									    +char(10)+"OR (ISNULL(PREVIOUSMATCHES.TOTALFOREIGN,0) + " + CAST(ISNULL(@pnForeign, 0) AS NVARCHAR) + ") > ABS(WI.FOREIGNVALUE)"
								    End
								    Else
								    Begin
									    Set @sSql = @sSql
									    +char(10)+"ISNULL(PREVIOUSMATCHES.TOTALLOCAL, 0) >= ABS(WI.LOCALVALUE)"
									    +char(10)+"OR (ISNULL(PREVIOUSMATCHES.TOTALLOCAL, 0) + " + CAST(ISNULL(@pnLocal, 0) AS NVARCHAR) + ") > ABS(WI.LOCALVALUE)"
								    End
							    End
							    Else If (@pnProcessType = 500) -- :Agent Debit Note
							    Begin
								    Set @sSql = @sSql
								    +char(10)+"ISNULL(PREVIOUSMATCHES.TOTALLOCAL, 0) >= ABS(WI.LOCALVALUE)"
							    --	+char(10)+"OR (ISNULL(PREVIOUSMATCHES.TOTALLOCAL, 0) + " + CAST(ISNULL(@pnLocal, 0) AS NVARCHAR) + ") > ABS(WI.LOCALVALUE)"					
							    End
							    -- Execute @sSql to delete previously matched items into #WIPITEMS
							    exec @nErrorCode=sp_executesql @sSql
    							
							    If (@pbDebug = 1)
							    Begin
								    print '
								    -- ** Delete statement - to remove tems that have been previously matched to the full amount  ** '
								    print @sSql
							    End
    								
						    End
    	
						    select @pnRowCount = COUNT(*)
						    FROM #WIPITEMS
    	
						    If (@pbDebug = 1)
						    Begin
							    print '
							    -- ** matching rows found:' + cast(@pnRowCount as nvarchar) + ' ** '
						    End
					    End
				    End
    					
				    If (@pnRowCount <> 1)
				    begin	
					    DELETE
					    FROM #WIPITEMS
    		
					    -- If single match NOT already found: default based on Case, WIP Code and other default criteria.
					    set @sSql = @sSqlSelect + @sSqlFrom + @sSqlWhere
    		
					    Set @sSql = @sSql 
					    +char(10)+"AND WH.WIPCODE = "+ CHAR(39) + @psWIPCode + CHAR(39)
    		
					    -- Execute @sSql to insert into #WIPITEMS
					    exec @nErrorCode=sp_executesql @sSql
    					
					    Set @pnRowCount = @@RowCount
    					
					    If (@pbDebug = 1)
					    Begin
						    print '
						    -- ** insert statement - trying to default based on Case, WIPCode specified and other default criteria ** '
						    print @sSql
					    End
    		
					    -- NOTE: This logic should not be executed for Direct Pays.
					    If (@pbIncMatchedItems = 0)
					    Begin
    						
						    If (@pbDebug = 1)
						    Begin
							    print '
							    -- ** Current list of potential Matching Items ** '
							    SELECT * 
							    FROM #WIPITEMS
						    End
    						
						    If (@pnProcessType = 501) -- :Agent Credit Note
						    OR (@pnProcessType = 516) -- :Client Credit Note
						    Begin
							    If (@psCurrency is NOT NULL) AND (@psCurrency <> '')
							    Begin
								    DELETE 
								    FROM #WIPITEMS
								    WHERE ABS(FOREIGNVALUE) < ISNULL(@pnForeign, 0)
							    End
							    Else
							    Begin
								    DELETE 
								    FROM #WIPITEMS
								    WHERE ABS(LOCALVALUE) < ISNULL(@pnLocal, 0)
							    End
    							
							    If (@pbDebug = 1)
							    Begin
								    print '
								    -- ** Removed WIP Items that are too small anyway ** '
								    SELECT * 
								    FROM #WIPITEMS
							    End
						    End
    						
						    Set @sSql = "DELETE #WIPITEMS"
						    +char(10)+"FROM #WIPITEMS WI"
						    +char(10)+"JOIN (select ISNULL(SUM(ABS(LOCALTRANSVALUE)),0) AS TOTALLOCAL, ISNULL(SUM(ABS(FOREIGNTRANVALUE)),0) AS TOTALFOREIGN, "
						    +char(10)+"	WH.MATCHENTITYNO, WH.MATCHTRANSNO, WH.MATCHWIPSEQNO"
						    +char(10)+"	from WORKHISTORY WH"
						    +char(10)+"	JOIN #WIPITEMS WI1 	ON (WH.MATCHENTITYNO = WI1.WIPENTITYNO"
						    +char(10)+"				AND WH.MATCHTRANSNO = WI1.WIPTRANSNO"
						    +char(10)+"				AND WH.MATCHWIPSEQNO = WI1.WIPSEQNO)"
    						
						    If (@pnProcessType = 516) -- :Client Credit Note
						    Begin
							    Set @sSql = @sSql +char(10)+"	WHERE WH.TRANSTYPE = 516"
						    End
						    Else If (@pnProcessType = 501) -- :Agent Credit Note
						    Begin
							    Set @sSql = @sSql +char(10)+"	WHERE WH.TRANSTYPE = 402"
							    +char(10)+"	AND WH.LOCALTRANSVALUE < 0"
						    End
						    Else If (@pnProcessType = 500) -- :Agent Debit Note
						    Begin
							    Set @sSql = @sSql +char(10)+"	WHERE WH.TRANSTYPE IN (402, 406)"
							    +char(10)+"	AND WH.LOCALTRANSVALUE > 0"
						    End
    						
						    Set @sSql = @sSql +char(10)+  
						    "	GROUP BY WH.MATCHENTITYNO, WH.MATCHTRANSNO, WH.MATCHWIPSEQNO) AS PREVIOUSMATCHES  	ON (PREVIOUSMATCHES.MATCHENTITYNO = WI.WIPENTITYNO"
						    +char(10)+"												AND PREVIOUSMATCHES.MATCHTRANSNO = WI.WIPTRANSNO"
						    +char(10)+"												AND PREVIOUSMATCHES.MATCHWIPSEQNO = WI.WIPSEQNO)"
						    +char(10)+"WHERE" 
    						
						    If (@pnProcessType = 516) OR -- :Client Credit Note
						    (@pnProcessType = 501) -- :Agent Credit Note
						    Begin
							    If (@psCurrency is NOT NULL) AND (@psCurrency <> '')
							    Begin
								    Set @sSql = @sSql
								    +char(10)+"ISNULL(PREVIOUSMATCHES.TOTALFOREIGN,0) >= ABS(WI.FOREIGNVALUE)"
								    +char(10)+"OR (ISNULL(PREVIOUSMATCHES.TOTALFOREIGN,0) + " + CAST(ISNULL(@pnForeign, 0) AS NVARCHAR) + ") > ABS(WI.FOREIGNVALUE)"
							    End
							    Else
							    Begin
								    Set @sSql = @sSql 
								    +char(10)+"ISNULL(PREVIOUSMATCHES.TOTALLOCAL, 0) >= ABS(WI.LOCALVALUE)"
								    +char(10)+"OR (ISNULL(PREVIOUSMATCHES.TOTALLOCAL, 0) + " + CAST(ISNULL(@pnLocal, 0) AS NVARCHAR) + ") > ABS(WI.LOCALVALUE)"
							    End
						    End
						    Else If (@pnProcessType = 500) -- :Agent Debit Note
						    Begin
							    Set @sSql = @sSql 
							    +char(10)+"ISNULL(PREVIOUSMATCHES.TOTALLOCAL, 0) >= ABS(WI.LOCALVALUE)"
						    --	+char(10)+"OR (ISNULL(PREVIOUSMATCHES.TOTALLOCAL, 0) + " + CAST(ISNULL(@pnLocal, 0) AS NVARCHAR) + ") > ABS(WI.LOCALVALUE)"					
						    End
						    -- Execute @sSql to delete previously matched items into #WIPITEMS
						    exec @nErrorCode=sp_executesql @sSql
    						
						    If (@pbDebug = 1)
						    Begin
							    print '
							    -- ** Delete statement - to remove tems that have been previously matched to the full amount  ** '
							    print @sSql
						    End
    							
					    End
    		
					    select @pnRowCount = COUNT(*)
					    FROM #WIPITEMS
    	
					    If (@pbDebug = 1)
					    Begin
						    print '
						    -- ** matching rows found:' + cast(@pnRowCount as nvarchar) + ' ** '
					    End
				    End
    			
				    If (@pnRowCount <> 1)
				    begin
					    DELETE
					    FROM #WIPITEMS
    		
					    -- If single match NOT already found: default based on Case and Action Type for that WIP Code and other default criteria.
					    set @sSql = @sSqlSelect + @sSqlFrom + @sSqlWhere
    		
					    If ((@sWIPAttribute is not null) AND (@sWIPAttribute <> ''))
					    Begin
						    Set @sSql = @sSql
						    +char(10)+"AND WT.WIPATTRIBUTE = "+ CHAR(39) + @sWIPAttribute + CHAR(39)
					    End
    					
					    -- Execute @sSql to insert into #WIPITEMS
					    exec @nErrorCode=sp_executesql @sSql
    					
					    Set @pnRowCount = @@RowCount
    					
					    If (@pbDebug = 1)
					    Begin
						    print '
						    -- ** insert statement - trying to default based on Case, Action Type (WIPATTRIBUTE) specified and other default criteria ** '
						    print @sSql
					    End
    				
					    -- NOTE: This logic should not be executed for Direct Pays.
					    If (@pbIncMatchedItems = 0)
					    Begin
    						
						    If (@pbDebug = 1)
						    Begin
							    print '
							    -- ** Current list of potential Matching Items ** '
							    SELECT * 
							    FROM #WIPITEMS
						    End
    						
						    If (@pnProcessType = 501) -- :Agent Credit Note
						    OR (@pnProcessType = 516) -- :Client Credit Note
						    Begin
							    If (@psCurrency is NOT NULL) AND (@psCurrency <> '')
							    Begin
								    DELETE 
								    FROM #WIPITEMS
								    WHERE ABS(FOREIGNVALUE) < ISNULL(@pnForeign, 0)
							    End
							    Else
							    Begin
								    DELETE 
								    FROM #WIPITEMS
								    WHERE ABS(LOCALVALUE) < ISNULL(@pnLocal, 0)
							    End
    							
							    If (@pbDebug = 1)
							    Begin
								    print '
								    -- ** Removed WIP Items that are too small anyway ** '
								    SELECT * 
								    FROM #WIPITEMS
							    End
						    End
    						
						    Set @sSql = "DELETE #WIPITEMS"
						    +char(10)+"FROM #WIPITEMS WI"
						    +char(10)+"JOIN (select ISNULL(SUM(ABS(LOCALTRANSVALUE)),0) AS TOTALLOCAL, ISNULL(SUM(ABS(FOREIGNTRANVALUE)),0) AS TOTALFOREIGN, "
						    +char(10)+"	WH.MATCHENTITYNO, WH.MATCHTRANSNO, WH.MATCHWIPSEQNO"
						    +char(10)+"	from WORKHISTORY WH"
						    +char(10)+"	JOIN #WIPITEMS WI1 	ON (WH.MATCHENTITYNO = WI1.WIPENTITYNO"
						    +char(10)+"			AND WH.MATCHTRANSNO = WI1.WIPTRANSNO"
						    +char(10)+"			AND WH.MATCHWIPSEQNO = WI1.WIPSEQNO)"
    						
						    If (@pnProcessType = 516) -- :Client Credit Note
						    Begin
							    Set @sSql = @sSql +char(10)+"	WHERE WH.TRANSTYPE = 516"
						    End
						    Else If (@pnProcessType = 501) -- :Agent Credit Note
						    Begin
							    Set @sSql = @sSql +char(10)+"	WHERE WH.TRANSTYPE = 402"
							    +char(10)+"	AND WH.LOCALTRANSVALUE < 0"
						    End
						    Else If (@pnProcessType = 500) -- :Agent Debit Note
						    Begin
							    Set @sSql = @sSql +char(10)+"	WHERE WH.TRANSTYPE IN (402, 406)"
							    +char(10)+"	AND WH.LOCALTRANSVALUE > 0"
						    End						

    					
						    Set @sSql = @sSql +char(10)+  
						    "	GROUP BY WH.MATCHENTITYNO, WH.MATCHTRANSNO, WH.MATCHWIPSEQNO) AS PREVIOUSMATCHES  	ON (PREVIOUSMATCHES.MATCHENTITYNO = WI.WIPENTITYNO"
						    +char(10)+"												AND PREVIOUSMATCHES.MATCHTRANSNO = WI.WIPTRANSNO"
						    +char(10)+"												AND PREVIOUSMATCHES.MATCHWIPSEQNO = WI.WIPSEQNO)"
						    +char(10)+"WHERE" 
    						
						    If (@pnProcessType = 516) OR -- :Client Credit Note
						    (@pnProcessType = 501) -- :Agent Credit Note
						    Begin
							    If (@psCurrency is NOT NULL) AND (@psCurrency <> '')
							    Begin
								    Set @sSql = @sSql
								    +char(10)+"ISNULL(PREVIOUSMATCHES.TOTALFOREIGN,0) >= ABS(WI.FOREIGNVALUE)"
								    +char(10)+"OR (ISNULL(PREVIOUSMATCHES.TOTALFOREIGN,0) + " + CAST(ISNULL(@pnForeign, 0) AS NVARCHAR) + ") > ABS(WI.FOREIGNVALUE)"
							    End
							    Else
							    Begin
								    Set @sSql = @sSql 
								    +char(10)+"ISNULL(PREVIOUSMATCHES.TOTALLOCAL, 0) >= ABS(WI.LOCALVALUE)"
								    +char(10)+"OR (ISNULL(PREVIOUSMATCHES.TOTALLOCAL, 0) + " + CAST(ISNULL(@pnLocal, 0) AS NVARCHAR) + ") > ABS(WI.LOCALVALUE)"
							    End
						    End
						    Else If (@pnProcessType = 500) -- :Agent Debit Note
						    Begin
							    Set @sSql = @sSql
							    +char(10)+"ISNULL(PREVIOUSMATCHES.TOTALLOCAL, 0) >= ABS(WI.LOCALVALUE)"
						    --	+char(10)+"OR (ISNULL(PREVIOUSMATCHES.TOTALLOCAL, 0) + " + CAST(ISNULL(@pnLocal, 0) AS NVARCHAR) + ") > ABS(WI.LOCALVALUE)"					
						    End
						    -- Execute @sSql to delete previously matched items into #WIPITEMS
						    exec @nErrorCode=sp_executesql @sSql
    						
						    If (@pbDebug = 1)
						    Begin
							    print '
							    -- ** Delete statement - to remove tems that have been previously matched to the full amount  ** '
							    print @sSql
						    End
    							
					    End
    		
					    select @pnRowCount = COUNT(*)
					    FROM #WIPITEMS
    					
					    If (@pbDebug = 1)
					    Begin
						    print '
						    -- ** matching rows found:' + cast(@pnRowCount as nvarchar) + ' ** '
					    End
				    End
    		
				    If (@pnRowCount > 1)
				    begin
					    -- If single match NOT already found: Do not default.
					    DELETE
					    FROM #WIPITEMS
				    End
			    End
		    end
		    Else If (@pbDefaulting = 0) AND (@pnProcessType <> 406) --: Direct Pays
		    -- Not defaulting, populating Pick List window
		    Begin
			    -- previously selected/entered invoice
			    If (@psInvoiceNo IS NOT NULL) AND (@psInvoiceNo <> '') 
			    Begin
				    If (@pnProcessType = 501) --: Agent Credit Note
				    Begin
					    Set @sSqlWhere = @sSqlWhere 
					    +char(10)+"AND WH.INVOICENUMBER LIKE "+ CHAR(39) + @psInvoiceNo + "%" + CHAR(39)
				    End
				    Else
				    Begin
					    Set @sSqlWhere = @sSqlWhere
					    +char(10)+"AND OI.OPENITEMNO LIKE "+ CHAR(39) + @psInvoiceNo + "%" + CHAR(39)
				    End
			    End
    	
			    -- Enforce WIP Attribute setting of selected WIP Code
			    If (@bEnforceWIPAttrFlag = 1) AND 
			    ((@sWIPAttribute is not null) AND (@sWIPAttribute <> ''))
			    Begin
				    Set @sSqlWhere = @sSqlWhere
				    +char(10)+"AND WT.WIPATTRIBUTE = "+ CHAR(39) + @sWIPAttribute + CHAR(39)
			    End

			    -- WIP Type on the filter window
			    If (@psWIPTypeId IS NOT NULL) AND (@psWIPTypeId <> '')
			    Begin
				    Set @sSqlWhere = @sSqlWhere
				    +char(10)+"AND WT.WIPTYPEID = " + CHAR(39) + @psWIPTypeId + CHAR(39)	
			    End
    	
			    -- WIP Category on the filter window
			    If (@psWIPCategoryList is NOT NULL) AND (@psWIPCategoryList <> '')
			    Begin
				    set @sSqlFrom = @sSqlFrom
				    +char(10)+"JOIN WIPTYPE WTY	ON (WTY.WIPTYPEID = WT.WIPTYPEID)"
    	
				    Set @sSqlWhere = @sSqlWhere
				    +char(10)+"AND WTY.CATEGORYCODE IN (" + @psWIPCategoryList + " ) " 
    	
			    End
    		
			    -- WIP Code filtering via the table on the filter window
			    If (@nWIPCodeRowCount > 0) 
			    Begin
				    set @sSqlFrom = @sSqlFrom
				    +char(10)+"JOIN #WIPCODES WC ON (WC.WIPCODE = WH.WIPCODE)"
			    End
    	
			    -- From Date on the filter window
			    If (@pdtFromDate IS NOT NULL)
			    Begin
				    Set @sSqlWhere = @sSqlWhere
				    +char(10)+"AND CAST(CONVERT(NVARCHAR,WH.TRANSDATE,112) as DATETIME) >= " + CHAR(39) + convert(nvarchar,@pdtFromDate,112) + CHAR(39)
    			
			    End
    			
			    -- To Date on the filter window
			    If (@pdtToDate IS NOT NULL)
			    Begin
				    Set @sSqlWhere = @sSqlWhere
				    +char(10)+"AND CAST(CONVERT(NVARCHAR,WH.TRANSDATE,112) as DATETIME) <= " + CHAR(39) + convert(nvarchar,@pdtToDate,112)+ CHAR(39)
			    End
    	
			    set @sSql = @sSqlSelect + @sSqlFrom + @sSqlWhere
    	
			    -- Execute @sSql to insert into #WIPITEMS
			    exec @nErrorCode=sp_executesql @sSql
    			
			    Set @pnRowCount = @@RowCount
    			
			    If (@pbDebug = 1)
			    Begin
				    print '
				    -- ** Insert statement - to populate pick list window ** '
				    print @sSql
			    End
    			
			    -- NOTE: This logic should not be executed for Direct Pays.
			    If (@pbIncMatchedItems = 0)
			    Begin
    				
				    If (@pbDebug = 1)
				    Begin
					    print '
					    -- ** Current list of potential Matching Items ** '
					    SELECT * 
					    FROM #WIPITEMS
				    End
    				
				    If (@pnProcessType = 501) -- :Agent Credit Note
				    OR (@pnProcessType = 516) -- :Client Credit Note
				    Begin
					    If (@psCurrency is NOT NULL) AND (@psCurrency <> '')
					    Begin
						    DELETE 
						    FROM #WIPITEMS
						    WHERE ABS(FOREIGNVALUE) < ISNULL(@pnForeign, 0)
					    End
					    Else
					    Begin
						    DELETE 
						    FROM #WIPITEMS
						    WHERE ABS(LOCALVALUE) < ISNULL(@pnLocal, 0)
					    End
    					
					    If (@pbDebug = 1)
					    Begin
						    print '
						    -- ** Removed WIP Items that are too small anyway ** '
						    SELECT * 
						    FROM #WIPITEMS
					    End
				    End
    				
				    Set @sSql = "DELETE #WIPITEMS"
				    +char(10)+"FROM #WIPITEMS WI"
				    +char(10)+"JOIN (select ISNULL(SUM(ABS(LOCALTRANSVALUE)),0) AS TOTALLOCAL, ISNULL(SUM(ABS(FOREIGNTRANVALUE)),0) AS TOTALFOREIGN, WH.MATCHENTITYNO, WH.MATCHTRANSNO, WH.MATCHWIPSEQNO"
				    +char(10)+"	from WORKHISTORY WH"
				    +char(10)+"	JOIN #WIPITEMS WI1 	ON (WH.MATCHENTITYNO = WI1.WIPENTITYNO"
				    +char(10)+"				AND WH.MATCHTRANSNO = WI1.WIPTRANSNO"
				    +char(10)+"				AND WH.MATCHWIPSEQNO = WI1.WIPSEQNO)"

				    If (@pnProcessType = 516) -- :Client Credit Note
				    Begin
					    Set @sSql = @sSql +char(10)+"	WHERE WH.TRANSTYPE = 516"
				    End
				    Else If (@pnProcessType = 501) -- :Agent Credit Note
				    Begin
					    Set @sSql = @sSql +char(10)+"	WHERE WH.TRANSTYPE = 402"
					    +char(10)+"	AND WH.LOCALTRANSVALUE < 0"
				    End
				    Else If (@pnProcessType = 500) -- :Agent Debit Note
				    Begin
					    Set @sSql = @sSql +char(10)+"	WHERE WH.TRANSTYPE IN (402, 406)"
					    +char(10)+"	AND WH.LOCALTRANSVALUE > 0"
				    End
    				
				    Set @sSql = @sSql +char(10)+ 
				    "	GROUP BY WH.MATCHENTITYNO, WH.MATCHTRANSNO, WH.MATCHWIPSEQNO) AS PREVIOUSMATCHES  	ON (PREVIOUSMATCHES.MATCHENTITYNO = WI.WIPENTITYNO"
				    +char(10)+"												AND PREVIOUSMATCHES.MATCHTRANSNO = WI.WIPTRANSNO"
				    +char(10)+"												AND PREVIOUSMATCHES.MATCHWIPSEQNO = WI.WIPSEQNO)"
				    +char(10)+"WHERE" 
    				
				    If (@pnProcessType = 516) OR -- :Client Credit Note
				    (@pnProcessType = 501) -- :Agent Credit Note
				    Begin
					    If (@psCurrency is NOT NULL) AND (@psCurrency <> '')
					    Begin
						    Set @sSql = @sSql
						    +char(10)+"ISNULL(PREVIOUSMATCHES.TOTALFOREIGN,0) >= ABS(WI.FOREIGNVALUE)"
						    +char(10)+"OR (ISNULL(PREVIOUSMATCHES.TOTALFOREIGN,0) + " + CAST(ISNULL(@pnForeign, 0) AS NVARCHAR) + ") > ABS(WI.FOREIGNVALUE)"
					    End
					    Else
					    Begin
						    Set @sSql = @sSql
						    +char(10)+"ISNULL(PREVIOUSMATCHES.TOTALLOCAL, 0) >= ABS(WI.LOCALVALUE)"
						    +char(10)+"OR (ISNULL(PREVIOUSMATCHES.TOTALLOCAL, 0) + " + CAST(ISNULL(@pnLocal, 0) AS NVARCHAR) + ") > ABS(WI.LOCALVALUE)"
					    End
				    End
				    Else If (@pnProcessType = 500) -- :Agent Debit Note
				    Begin
					    Set @sSql = @sSql
					    +char(10)+"ISNULL(PREVIOUSMATCHES.TOTALLOCAL, 0) >= ABS(WI.LOCALVALUE)"
				    --	+char(10)+"OR (ISNULL(PREVIOUSMATCHES.TOTALLOCAL, 0) + " + CAST(ISNULL(@pnLocal, 0) AS NVARCHAR) + ") > ABS(WI.LOCALVALUE)"					
				    End
				    -- Execute @sSql to delete previously matched items into #WIPITEMS
				    exec @nErrorCode=sp_executesql @sSql
    				
				    If (@pbDebug = 1)
				    Begin
					    print '
					    -- ** Delete statement - to remove tems that have been previously matched to the full amount  ** '
					    print @sSql
				    End
    					
			    End
		    End
		
	    End	    
	End
	
	-- Everything else went OK return the result set in WIP Items
	If @nErrorCode = 0
	Begin
	
		-- When appropriate return the result set.
--		If (@pbDefaulting = 1 AND @pnRowCount = 1) OR (@pbDefaulting = 0)
--		Begin
		SELECT WIPENTITYNO, WIPTRANSNO, WIPSEQNO, OIENTITYNO, OITRANSNO, 
		INVOICENO, TRANSDATE, NAMENO, FORMATTEDNAME, CASEID, IRN, 
		WIPCODE, LOCALVALUE, LOCALCOST, FOREIGNCURRENCY, FOREIGNVALUE, 
		FOREIGNCOST, STATUS, STATUSDESC, BILLINADVANCE 
		FROM #WIPITEMS
		ORDER BY TRANSDATE ASC
--		End
	End

	Set @pnRowCount = @@Rowcount

	DROP TABLE #WIPITEMS
	DROP TABLE #WIPCODES

End

Return @nErrorCode
GO

Grant execute on dbo.wp_WIPItemMatching to public
GO
