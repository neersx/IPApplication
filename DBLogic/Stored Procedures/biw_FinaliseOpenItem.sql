-----------------------------------------------------------------------------------------------------------------------------
-- Creation of biw_FinaliseOpenItem									      
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[biw_FinaliseOpenItem]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.biw_FinaliseOpenItem.'
	Drop procedure [dbo].[biw_FinaliseOpenItem]
End
Print '**** Creating Stored Procedure dbo.biw_FinaliseOpenItem...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.biw_FinaliseOpenItem
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pbCalledFromCentura	bit		= 0,
	@pnItemEntityNo	int,
	@pnItemTransNo	int,
	@ptXMLEnteredOpenItems	ntext           = null,		
	@pdtItemDate	dateTime = null
)
as
-- PROCEDURE:	biw_FinaliseOpenItem
-- VERSION:	50
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Finalise the Open Item.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	-----------------------------------------------
-- 05 Feb 2010	AT	RFC3605	1	Procedure created.
-- 27 Apr 2010	AT	RFC8292	2	Cater for bill in advance WIP.
-- 07 May 2010	AT	RFC9092	3	Fix allocation of OpenItem.
-- 13 May 2010	AT	RFC9092	4	Execute GL processing.
-- 19 May 2010	AT	RFC9092	5	Adjusted conditions to identify draft Bill in Advance WIP
-- 23 Jun 2010	AT	RFC8291	6	Modified to cater for Credit Notes.
-- 21 Jul 2010	AT	RFC8305	7	Set Debit Note No into Activity Request for regular bills.
-- 16 Aug 2010	KR	RFC9080	8	modified the raise error code to non duplicate ones.
-- 06 Sep 2010	AT	RFC9740 9	Fixed writing of Work History rows when adjusting WIP.
-- 13 Oct 2010	KR	RFC100387	10	Added debtor numbers to the return select
-- 28 Dec 2010  MS      RFC8297 		11      Added OfficeRangeTo and OfficeDescription in the output result
-- 25 JAN 2011	AT	RFC8983	12	Removed debug stubs left behind.
-- 11 Feb 2011	AT	RFC10207  	13	Update written off WIP balances to 0 instead of null.
-- 18 Feb 2011  MS      RFC8297		14      Modified Office Item To and From variables length to Decimal from Int
-- 31 Mar 2011  DV      RFC9285 		15      Added extra parameter @ptXMLEnteredOpenItems and do not generate the OpenItemNo if
--                                      		         @ptXMLEnteredOpenItems is not nul
-- 25 Apr 2011  MS      RFC100492	16      Added @nErrorCode checks to remove execution of code when ErorrCode is not 0  
-- 05 May 2011	AT	RFC10581	17	Propogate ItemDate to transaction header and history lines.
-- 24 May 2011	AT	RFC10696	18	Fixed WIP balance update when finalising credit notes.
-- 15 Jul 2011	DL	SQA19791 	19	Extend variable referencing CONTROLTOTAL.TOTAL to dec(13,2) instead of dec(11,2)
-- 03 Aug 2011	AT	RFC11053	20	Fixed Control Total update for Credit Notes.
-- 20 Aug 2011  DV     	 RFC11069 	21      Insert IDENTITYID value in ACTIVITYREQUEST table
-- 07 Oct 2011	AT	RFC11392	22	Fixed Control Total update for Work History.
-- 07 Oct 2011  MS      RFC100573        23      Allow Name entry point for letter to have EntryPointType as null.
-- 28 Oct 2011	AT	RFC10168	24	Add support for Inter-Entity Billing.
-- 30 Nov 2011	AT	RFC11649	25	Fixed validation of duplicate open item no to include Entity no.
-- 12 Dec 2011	AT	RFC11681	26	Write Tax history against Debtor History with ItemImpact = 1.
-- 18 Apr 2011	AT	RFC12165	27	Update bill due date on finalise.
-- 02 May 2012	AT	RFC12250	28	Add more error code checks.
-- 14 May 2012	AT	RFC12149	29	Fixed derivation of source country to get country from staff office.
-- 24 May 2012	AT	RFC12270	30	Get period using acw_ValidateTransactionDate.
-- 03 Aug 2012	AT	RFC12581	31	Get default case from WORKINPROGRESS.
-- 07 Nov 2012  AK	RFC12544 	32 	Prevent finalize if bill date is future date
-- 12 Nov 2012  AK	RFC12544 	33 	Applied check for @pdtItemDate.
-- 12 Dec 2012	DV	RFC12765	34	Do not compare to accounts if the client uses external accounting systems.
-- 03 Jan 2013	CR	RFC13071	35 	Move the call to biw_ProcessInterEntityTransfers below the posting of TRANSACTIONHEADER
-- 08 Jan 2013   AK	RFC12544 	36 	Applied Error check.
-- 09 JAN 2013	DV	RFC12765	37 	Do not compare to accounts if the client uses external accounting systems (Fixed merge issue).
-- 12 Jun 2013	vql	RFC13563	38 	Out-of-range value error when finalising bill in french database.
-- 01 Apr 2015	vql	R45860		39	Create WIP Payments.
-- 08 Apr 2015	vql	R45860		40	Handle credit allocations.
-- 03 Jun 2015	DL	R46271		41	If Cash Accounting but allocate by preferences site control is blank then don't record wip payment in wippayment table.
-- 10 Jun 2015	KR	R44648		42	Added logic to prevent finalising a bill if the credit applied is locked by another user
-- 02 Sep 2016	DL	R64172		43	Enhance performance - Get the initial balance of all wip involved in the transaction rather than individually.
-- 04 Jan 2017  MS	R47798		44	Added FeeList logic for draft wip fees and charges items
-- 06 Jul 2017  AK      R71705		45	Added additional check on ACCTDEBTORNO 
-- 07 Feb 2018  MS      R73082          46      Added logic to use next available OPENITEMNO rather than throwing error
-- 20 Feb 2018  MS      R72834          47      Move ActivityRequest logic into separate sp and moved reconcile logic at end
-- 28 May 2018  MS      R74149          48      Change alert id for open item no not found
-- 30 May 2018  AK	    R74222			49	Added logic to catch errorcode from wp_AddDraftWipToFeeList
-- 10 Oct 2018  AK	R74005      50 passed @pnItemEntityNo parameter in fn_GetEffectiveTaxRate	

SET CONCAT_NULL_YIELDS_NULL OFF
-- Row counts required by the data adapter
SET NOCOUNT OFF

Declare @bDebug		bit

Declare @nErrorCode	int
Declare @sSQLString 	nvarchar(4000)
Declare @sReasonCode	nvarchar(2)
Declare @nPostPeriod	int
Declare @dtPostDate	datetime
Declare @dtMaxDate	datetime
Declare @nTransType	int
Declare @nMovementType	int
--Declare @dtPeriodEndDate datetime
--Declare @nClosedFor		int
Declare @nControlTotal	decimal(13,2)
Declare @nItemType      int

Declare @nMainCaseId	int

Declare @nGLJournalCreation int
Declare @nResult int

Declare @sAlertXML nvarchar(2000)

Declare @sReconciliationErrors table 
(
   ReconciliationErrorXml nvarchar(4000)
)

Set @bDebug = 0

set @dtPostDate = getdate()
set @dtMaxDate = '9999-12-31T00:00:00' -- use ISO8601 date format

-- Initialise variables
Set @nErrorCode = 0

-- Update Open Item
-- Delete Billed Items
-- Post Work History
-- Update /Delete WIP
-- Post Debtor History / Tax History and update Account
-- Delete Billed Credits
-- Delete Open Item Breakdown
-- Update Transaction Stauts
-- Process inter-entity transfers

-- Return the OPEN ITEM Numbers

-- Run GL
-- Reconcile Ledgers
-- Create Activity request
-- Raise Event

IF NOT EXISTS (select * from OPENITEM WHERE ITEMENTITYNO = @pnItemEntityNo AND ITEMTRANSNO = @pnItemTransNo and STATUS = 0)
Begin
	-- Draft OpenItem not found
	Set @sAlertXML = dbo.fn_GetAlertXML('AC127', 'Draft Open Item could not be found. Item has been modified or is already finalised.',
										null, null, null, null, null)
	RAISERROR(@sAlertXML, 14, 1)
	Set @nErrorCode = @@ERROR
End

Declare @nStaffKey int
Declare @sSourceCountry nvarchar(3)
	
If @nErrorCode = 0
Begin
	Set @sSQLString = "Select @nMainCaseId = ISNULL(O.MAINCASEID, DERIVEDMAINCASE.CASEID)
			FROM
			OPENITEM O,
			(Select top 1 CASEID
				From BILLEDITEM BI
				JOIN WORKINPROGRESS WIP on WIP.ENTITYNO = BI.WIPENTITYNO
										and WIP.TRANSNO = BI.WIPTRANSNO
										and WIP.WIPSEQNO = BI.WIPSEQNO
				Where ITEMENTITYNO = @pnItemEntityNo
				and ITEMTRANSNO = @pnItemTransNo
				and CASEID IS NOT NULL
				order by CASEID) as DERIVEDMAINCASE
			WHERE O.ITEMENTITYNO = @pnItemEntityNo
			and		O.ITEMTRANSNO = @pnItemTransNo"

	exec @nErrorCode=sp_executesql @sSQLString, 
				N'@pnItemEntityNo	int,
				  @pnItemTransNo	int,
				  @nMainCaseId		int OUTPUT',
				  @pnItemEntityNo = @pnItemEntityNo,
				  @pnItemTransNo = @pnItemTransNo,
				  @nMainCaseId = @nMainCaseId OUTPUT

	If (@bDebug = 1)
	Begin
		Print 'The Main Case Id is: ' + cast(@nMainCaseId as nvarchar(12))
	End
End


-- RFC10241 Prevent finalise if date changed will affect tax rates.
IF @nErrorCode = 0 and @pdtItemDate is not null and
EXISTS (SELECT * FROM OPENITEM 
	WHERE ITEMENTITYNO = @pnItemEntityNo AND ITEMTRANSNO = @pnItemTransNo and STATUS = 0
	AND dbo.fn_DateOnly(@pdtItemDate) != dbo.fn_DateOnly(ITEMDATE))
