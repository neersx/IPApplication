-----------------------------------------------------------------------------------------------------------------------------
-- Creation of dbo.ipw_ListSearchData 
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ipw_ListSearchData ]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ipw_ListSearchData.'
	Drop procedure [dbo].[ipw_ListSearchData ]
	Print '**** Creating Stored Procedure dbo.ipw_ListSearchData ...'
	Print ''
End
GO

SET QUOTED_IDENTIFIER OFF
GO

CREATE PROCEDURE dbo.ipw_ListSearchData 
(
	@pnColumnGroupRowCount		int		= null	output,
	@pnColumnRowCount		int		= null	output,
	@pnDefaultColumnsRowCount	int		= null	output,
	@pnQueryRowCount		int		= null	output,
	@pnSelectedColumnsRowCount	int		= null	output,
	@pnUserIdentityId		int,		-- Mandatory
	@psCulture			nvarchar(10) 	= null,
	@pnQueryContextKey		int,		-- Mandatory
	@pnQueryKey			int		= null,
	@psPresentationType		nvarchar(30)	= null,
	@pnPresentationKey		int		= null,
	@pbCalledFromCentura		bit		= 0
)
AS
-- PROCEDURE:	ipw_ListSearchData 
-- VERSION:	40
-- SCOPE:	InPro.net
-- DESCRIPTION:	Populates the SearchData dataset. The data returned is filtered to ensure that the user
--		only has access to appropriate columns.  

