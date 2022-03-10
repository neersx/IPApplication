---------------------------------------------------------------------------------------------
-- Creation of dbo.na_UpdateTelecommunication
---------------------------------------------------------------------------------------------
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[na_UpdateTelecommunication]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.na_UpdateTelecommunication.'
	drop procedure [dbo].[na_UpdateTelecommunication]
	Print '**** Creating Stored Procedure dbo.na_UpdateTelecommunication...'
	Print ''
End
go

SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO

create  procedure dbo.na_UpdateTelecommunication
(
	@pnUserIdentityId		int,			-- Mandatory
	@psCulture			nvarchar(10) = null,  	-- the language in which output is to be expressed
	@psNameKey			varchar(11) = null,	-- NAME.NAMENO
	@psTelecomKey			varchar(11) = null,	-- NAME.MAINPHONE
	@pnTelecomTypeId		int,
	@psTelecomISD			nvarchar(5) = null,
	@psTelecomAreaCode		nvarchar(5) = null,
	@psTelecomNumber		nvarchar(100) = null,                         
	@psTelecomExtension		nvarchar(5) = null,

	@pnNameKeyModified		int = null,
	@pnTelecomKeyModified		int = null,
	@pnTelecomTypeIdModified	int = null,
	@pnTelecomISDModified		int = null,
	@pnTelecomAreaCodeModified 	int = null,
	@pnTelecomNumberModified	int = null,
	@pnTelecomExtensionModified	int = null
)

-- PROCEDURE :	na_UpdateTelecommunication
-- VERSION :	6
-- DESCRIPTION:	Update the Telecommunication table and its child tables
-- SCOPE :	
-- Date		Who	Version	Change
-- ------------	-------	-------	----------------------------------------------- 
-- 01/07/2002	JB		Procedure created
-- 02/07/2002	SF		Put parameters as nullable, and adjusts sp to reflect that.
-- 15/11/2002	SF	4	Default Reminder Emails to true when the telecommunication row affected is an Email type.
-- 22 Nov 2007	SW	5	Change TELECOMMUNICATION.TELECOMNUMBER from nvarchar(50) to nvarchar(100)
-- 15 Apr 2013	DV	6	R13270 Increase the length of nvarchar to 11 when casting or declaring integer

AS
Declare @nTelecode int
Select @nTelecode = Cast(@psTelecomKey as int)
Declare @nErrorCode int
Declare @bMinimumDataMissing bit
Declare @bSubtableKeyChanged bit

set @nErrorCode = 0
-- ------------------------------------------
-- First stage is to check the situation
-- ------------------------------------------
If 	(@pnNameKeyModified = 1)
	or	(@pnTelecomTypeIdModified = 1)
	or	(@pnTelecomKeyModified = 1)

	Set @bSubtableKeyChanged = 1

-- Checking minimum data requirements --
If 	(@psTelecomNumber is null  	
and 	@psTelecomExtension is null)
and 	( @pnTelecomNumberModified = 1  
or  	@pnTelecomExtensionModified = 1 )	
begin
	Set @bMinimumDataMissing = 1
end


If @bMinimumDataMissing = 1
	-- we need to delete the child as it does not contain the minimum data
	Begin
		exec @nErrorCode = na_DeleteTelecommunication 
			@pnUserIdentityId=@pnUserIdentityId, @psCulture=@psCulture, 
			@pnTelecomTypeId=@pnTelecomTypeId, @psTelecomKey=@psTelecomKey
		Return @nErrorCode
	End

If @pnNameKeyModified = 1
	-- This is not covered in the spec so I guess we are not going to handle it heere
	Return @nErrorCode

If @psTelecomKey is null or @pnTelecomKeyModified = 1
Begin
	-- Remove the existing child
	Exec @nErrorCode = na_DeleteTelecommunication 
		@pnUserIdentityId=@pnUserIdentityId, @psCulture=@psCulture, 
		@pnTelecomTypeId=@pnTelecomTypeId, @psTelecomKey=@psTelecomKey

	If @psTelecomKey is not null and @nErrorCode <> 0
		-- We need to pick up the values from an existing row
		-- not sure about this bit
		Select 	@psTelecomISD=ISD,
			@psTelecomAreaCode=AREACODE,
			@psTelecomNumber=TELECOMNUMBER,
			@psTelecomExtension=EXTENSION
		from	TELECOMMUNICATION
		where TELECODE=@nTelecode

	-- Either way we need to add a new child
	Exec @nErrorCode = na_InsertTelecommunication
		@pnUserIdentityId=@pnUserIdentityId, @psCulture=@psCulture,
		@psNameKey=@psNameKey, @pnTelecomTypeId=@pnTelecomTypeId, 
		@psTelecomKey=@psTelecomKey, @psTelecomISD=@psTelecomISD,
		@psTelecomAreaCode=@psTelecomAreaCode, @psTelecomNumber=@psTelecomNumber,
		@psTelecomExtension=@psTelecomExtension

	Return @nErrorCode
End

-- Otherwise (no changes to the Telecode) we simply update the row
If @pnTelecomISDModified = 1
	or @pnTelecomAreaCodeModified = 1
	or @pnTelecomNumberModified = 1
	or @pnTelecomExtensionModified = 1

	update 	TELECOMMUNICATION Set
		ISD 		= case when (@pnTelecomISDModified=1) then @psTelecomISD else ISD end,
		AREACODE 	= case when (@pnTelecomAreaCodeModified=1) then @psTelecomAreaCode else AREACODE end,
		TELECOMNUMBER 	= case when (@pnTelecomNumberModified=1) then @psTelecomNumber else TELECOMNUMBER end,
		EXTENSION 	= case when (@pnTelecomExtensionModified=1) then @psTelecomExtension else EXTENSION end,
		REMINDEREMAILS 	= case @pnTelecomTypeId when 3 then 1 else null end
	where 	TELECODE = @nTelecode	

RETURN @nErrorCode
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

grant exec on dbo.na_UpdateTelecommunication to public
go
