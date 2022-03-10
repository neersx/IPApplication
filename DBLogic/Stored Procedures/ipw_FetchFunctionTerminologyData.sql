-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ipw_FetchFunctionTerminologyData
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ipw_FetchFunctionTerminologyData]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ipw_FetchFunctionTerminologyData.'
	Drop procedure [dbo].[ipw_FetchFunctionTerminologyData]
End
Print '**** Creating Stored Procedure dbo.ipw_FetchFunctionTerminologyData...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.ipw_FetchFunctionTerminologyData
(
	@pnUserIdentityId		int,		-- Mandatory
	@psCulture			nvarchar(10) 	= null,
	@pnFunctionTerminologyKey		int		= null,	
	@pbCalledFromCentura		bit		= 0
)
as
-- PROCEDURE:	ipw_ListFunctionTerminologyData
-- VERSION:	1
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Programmer comments here

-- MODIFICATIONS :
-- Date			Who	Change	Version	Description
-- -----------	--- ------  ------  -------------------------------------------------- 
-- 15 Mar 2010	PA	8378	1		Procedure created

SET CONCAT_NULL_YIELDS_NULL OFF
-- Row counts required by the data adapter
SET NOCOUNT OFF

Declare	@nErrorCode	int
Declare @sSQLString 		nvarchar(4000)
Declare @sLookupCulture		nvarchar(10)


-- Initialise variables
Set @nErrorCode = 0
Set @sLookupCulture = dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)
-- populate the FunctionTerminology data table
If @nErrorCode = 0
Begin
	Set @sSQLString ="
		Select	Cast(ISNULL(B.FUNCTIONTYPE,0) as nvarchar(10)) as 'RowKey',
			B.FUNCTIONTYPE		as 'FunctionType',
			"+dbo.fn_SqlTranslatedColumn('BUSINESSFUNCTION','DESCRIPTION',null,'B',@sLookupCulture,@pbCalledFromCentura)
					+ " 			as FunctionTypeDescription
	from	BUSINESSFUNCTION B
	where	B.FUNCTIONTYPE = @pnFunctionTerminologyKey"

	exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnFunctionTerminologyKey		int',
					@pnFunctionTerminologyKey		= @pnFunctionTerminologyKey
	
End

Return @nErrorCode
GO

Grant execute on dbo.ipw_FetchFunctionTerminologyData to public
GO
