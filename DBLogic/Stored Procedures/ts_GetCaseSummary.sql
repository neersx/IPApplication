-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ts_GetCaseSummary
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ts_GetCaseSummary]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ts_GetCaseSummary.'
	Drop procedure [dbo].[ts_GetCaseSummary]
End
Print '**** Creating Stored Procedure dbo.ts_GetCaseSummary...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.ts_GetCaseSummary
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pbCalledFromCentura	bit		= 0,
	@pnCaseKey		int,			-- Mandatory
	@pbCanViewBillingHistory bit		= null,
	@pbCanViewReceivableItems bit		= null
)
as
-- PROCEDURE:	ts_GetCaseSummary
-- VERSION:	10
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Get case summary which are relevant when entering time.

-- MODIFICATIONS :
-- Date		Who	Change		Version	Description
-- -----------	-------	------		-------	----------------------------------------------- 
-- 6 SEP 2010	SF	RFC9717		1	Procedure created
-- 10-Feb-2011	AT	RFC10207	2	Optimised case billing information.
-- 28-Apr-2011	SF	RFC10349	3	Return case narrative
-- 13-May-2011	SF	RFC10627	4	Timesheet Case Summary should display unbilled WIP
-- 22-Jul-2011	SF	RFC10045	5	Only evaluate ViewBillingHistory permission if not provided.
-- 01-Dec-2011	SF	RFC11551	6	Return Receivable Balance and Receipt Details.
-- 05 Jul 2013	vql	R13629		7	Remove string length restriction and use nvarchar on datetime conversions using 106 format.
-- 26 Jun 2014	LP	R33805		8	Fixed syntax error when @pbCanViewReceivableItems is NULL.
-- 02 Nov 2015	vql	R53910		9	Adjust formatted names logic (DR-15543).
-- 14 Nov 2018  AV  75198/DR-45358	10   Date conversion errors when creating cases and opening names in Chinese DB

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare	@nErrorCode			int
Declare @sSQLString			nvarchar(4000)

Declare @sLookupCulture			nvarchar(10)
Declare @bHasBillingHistorySubject	bit
Declare @bHasReceivableItemsSubject	bit
Declare @bExternalUser			bit
Declare @sLocalCurrencyCode		nvarchar(3)
Declare @nLocalDecimalPlaces		tinyint
Declare @nUnbilledWip			decimal(11,2)
Declare @dtLastInvoicedDate		datetime
Declare @sLastInvoicedNo		nvarchar(12)
Declare @sLastInvoicedEntity		int
Declare @dtToday			datetime
Declare @nDebtorKey			int

Declare @tbCaseNameResultSet table
	(
		CASEID			int						NOT NULL,
		NAMETYPE		nvarchar(3)	collate database_default	NOT NULL,
		NAMENO			int						NOT NULL,
		SEQUENCE		smallint					NOT NULL,
		NAMETYPEDESCRIPTION	nvarchar(50)	collate database_default	NOT NULL,
		NAME			nvarchar(512)	collate database_default	NOT NULL,
		NAMECODE		nvarchar(20)	collate database_default	NULL,
		REFERENCENO		nvarchar(80)	collate database_default	NULL,
		ROWKEY			nvarchar(512)	collate database_default	NOT NULL,
		ISVISIBLE		bit						NOT NULL,
		LASTRECEIPTQUERIED	bit						NOT NULL,
		RECEIVABLEBALANCE	decimal(11,2)					NULL,
		LASTRECEIPTDATE		datetime					NULL,
		LASTRECEIPTLOCAL	decimal(11,2)					NULL,
		LASTRECEIPTFOREIGN	decimal(11,2)					NULL,		
		FOREIGNCURRENCYCODE	nvarchar(3)	collate database_default	NULL,
		FOREIGNCURRENCYDECIMALS	tinyint						NULL
	)


-- Initialise variables
Set     @nErrorCode = 0
Set 	@bExternalUser = 0
Set	@dtToday		= getdate()
Set	@sLookupCulture = dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)
Set	@bHasBillingHistorySubject = @pbCanViewBillingHistory
Set	@bHasReceivableItemsSubject = @pbCanViewReceivableItems

-- Determine if the user is internal or external
If @nErrorCode = 0
Begin		
	Set @sSQLString = "
	Select	@bExternalUser = ISEXTERNALUSER
	from USERIDENTITY
	where IDENTITYID = @pnUserIdentityId"

	Exec  @nErrorCode = sp_executesql @sSQLString,
				N'@bExternalUser	bit			OUTPUT,
				  @pnUserIdentityId	int',
				  @bExternalUser	= @bExternalUser	OUTPUT,
				  @pnUserIdentityId	= @pnUserIdentityId
End


