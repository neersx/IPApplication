-----------------------------------------------------------------------------------------------------------------------------
-- Creation of qr_UpdateQuery
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[qr_UpdateQuery]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.qr_UpdateQuery.'
	Drop procedure [dbo].[qr_UpdateQuery]
End
Print '**** Creating Stored Procedure dbo.qr_UpdateQuery...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
-- Allow comparison of null values.
-- Procedure uses setting in place before it's created. 
SET ANSI_NULLS OFF
GO


CREATE PROCEDURE dbo.qr_UpdateQuery
(
	@pnUserIdentityId		int,		-- Mandatory
	@psCulture			nvarchar(10) 	= null,
	@pnQueryKey			int,		-- Mandatory
	@pnContextKey			int,		-- Mandatory
	@pnAdoptFilterFromQueryKey	int	 	= null,		-- Indicates that the filter on the identified query should be used
	@pnAdoptColumnsFromQueryKey	int	 	= null,		-- Indicates that the presentation on the identified query should be used
	@psQueryName			nvarchar(50)	= null,
	@psQueryDescription		nvarchar(254)	= null,
	@ptXMLFilterCriteria		ntext		= null,
	@pbUsesDefaultPresentation	bit		= null,
	@pbIsPublic			bit		= null,
	@psReportTemplateName		nvarchar(254)	= null,
	@psReportTitle			nvarchar(80)	= null,
	@pnReportToolKey		int		= null,	
	@pnExportFormatKey		int		= null,	
	@pnGroupKey			int		= null,	
	@pbIsDefaultSearch		bit		= null,		-- indicates whether this query is public default search.  	
	@pbIsDefaultUserSearch		bit		= null,	-- indicates whether this query is default user search. 
	@pnFreezeColumnKey		int = null,
	@psOldQueryName			nvarchar(50)	= null,
	@psOldQueryDescription		nvarchar(254)	= null,
	@ptOldXMLFilterCriteria		ntext		= null,
	@pbOldUsesDefaultPresentation	bit		= null,
	@pbOldIsPublic			bit		= null,
	@psOldReportTemplateName	nvarchar(254)	= null,
	@psOldReportTitle		nvarchar(80)	= null,
	@pnOldReportToolKey		int		= null,	
	@pnOldExportFormatKey		int		= null,	
	@pnOldGroupKey			int		= null,
	@pbOldIsDefaultSearch		bit		= null,
	@pbOldIsDefaultUserSearch		bit		= null,
	@pnOldFreezeColumnKey	int = null
)
as
-- PROCEDURE:	qr_UpdateQuery
-- VERSION:	10
-- DESCRIPTION:	Add a new query, returning the generated key.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 07 Dec 2003	JEK	RFC398	1	Procedure created
-- 15 Apr 2004 	TM	RFC917	2	Use fn_IsNtextEqual() to compare ntext strings.
-- 19 Apr 2004	TM	RFC919	3	Add new parameters to be able to maintain new columns in the SearchData dataset.
-- 20 Jul 2004	TM	RFC1543	4	Add new @pbIsDefaultSearch and @pbOldIsDefaultSearch parameters. Perform Insert 
--					Default Search or Delete Default Search as required. Correct the logic extracting 
--					the old filter and presentation keys. 
-- 21 Dec 2005	TM	RFC3221	5	Implement default searches by access account.
-- 13 Mar 2009	PS  RFC7200 6   Save private user search
-- 19 Feb 2010	SF	RFC8483	7	Save freeze column index
-- 05 Jun 2013	DV	R13454	8	Added check for duplicate search name
-- 23 Jul 2013  SW      DR224   9       Modified the check on duplicate search name  
-- 8  Aug 2013  SW      DR224   10      Added the check for IsPublic for duplicate search name     

SET CONCAT_NULL_YIELDS_NULL OFF
-- Row counts required by the data adapter
SET NOCOUNT OFF
-- Reset so that next procedure gets the default. 
SET ANSI_NULLS ON

declare	@nErrorCode		int
declare @sSQLString 		nvarchar(4000)
declare @nFilterKey		int
declare @nPresentationKey	int
declare @nOldFilterKey		int
declare @nOldPresentationKey	int
declare @nIdentityKey		int
declare @nAccessAccountID	int
declare @sAlertXML      nvarchar(max)

-- Initialise variables
Set @nErrorCode 		= 0
Set @nAccessAccountID		= null

