-----------------------------------------------------------------------------------------------------------------------------
-- Creation of prw_InsertCaseSearchResult
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[prw_InsertCaseSearchResult]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.prw_InsertCaseSearchResult.'
	Drop procedure [dbo].[prw_InsertCaseSearchResult]
End
Print '**** Creating Stored Procedure dbo.prw_InsertCaseSearchResult...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.prw_InsertCaseSearchResult
(
	@pnUserIdentityId		int,		-- Mandatory
	@psCulture			nvarchar(10) 	= null,
	@pnPriorArtKey			int,
	@pnCaseKey			int,
	@pnStatusKey			int		= null,
	@pbCaseFirstLinkedTo		bit		= 0

)
as
-- PROCEDURE:	prw_InsertCaseSearchResult
-- VERSION:	1
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Insert a Case Search Result

-- MODIFICATIONS :
-- Date			Who		Change	Version	Description
-- -----------	-------	------	-------	-----------------------------------------------
-- 2 Mar 2011	JC		RFC6563	1		Procedure created

SET CONCAT_NULL_YIELDS_NULL OFF
-- Row counts required by the data adapter
SET NOCOUNT OFF

Declare @nErrorCode			int
Declare @sSQLString 			nvarchar(4000)
Declare @dToday				datetime
Declare @nCount				int
Declare @nDefaultStatusKey		int

-- Initialise variables
Set @nErrorCode			= 0
Set @dToday			= getDate()
Set @nCount			= 0
Set @nDefaultStatusKey		= null

If @nErrorCode = 0 
Begin
	Set @sSQLString = "select @nCount = count(*)
		from	CASESEARCHRESULT
		where	PRIORARTID		= @pnPriorArtKey
		and	CASEID			= @pnCaseKey"
	
	exec @nErrorCode=sp_executesql @sSQLString,
	      		N'
		@pnPriorArtKey	int,
		@pnCaseKey	int,
		@nCount		int OUTPUT',
		@pnPriorArtKey	= @pnPriorArtKey,
		@pnCaseKey	= @pnCaseKey,
		@nCount		= @nCount OUTPUT		
		
End

If @nErrorCode = 0 and @nCount > 0
Begin
	If @pnStatusKey is null
	Begin
		Set @sSQLString = "select @nDefaultStatusKey = max(STATUS)
			from	CASESEARCHRESULT 
			where	STATUS is not null
			and	PRIORARTID	= @pnPriorArtKey 
			and	CASEID		= @pnCaseKey"

		exec @nErrorCode=sp_executesql @sSQLString,
	      			N'
			@pnPriorArtKey			int,
			@pnCaseKey			int,
			@nDefaultStatusKey		int OUTPUT',
			@pnPriorArtKey			= @pnPriorArtKey,
			@pnCaseKey			= @pnCaseKey,
			@nDefaultStatusKey		= @nDefaultStatusKey OUTPUT
	End
	Else
	Begin
		Set @sSQLString = "UPDATE CASESEARCHRESULT
			set	STATUS			= @pnStatusKey,
				UPDATEDDATE		= @dToday
			where	PRIORARTID		= @pnPriorArtKey
			and	CASEID			= @pnCaseKey"
				
		exec @nErrorCode=sp_executesql @sSQLString,
	      			N'
			@pnPriorArtKey		int,
			@pnCaseKey		int,
			@pnStatusKey		int,
			@dToday			datetime',
			@pnPriorArtKey		= @pnPriorArtKey,
			@pnCaseKey		= @pnCaseKey,
			@pnStatusKey		= @pnStatusKey,
			@dToday			= @dToday
	End
End


If @nErrorCode = 0
Begin

	Set @sSQLString = "Insert into CASESEARCHRESULT
				(PRIORARTID,
				 CASEID,
				 STATUS,
				 CASEFIRSTLINKEDTO,
				 UPDATEDDATE)
			values (
				@pnPriorArtKey,
				@pnCaseKey,
				isnull(@pnStatusKey,@nDefaultStatusKey),
				@pbCaseFirstLinkedTo,
				@dToday)"

	exec @nErrorCode=sp_executesql @sSQLString,
			N'
		@pnPriorArtKey			int,
		@pnCaseKey			int,
		@pnStatusKey			int,
		@pbCaseFirstLinkedTo		bit,
		@nDefaultStatusKey		int,
		@dToday				datetime',
		@pnPriorArtKey		= @pnPriorArtKey,
		@pnCaseKey		= @pnCaseKey,
		@pnStatusKey		= @pnStatusKey,
		@pbCaseFirstLinkedTo	= @pbCaseFirstLinkedTo,
		@nDefaultStatusKey	= @nDefaultStatusKey,
		@dToday			= @dToday


End

Return @nErrorCode
GO

Grant execute on dbo.prw_InsertCaseSearchResult to public
GO