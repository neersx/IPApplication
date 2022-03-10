-----------------------------------------------------------------------------------------------------------------------------
-- Creation of biw_GenerateChangeAlert									      
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[biw_GenerateChangeAlert]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.biw_GenerateChangeAlert.'
	Drop procedure [dbo].[biw_GenerateChangeAlert]
End
Print '**** Creating Stored Procedure dbo.biw_GenerateChangeAlert...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.biw_GenerateChangeAlert
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pbCalledFromCentura	bit		= 0,
	@pnItemEntityKey	int,	-- Mandatory.
	@pnItemTransKey		int,	-- Mandatory.
	@pnDebtorKey		int,	-- Mandatory.
	@pnNameKey		int = null, -- For copies to names
	@pbHasDebtorChanged	bit = 0,
	@pbHasDebtorReferenceChanged bit = 0,
	@pbHasAddressChanged	bit = 0,
	@pbHasAttentionChanged	bit = 0,
	@pnAddressChangeReason	int
)
as
-- PROCEDURE:	biw_GenerateChangeAlert
-- VERSION:	6
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Generate a reminder notice for changes on an invoice.
--				Pass @pnName key only for copies to address name changes.
--
-- MODIFICATIONS :
-- Date		Who	Change		Version	Description
-- -----------	-------	---------------	-------	-----------------------------------------------
-- 18-Oct-2010	AT	RFC7272		1	Procedure created.
-- 12-Jan-2011	AT	RFC8983		2	Clear wildcard strings if nothing has changed.
-- 22-May-2012	AT	RFC11920	3	Display data that hasn't changed as 'UNCHANGED'
-- 03-Aug-2012	KR	RFC100724	4	Changed logic to obtain OLDATTN
-- 13-Feb-2013	vql	RFC11732	5	Retrieve debtor ref changes.
-- 02 Nov 2015	vql	R53910		6	Adjust formatted names logic (DR-15543).

SET CONCAT_NULL_YIELDS_NULL OFF

SET NOCOUNT OFF

Declare @nErrorCode		int
Declare @sSQLString 		nvarchar(4000)
Declare @sOpenItemNo		nvarchar(12)
Declare @nMainCaseKey		int
Declare @nStaffKey		int
Declare @sReason		nvarchar(80)
Declare @bUseRenewalDebtor	bit

Declare @sNewDebtor		nvarchar(254)
Declare @sNewDebtorReferences	nvarchar(254)
Declare @sCopiesToName		nvarchar(500)
Declare @sNewAddress		nvarchar(254)
Declare @sNewAttention		nvarchar(254)

Declare @sReminderText		nvarchar(max)
Declare @sAlertTemplate		nvarchar(10)
Declare @nAddressAdmin		int
Declare @sReplaceString		nvarchar(254)

Declare @dtAlertSeq		datetime
Declare @dtDueDate		datetime
Declare @dtStopDate		datetime
Declare @dtDeleteDate		datetime

Declare @nPolicingBatchNo	int

Declare @sUnchangedString	nvarchar(10)
Declare @nOldAttentionName	int

Set @sUnchangedString = 'UNCHANGED'


-- Initialise variables
Set @nErrorCode = 0

