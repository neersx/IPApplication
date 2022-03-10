-----------------------------------------------------------------------------------------------------------------------------
-- Creation of crm_InsertLead									      
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[crm_InsertLead]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.crm_InsertLead.'
	Drop procedure [dbo].[crm_InsertLead]
End
Print '**** Creating Stored Procedure dbo.crm_InsertLead...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.crm_InsertLead
(
	@pnUserIdentityId		int,		-- Mandatory
	@psCulture			nvarchar(10) 	= null,
	@pbCalledFromCentura		bit		= 0,
	@pnNameKey			int,	-- Mandatory.
	@pnLeadStatusKey		int		 = null,
	@pnLeadSourceKey		int		 = null,
	@pnEstimatedRevenueLocal	decimal(11,2)		 = null,
	@pnEstimatedRevenue		decimal(11,2)		 = null,
	@psEstimatedRevenueCurrencyCode	nvarchar(3)		 = null,
	@psComments			nvarchar(4000)		 = null,
	@pbIsLeadStatusKeyInUse		bit	 = 0,
	@pbIsLeadSourceKeyInUse		bit	 = 0,
	@pbIsEstimatedRevenueLocalInUse	bit	 = 0,
	@pbIsEstimatedRevenueInUse	bit	 = 0,
	@pbIsEstimatedRevenueCurrencyCodeInUse		bit	 = 0,
	@pbIsCommentsInUse		bit	 = 0
)
as
-- PROCEDURE:	crm_InsertLead
-- VERSION:	3
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Insert Lead.

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

Declare @nErrorCode		int
Declare @sSQLString 		nvarchar(4000)
Declare @sInsertString 	nvarchar(4000)
Declare @sValuesString		nvarchar(4000)
Declare @sComma		nchar(1)

-- Initialise variables
Set @nErrorCode = 0
Set @sValuesString = CHAR(10)+" values ("

If @nErrorCode = 0
Begin
	Set @sInsertString = "Insert into LEADDETAILS
				("


	Set @sComma = ","
	Set @sInsertString = @sInsertString+CHAR(10)+"
			NAMENO
			"

	Set @sValuesString = @sValuesString+CHAR(10)+"
			@pnNameKey
			"

	If @pbIsLeadSourceKeyInUse = 1
	Begin
		Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"LEADSOURCE"
		Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@pnLeadSourceKey"
		Set @sComma = ","
	End

	If @pbIsEstimatedRevenueLocalInUse = 1
	Begin
		Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"ESTIMATEDREVLOCAL"
		Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@pnEstimatedRevenueLocal"
		Set @sComma = ","
	End

	If @pbIsEstimatedRevenueInUse = 1
	Begin
		Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"ESTIMATEDREV"
		Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@pnEstimatedRevenue"
		Set @sComma = ","
	End

	If @pbIsEstimatedRevenueCurrencyCodeInUse = 1
	Begin
		Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"ESTREVCURRENCY"
		Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@psEstimatedRevenueCurrencyCode"
		Set @sComma = ","
	End

	If @pbIsCommentsInUse = 1
	Begin
		Set @sInsertString = @sInsertString+CHAR(10)+@sComma+"COMMENTS"
		Set @sValuesString = @sValuesString+CHAR(10)+@sComma+"@psComments"
		Set @sComma = ","
	End

	Set @sInsertString = @sInsertString+CHAR(10)+")"
	Set @sValuesString = @sValuesString+CHAR(10)+")"

	Set @sSQLString = @sInsertString + @sValuesString

	exec @nErrorCode=sp_executesql @sSQLString,
			      	N'
			@pnNameKey		int,
			@pnLeadSourceKey		int,
			@pnEstimatedRevenueLocal	decimal(11,2),
			@pnEstimatedRevenue		decimal(11,2),
			@psEstimatedRevenueCurrencyCode		nvarchar(3),
			@psComments		nvarchar(254)',
			@pnNameKey	 = @pnNameKey,
			@pnLeadSourceKey	 = @pnLeadSourceKey,
			@pnEstimatedRevenueLocal = @pnEstimatedRevenueLocal,
			@pnEstimatedRevenue	 = @pnEstimatedRevenue,
			@psEstimatedRevenueCurrencyCode	 = @psEstimatedRevenueCurrencyCode,
			@psComments	 = @psComments

End

If @nErrorCode = 0
Begin

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

Grant execute on dbo.crm_InsertLead to public
GO