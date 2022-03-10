-----------------------------------------------------------------------------------------------------------------------------
-- Creation of dbo.na_GenerateNameCode
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[na_GenerateNameCode]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.na_GenerateNameCode.'
	Drop procedure [dbo].[na_GenerateNameCode]
	Print '**** Creating Stored Procedure dbo.na_GenerateNameCode...'
	Print ''
End
GO

SET QUOTED_IDENTIFIER OFF
GO

CREATE PROCEDURE dbo.na_GenerateNameCode
(
	@psNameCode		nvarchar(10) 	output,
	@pnUserIdentityId	int		-- Mandatory

)
-- PROCEDURE:	na_GenerateNameCode
-- VERSION :	4
-- DESCRIPTION:	The stored procedure generates and returns the next available
-- code for use on a name.  The code returned includes a check digit and is 
-- formatted ready for use on the name. Note: this processing includes updates
-- to the database.

-- MODIFICATIONS :
-- Date		Who	RFC	Version	Change
-- ------------	-------	------	-------	----------------------------------------------- 
-- 21-MAR-2006  SW		1	Procedure created
-- 11 Dec 2008	MF	17136	2	Improve performance on SiteControl table by removing use of UPPER in JOIN against CONTROLID	
-- 15 May 2009	DW	17650	3	Don't raise error if length exceeds value specified in 'NAMECODELENGTH' site control.
-- 17 Oct 2011	MF	R11433	4	Make checkdigit in generated namecode optional. Code supplied by client requesting change.
AS

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare @nErrorCode 		int
Declare @nLastSequenceNo 	int
Declare @nNameCodeLength	int
Declare @sAlertXML		nvarchar(1024)
Declare @sSQLString		nvarchar(max)
Declare @nRowCount		int
Declare	@bUseCheckdigit		bit		-- SQA20068

Set @nErrorCode = 0

-- Pre-check on site control LASTNAMECODE, if not exist then create one.
Set @sSQLString = '
	Select @nRowCount = count(CONTROLID)
	from SITECONTROL
	where CONTROLID = ''LASTNAMECODE'''

Exec @nErrorCode = sp_executesql @sSQLString,
		N'@nRowCount	int		OUTPUT',
		  @nRowCount	= @nRowCount	OUTPUT

If @nErrorCode = 0
and @nRowCount = 0
Begin
	Set @sSQLString = '
		Insert into SITECONTROL (CONTROLID, DATATYPE, COLCHARACTER, COMMENTS)
		values (''LASTNAMECODE'', ''C'', ''0'', ''The last name code number automatically allocated'')'

	Exec @nErrorCode=sp_executesql @sSQLString
End

-- SQA20068 
-- Determine if Check Digit is required for 
-- Name Code generation.
If @nErrorCode = 0
Begin
	Set @sSQLString = '
		Select @bUseCheckdigit = COLBOOLEAN
		from	SITECONTROL
		where	CONTROLID = ''Name Code has Check Digit'''

	Exec @nErrorCode = sp_executesql @sSQLString,
		N'@bUseCheckdigit	bit			OUTPUT',
		  @bUseCheckdigit	= @bUseCheckdigit	OUTPUT

	Set @bUseCheckdigit = ISNULL(@bUseCheckdigit,1)
End


If @nErrorCode = 0
Begin

	-- Default to 0 if LASTNAMECODE is null
	Set @sSQLString = 'Select @nLastSequenceNo = coalesce(COLCHARACTER, 0)
		from SITECONTROL
		where CONTROLID = ''LASTNAMECODE'''
	
	Exec @nErrorCode = sp_executesql @sSQLString,
				N'@nLastSequenceNo	int			OUTPUT',
				  @nLastSequenceNo	= @nLastSequenceNo	OUTPUT

	---------------------------------------------------
	-- If check digit is in use then remove check digit
	-- from the end of the last sequence no saved.
	---------------------------------------------------
	If @bUseCheckdigit = 1
	Begin
		Set @nLastSequenceNo = left(@nLastSequenceNo, len(@nLastSequenceNo) - 1)
	End

	-- Find out code length from site control
	Set @sSQLString = '
		Select @nNameCodeLength = COLINTEGER
		from SITECONTROL
		where CONTROLID = ''NAMECODELENGTH'''

	Exec @nErrorCode=sp_executesql @sSQLString,
				N'@nNameCodeLength	int		OUTPUT',
				  @nNameCodeLength	= @nNameCodeLength	OUTPUT

	-- Default @nNameCodeLength to 6 if null or 0
	If @nNameCodeLength is null 
	or @nNameCodeLength =  0
	Begin
		Set @nNameCodeLength = 6
	End

	-- Reset @nNameCodeLength to 10 if overflow
	If @nNameCodeLength > 10
	Begin
		Set @nNameCodeLength = 10
	End

	If @nErrorCode = 0
	Begin
		-- Set it to anything other than 0 to enter while loop
		Set @nRowCount = 1

		While (@nRowCount <> 0)
		Begin
			
			Set @nLastSequenceNo = @nLastSequenceNo + 1
			
			If @bUseCheckdigit = 1		-- SQA20068
				Set @psNameCode = cast(@nLastSequenceNo as varchar(9)) + dbo.fn_GetCheckDigit(@nLastSequenceNo)
			Else	
				Set @psNameCode = cast(@nLastSequenceNo as varchar(10))
				
			-- Pad 0 at the front
			Set @psNameCode = replicate('0', @nNameCodeLength - len(@psNameCode)) + @psNameCode
			
			-- Check if @psNameCode already exists on NAME.NAMECODE or not.
			Set @sSQLString='
				Select 	@nRowCount = count(NAMECODE)
				from	[NAME]
				where	NAMECODE = @psNameCode'
		
			Exec @nErrorCode=sp_executesql @sSQLString,
						N'@nRowCount	int		OUTPUT,
						  @psNameCode	nvarchar(10)',
						  @nRowCount	= @nRowCount	OUTPUT,
						  @psNameCode	= @psNameCode

			-- Escape while loop if errorcode not 0
			If @nErrorCode <> 0
			Begin
				Set @nRowCount = 0
			End
		End
	End
	
	If @nErrorCode = 0
	Begin
		-- Save the @psNameCode to site control LASTNAMECODE
		Set @sSQLString='
			Update 	SITECONTROL
			set	COLCHARACTER = @psNameCode
			where	CONTROLID = ''LASTNAMECODE'''
		
		Exec @nErrorCode = sp_executesql @sSQLString,
					N'@psNameCode	nvarchar(10)',
					  @psNameCode	= @psNameCode
	End
End

Return @nErrorCode
GO

Grant execute on dbo.na_GenerateNameCode to public
GO
