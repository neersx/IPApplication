-----------------------------------------------------------------------------------------------------------------------------
-- Creation of naw_UpdateNameAddress									      
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[naw_UpdateNameAddress]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.naw_UpdateNameAddress.'
	Drop procedure [dbo].[naw_UpdateNameAddress]
End
Print '**** Creating Stored Procedure dbo.naw_UpdateNameAddress...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
-- Allow comparison of null values.
-- Procedure uses setting in place before it's created.
SET ANSI_NULLS OFF
GO


CREATE PROCEDURE dbo.naw_UpdateNameAddress
(
	@pnUserIdentityId		int,		-- Mandatory
	@psCulture			nvarchar(10) 	= null,
	@pbCalledFromCentura		bit		= 0,
	@pnNameKey			int,		-- Mandatory
	@pnAddressKey			int		= null OUTPUT,
	@pnAddressTypeKey		int,		-- Mandatory

	@pbIsOwner			bit		= null,
	@psStreet			nvarchar(254)	= null,
	@psCity				nvarchar(30)	= null,
	@psStateCode			nvarchar(20)	= null,
	@psPostCode			nvarchar(10)	= null,
	@psCountryCode			nvarchar(3)	= null,
	@pnTelephoneKey			int		= null,
	@pnFaxKey			int		= null,
	@pnAddressStatusKey		int		= null,
	@pdtDateCeased			datetime	= null,

	@pnOldAddressKey		int,		-- Mandatory
	@pnOldAddressTypeKey		int,		-- Mandatory

	@pbOldIsOwner			bit		= null,
	@psOldStreet			nvarchar(254)	= null,
	@psOldCity			nvarchar(30)	= null,
	@psOldStateCode			nvarchar(20)	= null,
	@psOldPostCode			nvarchar(10)	= null,
	@psOldCountryCode		nvarchar(3)	= null,
	@pnOldTelephoneKey		int		= null,
	@pnOldFaxKey			int		= null,
	@pnOldAddressStatusKey		int		= null,
	@pdtOldDateCeased		datetime	= null,

	@pbIsIsOwnerInUse		bit		= 0,
	@pbIsStreetInUse		bit		= 0,
	@pbIsCityInUse			bit		= 0,
	@pbIsStateCodeInUse		bit		= 0,
	@pbIsPostCodeInUse		bit		= 0,
	@pbIsCountryCodeInUse		bit		= 0,
	@pbIsTelephoneKeyInUse		bit		= 0,
	@pbIsFaxKeyInUse		bit		= 0,
	@pbIsAddressStatusKeyInUse	bit		= 0,
	@pbIsDateCeasedInUse		bit		= 0,
	@psTelephoneISD			nvarchar(5)	= null,		
	@psTelephoneAreaCode		nvarchar(5)	= null,
	@psTelephoneNumber		nvarchar(100)	= null,
	@psTelephoneExt			nvarchar(5)	= null,
	@psFaxISD			nvarchar(5)	= null,
	@psFaxAreaCode			nvarchar(5)	= null,
	@psFaxNumber			nvarchar(100)	= null, 
	@psOldTelephoneISD		nvarchar(5)	= null,		
	@psOldTelephoneAreaCode		nvarchar(5)	= null,
	@psOldTelephoneNumber		nvarchar(100)	= null,
	@psOldTelephoneExt		nvarchar(5)	= null,
	@psOldFaxISD			nvarchar(5)	= null,
	@psOldFaxAreaCode		nvarchar(5)	= null,
	@psOldFaxNumber			nvarchar(100)	= null 

)
as
-- PROCEDURE:	naw_UpdateNameAddress
-- VERSION:	6
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Update NameAddress if the underlying values are as expected.

-- MODIFICATIONS :
-- Date			Who		Change	Version	Description
-- -----------	-------	------	-------	-----------------------------------------------
-- 13 Jun 2006	SW		RFC3787		1	Procedure created
-- 14 Dec 2007	PG		RFC3497		2	Support for address telecoms
-- 30 Mar 2009	SF		RFC7478		3	Cater for situation where only address type key needs to be changed.
-- 26 Jul 2010	SF		RFC9563		4	Ensure IsOwner flag is returned as either a 0 or a 1.
-- 18 May 2016	MF		R61795		5	Change of Address Type should be handled by an UPDATE of NAMEADDRESS row.
-- 18 Mar 2020	vql		DR-52944	6	Problem correcting lowercase postcode.


