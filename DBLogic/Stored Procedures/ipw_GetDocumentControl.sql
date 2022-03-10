-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ipw_GetDocumentControl
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ipw_GetDocumentControl]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ipw_GetDocumentControl.'
	Drop procedure [dbo].[ipw_GetDocumentControl]
End
Print '**** Creating Stored Procedure dbo.ipw_GetDocumentControl...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.ipw_GetDocumentControl
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null, -- Language in which output is to be expressed
	@psDocumentName nvarchar(50), -- Mandatory. XFOP Document Name
	@pnCaseCriteriaKey int = null, -- Case Criteria
	@pnNameCriteriaKey int = null, -- Name Criteria
	@pbCalledFromCentura		bit		= 0
)
as
-- PROCEDURE:	ipw_GetDocumentControl
-- VERSION:	6
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Return details of a single Window Control and child Controls (Tabs, Topics, Fields and Rules)

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 06 JAN 2009	JC	RFC6732	1	Procedure created
-- 23 May 2011	LP	RFC10665 2	Limit TOPICCONTROL to those with valid TABCONTROL.
-- 17 Jun 2011  DV      RFC100551 3     Revert the code added in RFC10665.
-- 20 Jun 2013	vql	RFC8511	4	Provide the ability to display Name Text of a given Name Type and Text Type within Case program.
-- 16 Sep 2014  SW      RFC27882  5     Return FilterName and FilterValue for Case Name topics in the Topics ResultSet
-- 29 Dec 2017  DV	R73211	6	Return IsReadOnly for Custom filters based on Maintain Custom Content Access task security

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare	@nErrorCode	int
Declare @sLookupCulture	nvarchar(10)
Declare @sSQLString			nvarchar(4000)
Declare @bExternalUser	bit
Declare @sSQLCondition	nvarchar(4000)
Declare @nRowCount int
declare @bCanMaintainCustomContentAccess bit

-- Initialise variables
Set @nErrorCode	= 0
Set @sLookupCulture 	= dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)
Set @bExternalUser 	= 0
Set @nRowCount	= 0
Set @bCanMaintainCustomContentAccess = 0

If @nErrorCode = 0
Begin	
Set @sSQLString = "Select @bCanMaintainCustomContentAccess = 1
	from dbo.fn_PermissionsGranted(@pnUserIdentityId, 'TASK', 273, null, getdate()) PG
	where PG.CanExecute = 1"

	exec @nErrorCode = sp_executesql @sSQLString,
					N'@bCanMaintainCustomContentAccess	bit				OUTPUT,
					  @pnUserIdentityId		int',
					  @bCanMaintainCustomContentAccess	= @bCanMaintainCustomContentAccess	OUTPUT,
					  @pnUserIdentityId		= @pnUserIdentityId
End

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


If @nErrorCode = 0
Begin
	Set @sSQLCondition = "
	W.ISEXTERNAL = @bExternalUser
	and W.WINDOWNAME = @psDocumentName"+
	CASE WHEN @pnCaseCriteriaKey IS NOT NULL
		THEN " and W.CRITERIANO = @pnCaseCriteriaKey"
		ELSE " and W.NAMECRITERIANO = @pnNameCriteriaKey"
	END
End 

-- Resultset for Windows
If @nErrorCode = 0
Begin
	Set @sSQLString = 
	"Select"+char(10)+
	"W.WINDOWCONTROLNO as 'DocumentControlKey',"+char(10)+
	"W.CRITERIANO      as 'CaseCriteriaKey',"+char(10)+
	"W.NAMECRITERIANO  as 'NameCriteriaKey',"+char(10)+
	"W.WINDOWNAME      as 'DocumentName',"+char(10)+
	"W.DISPLAYSEQUENCE as 'DisplaySequence',"+char(10)+
	dbo.fn_SqlTranslatedColumn('WINDOWCONTROL','WINDOWTITLE',null,'W',@sLookupCulture,@pbCalledFromCentura)+" as Title,"+char(10)+
	dbo.fn_SqlTranslatedColumn('WINDOWCONTROL','WINDOWSHORTTITLE',null,'W',@sLookupCulture,@pbCalledFromCentura)+" as ShortTitle,"+char(10)+ 
	"W.ENTRYNUMBER     as 'EntryNumber',"+char(10)+
	"W.THEME           as 'Theme',"+char(10)+
	"W.ISINHERITED     as 'IsInherited'"+char(10)+	
	"from WINDOWCONTROL W"+char(10)+
	"where "+@sSQLCondition+char(10)+
	"order by W.DISPLAYSEQUENCE"
  
	exec @nErrorCode=sp_executesql @sSQLString,
		N'@pnCaseCriteriaKey int,
		@pnNameCriteriaKey int,
		@bExternalUser bit,
		@psDocumentName nvarchar(50)',	
		@pnCaseCriteriaKey = @pnCaseCriteriaKey,
		@pnNameCriteriaKey = @pnNameCriteriaKey,
		@bExternalUser = @bExternalUser,
		@psDocumentName = @psDocumentName
	
	set @nRowCount = @@rowcount
