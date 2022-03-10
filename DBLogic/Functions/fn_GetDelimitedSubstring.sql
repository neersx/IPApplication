-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_GetDelimitedSubstring
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[fn_GetDelimitedSubstring]') and xtype in (N'FN', N'IF', N'TF'))
begin
	print '**** Drop function dbo.fn_GetDelimitedSubstring.'
	drop function [dbo].[fn_GetDelimitedSubstring]
	print '**** Creating function dbo.fn_GetDelimitedSubstring...'
	print ''
end
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

CREATE  FUNCTION [dbo].[fn_GetDelimitedSubstring]
(
	@sInputString	nvarchar(max),
	@sDelimiter 	nvarchar(5),
	@nBefore	bit,  ---If the string needs to be before or after the delimeter	
	@nLastOccurence   bit	--check for last occurence or first occurence of the delimeter
)
RETURNS nvarchar(max)
As
-- FUNCTION :	fn_GetDelimitedSubstring
-- VERSION :	2
-- DESCRIPTION:	Splits an input string before or after the first or last occurence of the delimeter .  
-- MODIFICATIONS :
-- Date		Who	Number	Version	Description
-- -----------	-------	------- ------- ----------------------------------------------- 
-- 20 Aug 2009	DV	RFC8016 1	Created
-- 14 Apr 2011	MF	RFC10475 2	Change nvarchar(4000) to nvarchar(max)



Begin
	DECLARE @sOutputString nvarchar(max)
	if charindex(@sDelimiter, @sInputString)=0
		set @sOutputString=@sInputString
	else
	Begin
		if @nLastOccurence = 0
		Begin
			if @nBefore = 1
				set @sOutputString=ltrim(substring(@sInputString, 1, CHARINDEX(@sDelimiter,@sInputString)-1))
			else
				set @sOutputString=ltrim(substring(@sInputString, charindex(@sDelimiter,@sInputString)+1, datalength(@sInputString)))
		End
		else
		Begin
			Declare @reverseSubString nvarchar(max)
			Set @reverseSubString = reverse(@sInputString);
			if @nBefore = 0
				set @sOutputString = reverse(left(@reverseSubString, charindex(@sDelimiter, @reverseSubString) -1))				
			else
				set @sOutputString = reverse(substring(@reverseSubString, charindex(@sDelimiter, @reverseSubString) + 1,datalength(@sInputString)))
		End
	End
	return  @sOutputString
End

GO
grant execute on dbo.fn_GetDelimitedSubstring to public
GO


