-----------------------------------------------------------------------------------------------------------------------------
-- Creation of cs_VerifyUpdatedCase
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[cs_VerifyUpdatedCase]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.cs_VerifyUpdatedCase.'
	Drop procedure [dbo].[cs_VerifyUpdatedCase]
	Print '**** Creating Stored Procedure dbo.cs_VerifyUpdatedCase...'
	Print ''
End
go

SET QUOTED_IDENTIFIER off
go

CREATE procedure dbo.cs_VerifyUpdatedCase
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null, 
	@pnCaseKey		int		-- Mandatory
)

-- PROCEDURE :	cs_VerifyUpdatedCase
-- VERSION :	8
-- SCOPE:	CPA.net, InPro.net
-- DESCRIPTION:	Verify that the information for an updated case is valid.
--		Note: the case and all child tables must have been saved.
--		Raises errors for any invalid conditions.

-- MODIFICTIONS :
-- Date         Who  Version  	Change
-- ------------ ---- -------- 	------------------------------------------- 
-- 23 Oct 2002	JEK	1	Procedure created
-- 24 Oct 2002	JEK	2	Update with correct error numbers.
-- 25 Oct 2002	JB	3	Implemented row level security (cs_GetSecurityForCase)
-- 21 Feb 2003	SF	4	RFC09 Retrict Name Type against cases screen control
-- 10 Mar 2003	JEK	7	RFC82 Localise stored procedure errors.
-- 13-Jul-2011	DL	8	RFC10830 Specify collation default in temp table.

AS

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare	@nErrorCode		int
Declare	@nRowCount		int
Declare @tMissingNames 		table (	IDENT		int identity(1,1),
					[DESCRIPTION]	nvarchar(50) collate database_default )
Declare @sNamesSubstitution 	nvarchar(4000)
Declare @nCounter 		int
Declare @sNameDescription 	nvarchar(50)
Declare @nMaximumAllowed 	smallint
Declare @bHasUpdateRights	bit
Declare @sAlertXML 		nvarchar(400)

Set	@nErrorCode=0


-- Row level security
If @nErrorCode = 0
Begin
	Exec @nErrorCode = cs_GetSecurityForCase
		@pnUserIdentityId = @pnUserIdentityId,
		@psCulture = @psCulture,
		@pnCaseKey = @pnCaseKey,
		@pbCanUpdate = @bHasUpdateRights output

	If @nErrorCode = 0 and @bHasUpdateRights = 0
	Begin
		Set @sAlertXML = dbo.fn_GetAlertXML('CS3', 'User has insufficient security to update this case.',
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
		where	NOT EXISTS ( 	select	*
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
			RAISERROR(@sAlertXML, 12, 2, @sNamesSubstitution)
			Set @nErrorCode = @@ERROR
		End
	End
End

-- Maximum Name Type occurrences
If @nErrorCode=0
Begin
	Set @nMaximumAllowed = -1

	Select	top 1
		@sNamesSubstitution = N.DESCRIPTION, 
		@nMaximumAllowed = N.MAXIMUMALLOWED
	from	NAMETYPE N
	where	N.MAXIMUMALLOWED < ( 	select	count(*)
					from	CASENAME CN
					where	CN.CASEID = @pnCaseKey
					and	CN.NAMETYPE = N.NAMETYPE
					and  	(CN.EXPIRYDATE is null OR CN.EXPIRYDATE>getdate()) )
	and	N.MAXIMUMALLOWED is not NULL
	and	N.NAMETYPE in (	Select 	NameTypeKey 
				from 	dbo.fn_GetScreenControlNameTypes(@pnUserIdentityId, @pnCaseKey, default))
	order by N.DESCRIPTION

	Set @nErrorCode = @@ERROR

	If @nMaximumAllowed > -1 and @nErrorCode = 0
	Begin
		Set @sAlertXML = dbo.fn_GetAlertXML('CS7', 'There may only be {0} names defined for {1}.',
			'%d', '%s', null, null, null)
		RAISERROR(@sAlertXML, 12, 1, @nMaximumAllowed, @sNamesSubstitution)
		Set @nErrorCode = @@ERROR
	End

End

Return @nErrorCode
GO

Grant execute on dbo.cs_VerifyUpdatedCase to public
GO