End

-- Resultset for Tabs
If @nErrorCode = 0 and @nRowCount > 0
Begin
	Set @sSQLString = 
	"Select"+char(10)+
	"T.TABCONTROLNO    as 'TabControlKey',"+char(10)+
	"W.WINDOWCONTROLNO as 'DocumentControlKey',"+char(10)+
	"T.TABNAME         as 'TabName',"+char(10)+
	"T.DISPLAYSEQUENCE as 'DisplaySequence',"+char(10)+
	dbo.fn_SqlTranslatedColumn('TABCONTROL','TABTITLE',null,'T',@sLookupCulture,@pbCalledFromCentura)+" as Title,"+char(10)+
	"T.ISINHERITED    as 'IsInherited'"+char(10)+
	"from TABCONTROL T"+char(10)+
	"join WINDOWCONTROL W on (W.WINDOWCONTROLNO = T.WINDOWCONTROLNO)"+char(10)+
	"where "+@sSQLCondition+char(10)+
	"order by T.DISPLAYSEQUENCE"
  
	exec @nErrorCode=sp_executesql @sSQLString,
		N'@pnCaseCriteriaKey int,
		@pnNameCriteriaKey int,
		@bExternalUser bit,
		@psDocumentName nvarchar(50)',	
		@pnCaseCriteriaKey = @pnCaseCriteriaKey,
		@pnNameCriteriaKey = @pnNameCriteriaKey,
		@bExternalUser = @bExternalUser,
		@psDocumentName = @psDocumentName  
End

-- Resultset for Topics
If @nErrorCode = 0 and @nRowCount > 0
Begin
	Set @sSQLString = 
	"Select"+char(10)+
	"P.TOPICCONTROLNO     as 'TopicControlKey',"+char(10)+
	"W.WINDOWCONTROLNO    as 'DocumentControlKey',"+char(10)+
	"P.TOPICNAME          as 'TopicName',"+char(10)+
	"P.TOPICSUFFIX        as 'TopicSuffix',"+char(10)+
	"P.TABCONTROLNO       as 'TabControlKey',"+char(10)+
	"P.ROWPOSITION        as 'RowPosition',"+char(10)+
	"P.COLPOSITION        as 'ColPosition',"+char(10)+
	dbo.fn_SqlTranslatedColumn('TOPICCONTROL','TOPICTITLE',null,'P',@sLookupCulture,@pbCalledFromCentura)+" as Title,"+char(10)+
	dbo.fn_SqlTranslatedColumn('TOPICCONTROL','TOPICSHORTTITLE',null,'P',@sLookupCulture,@pbCalledFromCentura)+" as ShortTitle,"+char(10)+
	dbo.fn_SqlTranslatedColumn('TOPICCONTROL','TOPICDESCRIPTION',null,'P',@sLookupCulture,@pbCalledFromCentura)+" as Description,"+char(10)+
	"P.DISPLAYDESCRIPTION as 'DisplayDescription',"+char(10)+
	dbo.fn_SqlTranslatedColumn('TOPICCONTROL','SCREENTIP',null,'P',@sLookupCulture,@pbCalledFromCentura)+" as ScreenTip,"+char(10)+
	"P.ISHIDDEN           as 'IsHidden',"+char(10)+
	"P.ISMANDATORY        as 'IsMandatory',"+char(10)+
	"P.ISINHERITED        as 'IsInherited',"+char(10)+
	"P.FILTERNAME         as 'FilterName',"+char(10)+
	"P.FILTERVALUE        as 'FilterValue'"+char(10)+
	"from TOPICCONTROL P"+char(10)+
	"join WINDOWCONTROL W on (W.WINDOWCONTROLNO = P.WINDOWCONTROLNO)"+char(10)+
	"where "+@sSQLCondition+char(10)+
	"order by P.TOPICSUFFIX, P.ROWPOSITION,P.COLPOSITION"
  
	exec @nErrorCode=sp_executesql @sSQLString,
		N'@pnCaseCriteriaKey int,
		@pnNameCriteriaKey int,
		@bExternalUser bit,
		@psDocumentName nvarchar(50)',	
		@pnCaseCriteriaKey = @pnCaseCriteriaKey,
		@pnNameCriteriaKey = @pnNameCriteriaKey,
		@bExternalUser = @bExternalUser,
		@psDocumentName = @psDocumentName  
End

