---------------------------------------------------------------------------------------------
-- Creation of dbo.na_InsertTelecommunication
---------------------------------------------------------------------------------------------
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[na_InsertTelecommunication]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop Stored Procedure dbo.na_InsertTelecommunication.'
	drop procedure [dbo].[na_InsertTelecommunication]
	print '**** Creating Stored Procedure dbo.na_InsertTelecommunication...'
	print ''
end
go

SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO

create    procedure dbo.na_InsertTelecommunication
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) = null,  	-- the language in which output is to be expressed
	@psNameKey		varchar(11),  
	@pnTelecomTypeId	int, 
	@psTelecomKey		nvarchar(11) output,
	@psTelecomISD		nvarchar(5) = null,
	@psTelecomAreaCode	nvarchar(5) = null,
	@psTelecomNumber	nvarchar(100) = null,
	@psTelecomExtension	nvarchar(5) = null
)
-- VERSION:	8
-- DESCRIPTION:	Insert Telecommunication for a Name
-- SCOPE:	CPA.net

-- MODIFICATIONS :
-- Date		Who	Number	Version	Change
-- ------------	-------	------	-------	----------------------------------------------- 
-- 15 Nov 2002	SF		4	Default Reminder Emails to true when the telecommunication row affected is an Email type.
-- 15 Nov 2002	SF		4	Update Version Number
-- 25 Feb 2004	TM	RFC867	6	Update Name.MainEmail column for the MainEmail (if @pnTelecomTypeId = 2) similar 
--					to Name.MainPhone and Name.Fax columns. Before updating the Name.MainEmail check
--					that there is no data in that column already. If there is, the Name.MainEmail 
--					column should not be updated.
-- 22 Nov 2007	SW	RFC5967	7	Change TELECOMMUNICATION.TELECOMNUMBER from nvarchar(50) to nvarchar(100)
-- 15 Apr 2013	DV	R13270	8	Increase the length of nvarchar to 11 when casting or declaring integer

as
begin
		
	-- assumes that a new row needs to be created.
	-- get last internal code.
	declare @nLastInternalCode int
	declare @nTelecomType int
	declare @nErrorCode int

	set @nErrorCode=@@Error

	if  @nErrorCode = 0
	and @psTelecomNumber is null
	and @psTelecomExtension is null
	begin
		/* minimum data requirement not met */
		set @nErrorCode = -1
	end
	
	if @nErrorCode = 0
	begin	
		select 	@nLastInternalCode = INTERNALSEQUENCE + 1
		from	LASTINTERNALCODE
		where 	TABLENAME = 'TELECOMMUNICATION'
	
		select @nErrorCode=@@Error
	end

	if @nErrorCode = 0
	begin
		/* Update Name Row 
		      Phone = 1 (Phone	Device Type 	= 1901)
		      Fax   = 2	(Fax Device Type	= 1902)
		      Email = 3 (Email Device Type	= 1903)

		*/

		declare @bReminderEmail decimal(1,0)

		select @nTelecomType = 
			case @pnTelecomTypeId 
				when 1 then 1901
				when 2 then 1902
				when 3 then 1903
			else
				1901 -- there are other types but should really return an error.
			end,
			@bReminderEmail =
			case @pnTelecomTypeId 
				when 3 then 1
			else
				null
			end
	
		insert 
		into TELECOMMUNICATION (TELECODE, TELECOMTYPE, ISD, AREACODE, TELECOMNUMBER, EXTENSION, REMINDEREMAILS)
		values	(@nLastInternalCode, @nTelecomType, @psTelecomISD, @psTelecomAreaCode, @psTelecomNumber, @psTelecomExtension, @bReminderEmail)	

		set @nErrorCode = @@Error
	end
	
	if @nErrorCode= 0
	begin
		set @psTelecomKey = Cast(@nLastInternalCode as nvarchar(11))
		update 	LASTINTERNALCODE 
		set 	INTERNALSEQUENCE = @nLastInternalCode
		where 	TABLENAME = 'TELECOMMUNICATION'
		
		set @nErrorCode = @@Error
	end


	/* Add Name Telecom Row */
	if @nErrorCode = 0
	begin
		insert into NAMETELECOM (NAMENO, TELECODE, OWNEDBY)
		values (@psNameKey, @nLastInternalCode, 1)

		set @nErrorCode = @@Error
	end
	
	/* Update Name Row 
	      Phone = 1,
	      Fax = 2,
	      Email = 3  
	*/
	if @nErrorCode = 0
	begin

		if @pnTelecomTypeId = 1
		begin
			update NAME 
			set MAINPHONE = @nLastInternalCode
			where NAMENO = @psNameKey
		end

		if @pnTelecomTypeId = 2
		begin
			update NAME 
			set FAX = @nLastInternalCode
			where NAMENO = @psNameKey
		end

		if @pnTelecomTypeId = 3
		and exists (Select * from NAME where NAMENO = @psNameKey and MAINEMAIL is null)
		begin
			update NAME 
			set MAINEMAIL = @nLastInternalCode
			where NAMENO = @psNameKey
		end

		set @nErrorCode = @@Error
	end

	return @nErrorCode

end
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

grant exec on dbo.na_InsertTelecommunication to public
go
