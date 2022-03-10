-----------------------------------------------------------------------------------------------------------------------------
-- Creation of qr_InsertQuery
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[qr_InsertQuery]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.qr_InsertQuery.'
	Drop procedure [dbo].[qr_InsertQuery]
End
Print '**** Creating Stored Procedure dbo.qr_InsertQuery...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
-- Allow comparison of null values.
-- Procedure uses setting in place before it's created. 
SET ANSI_NULLS OFF
GO


CREATE PROCEDURE dbo.qr_InsertQuery
(
	@pnQueryKey			int = null	output,		-- Included to provide a standard interface
	@pnUserIdentityId		int,		-- Mandatory
	@psCulture			nvarchar(10) 	= null,
	@psQueryName			nvarchar(50)	= null,
	@psQueryDescription		nvarchar(254)	= null,
	@pnContextKey			int,		-- Mandatory
	@ptXMLFilterCriteria		ntext		= null,
	@pnAdoptFilterFromQueryKey	int	 	= null,		-- Indicates that the filter on the identified query should be used
	@pnAdoptColumnsFromQueryKey	int	 	= null,		-- Indicates that the presentation on the identified query should be used
	@pbUsesDefaultPresentation	bit		= null,
	@pbIsPublic			bit		= null,
	@pbIsClientServer 		bit 		= 0,
	@psReportTemplateName		nvarchar(254)	= null,
	@psReportTitle			nvarchar(80)	= null,
	@pnReportToolKey		int		= null,	
	@pnExportFormatKey		int		= null,	
	@pnGroupKey			int		= null,	
	@pbIsReadOnly			bit		= 0,
	@pbIsDefaultSearch		bit		= null,		-- indicates whether this query is public default search.  
	@pbIsDefaultUserSearch          bit             = null,
	@pnFreezeColumnKey		int	        = null,
	@pbReturnNewKey                 bit             = 1     -- indicate whether the key for the new query should be returned
)
as
-- PROCEDURE:	qr_InsertQuery
-- VERSION:	17
-- DESCRIPTION:	Add a new query, returning the generated key.

-- MODIFICATIONS :
-- Date		Who	Change		Version	Description
-- -----------	-------	--------	-------	----------------------------------------------- 
-- 07 Dec 2003	JEK	RFC398		1	Procedure created
-- 12 Dec 2003	JEK	RFC398		2	To allow quick implementation, updates will be performed
--						by deleting any existing query and then inserting the new query.
-- 15 Dec 2003	JEK	RFC398		3	Change to use qr_DeleteQueryByKey.
-- 26 Feb 2004	TM	RFC1053		4	Implement a new @pbIsClientServer bit parameter that defaults to 0.  
--						Write this data to the Query table.	
-- 19 Apr 2004	TM	RFC919		5	Add new parameters to be able to maintain new columns in the SearchData dataset.
-- 01 Jul 2004	IB	SQA10125	6	Implemented @pbIsReadOnly parameter, defaulted it to 0.
-- 20 Jul 2004	TM	RFC1543		7	Add new @pbIsDefaultSearch parameter. If it set to 1, perform 
--						Insert Default Search.
-- 25 Aug 2004	TM	RFC828		8	Remove the call to qr_DeleteQueryByKey.
-- 15 Sep 2004	TM	RFC1822		9	Use IDENT_CURRENT('table_name') instead of the @@IDENTITY to publish the key.
-- 20 Sep 2004 	TM	RFC1822		10	Implement SCOPE_IDENTITY() IDENT_CURRENT and move this logic inside the
--						SQL string executed by sp_executesql.
-- 20 Dec 2005	TM	RFC3221		11	Implement default searches by access account.
-- 19 Feb 2010	SF	RFC8483		12	save freeze column index
-- 12 Mar 2009	PS      RFC7200         13      save default user search.
-- 17 Mar 2010  LP      RFC8801         14      Allow control over whether new query key should be returned or not.
-- 05 Jun 2013	DV	R13454		15	Added check for duplicate search name
-- 23 Jul 2013  SW      DR224           16      Modified the check on duplicate search name
-- 8  Aug 2013  SW      DR224           17      Added the check for IsPublic for duplicate search name 


SET CONCAT_NULL_YIELDS_NULL OFF
-- Row counts required by the data adapter
SET NOCOUNT OFF
-- Reset so that next procedure gets the default. 
SET ANSI_NULLS ON

declare	@nErrorCode		int
declare @sSQLString 		nvarchar(4000)
declare @nFilterKey		int
declare @nPresentationKey	int
declare @nIdentityKey		int
declare @nAccessAccountID	int
declare @sAlertXML      nvarchar(max)


