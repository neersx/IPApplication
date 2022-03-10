-----------------------------------------------------------------------------------------------------------------------------
-- Creation of dbo.na_DeleteAddress
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[na_DeleteAddress]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop Stored Procedure dbo.na_DeleteAddress.'
	drop procedure [dbo].[na_DeleteAddress]
	print '**** Creating Stored Procedure dbo.na_DeleteAddress...'
	print ''
end
go

SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO

create     procedure dbo.na_DeleteAddress
(
	@pnUserIdentityId	int,			-- Mandatory
	@psCulture		nvarchar(10) = null,  	-- the language in which output is to be expressed
	@psNameKey		varchar(11) = null,	
	@pnAddressTypeId	int = null, 		
	@psAddressKey		varchar(11) = null
)
-- VERSION:	5
-- DESCRIPTION:	Delete an Address for a Name
-- SCOPE:	CPA.net

-- MODIFICATIONS :
-- Date		Who	Version	Change
-- ------------	-------	-------	----------------------------------------------- 
-- 15 Nov 2002 	SF	4	Update Version Number
-- 15 Apr 2013	DV	5	R13270 Increase the length of nvarchar to 11 when casting or declaring integer
as
begin
			
	/* Update Name Row  
		      Postal Address = 1  

	*/

	-- requires that NameKey exists and maps to NAME.NAMENO.
	declare @nErrorCode int
	declare @nNameNo int
	declare @nAddressCode int

	set @nErrorCode = 0

	if @psNameKey is null
	and @pnAddressTypeId is null
	and @psAddressKey is null
	begin
		/* minimum data is unavailable */
	 	set @nErrorCode = -1		
	end
	
	if @nErrorCode = 0
	begin
		select @nNameNo = Cast(@psNameKey as int)
		select @nErrorCode = @@Error
	end
	if @nErrorCode = 0
	begin
		select @nAddressCode = Cast(@psAddressKey as int)
		select @nErrorCode = @@Error
	end

	/* assumes the addresstypeid is valid */
	if @pnAddressTypeId = 1 and @nErrorCode = 0
	begin
		/* remove ADDRESS reference from NAME.POSTALADDRESS */
		update	NAME		
		   set	POSTALADDRESS = null
		 where	NAMENO = @nNameNo
		   and	POSTALADDRESS = @nAddressCode
			
		select @nErrorCode = @@Error			
	end
			
	if exists (select 	*  
			from 	NAME  
			where 	NAMENO = @nNameNo
			and 	(POSTALADDRESS = @nAddressCode
			or	STREETADDRESS = @nAddressCode))
	begin
		select @nErrorCode = -1
	end

	if @pnAddressTypeId = 1 and @nErrorCode = 0
	begin
		/*
			Postal Address Type	= 301
			Street Address Type	= 302
		*/
		delete  
		from 	NAMEADDRESS
		where 	NAMENO = @nNameNo
		and	ADDRESSCODE = @nAddressCode
		and	ADDRESSTYPE = 301
		/* owned by ? */
			
		select @nErrorCode = @@Error		
	end
		
	if @nErrorCode = 0 and  
		not exists (Select	*
				from	NAMEADDRESS
				where	ADDRESSCODE = @nAddressCode)
	begin
		delete  
		from 	ADDRESS
		where	ADDRESSCODE = @nAddressCode
			
		select @nErrorCode = @@Error					
	end

	return @nErrorCode
end
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

grant exec on dbo.na_DeleteAddress to public
go
