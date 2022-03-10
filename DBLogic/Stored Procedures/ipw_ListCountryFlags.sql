-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ipw_ListCountryFlags
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ipw_ListCountryFlags]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop Stored Procedure dbo.ipw_ListCountryFlags.'
	drop procedure [dbo].[ipw_ListCountryFlags]
	print '**** Creating Stored Procedure dbo.ipw_ListCountryFlags...'
	print ''
end
go

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.ipw_ListCountryFlags
(
	@pnRowCount		int		= null output,
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pnCaseKey 		int, 		-- Mandatory
	@pbCalledFromCentura	bit		= 0
)
-- PROCEDURE:	ipw_ListCountryFlags
-- VERSION:	3
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- SCOPE:	Inpro.Net
-- DESCRIPTION:	Returns a list of country flags of the case.

-- MODIFICATIONS :
-- Date		Who	Number	Version	Change
-- ------------	-------	------	-------	----------------------------------------------- 
-- 17 Oct 2005  TM	RFC3144	1	Procedure created
-- 20 Dec 2007	LP	RFC3210	2	Change RowKey to only use COUNTRYFLAG
-- 03 Jan 2008	LP	RFC3210	3	Add new column IsNationalPhase
AS

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare @sSQLString		nvarchar(4000)
Declare @nErrorCode		int
Declare @sLookupCulture		nvarchar(10)

-- Initialise variables
Set @nErrorCode = 0
set @sLookupCulture = dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)
	
If @nErrorCode = 0
Begin
	Set @sSQLString="
	Select  CF.FLAGNUMBER	as RowKey, 
		CF.FLAGNAME  	as FlagDescription,
		CF.NATIONALALLOWED as IsNationalPhase
	from CASES C
	join COUNTRYFLAGS CF	on (CF.COUNTRYCODE = C.COUNTRYCODE)
	where C.CASEID = @pnCaseKey
	order by FlagDescription" 

	exec @nErrorCode = sp_executesql @sSQLString,
				N'@pnCaseKey	int',
				  @pnCaseKey	= @pnCaseKey
	
	Set @pnRowCount = @@Rowcount
End

Return @nErrorCode
go

grant execute on dbo.ipw_ListCountryFlags  to public
go
