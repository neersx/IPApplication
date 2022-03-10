-----------------------------------------------------------------------------------------------------------------------------
-- Creation of qr_DeleteQuery
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[qr_DeleteQuery]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.qr_DeleteQuery.'
	Drop procedure [dbo].[qr_DeleteQuery]
End
Print '**** Creating Stored Procedure dbo.qr_DeleteQuery...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
-- Allow comparison of null values.
-- Procedure uses setting in place before it's created. 
SET ANSI_NULLS OFF
GO


CREATE PROCEDURE dbo.qr_DeleteQuery
(
	@pnUserIdentityId		int,		-- Mandatory
	@psCulture			nvarchar(10) 	= null,
	@pnQueryKey			int,		-- Mandatory
	@pnContextKey			int,		-- Mandatory
	@psOldQueryName			nvarchar(50)	= null,
	@psOldQueryDescription		nvarchar(254)	= null,
	@ptOldXMLFilterCriteria		ntext		= null,
	@pbOldUsesDefaultPresentation	bit		= null,
	@pbOldIsPublic			bit		= null,	
	@psOldReportTemplateName	nvarchar(254)	= null,
	@psOldReportTitle		nvarchar(80)	= null,
	@pnOldReportToolKey		int		= null,	
	@pnOldExportFormatKey		int		= null,	
	@pnOldGroupKey			int		= null	
)
as
-- PROCEDURE:	qr_DeleteQuery
-- VERSION:	4
-- DESCRIPTION:	Delete a query, and its corresponding filter/presentation if necessary.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 07 Dec 2003	JEK	RFC398	1	Procedure created
-- 15 Apr 2004 	TM	RFC917	2	Use fn_IsNtextEqual() to compare ntext strings.
-- 20 Apr 2004	TM	RFC919	3	Add new parameters to be able to maintain new columns in the SearchData dataset.
-- 28 Sep 2004	TM	RFC1854	4	Correct the logic extracting the old filter and presentation keys. 


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

-- Initialise variables
Set @nErrorCode 		= 0

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
					N'@nOldFilterKey		int			output,
					  @nOldPresentationKey		int			output,
					  @pnUserIdentityId		int,
					  @pnQueryKey			int,
					  @ptOldXMLFilterCriteria 	ntext,
					  @pbOldIsPublic		bit,
					  @psOldReportTemplateName 	nvarchar(254),
					  @psOldReportTitle		nvarchar(80),
					  @pnOldReportToolKey		int,
					  @pnOldExportFormatKey		int,
				 	  @pnOldGroupKey		int',
					  @nOldFilterKey		= @nOldFilterKey 	output,
					  @nOldPresentationKey		= @nOldPresentationKey 	output,
					  @pnUserIdentityId		= @pnUserIdentityId,
					  @pnQueryKey			= @pnQueryKey,
					  @ptOldXMLFilterCriteria 	= @ptOldXMLFilterCriteria,
					  @pbOldIsPublic		= @pbOldIsPublic,
					  @psOldReportTemplateName	= @psOldReportTemplateName,
					  @psOldReportTitle		= @psOldReportTitle,
					  @pnOldReportToolKey		= @pnOldReportToolKey,
					  @pnOldExportFormatKey		= @pnOldExportFormatKey,
					  @pnOldGroupKey		= @pnOldGroupKey 
End

If @nErrorCode = 0
Begin
	Set @sSQLString = " 
	delete	QUERY
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
					  @psOldQueryName	nvarchar(50),
					  @psOldQueryDescription nvarchar(254),
					  @pbOldIsPublic	bit,
					  @nOldFilterKey	int,
					  @nOldPresentationKey	int,
					  @pnOldGroupKey	int',
					  @pnUserIdentityId	= @pnUserIdentityId,
					  @pnQueryKey		= @pnQueryKey,
					  @psOldQueryName	= @psOldQueryName,
					  @psOldQueryDescription = @psOldQueryDescription,
					  @pbOldIsPublic	= @pbOldIsPublic,
					  @nOldFilterKey	= @nOldFilterKey,
					  @nOldPresentationKey	= @nOldPresentationKey,
					  @pnOldGroupKey	= @pnOldGroupKey

End

-- Delete any orphaned filter criteria
If @nErrorCode = 0
and @nOldFilterKey is not null
Begin
	exec @nErrorCode = qr_DeleteFilter
		@pnUserIdentityId 	= @pnUserIdentityId,
		@psCulture		= @psCulture,
		@pnFilterKey		= @nOldFilterKey
End

-- Delete any orphaned presentation
If @nErrorCode = 0
and @nOldPresentationKey is not null
Begin
	exec @nErrorCode = qr_DeletePresentation
		@pnUserIdentityId 	= @pnUserIdentityId,
		@psCulture		= @psCulture,
		@pnPresentationKey	= @nOldPresentationKey
End

Return @nErrorCode
GO

Grant execute on dbo.qr_DeleteQuery to public
GO