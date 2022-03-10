-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ipw_ListMultipleCaseFamily
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ipw_ListMultipleCaseFamily]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ipw_ListMultipleCaseFamily.'
	Drop procedure [dbo].[ipw_ListMultipleCaseFamily]
End
Print '**** Creating Stored Procedure dbo.ipw_ListMultipleCaseFamily...'
Print ''
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO


CREATE PROCEDURE [dbo].[ipw_ListMultipleCaseFamily]
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pbCalledFromCentura	bit		= 0,
	@psFamilyKeys		nvarchar(4000),
	@psFamilyKeysDelimiter 	nvarchar(5) = null
)
as
-- PROCEDURE:	ipw_ListMultipleCaseFamily
-- VERSION:	2
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Given a list of comma delimited FamilyKeys, return matching Case Family as a result set.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 02 AUG 2016	MS	R71789	1	Procedure created
-- 09 SEP 2019	SF	DR-49793 2 	Support passed in 

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare @nErrorCode     int
Declare @sLookupCulture	nvarchar(10)

Set @sLookupCulture = dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)

Set @nErrorCode = 0

select 	F.FAMILY as FamilyKey,
		dbo.fn_GetTranslation(F.FAMILYTITLE, null, F.FAMILYTITLE_TID, @sLookupCulture) as Family
from 	CASEFAMILY F
join	dbo.fn_Tokenise(@psFamilyKeys, isnull(@psFamilyKeysDelimiter, ',')) K on K.Parameter = F.FAMILY	

RETURN @nErrorCode

GO

GRANT EXECUTE ON dbo.[ipw_ListMultipleCaseFamily]  TO PUBLIC

GO