SET CONCAT_NULL_YIELDS_NULL OFF
-- Row counts required by the data adapter
SET NOCOUNT OFF
-- Reset so that next procedure gets the default.
SET ANSI_NULLS ON

Declare @nErrorCode		int
Declare @sSQLString 		nvarchar(4000)
Declare @sUpdateString 		nvarchar(4000)
Declare @sWhereString		nvarchar(4000)
Declare @sComma			nchar(1)
Declare @sAnd			nchar(5)
Declare @nTelephoneKey	int

-- Initialise variables
Set @nErrorCode = 0
Set @sAnd = ' and ' 
Set @sWhereString = CHAR(10)+" where "

Set @pbOldIsOwner = ISNULL(@pbOldIsOwner, 0)
Set @pbIsOwner = ISNULL(@pbIsOwner, 0)

-- Add to NAMEADDRESS if no neither keys match
If @nErrorCode = 0
Begin
	If (@pnAddressKey <> @pnOldAddressKey 
	OR  @pnAddressKey is null)
	Begin
		exec @nErrorCode = dbo.naw_InsertNameAddress
			@pnUserIdentityId		= @pnUserIdentityId,
			@psCulture			= @psCulture,
			@pbCalledFromCentura		= @pbCalledFromCentura,
			@pnNameKey			= @pnNameKey,
			@pnAddressKey			= @pnAddressKey OUTPUT,
			@pnAddressTypeKey		= @pnAddressTypeKey,
		
			@pbIsOwner			= @pbIsOwner,
			@psStreet			= @psStreet,
			@psCity				= @psCity,
			@psStateCode			= @psStateCode,
			@psPostCode			= @psPostCode,
			@psCountryCode			= @psCountryCode,
			@pnTelephoneKey			= @pnTelephoneKey,
			@pnFaxKey			= @pnFaxKey,
			@pnAddressStatusKey		= @pnAddressStatusKey,
			@pdtDateCeased			= @pdtDateCeased,
		
			@pbIsIsOwnerInUse		= @pbIsIsOwnerInUse,
			@pbIsStreetInUse		= @pbIsStreetInUse,
			@pbIsCityInUse			= @pbIsCityInUse,
			@pbIsStateCodeInUse		= @pbIsStateCodeInUse,
			@pbIsPostCodeInUse		= @pbIsPostCodeInUse,
			@pbIsCountryCodeInUse		= @pbIsCountryCodeInUse,
			@pbIsTelephoneKeyInUse		= @pbIsTelephoneKeyInUse,
			@pbIsFaxKeyInUse		= @pbIsFaxKeyInUse,
			@pbIsAddressStatusKeyInUse	= @pbIsAddressStatusKeyInUse,
			@pbIsDateCeasedInUse		= @pbIsDateCeasedInUse,
			@psTelephoneISD			= @psTelephoneISD,		
			@psTelephoneAreaCode		= @psTelephoneAreaCode,
			@psTelephoneNumber		= @psTelephoneNumber,
			@psTelephoneExt			= @psTelephoneExt,
			@psFaxISD			= @psFaxISD,
			@psFaxAreaCode			= @psFaxAreaCode,
			@psFaxNumber			= @psFaxNumber 

		If ((@nErrorCode = 0)
		and (@pnAddressKey = @pnOldAddressKey and @pnOldAddressKey is not null))		
		Begin
			-- The end user would like to change the address type of the address.
			-- the above logic ensures the a NAMEADDRESS row is inserted for the name 
			-- the below logic removes the existing row which is no longer relevant.
			
			Set @sSQLString = "Delete from NAMEADDRESS
			   where "

			Set @sSQLString = @sSQLString+CHAR(10)+"
				NAMENO = @pnNameKey and 
				ADDRESSCODE = @pnAddressKey and
				ADDRESSTYPE = @pnAddressTypeKey"

			If @pbIsAddressStatusKeyInUse = 1
			Begin
				Set @sSQLString = @sSQLString+CHAR(10)+@sAnd+"ADDRESSSTATUS = @pnOldAddressStatusKey"
			End

			If @pbIsDateCeasedInUse = 1
			Begin
				Set @sSQLString = @sSQLString+CHAR(10)+@sAnd+"DATECEASED = @pdtOldDateCeased"
			End

			If @pbIsIsOwnerInUse = 1
			Begin
				Set @sSQLString = @sSQLString+CHAR(10)+@sAnd+"ISNULL(OWNEDBY,0) = @pbOldIsOwner"
			End

			exec @nErrorCode=sp_executesql @sSQLString,
						N'
						@pnNameKey		int,
						@pnAddressKey		int,
						@pnAddressTypeKey	int,
						@pbOldIsOwner		bit,
						@pnOldAddressStatusKey	int,
						@pdtOldDateCeased	datetime',
						@pnNameKey	 	= @pnNameKey,
						@pnAddressKey	 	= @pnAddressKey,
						@pnAddressTypeKey	= @pnOldAddressTypeKey,
						@pbOldIsOwner	 	= @pbOldIsOwner,
						@pnOldAddressStatusKey	= @pnOldAddressStatusKey,
						@pdtOldDateCeased	= @pdtOldDateCeased

		End
	End
	-- Update required if keys match
	Else
	Begin
		-- Update Address if necesary
		If ( (@pbIsStreetInUse       = 1 and @psStreet       <> @psOldStreet COLLATE Latin1_General_CS_AS)
		  or (@pbIsCityInUse         = 1 and @psCity         <> @psOldCity COLLATE Latin1_General_CS_AS)
		  or (@pbIsStateCodeInUse    = 1 and @psStateCode    <> @psOldStateCode COLLATE Latin1_General_CS_AS)
		  or (@pbIsPostCodeInUse     = 1 and @psPostCode     <> @psOldPostCode COLLATE Latin1_General_CS_AS)
		  or (@pbIsCountryCodeInUse  = 1 and @psCountryCode  <> @psOldCountryCode COLLATE Latin1_General_CS_AS)
		  or (@pbIsTelephoneKeyInUse = 1 and @pnTelephoneKey <> @pnOldTelephoneKey)
		  or (@pbIsFaxKeyInUse       = 1 and @pnFaxKey       <> @pnOldFaxKey)
		  or (@psTelephoneISD       <> @psOldTelephoneISD)
		  or (@psTelephoneAreaCode  <> @psOldTelephoneAreaCode)
		  or (@psTelephoneNumber    <> @psOldTelephoneNumber)
		  or (@psTelephoneExt       <> @psOldTelephoneExt)
		  or (@psFaxISD             <> @psOldFaxISD)
		  or (@psFaxAreaCode        <> @psOldFaxAreaCode)
		  or (@psFaxNumber          <> @psOldFaxNumber))
		Begin
			Exec @nErrorCode = dbo.naw_UpdateAddress
				@pnUserIdentityId	= @pnUserIdentityId,
				@psCulture		= @psCulture, 
				@pbCalledFromCentura	= @pbCalledFromCentura, 
				@pnAddressKey 		= @pnAddressKey, 

				@psStreet		= @psStreet, 
				@psCity			= @psCity, 
				@psStateCode		= @psStateCode, 
				@psPostCode		= @psPostCode, 
				@psCountryCode		= @psCountryCode, 
				@pnTelephoneKey		= @pnTelephoneKey, 
				@pnFaxKey		= @pnFaxKey, 
		
				@psOldStreet		= @psOldStreet,
				@psOldCity		= @psOldCity,
				@psOldStateCode		= @psOldStateCode,
				@psOldPostCode		= @psOldPostCode,
				@psOldCountryCode	= @psOldCountryCode,
				@pnOldTelephoneKey	= @pnOldTelephoneKey,
				@pnOldFaxKey		= @pnOldFaxKey,

				@pbIsStreetInUse	= @pbIsStreetInUse, 
				@pbIsCityInUse		= @pbIsCityInUse, 
				@pbIsStateCodeInUse	= @pbIsStateCodeInUse, 
				@pbIsPostCodeInUse	= @pbIsPostCodeInUse, 
				@pbIsCountryCodeInUse	= @pbIsCountryCodeInUse, 
				@pbIsTelephoneKeyInUse	= @pbIsTelephoneKeyInUse, 
				@pbIsFaxKeyInUse	= @pbIsFaxKeyInUse

				If @nErrorCode = 0
				Begin
					If @psTelephoneNumber is not null and @psOldTelephoneNumber is null
					Begin	--insert address telecom
						Exec @nErrorCode = dbo.naw_InsertAddressTelecom
							@pnUserIdentityId	= @pnUserIdentityId,
							@psCulture		= @psCulture,
							@pbCalledFromCentura	= 0,
							@pnTelecomKey		= @nTelephoneKey OUTPUT,
							@pnAddressKey		= @pnAddressKey,
							@pnTelecomTypeKey	= '1901',
							@psIsd			= @psTelephoneISD,
							@psAreaCode		= @psTelephoneAreaCode,
							@psTelecomNumber	= @psTelephoneNumber,
							@psExtension		= @psTelephoneExt,
							@pbIsReminderAddress	= null,
							@pbIsMain		=1
					End
					If @nErrorCode =0 and @psFaxNumber is not null and @psOldFaxNumber is null
					Begin	--insert address telecom
						Exec @nErrorCode = dbo.naw_InsertAddressTelecom
							@pnUserIdentityId	= @pnUserIdentityId,
							@psCulture		= @psCulture,
							@pbCalledFromCentura	= 0,
							@pnTelecomKey		= @nTelephoneKey OUTPUT,
							@pnAddressKey		= @pnAddressKey,
							@pnTelecomTypeKey	= '1902',
							@psIsd			= @psTelephoneISD,
							@psAreaCode		= @psTelephoneAreaCode,
							@psTelecomNumber	= @psTelephoneNumber,
							@psExtension		= @psTelephoneExt,
							@pbIsReminderAddress	= null,
							@pbIsMain		=1
					End
					If @nErrorCode =0 and 
					(@pbIsTelephoneKeyInUse = 1 and @pnTelephoneKey = @pnOldTelephoneKey)
					Begin
						exec @nErrorCode = dbo.naw_UpdateTelecommunication
							@pnUserIdentityId	= @pnUserIdentityId,
							@psCulture		= @psCulture,
							@pbCalledFromCentura	= @pbCalledFromCentura,
							@pnTelecomKey		= @pnTelephoneKey,
					
							@pnTelecomTypeKey	= '1901',
							@psIsd			= @psTelephoneISD,
							@psAreaCode		= @psTelephoneAreaCode,
							@psTelecomNumber	= @psTelephoneNumber,
							@psExtension		= @psTelephoneExt,
							@pnCarrierKey		= null,
							@pbIsReminderAddress	= null,
					
							@pnOldTelecomTypeKey	= '1901',
							@psOldIsd		= @psOldTelephoneISD,
							@psOldAreaCode		= @psOldTelephoneAreaCode,
							@psOldTelecomNumber	= @psOldTelephoneNumber,
							@psOldExtension		= @psOldTelephoneExt,
							@pnOldCarrierKey	= null,
							@pbOldIsReminderAddress	= null,
					
							@pbIsTelecomTypeKeyInUse= 1,
							@pbIsIsdInUse		= 1,
							@pbIsAreaCodeInUse	= 1,
							@pbIsTelecomNumberInUse	= 1,
							@pbIsExtensionInUse	= 1,
							@pbIsCarrierKeyInUse	= 0,
							@pbIsIsReminderAddressInUse= 0
					End
		  
					If @nErrorCode =0 and 
					(@pbIsFaxKeyInUse = 1 and @pnFaxKey = @pnOldFaxKey)
					Begin
						exec @nErrorCode = dbo.naw_UpdateTelecommunication
							@pnUserIdentityId	= @pnUserIdentityId,
							@psCulture		= @psCulture,
							@pbCalledFromCentura	= @pbCalledFromCentura,
							@pnTelecomKey		= @pnFaxKey,
					
							@pnTelecomTypeKey	= '1902',
							@psIsd			= @psFaxISD,
							@psAreaCode		= @psFaxAreaCode,
							@psTelecomNumber	= @psFaxNumber,
							@psExtension		= null,
							@pnCarrierKey		= null,
							@pbIsReminderAddress	= null,
					
							@pnOldTelecomTypeKey	= '1902',
							@psOldIsd		= @psOldFaxISD,
							@psOldAreaCode		= @psOldFaxAreaCode,
							@psOldTelecomNumber	= @psOldFaxNumber,
							@psOldExtension		= null,
							@pnOldCarrierKey	= null,
							@pbOldIsReminderAddress	= null,
					
							@pbIsTelecomTypeKeyInUse= 1,
							@pbIsIsdInUse		= 1,
							@pbIsAreaCodeInUse	= 1,
							@pbIsTelecomNumberInUse	= 1,
							@pbIsExtensionInUse	= 1,
							@pbIsCarrierKeyInUse	= 0,
							@pbIsIsReminderAddressInUse= 0
					End
				End				
		End
	
		-- Update NameAddress if necessary
	
		If ( (@pnAddressStatusKey <> @pnOldAddressStatusKey and @pbIsAddressStatusKeyInUse = 1)
		  or (@pdtDateCeased      <> @pdtOldDateCeased      and @pbIsDateCeasedInUse       = 1)
		  or (@pnAddressTypeKey   <> @pnOldAddressTypeKey))
		Begin
			Set @sUpdateString = "Update NAMEADDRESS"
				  +char(10)+ "set "
		
			Set @sWhereString = @sWhereString+CHAR(10)+"
				NAMENO      = @pnNameKey    and
				ADDRESSCODE = @pnAddressKey and
				ADDRESSTYPE = @pnOldAddressTypeKey"
		
			If @pnAddressTypeKey <> @pnOldAddressTypeKey
			Begin
				Set @sUpdateString = @sUpdateString+CHAR(10)+@sComma+"ADDRESSTYPE = @pnAddressTypeKey"
				Set @sWhereString = @sWhereString+CHAR(10)+@sAnd+"not exists(select 1 from NAMEADDRESS NA"
								 +CHAR(10)+  "               where NAMENO     =NAMEADDRESS.NAMENO"
								 +CHAR(10)+  "               and   ADDRESSCODE=NAMEADDRESS.ADDRESSCODE"
								 +CHAR(10)+  "               and   ADDRESSTYPE=@pnAddressTypeKey)"
								  
				Set @sComma = ","
			End
		
			If @pbIsAddressStatusKeyInUse = 1
			Begin
				Set @sUpdateString = @sUpdateString+CHAR(10)+@sComma+"ADDRESSSTATUS = @pnAddressStatusKey"
				Set @sWhereString = @sWhereString+CHAR(10)+@sAnd+"ADDRESSSTATUS = @pnOldAddressStatusKey"
				Set @sComma = ","
			End
		
			If @pbIsDateCeasedInUse = 1
			Begin
				Set @sUpdateString = @sUpdateString+CHAR(10)+@sComma+"DATECEASED = @pdtDateCeased"
				Set @sWhereString = @sWhereString+CHAR(10)+@sAnd+"DATECEASED = @pdtOldDateCeased"
				Set @sComma = ","
			End
		
			If @pbIsIsOwnerInUse = 1
			Begin
				Set @sUpdateString = @sUpdateString+CHAR(10)+@sComma+"OWNEDBY = @pbIsOwner"
				Set @sWhereString = @sWhereString+CHAR(10)+@sAnd+"ISNULL(OWNEDBY,0) = @pbOldIsOwner"
				Set @sComma = ","
			End
		
			Set @sSQLString = @sUpdateString + @sWhereString
		
			exec @nErrorCode=sp_executesql @sSQLString,
						N'
						@pnNameKey		int,
						@pnAddressKey		int,
						@pnOldAddressTypeKey	int,
						@pnAddressTypeKey	int,
						@pbIsOwner		bit,
						@pnAddressStatusKey	int,
						@pdtDateCeased		datetime,
						@pbOldIsOwner		bit,
						@pnOldAddressStatusKey	int,
						@pdtOldDateCeased	datetime',
						@pnNameKey	 	= @pnNameKey,
						@pnAddressKey	 	= @pnAddressKey,
						@pnOldAddressTypeKey	= @pnOldAddressTypeKey,
						@pnAddressTypeKey	= @pnAddressTypeKey,
						@pbIsOwner	 	= @pbIsOwner,
						@pnAddressStatusKey	= @pnAddressStatusKey,
						@pdtDateCeased	 	= @pdtDateCeased,
						@pbOldIsOwner	 	= @pbOldIsOwner,
						@pnOldAddressStatusKey	= @pnOldAddressStatusKey,
						@pdtOldDateCeased	= @pdtOldDateCeased

		End
	End
End

Return @nErrorCode
GO

Grant execute on dbo.naw_UpdateNameAddress to public
GO