Begin
	
	Select @nStaffKey = EMPLOYEENO
	from OPENITEM 
	where ITEMENTITYNO = @pnItemEntityNo 
	and ITEMTRANSNO = @pnItemTransNo
	
	If (@nErrorCode = 0)
	Begin
		Select @sSourceCountry = dbo.fn_GetSourceCountry(@nStaffKey, @nMainCaseId)
	End
	
	-- Validate the change of date.
	If EXISTS (SELECT * FROM OPENITEMTAX OIT 
		JOIN TAXRATES TR ON TR.TAXCODE = OIT.TAXCODE
		where ITEMENTITYNO = @pnItemEntityNo 
		AND ITEMTRANSNO = @pnItemTransNo
		AND OIT.TAXRATE != dbo.fn_GetEffectiveTaxRate(TR.TAXCODE,@sSourceCountry,@pdtItemDate,@pnItemEntityNo)
		)
	Begin
		-- Tax rates do not match. The bill must be reviewed.
		Set @sAlertXML = dbo.fn_GetAlertXML('BI12', 'The date entered may result in a different tax rate being applied. It will not be possible to change the Bill Date from this window.',
											null, null, null, null, null)
		RAISERROR(@sAlertXML, 14, 1)
		Set @nErrorCode = @@ERROR
	End
End

	
If (@nErrorCode = 0)
Begin
	Set @sSQLString = "Select @nTransType = TRANSTYPE
		FROM TRANSACTIONHEADER
		WHERE ENTITYNO = @pnItemEntityNo
		AND TRANSNO = @pnItemTransNo"

	exec @nErrorCode=sp_executesql @sSQLString, 
				N'@pnItemEntityNo	int,
				  @pnItemTransNo	int,
				  @nTransType		int OUTPUT',
				  @pnItemEntityNo = @pnItemEntityNo,
				  @pnItemTransNo = @pnItemTransNo,
				  @nTransType = @nTransType OUTPUT

	If (@bDebug = 1)
	Begin
		Print 'Trans Type = ' + cast(@nTransType as nvarchar(12))
	End
End

if (@nErrorCode = 0 and @nTransType in (516,511,519))
Begin
	Set @sSQLString = "Select @sReasonCode = REASONCODE
		from DEBTORHISTORY
		where REFENTITYNO = @pnItemEntityNo
		and REFTRANSNO = @pnItemTransNo"

	exec @nErrorCode=sp_executesql @sSQLString, 
				N'@pnItemEntityNo	int,
				  @pnItemTransNo	int,
				  @sReasonCode		nvarchar(2) OUTPUT',
				  @pnItemEntityNo = @pnItemEntityNo,
				  @pnItemTransNo = @pnItemTransNo,
				  @sReasonCode = @sReasonCode OUTPUT

	If (@bDebug = 1)
	Begin
		Print 'Reason Code = ' + @sReasonCode
	End
End


If (@nErrorCode = 0 and @pdtItemDate is null)
Begin
	Set @sSQLString = "Select @pdtItemDate = ITEMDATE
			From OPENITEM 
			Where ITEMENTITYNO = @pnItemEntityNo
			and ITEMTRANSNO = @pnItemTransNo"
	
	exec @nErrorCode=sp_executesql @sSQLString, 
				N'@pnItemEntityNo	int,
				  @pnItemTransNo	int,
				  @pdtItemDate		datetime OUTPUT',
				  @pnItemEntityNo = @pnItemEntityNo,
				  @pnItemTransNo = @pnItemTransNo,
				  @pdtItemDate = @pdtItemDate OUTPUT

	If (@bDebug = 1)
	Begin
		Print 'Item Date = ' + cast(@pdtItemDate as nvarchar(20))
	End
End
Else if (@nErrorCode = 0)
Begin
	-- 10581 Update the transactionheader with the new transdate.
	Set @sSQLString = "UPDATE TRANSACTIONHEADER
			SET TRANSDATE = @pdtItemDate
			Where ENTITYNO = @pnItemEntityNo
			and TRANSNO = @pnItemTransNo"
	
	exec @nErrorCode=sp_executesql @sSQLString, 
				N'@pnItemEntityNo	int,
				  @pnItemTransNo	int,
				  @pdtItemDate		datetime',
				  @pnItemEntityNo = @pnItemEntityNo,
				  @pnItemTransNo = @pnItemTransNo,
				  @pdtItemDate = @pdtItemDate
	
	If (@bDebug = 1)
	Begin
		Print 'Updated item date on TRANSACTIONHEADER TO ' + cast(@pdtItemDate as nvarchar(20))
	End
End

If @nErrorCode = 0
Begin
	-- validate the transaction date and get the post period.
	exec @nErrorCode = dbo.acw_ValidateTransactionDate
				@pnUserIdentityId	= @pnUserIdentityId,
				@psCulture		= @psCulture,
				@pbCalledFromCentura	= @pbCalledFromCentura,
				@pdtItemDate		= @pdtItemDate,
				@pnModule		= 2,
				@pbIgnoreWarnings	= 1,
				@pnPeriodId		= @nPostPeriod output
End

If (@bDebug = 1)
Begin
	Print 'Post Period = ' + cast(@nPostPeriod as nvarchar(12))
End

If (@nErrorCode = 0 and @nPostPeriod is null)
Begin
        -- Get the Item Type
	Set @sSQLString = "Select @nItemType = ITEMTYPE
			From OPENITEM 
			Where ITEMENTITYNO = @pnItemEntityNo
			and ITEMTRANSNO = @pnItemTransNo"
	
	exec @nErrorCode=sp_executesql @sSQLString, 
				N'@pnItemEntityNo	int,
				  @pnItemTransNo	int,                                 
				  @nItemType		int OUTPUT',
				  @pnItemEntityNo       = @pnItemEntityNo,
				  @pnItemTransNo        = @pnItemTransNo,                                  
				  @nItemType            = @nItemType OUTPUT

	If (@bDebug = 1)
	Begin
		Print 'Item Type = ' + cast(@nItemType as nvarchar(10))
	End
End

If (@nErrorCode = 0)
Begin
        -- Get the Item Type
	Set @sSQLString = "Select @nItemType = ITEMTYPE
			From OPENITEM 
			Where ITEMENTITYNO = @pnItemEntityNo
			and ITEMTRANSNO = @pnItemTransNo"
	
	exec @nErrorCode=sp_executesql @sSQLString, 
				N'@pnItemEntityNo	int,
				  @pnItemTransNo	int,                                 
				  @nItemType		int OUTPUT',
				  @pnItemEntityNo       = @pnItemEntityNo,
				  @pnItemTransNo        = @pnItemTransNo,                                  
				  @nItemType            = @nItemType OUTPUT

	If (@bDebug = 1)
	Begin
		Print 'Item Type = ' + cast(@nItemType as nvarchar(10))
	End
End


--Get the OpenItem Number
-- TODO: allow OpenItem Number to be allocated manually for each OpenItem

declare @nOfficeId int
declare @sOfficeDescription nvarchar(80)
declare @nItemNoTo decimal(10,0)
declare @nHighestItemNumberOffice decimal(10,0)
declare @nFirstOpenItemNo decimal(10,0)

Declare @nCountOpenItems int
Declare @sItemNoPrefix nvarchar(2)
Declare @sItemTypePrefix nvarchar(10)

if (@nErrorCode = 0)
Begin
	Set @sSQLString = "Select @nCountOpenItems = COUNT(*) from OPENITEM Where ITEMENTITYNO = @pnItemEntityNo and ITEMTRANSNO = @pnItemTransNo"
	
	exec @nErrorCode=sp_executesql @sSQLString, 
				N'@nCountOpenItems int OUTPUT,
				  @pnItemEntityNo int,
				  @pnItemTransNo int',
				  @nCountOpenItems = @nCountOpenItems OUTPUT,
				  @pnItemEntityNo = @pnItemEntityNo,
				  @pnItemTransNo = @pnItemTransNo
End

