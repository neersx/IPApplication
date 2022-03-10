-----------------------------------------------------------------------------------------------------------------------------
-- Creation of naw_ListTitles
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[naw_ListTitles]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.naw_ListTitles.'
	Drop procedure [dbo].[naw_ListTitles]
End
Print '**** Creating Stored Procedure dbo.naw_ListTitles...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.naw_ListTitles
(
	@pnRowCount		int		= null output,
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@psGenderCode		nchar(1)	= null, 	-- (M-Male, F-Female, B-Both)
	@psPickListSearch	nvarchar(30)	= null,
	@psTitleKey		nvarchar(20)	= null
)
as
-- PROCEDURE:	naw_ListTitles
-- VERSION:	5
-- DESCRIPTION:	List all the titles (Mr, Mrs etc.) that are available for selection.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 05 Dec 2003	JEK	RFC408	1	Procedure created
-- 11 Apr 2006	PG	RFC3212	2	Return TitleKey, GenderFlag and IsDefault
-- 19 May 2006	SW	RFC3492	3	Add 2 new optional parameters @psGenderCode and @psPickListSearch
-- 23 Jun 2006	SW	RFC4035	4	Male and Female need to show Both as well.
-- 03 Jul 2006	IB	RFC4059	5	Add an optional parameter @psTitleKey.  If @psTitleKey is not null 
--					return the row where TITLES.TITLE = @psTitleKey.

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare	@nErrorCode	int
Declare @sSQLString	nvarchar(4000)

-- Initialise variables
Set @nErrorCode = 0

If @nErrorCode = 0
Begin

	Set @sSQLString = "
		Select 	TITLE As Title, 
			TITLE As TitleKey, 
			GENDERFLAG As GenderFlag, 
			CAST(DEFAULTFLAG as bit) As IsDefault
		from	TITLES
		where	1 = 1
	"

	If @psGenderCode is not null and @psGenderCode <> ''
	Begin
		Set @sSQLString = @sSQLString + char(10)
			+ "		and GENDERFLAG in (@psGenderCode, 'B')"
	End

	If @psPickListSearch is not null
	Begin
		Set @sSQLString = @sSQLString + char(10)
			+ "		and UPPER(TITLE) like " + dbo.fn_WrapQuotes(UPPER(@psPickListSearch) + '%', 0, 0)
	End

	If @psTitleKey is not null
	Begin
		Set @sSQLString = @sSQLString + char(10)
			+ "		and TITLE = " + dbo.fn_WrapQuotes(@psTitleKey, 0, 0)
	End
	
	Set @sSQLString = @sSQLString + char(10)
		+ "		ORDER BY TITLE"

	Exec @nErrorCode = sp_executesql @sSQLString,
				N'@psGenderCode		nchar(1)',
				  @psGenderCode		= @psGenderCode

	Set @pnRowCount = @@ROWCOUNT
End

Return @nErrorCode
GO

Grant execute on dbo.naw_ListTitles to public
GO
