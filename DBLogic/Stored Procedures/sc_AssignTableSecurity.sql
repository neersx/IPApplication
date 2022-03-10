-----------------------------------------------------------------------------------------------------------------------------
-- Creation of sc_AssignTableSecurity
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[sc_AssignTableSecurity]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.sc_AssignTableSecurity.'
	Drop procedure [dbo].[sc_AssignTableSecurity]
End
Print '**** Creating Stored Procedure dbo.sc_AssignTableSecurity...' 
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO


CREATE PROCEDURE dbo.sc_AssignTableSecurity
(
	@psTableName		nvarchar(30)	-- Mandatory
)
as
-- PROCEDURE:	sc_AssignTableSecurity
-- VERSION:	4
-- DESCRIPTION:	Table is associated with al

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 20 Mar 2009	MF	17509	1	Procedure created
-- 26 Mar 2009	MF	17509	2	Check that Users being assigned exist in sysusers table
-- 27 Mar 2009	MF	17509	3	Add square brackets arounnd table name and user to ensure embedded
--					spaces do not cause a problem.
-- 02 Jul 2009	MF	17845	4	Handle the situation where the users rights are directly assigned to the
--					security profile rather than by going via Security Group.

SET NOCOUNT ON
SET ANSI_WARNINGS OFF

Declare	@nErrorCode		int
Declare @nTranCountStart 	int
Declare @nRowCount		int
Declare @sSQLString		nvarchar(4000)
Declare @sUserId		nvarchar(30)
Declare @sAlertXML		nvarchar(400)

-- Initialise variables
Set @nErrorCode = 0
Set @nRowCount  = 0

-- Validate that the Table exists
If @nErrorCode =0
and not exists (select 1 from INFORMATION_SCHEMA.TABLES
		where TABLE_NAME=@psTableName)
Begin
	Set @sAlertXML = dbo.fn_GetAlertXML('SC01', 'The table name provided in parameter @psTableName does not exist in this database.',
					null, null, null, null, null)
	RAISERROR(@sAlertXML, 14, 1)
	Set @nErrorCode = @@ERROR
End


-- Start a transaction
Set @nTranCountStart = @@TranCount
BEGIN TRANSACTION

If @nErrorCode = 0
Begin
	------------------------------------------------------------------
	-- Any existing security profiles for the Table are to be updated
	-- to indicate that full security access is to be granted.
	------------------------------------------------------------------
	Update S
	Set SECURITYFLAG=15
	from SECURITYTEMPLATE S
	join GROUPPROFILES GP	on (GP.PROFILE=S.PROFILE)
	join ASSIGNEDUSERS AU	on (AU.SECURITYGROUP=GP.SECURITYGROUP)
	Where S.NAMEOFTABLE=upper(@psTableName)
	and isnull(S.SECURITYFLAG,0)<>15
	
	Set @nErrorCode=@@Error
End

If @nErrorCode = 0
Begin
	------------------------------------------------------------------
	-- User is directly assigned to the Security Profile.
	-- Any existing security profiles for the Table are to be updated
	-- to indicate that full security access is to be granted.
	------------------------------------------------------------------
	Update S
	Set SECURITYFLAG=15
	from SECURITYTEMPLATE S
	join USERPROFILES US	on (US.PROFILE=S.PROFILE)
	Where S.NAMEOFTABLE=upper(@psTableName)
	and isnull(S.SECURITYFLAG,0)<>15
	
	Set @nErrorCode=@@Error
End

If @nErrorCode = 0
Begin
	------------------------------------------------------------------
	-- Add new table to each PROFILE (SECURITYTEMPLATE) that has other
	-- tables already against it and the PROFILE is associated with 
	-- at least one SECURITYGROUP that has ASSIGNEDUSERS
	-- SecurityFlag is set to 15 for full rights.
	------------------------------------------------------------------
	Insert into SECURITYTEMPLATE(NAMEOFTABLE, PROFILE, SECURITYFLAG)
	select distinct @psTableName, S.PROFILE , 15
	from SECURITYTEMPLATE S
	join GROUPPROFILES GP	on (GP.PROFILE=S.PROFILE)
	join ASSIGNEDUSERS AU	on (AU.SECURITYGROUP=GP.SECURITYGROUP)
	left join SECURITYTEMPLATE S1
				on (S1.NAMEOFTABLE=upper(@psTableName)
				and S1.PROFILE=S.PROFILE)
	Where S1.NAMEOFTABLE is null
	
	Set @nErrorCode=@@Error
End

