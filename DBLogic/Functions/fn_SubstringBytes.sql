-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_SubstringBytes
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id('dbo.fn_SubstringBytes') and xtype='FN')
Begin
	Print '**** Drop Function dbo.fn_SubstringBytes'
	Drop function [dbo].[fn_SubstringBytes]
	Print '**** Creating Function dbo.fn_SubstringBytes...'
	Print ''
End
go

CREATE FUNCTION dbo.fn_SubstringBytes
(
	@psStringToClean	nvarchar(max),
	@pnFrom			smallint,
	@pnLength		smallint
)
RETURNS nvarchar(max)

-- FUNCTION	 :	fn_SubstringBytes
-- VERSION 	 :	3
-- DESCRIPTION	 :	Returns the passed string with all non numeric characters removed

-- MODIFICATIONS :
-- Date		Who	No.	Version	Change
-- ----		---	---	-------	---------------------------------------------------------
-- 07 Dec 2004  MF		1	Function created
-- 07 Dec 2004	MF	10738	2	Ensure that double byte characters are only included if the whole
--					character fits within the required number of bytes.
-- 14 Apr 2011	MF	10475	3	Change nvarchar(4000) to nvarchar(max)

AS
Begin
	
	Declare @sCleanString		nvarchar(max)
	Declare @sCurrentCharacter	nvarchar(1)
	Declare @nCharacter		smallint
	Declare @nStringLength		smallint
	Declare	@nCharCount		smallint
	
	If @psStringToClean is not null
	Begin
		Set @sCleanString  = ''
		Set @nCharacter    = @pnFrom
		Set @nStringLength = len(@psStringToClean)
		Set @nCharCount    = 0
		
		While @nCharacter <= @nStringLength
		and @nCharCount   <= @pnLength
		Begin
			Set @sCurrentCharacter = substring(@psStringToClean, @nCharacter, 1 )

			If unicode(@sCurrentCharacter) >1000
			Begin
				Set @nCharCount =@nCharCount + 2
				-- 2 byte characters are not to be included
				-- unless the full 2 bytes can fit within the required length
				If @nCharCount<=@pnLength
					Set @sCleanString = @sCleanString + @sCurrentCharacter 	
			End
			Else Begin
				Set @nCharCount =@nCharCount + 1
				Set @sCleanString = @sCleanString + @sCurrentCharacter 	
			End
			
			Set @nCharacter = @nCharacter + 1
		End
	End

	Return @sCleanString
End
go

grant execute on dbo.fn_SubstringBytes to public
go

