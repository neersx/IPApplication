SET QUOTED_IDENTIFIER OFF
GO

-----------------------------------------------------------------------------------------------------------------------------
-- Creation of Procedure
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ipn_ListImportanceLevel]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ipn_ListImportanceLevel.'
	Drop procedure [dbo].[ipn_ListImportanceLevel]
End
Print '**** Creating Stored Procedure dbo.ipn_ListImportanceLevel...'
Print ''
GO

CREATE PROCEDURE dbo.ipn_ListImportanceLevel
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null
)
-- PROCEDURE:	ipn_ListImportanceLevel
-- VERSION:	1
-- SCOPE:	CPA.net, InPro.net
-- DESCRIPTION:	A list of all the importance levels in ImportanceLevel order.

-- MODIFICATIONS :
-- Date		Who	Version	Change
-- ------------	-------	-------	----------------------------------------------- 
-- 30-APR-2003  SF	1	Procedure created

as

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare @nErrorCode int

Set @nErrorCode = 0

If @nErrorCode = 0
Begin
	-- Some code here
	Set @nErrorCode = @@ERROR

	Select 	IMPORTANCELEVEL as 'ImportanceLevelKey',
		IMPORTANCEDESC as 'ImportanceLevelDescription',
		IMPORTANCELEVEL as 'ImportanceLevel'
	from 	IMPORTANCE
	order by IMPORTANCELEVEL

End

Return @nErrorCode
GO

Grant execute on dbo.ipn_ListImportanceLevel to public
GO