If (@nErrorCode = 0)
Begin
	-- Check if we have an office setup to generate OI numbers
	Set @sSQLString = "Select @nOfficeId = TA.TABLECODE,
			@nItemNoTo = O.ITEMNOTO,
			@nHighestItemNumberOffice = Case when (ISNULL(O.LASTITEMNO,0) + @nCountOpenItems) < ITEMNOFROM THEN ITEMNOFROM ELSE ISNULL(O.LASTITEMNO,0) + @nCountOpenItems END,
			@sItemNoPrefix = O.ITEMNOPREFIX,
			@nFirstOpenItemNo = CASE WHEN O.ITEMNOFROM is null and O.LASTITEMNO is null THEN null
                                            WHEN O.ITEMNOFROM is null and O.LASTITEMNO is not null THEN O.LASTITEMNO + 1
                                            ELSE CASE WHEN (ISNULL(O.LASTITEMNO,0) + @nCountOpenItems) < ITEMNOFROM THEN ITEMNOFROM ELSE ISNULL(O.LASTITEMNO,0) + 1 END 
                                            END,
			@sOfficeDescription	= O.DESCRIPTION,
                        @sItemTypePrefix = CASE WHEN @nItemType != 510 THEN ABBREVIATION ELSE '' END
			FROM DEBTOR_ITEM_TYPE
                        left join TABLEATTRIBUTES TA on (TA.TABLETYPE = 44 and TA.PARENTTABLE = 'NAME' 
                                                                           and TA.GENERICKEY = (SELECT TOP 1 EMPLOYEENO
								                                        FROM OPENITEM
								                                        WHERE ITEMENTITYNO = @pnItemEntityNo
								                                        AND ITEMTRANSNO = @pnItemTransNo))
			left join OFFICE O on (O.OFFICEID = TA.TABLECODE and O.ITEMNOPREFIX is not null)
                        Where ITEM_TYPE_ID = @nItemType"
	
	exec @nErrorCode=sp_executesql @sSQLString, 
				N'@pnItemEntityNo	int,
				  @pnItemTransNo	int,
				  @nCountOpenItems      int,
                                  @nItemType            int,
				  @nOfficeId		int OUTPUT,
				  @nItemNoTo		        decimal(10,0) OUTPUT,
				  @nHighestItemNumberOffice     decimal(10,0) OUTPUT,
				  @sItemNoPrefix	nvarchar(2) OUTPUT,
                                  @sItemTypePrefix	nvarchar(2) OUTPUT,
				  @nFirstOpenItemNo             decimal(10,0) OUTPUT,
				  @sOfficeDescription nvarchar(80) OUTPUT',
				  @pnItemEntityNo = @pnItemEntityNo,
				  @pnItemTransNo = @pnItemTransNo,
				  @nCountOpenItems = @nCountOpenItems,
                                  @nItemType = @nItemType,
				  @nOfficeId = @nOfficeId OUTPUT,
				  @nItemNoTo = @nItemNoTo OUTPUT,
				  @nHighestItemNumberOffice = @nHighestItemNumberOffice OUTPUT,
                                  @sItemTypePrefix = @sItemTypePrefix OUTPUT,
				  @sItemNoPrefix = @sItemNoPrefix OUTPUT,
				  @nFirstOpenItemNo = @nFirstOpenItemNo OUTPUT,
				  @sOfficeDescription = @sOfficeDescription OUTPUT

        If @nErrorCode = 0
	Begin
                Declare @sOpenItemNo nvarchar(12)                

	        If (@nOfficeId is not null and @nFirstOpenItemNo is not null)
	        Begin
                        Set @nFirstOpenItemNo = dbo.fn_GetFirstOpenItemNumber(@sItemNoPrefix, @nFirstOpenItemNo, @nCountOpenItems)                       

                        If @nErrorCode = 0
                        Begin                             
                                Select @sOpenItemNo = @sItemNoPrefix + cast(@nFirstOpenItemNo as nvarchar(12)) + @sItemTypePrefix

                                While exists (Select 1 from OPENITEM where OPENITEMNO = @sOpenItemNo AND ITEMENTITYNO = @pnItemEntityNo)
                                Begin
	                                Select @sOpenItemNo = @sItemNoPrefix + cast(++@nFirstOpenItemNo as nvarchar(12)) + @sItemTypePrefix
                                End
                        End

                        Set @nHighestItemNumberOffice = @nFirstOpenItemNo + @nCountOpenItems - 1 

		        If @nItemNoTo is not null and @nItemNoTo < @nHighestItemNumberOffice
		        Begin
			        -- The next Office OpenItem Number is out of range
			        Set @sAlertXML = dbo.fn_GetAlertXML('ACxxx', 'The '+ CASE WHEN @nItemType = 511 then 'credit' else 'debit' end 
                                        +' note number upper limit of ' + cast(@nItemNoTo as nvarchar(14)) + ' for the office ' 
                                        + @sOfficeDescription + ' has been exceeded. You must revise the upper limit before continuing.',
					null, null, null, null, null)

			        RAISERROR(@sAlertXML, 14, 1)
			        Set @nErrorCode = @@ERROR
		        End

                        If @nErrorCode = 0
                        Begin
		                Set @sSQLString = "UPDATE O
				                SET LASTITEMNO = @nHighestItemNumberOffice
				                FROM OFFICE O
				                Where O.OFFICEID = @nOfficeId
				                and O.ITEMNOPREFIX is not null
				                and O.ITEMNOTO is not null
				                                and O.ITEMNOTO > ISNULL(O.LASTITEMNO,0)"
		
		                exec @nErrorCode=sp_executesql @sSQLString, 
				                  N'@nHighestItemNumberOffice	decimal(10,0),
				                  @nOfficeId		int',
				                  @nHighestItemNumberOffice = @nHighestItemNumberOffice,
				                  @nOfficeId = @nOfficeId
	                End
	        End
	        Else
	        Begin
                        Declare @sDraftPrefix nvarchar(10)

                        If @nErrorCode = 0
                        Begin
                                Set @sSQLString = "
			                        Select @nFirstOpenItemNo = SN.LASTOPENITEMNO + 1,
                                                @sItemNoPrefix = O.ITEMNOPREFIX
			                        FROM SPECIALNAME SN
                                                Left join (SELECT ITEMNOPREFIX FROM OFFICE WHERE OFFICEID = @nOfficeId) AS O on (1=1)
				                Where SN.NAMENO = @pnItemEntityNo"

	                         exec @nErrorCode=sp_executesql @sSQLString, 
				                        N'@nFirstOpenItemNo	decimal(10,0) OUTPUT,
                                                          @sItemNoPrefix  nvarchar(2) OUTPUT,
                                                          @nOfficeId	  int,
                                                          @pnItemEntityNo int',
				                          @nFirstOpenItemNo = @nFirstOpenItemNo OUTPUT,
				                          @sItemNoPrefix = @sItemNoPrefix OUTPUT,
                                                          @nOfficeId = @nOfficeId,
                                                          @pnItemEntityNo = @pnItemEntityNo
                        End

                        If @nErrorCode = 0
                        Begin 
                                Select @sOpenItemNo = @sItemNoPrefix + cast(@nFirstOpenItemNo as nvarchar(12)) + @sItemTypePrefix

                                While exists (Select 1 from OPENITEM where OPENITEMNO = @sOpenItemNo AND ITEMENTITYNO = @pnItemEntityNo)
                                Begin
                                        Set @nFirstOpenItemNo = @nFirstOpenItemNo + 1
	                                Select @sOpenItemNo = @sItemNoPrefix + cast(@nFirstOpenItemNo  as nvarchar(12)) + @sItemTypePrefix
                                End
                        End

		        -- Get the number in the normal way
		        Set @sSQLString = "UPDATE SPECIALNAME
				        Set LASTOPENITEMNO = @nFirstOpenItemNo + @nCountOpenItems - 1
				        Where NAMENO = @pnItemEntityNo"

		        exec @nErrorCode=sp_executesql @sSQLString, 
				        N'@pnItemEntityNo	int,
				          @nCountOpenItems	int,
				          @nFirstOpenItemNo	decimal(10,0)',
				          @pnItemEntityNo = @pnItemEntityNo,
				          @nCountOpenItems = @nCountOpenItems,
				          @nFirstOpenItemNo = @nFirstOpenItemNo
	End
        End

	If (@bDebug = 1)
	Begin
		Print 'Number of Open Items = ' + cast(@nCountOpenItems as nvarchar(12))
		Print 'First Open Item No = ' + @sItemNoPrefix +CAST(@nFirstOpenItemNo AS NVARCHAR(12))
	End

	If (@nErrorCode = 0 and @nFirstOpenItemNo is null)
	Begin
		-- The next Office OpenItem Number is out of range
		Set @sAlertXML = dbo.fn_GetAlertXML('AC128', 'The process failed to complete - an Open Item Number could not be generated. Consequently, no data has been saved or updated.',
											null, null, null, null, null)
		RAISERROR(@sAlertXML, 14, 1)
		Set @nErrorCode = @@ERROR
	End

        If @nErrorCode = 0
        Begin
                Declare @iCount int
                Set @iCount = 1 
                
                WHILE @iCount < @nCountOpenItems and @nErrorCode = 0
                Begin 
                        Select @sOpenItemNo = @sItemNoPrefix + cast(@nFirstOpenItemNo + @iCount as nvarchar(12)) + @sItemTypePrefix

                        If exists (Select 1 from OPENITEM where OPENITEMNO = @sOpenItemNo AND ITEMENTITYNO = @pnItemEntityNo)  
                        Begin   
                               -- The Office OpenItem Number already exist
		                Set @sAlertXML = dbo.fn_GetAlertXML('AC128', 'The process failed to complete - Open Item Number ' + @sOpenItemNo + ' already exists for the Entity. Consequently, no data has been saved or updated.',
											                null, null, null, null, null)
		                RAISERROR(@sAlertXML, 14, 1)
		                Set @nErrorCode = @@ERROR                             
                        End 

                        Set @iCount = @iCount + 1
                End 
        End
End


-- Update Open Item
If (@nErrorCode = 0)
Begin
	If (@bDebug = 1)
	Begin
		Print 'Updating OpenItem to posted.'
	End

	Set @sSQLString = "UPDATE OPENITEM"+CHAR(10)+
					"Set STATUS = 1,"+CHAR(10)+
					"POSTDATE = @dtPostDate,"+CHAR(10)+
					"POSTPERIOD = @nPostPeriod,"+CHAR(10)+
					"CLOSEPOSTDATE=Case When LOCALBALANCE = 0 THEN @dtPostDate Else @dtMaxDate End,"+char(10)+
					"CLOSEPOSTPERIOD=Case When LOCALBALANCE = 0 THEN @nPostPeriod Else 999999 End,"+char(10)+
					"EXCHVARIANCE = ISNULL(EXCHVARIANCE, 0),"+char(10)+
					"OPENITEMNO = @sItemNoPrefix + cast(@nFirstOpenItemNo + 
						(SELECT COUNT(*) FROM OPENITEM OI1 WHERE OI1.OPENITEMNO < OI.OPENITEMNO 
						and ITEMENTITYNO = @pnItemEntityNo 
						and ITEMTRANSNO = @pnItemTransNo) as nvarchar(12)) + CASE WHEN OI.ITEMTYPE != 510 THEN DIT.ABBREVIATION END"
					--"LOCKIDENTITYID = NULL"

	If @nErrorCode = 0 and  @pdtItemDate is not null
	Begin
		Set @sSQLString = @sSQLString + ","+CHAR(10)+"ITEMDATE=@pdtItemDate,"+char(10)+
					"ITEMDUEDATE=CASE WHEN COALESCE(IPN.TRADINGTERMS, TTSC.COLINTEGER, 0) = 0"+CHAR(10)+
							"THEN NULL"+CHAR(10)+
							"ELSE @pdtItemDate + isnull(IPN.TRADINGTERMS, TTSC.COLINTEGER) END"
	End

	Set @sSQLString = @sSQLString + char(10) +
			"From OPENITEM OI"+char(10)+
			"Join DEBTOR_ITEM_TYPE DIT on (DIT.ITEM_TYPE_ID = OI.ITEMTYPE)"+char(10)+
			"Join IPNAME IPN ON IPN.NAMENO = OI.ACCTDEBTORNO"+CHAR(10)+
			"Left Join SITECONTROL TTSC on TTSC.CONTROLID = 'Trading Terms'"+CHAR(10)+
			"Where ITEMENTITYNO = @pnItemEntityNo"+char(10)+
			"and ITEMTRANSNO = @pnItemTransNo"

	exec @nErrorCode=sp_executesql @sSQLString, 
				N'@pnItemEntityNo	int,
				  @pnItemTransNo	int,
				  @pdtItemDate		datetime,
				  @dtPostDate		datetime,
				  @nPostPeriod		int,
				  @sItemNoPrefix	nvarchar(2),
				  @nFirstOpenItemNo	decimal(10,0),
				  @dtMaxDate		datetime',
				  @pnItemEntityNo = @pnItemEntityNo,
				  @pnItemTransNo = @pnItemTransNo,
				  @pdtItemDate = @pdtItemDate,
				  @dtPostDate = @dtPostDate,
				  @nPostPeriod = @nPostPeriod,
				  @sItemNoPrefix = @sItemNoPrefix,
				  @nFirstOpenItemNo = @nFirstOpenItemNo,
				  @dtMaxDate = @dtMaxDate
