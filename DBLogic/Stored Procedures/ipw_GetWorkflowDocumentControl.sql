-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ipw_GetWorkflowDocumentControl
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ipw_GetWorkflowDocumentControl]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ipw_GetWorkflowDocumentControl.'
	Drop procedure [dbo].[ipw_GetWorkflowDocumentControl]
End
Print '**** Creating Stored Procedure dbo.ipw_GetWorkflowDocumentControl...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.ipw_GetWorkflowDocumentControl
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null, -- Language in which output is to be expressed
	@psDocumentName		nvarchar(50), -- Mandatory. 
	@pnCriteriaKey		int = null, -- Criteria Key
	@pnEntryNumber 		smallint = null, -- Entry Key
	@pbCalledFromCentura	bit		= 0
)
as
-- PROCEDURE:	ipw_GetWorkflowDocumentControl
-- VERSION:	1
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Return details of a adapted workflow screen control into Window Control and child Controls (Tabs, Topics, Fields and Rules)
--		This is an adaptor read model.  Not meant to be used for saving.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 18 MAR 2012	SF	R11318	1	Procedure created

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare	@nErrorCode	int
Declare @sLookupCulture	nvarchar(10)
Declare @sSQLString		nvarchar(max)
Declare @bExternalUser	bit
Declare @nRowCount int

-- Initialise variables
Set @nErrorCode	= 0
Set @sLookupCulture 	= dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)
Set @bExternalUser 	= 0
Set @nRowCount	= 0

-- Determine if the user is internal or external
If @nErrorCode = 0
Begin		
	Set @sSQLString = "
	Select	@bExternalUser = ISEXTERNALUSER
	from USERIDENTITY
	where IDENTITYID = @pnUserIdentityId"

	Exec  @nErrorCode=sp_executesql @sSQLString,
			N'@bExternalUser  bit OUTPUT,
			  @pnUserIdentityId	int',
			  @bExternalUser  = @bExternalUser	OUTPUT,
			  @pnUserIdentityId = @pnUserIdentityId
End

-- Resultset for Windows
If @nErrorCode = 0
Begin
	Set @sSQLString = 
	"Select top 1 "+char(10)+
	"1 				as 'DocumentControlKey',"+char(10)+
	"@pnCriteriaKey			as 'CaseCriteriaKey',"+char(10)+
	"null 				as 'NameCriteriaKey',"+char(10)+
	"@psDocumentName		as 'DocumentName',"+char(10)+
	"cast(1 as smallint) 		as 'DisplaySequence',"+char(10)+
	"null				as 'Title',"+char(10)+
	"null				as 'ShortTitle',"+char(10)+
	"DC.ENTRYNUMBER			as 'EntryNumber',"+char(10)+
	"null            		as 'Theme',"+char(10)+
	"cast(0 as bit)			as 'IsInherited'"+char(10)+
	"from	DETAILCONTROL DC"+char(10)+
	"where	DC.CRITERIANO = @pnCriteriaKey"+char(10)+
	"and	DC.ENTRYNUMBER = @pnEntryNumber"
	
	exec @nErrorCode=sp_executesql @sSQLString,
		N'@pnCriteriaKey int,
		@pnEntryNumber 	int,
		@psDocumentName nvarchar(50)',	
		@pnCriteriaKey = @pnCriteriaKey,
		@pnEntryNumber = @pnEntryNumber,
		@psDocumentName = @psDocumentName
	
	set @nRowCount = @@rowcount
End

