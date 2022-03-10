-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_FormatName
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[fn_FormatName]') and xtype in (N'FN', N'IF', N'TF'))
begin
	print '**** Drop function dbo.fn_FormatName.'
	drop function [dbo].[fn_FormatName]
	print '**** Creating function dbo.fn_FormatName...'
	print ''
end
GO

SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO

create Function dbo.fn_FormatName
			(
			@psName			nvarchar(254),
			@psFirstName		nvarchar(50),
			@psTitle		nvarchar(20),
			@pnNameStyle		int
			)
Returns nvarchar(254)

-- FUNCTION :	fn_FormatName
-- VERSION :	8
-- DESCRIPTION:	This function accepts the components of a Name and an optional style and returns
--		it as a formatted text string. 

-- MODIFICATIONS :
-- Date		Who	No.	Version	Change
-- ------------	-------	-------	-------	----------------------------------------------- 
-- 19 AUG 2002	MF		1	Function created
-- 21 AUG 2002	SF			Renamed from ipfn_FormatName to fn_FormatName
-- 28 JAN 2003	SF			Modify the standard presentation to be <Surname>, <Title> <Given Names>.
-- 27 AUG 2003	MF		5	Include the Title in the formatted name if it is supplied.
-- 28 AUG 2003	MF		6	Remove Title from the default format
-- 17 MAY 2004	JB	8117	7	Centura bug  - changed the return nvarchar from 400 to 254
-- 30 JUL 2008	MF	16761	8	Handle when components of Name are null.

Begin
	declare @sFormattedName	nvarchar(254)

	-- The Address styles are hardcode values as follows :
	-- 7101		Title SPACE First Names SPACE Family Name
	-- 7102		Family Name SPACE First Names
	-- Null		Family Name COMMA SPACE Title SPACE Firstnames

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

		Select @sFormattedName=isnull(@psName,'')	+CASE WHEN(@psFirstName is not null) THEN ', '+@psFirstName ELSE '' END
	End

	If @sFormattedName=''
		Set @sFormattedName=NULL

	Return ltrim(rtrim(@sFormattedName))
End
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

grant execute on dbo.fn_FormatName to public
GO