End

-- Update Open Item with EnteredOpenItemNo
If (@nErrorCode = 0 and datalength(@ptXMLEnteredOpenItems) > 0)
Begin
	If (@bDebug = 1)
	Begin
		Print 'Updating OpenItem with Entered Open Item No'
	End
	-- Create an XML document in memory and then retrieve the information 
	-- from the rowset using OPENXML
	CREATE TABLE #ENTEREDOPENITEM (ENTITYKEY int, ACCOUNTENTITYKEY int, TRANSACTIONKEY int, 
					DEBTORNO int, ENTEREDOPENITEMNO nvarchar(12) collate database_default null)
        declare @sRowPattern nvarchar(256)
        Declare @idoc int 
        
	exec sp_xml_preparedocument	@idoc OUTPUT, @ptXMLEnteredOpenItems	
	
	Set @sRowPattern = "//biw_FinaliseOpenItem/OpenItemGroup/OpenItem"
		Insert into #ENTEREDOPENITEM(ENTITYKEY,ACCOUNTENTITYKEY,TRANSACTIONKEY, DEBTORNO,ENTEREDOPENITEMNO)
		Select	*
		from	OPENXML (@idoc, @sRowPattern, 2)
		WITH (
		      EntityKey			int		'EntityKey/text()',
		      AccountEntityKey		int	        'AccountEntityKey/text()',
		      TransactionKey		int		'TransactionKey/text()',
		      DebtorNo		        int	        'DebtorKey/text()',
		      EnteredOpenItemNo		nvarchar(12)	'EnteredOpenItemKey/text()'
		     )

	-- deallocate the xml document handle when finished.
	exec sp_xml_removedocument @idoc
	Set @sSQLString = "UPDATE OPENITEM"+CHAR(10)+
					"Set OPENITEMNO = EOI.ENTEREDOPENITEMNO"+CHAR(10)+
					"FROM #ENTEREDOPENITEM AS EOI, OPENITEM AS OI"+CHAR(10)+
					"Join DEBTOR_ITEM_TYPE DIT on (DIT.ITEM_TYPE_ID = OI.ITEMTYPE)"+char(10)+
					"WHERE EOI.ENTITYKEY = OI.ITEMENTITYNO  AND "+CHAR(10)+
					"EOI.ACCOUNTENTITYKEY    = OI.ACCTENTITYNO AND"+char(10)+
					"EOI.TRANSACTIONKEY    = OI.ITEMTRANSNO AND"+char(10)+
					"EOI.DEBTORNO = OI.ACCTDEBTORNO AND"+char(10)+
					"EOI.ENTEREDOPENITEMNO is not null AND"+char(10)+
					"OI.ITEMENTITYNO = @pnItemEntityNo AND"+char(10)+
			                "OI.ITEMTRANSNO = @pnItemTransNo"

        exec @nErrorCode=sp_executesql @sSQLString, 
				N'@pnItemEntityNo	int,
				  @pnItemTransNo	int',
				  @pnItemEntityNo = @pnItemEntityNo,
				  @pnItemTransNo = @pnItemTransNo
				  
	EXEC sp_executesql N'DROP table #ENTEREDOPENITEM' 		  
End
Declare @bIsInstalmentBill bit
Set @bIsInstalmentBill = 0

-- Check if we are processing an Instalment Bill
If @nErrorCode = 0 
and exists (Select * from SITECONTROL where CONTROLID = 'Quotations' AND COLBOOLEAN = 1) -- Quotations set
and not exists( 
	SELECT * FROM TRANSACTIONHEADER
	Where TRANSTYPE IN (516, 519)
	and ENTITYNO = @pnItemEntityNo
	and TRANSNO = @pnItemTransNo) -- Not a credit note
and exists (
	SELECT *
	FROM INSTALMENT I
	Where I.ENTITYNO = @pnItemEntityNo
	and I.TRANSNO = @pnItemTransNo) -- An Instalment exists
and not exists (
	SELECT *
	FROM INSTALMENT I
	JOIN INSTALMENT I1 on (I1.QUOTATIONNO = I.QUOTATIONNO
							and I1.INSTALMENTNO != I.INSTALMENTNO)
	JOIN OPENITEM OI on (OI.ITEMENTITYNO = I1.ENTITYNO
						and OI.ITEMTRANSNO = I1.TRANSNO
						and OI.POSTDATE IS NOT NULL)
	WHERE I.ENTITYNO = @pnItemEntityNo
	and I.TRANSNO = @pnItemTransNo) -- And no other outstanding Instalments exists
Begin
	If (@bDebug = 1)
	Begin
		Print 'Processing instalment bill.'
	End

	Set @bIsInstalmentBill = 1

	-- Close the Quotation
	Set @sSQLString = "UPDATE QUOTATION
		SET STATUS = 7403
		FROM QUOTATION
		JOIN INSTALMENT I on (I.QUOTATIONNO = QUOTATION.QUOTATIONNO)
		WHERE I.ENTITYNO = @pnItemEntityNo
		and I.TRANSNO = @pnItemTransNo"

	exec @nErrorCode=sp_executesql @sSQLString, 
				N'@pnItemEntityNo	int,
				  @pnItemTransNo	int',
				  @pnItemEntityNo = @pnItemEntityNo,
				  @pnItemTransNo = @pnItemTransNo
End

-- Post Work History
If (@nErrorCode = 0)
Begin
	If (@bDebug = 1)
	Begin
		Print 'Delete no value Work History.'
	End

	-- Delete Work History with no local value
	Set @sSQLString = "
		Delete from WH
		From WORKHISTORY WH
		Join BILLEDITEM BI ON BI.WIPENTITYNO = WH.ENTITYNO
							and BI.WIPTRANSNO = WH.TRANSNO
							and BI.WIPSEQNO = WH.WIPSEQNO
		Where WH.LOCALTRANSVALUE = 0
		AND WH.ENTITYNO = @pnItemEntityNo
		AND WH.TRANSNO = @pnItemTransNo"

	exec @nErrorCode=sp_executesql @sSQLString, 
				N'@pnItemEntityNo	int,
				  @pnItemTransNo	int',
				  @pnItemEntityNo = @pnItemEntityNo,
				  @pnItemTransNo = @pnItemTransNo
End

-- Post Draft Work History
If (@nErrorCode = 0)
Begin
	If (@bDebug = 1)
	Begin
		Print 'Post Consume Work History'
	End

	exec @nErrorCode = dbo.acw_PostWorkHistory
				@pnUserIdentityId = @pnUserIdentityId,
				@psCulture = @psCulture,
				@pbCalledFromCentura = @pbCalledFromCentura,
				@pnItemEntityNo	= @pnItemEntityNo,
				@pnItemTransNo = @pnItemTransNo,
				@pnMovementType	= 2, -- Consume
				@pnPostPeriod = @nPostPeriod,
				@pnTransType = @nTransType

	Set @nErrorCode = @@error
End

-- Process WIP Variations
if @nErrorCode = 0 and 
	exists(select * from BILLEDITEM 
			WHERE ITEMENTITYNO = @pnItemEntityNo
			AND ITEMTRANSNO = @pnItemTransNo
			AND ADJUSTEDVALUE IS NOT NULL
			AND REASONCODE IS NOT NULL
			AND ADJUSTEDVALUE > 0)
Begin
	If (@bDebug = 1)
	Begin
		Print 'Post Equalise WIP Variations.'
	End
	-- Create Adjustment WIP items. (equalise)
	--xfVaryItem
	-- Vary the balance of the item by the value
	-- on the Billed Item (write-up/down)
	-- No reason code = partial billing, not adjustment
	exec @nErrorCode = dbo.acw_PostWorkHistory
				@pnUserIdentityId = @pnUserIdentityId,
				@psCulture = @psCulture,
				@pbCalledFromCentura = @pbCalledFromCentura,
				@pnItemEntityNo	= @pnItemEntityNo,
				@pnItemTransNo = @pnItemTransNo,
				@pnMovementType	= 9, -- Equalise
				@pnPostPeriod = @nPostPeriod,
				@pnTransType = @nTransType
End

if @nErrorCode = 0 and 
	exists(select * from BILLEDITEM 
			WHERE ITEMENTITYNO = @pnItemEntityNo
			AND ITEMTRANSNO = @pnItemTransNo
			AND ADJUSTEDVALUE IS NOT NULL
			AND REASONCODE IS NOT NULL
			AND ADJUSTEDVALUE < 0)
Begin
	If (@bDebug = 1)
	Begin
		Print 'Post Dispose WIP Adjustments.'
	End

	-- Create Adjustment WIP items (dispose)
	exec @nErrorCode = dbo.acw_PostWorkHistory
				@pnUserIdentityId = @pnUserIdentityId,
				@psCulture = @psCulture,
				@pbCalledFromCentura = @pbCalledFromCentura,
				@pnItemEntityNo	= @pnItemEntityNo,
				@pnItemTransNo = @pnItemTransNo,
				@pnMovementType	= 3, -- Dispose
				@pnPostPeriod = @nPostPeriod,
				@pnTransType = @nTransType
End

