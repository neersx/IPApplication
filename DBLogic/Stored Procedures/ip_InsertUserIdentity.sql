SET QUOTED_IDENTIFIER OFF
GO

-----------------------------------------------------------------------------------------------------------------------------
-- Creation of Procedure
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ip_InsertUserIdentity]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ip_InsertUserIdentity.'
	Drop procedure [dbo].[ip_InsertUserIdentity]
End
Print '**** Creating Stored Procedure dbo.ip_InsertUserIdentity...'
Print ''
GO

CREATE PROCEDURE dbo.ip_InsertUserIdentity
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@psIdentityKey		nvarchar(11)	= null output,	-- new identity key
	@psLoginID		nvarchar(50),	-- Mandatory
	@pnPassword		binary(16),		-- Mandatory (Encrypted)
	@psIdentityNameKey	nvarchar(11)	= null,
	@psDisplayName		nvarchar(255)	= null, -- not used in this proc
	@psNameCode		nvarchar(10)	= null, -- not used in this proc
	@pbIsExternalUser	bit		= 0,
	@pbIsAdministrator	bit		= 0
)
-- PROCEDURE:	ip_InsertUserIdentity
-- VERSION:	10
-- DESCRIPTION:	Create a user.  
--		NOTE: Only an Administrator can perform this action.

-- MODIFICATIONS :
-- Date		Who	Number	Version	Change
-- ------------	-------	------	-------	----------------------------------------------- 
-- 16-OCT-2002  SF		1	Procedure created
-- 30-OCT-2002	SF		2	Change the way error is raised.
-- 04 Nov 2002	JB		3	Password now passed/stored binary
-- 					Added @pbIsAdministrator for future use
--					Checking that the LoginID has not been used
-- 01 Dec 2002	SF		4	Raise error when password is not provided.
-- 10 Mar 2003	JEK	RFC82	5	Localise stored procedure errors.
-- 24 Feb 2004	TM	RFC709	6	Increase the datasize of the @psLoginID parameter from nvarchar(20) 
--					to nvarchar(50). 
-- 03 Mar 2004	TM	RFC1003	7	Mark Inprostart user complete, and WorkBench user incomplete.
-- 15 Sep 2004	TM	RFC1822	8	Use IDENT_CURRENT('table_name') instead of the @@IDENTITY to publish the key.
-- 17 Sep 2004 	TM	RFC886	9	Implement SCOPE_IDENTITY() IDENT_CURRENT.
-- 15 Apr 2013	DV	R13270	10	Increase the length of nvarchar to 11 when casting or declaring integer

as

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare @nErrorCode int
Declare @nNewIdentityKey int
Declare @sAlertXML nvarchar(400)
Set @nErrorCode = 0

If @nErrorCode = 0 and ((Select ISADMINISTRATOR from USERIDENTITY where IDENTITYID = @pnUserIdentityId)=0)
Begin
	Set @sAlertXML = dbo.fn_GetAlertXML('IP5', 'Only users with system administration privileges may perform this task.',
		null, null, null, null, null)
	RAISERROR(@sAlertXML, 14, 1)
	Set @nErrorCode = @@ERROR
End	

If @nErrorCode = 0 and exists(Select * from USERIDENTITY where upper(@psLoginID) = upper(LOGINID))
Begin
	Set @sAlertXML = dbo.fn_GetAlertXML('IP6', 'Login Id {0} is already in use.',
		'%s', null, null, null, null)
	RAISERROR(@sAlertXML, 12, 1, @psLoginID)
	Set @nErrorCode = @@ERROR
End

If @nErrorCode = 0 and @pnPassword is null
Begin
	Set @sAlertXML = dbo.fn_GetAlertXML('IP1', 'Password is mandatory but is not provided.',
		null, null, null, null, null)
	RAISERROR(@sAlertXML, 12, 1)
	Set @nErrorCode = @@ERROR
End

If @nErrorCode = 0
Begin
	Insert into USERIDENTITY (
		LOGINID,
		[PASSWORD],
		NAMENO,
		ISEXTERNALUSER,
		ISADMINISTRATOR,
		ISVALIDINPROSTART,
		ISVALIDWORKBENCH ) 
	values (
		@psLoginID,
		@pnPassword,
		Cast(@psIdentityNameKey as int), 
		@pbIsExternalUser,
		@pbIsAdministrator,
		1,
		0 ) 	

	Select  @nErrorCode = @@ERROR, 	
		@nNewIdentityKey = SCOPE_IDENTITY()

	Set @psIdentityKey = Cast(@nNewIdentityKey as nvarchar(11))
End
Return @nErrorCode
GO

Grant execute on dbo.ip_InsertUserIdentity to public
GO