-- Resultset for Tabs
If @nErrorCode = 0 and @nRowCount > 0
Begin
	Set @sSQLString = 
	"Select  cast(@pnEntryNumber + 99999 as int)		as 'TabControlKey',
		1    				  		as 'DocumentControlKey',
		'WorkflowWizard_UpdateEventEntry'		as 'TabName',
		cast(0 as smallint)				as 'DisplaySequence',
		NULL						as 'Title',
		cast(0 as bit)					as 'IsInherited'
	from	(Select 1 as txt) TMP
	union	
	Select  cast(@pnEntryNumber + 99998 as int)		as 'TabControlKey',
		1    				  		as 'DocumentControlKey',
		'WorkflowWizard_ConfirmLetters'			as 'TabName',
		cast(1 as smallint)				as 'DisplaySequence',
		NULL						as 'Title',
		cast(0 as bit)					as 'IsInherited'
	from	SITECONTROL SC 
	where	SC.CONTROLID = 'Letters Tab Hidden When Empty'
	and	exists (
		select	* 
		from	DETAILLETTERS DL 
		where	DL.CRITERIANO = @pnCriteriaKey
		and	DL.ENTRYNUMBER = @pnEntryNumber
		and	SC.COLBOOLEAN = 1
	) 
	or	(SC.COLBOOLEAN is null or SC.COLBOOLEAN = 0)
	union
	Select	cast(
			Cast(SC.ENTRYNUMBER as nvarchar(15)) + 
			Cast(SC.SCREENID as nvarchar(15))
		as int)						as 'TabControlKey',
		1    				  		as 'DocumentControlKey',
		SC.SCREENNAME  					as 'TabName',
		cast(SC.DISPLAYSEQUENCE+2 as smallint)		as 'DisplaySequence'," + 
		dbo.fn_SqlTranslatedColumn('SCREENCONTROL','SCREENTITLE',null,'SC',@sLookupCulture,0) + 
						"		as 'Title', 
		cast(isnull(SC.INHERITED,0) as bit)		as 'IsInherited'
	from	SCREENCONTROL SC
	where	SC.CRITERIANO = @pnCriteriaKey
	and	SC.ENTRYNUMBER = @pnEntryNumber
	order by 4"
  
	exec @nErrorCode=sp_executesql @sSQLString,
		N'@pnCriteriaKey 	int,
		@pnEntryNumber 		int',	
		@pnCriteriaKey = @pnCriteriaKey,
		@pnEntryNumber = @pnEntryNumber
End

