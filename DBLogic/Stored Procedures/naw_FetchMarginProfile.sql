-----------------------------------------------------------------------------------------------------------------------------
-- Creation of naw_FetchMarginProfile
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[naw_FetchMarginProfile]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.naw_FetchMarginProfile.'
	Drop procedure [dbo].[naw_FetchMarginProfile]
End
Print '**** Creating Stored Procedure dbo.naw_FetchMarginProfile...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.naw_FetchMarginProfile
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pbCalledFromCentura	bit		= 0,
	@pnNameKey		int,		-- Mandatory
	@pbNewRow		bit		= 0
)
as
-- PROCEDURE:	naw_FetchMarginProfile
-- VERSION:	1
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Populate the Margin Profile business entity.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 17 Mar 2010	MS	RFC3298	1	Procedure created

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare @nErrorCode	int
Declare @sSQLString 	nvarchar(4000)
Declare @sLookupCulture	nvarchar(10)

-- Initialise variables
Set @nErrorCode = 0
Set @sLookupCulture = dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)

If @nErrorCode = 0
Begin	
	If @pbNewRow = 1
	Begin
		If @nErrorCode = 0
		Begin
			Select 	null		as RowKey,
				@pnNameKey	as NameKey,
				null		as WIPCategoryCode,
				null		as WIPTypeCode,
				null		as MarginProfileKey				
		End

	End
	Else
	Begin
		Set @sSQLString = "SELECT  
			CAST(NMP.NAMENO as varchar(11)) + '^' + CAST(NMP.NAMEMARGINSEQNO as varchar(11))  
				as 'RowKey',  
			NMP.NAMENO as 'NameKey',
			Cast(NMP.NAMEMARGINSEQNO as int) as 'Sequence',
			NMP.CATEGORYCODE as 'WIPCategoryCode',		
			"+dbo.fn_SqlTranslatedColumn('WIPCATEGORY','DESCRIPTION',null,'WC',@sLookupCulture,@pbCalledFromCentura)
					+ " as 'WIPCategory', 
			NMP.WIPTYPEID as 'WIPTypeCode',		
			"+dbo.fn_SqlTranslatedColumn('WIPTYPE','DESCRIPTION',null,'WT',@sLookupCulture,@pbCalledFromCentura)
					+ " as 'WIPType', 		 
			NMP.MARGINPROFILENO as 'MarginProfileKey',  
			"+dbo.fn_SqlTranslatedColumn('MARGINPROFILE','PROFILENAME',null,'MP',@sLookupCulture,@pbCalledFromCentura)
					+ " as 'MarginProfileName'                                                                                                                        
		FROM  NAMEMARGINPROFILE NMP  
		JOIN WIPCATEGORY WC on (NMP.CATEGORYCODE = WC.CATEGORYCODE)  
		LEFT JOIN WIPTYPE WT on (NMP.WIPTYPEID = WT.WIPTYPEID)  
		LEFT JOIN MARGINPROFILE MP on (NMP.MARGINPROFILENO = MP.MARGINPROFILENO)  
		WHERE  NMP.NAMENO = @pnNameKey
		order by 'WIPCategory', 'WIPType', 'MarginProfileName'"

		exec @nErrorCode=sp_executesql @sSQLString,
				N'@pnNameKey		int',
				@pnNameKey		= @pnNameKey
	End
	

End

Return @nErrorCode
GO

Grant execute on dbo.naw_FetchMarginProfile to public
GO