If @psQueryName	<> @psOldQueryName and exists (Select 1 From QUERY where QUERYNAME = @psQueryName and CONTEXTID = @pnContextKey and (IDENTITYID = @pnUserIdentityId or (@pbIsPublic = 1 and IDENTITYID is null)))
Begin	
	Set @sAlertXML = dbo.fn_GetAlertXML('IP141', 'Search Name already exists. Enter a new name for the search.',
										null, null, null, null, null)
	RAISERROR(@sAlertXML, 14, 1)
	Set @nErrorCode = @@ERROR
End

If @nErrorCode = 0
Begin
	Set @sSQLString = "
	Select	@nAccessAccountID = ACCOUNTID
	from USERIDENTITY
	where IDENTITYID = @pnUserIdentityId
	and   ISEXTERNALUSER = 1
	and   @pbIsPublic = 1"

	exec @nErrorCode = sp_executesql @sSQLString,
				N'@nAccessAccountID		int			output,
				  @pnUserIdentityId		int,
				  @pbIsPublic			bit',
				  @nAccessAccountID		= @nAccessAccountID	output,
				  @pnUserIdentityId		= @pnUserIdentityId,
				  @pbIsPublic			= @pbIsPublic
End

-- Locate the old filter and presentation keys
If @nErrorCode = 0
Begin
	Set @sSQLString = " 
	select	@nOldFilterKey 		= F.FILTERID,
		@nOldPresentationKey 	= P.PRESENTATIONID
	from	QUERY Q
	left join QUERYPRESENTATION P	on (P.PRESENTATIONID = Q.PRESENTATIONID)
	left join QUERYFILTER F		on (F.FILTERID = Q.FILTERID)
	where	QUERYID = @pnQueryKey
	-- Use the fn_IsNtextEqual() function to compare ntext strings
	and     ( dbo.fn_IsNtextEqual(F.XMLFILTERCRITERIA, @ptOldXMLFilterCriteria) = 1 )	
	and	((Q.IDENTITYID is null and @pbOldIsPublic = 1) or
		 (Q.IDENTITYID = @pnUserIdentityId and @pbOldIsPublic = 0))
	and 	P.REPORTTEMPLATE	= @psOldReportTemplateName
	and 	P.REPORTTITLE		= @psOldReportTitle
	and	P.REPORTTOOL		= @pnOldReportToolKey
	and	P.EXPORTFORMAT		= @pnOldExportFormatKey
	and 	Q.GROUPID		= @pnOldGroupKey"

	exec @nErrorCode=sp_executesql @sSQLString,
					N'@nOldFilterKey		int		output,
					  @nOldPresentationKey		int		output,
					  @pnUserIdentityId		int,
					  @pnQueryKey			int,
					  @ptOldXMLFilterCriteria 	ntext,
					  @pbOldIsPublic		bit,
					  @psOldReportTemplateName 	nvarchar(254),
					  @psOldReportTitle		nvarchar(80),
					  @pnOldReportToolKey		int,
					  @pnOldExportFormatKey		int,
				 	  @pnOldGroupKey		int',
					  @nOldFilterKey		= @nOldFilterKey output,
					  @nOldPresentationKey		= @nOldPresentationKey output,
					  @pnUserIdentityId		= @pnUserIdentityId,
					  @pnQueryKey			= @pnQueryKey,
					  @ptOldXMLFilterCriteria 	= @ptOldXMLFilterCriteria,
					  @pbOldIsPublic		= @pbOldIsPublic,
					  @psOldReportTemplateName	= @psOldReportTemplateName,
					  @psOldReportTitle		= @psOldReportTitle,
					  @pnOldReportToolKey		= @pnOldReportToolKey,
					  @pnOldExportFormatKey		= @pnOldExportFormatKey,
					  @pnOldGroupKey		= @pnOldGroupKey 

	Set @nFilterKey = @nOldFilterKey
	Set @nPresentationKey = @nOldPresentationKey
End
-- Filter criteria has been removed
If @pnAdoptFilterFromQueryKey is null
and @ptXMLFilterCriteria is null
and @ptOldXMLFilterCriteria is not null
Begin
	Set @nFilterKey = null
End
-- Filter criteria has been added or changed.
Else If @nErrorCode = 0
and (@pnAdoptFilterFromQueryKey is not null or
     @ptXMLFilterCriteria is not null or
     @ptOldXMLFilterCriteria is not null)
