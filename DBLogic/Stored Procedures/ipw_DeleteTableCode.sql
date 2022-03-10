-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ipw_DeleteTableCode									      
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ipw_DeleteTableCode]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ipw_DeleteTableCode.'
	Drop procedure [dbo].[ipw_DeleteTableCode]
End
Print '**** Creating Stored Procedure dbo.ipw_DeleteTableCode...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
-- Allow comparison of null values.
-- Procedure uses setting in place before it's created.
SET ANSI_NULLS OFF
GO


CREATE PROCEDURE dbo.ipw_DeleteTableCode
(
	@pnUserIdentityId			int,		-- Mandatory
	@psCulture				nvarchar(10) 	= null,
	@pbCalledFromCentura		        bit		= 0,
	@pnTableCode				int,	        -- Mandatory
	@pnOldTableType				smallint	= null,
	@psOldDescription			nvarchar(80)	= null,
	@psOldUserCode				nvarchar(50)	= null
)
as
-- PROCEDURE:	ipw_DeleteTableCode
-- VERSION:	2
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Delete TableCodes if the underlying values are as expected.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	-----------------------------------------------
-- 08 Oct 2008	SF	RFC6510	1	Procedure created
-- 22 Mar 2011  MS      RFC100492  2    Modify size for UserCode column to 50

SET CONCAT_NULL_YIELDS_NULL OFF
-- Row counts required by the data adapter
SET NOCOUNT OFF
-- Reset so that next procedure gets the default.
SET ANSI_NULLS ON

Declare @nErrorCode		int
Declare @sSQLString 		nvarchar(4000)

-- Initialise variables
Set @nErrorCode = 0

If @nErrorCode = 0
Begin
	Set @sSQLString = "Delete from TABLECODES
			   where TABLECODE	= @pnTableCode and
					TABLETYPE	= @pnOldTableType and		
					DESCRIPTION = @psOldDescription and 
					USERCODE = @psOldUserCode"	

	exec @nErrorCode=sp_executesql @sSQLString,
			      	N'
			@pnTableCode		int,
			@pnOldTableType		smallint,
			@psOldDescription	nvarchar(80),
			@psOldUserCode		nvarchar(50)',
			@pnTableCode		= @pnTableCode,
			@pnOldTableType		= @pnOldTableType,
			@psOldDescription	= @psOldDescription,
			@psOldUserCode		= @psOldUserCode


End

Return @nErrorCode
GO

Grant execute on dbo.ipw_DeleteTableCode to public
GO

