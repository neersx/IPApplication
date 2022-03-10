-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ipw_GetActivityTemplate
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ipw_GetActivityTemplate]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ipw_GetActivityTemplate.'
	Drop procedure [dbo].[ipw_GetActivityTemplate]
End
Print '**** Creating Stored Procedure dbo.ipw_GetActivityTemplate...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[ipw_GetActivityTemplate]
(	
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pbCalledFromCentura	bit		= 0,
	@psActivityTemplateCode	nvarchar(20)	-- Mandatory
)
as
-- PROCEDURE:	ipw_GetActivityTemplate
-- VERSION:	4
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Populates the ActivityTemplate dataset.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 25 Sep 2014	DV	R26412	 1	Procedure created 
-- 13 Oct 2014  SW      R26412   2      Returned RowKey in dataset
-- 02 Nov 2015	vql	R53910	 3	Adjust formatted names logic (DR-15543).
-- 23 Mar 2020	BS	DR-57435 4	DB public role missing execute permission on some stored procedures and functions

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare	@nErrorCode	int
Declare @sLookupCulture	nvarchar(10)
Declare @sSQLString	nvarchar(4000)
Declare @bIsExternalUser	bit
Declare @nAccessAccountId	int

-- Initialise variables
Set @nErrorCode = 0
Set @sLookupCulture = dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)

-- Determine if the user is internal or external
If @nErrorCode=0
Begin		
	Set @sSQLString=
	"Select	@bIsExternalUser=ISEXTERNALUSER,
	@nAccessAccountId=ACCOUNTID
	from USERIDENTITY
	where IDENTITYID=@pnUserIdentityId"

	Exec  @nErrorCode=sp_executesql @sSQLString,
				N'@bIsExternalUser	bit		  OUTPUT,
				  @nAccessAccountId 	int		  OUTPUT,
				  @pnUserIdentityId	int',
				  @bIsExternalUser	=@bIsExternalUser OUTPUT,
				  @nAccessAccountId	=@nAccessAccountId  OUTPUT,
				  @pnUserIdentityId	=@pnUserIdentityId
End

If @nErrorCode = 0
Begin
	Set @sSQLString = "Select
		A.ACTIVITYTEMPLATECODE					as ActivityTemplateCode,
		A.NAMENO						as ContactKey,
		N.NAMECODE						as ContactCode,
		dbo.fn_FormatNameUsingNameNo(N.NAMENO, NULL)
									as ContactName,
		"+dbo.fn_SqlTranslatedColumn('DEBTORSTATUS','DEBTORSTATUS',null,'DS',@sLookupCulture,@pbCalledFromCentura)
			     +" as 'ContactRestriction',		 
		DS.ACTIONFLAG	as 'ContactRestrictionActionKey',							
		A.RELATEDNAME						as RegardingKey,
		NR.NAMECODE						as RegardingCode,
		dbo.fn_FormatNameUsingNameNo(NR.NAMENO, NULL)
									as RegardingName,
		"+dbo.fn_SqlTranslatedColumn('DEBTORSTATUS','DEBTORSTATUS',null,'DS4',@sLookupCulture,@pbCalledFromCentura)
			    + " as 'RegardingRestriction',		 
		DS4.ACTIONFLAG as 'RegardingRestrictionActionKey',							
		A.CASEID						as CaseKey,
		C.IRN							as CaseReference,
		A.REFERREDTO						as ReferredToKey,
		NRT.NAMECODE						as ReferredToCode,
		dbo.fn_FormatNameUsingNameNo(NRT.NAMENO, NULL)
									as ReferredToName,
		A.INCOMPLETE						as IsIncomplete,
		A.SUMMARY						as Summary,
		A.CALLSTATUS						as CallStatusCode,
		A.ACTIVITYCATEGORY					as ActivityCategoryKey,			
		"+dbo.fn_SqlTranslatedColumn('TABLECODES','DESCRIPTION',null,'TCC',@sLookupCulture,@pbCalledFromCentura)	
					 +" as ActivityCategory,	
		A.REFERENCENO						as ReferenceNo,
		A.CLIENTREFERENCE					as ClientReference,
		ISNULL(A.CREATEADHOCDATE,0)				as IsCreateAdHocDate,			 
		A.NOTES							as Notes,
		A.LOGDATETIMESTAMP					as ActivityLastModifiedDate,
		A.ACTIVITYTEMPLATECODE					as RowKey		
		from ACTIVITYTEMPLATE A
		-- Contact data				
		left join NAME N			on (A.NAMENO = N.NAMENO)
		left join IPNAME IP		        on (IP.NAMENO = N.NAMENO)
	        left join DEBTORSTATUS DS	        on (DS.BADDEBTOR = IP.BADDEBTOR)
	        -- Regarding data
		left join NAME NR			on (A.RELATEDNAME = NR.NAMENO)
		left join IPNAME IP4		        on (IP4.NAMENO = NR.NAMENO)
	        left join DEBTORSTATUS DS4	        on (DS4.BADDEBTOR = IP4.BADDEBTOR)
		left join NAME NRT			on (A.REFERREDTO = NRT.NAMENO)
		left join CASES C			on (A.CASEID = C.CASEID)	
		left join TABLECODES TCC	on (TCC.TABLECODE = A.ACTIVITYCATEGORY)		
		where A.ACTIVITYTEMPLATECODE = @psActivityTemplateCode
		and A.ISEXTERNAL = @bIsExternalUser"
		
		if(@bIsExternalUser=1)
		Begin
			Set @sSQLString = @sSQLString +CHAR(10)+"and A.ACCESSACCOUNTID =@nAccessAccountId" 
		End
		
		exec @nErrorCode=sp_executesql @sSQLString,
				N'
				@pnUserIdentityId	int,
				@pbCalledFromCentura	bit,
				@bIsExternalUser	bit,	
				@nAccessAccountId	int,			
				@psActivityTemplateCode	nvarchar(20)',
				@pnUserIdentityId   = @pnUserIdentityId,
				@pbCalledFromCentura = @pbCalledFromCentura,
				@bIsExternalUser     = @bIsExternalUser,
				@nAccessAccountId    = @nAccessAccountId,				
				@psActivityTemplateCode	= @psActivityTemplateCode
End

Return @nErrorCode
GO

Grant execute on dbo.ipw_GetActivityTemplate to public
GO