Begin
	exec @nErrorCode = qr_MaintainFilter
		@pnFilterKey		= @nFilterKey	output,
		@pnUserIdentityId	= @pnUserIdentityId,
		@psCulture		= @psCulture,
		@pnContextKey		= @pnContextKey,
		@pnAdoptFromQueryKey	= @pnAdoptFilterFromQueryKey,
		@ptXMLFilterCriteria	= @ptXMLFilterCriteria,
		@ptOldXMLFilterCriteria	= @ptOldXMLFilterCriteria

End
Else
Begin
	Set @nFilterKey = @nOldFilterKey
End

-- Presentation has been removed.
If @pbUsesDefaultPresentation = 1
and @pbOldUsesDefaultPresentation = 0
Begin
	Set @nPresentationKey = null
End
-- Presentation has been added or changed
Else If @nErrorCode = 0
and (
	(@pnAdoptColumnsFromQueryKey is not null)
    or
	(@pbUsesDefaultPresentation = 0) and
	(@pbOldUsesDefaultPresentation <> @pbUsesDefaultPresentation or
	 @pbOldIsPublic <> @pbIsPublic or
	 @psOldReportTemplateName <> @psReportTemplateName or
	 @psOldReportTitle <> @psReportTitle or
	 @pnOldReportToolKey <> @pnReportToolKey or
	 @pnOldExportFormatKey <> @pnExportFormatKey or
	 @pnOldFreezeColumnKey <> @pnFreezeColumnKey)
    )
Begin
	exec @nErrorCode = qr_MaintainPresentation
		@pnPresentationKey		= @nPresentationKey output,
		@pnUserIdentityId		= @pnUserIdentityId,
		@psCulture			= @psCulture,
		@pnContextKey			= @pnContextKey,
		@pnAdoptFromQueryKey		= @pnAdoptColumnsFromQueryKey,
		@pbUsesDefaultPresentation	= @pbUsesDefaultPresentation,
		@pbIsPublic			= @pbIsPublic,
		@psReportTemplateName		= @psReportTemplateName,
		@psReportTitle			= @psReportTitle,
		@pnReportToolKey		= @pnReportToolKey,
		@pnExportFormatKey		= @pnExportFormatKey,
		@pbIsContextDefault		= 0,		-- not implemented yet
		@pbOldUsesDefaultPresentation	= @pbOldUsesDefaultPresentation,
		@pbOldIsPublic			= @pbOldIsPublic,
		@psOldReportTemplateName	= @psOldReportTemplateName,
		@psOldReportTitle		= @psOldReportTitle,
		@pnOldReportToolKey 		= @pnOldReportToolKey,
	 	@pnOldExportFormatKey		= @pnOldExportFormatKey,
		@pbOldIsContextDefault		= 0,		-- not implemented yet,
		@pnFreezeColumnKey			= @pnFreezeColumnKey,
		@pnOldFreezeColumnKey		= @pnOldFreezeColumnKey

End
Else
Begin
	Set @nPresentationKey = @nOldPresentationKey
End

If @nErrorCode = 0
and (@psOldQueryName		<> @psQueryName or
     @psOldQueryDescription	<> @psQueryDescription or
     @pbOldIsPublic		<> @pbIsPublic or
     @nOldFilterKey		<> @nFilterKey or
     @nOldPresentationKey	<> @nPresentationKey or
     @pnOldGroupKey		<> @pnGroupKey)
