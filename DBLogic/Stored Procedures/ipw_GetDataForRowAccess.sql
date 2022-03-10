-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ipw_GetDataForRowAccess
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ipw_GetDataForRowAccess]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ipw_GetDataForRowAccess.'
	Drop procedure [dbo].[ipw_GetDataForRowAccess]
End
Print '**** Creating Stored Procedure dbo.ipw_GetDataForRowAccess...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.ipw_GetDataForRowAccess
(
	@psCaseTypeKey		nvarchar(2)	= null output,
	@psPropertyTypeKey	nvarchar(2)	= null output,
	@pnOfficeKey		int		= null output,
	@psNameTypeKeys		nvarchar(max)	= null output,
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pnCaseKey		int		= null,
	@pnNameKey		int		= null,	
	@pbCalledFromCentura	bit		= 0
)
as
-- PROCEDURE:	ipw_GetDataForRowAccess
-- VERSION:	2
-- COPYRIGHT:	Copyright CPA Global Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Returns the case or name data used for row access security evaluation

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 02 Nov 2009	LP	RFC6712	1	Procedure created
-- 07 Sep 2018	AV	74738	2	Set isolation level to read uncommited.


SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

declare	@nErrorCode		int
declare @sSQLString		nvarchar(max)

-- Initialise variables
Set @nErrorCode = 0

If @nErrorCode = 0
Begin
	If @pnCaseKey is not null
	Begin
		Select @psCaseTypeKey = CASETYPE,
		@psPropertyTypeKey = PROPERTYTYPE,
		@pnOfficeKey = OFFICEID
		from CASES
		where CASEID = @pnCaseKey		
		
	End
	Else If @pnNameKey is not null
	Begin
		select @psNameTypeKeys = nullif(@psNameTypeKeys+',',',')+
					cast(NTC.NAMETYPE as nvarchar(6)) 
		from NAMETYPECLASSIFICATION NTC 
		WHERE NTC.ALLOW = 1 
		and NTC.NAMENO = @pnNameKey
	End
	
	Set @nErrorCode = @@ERROR
End

Return @nErrorCode
GO

Grant execute on dbo.ipw_GetDataForRowAccess to public
GO

