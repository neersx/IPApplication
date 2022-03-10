----------------------------------------------------------------------------------------------
-- Creation of dbo.na_InsertName
----------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[na_InsertName]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.na_InsertName.'
	Drop procedure [dbo].[na_InsertName]
	Print '**** Creating Stored Procedure dbo.na_InsertName...'
	Print ''
End
GO

SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO

CREATE procedure dbo.na_InsertName
(
	@pnUserIdentityId		int,		-- Mandatory
	@psCulture			nvarchar(10) 	= null,
	@psNameKey			varchar(11) 	output,
	@psNameCode			nvarchar(10) 	= null,
	@pnEntityType			int 		= null,	
	@pnNameUsedAs			int 		= null,	
	@psName				nvarchar(254),	-- Mandatory
	@psGivenNames			nvarchar(50) 	= null,
	@psTitleKey			nvarchar(20) 	= null,
	@psFormalSalutation		nvarchar(50) 	= null, 
	@psCasualSalutation		nvarchar(50) 	= null, 
	@psIncorporated			nvarchar(254) 	= null,
	@psNationalityKey		nvarchar(3) 	= null,
	@pdtDateCeased			datetime 	= null,
	@pbIsCPAReportable		decimal(1,0) 	= null,	
	@psTaxNumber			nvarchar(20) 	= null, 
	@psRemarks			nvarchar(254) 	= null,
	@pnNameStyle			int		= null
)
-- PROCEDURE:	na_InsertName
-- VERSION :	19
-- SCOPE:	CPA.net, IPNet
-- DESCRIPTION:	Insert a new name.

-- MODIFICATIONS :
-- Date		Who	Version	Change	Description
-- ------------	-------	-------	------	----------------------------------------- 
-- 04 Jul 2002  JB	1		Procedure created
-- 18 Jul 2002	JB	2		JB Tidied up, added doco and Standing Instructions
-- 25 Oct 2002 	SF	4		Added code to pad name code and generate searchkey.
-- 30 Oct 2002	SF	5 		Use the generated searchkey in the insert statement.  
-- 27 Nov 2002	SF	8		NameUsedAs Staff/Client
-- 06 Dec 2002	SF	9		Back out the 345 change.
-- 09 Dec 2002	SF	10		Re implement NameUsedAs Staff/Client with some modification.
-- 10 Mar 2003	JEK	11	RFC82	Localise stored procedure errors.
-- 22 May 2003  TM      12      RFC179	Name Code and Case Family Case Sensitivity
-- 07 Dec 2003	JEK	13	RFC408	Implement @pnNameStyle, and Individiual.
-- 15 Feb 2007	SW	14	RFC4757 Insert NAME.SOUNDEX column by fn_SoundsLike function.
-- 15 Jan 2008	Dw	15	9782	Tax No moved from Organisation to Name table.
-- 09 May 2008	Dw	16	16326	Extended salutation columns
-- 11 Dec 2008	MF	17	17136	Improve performance on SiteControl table by removing use of UPPER in JOIN against CONTROLID
-- 05 Mar 2009	MF	18	17453	Include an explict transaction to reduce the chance of locking.
-- 15 Apr 2013	DV	19	R13270	Increase the length of nvarchar to 11 when casting or declaring integer
as

Declare @nNameId int
	
-- assumes that a new row needs to be created.
-- get last internal code.
Declare @nUsedAs 		smallint
Declare @nErrorCode 		int	
Declare @TransactionCountStart	int
Declare @sSearchKey1 		nvarchar(20)
Declare @sSearchKey2 		nvarchar(20)
Declare @sAlertXML 		nvarchar(400)
Declare @sSex			nvarchar(1)
Declare @nCPACode		int

Set @nErrorCode = 0
Set @nUsedAs = 0
Set @psNameCode = upper(@psNameCode)            --Ensure name code is upper case   

If @pnEntityType = 1 		
	Set @nUsedAs = @nUsedAs | 0x0000 	-- Organisation (0x0000)				
Else
	Set @nUsedAs = @nUsedAs | 0x0001	-- Individual (0x0001)

if @pnNameUsedAs is null
	Set @pnNameUsedAs = 0

Set @nUsedAs = 
	Case @pnNameUsedAs
		When 1 then @nUsedAs | 0x0002	-- Staff (0x0002)
		When 3 then @nUsedAs | 0x0004	-- Client (0x0004)
	Else
		@nUsedAs	-- preseved whatever has been set at from the entitytype.
	End

If @pnEntityType = 1 -- Organisation
Begin
	Set @psGivenNames = null
	Set @psTitleKey = null
End

If @nErrorCode = 0
Begin
	-- Name Validation Add in.
	Set @sSearchKey1 = null
	Set @sSearchKey2 = null

	Exec @nErrorCode = dbo.na_GenerateSearchKey 
			@psSearchKey1 = @sSearchKey1 OUTPUT,
			@psSearchKey2 = @sSearchKey2 OUTPUT,
			@pnUserIdentityId = @pnUserIdentityId,
			@psCulture = @psCulture,
			@psName = @psName,
			@psGivenNames = @psGivenNames
End

