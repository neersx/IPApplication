--acw_GetTaxRate
-----------------------------------------------------------------------------------------------------------------------------
-- Creation of [acw_GetTaxRate] 
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[acw_GetTaxRate]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.[acw_GetTaxRate].'
	drop procedure dbo.[acw_GetTaxRate]
end
print '**** Creating procedure dbo.[acw_GetTaxRate]...'
print ''
go

set QUOTED_IDENTIFIER off
go
set ANSI_NULLS on
go

create procedure dbo.[acw_GetTaxRate]
				@pnUserIdentityId		int,		-- Mandatory
				@psCulture				nvarchar(10) 	= null,
				@pbCalledFromCentura	bit		= 0,
				@psTaxCode	nvarchar(3) = null, -- pass null if all tax rates to be returned.
				@pnStaffKey	int = null,
				@pdtItemDate	datetime = null,
				@pnEntitykey	int = null
as
-- PROCEDURE :	acw_GetTaxRate
-- VERSION :	5
-- DESCRIPTION:	A wrapper procedure that calls dbo.fn_GetEffectiveTaxRate
--
-- COPYRIGHT:	Copyright 1993 - 2010 CPA Global Software Solutions (Australia) Pty Limited
-- MODIFICATION
-- Date		Who	RFC		Version Description
-- -----------	-------	---------------	------- ----------------------------------------------- 
-- 23-Dec-2010	AT	RFC10042	1	Procedure Created.
-- 25-May-2011	AT	RFC7956		2	Fixed TableType of source country.
-- 08-Aug-2011	AT	RFC10241	3	Allow return of all tax rates for a particular date.
-- 14-May-2012	AT	RFC12149	4	Call function to get source country.
-- 10 Oct 2018  AK	R74005      5   included parameter @pnEntitykey

set nocount on

Declare	@ErrorCode	int
Declare @sSQLString nvarchar(1000)
Declare @sSourceCountry	nvarchar(3)

Set @ErrorCode = 0

If (@ErrorCode = 0 and @pnStaffKey is not null)
Begin
	Select @sSourceCountry = dbo.fn_GetSourceCountry(@pnStaffKey, null)
End

if @psTaxCode is not null
Begin
	Set @sSQLString = "Select dbo.fn_GetEffectiveTaxRate(@psTaxCode,@sSourceCountry,isnull(@pdtItemDate,getdate()), @pnEntitykey) as 'TaxRate'"
End
Else
Begin
	Set @sSQLString = "Select TAXCODE as TaxCode,
			DESCRIPTION as TaxDescription,
			dbo.fn_GetEffectiveTaxRate(TAXCODE,@sSourceCountry,isnull(@pdtItemDate,getdate()),@pnEntitykey) as 'TaxRate'
			FROM TAXRATES"
End

exec @ErrorCode = sp_executesql @sSQLString, 
				  N'@psTaxCode	nvarchar(3),
					@sSourceCountry nvarchar(3),
					@pnEntitykey int,
					@pdtItemDate datetime',
					@psTaxCode=@psTaxCode,
					@sSourceCountry=@sSourceCountry,
					@pnEntitykey=@pnEntitykey,
					@pdtItemDate=@pdtItemDate

return @ErrorCode
go

grant execute on dbo.[acw_GetTaxRate]  to public
go
