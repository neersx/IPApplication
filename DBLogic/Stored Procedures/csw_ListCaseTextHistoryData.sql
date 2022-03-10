-----------------------------------------------------------------------------------------------------------------------------
-- Creation of csw_ListCaseTextHistoryData 
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[csw_ListCaseTextHistoryData]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.csw_ListCaseTextHistoryData.'
	Drop procedure [dbo].[csw_ListCaseTextHistoryData]
	Print '**** Creating Stored Procedure dbo.csw_ListCaseTextHistoryData...'
	Print ''
End
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.csw_ListCaseTextHistoryData 
(
	@pnRowCount		int		= null output,
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pnCaseKey		int,		-- Mandatory
	@psTextTypeKey 		nvarchar(2),	-- Mandatory
	@psClass 		nvarchar(11)	= null,
	@pnLanguageKey 		int		= null,
	@pbIsExternalUser 	bit,		-- Mandatory 		
	@pbCalledFromCentura	bit		= 0
)
AS
-- PROCEDURE:	csw_ListCaseTextHistoryData 
-- VERSION:	5
-- SCOPE:	Inpro.Net
-- DESCRIPTION:	Populates CaseTextHistoryData dataset.

-- MODIFICATIONS :
-- Date		Who	Number	Version	Change
-- ------------	-------	------	-------	----------------------------------------------- 
-- 18 Oct 2004  TM	RFC1156	1	Procedure created
-- 29 Nov 2004	TM	RFC1156	2	Correct comments and improve performance.
-- 15 May 2005	JEK	RFC2508	3	Extract @sLookupCulture and pass to translation instead of @psCulture
-- 04 Aug 2006	AU	RFC4260	4	Fixed error in TextHistory.Text column
-- 1 Mar 2007	PY	SQA14425 5	Reserved word [language]

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare @nErrorCode 	int

Declare @sSQLString	nvarchar(4000)

Declare @sLookupCulture		nvarchar(10)

set @sLookupCulture = dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)

Set	@nErrorCode      = 0
Set 	@pnRowCount	 = 0

	
-- Populating CaseText datatable
If @nErrorCode = 0
Begin
	Set @sSQLString = "
	Select  distinct
		C.IRN 			as CaseReference,
		@psClass		as Class,
		FUTT.TEXTDESCRIPTION	as TextTypeDescription,
		"+dbo.fn_SqlTranslatedColumn('TABLECODES','DESCRIPTION',null,'TC',@sLookupCulture,@pbCalledFromCentura)+"
				  	as [Language]	
	from CASES C
	join dbo.fn_FilterUserTextTypes(@pnUserIdentityId,@sLookupCulture,@pbIsExternalUser, @pbCalledFromCentura) FUTT 
				on (FUTT.TEXTTYPE = @psTextTypeKey)	
	join CASETEXT CT	on ( CT.CASEID = @pnCaseKey
				and  CT.TEXTTYPE = @psTextTypeKey
				and (CT.LANGUAGE = @pnLanguageKey 
				 or (CT.LANGUAGE is null and @pnLanguageKey is null))
				and (CT.CLASS = @psClass 
				 or (CT.CLASS is null and @psClass is null)))				
	left join TABLECODES TC	on (TC.TABLECODE = @pnLanguageKey)
	where C.CASEID = @pnCaseKey"

	exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnCaseKey		int,	
					  @psTextTypeKey 	nvarchar(2),
					  @psClass		nvarchar(11),
					  @pnLanguageKey	int,
					  @pbIsExternalUser	bit,
					  @pbCalledFromCentura	bit,
					  @pnUserIdentityId	int,
					  @sLookupCulture	nvarchar(10)',
					  @pnCaseKey		= @pnCaseKey,
					  @psTextTypeKey	= @psTextTypeKey,
					  @psClass		= @psClass,
					  @pnLanguageKey	= @pnLanguageKey,
					  @pbIsExternalUser	= @pbIsExternalUser,
					  @pbCalledFromCentura	= @pbCalledFromCentura,
					  @pnUserIdentityId	= @pnUserIdentityId,
					  @sLookupCulture	= @sLookupCulture			  	
End

-- Populating TextHistory datatable
If @nErrorCode = 0
Begin
	Set @sSQLString = "
	Select CT.MODIFIEDDATE	as DateModified,
	ISNULL(CT.TEXT, CT.SHORTTEXT)	
				as Text
	from dbo.fn_FilterUserTextTypes(@pnUserIdentityId,@sLookupCulture,@pbIsExternalUser, @pbCalledFromCentura) FUTT 				
	join CASETEXT CT	on ( CT.CASEID = @pnCaseKey
				and  CT.TEXTTYPE = @psTextTypeKey
				and (CT.LANGUAGE = @pnLanguageKey 
				 or (CT.LANGUAGE is null and @pnLanguageKey is null))
				and (CT.CLASS = @psClass 
				 or (CT.CLASS is null and @psClass is null)))	
	where CT.CASEID = @pnCaseKey
	and   FUTT.TEXTTYPE = @psTextTypeKey
	and  (CT.MODIFIEDDATE is not null 
	 or ISNULL(CT.SHORTTEXT,CT.TEXT) is not null)
	order by DateModified desc"

	exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnCaseKey		int,	
					  @psTextTypeKey 	nvarchar(2),
					  @psClass		nvarchar(11),
					  @pnLanguageKey	int,
					  @pbIsExternalUser	bit,
					  @pbCalledFromCentura	bit,
					  @pnUserIdentityId	int,
					  @sLookupCulture	nvarchar(10)',
					  @pnCaseKey		= @pnCaseKey,
					  @psTextTypeKey	= @psTextTypeKey,
					  @psClass		= @psClass,
					  @pnLanguageKey	= @pnLanguageKey,
					  @pbIsExternalUser	= @pbIsExternalUser,
					  @pbCalledFromCentura	= @pbCalledFromCentura,
					  @pnUserIdentityId	= @pnUserIdentityId,
					  @sLookupCulture	= @sLookupCulture			  	

	Set @pnRowCount = @@Rowcount
End


Return @nErrorCode
GO

Grant execute on dbo.csw_ListCaseTextHistoryData to public
GO
