-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ipw_ListCountryAttributes
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ipw_ListCountryAttributes]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ipw_ListCountryAttributes.'
	Drop procedure [dbo].[ipw_ListCountryAttributes]
End
Print '**** Creating Stored Procedure dbo.ipw_ListCountryAttributes...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.ipw_ListCountryAttributes
(	@pnUserIdentityId		int,			-- Mandatory
	@psCulture			nvarchar(5)	= null, -- the language in which output is to be expressed
	@psCountryCode			nvarchar(3)
)
as
-- PROCEDURE:	ipw_ListCountryAttributes
-- VERSION:	1
-- SCOPE:	WorkBenches
-- DESCRIPTION:	Returns Attributes for a Country.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 5 Dec 2007	AT	SQA3208	1	Procedure created


SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

declare	@nErrorCode	int
declare @sSQLString nvarchar(1000)

-- Initialise variables
Set @nErrorCode = 0

If @nErrorCode = 0
Begin
	Set @sSQLString = "
		SELECT TA.TABLECODE as AttributeCode,
			TA.TABLETYPE as AttributeType,
			TC.DESCRIPTION as AttributeDescription,
			TA.GENERICKEY + '^' + 
				cast(TA.TABLECODE as nvarchar(15)) + '^' + 
				cast(TA.TABLETYPE as nvarchar(15)) AS RowKey
		FROM TABLEATTRIBUTES TA
		JOIN TABLECODES TC ON (TC.TABLECODE = TA.TABLECODE
					and TC.TABLETYPE = TA.TABLETYPE)
		WHERE TA.PARENTTABLE = 'COUNTRY' 
		AND TA.GENERICKEY= @psCountryCode"

	exec @nErrorCode=sp_executesql @sSQLString,
			N'	@psCountryCode	nvarchar(3)',
				@psCountryCode	= @psCountryCode

	Set @nErrorCode = @@ERROR
End

Return @nErrorCode
GO

Grant execute on dbo.ipw_ListCountryAttributes to public
GO
