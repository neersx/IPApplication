-----------------------------------------------------------------------------------------------------------------------------
-- Creation of cs_GetDebtorContactKeys
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[cs_GetDebtorContactKeys]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.cs_GetDebtorContactKeys.'
	Drop procedure [dbo].[cs_GetDebtorContactKeys]
End
Print '**** Creating Stored Procedure dbo.cs_GetDebtorContactKeys...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.cs_GetDebtorContactKeys
(
	@pnAttentionKey			int		OUTPUT,		-- maybe inputted
	@pnAddressKey			int		OUTPUT,		-- maybe inputted
	@pnUserIdentityId		int,				-- Mandatory
	@pnNameKey			int,				-- Mandatory
	@pnInheritedNameKey		int,				-- The key of the name on the left hand side of the associate name relationship that the case name was inherited from.
	@psInheritedRelationCode	nvarchar(3),			-- The key of the associated name relationship that the case name was inherited from
	@pnInheritedSequence		smallint			-- The sequence number of the associated name relationship that the case name was inherited from
)
as
-- PROCEDURE:	cs_GetDebtorContactKeys
-- VERSION:	1
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	The procedure returns the keys of the attention and address that will be used for a debtor case name (either Debtor (D) or Renewal Debtor (Z)). 
--		Note: the procedure does not assume that the case name information is already written to the database.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 24 Apr 2006	SW	1	1	Procedure created

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare	@nErrorCode	int
Declare @sSQLString	nvarchar(4000)

-- Initialise variables
Set @nErrorCode = 0

If @nErrorCode = 0 and (@pnAttentionKey is null or @pnAddressKey is null)
Begin
	/*
		STEP1	If the debtor was inherited from the associated name
			then the details recorded against this associated name will be returned.
	
		STEP2	Check if the address/attention has been overridden on Send Bills To associated name relationship.
	
		STEP3	Check from NAME table, we always have a row in NAME.
	*/

	Set @sSQLString = '
		Select 		@pnAttentionKey = coalesce(@pnAttentionKey, STEP1.CONTACT, STEP2.CONTACT, STEP3.MAINCONTACT),
				@pnAddressKey = coalesce(@pnAddressKey, STEP1.POSTALADDRESS, STEP2.POSTALADDRESS, STEP3.POSTALADDRESS)
		from		[NAME] STEP3
		left join	ASSOCIATEDNAME STEP1 on (STEP1.NAMENO = @pnInheritedNameKey
							 	and STEP1.RELATIONSHIP = @psInheritedRelationCode
								and STEP1.[SEQUENCE] = @pnInheritedSequence
								and STEP1.RELATEDNAME = @pnNameKey)
		left join	ASSOCIATEDNAME STEP2 on (STEP2.NAMENO = @pnNameKey and STEP2.RELATIONSHIP = ''BIL'' and STEP2.RELATEDNAME = @pnNameKey)
		where		STEP3.NAMENO = @pnNameKey'

	Exec @nErrorCode = sp_executesql @sSQLString,
				N'@pnAttentionKey		int				OUTPUT,
				  @pnAddressKey			int				OUTPUT,
				  @pnInheritedNameKey		int,
				  @psInheritedRelationCode	nvarchar(3),
				  @pnInheritedSequence		smallint,
				  @pnNameKey			int',
				  @pnAttentionKey		= @pnAttentionKey		OUTPUT,
				  @pnAddressKey			= @pnAddressKey			OUTPUT,
				  @pnInheritedNameKey		= @pnInheritedNameKey,
				  @psInheritedRelationCode	= @psInheritedRelationCode,
				  @pnInheritedSequence		= @pnInheritedSequence,
				  @pnNameKey			= @pnNameKey

End

Return @nErrorCode
GO

Grant execute on dbo.cs_GetDebtorContactKeys to public
GO
