-----------------------------------------------------------------------------------------------------------------------------
-- Creation of qr_MaintainPresentation
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[qr_MaintainPresentation]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.qr_MaintainPresentation.'
	Drop procedure [dbo].[qr_MaintainPresentation]
End
Print '**** Creating Stored Procedure dbo.qr_MaintainPresentation...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
-- Allow comparison of null values.
-- Procedure uses setting in place before it's created. 
SET ANSI_NULLS OFF
GO


CREATE PROCEDURE dbo.qr_MaintainPresentation
(
	@pnPresentationKey		int		= null output,	-- Required for update
	@pnUserIdentityId		int,		-- Mandatory
	@psCulture			nvarchar(10) 	= null,
	@pnContextKey			int,		-- Mandatory
	@pnAdoptFromQueryKey		int	 	= null,		-- Indicates that the presentation on the identified query should be used
	@pbUsesDefaultPresentation	bit		= null,
	@pbIsPublic			bit		= null,
	@pbIsContextDefault		bit		= null,
	@psReportTemplateName		nvarchar(254)	= null,
	@psReportTitle			nvarchar(80)	= null,
	@pnReportToolKey		int		= null,	
	@pnExportFormatKey		int		= null,
	@pnFreezeColumnKey		int		= null,
	@psPresentationType		nvarchar(30) = null,
	@pbOldUsesDefaultPresentation	bit		= null,
	@pbOldIsPublic			bit		= null,
	@pbOldIsContextDefault		bit		= null,
	@psOldReportTemplateName	nvarchar(254)	= null,
	@psOldReportTitle		nvarchar(80)	= null,
	@pnOldReportToolKey		int		= null,	
	@pnOldExportFormatKey		int		= null,
	@pnOldFreezeColumnKey		int		= null
)
as
-- PROCEDURE:	qr_MaintainPresentation
-- VERSION:	8
-- DESCRIPTION:	Insert/update/adopt a query presentation.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 07 Dec 2003	JEK	RFC398	1	Procedure created
-- 19 Apr 2004	TM	RFC919	2	Add new parameters to be able to maintain new columns in the SearchData dataset.
-- 20 Jul 2004	TM	RFC578	3	Delete any existing default presentation first, and ensure correct operation 
--					when called with Presentation table information.
-- 21 Jul 2004 	TM 	RFC578	4	Remove @pbIsContextDefault, @psReportTemplateName, @psReportTitle, @pnReportToolKey,
--					and @pnExportFormatKey parameters when call qr_DeleteDefaultPresentation.   
-- 15 Sep 2004	TM	RFC1822	5	Use IDENT_CURRENT('table_name') instead of the @@IDENTITY to publish the key.
-- 20 Sep 2004 	TM	RFC1822	6	Implement SCOPE_IDENTITY() IDENT_CURRENT and move this logic inside the
--					SQL string executed by sp_executesql.
-- 20 Dec 2005	TM	RFC3221	7	Implement default searches by access account.
-- 03 Feb 2010	SF	RFC8483	8	Implement freeze column index and presentation type.
-- 19 Feb 2010	SF	RFC8483	9	update freeze column incorrect

SET CONCAT_NULL_YIELDS_NULL OFF
-- Row counts required by the data adapter
SET NOCOUNT OFF
-- Reset so that next procedure gets the default. 
SET ANSI_NULLS ON

Declare	@nErrorCode		int
Declare @sSQLString 		nvarchar(4000)

Declare @nAccessAccountID	int

-- Initialise variables
Set @nErrorCode 		= 0
Set @nAccessAccountID		= null
	
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
				
-- Reuse from another query
If @nErrorCode = 0
and @pnAdoptFromQueryKey is not null
Begin
	Set @sSQLString = " 
	select	@pnPresentationKey=P.PRESENTATIONID
	from	QUERY Q
	join	QUERYPRESENTATION P	on (P.PRESENTATIONID = Q.PRESENTATIONID)
	where	Q.QUERYID = @pnAdoptFromQueryKey"

	exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnPresentationKey	int	output,
					  @pnAdoptFromQueryKey	int',
					  @pnPresentationKey	= @pnPresentationKey	output,
					  @pnAdoptFromQueryKey	= @pnAdoptFromQueryKey
