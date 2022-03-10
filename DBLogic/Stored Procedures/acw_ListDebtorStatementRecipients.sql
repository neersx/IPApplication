-----------------------------------------------------------------------------------------------------------------------------
-- Creation of acw_ListDebtorStatementRecipients
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[acw_ListDebtorStatementRecipients]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.acw_ListDebtorStatementRecipients.'
	Drop procedure [dbo].[acw_ListDebtorStatementRecipients]
End
Print '**** Creating Stored Procedure dbo.acw_ListDebtorStatementRecipients...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.acw_ListDebtorStatementRecipients
(
	@pnUserIdentityId		int,			-- Mandatory
	@psCulture			nvarchar(10) 	=NULL,			
	@pbCalledFromCentura		bit		= 0,
	@pnPeriod			int,			-- Mandatory
	@pnEntityNo			int,			-- Mandatory
	@pnDebtorNo			int		=NULL,
	@pnSortBy			int		= 0,
	@psFromDebtor			nvarchar(20)	=NULL,
	@psToDebtor			nvarchar(20)	=NULL,
	@pbPrintPositiveBal		bit		= 0,
	@pbPrintNegativeBal		bit		= 0,
	@pbPrintZeroBalance		bit		= 0,
	@pbPrintZeroBalWOAct		bit		= 0,
	@psDebtorRestrictions		NVARCHAR(4000)	= null,
	@pbLocalDebtor			bit		= 1,
	@pbForeignDebtor		bit		= 1,
	@pbIsForSummary			bit		= 0,
	@psEmailSubject			nvarchar(254)	= null,
	@psEmailBody			nvarchar(max)	= null,
	@psDebtorNos			nvarchar(4000)	=NULL
)
as
-- PROCEDURE:	acw_ListDebtorStatementRecipients
-- VERSION:	19
-- COPYRIGHT:	Copyright CPA Global Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Return the list of debtors for which a statement will be created and delivered.
--		This contains the Name and the email address to which the statement will be sent.
--		The order of precedence for the statement email address is as follows:
--		1) If 'Statements Email Telecom Type' site control is on, and telecom of this type
--		exists for any of below names, then this will be used in the below order of precedence.
--		2) The Attention Name for the Send Statements To Name against the Debtor
--		3) The Main Contact for the Send Statements To Name against the Debtor
--		5) The Send Statements To against the Debtor
--		6) The Main Contact for the Debtor
--		7) The Debtor itself
-- 

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 23 Dec 2011	LP	R10835	1	Procedure created
-- 20 Mar 2012	LP	R10673	2	Previously if contact name exists but does not have an email address, email is not sent
--					Corrected to default to the next available email address in order of precedence
-- 03 Apr 2012	LP	R12142	3	Email addresses were not being returned for "Send Statements To" and "Main Contact" names
--					Also extend to pick-up Main Contact (as opposed to Attention Name) of "Send Statements To" name 
-- 15 May 2012	LP	R12142	4	Statements Email Telecom Type should take precedence over all other email addresses.
--					Also ensured only Main Email Address is picked-up to prevent multiple emails being sent.
-- 27 Feb 2014	DL	S21508	5	Change variables and temp table columns that reference namecode to 20 characters
-- 28 Mar 2014	MS	R31038	6	Added parameters for debtor restrictions, local and foreign debtors for filter
-- 04 Apr 2014	DV	R31105  7	Get the To,CC,BCC,Subject and Body from the Doc item
-- 25 Apr 2014  MS      R32384  8       Get DeliveryType for recipients from name attributes
-- 07 May 2014	MS	R33107	9	Get DebtorBalance, Currency and DebtorRestriction
-- 17 Jun 2014	DV	R35246	10	Allow multiple debtors to be passed in the filter criteria
-- 19 Jun 2014	DV	R35250	11	Added parameter for Subject and Body which will override the values from Doc Item.
-- 25 Jun 2014  SW      R35244  12      Return DeliveryType for Debtor Summary Validation
-- 13 jul 2014  DV	R37223	13	Changed the subject to nvarchar(254)
-- 01 Oct 2015	LP	R48993	14	Pass EntityNo and Period to Doc Items
-- 09 Oct 2015  vql	DR12412	15	Handle new delivery methods Email Including Current Invoices and Email Including Outstanding Invoices
-- 02 Nov 2015	vql	R53910	16	Adjust formatted names logic (DR-15543).
-- 19 Apr 2016	vql	R55531	17	Debtor Item Movement Statement Summary report displays incorrect balance figure (DR-16693).
-- 24 Aug 2017	MF	71713	18	Ethical Walls rules applied for logged on user.
-- 24 Oct 2017	AK	R72645	19	Make compatible with case sensitive server with case insensitive database.    

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare @nErrorCode 		int
Declare @sSQLString		nvarchar(max)
Declare @sLookupCulture		nvarchar(10)
Declare @sParameterName		nvarchar(128)   -- name of parameter whose value is being stored
Declare @sDataType		nvarchar(1)     -- datatype of parameter
Declare @nColInteger		int		-- parameter value if integer
Declare @nColDecimal		decimal (12,2)  -- parameter value if decimal
Declare @sColCharacter		nvarchar(256)   -- parameter value if string
Declare @dtColDate		datetime        -- parameter value if date
Declare @nBracket0Days		int		-- first ageing bracket (number of days from base date)
Declare @nBracket1Days		int		-- second ageing bracket (number of days from base date)
Declare @nBracket2Days		int		-- third ageing bracket (number of days from base date)
Declare @nAge0Days		int		-- number of days in the first ageing bracket
Declare @nAge1Days		int		-- number of days in the second ageing bracket
Declare @nAge2Days		int		-- number of days in the third ageing bracket
Declare @dtBaseDate		datetime	-- the base date for calculation of ageing
Declare @dtItemDateTo		datetime	-- restricts report to transactions entered prior to this date
Declare @nStatementTelecomType	nvarchar(40)
Declare @sDocItemEmailTo	nvarchar(40)
Declare @sDocItemEmailCC	nvarchar(40)
Declare @sDocItemEmailBCC	nvarchar(40)
Declare @sDocItemEmailSubject	nvarchar(40)
Declare @sDocItemEmailBody	nvarchar(40)
Declare @nDebtorNo		int
Declare @sSQLDocItem		nvarchar(max)