-- MODIFICATIONS :
-- Date		Who	Number	Version	Change
-- ------------	-------	------	-------	----------------------------------------------- 
-- 19-Nov-2003  TM	RFC397	1	Procedure created
-- 20-Nov-2003	TM	RFC397	2	Implement subset security
-- 21-Nov-2003	TM	RFC397	3	The DefaultColumns will only select QueryPresentation rows where IsDefault=1.
-- 09-Dec-2003	JEK	RFC397	4	The DefaultColumns are not being filtered for the context.
-- 13-Dec-2003	JEK	RFC397	5	The Query information is not being filtered by QueryKey.
-- 09-Dec-2003	JEK	RFC397	4	The DefaultColumns are not being filtered for the context.
-- 13-Dec-2003	JEK	RFC397	5	The Query information is not being filtered by QueryKey.
-- 15-Dec-2003	TM	RFC397	6	Replace the use of Unions with one 'Select' statement.
-- 15-Dec-2003	TM	RFC742	7	Remove unnecessary 'Select' statement from the 'Populating DefaultColumns dataset'
--					section. 
-- 17-Dec-2003	TM	RFC742	8	Replace 'or QDI.QUALIFIERTYPE not in (1,2,4,5))' with the following:
--					'CASE WHEN QDI.QUALIFIERTYPE...ELSE QC.QUALIFIER END'. Remove some debug code.
-- 17-Dec-2003	TM	RFC742	9	Set all of the RowCounts to 0 at the beginning of the stored procedure.
-- 19-Feb-2004	TM	RFC976	10	Add the @pbCalledFromCentura  = default parameter to the calling code 
--					for relevant functions.
-- 08-Mar-2004	TM	RFC934	11	Modify implementation of fn_FilterUserEvents to apply for external users only.
-- 19-Apr-2004	TM	RFC919	12	Add the following columns to the Query result set: ReportTemplateName, ReportTitle, 
--					ReportToolKey, ExportFormatKey, ReportToolDescription, ExportFormatDescription, 
--					GroupKey and GroupName.  
-- 27-Apr-2004	TM	RFC919	13	Since WorkBenches cannot process Centura reports as reports, ensure that report 
--					related columns are returned as null (ReportTemplateName, ReportTitle, 
--					ReportToolKey, ReportToolDescription, ExportFormatKey, ExportFormatDescription).
--					Applies when ReportToolKey = 9401.
-- 19-Jul-2004	TM	RFC1543	14	Add IsDefaultSearch and IsDefaultUserSearch columns to the Query result set.
-- 20-Jul-2004	TM	RFC578	15	Add IsDefaultUserPresentation column to the Query result set.
-- 06-Sep-2004	TM	RFC578	16	Add new DefaultColumns.IsDefaultUserPresentation column.
-- 09 Sep 2004	JEK	RFC886	17	Implement @psCulture and @pbCalledByCentura in FilterUser functions.
-- 01 Oct 2004	TM	RFC1881	18	Implement the Permissions subsystem instead of using a join to RoleTopics (no longer in use).
-- 14 Oct 2004	TM	RFC1898	19	Modify calls to the fn_PermissionsGranted to include 'CanSelect = 1' as a 'join' or 'where' condition. 
-- 05 Apr 2005	TM	RFC2499	20	Use derived table when checking subject security when retrieving the columns for 
--					a saved search.
-- 15 May 2005  JEK	RFC2508	21	Pass @sLookupCulture to fn_FilterUserXxx.
-- 25 Aug 2005	TM	RFC2593	22	When populating the information for the default presentation (DefaultColumns, 
--					extend the join logic to select only QueryPresentation rows where 
--					PresentationType is null.
-- 20 Dec 2005	TM	RFC3221	23	Implement default searches by access account.
-- 31 Jan 2006	TM	RFC3538	24	IsDefaultSearch will be set to true for a public search if it is default public 
--					search, and true for a personal search if it is the default personal search.
-- 21 Feb 2006	SF	RFC3557	25	Query result set will only be filtered on the @pnQueryKey.
-- 17 Mar 2006	IB	RFC3325	26	Suppress alias columns with an Alias Type qualifier (Qualifier Type = 8)
--					that the current user does not have access to.  Applies to external users only.
-- 12 Jul 2006	SW	RFC3828	27	Pass getdate() to fn_Permission..
-- 12 Dec 2006	JEK	RFC2984	28	Implement subset security for qualifier type Instruction Type.
-- 25 Jan 2007	SW	RFC4982	29	Allow comma separated value in QUALIFIER for QUALIFIERTYPE = 2
-- 13 Mar 2009  PS	RFC7200 30	IsDefaultSearch will be 1 for public default search else 0. 
-- 13 Jan 2010	LP	RFC8656	31	Return ReportTemplateFileName as ReportTemplate.rdl.
-- 13 Jan 2010	LP	RFC8656	31	Return ReportTemplateFileName as ReportTemplate.rdl.
-- 18 Jan 2010	SF	RFC8483 32	Cast 1s and 0s as bits
-- 22 Jan 2010	SF	RFC8483 33	Extend to return IsFreezeColumnIndex, and GroupBySortOrder and GroupBySortDirection columns
--								Allow Presentation Type to be returned
-- 08 Feb 2010	SF	RFC8483	34	Wrong set of columns is returned when the query context has multiple presentation.
-- 11 Feb 2010	SF	RFC8483	35	Implemented IsGroupable
-- 19 Feb 2010	SF	RFC8483	36	Return FreezeColumnKey for maintenance purposes.
-- 03 Nov 2010	LP	RFC9543	37	Allow PresentationKey to be specified.
-- 04 Apr 2011  DV      RFC9947 38      Check for topic security with QueryDataItems for saved queries.
-- 28 Jun 2012	LP	R100730 39	Added DISTINCT to select clause when returning SelectedColumns result set.
--					This was previously returning duplicate row for QUERYDATAITEMs governed Subject Security.
-- 05 May 2017	MF	71399	40	Implemented translation. Correction provided by AK(Novagraaf).

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare @sSQLString 			nvarchar(4000)
Declare @bIsExternalUser		bit
Declare @nAccessAccountID		int

Declare	@sLookupCulture			nvarchar(10)

Declare @bUseDefaultIdentity		bit	-- If @bUseDefaultIdentity = 1 then DefaultColumns are selected for IdentityId = null 

Declare @nErrorCode			int
Declare @dtToday			datetime

Set 	@nErrorCode 			= 0
Set	@dtToday			= getdate()
set	@sLookupCulture = dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)