If @nErrorCode = 0
Begin
	If (@bDebug = 1)
	Begin
		Print 'Add Fee List'
	End

	-- Add to Fee List for draft wip items
	exec @nErrorCode = dbo.wp_AddDraftWipToFeeList
		@pnUserIdentityId = @pnUserIdentityId,
		@psCulture = @psCulture,
		@pnItemEntityNo= @pnItemEntityNo,
		@pnItemTransNo = @pnItemTransNo,
		@pdtItemDate = @pdtItemDate
End

If (@nErrorCode = 0)
Begin
	If (@bDebug = 1)
	Begin
		Print 'Update WIP Balances.'
	End

	-- Update the WIP balances
	-- Don't update bill in advance WIP (WH.MOVEMENTCLASS = 2 AND WH.COMMANDID=2)
	
	-- For credit note with write down WIP checked,
	--	WIP.BALANCE - BI.BILLEDVALUE because BILLED item is stored differently
	
	-- For credit note draft wip
	--	If write down wip consume the billed value (commandid = 99 and reasoncode is not null)
	--	otherwise leave WIP balance to be consumed later (commandid = 99 and reasoncode is null)

	Set @sSQLString = "Update WIP
		SET WIP.BALANCE = WIP.BALANCE - case when WIP.STATUS = 0 and WH.MOVEMENTCLASS = 2 AND (WH.COMMANDID = 2 
								or (WH.COMMANDID = 99 AND BI.REASONCODE IS NULL)) then 0 else 
							case when WIP.STATUS = 0 AND WH.MOVEMENTCLASS = 2 AND WH.COMMANDID = 99 and BI.REASONCODE IS NOT NULL
							THEN BI.BILLEDVALUE
							ELSE BI.BILLEDVALUE - ISNULL(BI.ADJUSTEDVALUE,0) end
						END,
		WIP.FOREIGNBALANCE = case when WIP.FOREIGNCURRENCY IS NOT NULL 
					then (WIP.FOREIGNBALANCE - case when WIP.STATUS = 0 and WIP.DISCOUNTFLAG = 0 then 0 else BI.FOREIGNBILLEDVALUE end)
					else null end,
		WIP.STATUS = 1
		FROM WORKINPROGRESS WIP
		join BILLEDITEM BI on (BI.WIPENTITYNO = WIP.ENTITYNO
							and BI.WIPTRANSNO = WIP.TRANSNO
							and BI.WIPSEQNO = WIP.WIPSEQNO)
		join WORKHISTORY WH on (WH.ENTITYNO = WIP.ENTITYNO
							and WH.TRANSNO = WIP.TRANSNO
							and WH.WIPSEQNO = WIP.WIPSEQNO
							and WH.ITEMIMPACT = 1)
		Where BI.ITEMENTITYNO = @pnItemEntityNo
		and BI.ITEMTRANSNO = @pnItemTransNo"

	exec @nErrorCode=sp_executesql @sSQLString, 
				N'@pnItemEntityNo	int,
				  @pnItemTransNo	int',
				  @pnItemEntityNo = @pnItemEntityNo,
				  @pnItemTransNo = @pnItemTransNo

End

-- Delete Billed Items
If (@nErrorCode = 0)
Begin
	If (@bDebug = 1)
	Begin
		Print 'Delete BILLEDITEMs.'
	End

	Set @sSQLString = "Delete from BILLEDITEM
				Where ITEMENTITYNO = @pnItemEntityNo
				and ITEMTRANSNO = @pnItemTransNo"

	exec @nErrorCode=sp_executesql @sSQLString, 
				N'@pnItemEntityNo	int,
				  @pnItemTransNo	int',
				  @pnItemEntityNo = @pnItemEntityNo,
				  @pnItemTransNo = @pnItemTransNo
End

If (@nErrorCode = 0)
Begin
	If (@bDebug = 1)
	Begin
		Print 'Delete WIP.'
	End

	-- Delete fully consumed WIP
	Set @sSQLString = "Delete WIP
		from WORKINPROGRESS WIP
		join WORKHISTORY WH ON WH.ENTITYNO = WIP.ENTITYNO
					and WH.TRANSNO = WIP.TRANSNO
					and WH.WIPSEQNO = WIP.WIPSEQNO
		Where WH.REFENTITYNO = @pnItemEntityNo
		and WH.REFTRANSNO = @pnItemTransNo
		and WIP.BALANCE = 0"

	exec @nErrorCode=sp_executesql @sSQLString, 
				N'@pnItemEntityNo	int,
				  @pnItemTransNo	int',
				  @pnItemEntityNo = @pnItemEntityNo,
				  @pnItemTransNo = @pnItemTransNo
End

If (@nErrorCode = 0)
Begin
	If (@bDebug = 1)
	Begin
		Print 'Update status of Bill in Advance WIP.'
	End

	--Post Work In Progress (for draft BILLED IN ADVANCE WIP items - See xfPostItem())
	Set @sSQLString = "Update WIP
		Set WIP.STATUS = 1,
			WIP.POSTDATE = @dtPostDate
		From WORKINPROGRESS WIP
		Join WORKHISTORY WH on (WH.ENTITYNO = WIP.ENTITYNO
								and WH.TRANSNO = WIP.TRANSNO
								and WH.WIPSEQNO = WIP.WIPSEQNO
								and WH.HISTORYLINENO = 1)
		where WH.ENTITYNO = @pnItemEntityNo
		and WH.TRANSNO = @pnItemTransNo
		and WH.MOVEMENTCLASS = 2"

	exec @nErrorCode=sp_executesql @sSQLString, 
				N'@pnItemEntityNo	int,
				  @pnItemTransNo	int,
				  @dtPostDate datetime',
				  @pnItemEntityNo = @pnItemEntityNo,
				  @pnItemTransNo = @pnItemTransNo,
				  @dtPostDate = @dtPostDate
End


If @nErrorCode = 0 and (@nTransType in (510,517,514)) -- bill
Begin
	If (@bDebug = 1)
	Begin
		Print 'Post Debtor History for a Bill.'
	End

	exec @nErrorCode = dbo.acw_PostDebtorHistory
		@pnUserIdentityId = @pnUserIdentityId,
		@psCulture = @psCulture,
		@pbCalledFromCentura = @pbCalledFromCentura,
		@pnItemEntityNo = @pnItemEntityNo,
		@pnItemTransNo = @pnItemTransNo,
		@pnMovementType = 1, -- Generate
		@pdtPostDate = @dtPostDate,
		@pnPostPeriod = @nPostPeriod,
		@pbPostCredits = 0,
		@psReasonCode = @sReasonCode

	-- Process take up credits
	if @nErrorCode = 0 
	and exists(
		select * from OPENITEM WHERE ITEMENTITYNO = @pnItemEntityNo
		and ITEMTRANSNO = @pnItemTransNo
		and LOCALORIGTAKENUP > 0
	)
	Begin
		If (@bDebug = 1)
		Begin
			Print 'Process take-up Credits on a Bill.'
		End
		
		If exists (select * from BILLEDCREDIT BC
			Join OPENITEM OI on (OI.ITEMENTITYNO = CRITEMENTITYNO
							and OI.ITEMTRANSNO = CRITEMTRANSNO
							and OI.ACCTENTITYNO = CRACCTENTITYNO
							and OI.ACCTDEBTORNO = CRACCTDEBTORNO)
			Where
			OI.LOCKIDENTITYID is not null
			and BC.DRITEMENTITYNO = @pnItemEntityNo
			and BC.DRITEMTRANSNO = @pnItemTransNo)
		Begin
			-- credit item has been locked by another process
			Set @sAlertXML = dbo.fn_GetAlertXML('AC221', 'One or more of the credit items choosen has been locked by another process and cannot be applied. Remove the credit item before proceeding.',
								null, null, null, null, null)
			RAISERROR(@sAlertXML, 14, 1)
			Set @nErrorCode = @@ERROR
		End

		If @nErrorCode = 0 
		Begin
			If not exists (
				Select * from BILLEDCREDIT BC
				Join OPENITEM OI on (OI.ITEMENTITYNO = DRITEMENTITYNO
								and OI.ITEMTRANSNO = DRITEMTRANSNO
								and OI.ACCTENTITYNO = DRACCTENTITYNO
								and OI.ACCTDEBTORNO = DRACCTDEBTORNO)
				Where
				OI.ITEMENTITYNO = @pnItemEntityNo
				and OI.ITEMTRANSNO = @pnItemTransNo)
			Begin 
				-- Could not determine find credits to take up
				Set @sAlertXML = dbo.fn_GetAlertXML('AC129', 'Debit Note has local taken up value, but no Billed Credit records. Please delete the draft Debit Note and re-enter it.',
											null, null, null, null, null)
				RAISERROR(@sAlertXML, 14, 1)
				Set @nErrorCode = @@ERROR
			End
			Else
			Begin
				If (@bDebug = 1)
				Begin
					Print 'Create Debtor History for application of Credit items.'
				End

				exec @nErrorCode = dbo.acw_PostDebtorHistory
					@pnUserIdentityId = @pnUserIdentityId,
					@psCulture = @psCulture,
					@pbCalledFromCentura = @pbCalledFromCentura,
					@pnItemEntityNo = @pnItemEntityNo,
					@pnItemTransNo = @pnItemTransNo,
					@pnMovementType = 5, -- Adjust debtor item Down
					@pdtPostDate = @dtPostDate,
					@pnPostPeriod = @nPostPeriod,
					@pbPostCredits = 0,
					@psReasonCode = @sReasonCode

				If @nErrorCode = 0
				Begin
					If (@bDebug = 1)
					Begin
						Print 'Post Debtor History for Credit items associated to the bill.'
					End

					--xfUpdateCreditItem
					-- Update the credits consumed on this bill

					exec @nErrorCode = dbo.acw_PostDebtorHistory
						@pnUserIdentityId = @pnUserIdentityId,
						@psCulture = @psCulture,
						@pbCalledFromCentura = @pbCalledFromCentura,
						@pnItemEntityNo = @pnItemEntityNo,
						@pnItemTransNo = @pnItemTransNo,
						@pnMovementType = 4, -- Adjust credit item up
						@pdtPostDate = @dtPostDate,
						@pnPostPeriod = @nPostPeriod,
						@pbPostCredits = 1,
						@psReasonCode = @sReasonCode
				End
			End
		End
	End
