-----------------------------------------------------------------------------------------------------------------------------
-- Creation of crm_UpdateLead									      
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[crm_UpdateLead]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.crm_UpdateLead.'
	Drop procedure [dbo].[crm_UpdateLead]
End
Print '**** Creating Stored Procedure dbo.crm_UpdateLead...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
-- Allow comparison of null values.
-- Procedure uses setting in place before it's created.
SET ANSI_NULLS OFF
GO


CREATE PROCEDURE dbo.crm_UpdateLead
(
	@pnUserIdentityId		int,		-- Mandatory
	@psCulture			nvarchar(10) 	= null,
	@pbCalledFromCentura		bit		= 0,
	@pnNameKey			int,	-- Mandatory
	@pnLeadStatusKey		int		 = null,
	@pnLeadSourceKey		int		 = null,
	@pnEstimatedRevenueLocal	decimal(11,2)		 = null,
	@pnEstimatedRevenue		decimal(11,2)		 = null,
	@psEstimatedRevenueCurrencyCode	nvarchar(3)		 = null,
	@psComments			nvarchar(4000)		 = null,
	@pnOldLeadStatusKey		int		 = null,
	@pnOldLeadSourceKey		int		 = null,
	@pnOldEstimatedRevenueLocal	decimal(11,2)		 = null,
	@pnOldEstimatedRevenue		decimal(11,2)		 = null,
	@psOldEstimatedRevenueCurrencyCode	nvarchar(3)		 = null,
	@psOldComments			nvarchar(4000)		 = null,
	@pbIsLeadStatusKeyInUse		bit	 = 0,
	@pbIsLeadSourceKeyInUse		bit	 = 0,
	@pbIsEstimatedRevenueLocalInUse	bit	 = 0,
	@pbIsEstimatedRevenueInUse	bit	 = 0,
	@pbIsEstimatedRevenueCurrencyCodeInUse		bit	 = 0,
	@pbIsCommentsInUse		bit	 = 0
)
as
-- PROCEDURE:	crm_UpdateLead
-- VERSION:	3
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Update Lead if the underlying values are as expected.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	-----------------------------------------------
-- 18 Jun 2008	SF	RFC6508	1	Procedure created
-- 26 Jun 2008	SF	RFC6508	2	Enlarge Comments column to 4000 characters, 
--								Remove EMPLOYEENO and MODIFIEDDATE
-- 21 Aug 2008	AT	RFC6894	3	Added Estimated Revenue Local.

SET CONCAT_NULL_YIELDS_NULL OFF
-- Row counts required by the data adapter
SET NOCOUNT OFF
-- Reset so that next procedure gets the default.
SET ANSI_NULLS ON

Declare @nErrorCode		int
Declare @sSQLString 		nvarchar(4000)
Declare @sInsertString 	nvarchar(4000)
Declare @sValuesString		nvarchar(4000)
Declare @sUpdateString 	nvarchar(4000)
Declare @sWhereString		nvarchar(4000)
Declare @sComma		nchar(1)
Declare @sAnd			nchar(5)

-- Initialise variables
Set @nErrorCode = 0
Set @sAnd = ' and ' 
Set @sWhereString = CHAR(10)+" where "

If @nErrorCode = 0
Begin
	Set @sUpdateString = "Update LEADDETAILS
			   set "

	Set @sWhereString = @sWhereString+CHAR(10)+"
		NAMENO = @pnNameKey