If @nErrorCode=0
and @pbCanViewBillingHistory is null
Begin
	Set @sSQLString="
	Select	@bHasBillingHistorySubject = ISNULL(IsAvailable, 0) 
	from dbo.fn_GetTopicSecurity(@pnUserIdentityId, 101, default, @dtToday)"

	exec @nErrorCode=sp_executesql @sSQLString,
				N'@bHasBillingHistorySubject	bit				OUTPUT,
				  @pnUserIdentityId		int,
				  @dtToday			datetime',
				  @bHasBillingHistorySubject	= @bHasBillingHistorySubject 	OUTPUT,
				  @pnUserIdentityId		= @pnUserIdentityId,	
				  @dtToday			= @dtToday
End

If @nErrorCode = 0
and @pbCanViewReceivableItems is null
Begin
	-- Is the Receivable Items topic available?
	Set @sSQLString = "
	Select @bHasReceivableItemsSubject = ISNULL(IsAvailable,0)
	from dbo.fn_GetTopicSecurity(@pnUserIdentityId, 200, default, @dtToday)"

	exec @nErrorCode=sp_executesql @sSQLString,
				N'@bHasReceivableItemsSubject	bit			OUTPUT,
				  @pnUserIdentityId		int,
				  @dtToday			datetime',
				  @bHasReceivableItemsSubject	= @bHasReceivableItemsSubject	OUTPUT,
				  @pnUserIdentityId		= @pnUserIdentityId,
				  @dtToday			= @dtToday
End

-- Retrieve Local Currency information
If @nErrorCode=0
and (	@bHasBillingHistorySubject=1
or	@bHasReceivableItemsSubject=1)
Begin
	exec @nErrorCode = ac_GetLocalCurrencyDetails 	@psCurrencyCode		= @sLocalCurrencyCode	OUTPUT,
							@pnDecimalPlaces 	= @nLocalDecimalPlaces	OUTPUT,
							@pnUserIdentityId 	= @pnUserIdentityId,
							@pbCalledFromCentura	= 0
End


If @nErrorCode = 0
and @bHasBillingHistorySubject=1
Begin
	Set @sSQLString="
	SELECT @nUnbilledWip = sum(WH.BALANCE)
		FROM WORKINPROGRESS WH
		where WH.CASEID = @pnCaseKey
		and WH.STATUS<>0"
		
	exec @nErrorCode = sp_executesql @sSQLString,
					N'@nUnbilledWip	decimal(11,2)	output,
					  @pnCaseKey	int',
					  @nUnbilledWip = @nUnbilledWip output,
					  @pnCaseKey = @pnCaseKey
End

If @nErrorCode = 0
and @bHasBillingHistorySubject=1
Begin
	Set @sSQLString="
	Select
	@dtLastInvoicedDate = OI.ITEMDATE,
	@sLastInvoicedNo = OI.OPENITEMNO,
	@sLastInvoicedEntity = OI.ITEMENTITYNO
	from  OPENITEM OI
	WHERE OI.ITEMTRANSNO in (SELECT REFTRANSNO
				FROM WORKHISTORY 
				WHERE CASEID = @pnCaseKey)
	and OI.STATUS = 1
	AND OI.ASSOCOPENITEMNO IS NULL
	AND OI.ITEMTYPE IN (510,513)
	ORDER BY OI.ITEMDATE ASC, OPENITEMNO ASC"
		
	exec @nErrorCode = sp_executesql @sSQLString,
					N'@dtLastInvoicedDate	datetime	output,
					  @sLastInvoicedNo	nvarchar(12)	output,
					  @sLastInvoicedEntity	int		output,
					  @pnCaseKey		int',
					  @dtLastInvoicedDate	= @dtLastInvoicedDate	output,
					  @sLastInvoicedNo	= @sLastInvoicedNo	output,
					  @sLastInvoicedEntity	= @sLastInvoicedEntity	output,
					  @pnCaseKey		= @pnCaseKey
