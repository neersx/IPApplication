-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ipw_GetScreenCriteriaNo
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ipw_GetScreenCriteriaNo]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ipw_GetScreenCriteriaNo.'
	Drop procedure [dbo].[ipw_GetScreenCriteriaNo]
End
Print '**** Creating Stored Procedure dbo.ipw_GetScreenCriteriaNo...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
-- Allow comparison of null values.
-- Procedure uses setting in place before it's created. 
SET ANSI_NULLS OFF
GO


CREATE PROCEDURE dbo.ipw_GetScreenCriteriaNo
(
	@pnScreenCriterionKey	int		= null output,	-- just an example
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@psProgramKey		nvarchar(8)	= null,
	@pnCaseKey		int		= null,
	@pnNameKey		int		= null,
	@pbCalledFromCentura	bit		= 0
)
as
-- PROCEDURE:	ipw_GetScreenCriteriaNo
-- VERSION:	1
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Return applicable screen criteria no for the Web version (Purpose Code='W')
--		ProgramName is defaulted based on user profile if not provided.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 19 OCT 2011	SF	R11378	1	Procedure created

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF
-- Reset so that next procedure gets the default. 
SET ANSI_NULLS ON

Declare	@nErrorCode	int
Declare @sSQLString	nvarchar(4000)
Declare @nProfileKey	int
Declare @nAttributeId	int		-- The identifier for the profile attribute
Declare @sSiteControl	nvarchar(120)	-- The name of the site control related to screen control
Declare @bIsCRMOnly	bit

-- Initialise variables
Set @nErrorCode = 0
If @nErrorCode = 0
Begin
	Select @nProfileKey = PROFILEID
        from USERIDENTITY
        where IDENTITYID = @pnUserIdentityId
End

If @nErrorCode = 0
and @pnCaseKey is not null
Begin
	-- Get the default program for the Case if not specified via input param
	If @nErrorCode = 0 and (@psProgramKey is null)
	Begin
		If @nErrorCode = 0 and @nProfileKey is not null
		Begin
			Select @psProgramKey = P.ATTRIBUTEVALUE
			from PROFILEATTRIBUTES P
			where P.PROFILEID = @nProfileKey
			and P.ATTRIBUTEID = 2 -- Default Case Program
			Set @nErrorCode = @@ERROR
		End
		
		If @nErrorCode = 0 and (@psProgramKey is null)
		Begin 
			Select @psProgramKey = SC.COLCHARACTER
			from SITECONTROL SC
			where SC.CONTROLID = 'Case Screen Default Program'
			Set @nErrorCode = @@ERROR
		End
	End

	Set @sSQLString = 
	"Select
		@pnScreenCriterionKey = dbo.fn_GetCriteriaNo(@pnCaseKey, 'W', 
			case 
				when CS.CRMONLY=1 
					then SCRM.COLCHARACTER 
					else isnull(@psProgramKey, SC.COLCHARACTER) 
				end, 
			null, @nProfileKey)
	from CASES C
	join CASETYPE CS on (CS.CASETYPE=C.CASETYPE)
	join SITECONTROL SC on (SC.CONTROLID = 'Case Screen Default Program')
	join SITECONTROL SCRM on (SCRM.CONTROLID = 'CRM Screen Control Program')
	Where C.CASEID = @pnCaseKey"

	exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnCaseKey		 	int,
					  @psProgramKey			nvarchar(8),	
					  @nProfileKey			int,
					  @pnScreenCriterionKey		int			OUTPUT',
					  @pnCaseKey		 	= @pnCaseKey,
					  @psProgramKey			= @psProgramKey,
					  @nProfileKey			= @nProfileKey,
					  @pnScreenCriterionKey		= @pnScreenCriterionKey		OUTPUT
End

If @nErrorCode = 0
and @pnNameKey is not null
Begin
	-- Get the Default Name Program for the profile
	-- Set the Default Program if not specified via input parameters
	If @nErrorCode = 0 
	AND (@psProgramKey is null)
	Begin
		-- No non-crm name types selected
		If not exists (SELECT 1 from NAME XN
					left join NAMETYPECLASSIFICATION NTC on (NTC.NAMENO=XN.NAMENO
										and NTC.NAMETYPE <> '~~~'
										and NTC.ALLOW=1)
					left join NAMETYPE NTP on (NTP.NAMETYPE=NTC.NAMETYPE and NTP.PICKLISTFLAGS&32<>32)
					where XN.NAMENO = @pnNameKey
					and NTP.NAMETYPE is not null)
		-- and at least 1 CRM Name type selected.
		and exists (SELECT 1 
					from NAME XN
					left join NAMETYPECLASSIFICATION NTC on (NTC.NAMENO=XN.NAMENO
										and NTC.NAMETYPE <> '~~~'
										and NTC.ALLOW=1)
					left join NAMETYPE NTP on (NTP.NAMETYPE=NTC.NAMETYPE and NTP.PICKLISTFLAGS&32=32)
					where XN.NAMENO = @pnNameKey
					and NTP.NAMETYPE is not null)
		Begin
			Set @bIsCRMOnly = 1
			Set @nAttributeId = 4
			Set @sSiteControl = 'CRM Name Screen Program'			
		End
		Else
		Begin
			Set @nAttributeId = 3
			Set @sSiteControl = 'Name Screen Default Program'		
		End
		
		If @nErrorCode = 0
		and @nProfileKey is not null
		Begin
			Select @psProgramKey = P.ATTRIBUTEVALUE
			from PROFILEATTRIBUTES P
			where P.PROFILEID = @nProfileKey
			and P.ATTRIBUTEID = @nAttributeId

			Set @nErrorCode = @@ERROR
		End
		
		If @nErrorCode = 0
		and (@psProgramKey is null)
		Begin 
			Select @psProgramKey = SC.COLCHARACTER
			from SITECONTROL SC
			where SC.CONTROLID = @sSiteControl
		
			Set @nErrorCode = @@ERROR
		End
	End
	
	If @nErrorCode = 0
	Begin
		Set @sSQLString = 
		"Select
			@pnScreenCriterionKey = dbo.fn_GetCriteriaNoForName(@pnNameKey, 'W', 
				case 
					when @bIsCRMOnly=1 
						then 'NAMECRM'
						else isnull(@psProgramKey, 'NAMENTRY') 
					end, 
				@nProfileKey)
		from NAME N
		Where N.NAMENO = @pnNameKey"

		exec @nErrorCode=sp_executesql @sSQLString,
						N'@pnNameKey		 	int,
						  @psProgramKey			nvarchar(8),	
						  @bIsCRMOnly			bit,
						  @nProfileKey			int,
						  @pnScreenCriterionKey		int			OUTPUT',
						  @pnNameKey		 	= @pnNameKey,
						  @psProgramKey			= @psProgramKey,
						  @bIsCRMOnly			= @bIsCRMOnly,
						  @nProfileKey			= @nProfileKey,
						  @pnScreenCriterionKey		= @pnScreenCriterionKey		OUTPUT
	End

End

If @nErrorCode=0
Begin
	Select @pnScreenCriterionKey as ScreenCriterionKey
End

Return @nErrorCode
GO

Grant execute on dbo.ipw_GetScreenCriteriaNo to public
GO
