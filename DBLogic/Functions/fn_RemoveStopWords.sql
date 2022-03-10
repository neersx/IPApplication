-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_RemoveStopWords
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id('dbo.fn_RemoveStopWords') and xtype='FN')
Begin
	Print '**** Drop Function dbo.fn_RemoveStopWords.'
	Drop function [dbo].[fn_RemoveStopWords]
	Print '**** Creating Function dbo.fn_RemoveStopWords...'
	Print ''
End
GO

SET QUOTED_IDENTIFIER OFF
GO

CREATE FUNCTION dbo.fn_RemoveStopWords
(
	@psDirtySentence	nvarchar(max)
)
RETURNS nvarchar(max)

-- PROCEDURE:	fn_RemoveStopWords
-- VERSION :	6
-- DESCRIPTION:	Returns the passed Sentence with all stop words removed

-- MODIFICATIONS :
-- Date		Who	Version	Change	Description
-- ------------	-------	-------	------	----------------------------------------- 
-- 21-OCT-2002  JB	1		Function created
-- 08 Nov 2002	JB	2		It was removing double spaces
-- 07 Feb 2003  MF	5		Correct spelling mistakes
-- 14 Apr 2011	MF	6	RFC10475 Change nvarchar(4000) to nvarchar(max)

AS
Begin
	Declare @sCleanSentence		nvarchar(max)
	Declare @sCurrentWord		nvarchar(max)
	Declare @sWorkingSentence	nvarchar(max)
	Declare @nCurrentSpace		int
	Declare @nNextSpace		int
	Declare @bRemovedWord		bit

	Set @bRemovedWord = 0
	
	If @psDirtySentence is not null
	Begin
		Set @nCurrentSpace = 0
		Set @sCleanSentence = ''
		Set @sWorkingSentence = LTRIM(RTRIM(@psDirtySentence)) + ' '

		Set @nNextSpace = CHARINDEX(' ', @sWorkingSentence, @nCurrentSpace+1)
		
		While @nNextSpace > 0
		Begin
			Set @sCurrentWord = UPPER(RTRIM(LTRIM(SUBSTRING(@sWorkingSentence, @nCurrentSpace, @nNextSpace-@nCurrentSpace))))
			If LEN(@sCurrentWord) > 0 
			Begin
				If exists (Select * from KEYWORDS 
					   where KEYWORD = @sCurrentWord
				           and STOPWORD in (2,3) )
					Set @bRemovedWord = 1
				Else
					Set @sCleanSentence = @sCleanSentence + ' ' + @sCurrentWord
			End
			Set @nCurrentSpace = @nNextSpace

			Set @nNextSpace = CHARINDEX(' ', @sWorkingSentence, @nCurrentSpace+1)
		End

		If @bRemovedWord = 1 
			Set @sCleanSentence = LTRIM(@sCleanSentence)
		Else 
			Set @sCleanSentence = @psDirtySentence
	End
	RETURN @sCleanSentence
End
GO

Grant execute on dbo.fn_RemoveStopWords to public 
go
