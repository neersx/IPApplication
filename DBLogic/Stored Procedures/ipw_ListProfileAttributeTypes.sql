-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ipw_ListProfileAttributeTypes
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ipw_ListProfileAttributeTypes]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ipw_ListProfileAttributeTypes.'
	Drop procedure [dbo].[ipw_ListProfileAttributeTypes]
End
Print '**** Creating Stored Procedure dbo.ipw_ListProfileAttributeTypes...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.ipw_ListProfileAttributeTypes
(
	@pnUserIdentityId	int,		
	@psCulture		nvarchar(10) 	= null,
	@pbCalledFromCentura	bit		= 0
)
as
-- PROCEDURE:	ipw_ListProfileAttributeTypes
-- VERSION:	1
-- COPYRIGHT:	Copyright CPA Global Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Return a list of Attribute types available for profiles.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 15 Sep 2009	LP	RFC8047 1	Procedure created

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

declare	@nErrorCode	int

-- Initialise variables
Set @nErrorCode = 0

If @nErrorCode = 0
Begin
	SELECT ATTRIBUTEID as AttributeKey,
	ATTRIBUTENAME as AttributeName	
	from ATTRIBUTES
	
	Set @nErrorCode = @@ERROR
End

Return @nErrorCode
GO

Grant execute on dbo.ipw_ListProfileAttributeTypes to public
GO
