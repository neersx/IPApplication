-----------------------------------------------------------------------------------------------------------------------------
-- Creation of dbo.naw_ListContactDetails
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[naw_ListContactDetails]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.naw_ListContactDetails.'
	Drop procedure [dbo].[naw_ListContactDetails]
End
Print '**** Creating Stored Procedure dbo.naw_ListContactDetails...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO

CREATE PROCEDURE dbo.naw_ListContactDetails
(
	@pnUserIdentityId		int,		-- Mandatory
	@psCulture			nvarchar(10) 	= null,
	@pnNameKey			int, 		-- Mandatory
	@pnCaseKey			int		= null,
	@psNameTypeKey			nvarchar(3)	= null,
	@pnCaseSequence			smallint	= null,
	@pnAddressKey			int		= null,
	@pnAttentionKey			int		= null,
	@pnInheritedNameKey		int		= null,
	@psInheritedRelationCode	nvarchar(3)	= null,
	@pnInheritedSequence		smallint	= null

)
AS
-- PROCEDURE:	naw_ListContactDetails
-- VERSION:	4

-- DESCRIPTION:	Populates the contact details dataset.

-- MODIFICATIONS :
-- Date		Who	Number	Version	Change
-- ------------	-------	------	-------	----------------------------------------------- 
-- 27 Apr 2006  SW	RFC3301	1	Procedure created
-- 07 Sep 2006  SW	RFC4163	2	Fix bug when calling fn_GetDerivedAttnNameNo
-- 26 Apr 2007	JS	14323	3	Pass new parameter NameType to fn_GetDerivedAttnNameNo.
-- 02 Nov 2015	vql	R53910	4	Adjust formatted names logic (DR-15543).


SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare @sSQLString 		nvarchar(4000)
Declare @nErrorCode		int
Declare @nRowCount		int




Declare @sLookupCulture		nvarchar(10)

Set 	@nErrorCode 		 = 0
Set	@nRowCount		 = 0

set	@sLookupCulture = dbo.fn_GetLookupCulture(@psCulture, null, 0)


























-- Debtor 
If @psNameTypeKey in ('D', 'Z')
Begin	
	-- If @pnCaseSequence not null, assign params and try to assign ADDRESSCODE and CORRESPONDNAME
	If @pnCaseSequence is not null
	Begin
		
		Set @sSQLString = '
			Select	@pnInheritedNameKey		= INHERITEDNAMENO,
				@psInheritedRelationCode	= INHERITEDRELATIONS,
				@pnInheritedSequence		= INHERITEDSEQUENCE,
				@pnAddressKey			= isnull(ADDRESSCODE, @pnAddressKey), 
				@pnAttentionKey			= isnull(CORRESPONDNAME, @pnAttentionKey)
			from	CASENAME
			where	@pnCaseKey = CASEID
			and	@pnNameKey = NAMENO
			and 	@psNameTypeKey = NAMETYPE
			and	@pnCaseSequence = SEQUENCE
		'
	
		Exec @nErrorCode = sp_executesql @sSQLString,
					N'@pnAddressKey			int				OUTPUT,
					  @pnAttentionKey		int				OUTPUT,
					  @pnInheritedNameKey		int				OUTPUT,
					  @psInheritedRelationCode	nvarchar(3)			OUTPUT,
					  @pnInheritedSequence		int				OUTPUT,
					  @pnCaseKey			int,





















					  @pnNameKey			int,


					  @psNameTypeKey		nvarchar(3),
					  @pnCaseSequence		int',
					  @pnAddressKey			= @pnAddressKey			OUTPUT,
					  @pnAttentionKey		= @pnAttentionKey		OUTPUT,
					  @pnInheritedNameKey		= @pnInheritedNameKey		OUTPUT,
					  @psInheritedRelationCode	= @psInheritedRelationCode	OUTPUT,
					  @pnInheritedSequence		= @pnInheritedSequence		OUTPUT,
					  @pnCaseKey			= @pnCaseKey,
					  @pnNameKey			= @pnNameKey,













































					  @psNameTypeKey		= @psNameTypeKey,
					  @pnCaseSequence		= @pnCaseSequence
	End

	-- if either @pnAddressKey or @pnAttentionKey are null, call cs_GetDebtorContactKeys 
	If @nErrorCode = 0 and (@pnAddressKey is null or @pnAttentionKey is null)
	Begin
		Exec @nErrorCode = dbo.cs_GetDebtorContactKeys
					@pnAttentionKey OUTPUT , 
					@pnAddressKey OUTPUT , 
					@pnUserIdentityId, 
					@pnNameKey, 
					@pnInheritedNameKey, 
					@psInheritedRelationCode, 
					@pnInheritedSequence
	
	End

