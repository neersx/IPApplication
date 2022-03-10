-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ipo_MailingLabel
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[ipo_MailingLabel]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.ipo_MailingLabel.'
	drop procedure dbo.ipo_MailingLabel
end
print '**** Creating procedure dbo.ipo_MailingLabel...'
print ''
go

create procedure dbo.ipo_MailingLabel
	@pnNameNo int,
	@psOverridingRelationship varchar(3) = NULL,
	@prsLabel varchar(254) = NULL OUTPUT

as
-- PROCEDURE :	ipo_MailingLabel
-- VERSION :	2.1.0
-- DESCRIPTION:	Format the Name, Attention and Postal Address into  a single string separated by Carriage Returns for 
-- 		the supplied NameNo.  Will use the base name attributes unless an overriding relationship is provided.
-- 		This is an AssociatedName relationship such as Billing address or Statement address.  If provided, the 
-- 		routine will use any attention or postal address on the associated name in preference to the base name 
-- 		information.
-- CALLED BY :	arb_OpenItemStatement, ipr_MailingLabel

-- Date		USER	MODIFICTION HISTORY
-- ====         ====	===================
-- 11/07/2001 	AvdA 	#6730 NameAddress formatting
-- 07/10/2003	AB	Add dbo owner to create procedure

DECLARE @nAttention INT, @nAddress INT, @nName INT,
	@sClientName varchar(254), @sAttention varchar(254),
	@sAddress varchar(254), @sNameWhere varchar(25)

IF @pnNameNo IS NULL
	RETURN
ELSE
	BEGIN
	IF exists( 
			select * from ASSOCIATEDNAME
			where NAMENO = @pnNameNo and
			@psOverridingRelationship IS NOT NULL and
			RELATIONSHIP = @psOverridingRelationship )
		BEGIN
		-- Choose assoc name values for preference, but default to related name
		select 	@nAttention = isnull( AN.CONTACT, RN.MAINCONTACT),
			@nAddress = isnull( AN.POSTALADDRESS, RN.POSTALADDRESS),
			@nName = AN.RELATEDNAME
			from ASSOCIATEDNAME AN, NAME RN
			where AN.NAMENO = @pnNameNo and
			AN.RELATIONSHIP = @psOverridingRelationship and
			AN.RELATEDNAME = RN.NAMENO
		END
	ELSE
		BEGIN
		select @nAttention = MAINCONTACT, @nAddress = POSTALADDRESS,
			@nName = NAMENO
		from NAME
		where NAMENO = @pnNameNo
		END

	EXEC ipo_FormatName @pnNameNo = @nName, @prsFormattedName = @sClientName OUTPUT
	EXEC ipo_FormatName @pnNameNo = @nAttention, @prsFormattedName = @sAttention OUTPUT
	EXEC ipo_FormatAddress @pnAddressCode = @nAddress, @prsFormattedAddress = @sAddress OUTPUT 

	-- Find where the country usually puts the name (before or after the address)
	select @sNameWhere = USERCODE 
	from ADDRESS A, COUNTRY CT,  TABLECODES ADS
	where A.COUNTRYCODE = CT.COUNTRYCODE
	and ADS.TABLECODE = CT.ADDRESSSTYLE 
	and ADS.TABLETYPE = 72 
	and A.ADDRESSCODE = @nAddress 

	select @prsLabel = convert( varchar(254),  CASE 
		WHEN @sNameWhere = 'NameBefore'
			THEN 
			CASE WHEN @sClientName IS NOT NULL THEN @sClientName + char(13) + char(10) END
			+ CASE WHEN @sAttention IS NOT NULL THEN @sAttention + char(13) + char(10) END
			+ @sAddress
		WHEN @sNameWhere = 'NameAfter'
			THEN
			CASE WHEN @sAddress IS NOT NULL THEN @sAddress + char(13) + char(10) END
			+ CASE WHEN @sAttention IS NOT NULL THEN @sAttention + char(13) + char(10) END
			+ @sClientName  
		END)

	END

Return 0
GO

grant execute on dbo.ipo_MailingLabel TO public
GO
