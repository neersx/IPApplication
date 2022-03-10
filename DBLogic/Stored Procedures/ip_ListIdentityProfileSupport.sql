-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ip_ListIdentityProfileSupport
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ip_ListIdentityProfileSupport]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ip_ListIdentityProfileSupport.'
	Drop procedure [dbo].[ip_ListIdentityProfileSupport]
	Print '**** Creating Stored Procedure dbo.ip_ListIdentityProfileSupport...'
	Print ''
End
GO

SET QUOTED_IDENTIFIER OFF
GO

CREATE PROCEDURE dbo.ip_ListIdentityProfileSupport
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@psTables		nvarchar(2000) = null
)
-- PROCEDURE:	ip_ListIdentityProfileSupport
-- VERSION :	3
-- DESCRIPTION:	provide the RowAccessProfile support table

-- MODIFICATIONS :
-- Date		Who	Version	Change
-- ------------	-------	-------	----------------------------------------------- 
-- 17-OCT-2002  SF	1	Procedure created

as

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

-- declare variables
Declare	@nErrorCode		int
Declare @nRow			smallint
Declare @nUserIdentityId	int
Declare @sCulture		nvarchar(10)
Declare	@sProc			nvarchar(254)
	
-- initialise variables
Set @nUserIdentityId=@pnUserIdentityId
Set @sCulture=@psCulture
Set @nRow=1

While @nRow is not null
Begin
	Select 	@sProc=
		Case Parameter
			When 'RowAccessProfile'	then 'ipn_ListRowAccessProfiles'
		Else NULL
		End
	from fn_Tokenise (@psTables, NULL)
	where InsertOrder=@nRow

	--If @sProc is not null
	If (@@ROWCOUNT > 0)
	Begin
		If @sProc is not null
		Begin
			Exec  @sProc @pnUserIdentityId=@nUserIdentityId, 
					@psCulture=@sCulture
		End
		Set @nRow=@nRow+1
	End
	Else Begin
		Set @nRow=null
	End

End
Select @nErrorCode=@@Error

Return @nErrorCode
GO

Grant execute on dbo.ip_ListIdentityProfileSupport to public
GO