End

	
-- Case result set
If @nErrorCode = 0
Begin
	Set @sSQLString = 
	"Select"+char(10)+
	"C.CASEID as CaseKey,"+char(10)+
	"C.IRN as CaseReference,"+char(10)+
	dbo.fn_SqlTranslatedColumn('CASES','TITLE',null,'C',@sLookupCulture,@pbCalledFromCentura)+" as Title,"+char(10)+
	dbo.fn_SqlTranslatedColumn('STATUS','INTERNALDESC',null,'ST',@sLookupCulture,@pbCalledFromCentura)+" as CaseStatusDescription,"+char(10)+
	dbo.fn_SqlTranslatedColumn('STATUS','INTERNALDESC',null,'RS',@sLookupCulture,@pbCalledFromCentura)+" as RenewalStatusDescription,"+char(10)+	
	"@nUnbilledWip				as WIPTotal,"+char(10)+
	"@dtLastInvoicedDate	as LastInvoiceDate,"+CHAR(10)+
	"@sLastInvoicedNo	as LastInvoiceNo,"+CHAR(10)+
	"@sLastInvoicedEntity	as LastInvoiceEntity,"+CHAR(10)+
	"@sLocalCurrencyCode	as LocalCurrencyCode,"+CHAR(10)+
	"@nLocalDecimalPlaces	as LocalDecimalPlaces"+CHAR(10)+
	"from CASES C"+char(10)+
	"left join PROPERTY P 		on (P.CASEID=C.CASEID)"+char(10)+
	"left join STATUS RS 		on (RS.STATUSCODE=P.RENEWALSTATUS)"+char(10)+
	"left join STATUS ST 		on (ST.STATUSCODE=C.STATUSCODE)"+char(10)+
	"Where C.CASEID = @pnCaseKey"

	exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnCaseKey		 	int,
					  @nUnbilledWip			decimal(11,2),
					  @dtLastInvoicedDate		datetime,
					  @sLastInvoicedNo		nvarchar(12),
					  @sLastInvoicedEntity		int,
					  @sLocalCurrencyCode		nvarchar(3),
					  @nLocalDecimalPlaces		tinyint',
					  @pnCaseKey		 	= @pnCaseKey,					  
					  @nUnbilledWip			= @nUnbilledWip,
					  @dtLastInvoicedDate		= @dtLastInvoicedDate,
					  @sLastInvoicedNo		= @sLastInvoicedNo,
					  @sLastInvoicedEntity		= @sLastInvoicedEntity,
					  @sLocalCurrencyCode		= @sLocalCurrencyCode,
					  @nLocalDecimalPlaces		= @nLocalDecimalPlaces
End

