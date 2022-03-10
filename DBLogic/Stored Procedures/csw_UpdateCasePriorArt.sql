-----------------------------------------------------------------------------------------------------------------------------
-- Creation of csw_UpdateCasePriorArt									      
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[csw_UpdateCasePriorArt]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.csw_UpdateCasePriorArt.'
	Drop procedure [dbo].[csw_UpdateCasePriorArt]
End
Print '**** Creating Stored Procedure dbo.csw_UpdateCasePriorArt...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
-- Allow comparison of null values.
-- Procedure uses setting in place before it's created.
SET ANSI_NULLS OFF
GO

CREATE PROCEDURE dbo.csw_UpdateCasePriorArt
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pbCalledFromCentura	bit		= 0,
	@pnCaseKey		int,		-- Mandatory
	@pnPriorArtKey		int,		-- Mandatory
	@pnStatusKey		int		= null,
	@pdtUpdatedDate		datetime	= null,
	@pnOldStatusKey		int		= null,
	@pdtOldUpdatedDate	datetime	= null,
	@pbIsStatusKeyInUse	bit	 	= 0,
	@pbIsUpdatedDateInUse	bit	 	= 0
)
as
-- PROCEDURE:	csw_UpdateCasePriorArt
-- VERSION:	2
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Update CasePriorArt if the underlying values are as expected.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	-----------------------------------------------
-- 19 Feb 2008	AT	RFC5670	1	Procedure created.
-- 24 Mar 2011	JC	RFC6563	2	Change logic to update without using the old values

SET CONCAT_NULL_YIELDS_NULL OFF
-- Row counts required by the data adapter
SET NOCOUNT OFF
-- Reset so that next procedure gets the default.
SET ANSI_NULLS ON

Declare @nErrorCode	int
Declare @sSQLString 	nvarchar(4000)
Declare @sUpdateString 	nvarchar(4000)
Declare @sWhereString	nvarchar(4000)
Declare @sComma		nchar(1)
Declare @sAnd		nchar(5)

-- Initialise variables
Set @nErrorCode = 0
Set @sWhereString = CHAR(10)+" where "

If @nErrorCode = 0
Begin
	Set @sUpdateString = "Update CASESEARCHRESULT
			   set "

	Set @sWhereString = @sWhereString+CHAR(10)+"
		CASEID = @pnCaseKey and
		PRIORARTID = @pnPriorArtKey"

	If @pbIsStatusKeyInUse = 1
	Begin
		Set @sUpdateString = @sUpdateString+CHAR(10)+@sComma+"STATUS = @pnStatusKey"
		Set @sComma = ","
		Set @sAnd = " and "

		-- Automatically update the UPDATEDDATE
		if (@pdtOldUpdatedDate != @pdtUpdatedDate and @pbIsUpdatedDateInUse = 1)
		Begin
			-- Update with new param value passed in
			Set @sUpdateString = @sUpdateString+CHAR(10)+@sComma+"UPDATEDDATE = @pdtUpdatedDate"
		End
		else
		Begin
			-- Update with system date/time
			Set @sUpdateString = @sUpdateString+CHAR(10)+@sComma+"UPDATEDDATE = getdate()"
		End

	End

	Set @sSQLString = @sUpdateString + @sWhereString

	exec @nErrorCode=sp_executesql @sSQLString,
			      	N'
			@pnCaseKey		int,
			@pnPriorArtKey		int,
			@pnStatusKey		int,
			@pdtUpdatedDate		datetime,
			@pnOldStatusKey		int,
			@pdtOldUpdatedDate	datetime',
			@pnCaseKey	 	= @pnCaseKey,
			@pnPriorArtKey	 	= @pnPriorArtKey,
			@pnStatusKey	 	= @pnStatusKey,
			@pdtUpdatedDate	 	= @pdtUpdatedDate,
			@pnOldStatusKey	 	= @pnOldStatusKey,
			@pdtOldUpdatedDate	= @pdtOldUpdatedDate

End

Return @nErrorCode
GO

Grant execute on dbo.csw_UpdateCasePriorArt to public
GO