Set	@pnColumnGroupRowCount		= 0
Set	@pnColumnRowCount		= 0
Set	@pnDefaultColumnsRowCount	= 0	
Set	@pnQueryRowCount		= 0	
Set	@pnSelectedColumnsRowCount	= 0

-- We need to determine if the user is external

If @nErrorCode = 0
Begin
	Set @sSQLString = "
	Select	@bIsExternalUser = ISEXTERNALUSER,
		@nAccessAccountID = ACCOUNTID
	from USERIDENTITY
	where IDENTITYID = @pnUserIdentityId"

	exec @nErrorCode = sp_executesql @sSQLString,
				N'@bIsExternalUser		bit	OUTPUT,
				  @nAccessAccountID		int	OUTPUT,
				  @pnUserIdentityId		int',
				  @bIsExternalUser=@bIsExternalUser	OUTPUT,
				  @nAccessAccountID=@nAccessAccountID	OUTPUT,
				  @pnUserIdentityId=@pnUserIdentityId

	If @bIsExternalUser is null
		Set @bIsExternalUser = 1
End


-- Populating ColumnGroup dataset

If @nErrorCode = 0
Begin
	Set @sSQLString="
	Select  Q.GROUPID		as 'GroupKey',
		" + dbo.fn_SqlTranslatedColumn('QUERYCOLUMNGROUP','GROUPNAME',null,'Q',@sLookupCulture,@pbCalledFromCentura) + "		as 'GroupName',
		Q.DISPLAYSEQUENCE	as 'DisplaySequence'
	from	QUERYCOLUMNGROUP Q
	where	Q.CONTEXTID = @pnQueryContextKey
	order by 'DisplaySequence'"

	exec @nErrorCode = sp_executesql @sSQLString,
					N'@pnQueryContextKey	int',
					  @pnQueryContextKey	= @pnQueryContextKey

	Set @pnColumnGroupRowCount = @@Rowcount
End

-- Populating Column dataset

-- The data returned needs to be filtered to ensure that the user only has access to appropriate columns.
-- Columns that are formed using qualifiers need to be checked to ensure that the QueryColumn.
-- Qualifier value is in the list of values that the current user is able to view.  

