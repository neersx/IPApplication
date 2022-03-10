-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ipw_LoadCaseInstructAllowed
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ipw_LoadCaseInstructAllowed]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ipw_LoadCaseInstructAllowed.'
	Drop procedure [dbo].[ipw_LoadCaseInstructAllowed]
End
Print '**** Creating Stored Procedure dbo.ipw_LoadCaseInstructAllowed...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.ipw_LoadCaseInstructAllowed
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pbCalledFromCentura	bit		= 0,
	@pnCaseId		int		= null,		-- Case to be loaded
	@pnDefinitionId		int		= null,	-- Specific definition to be loaded
	@psTableName		nvarchar(50) 	= null,		-- Name of table listing Cases (CASEID) to be loaded
	@pbClearExisting	bit		= 0
)
as
-- PROCEDURE:	ipw_LoadCaseInstructAllowed
-- VERSION:	4
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Procedure to asynchronously call the ipw_LoadCaseInstructAllowedAsync.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 01 Sep 2009	DV	RFC7050	1	Procedure created
-- 04 Feb 2010	DL	18430	2	Grant stored procedure to public
-- 28 May 2013	DL	10030	3	Replace calls to system extended SP sp_OAxxx with wrapper SP ipu_OAxxx
-- 14 Oct 2014	DL	R39102	4	Use service broker instead of OLE Automation to run the command asynchronoulsly


SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

declare	@nErrorCode		int
declare @sSQLString		nvarchar(4000)
declare	@sCommand	varchar(4000)
declare	@nObject	int
declare	@nObjectExist	tinyint

-- Initialise variables
Set @nErrorCode = 0

If  @nErrorCode = 0
Begin
	----------------------------------------------------------------
	-- Build command line to run ipw_LoadCaseInstructAllowedAsync 	
	----------------------------------------------------------------
	Set @sCommand = 'dbo.ipw_LoadCaseInstructAllowedAsync '
	
	If @pnUserIdentityId is not null
			Set @sCommand = @sCommand + "@pnUserIdentityId='" + convert(varchar,@pnUserIdentityId) + "',"

	If @pnCaseId is not null
			Set @sCommand = @sCommand + "@pnCaseId='" + convert(varchar,@pnCaseId) + "',"

	If @pnDefinitionId is not null
		Set @sCommand = @sCommand + "@pnDefinitionId='" + convert(varchar,@pnDefinitionId) + "',"

	If @psTableName is not null
		Set @sCommand = @sCommand + "@psTableName='" + convert(varchar,@psTableName) + "',"

	If @pbClearExisting is not null
		Set @sCommand = @sCommand + "@pbClearExisting='" + convert(varchar,@pbClearExisting) + "',"

	Set @sCommand = @sCommand + "@pbCalledFromCentura=0" 

	---------------------------------------------------------------
	-- RFC-39102 Use service broker instead of OLE Automation to run the command asynchronoulsly
	--------------------------------------------------------------- 
	exec @nErrorCode = dbo.ipu_ScheduleAsyncCommand @sCommand				
End
		
Return @nErrorCode
GO

Grant execute on dbo.ipw_LoadCaseInstructAllowed to public
GO
