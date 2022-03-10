-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_FormatFullName
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[fn_FormatFullName]') and xtype in (N'FN', N'IF', N'TF'))
begin
	print '**** Drop function dbo.fn_FormatFullName.'
	drop function [dbo].[fn_FormatFullName]
	print '**** Creating function dbo.fn_FormatFullName...'
	print ''
end
GO

SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO

create Function dbo.fn_FormatFullName
			(
			@psName			nvarchar(254),
			@psFirstName		nvarchar(50),
			@psMiddleName		nvarchar(50),
			@psSuffix		nvarchar(20),			
			@psTitle		nvarchar(20),
			@pnNameStyle		int
			)
Returns nvarchar(254)

-- FUNCTION :	fn_FormatFullName
-- VERSION :	2
-- DESCRIPTION:	This function accepts the components of a Name including middle name 
--		and suffix and a style and returns the name as a formatted string.

-- MODIFICATIONS :
-- Date		Who	No.	Version	Change
-- ------------	-------	-------	-------	----------------------------------------------- 
-- 02 Nov 2015	vql	R53910	1	Function created.
-- 12 Jan 2015	KR	R56954	2	Return only 254 characters

Begin
	Declare @sFormattedName	nvarchar(500)

	-- The Address styles are hardcode values as follows :
	-- 7101		Title SPACE First Names SPACE Family Name
	-- 7102		Family Name SPACE First Names
	-- Null		Family Name COMMA SPACE Title SPACE Firstnames

	-- cater for middle name and suffix
	If (@psMiddleName is not null)
	Begin
		Set @psFirstName = rtrim(ltrim(isnull(@psFirstName, '')+' '+@psMiddleName))
	End

	If (@psSuffix is not null)
	Begin
		Set @psName = rtrim(ltrim(@psName+' '+@psSuffix))
	End

	If @pnNameStyle=7101
	begin
		-- First Names SPACE Family Name
		Select @sFormattedName= CASE WHEN(@psTitle     is not null) THEN @psTitle    +' ' ELSE '' END +
					CASE WHEN(@psFirstName is not null) THEN @psFirstName+' ' ELSE '' END + 
					isnull(@psName,'')
	End
	Else If @pnNameStyle=7102
	begin
		-- Family Name SPACE First Names
		Select @sFormattedName=	isnull(@psName,'')+
					CASE WHEN(@psFirstName is not null) THEN ' '+ @psFirstName ELSE '' END+
					CASE WHEN(@psTitle     is not null) THEN ' '+ @psTitle     ELSE '' END
	End
	Else begin
		-- Family Name COMMA SPACE Firstnames
		Select @sFormattedName=isnull(@psName,'')+CASE WHEN(@psFirstName is not null) THEN ', '+@psFirstName ELSE '' END
	End

	If @sFormattedName=''
		Set @sFormattedName=null

	Return ltrim(rtrim(@sFormattedName))
End
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

grant execute on dbo.fn_FormatFullName to public
GO