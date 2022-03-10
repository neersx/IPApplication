-----------------------------------------------------------------------------------------------------------------------------
-- Creation of dbo.ar_ListNamePrepaymentItems 
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ar_ListNamePrepaymentItems ]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ar_ListNamePrepaymentItems .'
	Drop procedure [dbo].[ar_ListNamePrepaymentItems ]
End
Print '**** Creating Stored Procedure dbo.ar_ListNamePrepaymentItems ...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO

CREATE PROCEDURE dbo.ar_ListNamePrepaymentItems 
(
	@pnRowCount		int		= null	output,
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pnEntityKey 		int,		-- Mandatory
	@pnNameKey		int, 		-- Mandatory
	@psCurrencyCode		nvarchar(3)	= null,
	@pbCalledFromCentura	bit 		= 0
)
AS
-- PROCEDURE:	ar_ListNamePrepaymentItems 
-- VERSION:	21
-- SCOPE:	Client WorkBench
-- DESCRIPTION:	Populates NamePrepaymentItemsData dataset. Returns a list of the outstanding 
--		prepayment items for a particular client name, entity and currency. Prepayments
--		may be created for either a Debtor or by Case. Where a single prepayment is split
--		among multiple cases, the balance for each case is shown.  
-- COPYRIGHT:	Copyright 1993 - 2004 CPA Software Solutions (Australia) Pty Limited-- MODIFICTIONS :
-- MODIFICATIONS :
-- Date		Who	Number	Version	Change
-- ------------	-------	------	-------	----------------------------------------------- 
-- 11-Sep-2003  TM		1	Procedure created
-- 18-Sep-2003	TM		2	RFC403 Prepayment Items web part. Extract YourReference the way
--					cwb_ListWhatsNew does it. 
-- 19-Sep-2003	TM		3	RFC403 Prepayment Items web part. Remove 'distinct' from the second
--					result set. 
-- 03-Oct-2003	MF	RFC519	4	Performance improvements to fn_FilterUserCases & fn_FilterUserNames
-- 07-Oct-2003	TM	RFC403	5 	Prepayment Items web part. Make the row count the 
--					first parameter and name it @pnRowCount.
-- 13-Oct-2003	MF	RFC533	6	If the user is not on USERIDENTITY table then treat as if External User
-- 24-Oct-2003	TM	RFC403	7	In the "PrepaymentItem Result Set" remove "and O.ITEMDATE<=getdate()" and add: 
--					"AND O.LOCALBALANCE < 0".
-- 06-Dec-2003	JEK	RFC406	8	Implement topic level security.
-- 12-Dec-2003	JEK	RFC737	9	Prepayments should be shown for all cases regardless of security so that
--					the total matches what is shown for the name.
-- 18-Feb-2004	TM	RFC976	10	Add the @pbCalledFromCentura  = default parameter to the calling code for relevant functions.
-- 04-Mar-2004	TM	RFC1032	11	Pass NULL as the @pnCaseKey to the fn_FilterUserCases.
-- 02-Sep-2004	TM	RFC1538	12	Add a new Notes column.
-- 20-May-2005	TM	RFC2594	13	Only perform one lookup of the Prepayments and Receivable Items subjects.
-- 01-Nov-2005	TM	RFC2868	14	Add new PropertyTypeDescription, IsForRenewalWork and IsForNonRenewalWork columns 
--					to the PrepaymentItem result set.
-- 24 Nov 2005	LP	RFC1017	15	Extract @nCurrencyDecimalPlaces and @sCurrencyCode from 
--					ac_GetLocalCurrencyDetails and add to the Header result set
-- 14 Jul 2006	SW	RFC3828	16	Pass getdate() to fn_Permission..
-- 06 Sep 2006	AU	RFC4268	17	Return RowKey and NameKey in PrepaymentItem result-set.
-- 04 Mar 2013	ASH	R12380	18	Use CASEID as a part of RowKey in prepayments result set When CASEID is not null.
-- 15 Apr 2013	DV	R13270	19	Increase the length of nvarchar to 11 when casting or declaring integer
-- 05 Nov 2015	LP	R41553	20	Re-instate CASEID as part of RowKey.
-- 02 Nov 2015	vql	R53910	21	Adjust formatted names logic (DR-15543).

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare @nErrorCode		int

