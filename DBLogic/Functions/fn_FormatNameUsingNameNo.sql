-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_FormatNameUsingNameNo
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[fn_FormatNameUsingNameNo]') and xtype in (N'FN', N'IF', N'TF'))
begin
	print '**** Drop function dbo.fn_FormatNameUsingNameNo.'
	drop function [dbo].[fn_FormatNameUsingNameNo]
	print '**** Creating function dbo.fn_FormatNameUsingNameNo...'
	print ''
end
GO

SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO

create Function dbo.fn_FormatNameUsingNameNo
			(
			@pnNameNo	int,
			@pnNameStyle	int
			)
Returns nvarchar(254)

-- FUNCTION :	fn_FormatNameUsingNameNo
-- VERSION :	2
-- DESCRIPTION:	This function accepts the NameNo and a style and then
--		finds the name details and returns the name in a formatted string.

-- MODIFICATIONS :
-- Date		Who	No.	Version	Change
-- ------------	-------	-------	-------	----------------------------------------------- 
-- 02 Nov 2015	vql	R53910	1	Function created
-- 12 Jan 2016	KR	R56954	2	Return only 254 characters

Begin
	Declare @sTitle		nvarchar(20)
	Declare @sFirstNames	nvarchar(50)
	Declare @sMiddleName	nvarchar(50)
	Declare @sName		nvarchar(254)
	Declare @sSuffix	nvarchar(20)

	-- get components of the name.
	Select 	@sTitle	= TITLE, @sFirstNames = FIRSTNAME, @sMiddleName = MIDDLENAME, @sName = NAME, @sSuffix = SUFFIX
	from NAME where NAMENO = @pnNameNo

	Return dbo.fn_FormatFullName(@sName, @sFirstNames, @sMiddleName, @sSuffix, @sTitle, @pnNameStyle)
End
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

grant execute on dbo.fn_FormatNameUsingNameNo to public
GO