-- Initialise variables
Set @nErrorCode 		= 0
Set @nAccessAccountID		= null

Set @nErrorCode 		= 0
Set @nAccessAccountID		= null

If exists (Select 1 From QUERY where QUERYNAME = @psQueryName and CONTEXTID = @pnContextKey and (IDENTITYID = @pnUserIdentityId or (@pbIsPublic = 1 and IDENTITYID is null)))
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

-- Add filter criteria if necessary
If @nErrorCode = 0
and (@pnAdoptFilterFromQueryKey is not null or
     @ptXMLFilterCriteria is not null)
Begin
	exec @nErrorCode = qr_MaintainFilter
		@pnFilterKey		= @nFilterKey	output,
		@pnUserIdentityId	= @pnUserIdentityId,
		@psCulture		= @psCulture,
		@pnContextKey		= @pnContextKey,
		@pnAdoptFromQueryKey	= @pnAdoptFilterFromQueryKey,
		@ptXMLFilterCriteria	= @ptXMLFilterCriteria
End

-- Add presentation if necessary
If @nErrorCode = 0
and (@pnAdoptColumnsFromQueryKey is not null or
     @pbUsesDefaultPresentation = 0)
Begin
	exec @nErrorCode = qr_MaintainPresentation
		@pnPresentationKey		= @nPresentationKey output,
		@pnUserIdentityId		= @pnUserIdentityId,
		@psCulture			= @psCulture,
		@pnContextKey			= @pnContextKey,
		@pnAdoptFromQueryKey		= @pnAdoptColumnsFromQueryKey,
		@pbUsesDefaultPresentation	= @pbUsesDefaultPresentation,
		@pbIsPublic			= @pbIsPublic,
		@pbIsContextDefault		= 0,		-- not implemented yet
		@psReportTemplateName		= @psReportTemplateName,
		@psReportTitle			= @psReportTitle,
		@pnReportToolKey		= @pnReportToolKey,
		@pnExportFormatKey		= @pnExportFormatKey,
		@pnFreezeColumnKey		= @pnFreezeColumnKey
End

-- Add query
If @nErrorCode = 0
Begin
	Set @sSQLString = " 
	insert	QUERY
		(CONTEXTID,
		IDENTITYID,
		QUERYNAME,
		DESCRIPTION,
		PRESENTATIONID,
		FILTERID,
		ISCLIENTSERVER,
		GROUPID,
		ISREADONLY,
		ACCESSACCOUNTID)
	values	(@pnContextKey,
		case when @pbIsPublic = 1 then null else @pnUserIdentityId end,
		@psQueryName,
		@psQueryDescription,
		@nPresentationKey,
		@nFilterKey,
		@pbIsClientServer,
		@pnGroupKey,
		@pbIsReadOnly,
		@nAccessAccountID)

		Set @pnQueryKey = SCOPE_IDENTITY()"

	exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnQueryKey		int		OUTPUT,
					  @pnUserIdentityId	int,
					  @psQueryName		nvarchar(50),
					  @psQueryDescription	nvarchar(254),
					  @pnContextKey		int,
					  @pbIsPublic		bit,
					  @nFilterKey		int,
					  @nPresentationKey	int,
					  @pbIsClientServer	bit,
					  @pnGroupKey		int,
					  @pbIsReadOnly		bit,
					  @nAccessAccountID	int',
					  @pnQueryKey		= @pnQueryKey	OUTPUT,
					  @pnUserIdentityId	= @pnUserIdentityId,
					  @psQueryName		= @psQueryName,
					  @psQueryDescription	= @psQueryDescription,
					  @pnContextKey		= @pnContextKey,
					  @pbIsPublic		= @pbIsPublic,
					  @nFilterKey		= @nFilterKey,
					  @nPresentationKey	= @nPresentationKey,
					  @pbIsClientServer	= @pbIsClientServer,
					  @pnGroupKey		= @pnGroupKey,
					  @pbIsReadOnly		= @pbIsReadOnly,
					  @nAccessAccountID	= @nAccessAccountID	

	-- Publish the generated key to update the data adapter
	If @pbReturnNewKey = 1
	Begin
	        select @pnQueryKey as QueryKey
	End
End

-- If defaulting is requested then insert new default.
If @nErrorCode = 0
and (@pbIsDefaultSearch = 1 or @pbIsDefaultUserSearch = 1)
Begin
	-- If @pbIsDefaultSearch = 0, set IdentityKey to current user's identity otherwise null:
	Set @nIdentityKey = CASE WHEN @pbIsDefaultSearch = 0 THEN @pnUserIdentityId ELSE NULL END

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

Grant execute on dbo.qr_InsertQuery to public
GO