-- Get the invoice details
if (@nErrorCode = 0)
Begin
	Set @sSQLString = "
		Select @sOpenItemNo = O.OPENITEMNO,
		@nMainCaseKey = O.MAINCASEID,
		@nStaffKey = EMPLOYEENO,
		@sReason = TC.DESCRIPTION,
		@bUseRenewalDebtor = ISNULL(O.RENEWALDEBTORFLAG, 0),
		@sNewDebtor = FORMATTEDNAME,
		@sNewAddress = FORMATTEDADDRESS,
		@sNewAttention = FORMATTEDATTENTION,
		@sNewDebtorReferences = FORMATTEDREFERENCE
		from OPENITEM AS O WITH (READUNCOMMITTED)
		left join NAMEADDRESSSNAP NAS with (READUNCOMMITTED) ON (NAS.NAMESNAPNO = O.NAMESNAPNO)
		left join TABLECODES TC  with (READUNCOMMITTED) ON (TC.TABLECODE = NAS.REASONCODE)		
		where ITEMENTITYNO = @pnItemEntityKey
		and ITEMTRANSNO = @pnItemTransKey
		and ACCTDEBTORNO = @pnDebtorKey"



	exec @nErrorCode = sp_executesql @sSQLString,
				N'@sOpenItemNo nvarchar(12) OUTPUT,
				@nMainCaseKey int OUTPUT,
				@nStaffKey int OUTPUT,
				@sReason nvarchar(80) OUTPUT,
				@bUseRenewalDebtor bit OUTPUT,
				@sNewDebtor nvarchar(254) OUTPUT,
				@sNewAddress nvarchar(254) OUTPUT,
				@sNewAttention nvarchar(254) OUTPUT,
				@sNewDebtorReferences nvarchar(254) OUTPUT,				
				@pnItemEntityKey int,
				@pnItemTransKey int,
				@pnDebtorKey int',
				@sOpenItemNo = @sOpenItemNo OUTPUT,
				@nMainCaseKey = @nMainCaseKey OUTPUT,
				@nStaffKey = @nStaffKey OUTPUT,
				@sReason = @sReason OUTPUT,
				@bUseRenewalDebtor = @bUseRenewalDebtor OUTPUT,
				@sNewDebtor = @sNewDebtor OUTPUT,
				@sNewAddress = @sNewAddress OUTPUT,
				@sNewAttention = @sNewAttention OUTPUT,
				@sNewDebtorReferences = @sNewDebtorReferences OUTPUT,				
				@pnItemEntityKey = @pnItemEntityKey,
				@pnItemTransKey = @pnItemTransKey,
				@pnDebtorKey = @pnDebtorKey
End

-- This is a copies to address change.
if (@pnNameKey is not null)
Begin
	Set @sSQLString = "select 
		@sReason = TC.DESCRIPTION,
		@sCopiesToName = NAS.FORMATTEDNAME,
		@sNewAddress = NAS.FORMATTEDADDRESS,
		@sNewAttention = NAS.FORMATTEDATTENTION,
		@sNewDebtorReferences = NAS.FORMATTEDREFERENCE
	from OPENITEMCOPYTO OIC with (READUNCOMMITTED) 
	JOIN NAMEADDRESSSNAP NAS with (READUNCOMMITTED) ON (NAS.NAMESNAPNO = OIC.NAMESNAPNO)
	left join TABLECODES TC with (READUNCOMMITTED) ON (TC.TABLECODE = NAS.REASONCODE)		
	WHERE OIC.ITEMENTITYNO = @pnItemEntitykey
	and OIC.ITEMTRANSNo = @pnItemTransKey
	and NAS.NAMENO = @pnNameKey"
	
	exec @nErrorCode = sp_executesql @sSQLString,
				N'@sReason nvarchar(80) OUTPUT,
				@sCopiesToName nvarchar(254) OUTPUT,
				@sNewAddress nvarchar(254) OUTPUT,
				@sNewAttention nvarchar(254) OUTPUT,
				@pnItemEntityKey int,
				@pnItemTransKey int,
				@pnNameKey int',
				@sReason = @sReason OUTPUT,
				@sCopiesToName = @sCopiesToName OUTPUT,
				@sNewAddress = @sNewAddress OUTPUT,
				@sNewAttention = @sNewAttention OUTPUT,
				@pnItemEntityKey = @pnItemEntityKey,
				@pnItemTransKey = @pnItemTransKey,
				@pnNameKey = @pnNameKey
				
	if (@sReason is null)
	Begin
		-- This must be a deleted copy to name. Set the reason to the param.
		select @sReason = DESCRIPTION FROM TABLECODES WITH (READUNCOMMITTED) WHERE TABLECODE = @pnAddressChangeReason
		select @sCopiesToName = dbo.fn_FormatNameUsingNameNo(N.NAMENO, null) FROM NAME N WITH (READUNCOMMITTED) WHERE NAMENO = @pnNameKey
		
		Set @sNewAttention = NULL
		Set @sNewAddress = null
	End
