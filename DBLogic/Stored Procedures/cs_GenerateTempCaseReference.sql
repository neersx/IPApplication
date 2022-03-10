-----------------------------------------------------------------------------------------------------------------------------
-- Creation of cs_GenerateTempCaseReference
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[cs_GenerateTempCaseReference]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.cs_GenerateTempCaseReference.'
	Drop procedure [dbo].[cs_GenerateTempCaseReference]
End
Print '**** Creating Stored Procedure dbo.cs_GenerateTempCaseReference...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.cs_GenerateTempCaseReference
(
	@psCaseReference	nvarchar(30)	= null output,	-- generated temporary case reference
	@pnUserIdentityId	int		-- Mandatory
)
as
-- PROCEDURE:	cs_GenerateTempCaseReference
-- VERSION:	2
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Generate a temporary case reference

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 07 Jul 2006	SW	RFC3248	1	Procedure created
-- 11 Dec 2008	MF	17136	2	Improve performance on SiteControl table by removing use of UPPER in JOIN against CONTROLID

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

declare	@nErrorCode		int
Declare @sAlertXML		nvarchar(1024)
Declare @sSQLString		nvarchar(4000)
Declare @nRowCount		int

Declare @nLastSequenceNo 	int
Declare @nIRNLength		int
Declare @bIRCheckDigit		bit

-- Initialise variables
Set @nErrorCode = 0

-- Pre-check on site control LASTIRN, if not exist then create one.
If @nErrorCode = 0
Begin
	Set @sSQLString = '
		Select @nRowCount = count(CONTROLID)
		from SITECONTROL
		where CONTROLID = ''LASTIRN'''
	
	Exec @nErrorCode = sp_executesql @sSQLString,
			N'@nRowCount	int		OUTPUT',
			  @nRowCount	= @nRowCount	OUTPUT
End

If @nErrorCode = 0
and @nRowCount = 0
Begin
	Set @sSQLString = '
		Insert into SITECONTROL (CONTROLID, DATATYPE, COLCHARACTER, COMMENTS)
		values (''LASTIRN'', ''C'', ''0'', ''The last case reference no. automatically allocated'')'

	Exec @nErrorCode=sp_executesql @sSQLString
End

-- Get values from SITECONTROL
If @nErrorCode = 0
Begin
	-- Default @nLastSequenceNo to 0 if null
	-- Default @nIRNLength to 10 if null or 0
	-- Reset @nIRNLength to 30 if overflow
	Set @sSQLString = '
		Select 	@nLastSequenceNo = coalesce(IRN.COLCHARACTER, 0),
			@bIRCheckDigit = IRCD.COLBOOLEAN,
			@nIRNLength = CASE WHEN IRLEN.COLINTEGER is null or IRLEN.COLINTEGER = 0
			                   THEN 10
			                   WHEN IRLEN.COLINTEGER > 30
			                   THEN 30
			                   ELSE IRLEN.COLINTEGER
			              END
		from SITECONTROL IRN
		left join SITECONTROL IRCD on (IRCD.CONTROLID = ''IR Check Digit'')
		left join SITECONTROL IRLEN on (IRLEN.CONTROLID = ''IRNLENGTH'')
		where IRN.CONTROLID = ''LASTIRN'''
	
	Exec @nErrorCode=sp_executesql @sSQLString,
				N'@nLastSequenceNo	int			OUTPUT,
				  @bIRCheckDigit	bit			OUTPUT,
				  @nIRNLength		int			OUTPUT',
				  @nLastSequenceNo	= @nLastSequenceNo	OUTPUT,
				  @bIRCheckDigit	= @bIRCheckDigit	OUTPUT,
				  @nIRNLength		= @nIRNLength		OUTPUT

	-- Drop check digit in calculation if SITECONTROL IR CHECK DIGIT is on
	If @bIRCheckDigit = 1 and len(@nLastSequenceNo) > 1
	Begin
		Set @nLastSequenceNo = left(@nLastSequenceNo, len(@nLastSequenceNo) - 1)
	End
End

If @nErrorCode = 0
Begin
	-- Set it to anything other than 0 to enter while loop
	Set @nRowCount = 1

	While (@nRowCount <> 0)
	Begin
		
		Set @nLastSequenceNo = @nLastSequenceNo + 1

		-- Append check digit if site control "IR Check Digit" is on
		If @bIRCheckDigit = 1
		Begin
			Set @psCaseReference = cast(@nLastSequenceNo as varchar(29)) + dbo.fn_GetCheckDigit(@nLastSequenceNo)
		End
		else
		Begin
			Set @psCaseReference = cast(@nLastSequenceNo as varchar(30))
		End

		If len(@psCaseReference) > @nIRNLength
		Begin
			Set @sAlertXML = dbo.fn_GetAlertXML('CS75', 'Generated temporary case reference {0} exceeds maximum length of {1}.',@psCaseReference,@nIRNLength,null,null,null)
			Raiserror(@sAlertXML, 14, 1)

			-- Escape while loop when overflown
			Set @nRowCount = 0
		End
		Else
		Begin
			-- Pad 0 at the front
			Set @psCaseReference = replicate('0', @nIRNLength - len(@psCaseReference)) + @psCaseReference

			-- Check if @psCaseReference already exists on CASES.IRN or not.
			Set @sSQLString='
				Select 	@nRowCount = count(IRN)
				from	CASES
				where	IRN = @psCaseReference'
		
			Exec @nErrorCode=sp_executesql @sSQLString,
						N'@nRowCount		int		OUTPUT,
						  @psCaseReference	nvarchar(30)',
						  @nRowCount		= @nRowCount	OUTPUT,
						  @psCaseReference	= @psCaseReference

			-- Escape while loop if errorcode not 0
			If @nErrorCode <> 0
			Begin
				Set @nRowCount = 0
			End

		End
	

	End
End

If @nErrorCode = 0
Begin
	-- Save the @psCaseReference to site control LASTIRN
	Set @sSQLString='
		Update 	SITECONTROL
		set	COLCHARACTER = @psCaseReference
		where	CONTROLID = ''LASTIRN'''
	
	Exec @nErrorCode = sp_executesql @sSQLString,
				N'@psCaseReference	nvarchar(30)',
				  @psCaseReference	= @psCaseReference
End

Return @nErrorCode
GO

Grant execute on dbo.cs_GenerateTempCaseReference to public
GO
