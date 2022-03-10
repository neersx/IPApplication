-----------------------------------------------------------------------------------------------------------------------------
-- Creation of cs_VerifyInsertedCase
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[cs_VerifyInsertedCase]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.cs_VerifyInsertedCase.'
	Drop procedure [dbo].[cs_VerifyInsertedCase]
	Print '**** Creating Stored Procedure dbo.cs_VerifyInsertedCase...'
	Print ''
End
go

SET QUOTED_IDENTIFIER off
go

CREATE procedure dbo.cs_VerifyInsertedCase
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null, 
	@pnCaseKey		int		-- Mandatory
)

-- PROCEDURE :	cs_VerifyInsertedCase
-- VERSION :	11
-- SCOPE:	CPA.net, InPro.net
-- DESCRIPTION:	Verify that the information for a new case is valid.
--		Note: the case and all child tables must have been saved.
--		Raises errors for any invalid conditions.

-- MODIFICTIONS :
-- Date         Who  Version  	Change
-- ------------ ---- -------- 	------------------------------------------- 
-- 23 Oct 2002	JEK	1	Procedure created
-- 23 Oct 2002	JEK	2	Only test unexpired names
-- 23 Oct 2002	JB	3	Implement row security
-- 24 Oct 2002	JEK	4	Update with correct error numbers
-- 25 Oct 2002	JB	5	Adjusted to use cs_GetSecurityForCase
-- 29 Oct 2002	JB	6	Bug: still had ref to fn_GetSecurityForCase
-- 21 Feb 2003	SF	7	RFC09 Restrict Nametypes against cases screen control.
-- 10 Mar 2003	JEK	10	RFC82 Localise stored procedure errors.
-- 13-Jul-2011	DL	11	RFC10830 Specify collation default in temp table.

AS

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare	@nErrorCode		int
Declare	@nRowCount		int
Declare @tMissingNames 		table (	IDENT		int identity(1,1),
					[DESCRIPTION]	nvarchar(50) COLLATE DATABASE_DEFAULT )
Declare @sNamesSubstitution 	nvarchar(4000)
Declare @nCounter 		int
Declare @sNameDescription 	nvarchar(50)
Declare	@bHasInsertRights	bit
Declare @sAlertXML 		nvarchar(400)
Set	@nErrorCode=0


-- -------------------
-- Row level security
If @nErrorCode = 0
Begin
	Exec @nErrorCode = cs_GetSecurityForCase
		@pnUserIdentityId = @pnUserIdentityId,
		@psCulture = @psCulture,
		@pnCaseKey = @pnCaseKey,
		@pbCanInsert = @bHasInsertRights output

	If @nErrorCode = 0 and @bHasInsertRights = 0
	Begin
		Set @sAlertXML = dbo.fn_GetAlertXML('CS2', 'User has insufficient security to create this case.',
			null, null, null, null, null)
		RAISERROR(@sAlertXML, 14, 1)
		Set @nErrorCode = @@ERROR
	End
End


-- Mandatory names
If @nErrorCode=0
Begin
	-- Populate a table variable with missing name types
	Insert into @tMissingNames (DESCRIPTION)
		select 	N.DESCRIPTION
		from	NAMETYPE N
		where	N.NAMETYPE IN ('I', 'O', 'EMP', 'J')
		and	NOT EXISTS ( 	select	*
					from	CASENAME CN
					where	CN.CASEID = @pnCaseKey
					and	CN.NAMETYPE = N.NAMETYPE
					and  	(CN.EXPIRYDATE is null OR CN.EXPIRYDATE>getdate()) )
		and	N.MANDATORYFLAG = 1	
		and	N.NAMETYPE in (	Select 	NameTypeKey 
					from 	dbo.fn_GetScreenControlNameTypes(@pnUserIdentityId, @pnCaseKey, default))


	-- Raise an error for all the names in the list
	Select @nRowCount = @@ROWCOUNT, @nErrorCode = @@ERROR

	If @nRowCount > 0 and @nErrorCode = 0
	Begin
		-- Concatenate into a comma separated list
		Set @nCounter = 1
		While @nCounter <= @nRowCount and @nErrorCode = 0
		Begin
			
			Select 	@sNameDescription = DESCRIPTION
				from @tMissingNames
				where IDENT = @nCounter

			Set @nErrorCode = @@ERROR

			If @nErrorCode=0
			Begin
				If @sNamesSubstitution is null
					Set @sNamesSubstitution=@sNameDescription
				Else
					Set @sNamesSubstitution=@sNamesSubstitution+', '+@sNameDescription

				Set @nCounter = @nCounter + 1
			End

		End

		If @nErrorCode=0
		Begin
			Set @sAlertXML = dbo.fn_GetAlertXML('CS6', 'A name must be supplied for {0}.',
				'%s', null, null, null, null)
			RAISERROR(@sAlertXML, 12, 1, @sNamesSubstitution)
			Set @nErrorCode = @@ERROR
		End
	End
End

Return @nErrorCode
GO

Grant execute on dbo.cs_VerifyInsertedCase to public
GO