End

-- Get the address change template and address administrator site controls 
if (@nErrorCode = 0)
Begin
	Set @sSQLString = "
		Select @sReminderText = AT.ALERTMESSAGE,
		@sAlertTemplate = AT.ALERTTEMPLATECODE
		FROM ALERTTEMPLATE AT
		join SITECONTROL SC ON (SC.COLCHARACTER = AT.ALERTTEMPLATECODE)
		WHERE SC.CONTROLID = 'Addr Change Reminder Template'"
		
	exec @nErrorCode = sp_executesql @sSQLString,
		N'@sReminderText nvarchar(max) OUTPUT,
		@sAlertTemplate nvarchar(10) OUTPUT',
		@sReminderText = @sReminderText OUTPUT,
		@sAlertTemplate = @sAlertTemplate OUTPUT
End
	
if (@nErrorCode = 0)
Begin
	Set @sSQLString = "
		Select @nAddressAdmin = COLINTEGER
		FROM SITECONTROL 
		WHERE CONTROLID = 'Address Administrator'"
		
	exec @nErrorCode = sp_executesql @sSQLString,
		N'@nAddressAdmin int OUTPUT',
		@nAddressAdmin = @nAddressAdmin OUTPUT
End

-- Generate the reminder text if all applicable details are present
if ( ((@sReason != "" AND  @sReason is NOT null) OR @pbHasDebtorChanged = 1 OR @pbHasDebtorReferenceChanged = 1)
	and @sReminderText is not null
	and @nAddressAdmin is not null)