If @nErrorCode = 0
Begin
	------------------------------------------------------------------
	-- Add new table to each PROFILE (SECURITYTEMPLATE) that has other
	-- tables already against it and the PROFILE is associated with 
	-- at least one SECURITYGROUP that has ASSIGNEDUSERS
	-- SecurityFlag is set to 15 for full rights.
	------------------------------------------------------------------
	Insert into SECURITYTEMPLATE(NAMEOFTABLE, PROFILE, SECURITYFLAG)
	select distinct @psTableName, S.PROFILE , 15
	from SECURITYTEMPLATE S
	join USERPROFILES US	on (US.PROFILE=S.PROFILE)
	left join SECURITYTEMPLATE S1
				on (S1.NAMEOFTABLE=upper(@psTableName)
				and S1.PROFILE=S.PROFILE)
	Where S1.NAMEOFTABLE is null
	
	Set @nErrorCode=@@Error
End

If @nErrorCode = 0
Begin
	--------------------------------------------------------
	-- Get the first USERID that now has access to the table
	--------------------------------------------------------
	select @sUserId=min(AU.USERID)
	from SECURITYTEMPLATE S
	join GROUPPROFILES GP	on (GP.PROFILE=S.PROFILE)
	join ASSIGNEDUSERS AU	on (AU.SECURITYGROUP=GP.SECURITYGROUP)
	join sysusers SU	on (SU.name=AU.USERID)
	where S.NAMEOFTABLE=@psTableName
	
	Set @nErrorCode=@@Error
End

While @sUserId is not null
and @nErrorCode=0
Begin
	--------------------------------------------------------
	-- Loop through each User and grant full rights
	--------------------------------------------------------
	Set @sSQLString="
	GRANT  SELECT, DELETE, INSERT, UPDATE  ON ["+@psTableName+"] TO ["+@sUserId+"]"
	
	Exec @nErrorCode=sp_executesql @sSQLString
	Set @nRowCount=@nRowCount+1

	If @nErrorCode=0
	Begin
		--------------------------------------------------------
		-- Get the next USERID that now has access to the table
		--------------------------------------------------------
		select @sUserId=min(AU.USERID)
		from SECURITYTEMPLATE S
		join GROUPPROFILES GP	on (GP.PROFILE=S.PROFILE)
		join ASSIGNEDUSERS AU	on (AU.SECURITYGROUP=GP.SECURITYGROUP)
		join sysusers SU	on (SU.name=AU.USERID)
		where S.NAMEOFTABLE=@psTableName
		and AU.USERID>@sUserId
		
		Set @nErrorCode=@@Error
	End
End

------------------------------------------
-- Now process any Users that are directly
-- associated with the Security Template
------------------------------------------
If @nErrorCode = 0
Begin
	--------------------------------------------------------
	-- Get the first USERID that now has access to the table
	--------------------------------------------------------
	select @sUserId=min(US.USERID)
	from SECURITYTEMPLATE S
	join USERPROFILES US	on (US.PROFILE=S.PROFILE)
	join sysusers SU	on (SU.name=US.USERID)
	where S.NAMEOFTABLE=@psTableName
	
	Set @nErrorCode=@@Error
End

While @sUserId is not null
and @nErrorCode=0
Begin
	--------------------------------------------------------
	-- Loop through each User and grant full rights
	--------------------------------------------------------
	Set @sSQLString="
	GRANT  SELECT, DELETE, INSERT, UPDATE  ON ["+@psTableName+"] TO ["+@sUserId+"]"
	
	Exec @nErrorCode=sp_executesql @sSQLString
	Set @nRowCount=@nRowCount+1

	If @nErrorCode=0
	Begin
		--------------------------------------------------------
		-- Get the next USERID that now has access to the table
		--------------------------------------------------------
		select @sUserId=min(US.USERID)
		from SECURITYTEMPLATE S
		join USERPROFILES US	on (US.PROFILE=S.PROFILE)
		join sysusers SU	on (SU.name=US.USERID)
		where S.NAMEOFTABLE=@psTableName
		and US.USERID>@sUserId
		
		Set @nErrorCode=@@Error
	End
End

If @nErrorCode=0
Begin
	If @nRowCount>0
	Begin
		---------------------------------------------
		-- If User level security has been granted 
		-- then revoke the table security from PUBLIC
		---------------------------------------------
		Set @sSQLString="
		REVOKE SELECT, DELETE, INSERT, UPDATE  ON ["+@psTableName+"] FROM PUBLIC"
	End
	Else Begin
		---------------------------------------------
		-- If no User level security has been granted 
		-- then grant security to PUBLIC
		---------------------------------------------
		Set @sSQLString="
		GRANT SELECT, DELETE, INSERT, UPDATE  ON ["+@psTableName+"] TO PUBLIC"
	End
End

-- Commit or Rollback the transaction

If @@TranCount > @nTranCountStart
Begin
	If @nErrorCode = 0
		COMMIT TRANSACTION
	Else
		ROLLBACK TRANSACTION
End

Return @nErrorCode
GO

Grant execute on dbo.sc_AssignTableSecurity to public
GO