Declare @sSQLString 		nvarchar(4000)
Declare @bIsExternalUser	bit
Declare @bIsPrepaymentsRequired bit

Declare @sLookupCulture		nvarchar(10)

Declare @sLocalCurrencyCode	nvarchar(3)
Declare @nLocalDecimalPlaces	tinyint
Declare @dtToday		datetime

Set 	@nErrorCode 		= 0
Set	@pnRowCount		= 0
Set 	@sLookupCulture 	= dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)
Set	@dtToday		= getdate()

-- Retrieve Local Currency information
If @nErrorCode=0
Begin
	exec @nErrorCode = ac_GetLocalCurrencyDetails 	@psCurrencyCode		= @sLocalCurrencyCode	OUTPUT,
							@pnDecimalPlaces 	= @nLocalDecimalPlaces	OUTPUT,
							@pnUserIdentityId 	= @pnUserIdentityId,
							@pbCalledFromCentura	= @pbCalledFromCentura
End

-- We need to determine if the user is external and 
-- check whether the Prepayments information is required

If @nErrorCode=0
Begin
	Set @sSQLString="
	Select	@bIsExternalUser=UI.ISEXTERNALUSER,
		@bIsPrepaymentsRequired=CASE WHEN TS.IsAvailable = 1 THEN 1 ELSE 0 END
	from USERIDENTITY UI
	left join dbo.fn_GetTopicSecurity(@pnUserIdentityId, 201, default, @dtToday) TS
					on (TS.IsAvailable=1)
	where UI.IDENTITYID=@pnUserIdentityId"

	exec @nErrorCode=sp_executesql @sSQLString,
				N'@bIsExternalUser		bit			OUTPUT,
				  @bIsPrepaymentsRequired	bit			OUTPUT,
				  @pnUserIdentityId		int,
				  @dtToday			datetime',
				  @bIsExternalUser		=@bIsExternalUser	OUTPUT,
				  @bIsPrepaymentsRequired	=@bIsPrepaymentsRequired OUTPUT,
				  @pnUserIdentityId		=@pnUserIdentityId,
				  @dtToday			=@dtToday

	If @bIsExternalUser is null
		Set @bIsExternalUser=1
End

-- Populating Header Result Set

If @nErrorCode=0
Begin
	Set @sSQLString="
	Select 
	N.NAMENO		as 'NameKey',
	dbo.fn_FormatNameUsingNameNo(N.NAMENO, COALESCE(N.NAMESTYLE, NN.NAMESTYLE, 7101)) 
				as 'Name',
	EN.NAMENO		as 'EntityKey',
	dbo.fn_FormatNameUsingNameNo(EN.NAMENO, COALESCE(EN.NAMESTYLE, NN1.NAMESTYLE, 7101))
	 			as 'EntityName',
	@psCurrencyCode		as 'RequestedCurrencyCode',
	@sLocalCurrencyCode	as 'LocalCurrencyCode',
	@nLocalDecimalPlaces	as 'LocalDecimalPlaces'
	from NAME N"+

	-- If the user is an External User then require an additional join to the Filtered Names to
	-- ensure the user has access
	CASE WHEN(@bIsExternalUser=1)
		THEN char(10)+"	join dbo.fn_FilterUserNames(@pnUserIdentityId, 1) FN on (FN.NAMENO=N.NAMENO)"
	END	
	+"
	join NAME EN 	 		on (EN.NAMENO = @pnEntityKey)
	left join COUNTRY NN1		on (NN1.COUNTRYCODE =EN.NATIONALITY)
	left join COUNTRY NN		on (NN.COUNTRYCODE = N.NATIONALITY)
	where N.NAMENO = @pnNameKey
	-- Return an empty result set if the user does not have access to the Prepayments topic
	and @bIsPrepaymentsRequired = 1"
		
	exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnNameKey		int,
					  @pnUserIdentityId	int,
					  @psCurrencyCode	nvarchar(3),
					  @pnEntityKey		int,
					  @bIsPrepaymentsRequired bit,
					  @sLocalCurrencyCode	nvarchar(3),
					  @nLocalDecimalPlaces	tinyint',
					  @pnNameKey		=@pnNameKey,
					  @pnEntityKey		=@pnEntityKey,
					  @pnUserIdentityId	=@pnUserIdentityId,
					  @psCurrencyCode	=@psCurrencyCode,
					  @bIsPrepaymentsRequired=@bIsPrepaymentsRequired,
					  @sLocalCurrencyCode	= @sLocalCurrencyCode,
					  @nLocalDecimalPlaces	= @nLocalDecimalPlaces

