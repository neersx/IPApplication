-----------------------------------------------------------------------------------------------------------------------------
-- Creation of biw_IsValidOpenItem
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[biw_IsValidOpenItem]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.biw_IsValidOpenItem.'
	Drop procedure [dbo].[biw_IsValidOpenItem]
End
Print '**** Creating Stored Procedure dbo.biw_IsValidOpenItem...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO

SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.biw_IsValidOpenItem
(
	@pbYes				bit		= null output,	
	@pnUserIdentityId		int,		-- Mandatory
	@psCulture			nvarchar(10) 	= null,
	@pbCalledFromCentura		bit		= 0,
	@psOpenItemNo			nvarchar(max)
)
as
-- PROCEDURE:	biw_IsValidOpenItem
-- VERSION:	2
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Check to see if the Open Item exists 

-- MODIFICATIONS :
-- Date		Who	Change		Version	Description
-- -----------	-------	------		-------	----------------------------------------------- 
-- 18 Jul 2011	KR	RFC10997	1	Procedure created
-- 14 Nov 2011	AT	RFC11554	2	Allow multiple OpenItems to be passed, delimited by a bar '|'

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

declare	@nErrorCode	int
-- Initialise variables
Set @nErrorCode = 0
Set @pbYes = 0

If @nErrorCode = 0 and
	not exists (select * 
		from dbo.fn_Tokenise(@psOpenItemNo,'|') T
		LEFT JOIN OPENITEM ON (T.Parameter = OPENITEM.OPENITEMNO)
		WHERE OPENITEM.ITEMENTITYNO IS NULL)
Begin
		Set @pbYes = 1
End


If @nErrorCode = 0
Begin
	-- publish to .net dataaccess
	Select isnull(@pbYes,0)
End

Return @nErrorCode
GO

Grant execute on dbo.biw_IsValidOpenItem to public
GO
