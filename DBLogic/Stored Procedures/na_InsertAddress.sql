---------------------------------------------------------------------------------------------
-- Creation of dbo.na_InsertAddress
---------------------------------------------------------------------------------------------
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[na_InsertAddress]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop Stored Procedure dbo.na_InsertAddress.'
	drop procedure [dbo].[na_InsertAddress]
	print '**** Creating Stored Procedure dbo.na_InsertAddress...'
	print ''
end
go

SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO

create   procedure dbo.na_InsertAddress
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) = null,  	-- the language in which output is to be expressed
	@psNameKey		varchar(11), 
	@pnAddressTypeId	int, 		
	@psAddressKey		nvarchar(11) output,
	@psFreeFormAddress	nvarchar(254) = null,		-- not used?
	@psStreet		nvarchar(254) = null,
	@psCity			nvarchar(30) = null,
	@psStateKey		nvarchar(20) = null,
	@psStateName		nvarchar(40) = null,
	@psPostCode		nvarchar(11) = null,
	@psCountryKey		nvarchar(3) = null,
	@psCountryName		nvarchar(60) = null
)

-- PROCEDURE :	na_InsertAddress
-- VERSION :	8
-- DESCRIPTION:	Insert an Address to a name
-- CALLED BY :	

-- Date		MODIFICTION HISTORY
-- ====         ===================
-- 04/07/2002	SF			Procedure created
-- 19/07/2002	SF			Remove StateKey Check.
-- 15 Apr 2013	DV	8	R13270 Increase the length of nvarchar to 11 when casting or declaring integer
as
begin

	
		
	-- assumes that a new row needs to be created.
	-- get last internal code.
	declare @nLastInternalCode int
	declare @nErrorCode int
	declare @nAddressType int
	set @nErrorCode = 0

	if @nErrorCode = 0
	begin
		if (@psCountryKey is null) or
			(@psCountryKey is not null and 
			not exists(select * from COUNTRY where COUNTRYCODE = @psCountryKey))
		begin
			-- insert country?
			-- just return an errorcode for now.
			set @nErrorCode = -1
		end
	end

/*	
	if @nErrorCode = 0
	begin	
		if (@psStateKey is null) or
			(@psStateKey is not null and 
			not exists(select * from STATE where STATE = @psStateKey))
		begin
			-- insert state?
			-- just return an errorcode for now.
			set @nErrorCode = -2		
		end
	end
*/
	if @nErrorCode = 0
	begin
		-- -------------------------
		-- Get the next sequence no - JB added 16/7/02
		Exec @nErrorCode = ip_GetLastInternalCode 1, NULL, 'ADDRESS', @nLastInternalCode OUTPUT
	end	

	if @nErrorCode = 0
	begin
		insert 
		into 	ADDRESS (ADDRESSCODE, STREET1, CITY, STATE, POSTCODE, COUNTRYCODE)
		values	(@nLastInternalCode, @psStreet, @psCity, @psStateKey, @psPostCode, @psCountryKey)	

		select @nErrorCode=@@Error
	end
	
	if @nErrorCode= 0
	begin
		set @psAddressKey = Cast(@nLastInternalCode as nvarchar(11))
		--update 	LASTINTERNALCODE 
		--set 	INTERNALSEQUENCE = @nLastInternalCode
		--where 	TABLENAME = 'ADDRESS'

		select @nErrorCode=@@Error
	end

	/* Add Name Address Row 
	      Postal = 1
	*/
	if @nErrorCode = 0
	begin
		/*
			Postal Address Type	= 301
			Street Address Type	= 302

		select @nAddressType = 
			Case @pnAddressTypeId
			when 1 then 301
			else 302  -- or whatever else to be implemented later.
			end		
		*/			
		insert into NAMEADDRESS (NAMENO, ADDRESSTYPE, ADDRESSCODE, OWNEDBY)
		values (@psNameKey, 301, @nLastInternalCode, 1)

		select @nErrorCode = @@Error
	end
	
	/* Update Name Row 
	      Postal = 1  -- there is no implemenration for MAINEMAIL in the NAME table
	*/
	if @nErrorCode = 0
	begin

		if @pnAddressTypeId = 1
		begin
			update NAME 
			set POSTALADDRESS = @nLastInternalCode
			where NAMENO = @psNameKey
		end

		select @nErrorCode = @@Error
	end

	return @nErrorCode
end
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

grant exec on dbo.na_InsertAddress to public
go