If @nErrorCode = 0
Begin
	-- The content of the QueryDataItem.QualifierType indicates the type of subset security that needs to be applied:

	Set @sSQLString = 
	"Select DISTINCT QCC.GROUPID		as 'GroupKey',"+CHAR(10)+
	"	QCC.COLUMNID		as 'ColumnKey',"+CHAR(10)+
	"	" + dbo.fn_SqlTranslatedColumn('QUERYCOLUMN', 'COLUMNLABEL', null, 'QC', @sLookupCulture, @pbCalledFromCentura) + "		as 'ColumnLabel',"+CHAR(10)+
	"	" + dbo.fn_SqlTranslatedColumn('QUERYCOLUMN','DESCRIPTION', null, 'QC', @sLookupCulture, @pbCalledFromCentura) + "		as 'Description',"+CHAR(10)+
	"	CASE WHEN QCC.ISMANDATORY = 1 AND QCC.ISSORTONLY = 0 THEN cast(1 as bit) ELSE cast(0 as bit) END as 'IsDisplayMandatory',"+CHAR(10)+
	"	CASE WHEN QCC.ISSORTONLY = 1 THEN cast(0 as bit) WHEN QCC.ISSORTONLY = 0 THEN cast(1 as bit) ELSE cast(0 as bit) END as 'IsDisplayable',"+CHAR(10)+
	"	QDI.SORTDIRECTION	as 'DefaultSortDirection',"+CHAR(10)+
	"	CASE WHEN QDI.DATAFORMATID in (9107, 9110, 9112, 9113) THEN cast(0 as bit) ELSE cast(1 as bit) END as 'IsGroupable'"+CHAR(10)+
	"from	QUERYCONTEXTCOLUMN QCC"+CHAR(10)+
	"join QUERYCOLUMN QC	on (QC.COLUMNID = QCC.COLUMNID)"+CHAR(10)+
	"join QUERYDATAITEM QDI	on (QDI.DATAITEMID = QC.DATAITEMID)"+CHAR(10)+
	-- For QUALIFIERTYPE = 1 the fn_FilterUserTextTypes needs to be applied
	"left join dbo.fn_FilterUserTextTypes(@pnUserIdentityId,null,@bIsExternalUser,@pbCalledFromCentura) FT"+CHAR(10)+
	"				on (FT.TEXTTYPE = QC.QUALIFIER"+CHAR(10)+	
	"				and QDI.QUALIFIERTYPE = 1)"+CHAR(10)+						
	-- For QUALIFIERTYPE = 2 the fn_FilterUserNameTypes needs to be applied 
	"left join dbo.fn_FilterUserNameTypes(@pnUserIdentityId,null,@bIsExternalUser,@pbCalledFromCentura) FN"+CHAR(10)+
	--"				on (FN.NAMETYPE = QC.QUALIFIER"+CHAR(10)+
	"				on (Charindex(FN.NAMETYPE + ',', QC.QUALIFIER + ',') > 0"+CHAR(10)+
	"				and QDI.QUALIFIERTYPE = 2)"+CHAR(10)+	
	-- If the user is an External User then require an additional join to the Filtered Events
	-- and InstructionTypes
	CASE WHEN @bIsExternalUser = 1 
	     -- For QUALIFIERTYPE = 4 the fn_FilterUserEvents needs to be applied
	     THEN CHAR(10)+"left join dbo.fn_FilterUserEvents(@pnUserIdentityId,null,1,@pbCalledFromCentura) FE"+CHAR(10)+
			   "			on (cast(FE.EVENTNO as nvarchar(12)) = QC.QUALIFIER"+CHAR(10)+
			   "			and QDI.QUALIFIERTYPE = 4)"+CHAR(10)+   
	     -- For QUALIFIERTYPE = 14 the fn_FilterUserInstructionTypes needs to be applied
	     		   "left join dbo.fn_FilterUserInstructionTypes(@pnUserIdentityId,null,1,@pbCalledFromCentura) FI"+CHAR(10)+
			   "			on (FI.INSTRUCTIONTYPE = QC.QUALIFIER"+CHAR(10)+
			   "			and QDI.QUALIFIERTYPE = 14)"+CHAR(10)   
	END+	
	-- For QUALIFIERTYPE = 5 the fn_FilterUserNumberTypes needs to be applied
	"left join dbo.fn_FilterUserNumberTypes(@pnUserIdentityId,null,@bIsExternalUser,@pbCalledFromCentura) FNM"+CHAR(10)+
	"				on (FNM.NUMBERTYPE = QC.QUALIFIER"+CHAR(10)+
	"				and QDI.QUALIFIERTYPE = 5)"+CHAR(10)+		
     	-- For QUALIFIERTYPE = 8 the fn_FilterUserAliasTypes needs to be applied
	"left join dbo.fn_FilterUserAliasTypes(@pnUserIdentityId,null,@bIsExternalUser,@pbCalledFromCentura) FUAT"+CHAR(10)+
	"				on (FUAT.ALIASTYPE = QC.QUALIFIER"+CHAR(10)+
	"				and QDI.QUALIFIERTYPE = 8)"+CHAR(10)+
	"left join (	Select DISTINCT TDI1.DATAITEMID"+CHAR(10)+
	"		from TOPICDATAITEMS TDI1"+CHAR(10)+
 	"		join dbo.fn_PermissionsGranted(@pnUserIdentityId, 'DATATOPIC', NULL, NULL, @dtToday) PG"+CHAR(10)+
	"       				on (PG.ObjectIntegerKey = TDI1.TOPICID"+CHAR(10)+
	"       				and PG.CanSelect = 1)) TDI ON (TDI.DATAITEMID = QDI.DATAITEMID)"+CHAR(10)+
	"left join (	Select DISTINCT TDI3.DATAITEMID"+CHAR(10)+
	"		from TOPICDATAITEMS TDI3) TDI2 ON (TDI2.DATAITEMID = QDI.DATAITEMID)"+CHAR(10)+	
	"where QCC.CONTEXTID = @pnQueryContextKey"+CHAR(10)+
	"and (CASE WHEN QDI.QUALIFIERTYPE = 1 THEN Charindex(FT.TEXTTYPE + ',', QC.QUALIFIER + ',')"+CHAR(10)+					 
	"          WHEN QDI.QUALIFIERTYPE = 2 THEN Charindex(FN.NAMETYPE + ',', QC.QUALIFIER + ',')"+CHAR(10)+	
	CASE WHEN @bIsExternalUser = 1 
	-- For QUALIFIERTYPE = 4 for external user the Events filtering needs to be applied
	     THEN CHAR(10)+"	  WHEN QDI.QUALIFIERTYPE = 4 THEN Charindex(cast(FE.EVENTNO as nvarchar(12)) + ',', QC.QUALIFIER + ',')"+CHAR(10)+
	-- For QUALIFIERTYPE = 14 for external user the InstructionType filtering needs to be applied
	     		   "	  WHEN QDI.QUALIFIERTYPE = 14 THEN Charindex(FI.INSTRUCTIONTYPE + ',', QC.QUALIFIER + ',')"+CHAR(10)
	END+
	"          WHEN QDI.QUALIFIERTYPE = 5 THEN Charindex(FNM.NUMBERTYPE + ',', QC.QUALIFIER + ',')"+CHAR(10)+	
	"          WHEN QDI.QUALIFIERTYPE = 8 THEN Charindex(FUAT.ALIASTYPE + ',', QC.QUALIFIER + ',')"+CHAR(10)+	
	"          ELSE 1"+CHAR(10)+ -- always return
	"          END"+CHAR(10)+
	" > 0"+CHAR(10)+
	"or QC.QUALIFIER is null)"+CHAR(10)+
	-- The QueryDataItems need to be checked for topic security.  If there is a TopicDataItems for the DataItemID, 
	-- the current user must have a Role that grants access to the topic.
	"and (TDI.DATAITEMID = QDI.DATAITEMID or TDI2.DATAITEMID is null)"+char(10)+
	"order by 'GroupKey', 'ColumnLabel'"

	exec @nErrorCode = sp_executesql @sSQLString,
					N'@pnQueryContextKey	int,
					  @pnUserIdentityId	int,
					  @bIsExternalUser	bit,
					  @psCulture		nvarchar(10),
					  @pbCalledFromCentura	bit,
					  @dtToday		datetime',
					  @pnQueryContextKey	= @pnQueryContextKey,
					  @pnUserIdentityId	= @pnUserIdentityId,
					  @bIsExternalUser	= @bIsExternalUser,
					  @psCulture		= @psCulture,
					  @pbCalledFromCentura	= @pbCalledFromCentura,
					  @dtToday		= @dtToday

	Set @pnColumnRowCount = @@Rowcount
