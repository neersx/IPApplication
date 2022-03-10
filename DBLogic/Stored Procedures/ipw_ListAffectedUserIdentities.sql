-----------------------------------------------------------------------------------------------------------------------------
-- Creation of dbo.ipw_ListAffectedUserIdentities
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ipw_ListAffectedUserIdentities]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ipw_ListAffectedUserIdentities.'
	Drop procedure [dbo].[ipw_ListAffectedUserIdentities]
	Print '**** Creating Stored Procedure dbo.ipw_ListAffectedUserIdentities...'
	Print ''
End
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

CREATE PROCEDURE dbo.ipw_ListAffectedUserIdentities
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@psNameKeysToCompare	nvarchar(1000) 	= null,		-- Is the comma separated list of NameKeys
	@pnAccessAccountKey	int	
)	
AS
-- PROCEDURE :	ipw_ListAffectedUserIdentities
-- VERSION :	1
-- DESCRIPTION:	Return all user identities that can be deleted as a result of deleting the list of names included in @psNameKeysToCompare from the Access Account identified by the @pnAccessAccountKey.


-- MODIFICATIONS :
-- Date		Who	Number	Version	Change
-- ------------	-------	------	-------	----------------------------------------------- 
-- 12-Aug-2009  Ash	RFC100012	1	Procedure created 


SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare	@nErrorCode				int

Declare @sSQLString				nvarchar(4000)
Set	@nErrorCode      = 0


If @nErrorCode = 0
Begin	
	Set @sSQLString = "
	select U.IDENTITYID as IdentityKey from USERIDENTITY U 	
    where U.NAMENO in (
		 select EMP.RELATEDNAME
		 from ASSOCIATEDNAME EMP
		 join ACCESSACCOUNTNAMES AAN on (AAN.NAMENO = EMP.NAMENO and AAN.ACCOUNTID = @pnAccessAccountKey)
		 join dbo.fn_Tokenise(@psNameKeysToCompare, ',') t 
			   on ( EMP.NAMENO = t.Parameter)
	     where EMP.RELATIONSHIP = 'EMP' )
    and U.ACCOUNTID= @pnAccessAccountKey
	and U.IDENTITYID  not in (
	      select UI.IDENTITYID
	      from USERIDENTITY UI
	      join ASSOCIATEDNAME EMP on (UI.NAMENO=EMP.RELATEDNAME)	
		  join ACCESSACCOUNTNAMES AAN on (AAN.NAMENO = EMP.NAMENO and AAN.ACCOUNTID = @pnAccessAccountKey)
	      where  EMP.RELATIONSHIP = 'EMP' 
			and UI.ACCOUNTID = @pnAccessAccountKey
			and AAN.NAMENO not in (Select t.Parameter from dbo.fn_Tokenise(@psNameKeysToCompare, ',') t))"

	exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnUserIdentityId 	int,
					  @psNameKeysToCompare	nvarchar(1000),
					  @pnAccessAccountKey	int',
					  @pnUserIdentityId	= @pnUserIdentityId,
					  @psNameKeysToCompare	= @psNameKeysToCompare,
					  @pnAccessAccountKey	= @pnAccessAccountKey

End

Return @nErrorCode
GO

Grant execute on dbo.ipw_ListAffectedUserIdentities to public
GO