-- Resultset for Fields 
If @nErrorCode = 0 and @nRowCount > 0
Begin
	Set @sSQLString = 
	"Select"+char(10)+
	"E.ELEMENTCONTROLNO as 'FieldControlKey',"+char(10)+
	"W.WINDOWCONTROLNO  as 'DocumentControlKey',"+char(10)+
	"P.TOPICCONTROLNO   as 'TopicControlKey',"+char(10)+
	"E.ELEMENTNAME      as 'FieldName',"+char(10)+
	dbo.fn_SqlTranslatedColumn('ELEMENTCONTROL','SHORTLABEL',null,'E',@sLookupCulture,@pbCalledFromCentura)+" as ShortLabel,"+char(10)+
	dbo.fn_SqlTranslatedColumn('ELEMENTCONTROL','FULLLABEL',null,'E',@sLookupCulture,@pbCalledFromCentura)+" as FullLabel,"+char(10)+
	dbo.fn_SqlTranslatedColumn('ELEMENTCONTROL','BUTTON',null,'E',@sLookupCulture,@pbCalledFromCentura)+" as Button,"+char(10)+
	dbo.fn_SqlTranslatedColumn('ELEMENTCONTROL','TOOLTIP',null,'E',@sLookupCulture,@pbCalledFromCentura)+" as Tooltip,"+char(10)+
	dbo.fn_SqlTranslatedColumn('ELEMENTCONTROL','LINK',null,'E',@sLookupCulture,@pbCalledFromCentura)+" as Link,"+char(10)+
	dbo.fn_SqlTranslatedColumn('ELEMENTCONTROL','LITERAL',null,'E',@sLookupCulture,@pbCalledFromCentura)+" as Literal,"+char(10)+
	"E.DEFAULTVALUE     as 'DefaultValue',"+char(10)+
	"E.FILTERNAME	    as 'FilterName',"+char(10)+
	"E.FILTERVALUE	    as 'FilterValue',"+char(10)+
	"E.ISHIDDEN         as 'IsHidden',"+char(10)+
	"E.ISMANDATORY      as 'IsMandatory',"+char(10)+
	"E.ISREADONLY       as 'IsReadOnly',"+char(10)+
	"E.ISINHERITED      as 'IsInherited'"+char(10)+
	"from ELEMENTCONTROL E"+char(10)+
	"join TOPICCONTROL P on (P.TOPICCONTROLNO = E.TOPICCONTROLNO)"+char(10)+
	"join WINDOWCONTROL W on (W.WINDOWCONTROLNO = P.WINDOWCONTROLNO)"+char(10)+
	"where "+@sSQLCondition
  
	exec @nErrorCode=sp_executesql @sSQLString,
		N'@pnCaseCriteriaKey int,
		@pnNameCriteriaKey int,
		@bExternalUser bit,
		@psDocumentName nvarchar(50)',	
		@pnCaseCriteriaKey = @pnCaseCriteriaKey,
		@pnNameCriteriaKey = @pnNameCriteriaKey,
		@bExternalUser = @bExternalUser,
		@psDocumentName = @psDocumentName  
End

-- Resultset for Filters
If @nErrorCode = 0 and @nRowCount > 0
Begin
	Set @sSQLString = 
	"Select"+char(10)+
	"T.TOPICCONTROLNO   as 'TopicControlKey',"+char(10)+
	"P.FILTERNAME as 'FilterName',"+char(10)+
	"P.FILTERVALUE as 'FilterValue',"+char(10)+
	"cast((CASE WHEN P.FILTERNAME = 'ParentAccessAllowed' and @bCanMaintainCustomContentAccess = 0 THEN  1 ELSE 0 END) as bit) as 'IsReadOnly'"+char(10)+
	"from TOPICCONTROL T"+char(10)+
	"left join TOPICCONTROLFILTER P on (P.TOPICCONTROLNO = T.TOPICCONTROLNO)"+char(10)+
	"join WINDOWCONTROL W on (W.WINDOWCONTROLNO = T.WINDOWCONTROLNO)"+char(10)+
	"where "+@sSQLCondition+char(10)+
	"and P.FILTERNAME is not null"

	exec @nErrorCode=sp_executesql @sSQLString,
		N'@pnCaseCriteriaKey int,
		@pnNameCriteriaKey int,
		@bExternalUser bit,
		@psDocumentName nvarchar(50),
		@bCanMaintainCustomContentAccess	bit',	
		@pnCaseCriteriaKey = @pnCaseCriteriaKey,
		@pnNameCriteriaKey = @pnNameCriteriaKey,
		@bExternalUser = @bExternalUser,
		@psDocumentName = @psDocumentName,
		@bCanMaintainCustomContentAccess = @bCanMaintainCustomContentAccess
End

Return @nErrorCode
GO

Grant execute on dbo.ipw_GetDocumentControl to public
GO