End
Else
Begin
	-- Just post the credit note
	If @nErrorCode = 0
	Begin
		If (@bDebug = 1)
		Begin
			Print 'Post Credit Note.'
		End

		Set @sSQLString = "Update DEBTORHISTORY
					Set OPENITEMNO = OI.OPENITEMNO,
					POSTDATE = @dtPostDate,
					POSTPERIOD = @nPostPeriod," + char(10) +
					CASE WHEN @pdtItemDate IS NOT NULL THEN "TRANSDATE = '" + cast(@pdtItemDate as nvarchar) + "'," ELSE NULL END +char(10)+
					"STATUS = 1
					From OPENITEM OI 
					Join DEBTORHISTORY
						on (DEBTORHISTORY.REFENTITYNO = OI.ITEMENTITYNO
							and DEBTORHISTORY.REFTRANSNO = OI.ITEMTRANSNO
							and DEBTORHISTORY.ACCTDEBTORNO = OI.ACCTDEBTORNO)
					WHERE OI.ITEMENTITYNO = @pnItemEntityNo
					and OI.ITEMTRANSNO = @pnItemTransNo
					and HISTORYLINENO = 1"


		exec @nErrorCode=sp_executesql @sSQLString, 
				N'@pnItemEntityNo	int,
				  @pnItemTransNo	int,
				  @dtPostDate datetime,
				  @nPostPeriod	int',
				  @pnItemEntityNo = @pnItemEntityNo,
				  @pnItemTransNo = @pnItemTransNo,
				  @dtPostDate = @dtPostDate,
				  @nPostPeriod = @nPostPeriod


		If (@nErrorCode = 0)
		Begin

			If (@bDebug = 1)
			Begin
				Print 'Update Credit Note Control Total.'
			End
			Set @nControlTotal = 0

			-- Update control totals for the credit
			Set @sSQLString = "Select @nControlTotal = SUM(LOCALVALUE),
				@nMovementType = MOVEMENTCLASS
				From DEBTORHISTORY
				Where ITEMENTITYNO = @pnItemEntityNo
				and ITEMTRANSNO = @pnItemTransNo
				and HISTORYLINENO = 1
				GROUP BY MOVEMENTCLASS"

			exec @nErrorCode=sp_executesql @sSQLString, 
					N'@pnItemEntityNo	int,
					  @pnItemTransNo	int,
					  @nControlTotal decimal(13,2) OUTPUT,
					  @nMovementType	int OUTPUT',
					  @pnItemEntityNo = @pnItemEntityNo,
					  @pnItemTransNo = @pnItemTransNo,
					  @nControlTotal = @nControlTotal OUTPUT,
					  @nMovementType = @nMovementType OUTPUT
		End

		If (@nErrorCode = 0 and @nControlTotal != 0)
		Begin
			-- Call this procedure to insert/update as appropriate
			exec @nErrorCode = dbo.acw_UpdateControlTotal
				@pnUserIdentityId = @pnUserIdentityId,
				@psCulture = @psCulture,
				@pbCalledFromCentura = @pbCalledFromCentura,
				@pnLedger = 2,
				@pnCategory	= @nMovementType,
				@pnType	= @nTransType,
				@pnPeriodId	= @nPostPeriod,
				@pnEntityNo	= @pnItemEntityNo,
				@pnAmountToAdd = @nControlTotal
		End
	End
End


-- UPDATE DEBTOR'S ACCOUNT BALANCE
If (@nErrorCode = 0)
Begin

	If (@bDebug = 1)
	Begin
		Print 'Update debtor account balance'
	End

	Set @sSQLString = "
		Update A
		Set BALANCE = BALANCE + DH.TOTALLOCAL
		From ACCOUNT A
		Join (SELECT ACCTENTITYNO, ACCTDEBTORNO, SUM(LOCALVALUE) AS TOTALLOCAL 
				FROM DEBTORHISTORY 
				WHERE REFENTITYNO = @pnItemEntityNo
				and REFTRANSNO = @pnItemTransNo
			GROUP BY ACCTENTITYNO, ACCTDEBTORNO) as DH on (DH.ACCTENTITYNO = A.ENTITYNO
					and DH.ACCTDEBTORNO = A.NAMENO)"

	exec @nErrorCode=sp_executesql @sSQLString, 
			N'@pnItemEntityNo	int,
			  @pnItemTransNo	int',
			  @pnItemEntityNo = @pnItemEntityNo,
			  @pnItemTransNo = @pnItemTransNo
End

If @nErrorCode = 0
	and exists (select * from SITECONTROL WHERE CONTROLID = 'TAXREQUIRED' AND COLBOOLEAN = 1)
Begin
	If (@bDebug = 1)
	Begin
		Print 'Insert Tax History.'
	End

	--todo: PROVIDE SUPPORT FOR MULTI-TIER TAX
	Set @sSQLString = "INSERT INTO TAXHISTORY
			(ITEMENTITYNO, ITEMTRANSNO, ACCTENTITYNO, ACCTDEBTORNO,
			HISTORYLINENO,
			TAXCODE, TAXRATE,
			TAXABLEAMOUNT, TAXAMOUNT, COUNTRYCODE, 
			REFENTITYNO, REFTRANSNO,
			ADJUSTMENT, HARMONISED, MODIFIED, STATE, TAXONTAX)

			SELECT
			OIT.ITEMENTITYNO, OIT.ITEMTRANSNO, OIT.ACCTENTITYNO, OIT.ACCTDEBTORNO,
			DH.MAXHISTORYLINENO,
			OIT.TAXCODE,
			OIT.TAXRATE, OIT.TAXABLEAMOUNT, OIT.TAXAMOUNT, OIT.COUNTRYCODE,
			TH.ENTITYNO, TH.TRANSNO,
			NULL, NULL, NULL, NULL, NULL
			FROM TRANSACTIONHEADER TH
			Join OPENITEMTAX OIT on (OIT.ITEMENTITYNO = TH.ENTITYNO
									and OIT.ITEMTRANSNO = TH.TRANSNO)
			Join (Select ITEMENTITYNO, ITEMTRANSNO, ACCTENTITYNO, ACCTDEBTORNO, MAX(HISTORYLINENO) MAXHISTORYLINENO
					From DEBTORHISTORY
					Where ITEMENTITYNO = @pnItemEntityNo
					and ITEMTRANSNO = @pnItemTransNo
					and ITEMIMPACT = 1
					GROUP BY ITEMENTITYNO, ITEMTRANSNO, ACCTENTITYNO, ACCTDEBTORNO) AS DH 
				on (DH.ITEMENTITYNO = OIT.ITEMENTITYNO
					and DH.ITEMTRANSNO = OIT.ITEMTRANSNO
					and DH.ACCTENTITYNO = OIT.ACCTENTITYNO
					and DH.ACCTDEBTORNO = OIT.ACCTDEBTORNO)
			WHERE TH.ENTITYNO = @pnItemEntityNo
			and TH.TRANSNO = @pnItemTransNo"

	exec @nErrorCode=sp_executesql @sSQLString, 
			N'@pnItemEntityNo	int,
			  @pnItemTransNo	int',
			  @pnItemEntityNo = @pnItemEntityNo,
			  @pnItemTransNo = @pnItemTransNo


	-- Update the tax ledger
	If (@nErrorCode = 0)
	Begin
		If (@bDebug = 1)
		Begin
			Print 'Update Tax Ledger Control Total.'
		End

		Set @nControlTotal = 0

		Set @sSQLString = "SELECT @nControlTotal = SUM(LOCALTAXAMT)
				FROM OPENITEM
				WHERE ITEMENTITYNO = @pnItemEntityNo
				AND ITEMTRANSNO = @pnItemTransNo"

		exec @nErrorCode=sp_executesql @sSQLString, 
				N'@pnItemEntityNo	int,
				  @pnItemTransNo	int,
				  @nControlTotal decimal(13,2) OUTPUT',
				  @pnItemEntityNo = @pnItemEntityNo,
				  @pnItemTransNo = @pnItemTransNo,
				  @nControlTotal = @nControlTotal OUTPUT
	
		If (@nErrorCode = 0 and @nControlTotal != 0)
		Begin
			-- Call this procedure to insert/update as appropriate
			exec @nErrorCode = dbo.acw_UpdateControlTotal
				@pnUserIdentityId = @pnUserIdentityId,
				@psCulture = @psCulture,
				@pbCalledFromCentura = @pbCalledFromCentura,
				@pnLedger = 3,
				@pnCategory	= 1,
				@pnType	= @nTransType,
				@pnPeriodId	= @nPostPeriod,
				@pnEntityNo	= @pnItemEntityNo,
				@pnAmountToAdd = @nControlTotal
		End
	End
End

-- Delete Billed Credits
If (@nErrorCode = 0 and @nTransType not in (516,519))
Begin
	If (@bDebug = 1)
	Begin
		Print 'Delete Billed Credits.'
	End

	Set @sSQLString = "Delete FROM BILLEDCREDIT
		Where DRITEMENTITYNO = @pnItemEntityNo
		and DRITEMTRANSNO = @pnItemTransNo"

	exec @nErrorCode=sp_executesql @sSQLString, 
				N'@pnItemEntityNo	int,
				  @pnItemTransNo	int',
				  @pnItemEntityNo = @pnItemEntityNo,
				  @pnItemTransNo = @pnItemTransNo
End

-- Delete Open Item Breakdown
If (@nErrorCode = 0 and @nTransType not in (516,519))
Begin
	If (@bDebug = 1)
	Begin
		Print 'Delete Open Item Breakdown.'
	End

	Set @sSQLString = "Delete FROM OPENITEMBREAKDOWN
		WHERE ITEMENTITYNO = @pnItemEntityNo
		AND ITEMTRANSNO = @pnItemTransNo"

	exec @nErrorCode=sp_executesql @sSQLString, 
				N'@pnItemEntityNo	int,
				  @pnItemTransNo	int',
				  @pnItemEntityNo = @pnItemEntityNo,
				  @pnItemTransNo = @pnItemTransNo
End

