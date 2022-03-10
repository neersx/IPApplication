-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ipw_UpdateTableCode									      
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ipw_UpdateTableCode]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ipw_UpdateTableCode.'
	Drop procedure [dbo].[ipw_UpdateTableCode]
End
Print '**** Creating Stored Procedure dbo.ipw_UpdateTableCode...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
-- Allow comparison of null values.
-- Procedure uses setting in place before it's created.
SET ANSI_NULLS OFF
GO


CREATE PROCEDURE dbo.ipw_UpdateTableCode
(
	@pnUserIdentityId			int,		-- Mandatory
	@psCulture				nvarchar(10) 	= null,
	@pbCalledFromCentura		        bit		= 0,
	@pnTableCode				int,	        -- Mandatory
	@pnTableType				smallint	= null,
	@psDescription				nvarchar(80)	= null,
	@psUserCode				nvarchar(50)	= null,
	@pnOldTableType				smallint	= null,
	@psOldDescription			nvarchar(80)	= null,
	@psOldUserCode				nvarchar(50)	= null
)
as
-- PROCEDURE:	ipw_UpdateTableCode
-- VERSION:	3
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Update TableCodes if the underlying values are as expected.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	-----------------------------------------------
-- 08 Oct 2008	SF	RFC6510	1	Procedure created
-- 09 Aug 2010	DV	RFC8384 2	Restrict duplicate table code from getting inserted
-- 15 Feb 2011  MS      RFC8363 3       Updated UserCode field length to 50

SET CONCAT_NULL_YIELDS_NULL OFF
-- Row counts required by the data adapter
SET NOCOUNT OFF
-- Reset so that next procedure gets the default.
SET ANSI_NULLS ON

Declare @nErrorCode		int
Declare @sSQLString 		nvarchar(4000)
Declare @sUpdateString 	        nvarchar(4000)
Declare @sWhereString		nvarchar(4000)
Declare @sComma		        nchar(1)
Declare @sAnd			nchar(5)
Declare @sAlertXML		nvarchar(500)

-- Initialise variables
Set @nErrorCode = 0
Set @sWhereString = CHAR(10)+" where "

If @nErrorCode = 0
Begin	
	if (@psDescription is not null and
		exists(select 1 from TABLECODES where upper(DESCRIPTION) = upper(@psDescription) and TABLETYPE = @pnTableType and @psOldDescription <> @psDescription))
	Begin
		Set @sAlertXML = dbo.fn_GetAlertXML('IP119', 'Description already exists for the List Name.', null, null, null, null, null)
		RAISERROR(@sAlertXML, 12, 1)
		Set @nErrorCode = @@ERROR
	End
End

If @nErrorCode = 0
Begin
	Set @sSQLString = "Update TABLECODES
			   set	DESCRIPTION = @psDescription,
				USERCODE = @psUserCode

		where	TABLECODE = @pnTableCode 
		and	TABLETYPE = @pnOldTableType
		and	DESCRIPTION = @psOldDescription
		and	USERCODE = @psOldUserCode"		

	exec @nErrorCode=sp_executesql @sSQLString,
			      	N'
			@pnTableCode		int,
			@pnTableType		smallint,
			@psDescription		nvarchar(80),
			@psUserCode		nvarchar(50),
			@pnOldTableType		smallint,
			@psOldDescription	nvarchar(80),
			@psOldUserCode		nvarchar(50)',
			@pnTableCode		= @pnTableCode,
			@pnTableType		= @pnTableType,
			@psDescription		= @psDescription,
			@psUserCode		= @psUserCode,
			@pnOldTableType		= @pnOldTableType,
			@psOldDescription	= @psOldDescription,
			@psOldUserCode		= @psOldUserCode


End

Return @nErrorCode
GO

Grant execute on dbo.ipw_UpdateTableCode to public
GO
