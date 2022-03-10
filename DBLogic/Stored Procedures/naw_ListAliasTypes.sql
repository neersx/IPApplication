-----------------------------------------------------------------------------------------------------------------------------
-- Creation of naw_ListAliasTypes
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[naw_ListAliasTypes]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.naw_ListAliasTypes.'
	Drop procedure [dbo].[naw_ListAliasTypes]
	Print '**** Creating Stored Procedure dbo.naw_ListAliasTypes...'
	Print ''
End
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.naw_ListAliasTypes
(
	@pnRowCount		int		= null output,
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pbCalledFromCentura	bit		= 0
)
AS
-- PROCEDURE:	naw_ListAliasTypes
-- VERSION:	5
-- SCOPE:	Inpro.Net
-- DESCRIPTION:	Return AliasTypeKey, AliasTypeDescription from AliasType table. 

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 19-Dec-2003	TM	RFC611	1	Procedure created
-- 15 Sep 2004	JEK	RFC886	2	Implement translation.
-- 15 May 2005	JEK	RFC2508	3	Extract @sLookupCulture and pass to translation instead of @psCulture
-- 17 Mar 2006	IB	RFC3325	4	Enforce subset security by implementing fn_FilterUserAliasTypes.
-- 11 Apr 2013	DV	R13270	5	Increase the length of nvarchar to 11 when casting or declaring integer


SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare @nErrorCode 		int
Declare @sSQLString		nvarchar(500)
Declare @sLookupCulture		nvarchar(10)

set @sLookupCulture = dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)

Set	@nErrorCode      = 0
Set 	@pnRowCount	 = 0

If @nErrorCode = 0
Begin	
	Set @sSQLString = "
	Select 	A.ALIASTYPE 		as 'AliasTypeKey', 
		"+dbo.fn_SqlTranslatedColumn('ALIASTYPE','ALIASDESCRIPTION',null,'A',@sLookupCulture,@pbCalledFromCentura)
				+ " as 'AliasTypeDescription'		
	from ALIASTYPE A
	join dbo.fn_FilterUserAliasTypes(" + cast(@pnUserIdentityId as varchar(11)) + ", null, null, " + cast(@pbCalledFromCentura as varchar(1)) + ") FUAT "
				+ " on (FUAT.ALIASTYPE = A.ALIASTYPE)
	order by AliasTypeDescription"
	
	exec @nErrorCode = sp_executesql @sSQLString

	Set @pnRowCount = @@Rowcount
End


Return @nErrorCode
GO

Grant execute on dbo.naw_ListAliasTypes to public
GO