End	

-- Populating DefaultColumns dataset (the default columns to be displayed or sorted in the context)

If @nErrorCode = 0
Begin
	Set @sSQLString = "
	Select  QC.COLUMNID		as 'ColumnKey',
		QC.DISPLAYSEQUENCE	as 'DisplaySequence',
		QC.SORTORDER		as 'SortOrder',
		QC.SORTDIRECTION	as 'SortDirection',
		CASE WHEN QP1.IDENTITYID is not null 
		     THEN cast(1 as bit) 
		     ELSE cast(0 as bit)
		END			as 'IsDefaultUserPresentation',
		QC.GROUPBYSEQUENCE	as 'GroupBySortOrder',
		QC.GROUPBYSORTDIR	as 'GroupBySortDirection',
		CASE WHEN ISNULL(QP1.FREEZECOLUMNID, QP.FREEZECOLUMNID) =  QC.COLUMNID
			THEN cast(1 as bit)
			ELSE cast(0 as bit)
		END					as 'IsFreezeColumnIndex'
		
	from	QUERYPRESENTATION QP
	-- The default may be overridden for a specific user identity
	left join QUERYPRESENTATION QP1	on (QP1.CONTEXTID = QP.CONTEXTID
					and QP1.ISDEFAULT = QP.ISDEFAULT
					and QP1.IDENTITYID = @pnUserIdentityId					
					and ((QP1.PRESENTATIONTYPE IS NULL and @psPresentationType is null) or
						 (QP1.PRESENTATIONTYPE = @psPresentationType))
					)
	join QUERYCONTENT QC		on (QC.PRESENTATIONID = isnull(QP1.PRESENTATIONID, QP.PRESENTATIONID))
	where QP.CONTEXTID = @pnQueryContextKey
	and   QP.ISDEFAULT = 1
	and   QP.IDENTITYID IS NULL
	and   ((QP.PRESENTATIONTYPE IS NULL and @psPresentationType is null) or
			(QP.PRESENTATIONTYPE = @psPresentationType))
	order by 'DisplaySequence', 'SortOrder'"
		
	exec @nErrorCode = sp_executesql @sSQLString,
					N'@pnQueryContextKey	int,
					  @pnUserIdentityId	int,
					  @psPresentationType	nvarchar(30)',
				          @pnQueryContextKey	= @pnQueryContextKey,
					  @pnUserIdentityId	= @pnUserIdentityId,
					  @psPresentationType = @psPresentationType
	
	Set @pnDefaultColumnsRowCount = @@Rowcount
	
