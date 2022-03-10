-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ipw_ListProfileAttributeData
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ipw_ListProfileAttributeData]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ipw_ListProfileAttributeData.'
	Drop procedure [dbo].[ipw_ListProfileAttributeData]
End
Print '**** Creating Stored Procedure dbo.ipw_ListProfileAttributeData...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.ipw_ListProfileAttributeData
(
	@pnUserIdentityId	int,		
	@psCulture		nvarchar(10) 	= null,
	@pnProfileKey           int,
	@pnAttributeKey         int             = null,
	@pbCalledFromCentura	bit		= 0
)
as
-- PROCEDURE:	ipw_ListProfileAttributeData
-- VERSION:	1
-- COPYRIGHT:	Copyright CPA Global Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Returns information about the specified user profile attribute.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 09 Sep 2009	LP	RFC4087	1	Procedure created

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

declare	@nErrorCode	int
declare @sSQLString     nvarchar(4000)
declare @sLookupCulture		nvarchar(10)

-- Initialise variables
Set @nErrorCode = 0
set @sLookupCulture = dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)


If @nErrorCode = 0
Begin
        If @pnAttributeKey is not null
        Begin
	        Set @sSQLString = "
	        Select  P.PROFILEID as ProfileKey,"+
                        dbo.fn_SqlTranslatedColumn('PROFILES','PROFILENAME',null,'P',@sLookupCulture,@pbCalledFromCentura)+ " as ProfileName,
	                A.ATTRIBUTEID as AttributeKey,
	                A.ATTRIBUTENAME as AttributeName,
	                PA.ATTRIBUTEVALUE as AttributeValue
	        from PROFILES P
	        join PROFILEATTRIBUTES PA on (PA.PROFILEID = P.PROFILEID)
	        join ATTRIBUTES A on (A.ATTRIBUTEID = PA.ATTRIBUTEID)
	        where P.PROFILEID = @pnProfileKey
	        and PA.ATTRIBUTEID = @pnAttributeKey
	        "
	        exec @nErrorCode = sp_executesql @sSQLString,
		        N'@pnProfileKey         int,
		          @pnAttributeKey       int',
		          @pnProfileKey         = @pnProfileKey,
		          @pnAttributeKey       = @pnAttributeKey		
        End
        Else
        Begin
                Set @sSQLString = "
	        Select  P.PROFILEID as ProfileKey,"+
                        dbo.fn_SqlTranslatedColumn('PROFILES','PROFILENAME',null,'P',@sLookupCulture,@pbCalledFromCentura)+ " as ProfileName,
	                NULL as AttributeKey,
	                NULL as AttributeName,
	                NULL as AttributeValue
	        from PROFILES P
	        where P.PROFILEID = @pnProfileKey"
	        
	        exec @nErrorCode = sp_executesql @sSQLString,
		        N'@pnProfileKey         int',
		          @pnProfileKey         = @pnProfileKey
		          
        End
End

Return @nErrorCode
GO

Grant execute on dbo.ipw_ListProfileAttributeData to public
GO