End
-- Create Default Presentation
Else If @nErrorCode = 0 
and @pbIsContextDefault = 1
Begin
	-- Delete any existing default presentation
	exec @nErrorCode = qr_DeleteDefaultPresentation
		@pnUserIdentityId		= @pnUserIdentityId,
		@psCulture			= @psCulture,
		@pnContextKey			= @pnContextKey,
		@psPresentationType	= @psPresentationType,
		@pbIsPublic			= @pbIsPublic

	-- Insert Default Presentation
	If @nErrorCode = 0 
	Begin
		Set @sSQLString = " 
		insert	QUERYPRESENTATION
			(CONTEXTID, 
			IDENTITYID, 
			ISDEFAULT,
			REPORTTEMPLATE,
			REPORTTITLE,
			REPORTTOOL,
			EXPORTFORMAT,
			FREEZECOLUMNID,
			PRESENTATIONTYPE)
		values	(@pnContextKey, 
			case when @pbIsPublic = 1 then null else @pnUserIdentityId end,
			1,
			@psReportTemplateName,
			@psReportTitle,
			@pnReportToolKey,
			@pnExportFormatKey,
			@pnFreezeColumnKey,
			@psPresentationType)

		Set @pnPresentationKey = SCOPE_IDENTITY()"
	
		exec @nErrorCode=sp_executesql @sSQLString,
						N'@pnPresentationKey	int		    OUTPUT,
						  @pnUserIdentityId	int,
						  @pnContextKey		int,
						  @pbIsPublic		bit,
						  @psReportTemplateName	nvarchar(254),
						  @psReportTitle	nvarchar(80),
						  @pnReportToolKey	int,
						  @pnExportFormatKey	int,
						  @pnFreezeColumnKey	int,
						  @psPresentationType	nvarchar(30)',
						  @pnPresentationKey	=@pnPresentationKey OUTPUT,
						  @pnUserIdentityId	= @pnUserIdentityId,
						  @pnContextKey		= @pnContextKey,
						  @pbIsPublic		= @pbIsPublic,
						  @psReportTemplateName = @psReportTemplateName,
						  @psReportTitle	= @psReportTitle,
						  @pnReportToolKey	= @pnReportToolKey,
						  @pnExportFormatKey	= @pnExportFormatKey,
						  @pnFreezeColumnKey	= @pnFreezeColumnKey,
						  @psPresentationType	= @psPresentationType 			
	End
End
-- Insert
Else If @nErrorCode = 0
and @pbUsesDefaultPresentation = 0
and (@pbOldUsesDefaultPresentation is null or
     @pbOldUsesDefaultPresentation = 1)
Begin
	Set @sSQLString = " 
	insert	QUERYPRESENTATION
		(CONTEXTID, 
		IDENTITYID, 
		ISDEFAULT,
		REPORTTEMPLATE,
		REPORTTITLE,
		REPORTTOOL,
		EXPORTFORMAT,
		ACCESSACCOUNTID,
		FREEZECOLUMNID,
		PRESENTATIONTYPE)
	values	(@pnContextKey, 
		case when @pbIsPublic = 1 then null else @pnUserIdentityId end,
		@pbIsContextDefault,
		@psReportTemplateName,
		@psReportTitle,
		@pnReportToolKey,
		@pnExportFormatKey,
		@nAccessAccountID,
		@pnFreezeColumnKey,
		@psPresentationType)

		Set @pnPresentationKey = SCOPE_IDENTITY()"

	exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnPresentationKey	int		     OUTPUT,
					  @pnUserIdentityId	int,
					  @pnContextKey		int,
					  @pbIsPublic		bit,
					  @pbIsContextDefault	bit,
					  @psReportTemplateName	nvarchar(254),
					  @psReportTitle	nvarchar(80),
					  @pnReportToolKey	int,
					  @pnExportFormatKey	int,
					  @nAccessAccountID	int,
					  @pnFreezeColumnKey	int,
					  @psPresentationType nvarchar(30)',
					  @pnPresentationKey	= @pnPresentationKey OUTPUT,
					  @pnUserIdentityId	= @pnUserIdentityId,
					  @pnContextKey		= @pnContextKey,
					  @pbIsPublic		= @pbIsPublic,
					  @pbIsContextDefault	= @pbIsContextDefault,
					  @psReportTemplateName = @psReportTemplateName,
					  @psReportTitle	= @psReportTitle,
					  @pnReportToolKey	= @pnReportToolKey,
					  @pnExportFormatKey	= @pnExportFormatKey,
					  @nAccessAccountID	= @nAccessAccountID,
					  @pnFreezeColumnKey = @pnFreezeColumnKey, 
					  @psPresentationType = @psPresentationType
		

