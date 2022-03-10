-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ipw_ListValidActions
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ipw_ListValidActions]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ipw_ListValidActions.'
	Drop procedure [dbo].[ipw_ListValidActions]
End
Print '**** Creating Stored Procedure dbo.ipw_ListValidActions...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.ipw_ListValidActions
(
	@pnResult		int		= null output,	-- just an example
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pnCriteriaKey		int,
	@pbCalledFromCentura	bit		= 0
)
as
-- PROCEDURE:	ipw_ListValidActions
-- VERSION:	1
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	List all the valid Actions based on the Case Criteria

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 29 Dec 2009	MS	RFC8649	1	Procedure created

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

declare	@nErrorCode		int
Declare @sSQLString		nvarchar(max)
Declare @sLookupCulture		nvarchar(10)

-- Initialise variables
Set @nErrorCode		= 0
set @sLookupCulture	= dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)


If @nErrorCode = 0
Begin
	-- Some code here
	Set @sSQLString = "
	Select 	distinct VA.ACTION as ActionKey,
		"+dbo.fn_SqlTranslatedColumn('ACTIONS','ACTIONNAME',null,'A',@sLookupCulture,@pbCalledFromCentura)
				+ " as ActionName
	from CRITERIA C 
	join VALIDACTION VA on ((VA.CASETYPE = C.CASETYPE or C.CASETYPE is null)
				and (VA.PROPERTYTYPE = C.PROPERTYTYPE or C.PROPERTYTYPE is null)
				and VA.COUNTRYCODE = (	select min(VA1.COUNTRYCODE)
							from VALIDACTION VA1
							where VA1.CASETYPE = VA.CASETYPE
							and VA1.PROPERTYTYPE = VA.PROPERTYTYPE
							and VA1.COUNTRYCODE in (C.COUNTRYCODE, 'ZZZ')))	
	left join ACTIONS A on (A.ACTION = VA.ACTION)
	where CRITERIANO = @pnCriteriaKey
	order by 2"	

	exec @nErrorCode = sp_executesql @sSQLString, 
		N'@pnCriteriaKey int',
		  @pnCriteriaKey = @pnCriteriaKey
End

Return @nErrorCode
GO

Grant execute on dbo.ipw_ListValidActions to public
GO
