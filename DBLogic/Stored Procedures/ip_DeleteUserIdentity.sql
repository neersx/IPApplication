-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ip_DeleteUserIdentity
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ip_DeleteUserIdentity]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ip_DeleteUserIdentity.'
	Drop procedure [dbo].[ip_DeleteUserIdentity]
	Print '**** Creating Stored Procedure dbo.ip_DeleteUserIdentity...'
	Print ''
End
GO

SET QUOTED_IDENTIFIER OFF
GO

CREATE PROCEDURE dbo.ip_DeleteUserIdentity
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@psIdentityKey		nvarchar(11)	= null,	-- identity key to be deleted.
	@psLoginID		nvarchar(50)	= null,
	@pnPassword		binary(16)	= null, -- not used in this proc
	@psIdentityNameKey	nvarchar(10)	= null, -- not used in this proc
	@psDisplayName		nvarchar(255)	= null, -- not used in this proc
	@psNameCode		nvarchar(10)	= null, -- not used in this proc
	@pbIsExternalUser	bit		= 0	-- not used in this proc
)
-- PROCEDURE:	ip_DeleteUserIdentity
-- VERSION:	8
-- DESCRIPTION:	Delete a User Login via this stored procedure.
--		Only Administrator User can perform this operation.

-- MODIFICATIONS :
-- Date		Who	Number	Version	Change
-- ------------	-------	------	-------	----------------------------------------------- 
-- 17-OCT-2002  SF		1	Procedure created
-- 30-OCT-2002	SF		2	Change the way error is raised.
-- 12-NOV-2002	JB		4	Now passing @pnPassword not @psPassword
-- 03-MAR-2004	TM	RFC1003	6	Produce validation error if attempt is made to delete IsAdministrator = 1 user.	
-- 16-MAR-2004	TM	RFC709	7	Increase the datasize of the parameter @psLoginID from nvarchar(20) to 
--					nvarchar(50).
-- 15 Apr 2013	DV	R13270	8	Increase the length of nvarchar to 11 when casting or declaring integer
as

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare @nErrorCode 			int

Declare @sAlertXML 			nvarchar(400)
declare @sSQLString 			nvarchar(4000)
Declare @bIsCPAInprostartAdministrator	bit

Set @nErrorCode = 0

If ((Select ISADMINISTRATOR from USERIDENTITY where IDENTITYID = @pnUserIdentityId)=0)
Begin
	Set @sAlertXML = dbo.fn_GetAlertXML('IP5', 'Only users with system administration privileges may perform this task.',
		null, null, null, null, null)
	RAISERROR(@sAlertXML, 14, 1)
	Set @nErrorCode = @@ERROR
End	

-- Is the user to be deleted is Special Administrator user for CPA Inprostart?
If @nErrorCode = 0 
Begin
	Set @sSQLString = " 
	Select @bIsCPAInprostartAdministrator = ISADMINISTRATOR
 	from USERIDENTITY 		
	where IDENTITYID = cast(@psIdentityKey as int)"
	
	exec @nErrorCode=sp_executesql @sSQLString,
					N'@psIdentityKey		 nvarchar(11),		
					  @bIsCPAInprostartAdministrator bit				  OUTPUT',				
					  @psIdentityKey		 = @psIdentityKey,
					  @bIsCPAInprostartAdministrator = @bIsCPAInprostartAdministrator OUTPUT					  
End

If @nErrorCode = 0 
and @bIsCPAInprostartAdministrator = 1 
Begin
	Set @sAlertXML = dbo.fn_GetAlertXML('IP15', 'The administrator user cannot be deleted.',
		null, null, null, null, null)
	RAISERROR(@sAlertXML, 14, 1)
	Set @nErrorCode = @@ERROR
End

If @nErrorCode = 0
Begin
	Delete 
	from	USERIDENTITY 
	where	IDENTITYID	= Cast(@psIdentityKey as int)

	Set @nErrorCode = @@Error
End
	

Return @nErrorCode
GO

Grant execute on dbo.ip_DeleteUserIdentity to public
GO
