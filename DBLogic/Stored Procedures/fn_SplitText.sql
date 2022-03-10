-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_SplitText
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id('dbo.fn_SplitText') and xtype='FN')
Begin
	Print '**** Drop Function dbo.fn_SplitText'
	Drop function [dbo].[fn_SplitText]
End
Print '**** Creating Function dbo.fn_SplitText...'
Print ''


GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

Create  function dbo.fn_SplitText
			(
			@sInputString	nvarchar(max),
			@sDelimiter 	nvarchar(5),
			@nFromLineNo	smallint,	
			@nToLineNo		smallint 
			)
Returns nvarchar(max)
as
-- FUNCTION :	fn_SplitText
-- VERSION :	2
-- DESCRIPTION:	Splits an input string up using the input delimiter as an end of line marker
--		and returns the requested lines.  If the @nToLineNo < @nFromLineNo then returns the remaining text 
--		from the @nFromLineNo
-- MODIFICATIONS :
-- Date		Who	Number	Version	Description
-- -----------	-------	--------	-------	----------------------------------------------- 
-- 28 Mar 2007	DL	SQA12331 1	Created
-- 14 Apr 2011	MF	10475 	 5	Change nvarchar(4000) to nvarchar(max)



Begin
	declare @nCounter	smallint,
	@sString nvarchar(max)

	set	@nCounter	=1
	set 	@sInputString=ltrim(@sInputString)

	-- loop until each unrequired line has been removed from the input string.

	WHILE @nCounter < @nFromLineNo
	and   @sInputString is not null
	BEGIN
		if charindex(@sDelimiter, @sInputString)=0
		 	set @sInputString=null
		else	
			set @sInputString=ltrim(substring(@sInputString, CHARINDEX(@sDelimiter,@sInputString)+1, datalength(@sInputString)))
	
		set @nCounter=@nCounter+1
	END

	-- Now return the string from the begining of the remaining string up to the next
	-- @sDelimiter if @nFromLineNo = @nToLineNo
	if charindex(@sDelimiter, @sInputString)>0 and @nFromLineNo = @nToLineNo
		set @sInputString =  substring(@sInputString,1, CHARINDEX(@sDelimiter,@sInputString)-1)

	-- Get the rest of the lines upto the @nToLineNo
	else if @nFromLineNo < @nToLineNo
	Begin
		set @nCounter=@nFromLineNo
		While @nCounter <= @nToLineNo	and   @sInputString is not null
		Begin
			if charindex(@sDelimiter, @sInputString)>0
			Begin
				set @sString = ltrim( COALESCE(@sString, '') + ' ' + substring(@sInputString,1, CHARINDEX(@sDelimiter,@sInputString)-1) )
				set @sInputString=ltrim(substring(@sInputString, CHARINDEX(@sDelimiter,@sInputString)+1, datalength(@sInputString)))
			End
			Else
			Begin
				Set @sString = ltrim( COALESCE(@sString, '') + ' ' + COALESCE(@sInputString, '') )
				set @sInputString = null
			End
			set @nCounter=@nCounter+1
		End
		set @sInputString = @sString
	End

	return  @sInputString
End


GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

grant execute on dbo.fn_SplitText to public
GO
