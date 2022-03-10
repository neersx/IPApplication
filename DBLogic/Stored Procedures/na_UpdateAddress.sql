----------------------------------------------------------------------------------------------
-- Creation of dbo.na_UpdateAddress
----------------------------------------------------------------------------------------------
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[na_UpdateAddress]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.na_UpdateAddress'
	drop procedure [dbo].[na_UpdateAddress]
	Print '**** Creating Stored Procedure dbo.na_UpdateAddress...'
	Print ''
End
go

SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO

create  PROCEDURE dbo.na_UpdateAddress
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture			nvarchar(10) = null,  	-- the language in which output is to be expressed
	@psNameKey			varchar(11) = null, 
	@pnAddressTypeId	int = null, 		
	@psAddressKey		nvarchar(11) = null,
	@psFreeFormAddress	nvarchar(254) = null,		-- not used?
	@psStreet			nvarchar(254) = null,
	@psCity				nvarchar(30) = null,
	@psStateKey			nvarchar(20) = null,
	@psStateName		nvarchar(40) = null,
	@psPostCode			nvarchar(11) = null,
	@psCountryKey		nvarchar(3) = null,
	@psCountryName		nvarchar(60) = null,
	
	@pnNameKeyModified			int = null,
	@pnAddressTypeIdModified	int = null,
	@pnAddressKeyModified		int = null,
	@pnFreeFormAddressModified	int = null,
	@pnStreetModified			int = null,
	@pnCityModified				int = null,
	@pnStateKeyModified			int = null,
	@pnStateNameModified		int = null,
	@pnPostCodeModified			int = null,
	@pnCountryKeyModified		int = null,
	@pnCountryNameModified		int = null
)
-- VERSION:	5
-- DESCRIPTION:	Update an Address of a Name
-- SCOPE:	CPA.net

-- MODIFICATIONS :
-- Date		Who	Version	Change
-- ------------	-------	-------	----------------------------------------------- 
-- 15 Nov 2002 	SF	4	Update Version Number
-- 15 Apr 2013	DV	5	R13270 Increase the length of nvarchar to 11 when casting or declaring integer
AS
	/* SET NOCOUNT ON */
	declare @nErrorCode int
	declare @bMinimumDataMissing int
	declare @bSubtableKeyChanged int
	declare @bParentRelationKeyUnchanged int
	declare @sAddressCode varchar(11)
	declare @nNameNo int
	
	set @nNameNo = Cast(@psNameKey as int)
	
	set @nErrorCode = @@Error
	
	if @nErrorCode = 0
		and	@psStreet is null 
		and @psCity is null
		and	@psStateKey is null
		and	@psPostCode is null
		and	@psCountryKey is null
	begin
		set @bMinimumDataMissing = 1						
	end
		
	if @nErrorCode = 0
		and	(@pnNameKeyModified is not null
		or	@pnAddressTypeIdModified is not null
		or	@pnAddressKeyModified is not null)
	begin
		set @bSubtableKeyChanged = 1
	end
		
	if @nErrorCode = 0
		and (@pnNameKeyModified is not null
		or	@pnAddressTypeIdModified is not null)
	begin
		set @bParentRelationKeyUnchanged = 1
	end
		
	if @nErrorCode = 0
	begin
		if @bMinimumDataMissing is not null
		begin 
				/* remove address */
			exec @nErrorCode = na_DeleteAddress @pnUserIdentityId, @psCulture, @psNameKey, @pnAddressTypeId, @psAddressKey				
		end
		else
		begin
			if @bSubtableKeyChanged is null
			begin
				
				if	(@psAddressKey is not null)
					and (@pnStreetModified is not null
					or @pnCityModified is not null
					or @pnStateKeyModified is not null
					or @pnPostCodeModified is not null
					or @pnCountryKeyModified is not null)					
				begin
					/* update the address row, using the address key*/
					Update	ADDRESS set	
						STREET1		= case when (@pnStreetModified=1) then @psStreet else STREET1 end,
						CITY		= case when (@pnCityModified=1) then @psCity else CITY end,
						STATE		= case when (@pnStateKeyModified=1) then @psStateKey else STATE end,
						POSTCODE	= case when (@pnPostCodeModified=1) then @psPostCode else POSTCODE end,
						COUNTRYCODE 	= case when (@pnCountryKeyModified=1) then @psCountryKey else COUNTRYCODE end
					where	ADDRESSCODE = Cast(@psAddressKey as int)
					
					set @nErrorCode = @@Error
				end												
			end
			else
			begin
			if @bParentRelationKeyUnchanged = 1
			begin
				
				/* get previous address in this row */				
				select	@sAddressCode = Cast(POSTALADDRESS as varchar(11))
				from	NAME
				where	NAMENO = @nNameNo
					
				if (@psAddressKey is null) or (@sAddressCode <> @psAddressKey)
				begin
					/* delete old child and relationship */
					exec @nErrorCode = na_DeleteAddress @pnUserIdentityId, @psCulture, @psNameKey, @pnAddressTypeId, @sAddressCode
					
					if @nErrorCode = 0
					begin					
						/* create new child with relationship */						
						exec @nErrorCode = [dbo].[na_InsertAddress] @pnUserIdentityId, @psCulture, @psNameKey, @pnAddressTypeId, @psAddressKey OUTPUT , @psFreeFormAddress, @psStreet, @psCity, @psStateKey, @psStateName, @psPostCode, @psCountryKey, @psCountryName
					end
				end				
			end
			end			
		end
	
	end
	
	RETURN @nErrorCode


GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

grant exec on dbo.na_UpdateAddress to public
go