End
-- Update
Else If @nErrorCode = 0
and @pbOldUsesDefaultPresentation = 0
and @pbUsesDefaultPresentation = 0
and (@pbOldIsPublic		<> @pbIsPublic or
     @pbOldIsContextDefault 	<> @pbIsContextDefault or
     @psOldReportTemplateName 	<> @psReportTemplateName or
     @psOldReportTitle 		<> @psReportTitle or
     @pnOldReportToolKey 	<> @pnReportToolKey or
     @pnOldExportFormatKey 	<> @pnExportFormatKey or
     @pnOldFreezeColumnKey  <> @pnFreezeColumnKey)
and @pnPresentationKey is not null
Begin 
	Set @sSQLString = " 
	update	QUERYPRESENTATION
	set	IDENTITYID 	= case when @pbIsPublic = 1 then null else @pnUserIdentityId end,
		ISDEFAULT 	= @pbIsContextDefault,
		REPORTTEMPLATE 	= @psReportTemplateName,
		REPORTTITLE 	= @psReportTitle,
		REPORTTOOL 	= @pnReportToolKey,
		EXPORTFORMAT 	= @pnExportFormatKey,
		ACCESSACCOUNTID	= @nAccessAccountID,
		FREEZECOLUMNID = @pnFreezeColumnKey,
		PRESENTATIONTYPE = @psPresentationType  	
	where	PRESENTATIONID 	= @pnPresentationKey
	and	((IDENTITYID is null and @pbOldIsPublic = 1) or
		 (IDENTITYID = @pnUserIdentityId and @pbOldIsPublic = 0))
	and	ISDEFAULT 	= @pbOldIsContextDefault
	and 	REPORTTEMPLATE 	= @psOldReportTemplateName
	and 	REPORTTITLE 	= @psOldReportTitle
	and	REPORTTOOL 	= @pnOldReportToolKey
	and 	EXPORTFORMAT 	= @pnOldExportFormatKey"

	exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnUserIdentityId		int,
					  @pnPresentationKey		int,
					  @pbIsPublic			bit,
					  @pbIsContextDefault		bit,
					  @psReportTemplateName		nvarchar(254),
					  @psReportTitle		nvarchar(80),
					  @pnReportToolKey		int,
					  @pnExportFormatKey		int, 
					  @nAccessAccountID		int,
					  @pbOldIsPublic		bit,
					  @pbOldIsContextDefault	bit,
					  @psOldReportTemplateName	nvarchar(254),
					  @psOldReportTitle		nvarchar(80),
					  @pnOldReportToolKey		int,
					  @pnOldExportFormatKey		int,
					  @pnFreezeColumnKey		int,
					  @psPresentationType		nvarchar(30)',
					  @pnUserIdentityId		= @pnUserIdentityId,
					  @pnPresentationKey		= @pnPresentationKey,
					  @pbIsPublic			= @pbIsPublic,
					  @pbIsContextDefault		= @pbIsContextDefault,
					  @psReportTemplateName		= @psReportTemplateName,
					  @psReportTitle		= @psReportTitle,
					  @pnReportToolKey		= @pnReportToolKey,
					  @pnExportFormatKey		= @pnExportFormatKey,
					  @nAccessAccountID		= @nAccessAccountID,
					  @pbOldIsPublic		= @pbOldIsPublic,
					  @pbOldIsContextDefault	= @pbOldIsContextDefault,
					  @psOldReportTemplateName	= @psOldReportTemplateName,
					  @psOldReportTitle		= @psOldReportTitle,
					  @pnOldReportToolKey		= @pnOldReportToolKey,
					  @pnOldExportFormatKey		= @pnOldExportFormatKey,
					  @pnFreezeColumnKey		= @pnFreezeColumnKey,
					  @psPresentationType		= @psPresentationType 

End

Return @nErrorCode
GO

Grant execute on dbo.qr_MaintainPresentation to public
GO