Declare @tbRecipients table (
	DebtorName		nvarchar(max)	collate database_default,
	DebtorNameCode		nvarchar(20)	collate database_default null,
	EmailAddress		nvarchar(max)	collate database_default null,
	CopyTo			nvarchar(max)	collate database_default null,
	BlankCopyTo		nvarchar(max)	collate database_default null,
	EmailSubject		nvarchar(max)	collate database_default null,
	Body			nvarchar(max)	collate database_default null,
	DebtorNo		int,
	StatementAttentionNo	int		null,
	StatementContactNo	int		null,
	StatementNameNo		int		null,
	DebtorContactNo		int		null,
	DeliveryType		int,
	DebtorBalance		decimal(11,2)	null,
	DebtorCurrency		NVARCHAR(3)	collate database_default null,
	DebtorRestriction	nvarchar(254)	collate database_default null,
	EntityNo		int,
	SortByColumn		nvarchar(254)	null
)

set @sLookupCulture = dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)
Set	@nErrorCode      = 0

If @nErrorCode = 0
Begin
	-- determine the base date and ageing brackets
	If @pnPeriod is not null
	Begin
		exec @nErrorCode = dbo.acw_GetAgeingBrackets         
		@pnUserIdentityId,
		@psCulture,
		@pbCalledFromCentura,
		@pnPeriod,
		@dtBaseDate output,
		@nBracket0Days output,
		@nBracket1Days output,
		@nBracket2Days output
	
		Set @nAge0Days = @nBracket0Days
		Set @nAge1Days = (@nBracket1Days - @nBracket0Days)
		Set @nAge2Days = (@nBracket2Days - @nBracket1Days)
		-- report based on period so both these dates will be the same (end of specified period)
		Set @dtItemDateTo = @dtBaseDate
	End
