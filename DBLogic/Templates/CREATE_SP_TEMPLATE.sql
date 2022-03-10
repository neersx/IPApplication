-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ipn_MyStoredProc
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ipn_MyStoredProc]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ipn_MyStoredProc.'
	Drop procedure [dbo].[ipn_MyStoredProc]
End
Print '**** Creating Stored Procedure dbo.ipn_MyStoredProc...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.ipn_MyStoredProc
(
	@pnResult		int		= null output,	-- just an example
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pbCalledFromCentura	bit		= 0
)
as
-- PROCEDURE:	ipn_MyStoredProc
-- VERSION:	1
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Programmer comments here

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- dd MMM yyyy	AP	####	1	Procedure created

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

declare	@nErrorCode	int

-- Initialise variables
Set @nErrorCode = 0

If @nErrorCode = 0
Begin
	-- Some code here
End

Return @nErrorCode
GO

Grant execute on dbo.ipn_MyStoredProc to public
GO
