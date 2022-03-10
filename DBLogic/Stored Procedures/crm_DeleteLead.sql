
-----------------------------------------------------------------------------------------------------------------------------
-- Creation of crm_DeleteLead									      
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[crm_DeleteLead]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.crm_DeleteLead.'
	Drop procedure [dbo].[crm_DeleteLead]
End
Print '**** Creating Stored Procedure dbo.crm_DeleteLead...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
-- Allow comparison of null values.
-- Procedure uses setting in place before it's created.
SET ANSI_NULLS OFF
GO


CREATE PROCEDURE dbo.crm_DeleteLead
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pbCalledFromCentura	bit		= 0,
	@pnNameKey		int,	-- Mandatory
	@pnOldLeadStatusKey	int		 = null,
	@pnOldLeadSourceKey	int		 = null,
	@pnOldEstimatedRevenueLocal	decimal(11,2)		 = null,
	@pnOldEstimatedRevenue		decimal(11,2)		 = null,
	@psOldEstimatedRevenueCurrencyCode	nvarchar(3)		 = null,
	@psOldComments	nvarchar(4000)		 = null,
	@pbIsLeadStatusKeyInUse		bit	 = 0,
	@pbIsLeadSourceKeyInUse		bit	 = 0,
	@pbIsEstimatedRevenueLocalInUse		bit	 = 0,
	@pbIsEstimatedRevenueInUse		bit	 = 0,
	@pbIsEstimatedRevenueCurrencyCodeInUse		bit	 = 0,
	@pbIsCommentsInUse		bit	 = 0
)
as
-- PROCEDURE:	crm_DeleteLead
-- VERSION:	3
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Delete Lead if the underlying values are as expected.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	-----------------------------------------------
-- 18 Jun 2008	SF	RFC6508	1	Procedure created
-- 26 Jun 2008	SF	RFC6508	2	Enlarge Comments column to 4000 characters
-- 21 Aug 2008	AT	RFC6894	3	Add Estimated Revenue Local.

SET CONCAT_NULL_YIELDS_NULL OFF
-- Row counts required by the data adapter
SET NOCOUNT OFF
-- Reset so that next procedure gets the default.
SET ANSI_NULLS ON

Declare @nErrorCode		int
Declare @sSQLString 		nvarchar(4000)
Declare @sDeleteString		nvarchar(4000)
Declare @sAnd			nchar(5)

-- Initialise variables
Set @nErrorCode = 0
Set @sAnd = ' and ' 

If @nErrorCode = 0
Begin
	Set @sDeleteString = "Delete from LEADDETAILS
			   where "

	Set @sDeleteString = @sDeleteString+CHAR(10)+"
		NAMENO = @pnNameKey
"

	If @pbIsLeadSourceKeyInUse = 1
	Begin
		Set @sDeleteString = @sDeleteString+CHAR(10)+@sAnd+"LEADSOURCE = @pnOldLeadSourceKey"
	End

	If @pbIsEstimatedRevenueLocalInUse = 1
	Begin
		Set @sDeleteString = @sDeleteString+CHAR(10)+@sAnd+"ESTIMATEDREVLOCAL = @pnOldEstimatedRevenueLocal"
	End

	If @pbIsEstimatedRevenueInUse = 1
	Begin
		Set @sDeleteString = @sDeleteString+CHAR(10)+@sAnd+"ESTIMATEDREV = @pnOldEstimatedRevenue"
	End

	If @pbIsEstimatedRevenueCurrencyCodeInUse = 1
	Begin
		Set @sDeleteString = @sDeleteString+CHAR(10)+@sAnd+"ESTREVCURRENCY = @psOldEstimatedRevenueCurrencyCode"
	End

	If @pbIsCommentsInUse = 1
	Begin
		Set @sDeleteString = @sDeleteString+CHAR(10)+@sAnd+"COMMENTS = @psOldComments"
	End

	exec @nErrorCode=sp_executesql @sDeleteString,
			      	N'
			@pnNameKey		int,
			@pnOldLeadSourceKey		int,
			@pnOldEstimatedRevenueLocal	decimal(11,2),
			@pnOldEstimatedRevenue		decimal(11,2),
			@psOldEstimatedRevenueCurrencyCode		nvarchar(3),
			@psOldComments		nvarchar(4000)',
			@pnNameKey	 = @pnNameKey,
			@pnOldLeadSourceKey	 = @pnOldLeadSourceKey,
			@pnOldEstimatedRevenueLocal = @pnOldEstimatedRevenueLocal,
			@pnOldEstimatedRevenue	 = @pnOldEstimatedRevenue,
			@psOldEstimatedRevenueCurrencyCode	 = @psOldEstimatedRevenueCurrencyCode,
			@psOldComments	 = @psOldComments


End

Return @nErrorCode
GO

Grant execute on dbo.crm_DeleteLead to public
GO