"

	If @pbIsLeadSourceKeyInUse = 1
	Begin
		Set @sUpdateString = @sUpdateString+CHAR(10)+@sComma+"LEADSOURCE = @pnLeadSourceKey"
		Set @sWhereString = @sWhereString+CHAR(10)+@sAnd+"LEADSOURCE = @pnOldLeadSourceKey"
		Set @sComma = ","
	End

	If @pbIsEstimatedRevenueLocalInUse = 1
	Begin
		Set @sUpdateString = @sUpdateString+CHAR(10)+@sComma+"ESTIMATEDREVLOCAL = @pnEstimatedRevenueLocal"
		Set @sWhereString = @sWhereString+CHAR(10)+@sAnd+"ESTIMATEDREVLOCAL = @pnOldEstimatedRevenueLocal"
		Set @sComma = ","
	End

	If @pbIsEstimatedRevenueInUse = 1
	Begin
		Set @sUpdateString = @sUpdateString+CHAR(10)+@sComma+"ESTIMATEDREV = @pnEstimatedRevenue"
		Set @sWhereString = @sWhereString+CHAR(10)+@sAnd+"ESTIMATEDREV = @pnOldEstimatedRevenue"
		Set @sComma = ","
	End

	If @pbIsEstimatedRevenueCurrencyCodeInUse = 1
	Begin
		Set @sUpdateString = @sUpdateString+CHAR(10)+@sComma+"ESTREVCURRENCY = @psEstimatedRevenueCurrencyCode"
		Set @sWhereString = @sWhereString+CHAR(10)+@sAnd+"ESTREVCURRENCY = @psOldEstimatedRevenueCurrencyCode"
		Set @sComma = ","
	End

	If @pbIsCommentsInUse = 1
	Begin
		Set @sUpdateString = @sUpdateString+CHAR(10)+@sComma+"COMMENTS = @psComments"
		Set @sWhereString = @sWhereString+CHAR(10)+@sAnd+"COMMENTS = @psOldComments"
		Set @sComma = ","
	End

	Set @sSQLString = @sUpdateString + @sWhereString

	exec @nErrorCode=sp_executesql @sSQLString,
			      	N'
			@pnNameKey		int,
			@pnLeadSourceKey		int,
			@pnEstimatedRevenueLocal	decimal(11,2),
			@pnEstimatedRevenue		decimal(11,2),
			@psEstimatedRevenueCurrencyCode		nvarchar(3),
			@psComments		nvarchar(254),
			@pnOldLeadSourceKey		int,
			@pnOldEstimatedRevenueLocal	decimal(11,2),
			@pnOldEstimatedRevenue		decimal(11,2),
			@psOldEstimatedRevenueCurrencyCode		nvarchar(3),
			@psOldComments		nvarchar(4000)',
			@pnNameKey	 = @pnNameKey,
			@pnLeadSourceKey	 = @pnLeadSourceKey,
			@pnEstimatedRevenueLocal = @pnEstimatedRevenueLocal,
			@pnEstimatedRevenue	 = @pnEstimatedRevenue,
			@psEstimatedRevenueCurrencyCode	 = @psEstimatedRevenueCurrencyCode,
			@psComments	 = @psComments,
			@pnOldLeadSourceKey	 = @pnOldLeadSourceKey,
			@pnOldEstimatedRevenueLocal	= @pnOldEstimatedRevenueLocal,
			@pnOldEstimatedRevenue	 = @pnOldEstimatedRevenue,
			@psOldEstimatedRevenueCurrencyCode	 = @psOldEstimatedRevenueCurrencyCode,
			@psOldComments	 = @psOldComments


End

If @nErrorCode = 0
and @pbIsLeadStatusKeyInUse = 1
and @pnLeadStatusKey <> @pnOldLeadStatusKey
Begin

	/* If LeadStatusKey has been changed, insert a new LEADSTATUSHISTORY row */
	Set @sValuesString = CHAR(10)+" values ("
	Set @sInsertString = "Insert into LEADSTATUSHISTORY
				("


	Set @sComma = ","
	Set @sInsertString = @sInsertString+CHAR(10)+"
			NAMENO
			"

	Set @sValuesString = @sValuesString+CHAR(10)+"
			@pnNameKey
			"

	If @pbIsLeadStatusKeyInUse = 1
	Begin
		Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"LEADSTATUS"
		Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@pnLeadStatusKey"
		Set @sComma = ","
	End
	
	Set @sInsertString = @sInsertString+CHAR(10)+")"
	Set @sValuesString = @sValuesString+CHAR(10)+")"

	Set @sSQLString = @sInsertString + @sValuesString

	exec @nErrorCode=sp_executesql @sSQLString,
		      		N'
			@pnNameKey				int,
			@pnLeadStatusKey		int',
			@pnNameKey	 = @pnNameKey,
			@pnLeadStatusKey	 = @pnLeadStatusKey
End


Return @nErrorCode
GO

Grant execute on dbo.crm_UpdateLead to public
GO