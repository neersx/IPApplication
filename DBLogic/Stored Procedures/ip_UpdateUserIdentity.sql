-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ip_UpdateUserIdentity
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ip_UpdateUserIdentity]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ip_UpdateUserIdentity.'
	Drop procedure [dbo].[ip_UpdateUserIdentity]
	Print '**** Creating Stored Procedure dbo.ip_UpdateUserIdentity...'
	Print ''
End
GO

SET QUOTED_IDENTIFIER OFF
GO

CREATE PROCEDURE dbo.ip_UpdateUserIdentity
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@psIdentityKey		nvarchar(11)	= null,
	@psLoginID		nvarchar(50)	= null,
	@pnPassword		binary(16)	= null,
	@psIdentityNameKey	nvarchar(11)	= null,
	@psDisplayName		nvarchar(255)	= null, -- not used in this proc
	@psNameCode		nvarchar(10)	= null, -- not used in this proc
	@pbIsExternalUser	bit		= 0,

	@pbLoginIDModified		bit	= null,
	@pbPasswordModified		bit	= null,
	@pbIdentityNameKeyModified	bit	= null,
	@pbDisplayNameModified		bit	= null, -- not used in this proc
	@pbNameCodeModified		bit	= null, -- not used in this proc
	@pbIsExternalUserModified	bit	= null	
)
-- PROCEDURE:	ip_UpdateUserIdentity
-- VERSION :	12
-- DESCRIPTION:	Alter User Login, Password, NameNo and IsExternalUser flag via this stored procedure.
--		Only Administrator User can perform this operation.

-- MODIFICATIONS :
-- Date		Who	Number	Version	Change
-- ------------	-------	------	-------	----------------------------------------------- 
-- 17-OCT-2002  SF		1	Procedure created
-- 30-OCT-2002	SF		2	Change the way error is raised.
-- 04 Nov 2002	JB		3	Password is now binary
--					Checking that the LoginID has not been used
-- 12 Nov 2002	JG		4	Remove the RAISERROR(300013...) if the user already exists because it's an update
-- 06 Dec 2002	JB		7	Replaced @psLoginID with @psLoginId
-- 03 Mar 2003	SF	RFC072	8	Replaced @psLoginId with @psLoginID -- this is what is defined in the DataSet doc.
-- 10 Mar 2003	JEK	RFC082	9	Localise stored procedure errors.
-- 24 Feb 2004	TM	RFC709	10	Increase the datasize of the @psLoginID parameter from nvarchar(20) to nvarchar(50). 
-- 03 Mar 2004	TM	RFC1003	11	Implement validation to ensure that password is present. Mark Inprostart user 
--					complete.
-- 15 Apr 2013	DV	R13270	12	Increase the length of nvarchar to 11 when casting or declaring integer

as

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare @nErrorCode 		int

Declare @sAlertXML 		nvarchar(400)
Declare @sSQLString		nvarchar(4000)
Declare @bIsPasswordExists	bit		-- Set to 1 if there is a password for the user on the database.

Set @nErrorCode = 0

-- Is there a password for the user on the database?
If @nErrorCode = 0 and ((Select ISADMINISTRATOR from USERIDENTITY where IDENTITYID = @pnUserIdentityId)=0)
Begin
	Set @sAlertXML = dbo.fn_GetAlertXML('IP5', 'Only users with system administration privileges may perform this task.',
		null, null, null, null, null)
	RAISERROR(@sAlertXML, 14, 1)
	Set @nErrorCode = @@ERROR
End	

-- If the password has not changed, ensure that there is a password for the user on the database.
If @nErrorCode = 0
and (@pbPasswordModified = 0 
 or  @pbPasswordModified is null)
Begin
	Set @sSQLString = "
	Set @bIsPasswordExists = CASE WHEN exists(Select * 
						  from USERIDENTITY 
						  where IDENTITYID = cast(@psIdentityKey as int)
						  and PASSWORD is not null)
				      THEN 1
				      ELSE 0
				 END"

	exec @nErrorCode = sp_executesql @sSQLString,
				N'@psIdentityKey	nvarchar(11),
				  @bIsPasswordExists    bit			OUTPUT',
				  @psIdentityKey	= @psIdentityKey,
				  @bIsPasswordExists    = @bIsPasswordExists	OUTPUT

End
-- If the password was changed then set @bIsPasswordExists to 1   
Else if @nErrorCode = 0
Begin
	Set @bIsPasswordExists = 1 
End

-- Produce a user error if the password is not present.  
If  @nErrorCode = 0
and ( (@pbPasswordModified = 1 and @pnPassword is null) 
 or    @bIsPasswordExists = 0 ) 
Begin
	Set @sAlertXML = dbo.fn_GetAlertXML('IP1', 'Password is mandatory but is not provided.',
		null, null, null, null, null)
	RAISERROR(@sAlertXML, 14, 1)
	Set @nErrorCode = @@ERROR
End 

If @nErrorCode = 0
and   (	@pbLoginIDModified is not null
or  	@pbPasswordModified is not null
or 	@pbIdentityNameKeyModified is not null
or 	@pbIsExternalUserModified is not null)
Begin
	Update 	USERIDENTITY 
	Set 	LOGINID 	  = case when (@pbLoginIDModified=1) 		then @psLoginID else LOGINID end,
		[PASSWORD] 	  = case when (@pbPasswordModified=1) 		then @pnPassword else [PASSWORD] end,
		NAMENO 		  = case when (@pbIdentityNameKeyModified=1) 	then Cast(@psIdentityNameKey as int) else NAMENO end,
		ISEXTERNALUSER 	  = case when (@pbIsExternalUserModified=1) 	then @pbIsExternalUser else ISEXTERNALUSER end,
		ISVALIDINPROSTART = 1 
	where	IDENTITYID	= Cast(@psIdentityKey as int)

	Set @nErrorCode = @@ERROR
End

Return @nErrorCode
GO

Grant execute on dbo.ip_UpdateUserIdentity to public
GO