End	

-- Populating Query dataset

If @nErrorCode = 0
Begin
	Set @sSQLString = "
	Select  Q.QUERYID		as 'QueryKey',
		" + dbo.fn_SqlTranslatedColumn('QUERY','QUERYNAME',null,'Q',@sLookupCulture,@pbCalledFromCentura) + "		as 'QueryName',
		" + dbo.fn_SqlTranslatedColumn('QUERY','DESCRIPTION',null,'Q',@sLookupCulture,@pbCalledFromCentura) + "		as 'Description',
		Q.CONTEXTID		as 'ContextKey',
		QP.PRESENTATIONTYPE		as 'PresentationType',
		QF.XMLFILTERCRITERIA	as 'XMLFilterCriteria',
		null			as 'AdoptFilterFromQueryKey',
		null			as 'AdoptColumnsFromQueryKey',
		CASE WHEN Q.PRESENTATIONID is null THEN cast(1 as bit) 
		     ELSE cast(0 as bit)
		END			as 'UsesDefaultPresentation',
		CASE WHEN Q.IDENTITYID is null THEN cast(1 as bit) 
		     ELSE cast(0 as bit)
		END 			as 'IsPublic',
		-- Since WorkBenches cannot process Centura reports as reports, ensure that report 
		-- related columns are returned as null (ReportTemplateName, ReportTitle, ReportToolKey, 
		-- ReportToolDescription, ExportFormatKey, ExportFormatDescription). 
		-- Applies when ReportToolKey = 9401.
		CASE WHEN QP.REPORTTOOL = 9401 
		     THEN NULL
		     ELSE QP.REPORTTEMPLATE
		END			as 'ReportTemplateName',
		CASE WHEN QP.REPORTTOOL = 9401 
		     THEN NULL
		     ELSE QP.REPORTTITLE	
		END			as 'ReportTitle',
		CASE WHEN QP.REPORTTOOL = 9401 
		     THEN NULL
		     ELSE QP.REPORTTOOL	
		END			as 'ReportToolKey',	
		CASE WHEN QP.REPORTTOOL = 9401 
		     THEN NULL
		     ELSE RTD.DESCRIPTION
		END			as 'ReportToolDescription',
		CASE WHEN QP.REPORTTOOL = 9401 
		     THEN NULL
		     ELSE QP.EXPORTFORMAT	
		END			as 'ExportFormatKey',	
		CASE WHEN QP.REPORTTOOL = 9401 
		     THEN NULL
		     ELSE EFD.DESCRIPTION	
		END			as 'ExportFormatDescription',	
		Q.GROUPID		as 'GroupKey',
		QG.GROUPNAME		as 'GroupName',
		     -- For external users, if any default public search exists for their access account 
		     -- then the current public seach should match that search. If no default public search 
		     -- exists for their access account, then the current public search should match any 
		     -- default public search
		CASE WHEN (Q.IDENTITYID is null and Q.QUERYID = isnull(QD3.QUERYID, QD1.QUERYID))
			   -- For internal users, if any default public search matches the current 
			   -- public search (IdentityId and AccessAccountId are null)
		     THEN cast(1 as bit)
		     ELSE cast(0 as bit)
		END			as 'IsDefaultSearch',
		CASE WHEN Q.QUERYID = QD2.QUERYID
		     THEN cast(1 as bit)
		     ELSE cast(0 as bit)
		END			as 'IsDefaultUserSearch',
		CASE WHEN (QP.ISDEFAULT = 1 and QP.IDENTITYID is not null)
		     THEN cast(1 as bit) 
		     ELSE cast(0 as bit)
		END			as 'IsDefaultUserPresentation',
		CASE WHEN QP.REPORTTOOL = 9401 
		     THEN NULL
		     ELSE QP.REPORTTEMPLATE + '.rdl'
		END			as 'ReportTemplateFileName',
		QP.FREEZECOLUMNID	as 'FreezeColumnKey'			
	from	QUERY Q
	left join QUERYFILTER QF	on (QF.FILTERID = Q.FILTERID)
	left join QUERYPRESENTATION QP	on (QP.PRESENTATIONID = Q.PRESENTATIONID)
	-- Get the ReportToolDescription 
	left join TABLECODES RTD	on (RTD.TABLECODE = QP.REPORTTOOL)
	-- Get the ExportFormatDescription
	left join TABLECODES EFD	on (EFD.TABLECODE = QP.EXPORTFORMAT)
	left join QUERYGROUP QG		on (QG.GROUPID = Q.GROUPID)
	left join QUERYDEFAULT QD1	on (QD1.CONTEXTID = Q.CONTEXTID 
					and (QD1.IDENTITYID is null and
					     Q.IDENTITYID is null and
					     QD1.ACCESSACCOUNTID is null and 
					     Q.ACCESSACCOUNTID is null))
	left join QUERYDEFAULT QD2	on (QD2.CONTEXTID = Q.CONTEXTID
					and QD2.IDENTITYID = @pnUserIdentityId)
	left join QUERYDEFAULT QD3	on (QD3.CONTEXTID = Q.CONTEXTID 
					and QD3.ACCESSACCOUNTID = @nAccessAccountID
					and QD3.IDENTITYID is null) 					 
	where	Q.QUERYID = @pnQueryKey"

	exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnQueryKey		int,
					  @pnUserIdentityId 	int,
					  @nAccessAccountID	int',					  
					  @pnQueryKey		= @pnQueryKey,
					  @pnUserIdentityId	= @pnUserIdentityId,
					  @nAccessAccountID	= @nAccessAccountID	

	Set @pnQueryRowCount = @@Rowcount
