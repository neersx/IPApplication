-----------------------------------------------------------------------------------------------------------------------------
-- Creation of [biw_GetBillingAttention] 
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[biw_GetBillingAttention]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.[biw_GetBillingAttention].'
	drop procedure dbo.[biw_GetBillingAttention]
end
print '**** Creating procedure dbo.[biw_GetBillingAttention]...'
print ''
go

set QUOTED_IDENTIFIER off
go
set ANSI_NULLS on
go
SET CONCAT_NULL_YIELDS_NULL OFF
go 

create procedure dbo.[biw_GetBillingAttention]
				@pnUserIdentityId	int,		-- Mandatory
				@psCulture		nvarchar(10) 	= null,
				@pbCalledFromCentura	bit		= 0,
				@pnCaseKey		int,		-- Mandatory
				@pnDebtorKey		int,		-- Mandatory
				@pbRenewalDebtor	bit		= 0,
				@pbDebug		bit		= 0
as
-- PROCEDURE :	biw_GetBillingAttention
-- VERSION :	1
-- DESCRIPTION:	A procedure to get billing attention name and address.
--
-- COPYRIGHT:	Copyright 1993 - 2010 CPA Global Software Solutions Australia Pty Limited
-- MODIFICATION
-- Date			Who		RFC			Version Description
-- -----------	-------	------		------- ----------------------------------------------- 
-- 09/07/2010		KR		RFC8306			1	Procedure created


Set nocount on
declare @nErrorCode int
declare @sNameType nvarchar(3)
declare @nAttnAddressKey int
declare @nCorrespondNameKey int

Set @nErrorCode = 0


If @nErrorCode = 0
Begin
	if (@pbRenewalDebtor = 1)
		set @sNameType = 'Z'
	else
		set @sNameType = 'D'
		
	Select @nAttnAddressKey = ADDRESSCODE, @nCorrespondNameKey = CORRESPONDNAME From CASENAME Where CASEID = @pnCaseKey and NAMENO = @pnDebtorKey and NAMETYPE = @sNameType
	if (@nAttnAddressKey is null or @nCorrespondNameKey is null)
	Begin
		If exists (select * from CASENAME where INHERITEDNAMENO is not null AND INHERITEDRELATIONS is not null
			  and NAMENO is not null and INHERITEDSEQUENCE is not null
			  and CASEID = @pnCaseKey and NAMENO = @pnDebtorKey and NAMETYPE = @sNameType)
		Begin			
			Select @nAttnAddressKey = case when @nAttnAddressKey is null then  POSTALADDRESS else  @nAttnAddressKey end, 
			       @nCorrespondNameKey = case when @nCorrespondNameKey is null then CONTACT else @nCorrespondNameKey end
			From ASSOCIATEDNAME AN
			Join CASENAME CN on (AN.NAMENO = CN.INHERITEDNAMENO and AN.RELATIONSHIP = CN.INHERITEDRELATIONS
					    and AN.RELATEDNAME = CN.NAMENO and AN.SEQUENCE = CN.INHERITEDSEQUENCE
					    and CN.CASEID = @pnCaseKey and CN.NAMENO = @pnDebtorKey 
					    and CN.NAMETYPE = @sNameType)

		End
		
		Else
		Begin
			Select @nAttnAddressKey = case when @nAttnAddressKey is null then  POSTALADDRESS else  @nAttnAddressKey end, 
			       @nCorrespondNameKey = case when @nCorrespondNameKey is null then CONTACT else @nCorrespondNameKey end
			From ASSOCIATEDNAME 
			Where NAMENO = @pnDebtorKey and RELATIONSHIP = 'BIL' and RELATEDNAME = @pnDebtorKey and SEQUENCE = 0	

		End
	End
	
	if (@nAttnAddressKey is null or @nCorrespondNameKey is null)
	Begin
		Select @nAttnAddressKey = case when @nAttnAddressKey is null then POSTALADDRESS else  @nAttnAddressKey end, 
		@nCorrespondNameKey = case when @nCorrespondNameKey is null then MAINCONTACT else @nCorrespondNameKey end
		from NAME Where NAMENO = @pnDebtorKey
	End
	
	
	Select @nAttnAddressKey as AttentionAddressKey, @nCorrespondNameKey as CorrespondNameKey
	
End


return @nErrorCode
go

grant execute on dbo.[biw_GetBillingAttention]  to public
go
