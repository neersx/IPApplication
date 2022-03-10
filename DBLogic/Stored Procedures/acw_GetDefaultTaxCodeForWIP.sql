--acw_GetDefaultTaxCodeForWIP
-----------------------------------------------------------------------------------------------------------------------------
-- Creation of [acw_GetDefaultTaxCodeForWIP] 
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[acw_GetDefaultTaxCodeForWIP]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.[acw_GetDefaultTaxCodeForWIP].'
	drop procedure dbo.[acw_GetDefaultTaxCodeForWIP]
end
print '**** Creating procedure dbo.[acw_GetDefaultTaxCodeForWIP]...'
print ''
go

set QUOTED_IDENTIFIER off
go
set ANSI_NULLS on
go

create procedure dbo.[acw_GetDefaultTaxCodeForWIP]
				@pnUserIdentityId		int,		-- Mandatory
				@psCulture				nvarchar(10) 	= null,
				@pbCalledFromCentura	bit		= 0,
				@pnCaseKey				int	= null,
				@psWIPCode				nvarchar(6) = null,
				@pnDebtorKey			int,
				@pnStaffKey				int = null,
				@pnEntityKey			int = null
as
-- PROCEDURE :	acw_GetDefaultTaxCodeForWIP
-- VERSION :	6
-- DESCRIPTION:	A wrapper procedure that calls dbo.fn_GetEffectiveTaxRateForWIP
--
-- COPYRIGHT:	Copyright 1993 - 2013 CPA Global Software Solutions (Australia) Pty Limited
-- MODIFICATION
-- Date		Who	RFC		Version Description
-- -----------	-------	------		------- ----------------------------------------------- 
-- 28-Mar-2010	AT	RFC3605		1	Procedure created.
-- 23-Dec-2010	AT	RFC10042	2	Added debtor parameter.
-- 08-Jun-2011	AT	RFC10791	3	Allow Case Key null for debtor only.
-- 27-Mar-2012	AT	RFC13318	4	Undo re-derivation of debtor from case in case debtor has changed. Always pass debtor of bill.
-- 15-Feb-2018	Ak  RFC72937	5	passed @pnStaffKey in fn_GetDefaultTaxCodeForWIP.
-- 04 Oct 2018  AK  R74005		6   passed @pnEntityKey in fn_GetDefaultTaxCodeForWIP

set nocount on

Declare	@ErrorCode	int
Declare @sSQLString nvarchar(1000)

Set @sSQLString = "Select dbo.fn_GetDefaultTaxCodeForWIP(@pnCaseKey,@psWIPCode,@pnDebtorKey, @pnStaffKey, @pnEntityKey) as 'TaxCode'"

exec @ErrorCode = sp_executesql @sSQLString, 
				  N'@pnCaseKey	int,
					@psWIPCode nvarchar(6),
					@pnStaffKey	int,
					@pnDebtorKey int,
					@pnEntityKey int',
					@pnCaseKey=@pnCaseKey,
					@psWIPCode=@psWIPCode,
					@pnStaffKey=@pnStaffKey,
					@pnDebtorKey=@pnDebtorKey,
					@pnEntityKey=@pnEntityKey

return @ErrorCode
go

grant execute on dbo.[acw_GetDefaultTaxCodeForWIP]  to public
go