End
-- Non-debtor
Else
Begin

	If @pnCaseKey is not null
	Begin
		If @pnAttentionKey is null or @pnAddressKey is null
		Begin
			If @pnCaseSequence is null
			Begin
				Set @pnAttentionKey = isnull(@pnAttentionKey, dbo.fn_GetDerivedAttnNameNo(@pnNameKey, @pnCaseKey, @psNameTypeKey))

				If @pnAddressKey is null
				Begin

					Set @sSQLString = '
						Select	@pnAddressKey	= N.STREETADDRESS
						from	NAME N
						join	NAMETYPE on (KEEPSTREETFLAG = 1 and NAMETYPE = @psNameTypeKey)
						where	N.NAMENO = @pnNameKey'

					Exec @nErrorCode = sp_executesql @sSQLString,
								N'@pnAddressKey		int			OUTPUT,
								  @psNameTypeKey	nvarchar(3),
								  @pnNameKey		int',
								  @pnAddressKey		= @pnAddressKey		OUTPUT,
								  @psNameTypeKey	= @psNameTypeKey,
								  @pnNameKey		= @pnNameKey
				End
			End
			Else
			Begin
				Set @sSQLString = '
					Select	@pnAttentionKey	= isnull(@pnAttentionKey, CORRESPONDNAME), 
						@pnAddressKey = isnull(@pnAddressKey, ADDRESSCODE)
					from	CASENAME
					where	@pnCaseKey = CASEID
					and	@pnNameKey = NAMENO
					and 	@psNameTypeKey = NAMETYPE
					and	@pnCaseSequence = SEQUENCE
				'
	
				Exec @nErrorCode = sp_executesql @sSQLString,
							N'@pnAttentionKey	int			OUTPUT,
							  @pnAddressKey		int			OUTPUT,
							  @pnCaseKey		int,
							  @pnNameKey		int,
							  @psNameTypeKey	nvarchar(3),
							  @pnCaseSequence	int',
							  @pnAttentionKey	= @pnAttentionKey	OUTPUT,
							  @pnAddressKey		= @pnAddressKey		OUTPUT,
							  @pnCaseKey		= @pnCaseKey,
							  @pnNameKey		= @pnNameKey,
							  @psNameTypeKey	= @psNameTypeKey,
							  @pnCaseSequence	= @pnCaseSequence
	
			End
		End
	End



	If @nErrorCode = 0 and (@pnAttentionKey is null or @pnAddressKey is null)
	Begin
		-- Look at NAME.MAINCONTACT
		If @nErrorCode = 0
		Begin
			Set @sSQLString = '
				Select	@pnAttentionKey	= isnull(@pnAttentionKey, MAINCONTACT),
					@pnAddressKey = isnull(@pnAddressKey, POSTALADDRESS)
				from	[NAME]
				where	NAMENO = @pnNameKey
			'
	
			Exec @nErrorCode = sp_executesql @sSQLString,
						N'@pnAttentionKey	int			OUTPUT,
						  @pnAddressKey		int			OUTPUT,
						  @pnNameKey		int',
						  @pnAttentionKey	= @pnAttentionKey	OUTPUT,
						  @pnAddressKey		= @pnAddressKey		OUTPUT,
						  @pnNameKey		= @pnNameKey
		End
	End
End



-- Populating Name Result Set
	
If @nErrorCode = 0
Begin
	Set @sSQLString = 
	"Select N.NAMENO 	as 'NameKey',"+CHAR(10)+ 
	-- If Name.NameStyle is not null then pass the @pnNameStyle = Name.NameStyle to the
	-- fn_FormatNameUsingNameNo, else use Country.NameStyle. If still null, use 7101 NameStyle (Name Last)   
	"dbo.fn_FormatNameUsingNameNo(N.NAMENO, COALESCE(N.NAMESTYLE, NN.NAMESTYLE, 7101))"+CHAR(10)+  	
	"			as 'Name',"+CHAR(10)+  
	"N.NAMECODE		as 'NameCode',"+CHAR(10)+ 	
	dbo.fn_SqlTranslatedColumn('DEBTORSTATUS','DEBTORSTATUS',null,'DS',@sLookupCulture,0)
				+ " as 'Restriction',"+CHAR(10)+ 
	"DS.ACTIONFLAG		as 'RestrictionActionKey',"+CHAR(10)+ 

	"N1.NAMENO		as 'ContactKey',"+CHAR(10)+ 
	"dbo.fn_FormatNameUsingNameNo(N1.NAMENO, COALESCE(N1.NAMESTYLE, NN1.NAMESTYLE, 7101))"+CHAR(10)+ 	
	"			as 'ContactName'"+CHAR(10)+ 

     	"from NAME N"+CHAR(10)+   	
	"left join COUNTRY NN		on (NN.COUNTRYCODE = N.NATIONALITY)"+CHAR(10)+ 
	-- Look for contact information for @pnAttentionKey
	"left join NAME N1		on (N1.NAMENO  = @pnAttentionKey)"+CHAR(10)+ 
	"left join COUNTRY NN1		on (NN1.COUNTRYCODE = N1.NATIONALITY)"+CHAR(10)+ 
	-- For Restriction
	"left join IPNAME IP		on (IP.NAMENO = N.NAMENO)"+CHAR(10)+ 
	"left join DEBTORSTATUS DS	on (DS.BADDEBTOR = IP.BADDEBTOR)"+CHAR(10)+ 

	"where N.NAMENO = @pnNameKey"

	exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnNameKey		 int,
					  @pnUserIdentityId	 int,
					  @pnAttentionKey	 int',
					  @pnNameKey		 = @pnNameKey,
					  @pnUserIdentityId	 = @pnUserIdentityId,
					  @pnAttentionKey	 = @pnAttentionKey
End


-- Populating Telecommunications result set
If @nErrorCode = 0
Begin
	Exec @nErrorCode = naw_ListImportantTelecom
				@pnUserIdentityId	= @pnUserIdentityId,
				@psCulture		= @psCulture,
				@pnNameKey		= @pnNameKey,
				@pbCalledFromCentura	= 0

End
 
-- Populating Address result set
If @nErrorCode = 0
Begin
	Exec @nErrorCode = naw_ListAddressVersions
				@pnUserIdentityId	= @pnUserIdentityId,
				@pbCalledFromCentura	= 0,
				@pnAddressKey		= @pnAddressKey,
				@pbIncludeOriginal	= 1

End

Return @nErrorCode
GO

Grant execute on dbo.naw_ListContactDetails to public
GO


