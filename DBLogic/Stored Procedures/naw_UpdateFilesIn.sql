-----------------------------------------------------------------------------------------------------------------------------
-- Creation of naw_UpdateFilesIn									      
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[naw_UpdateFilesIn]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.naw_UpdateFilesIn.'
	Drop procedure [dbo].[naw_UpdateFilesIn]
End
Print '**** Creating Stored Procedure dbo.naw_UpdateFilesIn...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
-- Allow comparison of null values.
-- Procedure uses setting in place before it's created.
SET ANSI_NULLS OFF
GO


CREATE PROCEDURE dbo.naw_UpdateFilesIn
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pbCalledFromCentura	bit		= 0,
	@pnNameKey		int,		-- Mandatory
	@psCountryCode		nvarchar(3),	-- Mandatory
	@psNotes		nvarchar(254)	= null,
	@psOldCountryCode	nvarchar(3),	-- Mandatory
	@psOldNotes		nvarchar(254)	= null,
	@pbIsCountryCodeInUse	bit	 	= 0,
	@pbIsNotesInUse		bit	 	= 0
)
as
-- PROCEDURE:	naw_UpdateFilesIn
-- VERSION:	1
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Update FilesIn if the underlying values are as expected.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	-------	-------	-----------------------------------------------
-- 11 Apr 2006	IB	RFC3762	1	Procedure created

SET CONCAT_NULL_YIELDS_NULL OFF
-- Row counts required by the data adapter
SET NOCOUNT OFF
-- Reset so that next procedure gets the default.
SET ANSI_NULLS ON

Declare @nErrorCode		int
Declare @sSQLString 		nvarchar(4000)
Declare @sUpdateString 		nvarchar(4000)
Declare @sWhereString		nvarchar(4000)
Declare @sComma			nchar(1)
Declare @sAnd			nchar(5)

-- Initialise variables
Set @nErrorCode = 0
Set @sWhereString = CHAR(10)+" where "

If @nErrorCode = 0
Begin
	If @psCountryCode != @psOldCountryCode
	Begin
		exec @nErrorCode = dbo.naw_DeleteFilesIn
			@pnUserIdentityId	= @pnUserIdentityId,
			@psCulture		= @psCulture,
			@pbCalledFromCentura	= @pbCalledFromCentura,
			@pnNameKey		= @pnNameKey,
			@psCountryCode		= @psOldCountryCode,
			@psOldNotes		= @psOldNotes,
			@pbIsNotesInUse		= @pbIsNotesInUse

		If @nErrorCode = 0
		Begin
			exec @nErrorCode = dbo.naw_InsertFilesIn
				@pnUserIdentityId	= @pnUserIdentityId,
				@psCulture		= @psCulture,
				@pbCalledFromCentura	= @pbCalledFromCentura,
				@pnNameKey		= @pnNameKey,
				@psCountryCode		= @psCountryCode,
				@psNotes		= @psNotes,
				@pbIsNotesInUse		= @pbIsNotesInUse
		End
	End
	Else
	Begin
		Set @sUpdateString = "Update FILESIN
				   set "
	
		Set @sWhereString = @sWhereString+CHAR(10)+"
			NAMENO = @pnNameKey"
			
		Set @sAnd = " and "
	
		If @pbIsCountryCodeInUse = 1
		Begin
			Set @sUpdateString = @sUpdateString+CHAR(10)+@sComma+"COUNTRYCODE = @psCountryCode"
			Set @sWhereString = @sWhereString+CHAR(10)+@sAnd+"COUNTRYCODE = @psOldCountryCode"
			Set @sComma = ","
		End
	
		If @pbIsNotesInUse = 1
		Begin
			Set @sUpdateString = @sUpdateString+CHAR(10)+@sComma+"NOTES = @psNotes"
			Set @sWhereString = @sWhereString+CHAR(10)+@sAnd+"NOTES = @psOldNotes"
			Set @sComma = ","
		End
	
		Set @sSQLString = @sUpdateString + @sWhereString
	
		exec @nErrorCode=sp_executesql @sSQLString,
				      	N'
				@pnNameKey		int,
				@psCountryCode		nvarchar(3),
				@psNotes		nvarchar(254),
				@psOldCountryCode	nvarchar(3),
				@psOldNotes		nvarchar(254)',
				@pnNameKey	 	= @pnNameKey,
				@psCountryCode	 	= @psCountryCode,
				@psNotes	 	= @psNotes,
				@psOldCountryCode	= @psOldCountryCode,
				@psOldNotes	 	= @psOldNotes
	End

End

Return @nErrorCode
GO

Grant execute on dbo.naw_UpdateFilesIn to public
GO