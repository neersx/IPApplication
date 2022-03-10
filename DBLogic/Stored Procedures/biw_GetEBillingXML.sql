-----------------------------------------------------------------------------------------------------------------------------
-- Creation of biw_GetEBillingXML 
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].biw_GetEBillingXML') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.biw_GetEBillingXML.'
	drop procedure dbo.biw_GetEBillingXML
end
print '**** Creating procedure dbo.biw_GetEBillingXML...'
print ''
go

set QUOTED_IDENTIFIER off
go
set ANSI_NULLS on
go

create procedure dbo.biw_GetEBillingXML
				@pnUserIdentityId		int,		-- Mandatory
				@psCulture				nvarchar(10) 	= null,
				@pbCalledFromCentura	bit		= 0,
				@psOpenItemNo		nvarchar(12),
				@pnItemEntityNo		int
as
-- PROCEDURE :	biw_GetEBillingXML
-- VERSION :	1
-- DESCRIPTION:	A procedure that returns all Billing XML data
--
-- COPYRIGHT:	Copyright 1993 - 2010 CPA Global Software Solutions (Australia) Pty Limited
-- MODIFICATION
-- Date		Who	RFC	Version Description
-- -----------	-------	------	------- ----------------------------------------------- 
-- 11-Jul-2010	AT	RFC7278	1	Procedure created.

set nocount on
SET CONCAT_NULL_YIELDS_NULL OFF

Declare		@ErrorCode	int
Declare		@nRowCount	int
Declare		@sSQLString	nvarchar(4000)
Declare		@sXMLString	nvarchar(1000)
Declare		@sLookupCulture	nvarchar(10)

set @sLookupCulture = dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)

Set @ErrorCode = 0

Set @sXMLString = '<ACTIVITYREQUEST>
			 <DEBITNOTENO>' + @psOpenItemNo + '</DEBITNOTENO>
			 <ENTITYNO>' + cast(@pnItemEntityNo as nvarchar(14)) + '</ENTITYNO>
		</ACTIVITYREQUEST>'

If (@ErrorCode = 0)
Begin

	exec @ErrorCode = xml_GetDebitNoteMappedCodes	
		@pnUserIdentityId	= @pnUserIdentityId,
		@psCulture		= @psCulture,
		@pnQueryContextKey	= 460,
		@ptXMLFilterCriteria	= @sXMLString
End


return @ErrorCode
go

grant execute on dbo.biw_GetEBillingXML  to public
go
