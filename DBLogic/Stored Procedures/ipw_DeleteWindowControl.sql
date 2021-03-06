-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ipw_DeleteWindowControl
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ipw_DeleteWindowControl]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ipw_DeleteWindowControl.'
	Drop procedure [dbo].[ipw_DeleteWindowControl]
End
Print '**** Creating Stored Procedure dbo.ipw_DeleteWindowControl...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO

SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[ipw_DeleteWindowControl]
(
	@pnUserIdentityId			int,			-- Mandatory
	@psCulture					nvarchar(10) 	= null,
	@pnWindowControlNo			int,			-- Mandatory
	@pbApplyToDecendants		bit				= 0
)
as
-- PROCEDURE:	ipw_DeleteWindowControl
-- VERSION:	2
-- DESCRIPTION:	Delete a WindowControl if the underlying values are as expected.

-- MODIFICATIONS :
-- Date			Who		Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 22 Oct 2008	KR		RFC6732	1		Procedure created
-- 06 Feb 2009	JC		RFC6732	2		Fix Issues


SET CONCAT_NULL_YIELDS_NULL OFF
-- Row counts required by the data adapter
SET NOCOUNT OFF
-- Reset so that next procedure gets the default. 
SET ANSI_NULLS ON

declare	@nErrorCode			int
declare @sSQLString 		nvarchar(4000)


-- Initialise variables
Set @nErrorCode 		= 0

If @nErrorCode = 0
Begin
	Set @sSQLString = " 
	delete	WINDOWCONTROL
	where	WINDOWCONTROLNO		= @pnWindowControlNo"

	exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnWindowControlNo		int',
					  @pnWindowControlNo		= @pnWindowControlNo
End

Return @nErrorCode
GO

Grant execute on dbo.ipw_DeleteWindowControl to public
GO
