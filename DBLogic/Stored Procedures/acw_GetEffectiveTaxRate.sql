--acw_GetEffectiveTaxRate
-----------------------------------------------------------------------------------------------------------------------------
-- Creation of [acw_GetEffectiveTaxRate] 
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[acw_GetEffectiveTaxRate]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.[acw_GetEffectiveTaxRate].'
	drop procedure dbo.[acw_GetEffectiveTaxRate]
end
print '**** Creating procedure dbo.[acw_GetEffectiveTaxRate]...'
print ''
go

set QUOTED_IDENTIFIER off
go
set ANSI_NULLS on
go

create procedure dbo.[acw_GetEffectiveTaxRate]
				@pnUserIdentityId		int,		-- Mandatory
				@psCulture				nvarchar(10) 	= null,
				@pbCalledFromCentura	bit		= 0,
				@psTaxCode		nvarchar(3),
				@psCountryCode nvarchar(3) = null,
				@pdtTransDate	datetime = null,
				@pnStaffKey	int = null,
				@pnEntityKey int = null
				
as
-- PROCEDURE :	acw_GetEffectiveTaxRate
-- VERSION :	3
-- DESCRIPTION:	A wrapper procedure that calls dbo.fn_GetEffectiveTaxRate
--
-- COPYRIGHT:	Copyright 1993 - 2012 CPA Global Software Solutions (Australia) Pty Limited
-- MODIFICATION
-- Date		Who	RFC		Version Description
-- -----------	-------	---------------	------- ----------------------------------------------- 
-- 22-Jan-2009	AT	RFC3605		1	Procedure created
-- 14-May-2012	AT	RFC12149	2	Add Staff Key in case Country code is blank (Debtor only bills)
-- 10 Oct 2018  AK	R74005      3   included @pnEntityKey

set nocount on

Declare	@ErrorCode	int
Declare @sSQLString nvarchar(1000)

if (@psCountryCode is null and @pnStaffKey is not null)
Begin
	Select @psCountryCode = dbo.fn_GetSourceCountry(@pnStaffKey, null)
End

Set @sSQLString = "Select dbo.fn_GetEffectiveTaxRate(@psTaxCode,@psCountryCode,@pdtTransDate, @pnEntityKey) as 'TaxRate'"

exec @ErrorCode = sp_executesql @sSQLString, 
								  N'@psTaxCode		nvarchar(3),
									@psCountryCode nvarchar(3),
									@pnEntityKey	int,
									@pdtTransDate	datetime',
									@psTaxCode=@psTaxCode,
									@psCountryCode=@psCountryCode,
									@pnEntityKey=@pnEntityKey,
									@pdtTransDate=@pdtTransDate

return @ErrorCode
go

grant execute on dbo.[acw_GetEffectiveTaxRate]  to public
go