End

-- Populating PrepaymentItem Result Set

If @nErrorCode=0
Begin
	Set @sSQLString="
	Select
 	CAST(O.ITEMENTITYNO 	as nvarchar(11))+'^'+
	CAST(O.ITEMTRANSNO 	as nvarchar(11))+'^'+
	CAST(O.ACCTENTITYNO 	as nvarchar(11))+'^'+
	CAST(O.ACCTDEBTORNO 	as nvarchar(11))+'^'+
	CAST(OIC.CASEID		as nvarchar(11))
				as 'RowKey',
	@pnNameKey		as 'NameKey', 
	O.OPENITEMNO		as 'OpenItemNo',
	O.ITEMDATE		as 'ItemDate', 
	C.CASEID		as 'CaseKey',
	C.CURRENTOFFICIALNO 	as 'CurrentOfficialNumber',"+

	-- If the user is an External User then return their Reference
	CASE WHEN(@bIsExternalUser=1)
		THEN char(10)+"	FC.CLIENTREFERENCENO	as 'YourReference',"
		ELSE char(10)+"	NULL			as 'YourReference',"
	END
	
	+"
	C.IRN 			as 'OurReference',
	--'UtilisedPercentage' should be round to integer and it should be positive 
	-- by using ABS() function
	ABS(  
	convert(int,
	round(
        ((ISNULL(CASE WHEN OIC.CASEID IS NULL THEN O.LOCALVALUE     ELSE OIC.LOCALVALUE     END, 
		 CASE WHEN OIC.CASEID IS NULL THEN O.FOREIGNVALUE   ELSE OIC.FOREIGNVALUE   END) 
	  -
	  ISNULL(CASE WHEN OIC.CASEID IS NULL THEN O.LOCALBALANCE   ELSE OIC.LOCALBALANCE   END,
		 CASE WHEN OIC.CASEID IS NULL THEN O.FOREIGNBALANCE ELSE OIC.FOREIGNBALANCE END)
	)
	/ 
	-- Avoid 'divide by zero' by substituting 0 with 1
 	CASE WHEN(O.LOCALVALUE = 0  	  or OIC.LOCALVALUE = 0 
		  or O.FOREIGNVALUE = 0 or OIC.FOREIGNVALUE = 0) 
	     THEN 1
	     ELSE ISNULL(CASE WHEN OIC.CASEID IS NULL THEN O.LOCALVALUE   ELSE OIC.LOCALVALUE   END,
	  	         CASE WHEN OIC.CASEID IS NULL THEN O.FOREIGNVALUE ELSE OIC.FOREIGNVALUE END)
	END)*100, 0)))		as 'UtilisedPercentage',
	ISNULL(O.CURRENCY, @sLocalCurrencyCode)
				as 'ItemCurrencyCode',
	(CASE WHEN OIC.CASEID IS NULL THEN O.LOCALBALANCE 
	      ELSE OIC.LOCALBALANCE END)*-1 		
				as 'LocalBalance',
  	(CASE WHEN OIC.CASEID IS NULL THEN O.FOREIGNBALANCE 
	      ELSE OIC.FOREIGNBALANCE END)*-1 
				as 'ForeignBalance',
	CASE WHEN @bIsExternalUser = 0
	     THEN ISNULL(O.REFERENCETEXT, O.LONGREFTEXT)
	     ELSE NULL
	END			as  'Notes',
	"+dbo.fn_SqlTranslatedColumn('PROPERTYTYPE','PROPERTYNAME',null,'PT',@sLookupCulture,@pbCalledFromCentura)+"	
				  	as PropertyTypeDescription,
	CASE WHEN (O.PAYFORWIP = 'R' OR O.PAYFORWIP IS NULL) THEN CAST(1 as bit) ELSE CAST(0 as bit) END
				as 'IsForRenewalWork',
	CASE WHEN (O.PAYFORWIP = 'N' OR O.PAYFORWIP IS NULL) THEN CAST(1 as bit) ELSE CAST(0 as bit) END
				as 'IsForNonRenewalWork'	
	from NAME N"+

	-- If the user is an External User then require an additional join to the Filtered Names to
	-- ensure the user has access
	CASE WHEN(@bIsExternalUser=1)
		THEN char(10)+"	join dbo.fn_FilterUserNames(@pnUserIdentityId, 1) FN on (FN.NAMENO=N.NAMENO)"
	END	
		
	+"
	join  OPENITEM O		on (O.ACCTDEBTORNO = N.NAMENO)  
	left join OPENITEMCASE OIC 	on (OIC.ITEMENTITYNO = O.ITEMENTITYNO     
				   	and OIC.ITEMTRANSNO  = O.ITEMTRANSNO
				   	and OIC.ACCTENTITYNO = O.ACCTENTITYNO
				   	and OIC.ACCTDEBTORNO = O.ACCTDEBTORNO )
	left join CASES C		on (C.CASEID=OIC.CASEID)"+

	-- If the user is an External User then we need to add the additional join 
	-- to the filtered list of Cases to ensure that the user actually has access
	-- to the Case
	CASE WHEN(@bIsExternalUser=1)
		THEN char(10)+"	left join dbo.fn_FilterUserCases(@pnUserIdentityId, 1, null) FC 
					on (FC.CASEID=C.CASEID)"
	END

	+"
	left join PROPERTYTYPE PT	on (PT.PROPERTYTYPE = O.PAYPROPERTYTYPE)
	where N.NAMENO = @pnNameKey 
	and (OIC.CASEID IS NULL 
	or OIC.LOCALBALANCE < 0) 
	and O.STATUS in (1,2)
	and O.ITEMTYPE = 523 
	and O.LOCALBALANCE < 0 
	and O.ACCTENTITYNO = @pnEntityKey 
	and (ISNULL(O.CURRENCY, @sLocalCurrencyCode) = @psCurrencyCode 
	 or @psCurrencyCode is null)
	-- Return an empty result set if the user does not have access to the Prepayments topic
	and @bIsPrepaymentsRequired = 1
	order by 'ItemDate', 'OpenItemNo', 'OurReference'"	

	exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnNameKey		int,
					  @pnUserIdentityId	int,
					  @pnEntityKey		int,
					  @psCurrencyCode	nvarchar(3),
					  @bIsExternalUser	bit,
					  @bIsPrepaymentsRequired bit,
					  @sLocalCurrencyCode	nvarchar(3)',
					  @pnNameKey		=@pnNameKey,
					  @pnUserIdentityId	=@pnUserIdentityId,
					  @pnEntityKey         	=@pnEntityKey,
					  @psCurrencyCode       =@psCurrencyCode,
					  @bIsExternalUser	=@bIsExternalUser,
					  @bIsPrepaymentsRequired=@bIsPrepaymentsRequired,
					  @sLocalCurrencyCode	= @sLocalCurrencyCode

	Set @pnRowCount = @@Rowcount
End

Return @nErrorCode
GO

Grant execute on dbo.ar_ListNamePrepaymentItems  to public
GO