-- Resultset for Topics
If @nErrorCode = 0 and @nRowCount > 0
Begin
	Set @sSQLString = "	
	Select  cast(@pnEntryNumber + 99999 as int)		as 'TopicControlKey',
		1    				  		as 'DocumentControlKey',
		'WorkflowWizard_UpdateEventEntry'		as 'TopicName',
		NULL						as 'TopicSuffix',
		cast(@pnEntryNumber + 99999 as int)		as 'TabControlKey',
		0						as 'RowPosition',
		0						as 'ColPosition',  
		NULL						as 'Title',
		NULL						as 'ShortTitle',
		NULL						as 'Description',
		NULL						as 'DisplayDescription',
		NULL						as 'FilterName',
		NULL						as 'FilterValue',
		NULL						as 'ScreenTip',
		cast(0 as bit)					as 'IsHidden',
		cast(1 as bit)					as 'IsMandatory',
		cast(0 as bit)					as 'IsInherited',
		0						as 'DisplaySequence'
	from	(Select 1 as txt) TMP
	union	
	Select  cast(@pnEntryNumber + 99998 as int)		as 'TopicControlKey',
		1    				  		as 'DocumentControlKey',
		'WorkflowWizard_ConfirmLetters'			as 'TopicName',
		NULL						as 'TopicSuffix',
		cast(@pnEntryNumber + 99998 as int)		as 'TabControlKey',
		0						as 'RowPosition',
		0						as 'ColPosition',  
		NULL						as 'Title',
		NULL						as 'ShortTitle',
		NULL						as 'Description',
		NULL						as 'DisplayDescription',
		NULL						as 'FilterName',
		NULL						as 'FilterValue',
		NULL						as 'ScreenTip',
		cast(0 as bit)					as 'IsHidden',
		cast(0 as bit)					as 'IsMandatory',
		cast(0 as bit)					as 'IsInherited',
		1						as 'DisplaySequence'
	from	SITECONTROL SC 
	where	SC.CONTROLID = 'Letters Tab Hidden When Empty'
	and	exists (
		select	* 
		from	DETAILLETTERS DL 
		where	DL.CRITERIANO = @pnCriteriaKey
		and	DL.ENTRYNUMBER = @pnEntryNumber
		and	SC.COLBOOLEAN = 1
	) 
	or	(SC.COLBOOLEAN is null or SC.COLBOOLEAN = 0)
	union	
	Select	cast(
			Cast(SC.ENTRYNUMBER as nvarchar(15)) + 
			Cast(SC.SCREENID as nvarchar(15))
		as int)						as 'TopicControlKey',
		1    				  		as 'DocumentControlKey',
		SC.SCREENNAME  					as 'TopicName',
		NULL						as 'TopicSuffix',
		cast(
			Cast(SC.ENTRYNUMBER as nvarchar(15)) + 
			Cast(SC.SCREENID as nvarchar(15))
		as int)						as 'TabControlKey',
		0						as 'RowPosition',
		0						as 'ColPosition', " + 
		dbo.fn_SqlTranslatedColumn('SCREENCONTROL','SCREENTITLE',null,'SC',@sLookupCulture,0) + 
						"		as 'Title', " + 
		dbo.fn_SqlTranslatedColumn('SCREENCONTROL','SCREENTITLE',null,'SC',@sLookupCulture,0) + 
						"		as 'ShortTitle', 
		NULL						as 'Description',
		NULL						as 'DisplayDescription',	
		CASE 
			WHEN CHECKLISTTYPE IS NOT NULL THEN 'ChecklistTypeKey'
			WHEN TEXTTYPE IS NOT NULL THEN 'TextTypeKey'
			WHEN NAMETYPE IS NOT NULL THEN 'NameTypeKey'
			WHEN NAMEGROUP IS NOT NULL THEN 'NameGroupKey'
			WHEN FLAGNUMBER IS NOT NULL THEN 'FlagNumber'
			WHEN CREATEACTION IS NOT NULL THEN 'CreateAction'
			WHEN RELATIONSHIP IS NOT NULL THEN 'RelationshipKey'
		ELSE NULL END					as 'FilterName',
		CASE 
			WHEN CHECKLISTTYPE IS NOT NULL THEN Cast(CHECKLISTTYPE as nvarchar(12))
			WHEN TEXTTYPE IS NOT NULL THEN TEXTTYPE
			WHEN NAMETYPE IS NOT NULL THEN NAMETYPE
			WHEN NAMEGROUP IS NOT NULL THEN Cast(NAMEGROUP as nvarchar(12))
			WHEN FLAGNUMBER IS NOT NULL THEN Cast(FLAGNUMBER as nvarchar(12))
			WHEN CREATEACTION IS NOT NULL THEN CREATEACTION
			WHEN RELATIONSHIP IS NOT NULL THEN RELATIONSHIP
		ELSE NULL END					as 'FilterValue', "+char(10)+		/*SC.GENERICPARAMETER				as GenericParameter,*/
		dbo.fn_SqlTranslatedColumn('SCREENCONTROL','SCREENTIP',null,'SC',@sLookupCulture,0) + 
						"				as ScreenTip,
		cast(0 as bit)					as 'IsHidden',
		cast(isnull(SC.MANDATORYFLAG, 0) as bit)	as 'IsMandatory',
		cast(isnull(SC.INHERITED,0) as bit)		as 'IsInherited',
		SC.DISPLAYSEQUENCE+2				as 'DisplaySequence'
	from	SCREENCONTROL SC
	where	SC.CRITERIANO = @pnCriteriaKey
	and	SC.ENTRYNUMBER = @pnEntryNumber
	order by 'DisplaySequence'"
  print @sSQLString
  	exec @nErrorCode=sp_executesql @sSQLString,
		N'@pnCriteriaKey 	int,
		@pnEntryNumber 		int',	
		@pnCriteriaKey = @pnCriteriaKey,
		@pnEntryNumber = @pnEntryNumber
End

-- Resultset for Fields 
If @nErrorCode = 0 and @nRowCount > 0
Begin
	Set @sSQLString = 
	"Select"+char(10)+
	"NULL 	as 'FieldControlKey',"+char(10)+
	"NULL  	as 'DocumentControlKey',"+char(10)+
	"NULL   as 'TopicControlKey',"+char(10)+
	"NULL   as 'FieldName',"+char(10)+
	"NULL 	as 'ShortLabel',"+char(10)+
	"NULL 	as 'FullLabel',"+char(10)+
	"NULL 	as 'Button',"+char(10)+
	"NULL 	as 'Tooltip',"+char(10)+
	"NULL 	as 'Link',"+char(10)+
	"NULL 	as 'Literal',"+char(10)+
	"NULL   as 'DefaultValue',"+char(10)+
	"NULL	as 'FilterName',"+char(10)+
	"NULL 	as 'FilterValue',"+char(10)+
	"NULL	as 'IsHidden',"+char(10)+
	"NULL	as 'IsMandatory',"+char(10)+
	"NULL	as 'IsReadOnly',"+char(10)+
	"NULL	as 'IsInherited'"+char(10)+
	"from ELEMENTCONTROL E"+char(10)+
	"where 1=2"
  
	exec @nErrorCode=sp_executesql @sSQLString
	
End
Return @nErrorCode
GO

Grant execute on dbo.ipw_GetWorkflowDocumentControl to public
GO
