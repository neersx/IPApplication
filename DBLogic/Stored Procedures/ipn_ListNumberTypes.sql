SET QUOTED_IDENTIFIER OFF
GO

-----------------------------------------------------------------------------------------------------------------------------
-- Creation of Procedure
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ipn_ListNumberTypes]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ipn_ListNumberTypes.'
	Drop procedure [dbo].[ipn_ListNumberTypes]
End
Print '**** Creating Stored Procedure dbo.ipn_ListNumberTypes...'
Print ''
GO

CREATE PROCEDURE dbo.ipn_ListNumberTypes
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null
)
-- PROCEDURE:	ipn_ListNumberTypes
-- VERSION:	1
-- SCOPE:	CPA.net, InPro.net
-- DESCRIPTION:	Used by cs_ListCaseSupport

-- MODIFICATIONS :
-- Date		Who	Version	Change
-- ------------	-------	-------	----------------------------------------------- 
-- 28-JAN-2003  SF	1	Procedure created

as

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare @nErrorCode int

Set @nErrorCode = 0

If @nErrorCode = 0
Begin
	Select 	NUMBERTYPE 	as 'NumberTypeKey',
		DESCRIPTION	as 'NumberTypeDescription'
	from	NUMBERTYPES

	Set @nErrorCode = @@ERROR
End

Return @nErrorCode
GO

Grant execute on dbo.ipn_ListNumberTypes to public
GO