If (@nErrorCode = 0)
Begin
	Set @sSQLString = "
		Select @nGLJournalCreation = COLINTEGER
		From SITECONTROL
		Where CONTROLID = 'GL Journal Creation'"

	exec	@nErrorCode = sp_executesql @sSQLString,
					N'@nGLJournalCreation	int 			OUTPUT',
					@nGLJournalCreation = @nGLJournalCreation	OUTPUT
End


-- Update Transaction Status
-- This is done as late as possible to minimise the time the TransactionHeader table is locked.
If (@nErrorCode = 0)
Begin
	If (@bDebug = 1)
	Begin
		Print 'Update Transaction Header with Post info.'
	End

	Set @sSQLString = "Update TRANSACTIONHEADER Set TRANSTATUS = 1,"+char(10)+
						"TRANPOSTPERIOD = @nPostPeriod,"+CHAR(10)+
					"TRANPOSTDATE = @dtPostDate"+CHAR(10)
	
	If (@nGLJournalCreation is not null)
	Begin
		-- If generating a journal, set the gl status to awaiting processing
		Set @sSQLString = @sSQLString + "," + char(10) +
					"GLSTATUS = 0"
	End
	
	Set @sSQLString = @sSQLString + CHAR(10) +
						"Where ENTITYNO = @pnItemEntityNo"+CHAR(10)+
						"and TRANSNO = @pnItemTransNo"

	exec @nErrorCode=sp_executesql @sSQLString, 
				N'@nPostPeriod int,
				  @dtPostDate datetime,
				  @pnItemEntityNo	int,
				  @pnItemTransNo	int',
				  @nPostPeriod = @nPostPeriod,
				  @dtPostDate = @dtPostDate,
				  @pnItemEntityNo = @pnItemEntityNo,
				  @pnItemTransNo = @pnItemTransNo
End

-- Process inter-entity transfers
If @nErrorCode = 0
	and exists (Select * from SITECONTROL 
			Where CONTROLID = 'Inter-Entity Billing'
			and COLBOOLEAN = 1)
Begin
	exec @nErrorCode = dbo.biw_ProcessInterEntityTransfers
		@pnUserIdentityId	= @pnUserIdentityId,
		@psCulture		= @psCulture,
		@pbCalledFromCentura	= @pbCalledFromCentura,
		@pnItemEntityKey	= @pnItemEntityNo,
		@pnItemTransKey		= @pnItemTransNo
End

-- Return the OPEN ITEM Numbers and the debtor numbers
If (@nErrorCode = 0)
Begin
	Select OPENITEMNO as 'OpenItemNo',
	ACCTDEBTORNO as 'DebtorNo',
        @nItemNoTo as 'OfficeItemNoTo',
        @sOfficeDescription as 'OfficeDescription'
	From OPENITEM 
	Where ITEMENTITYNO = @pnItemEntityNo
	and ITEMTRANSNO = @pnItemTransNo
End

-- Create Initial WIP Prepayment
If @nErrorCode = 0 and 
exists (select * from SITECONTROL WHERE CONTROLID = 'Cash Accounting' AND COLBOOLEAN = 1) and 
exists (select 	1 
	from	SITECONTROL 
	where   CONTROLID = 'FI WIP Payment Preference'	
	and	case when isnull(PATINDEX('%PD%', COLCHARACTER), 0) > 0 then 1 else 0 end = 1)	
Begin
	Declare @nBillWithCreditApplied  bit
	set @nBillWithCreditApplied = 0
	
	If (@nErrorCode = 0 and @nTransType in (510))
	Begin
		Set @sSQLString = "Select TOP 1 @nBillWithCreditApplied = 1
			from DEBTORHISTORY
			where REFENTITYNO = @pnItemEntityNo
			and REFTRANSNO = @pnItemTransNo
			and MOVEMENTCLASS IN (4,5)
			and LOCALVALUE <> 0"

		exec @nErrorCode=sp_executesql @sSQLString, 
					N'@pnItemEntityNo	int,
					  @pnItemTransNo	int,
					  @nBillWithCreditApplied		bit OUTPUT',
					  @pnItemEntityNo = @pnItemEntityNo,
					  @pnItemTransNo = @pnItemTransNo,
					  @nBillWithCreditApplied	= @nBillWithCreditApplied OUTPUT
	End
	

	If (@nErrorCode = 0 and @nTransType in (510) and @nBillWithCreditApplied = 1)
	Begin
		-- Create initial balance of each wip
		If @nErrorCode = 0
		Begin
			exec @nErrorCode = dbo.fi_CreateWipPayment 	
				@pnUserIdentityId	= @pnUserIdentityId,
				@psCulture		= @psCulture,
				@pbCalledFromCentura	= 0,
				@pnEntityNo		= @pnItemEntityNo, 
				@pnRefTransNo		= @pnItemTransNo	
		End
		

		If @nErrorCode = 0
		Begin
			exec @nErrorCode = dbo.fi_ApplyCreditForWip
			@pnUserIdentityId	= @pnUserIdentityId,
			@psCulture		= @psCulture,
			@pbCalledFromCentura	= 0,
			@pnItemEntityNo		= @pnItemEntityNo,
			@pnItemTransNo		= @pnItemTransNo
		End
	End
End

-- Run GL
If (@nErrorCode = 0 and @nGLJournalCreation = 1)
Begin
	If (@bDebug = 1)
	Begin
		Print 'Process GL Interface'
	End
		
	exec @nErrorCode = dbo.fi_CreateAndPostJournals
	  @pnResult = @nResult OUTPUT,
	  @pnUserIdentityId = @pnUserIdentityId,
	  @psCulture = @psCulture,
	  @pbCalledFromCentura = @pbCalledFromCentura,
	  @pnEntityNo = @pnItemEntityNo,
	  @pnTransNo = @pnItemTransNo,
	  @pnDesignation = 1,
	  @pbIncProcessedNoJournal = 1
End
Else
Begin
	-- Return an empty result for posterity.
	SELECT 0 as JOURNALCOUNT, 0 as JOURNALSPOSTED, 0 as JOURNALSREJECTED, 0 as ERRORCODE
End

-- Create Activity request (documents)
If (@bDebug = 1)
Begin
	Print 'Generate Activity Request.'
End
If @nErrorCode = 0
Begin
        exec @nErrorCode = biw_GenerateBillActivityRequest
                @pnUserIdentityId = @pnUserIdentityId,	
		@psCulture = @psCulture,
		@pbCalledFromCentura = @pbCalledFromCentura,
                @pnItemEntityNo = @pnItemEntityNo,
	        @pnItemTransNo = @pnItemTransNo,
                @pnTransType = @nTransType,
                @pnMainCaseId = @nMainCaseId,
                @pnOfficeId = @nOfficeId
End

-- Raise Event
Declare @nEventNo int

If (@nErrorCode = 0)
Begin
	Set @sSQLString = "Select @nEventNo = EVENTNO from DEBTOR_ITEM_TYPE
	Where ITEM_TYPE_ID = CASE WHEN @nTransType = 511 then 516 else @nTransType end"

	exec @nErrorCode=sp_executesql @sSQLString, 
				N'@nEventNo		int OUTPUT,
				  @nTransType	int',
				  @nEventNo = @nEventNo OUTPUT,
				  @nTransType = @nTransType

End

if (@nErrorCode = 0 and @nEventNo is not null)
Begin
	If (@bDebug = 1)
	Begin
		Print 'Insert/Update Event from DEBTOR_ITEM_TYPE'
	End

	-- Update the event if it already exists.
	Set @sSQLString = "Update CE 
		set EVENTDATE = @dtPostDate,
		OCCURREDFLAG = 1
		From CASEEVENT CE
		-- for all the cases related to the OPENITEM.
		Join (Select distinct CASEID 
			From WORKHISTORY
			Where REFENTITYNO = @pnItemEntityNo
			and REFTRANSNO = @pnItemTransNo
			and CASEID IS NOT NULL) AS OICASES on (CE.CASEID = OICASES.CASEID)
		-- for the latest cycle
		Join (select CASEID, max(cycle) AS MAXCYCLE from CASEEVENT
				WHERE EVENTNO = @nEventNo
				GROUP BY CASEID, EVENTNO) as MC on (MC.CASEID = CE.CASEID
													and MC.MAXCYCLE = CE.CYCLE)
		Where CE.EVENTNO = @nEventNo"

	exec @nErrorCode=sp_executesql @sSQLString, 
				N'@dtPostDate		datetime,
				  @pnItemEntityNo	int,
				  @pnItemTransNo	int,
				  @nEventNo			int',
				  @dtPostDate = @dtPostDate,
				  @pnItemEntityNo = @pnItemEntityNo,
				  @pnItemTransNo = @pnItemTransNo,
				  @nEventNo = @nEventNo


        If @nErrorCode = 0
        Begin
	-- Insert event where event does not yet exist
	Set @sSQLString = "Insert into CASEEVENT (CASEID, EVENTNO, CYCLE, EVENTDATE, OCCURREDFLAG)
		SELECT OICASES.CASEID, @nEventNo, 1, @dtPostDate, 1
		From 
		(Select distinct CASEID
		From WORKHISTORY
		Where REFENTITYNO = @pnItemEntityNo
		and REFTRANSNO = @pnItemTransNo
		and CASEID IS NOT NULL) AS OICASES
		LEFT JOIN CASEEVENT CE on (CE.CASEID = OICASES.CASEID
								and CE.EVENTNO = @nEventNo)
		Where CE.CASEID IS NULL"


	exec @nErrorCode=sp_executesql @sSQLString, 
				N'@dtPostDate		datetime,
				  @pnItemEntityNo	int,
				  @pnItemTransNo	int,
				  @nEventNo			int',
				  @dtPostDate = @dtPostDate,
				  @pnItemEntityNo = @pnItemEntityNo,
				  @pnItemTransNo = @pnItemTransNo,
				  @nEventNo = @nEventNo
        End
End