-- CaseName result set
If @nErrorCode = 0
Begin
	insert into @tbCaseNameResultSet
	(
		CASEID,
		NAMETYPE,
		NAMENO,
		SEQUENCE,
		NAMETYPEDESCRIPTION,
		NAME,
		NAMECODE,
		REFERENCENO,
		ROWKEY,
		LASTRECEIPTQUERIED,
		ISVISIBLE
	)
	select CN.CASEID,
		CN.NAMETYPE,
		CN.NAMENO,
		CN.SEQUENCE,
		NT.DESCRIPTION,
		dbo.fn_FormatNameUsingNameNo(N.NAMENO, null),
		N.NAMECODE,
		CN.REFERENCENO,
		convert(nvarchar(11),CN.CASEID)+'^'+ CN.NAMETYPE+'^'+
		convert(nvarchar(11),CN.NAMENO)+'^'+ convert(nvarchar(11),CN.SEQUENCE),
		0,
		CASE WHEN CN.NAMETYPE = 'D' THEN 0 ELSE 1 END 
	from CASENAME CN
	join dbo.fn_FilterUserNameTypes(@pnUserIdentityId,@sLookupCulture,@bExternalUser,@pbCalledFromCentura) NT 
					on (NT.NAMETYPE = CN.NAMETYPE)
	join NAME N			on (N.NAMENO = CN.NAMENO)		
	where CN.CASEID = @pnCaseKey
	and CN.NAMETYPE in ('I', 'O', 'SIG', 'EMP', 'D')
	and (CN.EXPIRYDATE is null or CN.EXPIRYDATE>getdate())
	order by CASE	CN.NAMETYPE 			/* strictly only for orderby, not needed by CASEDATA */
		  	WHEN	'I'	THEN 0		/* Instructor */
		  	WHEN 	'A'	THEN 1		/* Agent */
		  	WHEN 	'O'	THEN 2		/* Owner */
			WHEN	'EMP'	THEN 3		/* Responsible Staff */
			WHEN	'SIG'	THEN 4		/* Signotory */
			ELSE 5				/* others, order by description and sequence */
		 END, CN.SEQUENCE

	Set @nErrorCode = @@ERROR

	-- populate last receipt details for all debtors in the case name result set
	-- only if the caller has receivable items subject security permission
	If @nErrorCode = 0
	and @bHasReceivableItemsSubject = 1
	Begin
		-- get the first debtor to populate last receipt details for
		Select  TOP 1 @nDebtorKey = NAMENO
		from	@tbCaseNameResultSet
		where	NAMETYPE = 'D'
		and	LASTRECEIPTQUERIED = 0
		
		While (@nDebtorKey is not null)
		Begin
			-- Populate Last Receipt Details for the current debtor
			Update @tbCaseNameResultSet
				SET	LASTRECEIPTDATE = Receipt.LASTRECEIPTDATE,
					FOREIGNCURRENCYCODE = Receipt.FOREIGNCURRENCYCODE,
					FOREIGNCURRENCYDECIMALS = Receipt.FOREIGNCURRENCYDECIMALPLACES,
					LASTRECEIPTLOCAL = Receipt.LASTRECEIPTLOCAL,
					LASTRECEIPTFOREIGN = Receipt.LASTRECEIPTFOREIGN,
					LASTRECEIPTQUERIED = 1,
					RECEIVABLEBALANCE = Receivable.BALANCE
			from	@tbCaseNameResultSet NAMES
			left join (		
				Select TOP 1 DH.TRANSDATE	as LASTRECEIPTDATE,
					     DH.CURRENCY	as FOREIGNCURRENCYCODE, 
					     DH.LOCALVALUE*-1	as LASTRECEIPTLOCAL,
					     CASE WHEN DH.FOREIGNTRANVALUE = null
							THEN null		
						ELSE DH.FOREIGNTRANVALUE*-1
					     END		as LASTRECEIPTFOREIGN,
					     CU.DECIMALPLACES	as FOREIGNCURRENCYDECIMALPLACES,
					     @nDebtorKey	as DEBTORNO
				from DEBTORHISTORY DH 
				left join CURRENCY CU on (CU.CURRENCY = DH.CURRENCY)
				where DH.ACCTDEBTORNO = @nDebtorKey
				and DH.MOVEMENTCLASS = 2 
				and DH.STATUS = 1 
				and DH.TRANSTYPE = 520 
				order by DH.POSTDATE DESC, DH.TRANSDATE DESC) as Receipt 
			on (Receipt.DEBTORNO = NAMES.NAMENO 
				and NAMES.NAMETYPE = 'D')
			left join (
				Select 
				SUM(ISNULL(O.LOCALBALANCE,0))	as BALANCE,
				@nDebtorKey			as DEBTORNO
				from OPENITEM O
				left join SITECONTROL SC	on (SC.CONTROLID = 'Trading Terms')
				where O.STATUS<>0
				and O.ITEMDATE<=getdate()
				and O.CLOSEPOSTDATE>=convert(nvarchar,dateadd(day, 1, getdate()),112)
				and O.ACCTDEBTORNO = @nDebtorKey
				group by SC.COLINTEGER)		as Receivable
			on (Receivable.DEBTORNO = NAMES.NAMENO 
				and NAMES.NAMETYPE = 'D')
			where	NAMES.NAMENO = @nDebtorKey
			and	NAMES.NAMETYPE = 'D'
	
			Select @nErrorCode = @@ERROR, 
				@nDebtorKey = null
								
			-- set up the next debtor that hasn't got the last receipt details populated
			Select  TOP 1 @nDebtorKey = NAMENO
			from	@tbCaseNameResultSet
			where	NAMETYPE = 'D'
			and	LASTRECEIPTQUERIED = 0
		End
	End

	If (@nErrorCode = 0)
	and @bHasReceivableItemsSubject <> 1
	Begin	
		delete 
		from @tbCaseNameResultSet 
		where NAMETYPE = 'D'
	End
	
	-- now return the case name results set
	If (@nErrorCode = 0)
	Begin		
		Select  CN.CASEID			as CaseKey,
			CN.NAMETYPE			as NameTypeKey,
			CN.NAMENO 			as NameKey,
			CN.SEQUENCE			as NameSequence,
			CN.NAMETYPEDESCRIPTION		as NameTypeDescription,
			CN.NAME				as Name,
			CN.NAMECODE			as NameCode,
			CN.REFERENCENO			as ClientReferenceNo,
			CN.ROWKEY			as RowKey,
			CN.ISVISIBLE			as IsVisible,
			CN.RECEIVABLEBALANCE		as ReceivableBalance,
			CN.LASTRECEIPTDATE		as LastReceiptDate,
			CN.LASTRECEIPTLOCAL		as LastReceiptLocal,
			CN.LASTRECEIPTFOREIGN		as LastReceiptForeign,
			CN.FOREIGNCURRENCYCODE		as ForeignCurrencyCode,
			CN.FOREIGNCURRENCYDECIMALS	as ForeignCurrencyDecimalPlaces
		from @tbCaseNameResultSet CN
	End
End

-- CaseNarrative result set
If @nErrorCode = 0
Begin
	exec @nErrorCode = dbo.ts_GetCaseBillingNarrative
		@pnUserIdentityId		= @pnUserIdentityId,
		@psCulture				= @psCulture,
		@pbCalledFromCentura	= @pbCalledFromCentura,
		@pnCaseKey				= @pnCaseKey
End

Return @nErrorCode
GO

Grant execute on dbo.ts_GetCaseSummary to public
GO
