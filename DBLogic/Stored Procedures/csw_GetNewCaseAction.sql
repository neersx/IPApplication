-----------------------------------------------------------------------------------------------------------------------------
-- Creation of csw_GetNewCaseAction
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[csw_GetNewCaseAction]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.csw_GetNewCaseAction.'
	Drop procedure [dbo].[csw_GetNewCaseAction]
End
Print '**** Creating Stored Procedure dbo.csw_GetNewCaseAction...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.csw_GetNewCaseAction
(
	@psActionKey		nvarchar(2)	= null output,	-- The key of the action to be opened. Note: may be null in which case, no action should be opened.
	@pnScreenCriteriaKey int = null output, -- The new screen criteria key
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,		-- The language in which output is to be expressed.
	@pbCalledFromCentura	bit		= 0,
	@pnCaseKey		int,		-- Mandatory. 	The key of the new case.
	@psLogicalProgramId nvarchar(16) = null -- Logical program name to be used in determining the criteria
)
as
-- PROCEDURE:	csw_GetNewCaseAction
-- VERSION:	7
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Returns the key of the action to be opened for a new case.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 19 Dec 2005	TM	RFC3200	1	Procedure created
-- 11 Dec 2008	MF	17136	2	Improve performance on SiteControl table by removing use of UPPER in JOIN against CONTROLID
-- 21 Sep 2009  LP	RFC8047 3	Pass ProfileKey parameter to fn_GetCriteriaNo
-- 05 Jan 2010  KR	RFC8171 4	Get default action from the DEFAULTSETTINGS and not from SCREENCONTROL
-- 05 Mar 2010	SF	RFC6547 5	Get new Screen Criteria Key
-- 24 Mar 2010	SF	RFC6547	6	Cater for CRM Cases
-- 20 Jul 2017	MF	71968	7	When determining the default Case program, first consider the Profile of the User.

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare	@nErrorCode	int
Declare @sSQLString	nvarchar(4000)
Declare @nProfileKey    int
Declare @sLogicalProgramName nvarchar(16)

-- Note, as a temporary measure, this information is obtained from client/server screen control rules.  
-- Screen control rules are stored against a CRITERIA with purpose code of 'S' for a logical program.


-- Initialise variables
Set @nErrorCode = 0

-- Get the ProfileKey for the current user
If @nErrorCode = 0
Begin
        Select @nProfileKey = PROFILEID
        from USERIDENTITY
        where IDENTITYID = @pnUserIdentityId
        
        Set @nErrorCode = @@ERROR
End

-- Get the default Logical Program Name if one not supplied
If @nErrorCode = 0
Begin

	if @psLogicalProgramId is null
	Begin
		Select	@sLogicalProgramName = left(isnull(PA.ATTRIBUTEVALUE,SC.COLCHARACTER),8)
		From	SITECONTROL SC
		join	CASES C     on (C.CASEID   = @pnCaseKey)
		join	CASETYPE CS on (CS.CASETYPE=C.CASETYPE)
		left join PROFILEATTRIBUTES PA  on (PA.PROFILEID=@nProfileKey
						and PA.ATTRIBUTEID=2)	-- Default Cases Program
		where	SC.CONTROLID = CASE WHEN CS.CRMONLY = 1 THEN 'CRM Screen Control Program' ELSE 'Case Screen Default Program' END
	End
	Else Begin
		Set @sLogicalProgramName = @psLogicalProgramId
	End
End

If @nErrorCode = 0
Begin
	print @sLogicalProgramName
	Select @pnScreenCriteriaKey = dbo.fn_GetCriteriaNo(@pnCaseKey,
							  'W', -- (WorkBench screen control)
							  @sLogicalProgramName,
							  getdate(),
							  @nProfileKey)
End

If @nErrorCode = 0
Begin
	Set @sSQLString = "	
	Select 
		@psActionKey = FILTERVALUE
	from TOPICDEFAULTSETTINGS S
	where S.TOPICNAME = N'Actions_Component'
	and	  S.FILTERNAME = N'NewCaseAction'
	and   S.CRITERIANO = @pnScreenCriteriaKey"

	exec @nErrorCode = sp_executesql @sSQLString,
				N'@psActionKey	nvarchar(2)	OUTPUT,
				  @pnScreenCriteriaKey int',
				  @psActionKey	= @psActionKey	OUTPUT,
				  @pnScreenCriteriaKey = @pnScreenCriteriaKey
End

Return @nErrorCode
GO

Grant execute on dbo.csw_GetNewCaseAction to public
GO