End

-- Populating SelectedColumns dataset

If @nErrorCode= 0
and @pnPresentationKey is not null
Begin
	Set @sSQLString = "
	Select  DISTINCT
		null as 'QueryKey',
		QC.COLUMNID		as 'ColumnKey',
		QC.DISPLAYSEQUENCE	as 'DisplaySequence',
		QC.SORTORDER		as 'SortOrder',
		QC.SORTDIRECTION	as 'SortDirection',
		QC.GROUPBYSEQUENCE	as 'GroupBySortOrder',
		QC.GROUPBYSORTDIR	as 'GroupBySortDirection',
		CASE WHEN QP.FREEZECOLUMNID	= QC.COLUMNID
			THEN cast(1 as bit)
			ELSE cast(0 as bit)
		END					as 'IsFreezeColumnIndex'
		from QUERYPRESENTATION QP 
		join QUERYCONTENT QC	on (QC.PRESENTATIONID = QP.PRESENTATIONID)
	        join QUERYCOLUMN QCC on (QCC.COLUMNID = QC.COLUMNID)
		join QUERYDATAITEM QDI on (QCC.DATAITEMID = QDI.DATAITEMID)	
		left join TOPICDATAITEMS TD1 on (TD1.DATAITEMID = QDI.DATAITEMID)
		left join dbo.fn_PermissionsGranted(@pnUserIdentityId, 'DATATOPIC', NULL, NULL, @dtToday) PG on (PG.ObjectIntegerKey = TD1.TOPICID)
	        where QP.PRESENTATIONID = @pnPresentationKey
	        and (PG.CanSelect = 1 or PG.CanSelect is null)				    
		order by 'DisplaySequence', 'SortOrder'"	
			
	exec @nErrorCode = sp_executesql @sSQLString,
					N'@pnPresentationKey	int,
					 @dtToday      datetime,
					 @pnUserIdentityId	int',					  
					 @pnPresentationKey	= @pnPresentationKey,
					 @dtToday      = @dtToday,
					 @pnUserIdentityId	= @pnUserIdentityId				

	Set @pnSelectedColumnsRowCount = @@Rowcount
