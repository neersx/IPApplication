-----------------------------------------------------------------------------------------------------------------------------
-- Creation of naw_ListRelationships
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[naw_ListRelationships]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.naw_ListRelationships.'
	Drop procedure [dbo].[naw_ListRelationships]
	Print '**** Creating Stored Procedure dbo.naw_ListRelationships...'
	Print ''
End
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.naw_ListRelationships
(
	@pnRowCount		int		= null output,
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pbCalledFromCentura	bit		= 0,
	@pnNameKey				int		= null
)
AS
-- PROCEDURE:	naw_ListRelationships
-- VERSION:	6
-- SCOPE:	Inpro.Net
-- DESCRIPTION:	Return RelationshipKey, RelationshipDescription, ReverseDescription form the NameRelation database table 
--		where ShowFlag = 1.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 19-Dec-2003	TM	RFC611	1	Procedure created
-- 15 Sep 2004	JEK	RFC886	2	Implement translation.
-- 15 May 2005	JEK	RFC2508	3	Extract @sLookupCulture and pass to translation instead of @psCulture
-- 11 Oct 2007	PG	RFC3501 4	Add @pnNameKey
-- 04 Mar 2009	PS	RFC7599 5	Filter CRM relationship if user do not have CRM licence.
-- 01 Oct 2014	LP	R9422	6	Cater for Marketing Module license

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare @nErrorCode 	int

Declare @sSQLString	nvarchar(500)
Declare @sString	nvarchar(500)

Declare @sLookupCulture		nvarchar(10)

Declare @nRelationUsedAs int

Declare @nNameUsedAs	smallint

set @sLookupCulture = dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)

Set	@nErrorCode      = 0
Set 	@pnRowCount	 = 0


If @nErrorCode = 0
Begin	
	Set @sSQLString = "
	Select 	R.RELATIONSHIP 		as 'RelationshipKey', 
		"+dbo.fn_SqlTranslatedColumn('NAMERELATION','RELATIONDESCR',null,'R',@sLookupCulture,@pbCalledFromCentura)
				+ " as 'RelationshipDescription',
		"+dbo.fn_SqlTranslatedColumn('NAMERELATION','REVERSEDESCR',null,'R',@sLookupCulture,@pbCalledFromCentura)
				+ " as 'ReverseDescription'
	from NAMERELATION R
	where R.SHOWFLAG = 1 " +
	CASE	WHEN dbo.fn_IsLicensedForCRM(@pnUserIdentityId, getdate())= 0 
		THEN char(10) + "	and R.CRMONLY != 1 or CRMONLY IS NULL" END
	
	If @pnNameKey is not null
	Begin		
		Set @sString='
		Select @nNameUsedAs=USEDASFLAG
		From NAME
		Where NAMENO=@pnNameKey'
		
		Exec  @nErrorCode=sp_executesql @sString,
					N'@nNameUsedAs	int	OUTPUT,
					  @pnNameKey	int',
					  @nNameUsedAs	=@nNameUsedAs	OUTPUT,
					  @pnNameKey	=@pnNameKey
		If (@nNameUsedAs = 0 or @nNameUsedAs =4)
		Begin
			Set @nRelationUsedAs = 4
		End
		Else If(@nNameUsedAs = 1 or @nNameUsedAs = 5)
		Begin
			Set @nRelationUsedAs = 2
		End
		Else If(@nNameUsedAs = 2 or @nNameUsedAs = 3)
		Begin
			Set @nRelationUsedAs = 1
		End
		Else
		Begin
			Set @nRelationUsedAs = @nNameUsedAs
		End
		Set @sSQLString = @sSQLString +" and ((cast(R.USEDBYNAMETYPE as int) & @nRelationUsedAs) = @nRelationUsedAs)"

	End
	Set @sSQLString = @sSQLString + " order by RelationshipDescription"

	Print @sSQLString
	If @pnNameKey is null
	Begin
		exec @nErrorCode = sp_executesql @sSQLString
	End
	Else
	Begin
		exec @nErrorCode = sp_executesql @sSQLString,
							N'@nRelationUsedAs int',	
							@nRelationUsedAs=@nRelationUsedAs
	End
	Set @pnRowCount = @@Rowcount
End


Return @nErrorCode
GO

Grant execute on dbo.naw_ListRelationships to public
GO