End

If @nErrorCode = 0
Begin
	-- determine which debtors will be included in the report and store then in the REPORTRECIPIENT table
		
	If  exists (select * from sys.objects where object_id = OBJECT_ID(N'[dbo].#DEBTORSTATEMENT') AND type in (N'U'))       
	Begin
		Drop table [dbo].#DEBTORSTATEMENT
	End

	if (@nErrorCode =0)
	Begin
	
		create table #DEBTORSTATEMENT (   
			MAILINGLABE		varchar(254)	collate database_default NULL,        
			ACCTENTITYNO		INT		NULL ,     
			NAMECODE		varchar(20)	collate database_default NULL,     
			ACCTDEBTORNO		INT		NULL,     
			CURRENCY		varchar(3)	collate database_default NULL,     
			CURRENCYDESCRIPTION	varchar(40)	collate database_default NULL,     
			ITEMDATE		DATETIME	NULL,     
			ITEMNO			varchar(12)	collate database_default NULL,    
			ITEMDESCRIPTION		varchar(254)	collate database_default,     
			OPENINGBALANCE		decimal(11,2),    
			CLOSINGBALANCE		decimal(11,2) ,     
			TRANSDATE		DATETIME	NULL,    
			TRANSNO			INT		NULL,     
			TRANSDESCRIPTION	varchar(254)	collate database_default NULL,     
			TRANSAMOUNT		decimal(11,2)	NULL,       
			AGE0			decimal(11,2),     
			AGE1			decimal(11,2),     
			AGE2			decimal(11,2),     
			AGE3			decimal(11,2),     
			UNALLOCATEDCASH		decimal(11,2),         
			TOTALPAYMENTS		decimal(11,2),    
			NAMECATEGORY		NVARCHAR(80)	collate database_default,    
			TRADINGTERMS		INT,    
			ITEMDUEDATE		DATETIME)     

		-- run the report sp and load the data into a temporary table
		insert   into #DEBTORSTATEMENT        
		exec @nErrorCode = dbo.arb_OpenItemStatement         
		@pnPeriod,        
		@dtBaseDate,           
		@dtItemDateTo,           
		@nAge0Days,          
		@nAge1Days,          
		@nAge2Days,    
		@pnEntityNo,         
		@pbPrintZeroBalance,        
		@pnDebtorNo,          
		@psFromDebtor,          
		@psToDebtor,          
		@pbPrintPositiveBal,        
		@pbPrintNegativeBal,        
		@pbPrintZeroBalWOAct,        
		@pnSortBy,
		@psDebtorRestrictions,
		@pbLocalDebtor,
		@pbForeignDebtor,
		@psDebtorNos

		ALTER TABLE #DEBTORSTATEMENT
		ADD identity_field INT IDENTITY (1, 1);

		/* Ranking the records with same item number value transactions to update 
		closing balalnce, and all aging fields to 0 after header transaction */
		SELECT *,
		Rank() OVER (partition BY acctentityno, namecode, acctdebtorno, currency, itemno ORDER BY identity_field) rankid
		INTO   #DEBTORSTATEMENT1
		FROM   #DEBTORSTATEMENT;

		UPDATE #DEBTORSTATEMENT1
		SET    CLOSINGBALANCE = 0,
		AGE3 = 0,
		AGE2 = 0,
		AGE1 = 0,
		AGE0 = 0,
		UNALLOCATEDCASH = 0
		WHERE  rankid <> 1;		
	End        
	
	If @nErrorCode = 0
	Begin
		Select @nStatementTelecomType = SC.COLINTEGER
		from SITECONTROL SC 
		where SC.CONTROLID = 'Statements Email Telecom Type'
		
		Set @nErrorCode = @@ERROR
	End
	
	-- Insert the Email Addresses from Send Statements To, Contact and Debtor Email
	If @nErrorCode =0
	Begin
		insert into @tbRecipients
		select DISTINCT 
			dbo.fn_FormatNameUsingNameNo(N.NAMENO,NULL)	as DebtorName,
			N.NAMECODE					as DebtorNameCode,
			--T.TELECOMNUMBER as EmailAddress,
			NULL						as EmailAddress,
			NULL						as CopyTo,
			NULL						as BlankCopyTo,
			@psEmailSubject					as EmailSubject,
			@psEmailBody					as Body,		
			N.NAMENO					as DebtorNo,
			STM.CONTACT					as StatementAttentionNo,
			NSTM.MAINCONTACT				as StatementContactNo,
			STM.RELATEDNAME					as StatementNameNo,
			N.MAINCONTACT					as DebtorContactNo,
			CASE WHEN TAO.TABLECODE is not null THEN 5
			     WHEN TAC.TABLECODE is not null THEN 4
			     WHEN TAP.TABLECODE is not null and TAE.TABLECODE is not null THEN 3
			     WHEN TAP.TABLECODE is not null THEN 2
			     WHEN TAE.TABLECODE is not null THEN 1 
			     ELSE 0 END					as DeliveryType,
			SUM(DS.CLOSINGBALANCE)				as DebtorBalance,
			DS.CURRENCY					as DebtorCurrency,
			DBS.DEBTORSTATUS				as DebtorRestriction,
			@pnEntityNo					as EntityNo,
			Case when @pnSortBy = 1 Then N.NAMECODE ELSE DS.NAMECATEGORY END 
									as SortByColumn		
		from dbo.fn_NamesEthicalWall(@pnUserIdentityId) N
		join #DEBTORSTATEMENT1 DS on (DS.ACCTDEBTORNO = N.NAMENO)
		left join IPNAME IP on (IP.NAMENO = N.NAMENO)
		left join DEBTORSTATUS DBS on (DBS.BADDEBTOR = IP.BADDEBTOR)
		left join ASSOCIATEDNAME STM on (STM.NAMENO = N.NAMENO
					and STM.RELATIONSHIP = 'STM')
		left join dbo.fn_NamesEthicalWall(@pnUserIdentityId) NSTM on (NSTM.NAMENO = STM.RELATEDNAME)
		left join TABLEATTRIBUTES TAP on (TAP.GENERICKEY = DS.ACCTDEBTORNO
					AND TAP.PARENTTABLE = 'NAME'
					AND TAP.TABLETYPE = -505
					AND TAP.TABLECODE = -42846977)	
		left join TABLEATTRIBUTES TAE on (TAE.GENERICKEY = DS.ACCTDEBTORNO
					AND TAE.PARENTTABLE = 'NAME'
					AND TAE.TABLETYPE = -505
					AND TAE.TABLECODE = -42846976)
		left join TABLEATTRIBUTES TAC on (TAC.GENERICKEY = DS.ACCTDEBTORNO
					AND TAC.PARENTTABLE = 'NAME'
					AND TAC.TABLETYPE = -505
					AND TAC.TABLECODE = -50502)
		left join TABLEATTRIBUTES TAO on (TAO.GENERICKEY = DS.ACCTDEBTORNO
					AND TAO.PARENTTABLE = 'NAME'
					AND TAO.TABLETYPE = -505
					AND TAO.TABLECODE = -50501)										
		where not exists(Select 1 from TABLEATTRIBUTES TA 
					where TA.GENERICKEY = DS.ACCTDEBTORNO
					AND TA.PARENTTABLE = 'NAME'
					AND TA.TABLETYPE = -505
					AND TA.TABLECODE = -42846978)	
		and (NSTM.NAMENO is not null OR STM.RELATEDNAME is null)		       
		group by DS.ACCTDEBTORNO, N.NAMENO, N.NAMECODE, N.FIRSTNAME, N.NAME, N.TITLE,STM.CONTACT,
				NSTM.MAINCONTACT,STM.RELATEDNAME,N.MAINCONTACT,TAP.TABLECODE, TAE.TABLECODE,TAO.TABLECODE,TAC.TABLECODE,
				DS.CURRENCY, DS.CURRENCYDESCRIPTION, DBS.DEBTORSTATUS, DS.NAMECATEGORY				
		
		Set @nErrorCode = @@ERROR
	 End
 
	 If @nErrorCode =0
	 Begin
		Set @sSQLString = "Select @sDocItemEmailTo = COLCHARACTER
						From SITECONTROL
						Where CONTROLID='Email Debtor Statement To'"

				exec @nErrorCode=sp_executesql @sSQLString,
							N'@sDocItemEmailTo		nvarchar(40)	Output',
							  @sDocItemEmailTo = @sDocItemEmailTo		Output
	 End
	 
	 If @nErrorCode =0
	 Begin
		Set @sSQLString = "Select @sDocItemEmailCC = COLCHARACTER
						From SITECONTROL
						Where CONTROLID='Email Debtor Statement CC'"

				exec @nErrorCode=sp_executesql @sSQLString,
							N'@sDocItemEmailCC		nvarchar(40)	Output',
							  @sDocItemEmailCC = @sDocItemEmailCC		Output
	 End
	 
	 If @nErrorCode =0
	 Begin
		Set @sSQLString = "Select @sDocItemEmailBCC = COLCHARACTER
						From SITECONTROL
						Where CONTROLID='Email Debtor Statement BCC'"

				exec @nErrorCode=sp_executesql @sSQLString,
							N'@sDocItemEmailBCC		nvarchar(40)	Output',
							  @sDocItemEmailBCC = @sDocItemEmailBCC		Output
	 End
	 
	 If @nErrorCode =0
	 Begin
		Set @sSQLString = "Select @sDocItemEmailSubject = COLCHARACTER
						From SITECONTROL
						Where CONTROLID='Email Debtor Statement Subject'"

				exec @nErrorCode=sp_executesql @sSQLString,
							N'@sDocItemEmailSubject		nvarchar(40)	Output',
							  @sDocItemEmailSubject = @sDocItemEmailSubject		Output
	 End
	 
	 If @nErrorCode =0
	 Begin
		Set @sSQLString = "Select @sDocItemEmailBody = COLCHARACTER
						From SITECONTROL
						Where CONTROLID='Email Debtor Statement Body'"

				exec @nErrorCode=sp_executesql @sSQLString,
							N'@sDocItemEmailBody		nvarchar(40)	Output',
							  @sDocItemEmailBody = @sDocItemEmailBody		Output
	 End	
	
	 If @nErrorCode = 0 and (@sDocItemEmailTo is null or @sDocItemEmailTo = ''
						or not exists (select 1 from ITEM WHERE ITEM_NAME = @sDocItemEmailTo))
	 Begin
		 -- Assign the matching StatementTelecomType for the best name in their order of precedence
		 If @nErrorCode = 0
		 and @nStatementTelecomType is not null	 
		 Begin
			 -- If there are any debtors with missing email addresses
			 -- Back-fill any Debtors with email address of Attention Send Statements To name
			 If @nErrorCode = 0
			 Begin
				Update @tbRecipients
				SET EmailAddress = T.TELECOMNUMBER
				from @tbRecipients TB
				join NAMETELECOM NT on (NT.NAMENO = TB.StatementAttentionNo)
				join TELECOMMUNICATION T on (T.TELECODE = NT.TELECODE)
				where TB.EmailAddress IS NULL
				and T.TELECOMTYPE = @nStatementTelecomType
			 End
			 
			 -- If there are any debtors with missing email addresses
			 -- Back-fill any Debtors with email address of Main Contact of the Send Statements To name
			 If @nErrorCode = 0
			 Begin
				Update @tbRecipients
				SET EmailAddress = T.TELECOMNUMBER
				from @tbRecipients TB
				join NAMETELECOM NT on (NT.NAMENO = TB.StatementContactNo)
				join TELECOMMUNICATION T on (T.TELECODE = NT.TELECODE)
				where TB.EmailAddress IS NULL
				and T.TELECOMTYPE = @nStatementTelecomType
			 End
			 
			 -- If there are any debtors with missing email addresses
			 -- Back-fill any Debtors with email address of the Send Statements To name
			 If @nErrorCode = 0
			 Begin
				Update @tbRecipients
				SET EmailAddress = T.TELECOMNUMBER
				from @tbRecipients TB
				join NAMETELECOM NT on (NT.NAMENO = TB.StatementNameNo)
				join TELECOMMUNICATION T on (T.TELECODE = NT.TELECODE)
				where TB.EmailAddress IS NULL
				and T.TELECOMTYPE = @nStatementTelecomType
			 End
			 
			 -- If there are any debtors with missing email addresses
			 -- Back-fill any Debtors with email address of Main Contact of the debtor
			 If @nErrorCode = 0
			 Begin
				Update @tbRecipients
				SET EmailAddress = T.TELECOMNUMBER
				from @tbRecipients TB
				join NAMETELECOM NT on (NT.NAMENO = TB.DebtorContactNo)
				join TELECOMMUNICATION T on (T.TELECODE = NT.TELECODE)
				where TB.EmailAddress IS NULL
				and T.TELECOMTYPE = @nStatementTelecomType
			 End
			 
			 -- If there are any debtors with missing email addresses
			 -- Back-fill any Debtors with their own email address
			 If @nErrorCode = 0
			 Begin
				Update @tbRecipients
				SET EmailAddress = T.TELECOMNUMBER
				from @tbRecipients TB
				join NAMETELECOM NT on (NT.NAMENO = TB.DebtorNo)
				join TELECOMMUNICATION T on (T.TELECODE = NT.TELECODE)
				where TB.EmailAddress IS NULL
				and T.TELECOMTYPE = @nStatementTelecomType
			 End
		 End
		 
		 -- Back-fill any missing email addresses with the first matching main email address in order of precedence	 
		 If @nErrorCode = 0
		 Begin	 
			UPDATE @tbRecipients
			SET TB.EmailAddress = T.TELECOMNUMBER
			from @tbRecipients TB
			left join NAME SANT on (SANT.NAMENO = TB.StatementAttentionNo)
			left join NAME SCNT on (SCNT.NAMENO = TB.StatementContactNo)
			left join NAME SSNT on (SSNT.NAMENO = TB.StatementNameNo)
			left join NAME DCNT on (DCNT.NAMENO = TB.DebtorContactNo)
			left join NAME DNT on (DNT.NAMENO = TB.DebtorNo)
			join TELECOMMUNICATION T on (T.TELECODE = coalesce(SANT.MAINEMAIL, SCNT.MAINEMAIL, SSNT.MAINEMAIL, DCNT.MAINEMAIL, DNT.MAINEMAIL))	
			where TB.EmailAddress is null				
			and T.TELECOMTYPE = 1903
			
			Set @nErrorCode = @@ERROR
		 End
	 End
	 
	 if @nErrorCode = 0 and (@sDocItemEmailTo != ''	or @sDocItemEmailCC	!= ''
							 or @sDocItemEmailBCC != '' or @sDocItemEmailSubject != '' 
							 or @sDocItemEmailBody != '')
	 Begin
		DECLARE DebtorStmtDocItem_Cursor cursor FOR 
		select DISTINCT DebtorNo
		from @tbRecipients
	
		OPEN DebtorStmtDocItem_Cursor
		FETCH NEXT FROM DebtorStmtDocItem_Cursor 
		INTO @nDebtorNo
		
		WHILE (@@FETCH_STATUS = 0 and @nErrorCode = 0)
		Begin	
			-- Update Email To		
			If @nErrorCode = 0 and @sDocItemEmailTo is not null and @sDocItemEmailTo != ''
						and exists (select * from ITEM WHERE ITEM_NAME = @sDocItemEmailTo)
				Begin  
					exec @nErrorCode=dbo.[ipw_FetchDocItem]
								@pnUserIdentityId	= @pnUserIdentityId,		-- Mandatory
								@psCulture		= @psCulture,
								@pbCalledFromCentura	= 0,
								@psDocItem		= @sDocItemEmailTo,
								@psEntryPoint		= @nDebtorNo, -- Debtor No	
								@psEntryPointP1		= @pnEntityNo,
								@psEntryPointP2		= @pnPeriod,						
								@bIsCSVEntryPoint	= 0,
								@pbOutputToVariable	= 1,
								@psOutputString		= @sSQLDocItem output
					If @nErrorCode = 0 and @sSQLDocItem is not null and @sSQLDocItem != ''
					Begin
						Update @tbRecipients
						Set EmailAddress = @sSQLDocItem
						From @tbRecipients where DebtorNo = @nDebtorNo		
						
						Set @nErrorCode = @@ERROR			
					End
				End
				
				-- Update Email CC		
				If @nErrorCode = 0 and @sDocItemEmailCC is not null and @sDocItemEmailCC != ''
						and exists (select * from ITEM WHERE ITEM_NAME = @sDocItemEmailCC)
				Begin  
					exec @nErrorCode=dbo.[ipw_FetchDocItem]
								@pnUserIdentityId	= @pnUserIdentityId,		-- Mandatory
								@psCulture		= @psCulture,
								@pbCalledFromCentura	= 0,
								@psDocItem		= @sDocItemEmailCC,
								@psEntryPoint		= @nDebtorNo, -- Debtor No							
								@psEntryPointP1		= @pnEntityNo,
								@psEntryPointP2		= @pnPeriod,
								@bIsCSVEntryPoint	= 0,
								@pbOutputToVariable	= 1,
								@psOutputString		= @sSQLDocItem output
					If @nErrorCode = 0 and @sSQLDocItem is not null and @sSQLDocItem != ''
					Begin
						Update @tbRecipients
						Set CopyTo = @sSQLDocItem
						From @tbRecipients where DebtorNo = @nDebtorNo		
						
						Set @nErrorCode = @@ERROR			
					End
				End
				
				-- Update Email Blind Copy To		
				If @nErrorCode = 0 and @sDocItemEmailBCC is not null and @sDocItemEmailBCC != ''
						and exists (select * from ITEM WHERE ITEM_NAME = @sDocItemEmailBCC)
				Begin  
					exec @nErrorCode=dbo.[ipw_FetchDocItem]
								@pnUserIdentityId	= @pnUserIdentityId,		-- Mandatory
								@psCulture		= @psCulture,
								@pbCalledFromCentura	= 0,
								@psDocItem		= @sDocItemEmailBCC,
								@psEntryPoint		= @nDebtorNo, -- Debtor No	
								@psEntryPointP1		= @pnEntityNo,
								@psEntryPointP2		= @pnPeriod,						
								@bIsCSVEntryPoint	= 0,
								@pbOutputToVariable	= 1,
								@psOutputString		= @sSQLDocItem output
					If @nErrorCode = 0 and @sSQLDocItem is not null and @sSQLDocItem != ''
					Begin
						Update @tbRecipients
						Set BlankCopyTo	 = @sSQLDocItem
						From @tbRecipients where DebtorNo = @nDebtorNo		
						
						Set @nErrorCode = @@ERROR			
					End
				End
				
				-- Update Email Subject		
				If @nErrorCode = 0 and @sDocItemEmailSubject is not null and @sDocItemEmailSubject != ''
						and exists (select * from ITEM WHERE ITEM_NAME = @sDocItemEmailSubject)
						and (@psEmailSubject is null or @psEmailSubject = '')
				Begin  
					exec @nErrorCode=dbo.[ipw_FetchDocItem]
								@pnUserIdentityId	= @pnUserIdentityId,		-- Mandatory
								@psCulture		= @psCulture,
								@pbCalledFromCentura	= 0,
								@psDocItem		= @sDocItemEmailSubject,
								@psEntryPoint		= @nDebtorNo, -- Debtor No	
								@psEntryPointP1		= @pnEntityNo,
								@psEntryPointP2		= @pnPeriod,						
								@bIsCSVEntryPoint	= 0,
								@pbOutputToVariable	= 1,
								@psOutputString		= @sSQLDocItem output
					If @nErrorCode = 0 and @sSQLDocItem is not null and @sSQLDocItem != ''
					Begin
						Update @tbRecipients
						Set EmailSubject = @sSQLDocItem
						From @tbRecipients where DebtorNo = @nDebtorNo		
						
						Set @nErrorCode = @@ERROR			
					End
				End
				
				-- Update Email Body		
				If @nErrorCode = 0 and @sDocItemEmailBody is not null and @sDocItemEmailBody != ''
						and exists (select * from ITEM WHERE ITEM_NAME = @sDocItemEmailBody)
						and (@psEmailBody is null or @psEmailBody = '')
				Begin  
					exec @nErrorCode=dbo.[ipw_FetchDocItem]
								@pnUserIdentityId	= @pnUserIdentityId,		-- Mandatory
								@psCulture		= @psCulture,
								@pbCalledFromCentura	= 0,
								@psDocItem		= @sDocItemEmailBody,
								@psEntryPoint		= @nDebtorNo, -- Debtor No	
								@psEntryPointP1		= @pnEntityNo,
								@psEntryPointP2		= @pnPeriod,						
								@bIsCSVEntryPoint	= 0,
								@pbOutputToVariable	= 1,
								@psOutputString		= @sSQLDocItem output
					If @nErrorCode = 0 and @sSQLDocItem is not null and @sSQLDocItem != ''
					Begin
						Update @tbRecipients
						Set Body = @sSQLDocItem
						From @tbRecipients where DebtorNo = @nDebtorNo		
						
						Set @nErrorCode = @@ERROR			
					End
				End
				
			FETCH NEXT FROM DebtorStmtDocItem_Cursor 
				INTO @nDebtorNo
		End
		
		CLOSE DebtorStmtDocItem_Cursor
		DEALLOCATE DebtorStmtDocItem_Cursor
	 End

	 If @pbIsForSummary = 1
	 Begin
		Select DISTINCT 
			CAST(DebtorNo as nvarchar(11)) + '^' + DebtorCurrency as RowKey,
			DebtorNo,
			DebtorName,
			DebtorNameCode,
			EmailAddress,
			CopyTo,
			BlankCopyTo,
			EmailSubject,
			Body,		
			Case When DeliveryType = 2 Then "Print"
			     When DeliveryType = 3 Then "Email and Print"
			     When DeliveryType = 4 Then "Email Including Current Invoices"
			     When DeliveryType = 5 Then "Email Including Outstanding Invoices"
			     ELse "Email" End as DeliveryMethod,
			DebtorBalance,
			DebtorCurrency,
			DebtorCurrency + cast(DebtorBalance as nvarchar(100)) as FormattedBalance,
			DebtorRestriction,
			EntityNo,
			SortByColumn,
			DeliveryType
		From @tbRecipients
		order by SortByColumn, DebtorNameCode, DebtorName
	 End
	 Else
	 Begin		
		Select DISTINCT 
			DebtorNo,
			DebtorName,
			DebtorNameCode,
			EmailAddress,
			CopyTo,
			BlankCopyTo,
			EmailSubject,
			Body,
			StatementAttentionNo,
			StatementContactNo,
			StatementNameNo,
			DebtorContactNo,
			DeliveryType,
			SortByColumn
		From @tbRecipients
		order by SortByColumn, DebtorNameCode, DebtorName
	 End
	 	 
	 Drop table [dbo].#DEBTORSTATEMENT
 
End

Return @nErrorCode
GO

Grant execute on dbo.acw_ListDebtorStatementRecipients to public
GO