If @pbIsCPAReportable = 1 
and @nErrorCode = 0
Begin

	-- Get the Standing Instruction code from the sitecontrol
	
	Select @nCPACode = COLINTEGER 
	From SITECONTROL
	Where CONTROLID= 'CPA Reportable Instr'
	
	Set @nErrorCode=@@Error

	If @nCPACode is null
	Begin
		Set @nErrorCode = -2
	End
End

If @nErrorCode = 0
and IsNumeric(@psNameCode)=1
Begin
	Select @psNameCode=Replicate('0',S.COLINTEGER-len(@psNameCode))+@psNameCode
	From 	SITECONTROL S
	Where	S.CONTROLID='NAMECODELENGTH'

	Set @nErrorCode = @@Error
End

If @nErrorCode = 0		
and Exists(Select * from NAME where NAMECODE=@psNameCode) 
Begin
	Set @sAlertXML = dbo.fn_GetAlertXML('NA1', 'Name code {0} is already in use.',
		'%s', null, null, null, null)
	RAISERROR(@sAlertXML, 12, 1, @psNameCode)
	Set @nErrorCode = @@ERROR		
End

If @nErrorCode = 0
and @psTitleKey is not null
Begin
	Select 	@sSex = GENDERFLAG
	from	TITLES
	where	GENDERFLAG in ('M','F')
	and	TITLE = @psTitleKey

	Set @nErrorCode = @@ERROR
End

If @nErrorCode = 0
Begin
	-- Start new transaction.
	Set @TransactionCountStart = @@TranCount
	BEGIN TRANSACTION
	
	-- Get the NameNo to use for the new Name.
	Exec @nErrorCode = dbo.ip_GetLastInternalCode 
				@pnUserIdentityId = @pnUserIdentityId,
				@psCulture = @psCulture,
				@psTable = 'NAME', 
				@pnLastInternalCode = @nNameId OUTPUT

	-------------------
	-- Convert the NameKey to be returned.
	If @nErrorCode = 0
		Set @psNameKey = Cast(@nNameId as nvarchar(11))
End	

-- Insert Name row
If @nErrorCode = 0
Begin
	Insert into [NAME] 
		(	[NAMENO],
			[NAMECODE],
			[NAME],
			[TITLE],
			[FIRSTNAME],
			[NATIONALITY],
			[REMARKS],
			[DATECEASED],
			[USEDASFLAG],
			[DATEENTERED],
			[TAXNO],
			[SEARCHKEY1],
			[SEARCHKEY2],
			[SOUNDEX],
			[NAMESTYLE]
		)
	values
		(	@nNameId,
			@psNameCode,
			@psName,
			@psTitleKey,
			@psGivenNames,
			@psNationalityKey,
			@psRemarks,
			@pdtDateCeased,
			@nUsedAs,
			getdate(),
			@psTaxNumber, 
			@sSearchKey1,
			@sSearchKey2,
			dbo.fn_SoundsLike(@psName),
			@pnNameStyle
		)					
	Set @nErrorCode = @@Error
End

-------------------
-- Add Main Orgainasation / Individual Row
If @nErrorCode = 0
Begin
	If @pnEntityType = 1 -- Organisation
	Begin
		Insert into [ORGANISATION]
			(	[NAMENO], 
				[INCORPORATED])
		values 	
			(	@nNameId, 
				@psIncorporated)
	End
	Else		-- Individual
	Begin
		Insert into [INDIVIDUAL]
			(	[NAMENO],
				[FORMALSALUTATION], 
				[CASUALSALUTATION],
				[SEX])
		values	
			(	@nNameId, 
				@psFormalSalutation, 
				@psCasualSalutation,
				@sSex)
	End
	Set @nErrorCode = @@Error
End

If @nErrorCode = 0
Begin
	If @pnNameUsedAs = 1 -- Staff (/ Company not implemented)
	Begin
		Insert into EMPLOYEE
		(
			EMPLOYEENO,
			ENDDATE
		)
		values
		(
			@nNameId,
			@pdtDateCeased
		)
	End
	
	If @pnNameUsedAs = 3 -- Client
	Begin
		Insert into IPNAME
		(
			NAMENO
		)
		values
		(
			@nNameId
		)
	End
	
	Set @nErrorCode = @@Error
End	

-- NOTE FROM MICHAEL FLEMING
-- The following code looks very questionable to me as I cannot think of
-- reason why we would enforce adding a specific standing instruction against
-- a name.  I am leaving the code here at the moment because more analysis is
-- required and from what I can see it is currently not being executed.
If @pbIsCPAReportable = 1 
and @nErrorCode = 0
Begin
	If @nCPACode is not null
	Begin
		-- Add NAMEINSTRUCTIONS
		Exec @nErrorCode = na_InsertNameInstructions 
					@pnUserIdentityId = @pnUserIdentityId,
					@psCulture = @psCulture,
					@pnNameNo = @nNameId,
					@pnInstructionCode = @nCPACode
	End
End	-- @pbIsCPAReportable

-- Commit transaction if successful.
If @@TranCount > @TransactionCountStart
Begin
	If @nErrorCode = 0
		COMMIT TRANSACTION
	Else
		ROLLBACK TRANSACTION
End

Return @nErrorCode
GO

Grant execute on dbo.na_InsertName to public
GO
