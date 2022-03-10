-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ipw_ListFunctions
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ipw_ListFunctions]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ipw_ListFunctions.'
	Drop procedure [dbo].[ipw_ListFunctions]
End
Print '**** Creating Stored Procedure dbo.ipw_ListFunctions...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.ipw_ListFunctions
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pbCalledFromCentura	bit		= 0
)
as
-- PROCEDURE:	ipw_ListFunctions
-- VERSION:	2
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Returns the list of functions.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- dd MMM yyyy	AP	####	1	Procedure created
-- 20 Dec 2010  ASH     RFC9993 2       Add Order by clause with select statement

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

declare	@nErrorCode	int

-- Initialise variables
Set @nErrorCode = 0

If @nErrorCode = 0
Begin
	Select BF.FUNCTIONTYPE as FunctionType, 
		BF.DESCRIPTION as FunctionDescription 
	from BUSINESSFUNCTION BF Order by BF.DESCRIPTION ASC 
End

Return @nErrorCode
GO

Grant execute on dbo.ipw_ListFunctions to public
GO
