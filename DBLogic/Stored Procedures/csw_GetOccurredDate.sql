-----------------------------------------------------------------------------------------------------------------------------
-- Creation of csw_GetOccurredDate
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[csw_GetOccurredDate]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop Stored Procedure dbo.csw_GetOccurredDate.'
	drop procedure [dbo].[csw_GetOccurredDate]
	print '**** Creating Stored Procedure dbo.csw_GetOccurredDate...'
	print ''
end
go

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.csw_GetOccurredDate
(
	@pdtOccurredDate	datetime	= null output,
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pbCalledFromCentura	bit		= 0,
	@pnCaseKey  		int,		-- Mandatory
	@pnEventKey		int,		-- Mandatory
	@pnCycle		smallint	-- Mandatory	
	
)
-- PROCEDURE:	csw_GetOccurredDate
-- VERSION:	1
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- SCOPE:	Inpro.Net
-- DESCRIPTION:	Returns an occured date of the case event.

-- MODIFICATIONS :
-- Date		Who	Number	Version	Change
-- ------------	-------	------	-------	----------------------------------------------- 
-- 09 Dec 2005  TM	RFC3275	1	Procedure created
AS

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare @sSQLString		nvarchar(500)
Declare @nErrorCode		int

-- Initialise variables
Set @nErrorCode = 0
	
If @nErrorCode = 0
Begin
	Set @sSQLString="
	Select @pdtOccurredDate = CE.EVENTDATE
	from CASEEVENT CE
	where CE.CASEID 	= @pnCaseKey
	and   CE.EVENTNO 	= @pnEventKey
	and   CE.CYCLE 		= @pnCycle"

	exec @nErrorCode = sp_executesql @sSQLString,
					N'@pdtOccurredDate	datetime		OUTPUT,
					  @pnCaseKey		int,
					  @pnEventKey		int,
					  @pnCycle		smallint',
					  @pdtOccurredDate	= @pdtOccurredDate	OUTPUT,
					  @pnCaseKey		= @pnCaseKey,
					  @pnEventKey		= @pnEventKey,
					  @pnCycle		= @pnCycle
End

Return @nErrorCode
go

grant execute on dbo.csw_GetOccurredDate  to public
go