Begin
	if (@pbHasDebtorChanged = 1)
	Begin
		-- Get the debtor change details
		Set @sSQLString = "
		Select @sReplaceString = dbo.fn_FormatNameUsingNameNo(N.NAMENO, null)
		from CASENAME CN
		JOIN NAME N ON N.NAMENO = CN.NAMENO
		WHERE CN.CASEID = @nMainCaseKey"
		
		If (@bUseRenewalDebtor = 1)
		Begin
			Set @sSQLString = @sSQLString + char(10) + "and CN.NAMETYPE = 'Z'"
		End
		Else
		Begin
			Set @sSQLString = @sSQLString + char(10) + "and CN.NAMETYPE = 'D'"
		End
			
		Set @sSQLString = @sSQLString + char(10) + "order by SEQUENCE DESC"
		
		exec @nErrorCode = sp_executesql @sSQLString ,
		N'@sReplaceString nvarchar(254) OUTPUT,
		@nMainCaseKey int',
		@sReplaceString = @sReplaceString OUTPUT,
		@nMainCaseKey = @nMainCaseKey
		
		If (charindex('%OLDDEBTOR', @sReminderText) > 0)
		Begin			
			select @sReminderText = replace(@sReminderText collate database_default, 
			'%OLDDEBTOR', isnull(@sReplaceString, ''))
				
			Set @sReplaceString = null
		End

		If (charindex('%NEWDEBTOR', @sReminderText) > 0)
		Begin
			select @sReminderText = replace(@sReminderText collate database_default, 
			'%NEWDEBTOR', isnull(@sNewDebtor, ''))
		End
	End
	else
	Begin
		-- No Changes. Old Debtor is the current debtor on the bill.
		-- New Debtor is 'UNCHANGED'
		If (charindex('%OLDDEBTOR', @sReminderText) > 0)
		Begin			
			select @sReminderText = replace(@sReminderText collate database_default, 
			'%OLDDEBTOR', isnull(@sNewDebtor, ''))
				
			Set @sReplaceString = null
		End

		If (charindex('%NEWDEBTOR', @sReminderText) > 0)
		Begin
			select @sReminderText = replace(@sReminderText collate database_default, 
			'%NEWDEBTOR', @sUnchangedString)
		End
	End

	if (@pbHasDebtorReferenceChanged = 1)
	Begin
		-- Get the debtor reference details
		Set @sSQLString = "
		Select @sReplaceString = stuff((SELECT ',' + REFERENCENO
		FROM CASENAME CN
		WHERE CN.CASEID in (select CASEID from dbo.fn_GetBillCases(@pnItemTransKey,@pnItemEntityKey))"
		
		If (@bUseRenewalDebtor = 1)
		Begin
			Set @sSQLString = @sSQLString + char(10) + "and CN.NAMETYPE = 'Z'"
		End
		Else
		Begin
			Set @sSQLString = @sSQLString + char(10) + "and CN.NAMETYPE = 'D'"
		End
			
		Set @sSQLString = @sSQLString + char(10) + "order by SEQUENCE DESC FOR XML PATH('')),1,1,'')"
		
		exec @nErrorCode = sp_executesql @sSQLString ,
		N'@sReplaceString nvarchar(254) OUTPUT,
		@pnItemTransKey int,
		@pnItemEntityKey int',
		@sReplaceString = @sReplaceString OUTPUT,
		@pnItemTransKey = @pnItemTransKey,
		@pnItemEntityKey = @pnItemEntityKey
		
		If (charindex('%OLDREF', @sReminderText) > 0)
		Begin			
			select @sReminderText = replace(@sReminderText collate database_default, 
			'%OLDREF', isnull(@sReplaceString, ''))
				
			Set @sReplaceString = null
		End

		If (charindex('%NEWREF', @sReminderText) > 0)
		Begin
			select @sReminderText = replace(@sReminderText collate database_default, 
			'%NEWREF', isnull(@sNewDebtorReferences, ''))
		End		
	End
	Else
	Begin
		-- No Changes
		If (charindex('%OLDREF', @sReminderText) > 0)
		Begin			
			select @sReminderText = replace(@sReminderText collate database_default, 
			'%OLDREF', isnull(@sNewDebtorReferences, ''))
				
			Set @sReplaceString = null
		End

		If (charindex('%NEWREF', @sReminderText) > 0)
		Begin
			select @sReminderText = replace(@sReminderText collate database_default, 
			'%NEWREF', @sUnchangedString)
		End
	End	
	
	-- Set changed copies to name
	If (charindex('%NAME', @sReminderText) > 0)
	Begin
		select @sReminderText = replace(@sReminderText collate database_default, 
		'%NAME', isnull(@sCopiesToName,''))
	End
	
	if (@pbHasAddressChanged = 1)
	Begin
		-- Get the existing Address details
		--dbo.fn_FormatAddress(AD.STREET1, AD.STREET2, AD.CITY, AD.STATE, ADS.STATENAME, AD.POSTCODE, ADC.POSTALNAME, ADC.POSTCODEFIRST, ADC.STATEABBREVIATED, ADC.POSTCODELITERAL, ADC.ADDRESSSTYLE)
		Set @sSQLString = "
		Select @sReplaceString = dbo.fn_GetFormattedAddress(AD.ADDRESSCODE, null, null, null, 0)
		from NAME N
		Left Join ASSOCIATEDNAME ASSN on (ASSN.NAMENO = N.NAMENO
									and ASSN.RELATIONSHIP = 'BIL')
		Left Join ADDRESS AD on (AD.ADDRESSCODE = ISNULL(N.POSTALADDRESS,ASSN.POSTALADDRESS))
		where N.NAMENO = ISNULL(@pnNameKey, @pnDebtorKey)
		order by SEQUENCE DESC"
		
		exec @nErrorCode = sp_executesql @sSQLString ,
		N'@sReplaceString nvarchar(254) OUTPUT,
		@pnNameKey  int,
		@pnDebtorKey int',
		@sReplaceString = @sReplaceString OUTPUT,
		@pnNameKey = @pnNameKey,
		@pnDebtorKey = @pnDebtorKey
		
		-- Old address is the debtor's current address
		If (charindex('%OLDADDR', @sReminderText) > 0)
		Begin
			select @sReminderText = replace(@sReminderText collate database_default, 
			'%OLDADDR', isnull(@sReplaceString, ''))
			
			Set @sReplaceString = null
		End
			
		If (charindex('%NEWADDR', @sReminderText) > 0)
		Begin
			select @sReminderText = replace(@sReminderText collate database_default, 
			'%NEWADDR', isnull(@sNewAddress, ''))
		End
	End
	Else
	Begin
		-- No Changes. Old address is the address on the bill.
		-- New Address is 'UNCHANGED'
		If (charindex('%OLDADDR', @sReminderText) > 0)
		Begin
			select @sReminderText = replace(@sReminderText collate database_default, 
			'%OLDADDR', isnull(@sNewAddress, ''))
			
			Set @sReplaceString = null
		End
		
		If (charindex('%NEWADDR', @sReminderText) > 0)
		Begin
			select @sReminderText = replace(@sReminderText collate database_default, 
			'%NEWADDR', @sUnchangedString)
		End
	End
	
	
	If (charindex('%ADDRREASON', @sReminderText) > 0)
	Begin
		select @sReminderText = replace(@sReminderText collate database_default, 
		'%ADDRREASON', isnull(@sReason,''))
	End
	
	If (@pbHasAttentionChanged = 1)
	Begin
		If (@pnNameKey is null)
		Begin
			-- Get the existing attention details
			-- If you can't find the casename contact, get the associated name.
			Set @sSQLString = "		
			
			Select @nOldAttentionName = COALESCE(CN.CORRESPONDNAME,INDEB.CONTACT,ANDEB.CONTACT,N.MAINCONTACT)		
			
			from NAME N
			LEFT JOIN CASENAME CN ON (CN.NAMENO = N.NAMENO AND CN.CASEID = @nMainCaseKey"
									
			If (@bUseRenewalDebtor = 1)
			Begin
				Set @sSQLString = @sSQLString + char(10) + "and CN.NAMETYPE = 'Z')"
			End
			Else
			Begin
				Set @sSQLString = @sSQLString + char(10) + "and CN.NAMETYPE = 'D')"
			End
			
			Set @sSQLString = @sSQLString + char(10) + 
			
			"LEFT JOIN NAME CNN ON (CNN.NAMENO = CN.CORRESPONDNAME)
			
			Left Join ASSOCIATEDNAME ANDEB ON (ANDEB.NAMENO = CN.NAMENO
								AND ANDEB.RELATIONSHIP = 'BIL'
								AND ANDEB.SEQUENCE = (SELECT MIN(SEQUENCE) FROM ASSOCIATEDNAME WHERE NAMENO = CN.NAMENO AND RELATIONSHIP = 'BIL')
								)
			Left Join ASSOCIATEDNAME INDEB ON (ISNULL(CN.INHERITED,0) = 1
								AND INDEB.NAMENO = CN.INHERITEDNAMENO
								AND INDEB.RELATIONSHIP = CN.INHERITEDRELATIONS
								AND INDEB.SEQUENCE = CN.INHERITEDSEQUENCE)			
			
			WHERE N.NAMENO = @pnDebtorKey"
			
			Set @sSQLString = @sSQLString + char(10) + "order by CN.SEQUENCE DESC, ANDEB.SEQUENCE, INDEB.SEQUENCE DESC"	
			
		End
		Else
		Begin
			-- Get attention details of copy to name.
			Set @sSQLString = "
			Select @nOldAttentionName = CN.NAMENO
			From NAME N
			left join NAME CN on (CN.NAMENO = N.MAINCONTACT)
			Where N.NAMENO = @pnNameKey"
		End

		exec @nErrorCode = sp_executesql @sSQLString ,
		N'@nOldAttentionName int OUTPUT,
		@pnDebtorKey int,
		@pnNameKey int,
		@nMainCaseKey int',
		@nOldAttentionName = @nOldAttentionName OUTPUT,
		@pnDebtorKey = @pnDebtorKey,
		@pnNameKey = @pnNameKey,
		@nMainCaseKey = @nMainCaseKey
		
		if (@nErrorCode = 0)
		Begin
		
			Set @sSQLString = "Select @sReplaceString =  dbo.fn_FormatNameUsingNameNo(NAMENO, 7101) from NAME where NAMENO = @nOldAttentionName"
			
			exec @nErrorCode = sp_executesql @sSQLString ,
			N'@sReplaceString nvarchar(254) OUTPUT,
			@nOldAttentionName int',
			@sReplaceString = @sReplaceString OUTPUT,
			@nOldAttentionName = @nOldAttentionName
		End
		
		-- Old Attention is the related attention name
		If (charindex('%OLDATTN', @sReminderText) > 0)
		Begin
			select @sReminderText = replace(@sReminderText collate database_default, 
			'%OLDATTN', isnull(convert(varchar(254),@sReplaceString ),''))
			
			Set @sReplaceString = null
		End
		
		If (charindex('%NEWATTN', @sReminderText) > 0)
		Begin
			select @sReminderText = replace(@sReminderText collate database_default, 
			'%NEWATTN', isnull(@sNewAttention,''))
		End
	End
	Else
	Begin
		-- No Changes. Old Attention attention name related to the case/debtor.
		-- New Attention is 'UNCHANGED'
		If (charindex('%OLDATTN', @sReminderText) > 0)
		Begin
			select @sReminderText = replace(@sReminderText collate database_default, 
			'%OLDATTN', isnull(@sNewAttention,''))
			
			Set @sReplaceString = null
		End
		
		If (charindex('%NEWATTN', @sReminderText) > 0)
		Begin
			select @sReminderText = replace(@sReminderText collate database_default, 
			'%NEWATTN', @sUnchangedString)
		End
	End
	

	If (charindex('%STAFF', @sReminderText) > 0)
	Begin
		Set @sSQLString = "
		Select @sReplaceString = dbo.fn_FormatNameUsingNameNo(N.NAMENO, null)
		FROM NAME N WHERE NAMENO = @nStaffKey"
		
		exec @nErrorCode = sp_executesql @sSQLString ,
		N'@sReplaceString nvarchar(254) OUTPUT,
		@nStaffKey int',
		@sReplaceString = @sReplaceString OUTPUT,
		@nStaffKey = @nStaffKey
		
		select @sReminderText = replace(@sReminderText collate database_default, 
		'%STAFF', isnull(@sReplaceString,''))
		
		Set @sReplaceString = null
	End
	
	If (charindex('%CASE', @sReminderText) > 0)
	Begin
		Set @sSQLString = "
		Select @sReplaceString = IRN
		FROM CASES WHERE CASEID = @nMainCaseKey"
		
		exec @nErrorCode = sp_executesql @sSQLString ,
		N'@sReplaceString nvarchar(254) OUTPUT,
		@nMainCaseKey int',
		@sReplaceString = @sReplaceString OUTPUT,
		@nMainCaseKey = @nMainCaseKey
		
		select @sReminderText = replace(@sReminderText collate database_default, 
		'%CASE', isnull(@sReplaceString,''))
		
		Set @sReplaceString = null
	End
	
	If (charindex('%INVOICENO', @sReminderText) > 0)
	Begin		
		select @sReminderText = replace(@sReminderText collate database_default, 
		'%INVOICENO', isnull(@sOpenItemNo,''))
	End
	
	
	
	-- Generate the actual Reminder request	
	If @nErrorCode = 0
	Begin
		-- Since DateTime is part of the key it is possible to
		-- get a duplicate key.  Keep trying until a unique DateTime
		-- is extracted.
		Set @dtAlertSeq = getdate()
		
		While exists (select * from ALERT WHERE EMPLOYEENO = @nAddressAdmin
					and ALERTSEQ = @dtAlertSeq)
		Begin	
			select @dtAlertSeq = dateadd(ms,3,@dtAlertSeq)
		End
	End
	
	If (@nErrorCode = 0)
	Begin

		Select @dtDueDate = DATEADD(mm, isnull(AT.MONTHSLEAD, 0), DATEADD(dd, isnull(AT.DAYSLEAD, 0), dbo.fn_DateOnly(GETDATE())))
		FROM ALERTTEMPLATE AT
		WHERE AT.ALERTTEMPLATECODE = @sAlertTemplate
		
		SELECT @dtStopDate = DATEADD(dd, AT.STOPALERT, @dtDueDate)
		FROM ALERTTEMPLATE AT
		WHERE AT.ALERTTEMPLATECODE = @sAlertTemplate
		
		SELECT @dtDeleteDate = DATEADD(dd, AT.DELETEALERT, @dtDueDate)
		FROM ALERTTEMPLATE AT
		WHERE AT.ALERTTEMPLATECODE = @sAlertTemplate	
		
		if (len(@sReminderText) > 1000)
		Begin
			Select @sReminderText = left(@sReminderText, 1000)
		End
		
		declare @nSequenceNo int
		
		select @nSequenceNo = max(SEQUENCENO) + 1 FROM ALERT
		
		--print @sReminderText
		
		insert into ALERT (EMPLOYEENO, ALERTSEQ, CASEID, ALERTMESSAGE, REFERENCE,
		ALERTDATE, DUEDATE, DATEOCCURRED, OCCURREDFLAG, DELETEDATE, STOPREMINDERSDATE,
		MONTHLYFREQUENCY, MONTHSLEAD, DAILYFREQUENCY, DAYSLEAD, SEQUENCENO, SENDELECTRONICALLY,
		EMAILSUBJECT, FROMCASEID, EVENTNO, CYCLE, LETTERNO, OVERRIDERULE, TRIGGEREVENTNO,
		SENDMETHOD, SENTDATE, RECEIPTDATE, RECEIPTREFERENCE, DISPLAYORDER, IMPORTANCELEVEL, NAMENO)
		SELECT 
		@nAddressAdmin, @dtAlertSeq, @nMainCaseKey, @sReminderText, NULL,
		dbo.fn_DateOnly(@dtAlertSeq), @dtDueDate, NULL, NULL, @dtDeleteDate, @dtStopDate,
		AT.MONTHLYFREQUENCY, AT.MONTHSLEAD, AT.DAILYFREQUENCY, AT.DAYSLEAD, @nSequenceNo, AT.SENDELECTRONICALLY,
		AT.EMAILSUBJECT, null, null, null, null, null, null,
		null, null, null, null, null, AT.IMPORTANCELEVEL, ISNULL(@pnNameKey,@pnDebtorKey)
		FROM ALERTTEMPLATE AT
		WHERE ALERTTEMPLATECODE = @sAlertTemplate

	End
		
	if (@nErrorCode = 0)
	Begin
		exec @nErrorCode = ip_GetLastInternalCode
			@pnUserIdentityId = @pnUserIdentityId,
			@psCulture = @psCulture,
			@psTable = 'POLICING',
			@pnLastInternalCode	= @nPolicingBatchNo OUTPUT,
			@pbCalledFromCentura = @pbCalledFromCentura,
			@pbIsInternalCodeNegative = 0
	End

	if (@nErrorCode = 0)
	Begin
		exec @nErrorCode = dbo.ipw_InsertPolicing
			@pnUserIdentityId	= @pnUserIdentityId,
			@psCulture		= @psCulture,
			@pnCaseKey = @nMainCaseKey,
			@pnTypeOfRequest	= 3, -- Event occurred
			@pnPolicingBatchNo	= @nPolicingBatchNo,
			@pnAdHocNameNo		= @nAddressAdmin,
			@pdtAdHocDateCreated = @dtAlertSeq
	End
	
	If (@nPolicingBatchNo is not null and @nErrorCode = 0)
	Begin
		 exec @nErrorCode = dbo.ipu_Policing
		   @pdtPolicingDateEntered  = null,
		   @pnPolicingSeqNo   = null,
		   @pnDebugFlag   = 0,
		   @pnBatchNo   = @nPolicingBatchNo,
		   @psDelayLength   = null,
		   @pnUserIdentityId  = @pnUserIdentityId,
		   @psPolicingMessageTable  = null
	End
End

Return @nErrorCode
GO

Grant execute on dbo.biw_GenerateChangeAlert to public
GO