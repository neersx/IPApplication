-----------------------------------------------------------------------------------------------------------------------------
-- Creation of cpa_GetCaseBatchWhatIf
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].cpa_GetCaseBatchWhatIf') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.cpa_GetCaseBatchWhatIf.'
	drop procedure dbo.cpa_GetCaseBatchWhatIf
end
print '**** Creating procedure dbo.cpa_GetCaseBatchWhatIf...'
print ''
go

set QUOTED_IDENTIFIER off
go

create proc dbo.cpa_GetCaseBatchWhatIf
	@pnCaseId int = null,
	@psIRN nvarchar(30) = null
as
-- PROCEDURE :	cpa_GetCaseBatchWhatIf
-- VERSION :	1
-- DESCRIPTION:	Calls the CPA batch processing in test mode for this case to see what would be sent NOW.
--				Takes IRN for easy docitem invocation.
-- CALLED BY :	
-- COPYRIGHT:	Copyright 1993 - 2012 CPA Software Solutions (Australia) Pty Limited
-- MODIFICATIONS :
-- Date			Who		Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 12/12/2011	AvdA	20278	1		Procedure Created

set nocount on
set concat_null_yields_null off
set ansi_warnings off

declare	@ErrorCode		int
declare	@sSQLString		nvarchar(4000)
declare @nCaseId		int

set @nCaseId = @pnCaseId

Select	@ErrorCode	=0

If @ErrorCode=0 and @nCaseId is null
Begin
	Set @sSQLString="
	Select	@nCaseId = CASEID
	From	CASES
	Where	IRN = " +dbo.fn_WrapQuotes (@psIRN,0,0)

	Exec @ErrorCode=sp_executesql @sSQLString, 
						N'@nCaseId	int OUTPUT',
						@nCaseId=@nCaseId OUTPUT
End

If @ErrorCode=0 and @nCaseId  is not null
begin

	Exec @ErrorCode=[cpa_InsertCPAComplete]
		@pnCaseId = @nCaseId,
		@psPropertyType = NULL,
		@pnNotProperty = NULL,
		@pnNewCases = 1,
		@pnChangedCases = 1,
		@pnPoliceEvents = 0,
		@pbCheckInstruction = 1,
		@psOfficeCPACode = NULL,
		@pnUserIdentityId = NULL,
		@pnTestMode = 1
end

Return @ErrorCode
go

grant execute on dbo.cpa_GetCaseBatchWhatIf to public
go