End
Else
Begin
	Set @sSQLString = "
	Select  DISTINCT
		Q.QUERYID		as 'QueryKey',
		QC.COLUMNID		as 'ColumnKey',
		QC.DISPLAYSEQUENCE	as 'DisplaySequence',
		QC.SORTORDER		as 'SortOrder',
		QC.SORTDIRECTION	as 'SortDirection',
		QC.GROUPBYSEQUENCE	as 'GroupBySortOrder',
		QC.GROUPBYSORTDIR	as 'GroupBySortDirection',
		CASE WHEN QP.FREEZECOLUMNID	= QC.COLUMNID
			THEN cast(1 as bit)
			ELSE cast(0 as bit)
		END					as 'IsFreezeColumnIndex'
		from QUERY Q
		join QUERYPRESENTATION QP on (Q.PRESENTATIONID = QP.PRESENTATIONID)
		join QUERYCONTENT QC	on (QC.PRESENTATIONID = QP.PRESENTATIONID)
	        join QUERYCOLUMN QCC on (QCC.COLUMNID = QC.COLUMNID)
		join QUERYDATAITEM QDI on (QCC.DATAITEMID = QDI.DATAITEMID)	
		left join TOPICDATAITEMS TD1 on (TD1.DATAITEMID = QDI.DATAITEMID)
		left join dbo.fn_PermissionsGranted(@pnUserIdentityId, 'DATATOPIC', NULL, NULL, @dtToday) PG on (PG.ObjectIntegerKey = TD1.TOPICID)
	        where Q.QUERYID = @pnQueryKey	
	        and (PG.CanSelect = 1 or PG.CanSelect is null)		    
		order by 'DisplaySequence', 'SortOrder'"		
	
	exec @nErrorCode = sp_executesql @sSQLString,
					N'@pnQueryKey	int,					  
					  @dtToday      datetime,
					  @pnUserIdentityId	int',					  
					  @pnQueryKey	= @pnQueryKey,
					  @dtToday      = @dtToday,
					  @pnUserIdentityId = @pnUserIdentityId				

	Set @pnSelectedColumnsRowCount = @@Rowcount
End

	

Return @nErrorCode
GO

Grant execute on dbo.ipw_ListSearchData  to public
GO