-- Reconcile Ledgers
-- Reconcile WIP Ledger
If (@nErrorCode = 0)
Begin
	If (@bDebug = 1)
	Begin
		Print 'Reconcile WIP Ledger.'
	End

	if not exists (
		Select * from WORKHISTORY 
		Where REFENTITYNO = @pnItemEntityNo
		and REFTRANSNO = @pnItemTransNo)
	Begin
		-- Work history does not exist
		Set @sAlertXML = dbo.fn_GetAlertXML('AC130', 'No Work History records located.',null, null, null, null, null)
			
                INSERT INTO @sReconciliationErrors
                Select @sAlertXML
	End
	
	If exists (select * from 
				(Select WH1.WHTOTAL, WH2.ENTITYNO, WH2.TRANSNO, WH2.WIPSEQNO
				From  (SELECT SUM(LOCALTRANSVALUE) AS WHTOTAL, ENTITYNO, TRANSNO, WIPSEQNO
						FROM WORKHISTORY
						GROUP BY ENTITYNO, TRANSNO, WIPSEQNO) AS WH1
				Join WORKHISTORY WH2 on WH2.ENTITYNO = WH1.ENTITYNO
									and WH2.TRANSNO = WH1.TRANSNO
									and WH2.WIPSEQNO = WH1.WIPSEQNO
				Where WH2.REFENTITYNO = @pnItemEntityNo
				and WH2.REFTRANSNO = @pnItemTransNo
				and WH2.STATUS != 0) AS WH
				Left Join WORKINPROGRESS WIP ON (WIP.ENTITYNO = WH.ENTITYNO
										AND WIP.TRANSNO = WH.TRANSNO
										AND WIP.WIPSEQNO = WH.WIPSEQNO)
				Where (WH.WHTOTAL != 0 and WIP.TRANSNO IS NULL) -- WIP is gone, but WH row not fully consumed
				or (WH.WHTOTAL != WIP.BALANCE and WIP.TRANSNO is not null) -- WIP exists and balance is out of sync with WH
				)
	Begin
		-- Work History Balances not calculated correctly
		Set @sAlertXML = dbo.fn_GetAlertXML('AC131', 'Work History records did not reconcile with Work in Progress records.',
						null, null, null, null, null)

		INSERT INTO @sReconciliationErrors
                Select @sAlertXML
	End
End

-- Reconcile Debtors Ledger (PostCondition)
If (@nErrorCode = 0)
Begin
	If (@bDebug = 1)
	Begin
		Print 'Reconcile Debtors Ledger.'
	End

	if not exists (
	Select * from DEBTORHISTORY
	Where REFENTITYNO = @pnItemEntityNo
	and REFTRANSNO = @pnItemTransNo)
	Begin
		-- Debtor history does not exist
		Set @sAlertXML = dbo.fn_GetAlertXML('AC132', 'No Debtor History records located.',
											null, null, null, null, null)
		INSERT INTO @sReconciliationErrors
                Select @sAlertXML
	End

	-- Check OPENITEM/DEBTORHISTORY balances
	If exists (select * from 
				(Select SUM(LOCALVALUE) AS LOCALTOTAL, SUM(isnull(FOREIGNTRANVALUE,0)) AS FOREIGNTOTAL,
					ITEMENTITYNO, ITEMTRANSNO, ACCTENTITYNO, ACCTDEBTORNO
					FROM DEBTORHISTORY
					WHERE STATUS != 0
					GROUP BY ITEMENTITYNO, ITEMTRANSNO, ACCTENTITYNO, ACCTDEBTORNO) AS DH
					JOIN
					-- Pick out specific items affected by this transaction.
					(SELECT DISTINCT ITEMENTITYNO, ITEMTRANSNO, ACCTENTITYNO, ACCTDEBTORNO
					from DEBTORHISTORY
					Where REFENTITYNO = @pnItemEntityNo
					and REFTRANSNO = @pnItemTransNo
					and STATUS != 0) DHITEMS on (DHITEMS.ITEMENTITYNO = DH.ITEMENTITYNO
											and DHITEMS.ITEMTRANSNO = DH.ITEMTRANSNO
											and DHITEMS.ACCTENTITYNO = DH.ACCTENTITYNO
											and DHITEMS.ACCTDEBTORNO = DH.ACCTDEBTORNO)
				Left Join OPENITEM OI ON (OI.ITEMENTITYNO = DH.ITEMENTITYNO
										AND OI.ITEMTRANSNO = DH.ITEMTRANSNO
										AND OI.ACCTENTITYNO = DH.ACCTENTITYNO
										AND OI.ACCTDEBTORNO = DH.ACCTDEBTORNO)
				Where OI.ITEMTRANSNO IS NULL -- OI does not exist
				or (DH.LOCALTOTAL != OI.LOCALBALANCE and OI.ITEMTRANSNO is not null) -- OI exists and balance is out of sync with DH
				or (DH.FOREIGNTOTAL != OI.FOREIGNBALANCE and OI.ITEMTRANSNO is not null)
				)
	Begin
		-- Debtor History Balances have not calculated correctly
		Set @sAlertXML = dbo.fn_GetAlertXML('AC133', 'Debtor History records did not reconcile with Open Item balance.',
											null, null, null, null, null)
		INSERT INTO @sReconciliationErrors
                Select @sAlertXML
	End

	-- Compare to cases
	If (@bDebug = 1)
	Begin
		Print 'Compare to cases.'
	End
	
	If exists( select * from OPENITEMCASE OIC
			JOIN OPENITEM OI ON OI.ITEMENTITYNO = OIC.ITEMENTITYNO
					and OI.ITEMTRANSNO = OIC.ITEMTRANSNO
					and OI.ACCTENTITYNO = OIC.ACCTENTITYNO
					and OI.ACCTDEBTORNO = OIC.ACCTDEBTORNO
			WHERE OI.ITEMENTITYNO = @pnItemEntityNo
			and OI.ITEMTRANSNO = @pnItemTransNo )
	and exists (
		Select *
		from (SELECT DISTINCT ITEMENTITYNO, ITEMTRANSNO, ACCTENTITYNO, ACCTDEBTORNO
					from DEBTORHISTORY
					Where REFENTITYNO = @pnItemEntityNo
					and REFTRANSNO = @pnItemTransNo
					and STATUS != 0) as DH
		Join OPENITEM OI on (OI.ITEMENTITYNO = DH.ITEMENTITYNO
								and OI.ITEMTRANSNO = DH.ITEMTRANSNO
								and OI.ACCTENTITYNO = DH.ACCTENTITYNO
								and OI.ACCTDEBTORNO = DH.ACCTDEBTORNO)
		Left Join (SELECT SUM(LOCALBALANCE) AS LOCALVALUETOTAL, ITEMENTITYNO, ITEMTRANSNO, ACCTENTITYNO, ACCTDEBTORNO
							FROM OPENITEMCASE
							GROUP BY ITEMENTITYNO, ITEMTRANSNO, ACCTENTITYNO, ACCTDEBTORNO) as OIC
									on (OIC.ITEMENTITYNO = OI.ITEMENTITYNO
										and OIC.ITEMTRANSNO = OI.ITEMTRANSNO
										and OIC.ACCTENTITYNO = OI.ACCTENTITYNO
										and OIC.ACCTDEBTORNO = OI.ACCTDEBTORNO)
		Left Join (SELECT SUM(LOCALVALUE) AS LOCALVALUETOTAL, ITEMENTITYNO, ITEMTRANSNO, ACCTENTITYNO, ACCTDEBTORNO
							FROM DEBTORHISTORYCASE
							GROUP BY ITEMENTITYNO, ITEMTRANSNO, ACCTENTITYNO, ACCTDEBTORNO) as DHC
									on (DHC.ITEMENTITYNO = OI.ITEMENTITYNO
										and DHC.ITEMTRANSNO = OI.ITEMTRANSNO
										and DHC.ACCTENTITYNO = OI.ACCTENTITYNO
										and DHC.ACCTDEBTORNO = OI.ACCTDEBTORNO)
		-- check OPENITEMCASE / DEBTORHISTORYCASE balance with OPENITEM'S LOCALBALANCE
		Where ((OI.LOCALBALANCE != OIC.LOCALVALUETOTAL AND OIC.ITEMTRANSNO IS NOT NULL)
			or
			(OI.LOCALBALANCE != DHC.LOCALVALUETOTAL AND DHC.ITEMTRANSNO IS NOT NULL))
	)	
	Begin
		-- OPENITEMCASE / DEBTORHISTORYCASE does not balance with OPENITEM
		Set @sAlertXML = dbo.fn_GetAlertXML('AC134', 'Open Item Case / Debtor History Case records did not reconcile with Open Item balance.',
											null, null, null, null, null)
		INSERT INTO @sReconciliationErrors
                Select @sAlertXML
	End

	-- Compare to Accounts
	If (@bDebug = 1)
	Begin
		Print 'Compare to Accounts.'
	End
	
	If not exists (Select * from SITECONTROL where CONTROLID = 'EXTACCOUNTSFLAG' AND COLBOOLEAN = 1) -- External Accounting system
	and exists(
		Select *
		from DEBTORHISTORY DH
		Join (Select sum(LOCALBALANCE) AS LOCALBALANCETOTAL, ACCTENTITYNO, ACCTDEBTORNO
			From OPENITEM
			Where STATUS IN (1,2)
			Group by ACCTENTITYNO, ACCTDEBTORNO) AS OIAB
						on (OIAB.ACCTENTITYNO = DH.ACCTENTITYNO
							and OIAB.ACCTDEBTORNO = DH.ACCTDEBTORNO)
		Left join ACCOUNT A on (A.ENTITYNO = DH.ACCTENTITYNO and A.NAMENO = DH.ACCTDEBTORNO)
		
		Where DH.REFENTITYNO = @pnItemEntityNo
		and DH.REFTRANSNO = @pnItemTransNo
		and (A.NAMENO IS NULL -- THERE MUST BE AN ACCOUNT
			or OIAB.LOCALBALANCETOTAL != A.BALANCE -- BALANCES MUST BE EQUAL
			)
	)	
	Begin
		-- OPENITEMCASE / DEBTORHISTORYCASE does not balance with OPENITEM
		Set @sAlertXML = dbo.fn_GetAlertXML('AC135', 'Total OpenItem balance does not match Account Balance.',
											null, null, null, null, null)
		INSERT INTO @sReconciliationErrors
                Select @sAlertXML
	End
End  

Select ReconciliationErrorXml from @sReconciliationErrors                                                                                                                     

Return @nErrorCode
GO

Grant execute on dbo.biw_FinaliseOpenItem to public
GO