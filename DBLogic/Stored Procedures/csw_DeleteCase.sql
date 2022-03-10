-----------------------------------------------------------------------------------------------------------------------------
-- Creation of csw_DeleteCase
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[csw_DeleteCase]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.csw_DeleteCase.'
	Drop procedure [dbo].[csw_DeleteCase]
End
Print '**** Creating Stored Procedure dbo.csw_DeleteCase...' 
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
-- Allow comparison of null values.
-- Procedure uses setting in place before it's created. 
SET ANSI_NULLS OFF
GO

CREATE PROCEDURE dbo.csw_DeleteCase
(
	@pnUserIdentityId		int,		-- Mandatory
	@psCulture			nvarchar(10) 	= null,	
	@pbCalledFromCentura		bit		= 0,
	@pnCaseKey			int		-- Mandatory
)
as
-- PROCEDURE:	csw_DeleteCase
-- VERSION:	9
-- DESCRIPTION:	Delete a case if the underlying values are as expected.

-- MODIFICATIONS :
-- Date		Who	Change	Version Description
-- -----------	-------	-------	------- ----------------------------------------------- 
-- 29 Sep 2005	TM		    1	    Procedure created
-- 17 Jul 2006	AU	RFC3394	    2	    Delete RELATEDCASE rows that reference the Case
--				    	    being deleted i.e. RELATEDCAES.RELATEDCASEID = @pnCaseKey
-- 19/03/2008	vql	SQA14773    3	    Make PurchaseOrderNo nvarchar(80)
-- 06/06/2008	Ash RFC5438    4	    Maintaining data in another culture.
-- 17 Nov 2008	AT	RFC7137	5	Cater for CRM Cases.
-- 13 Oct 2009	ASH	RFC100047	6	Remove the code which was implemented as a part of RFC5438.
-- 28 Oct 2010	ASH	RFC9788     7       Maintain Title in foreign languages.
-- 11 Apr 2014  MS      R31303      8       Remove unused old params
-- 19 May 2015  MS      R34423      9       Add , before @sTitle


SET CONCAT_NULL_YIELDS_NULL OFF
-- Row counts required by the data adapter
SET NOCOUNT OFF
-- Reset so that next procedure gets the default. 
SET ANSI_NULLS ON

declare	@nErrorCode	int
declare @sDeleteString	nvarchar(4000)
declare @sSQLString 	nvarchar(4000)
Declare @sLookupCulture	nvarchar(10)
Declare @nTranCountStart int
Declare @nTitleTID	int
Declare @sTitle         nvarchar(254)

Declare @sCaseType	nvarchar(3)

-- Initialise variables
Set @nErrorCode 	= 0

If @nErrorCode = 0
Begin
	Set @sLookupCulture = dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)
End

If @nErrorCode = 0
Begin
	
	Set @sDeleteString = "
	Delete RELATEDCASE
	where RELATEDCASEID = @pnCaseKey"

	exec @nErrorCode=sp_executesql @sDeleteString,
				      N'@pnCaseKey		int',
					@pnCaseKey		= @pnCaseKey

End

If @nErrorCode = 0
Begin
	Set @sSQLString = "Select @sCaseType = CASETYPE from CASES where CASEID = @pnCaseKey"

	exec @nErrorCode=sp_executesql @sSQLString,
				      N'@sCaseType	nvarchar(3) output,
					@pnCaseKey	int',
					@sCaseType	= @sCaseType output,
					@pnCaseKey	= @pnCaseKey
End

if exists(select * from CASETYPE WHERE CASETYPE = @sCaseType and CRMONLY = 1)
Begin
	
	If @nErrorCode = 0
	Begin
		
		Set @sDeleteString = "
		Delete FROM CRMCASESTATUSHISTORY
		where CASEID = @pnCaseKey"
	
		exec @nErrorCode=sp_executesql @sDeleteString,
					      N'@pnCaseKey		int',
						@pnCaseKey		= @pnCaseKey
	
	End
	
	If @nErrorCode = 0
	Begin
		
		Set @sDeleteString = "
		Delete FROM OPPORTUNITY
		where CASEID = @pnCaseKey"
	
		exec @nErrorCode=sp_executesql @sDeleteString,
					      N'@pnCaseKey		int',
						@pnCaseKey		= @pnCaseKey
	
	End
	
	If @nErrorCode = 0
	Begin
		
		Set @sDeleteString = "
		Delete FROM MARKETING
		where CASEID = @pnCaseKey"
	
		exec @nErrorCode=sp_executesql @sDeleteString,
					      N'@pnCaseKey		int',
						@pnCaseKey		= @pnCaseKey
	
	End
End

-- Culture is different to DB culture
If @nErrorCode = 0 and @sLookupCulture is not null
Begin
	-- Get the TIDs if the exist
	Set @sSQLString = "
		Select	@nTitleTID = TITLE_TID,
		        @sTitle = TITLE
		From CASES
		Where CASEID = @pnCaseKey"

	exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnCaseKey	int,
					@sTitle         nvarchar(254)   output,       
					@nTitleTID	int             output',
					@pnCaseKey      = @pnCaseKey,
					@sTitle         = @sTitle       output,
					@nTitleTID      = @nTitleTID	output

	If @nErrorCode = 0
	Begin
		Set @sSQLString = " 
			Delete TRANSLATEDTEXT 
			Where	SHORTTEXT = @sTitle and TID = @nTitleTID and CULTURE =@psCulture "

		exec @nErrorCode=sp_executesql @sSQLString,
					N'@nTitleTID		int,
                                          @psCulture		nvarchar(10),
					  @sTitle		nvarchar(254)',
					  @psCulture		= @psCulture,
					  @nTitleTID 		= @nTitleTID,
					  @sTitle		= @sTitle

	End
End


If @nErrorCode = 0
Begin
	Set @sDeleteString = "
	Delete from CASES 
	where CASEID = @pnCaseKey"

	exec @nErrorCode=sp_executesql @sDeleteString,
				      N'@pnCaseKey		int',
					@pnCaseKey		= @pnCaseKey
					
End



Return @nErrorCode
GO

Grant execute on dbo.csw_DeleteCase to public
GO