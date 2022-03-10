SET QUOTED_IDENTIFIER OFF
GO

-----------------------------------------------------------------------------------------------------------------------------
-- Creation of Procedure
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ipn_ListExaminationTypes]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ipn_ListExaminationTypes.'
	Drop procedure [dbo].[ipn_ListExaminationTypes]
End
Print '**** Creating Stored Procedure dbo.ipn_ListExaminationTypes...'
Print ''
GO

CREATE PROCEDURE dbo.ipn_ListExaminationTypes
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pnResult		int		= null output	-- just an example
)
-- PROCEDURE:	ipn_ListExaminationTypes
-- VERSION:	1
-- SCOPE:	CPA.net, InPro.net
-- DESCRIPTION:	A list of all the examination types in the system, ordered by description

-- MODIFICATIONS :
-- Date		Who	Version	Change
-- ------------	-------	-------	----------------------------------------------- 
-- 19 MAR 2003  SF	1	Procedure created

as

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare @nErrorCode int

Set @nErrorCode = 0

If @nErrorCode = 0
Begin

	Select 	TABLECODE	as 'Key', 
		DESCRIPTION	as 'Description' 
	from	TABLECODES
	where	TABLETYPE = 8
	order by DESCRIPTION

	Set @nErrorCode = @@ERROR
End

Return @nErrorCode
GO

Grant execute on dbo.ipn_ListExaminationTypes to public
GO