Begin
	Set @sSQLString = " 
	update	QUERY
	set 	IDENTITYID	= case when @pbIsPublic = 1 then null else @pnUserIdentityId end,
		QUERYNAME	= @psQueryName,
		DESCRIPTION	= @psQueryDescription,
		PRESENTATIONID	= @nPresentationKey,
		FILTERID	= @nFilterKey,
		GROUPID		= @pnGroupKey,
		ACCESSACCOUNTID	= @nAccessAccountID
	where	QUERYID		= @pnQueryKey
	and	((IDENTITYID is null and @pbOldIsPublic = 1) or
		 (IDENTITYID = @pnUserIdentityId and @pbOldIsPublic = 0))
	and	QUERYNAME 	= @psOldQueryName
	and	DESCRIPTION	= @psOldQueryDescription
	and	PRESENTATIONID	= @nOldPresentationKey
	and	FILTERID	= @nOldFilterKey
	and 	GROUPID		= @pnOldGroupKey"

	exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnUserIdentityId	int,
					  @pnQueryKey		int,
					  @psQueryName		nvarchar(50),
					  @psQueryDescription	nvarchar(254),
					  @pbIsPublic		bit,
					  @nFilterKey		int,
					  @nPresentationKey	int,
					  @pnGroupKey		int,
					  @nAccessAccountID	int,
					  @psOldQueryName	nvarchar(50),
					  @psOldQueryDescription nvarchar(254),
					  @pbOldIsPublic	bit,
					  @nOldFilterKey	int,
					  @nOldPresentationKey	int,
					  @pnOldGroupKey 	int',
					  @pnUserIdentityId	= @pnUserIdentityId,
					  @pnQueryKey		= @pnQueryKey,
					  @psQueryName		= @psQueryName,
					  @psQueryDescription	= @psQueryDescription,
					  @pbIsPublic		= @pbIsPublic,
					  @nFilterKey		= @nFilterKey,
					  @nPresentationKey	= @nPresentationKey,
					  @pnGroupKey		= @pnGroupKey,
					  @nAccessAccountID	= @nAccessAccountID,
					  @pnOldGroupKey	= @pnOldGroupKey,
					  @psOldQueryName	= @psOldQueryName,
					  @psOldQueryDescription = @psOldQueryDescription,
					  @pbOldIsPublic	= @pbOldIsPublic,
					  @nOldFilterKey	= @nOldFilterKey,
					  @nOldPresentationKey	= @nOldPresentationKey
End

-- Delete any orphaned filter criteria
If @nErrorCode = 0
and @nFilterKey <> @nOldFilterKey
and @nOldFilterKey is not null
Begin
	exec @nErrorCode = qr_DeleteFilter
		@pnUserIdentityId 	= @pnUserIdentityId,
		@psCulture		= @psCulture,
		@pnFilterKey		= @nOldFilterKey
End

-- Delete any orphaned presentation
If @nErrorCode = 0
and @nPresentationKey <> @nOldPresentationKey
and @nOldPresentationKey is not null
Begin
	exec @nErrorCode = qr_DeletePresentation
		@pnUserIdentityId 	= @pnUserIdentityId,
		@psCulture		= @psCulture,
		@pnPresentationKey	= @nOldPresentationKey
End

-- Remove Default Search
If @nErrorCode = 0
and ((@pbIsDefaultSearch = 0 and @pbOldIsDefaultSearch = 1) or (@pbIsDefaultUserSearch = 0 and @pbOldIsDefaultUserSearch = 1))
Begin
	-- If @pbOldIsDefaultSearch = 1 and @pbOldIsPublic = 1, set IdentityKey to null otherwise current user’s identity:
	Set @nIdentityKey = CASE WHEN ((@pbOldIsDefaultSearch = 1) and (@pbOldIsPublic = 1)) THEN NULL  ELSE @pnUserIdentityId END

	exec @nErrorCode = qr_DeleteQueryDefault
		@pnUserIdentityId	= @pnUserIdentityId,
		@psCulture		= @psCulture,
		@pnQueryKey		= @pnQueryKey,
		@pnIdentityKey		= @nIdentityKey
End
Else
-- Add Default Search
If @nErrorCode = 0
and ((@pbIsDefaultSearch = 1 and @pbOldIsDefaultSearch = 0) or (@pbIsDefaultUserSearch = 1 and @pbOldIsDefaultUserSearch = 0))
Begin
	-- If @pbIsDefaultSearch = 1 and @pbIsPublic = 1 then set IdentityKey to null otherwise current user’s identity:
		Set @nIdentityKey = CASE WHEN ((@pbIsPublic = 1) and (@pbIsDefaultSearch = 1)) THEN NULL ELSE @pnUserIdentityId END

	exec @nErrorCode = qr_InsertQueryDefault
		@pnUserIdentityId	= @pnUserIdentityId,
		@psCulture		= @psCulture,
		@pnQueryKey		= @pnQueryKey,
		@pnContextKey		= @pnContextKey,
		@pnIdentityKey		= @nIdentityKey,
		@pnAccessAccountKey	= @nAccessAccountID
End

Return @nErrorCode
GO

Grant execute on dbo.qr_UpdateQuery to public
GO