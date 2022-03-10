-----------------------------------------------------------------------------------------------------------------------------
-- Creation of acw_ListMarginProfileRules
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[acw_ListMarginProfileRules]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.acw_ListMarginProfileRules.'
	Drop procedure [dbo].[acw_ListMarginProfileRules]
	Print '**** Creating Stored Procedure dbo.acw_ListMarginProfileRules...'
	Print ''
End
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.acw_ListMarginProfileRules
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pbCalledFromCentura	bit		= 0,
	@pnMarginProfileKey	int		-- Mandatory
)
AS
-- PROCEDURE:	acw_ListMarginProfileRules
-- VERSION:	1
-- SCOPE:	Inpro.Net
-- DESCRIPTION:	Returns a list of available margin profiles rules for the 
--		specified margin profile.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	-------	-------	----------------------------------------------- 
-- 17 Mar 2010	MS	RFC3298	1	Procedure created.


SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare @nErrorCode 		int
Declare @sSQLString		nvarchar(4000)
Declare @sLookupCulture		nvarchar(10)

set @sLookupCulture = dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)

Set	@nErrorCode      = 0

If @nErrorCode = 0
Begin
	Set @sSQLString = "Select
			CAST(R.PROFILETYPENO as nvarchar(11)) as 'RowKey', 
			"+dbo.fn_SqlTranslatedColumn('MARGINTYPE','DESCRIPTION',null,'T',@sLookupCulture,@pbCalledFromCentura)
			+ " as 'MarginType', 
			"+dbo.fn_SqlTranslatedColumn('COUNTRY','COUNTRY',null,'C',@sLookupCulture,@pbCalledFromCentura)
			+ " as 'Country', 				
			"+dbo.fn_SqlTranslatedColumn('CASETYPE','CASETYPEDESC',null,'CT',@sLookupCulture,@pbCalledFromCentura)
			+ " as 'CaseType', 
			"+dbo.fn_SqlTranslatedColumn('PROPERTYTYPE','PROPERTYNAME',null,'P',@sLookupCulture,@pbCalledFromCentura)
			+ " as 'PropertyType', 	
			"+dbo.fn_SqlTranslatedColumn('CASECATEGORY','CASECATEGORYDESC',null,'CC',@sLookupCulture,@pbCalledFromCentura)
			+ " as 'Category', 			
			"+dbo.fn_SqlTranslatedColumn('SUBTYPE','SUBTYPEDESC',null,'S',@sLookupCulture,@pbCalledFromCentura)
			+ " as 'SubType', 
			"+dbo.fn_SqlTranslatedColumn('ACTIONS','ACTIONNAME',null,'A',@sLookupCulture,@pbCalledFromCentura)
			+ " as 'Action'	                                                                                                                                                                                                                                                            
			FROM MARGINPROFILERULE R  
			join MARGINPROFILE M on (M.MARGINPROFILENO = R.MARGINPROFILENO)  
			left join COUNTRY C on (C.COUNTRYCODE = R.COUNTRYCODE)  
			left join PROPERTYTYPE P on (P.PROPERTYTYPE = R.PROPERTYTYPE)  
			left join MARGINTYPE T on (T.MARGINTYPENO = R.MARGINTYPENO)  
			left join CASETYPE CT on (CT.CASETYPE = R.CASETYPE)  
			left join CASECATEGORY CC on (CC.CASECATEGORY = R.CASECATEGORY  AND CC.CASETYPE = CT.CASETYPE)  
			left join SUBTYPE S on (S.SUBTYPE = R.SUBTYPE)  
			left join ACTIONS A on (A.ACTION = R.ACTION)  
			WHERE M.MARGINPROFILENO =  @pnMarginProfileKey
			ORDER BY 2, 3"

	exec @nErrorCode = sp_executesql @sSQLString,
			N'@pnMarginProfileKey	int',
			@pnMarginProfileKey	= @pnMarginProfileKey

End
Return @nErrorCode
GO

Grant execute on dbo.acw_ListMarginProfileRules to public
GO
