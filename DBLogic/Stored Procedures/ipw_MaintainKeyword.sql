-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ipw_MaintainKeyword 
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ipw_MaintainKeyword]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ipw_MaintainKeyword.'
	Drop procedure [dbo].[ipw_MaintainKeyword]
End
Print '**** Creating Stored Procedure dbo.ipw_MaintainKeyword...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO

-- Allow comparison of null values
-- Procedure uses setting in place before it's created.
SET ANSI_NULLS OFF
GO


CREATE PROCEDURE dbo.ipw_MaintainKeyword
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pbCalledFromCentura	bit		= 0,
	@pnKeywordKey		int		= null,
	@psKeyword		nvarchar(100)	= null,
	@pnStopWord		decimal(5,1)	= null,
	@pdtLastModifiedDate	datetime	= null
)
as
-- PROCEDURE:	ipw_MaintainKeyword
-- VERSION:	1
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Insert or Update the Keyword.  Used by the Web version.

-- MODIFICATIONS :
-- Date		Who	Change		Version	Description
-- -----------	-------	------		-------	----------------------------------------------- 
-- 15 MAR 2012	KR	R8562		1	Procedure created

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

-- Reset so that next procedure gets the default
SET ANSI_NULLS ON

declare	@nErrorCode	int
declare @sSQLString nvarchar(4000)
declare @nKeywordNo int

-- Initialise variables
Set @nErrorCode = 0

If @nErrorCode = 0
Begin
	if @pnKeywordKey is not null
	Begin
		Set @sSQLString = N'
		Update	KEYWORDS
				Set 
				KEYWORD =  @psKeyword,
				STOPWORD = @pnStopWord
				where	KEYWORDNO = @pnKeywordKey and
				LOGDATETIMESTAMP = @pdtLastModifiedDate'
		
		exec @nErrorCode = sp_executesql @sSQLString,
		 				N'@pnKeywordKey		int,
		 				@psKeyword		nvarchar(100),
		 				@pnStopWord		decimal(5,1),
						@pdtLastModifiedDate		datetime',
						@pnKeywordKey			= @pnKeywordKey,
						@psKeyword			= @psKeyword,
						@pnStopWord			= @pnStopWord,
						@pdtLastModifiedDate		= @pdtLastModifiedDate		
	End	
	Else
	Begin
		if exists (select 1 from LASTINTERNALCODE Where TABLENAME = 'KEYWORDS')
			Select @nKeywordNo = INTERNALSEQUENCE+1 From LASTINTERNALCODE Where TABLENAME = 'KEYWORDS'
		else
			Set @nKeywordNo = 0
		select @nKeywordNo
		
		Set @sSQLString = "Insert into KEYWORDS
		(
		KEYWORDNO,
		KEYWORD,
		STOPWORD
		)
		Values
		(
		@nKeywordNo,
		@psKeyword,
		@pnStopWord
		)"
		
		exec @nErrorCode=sp_executesql @sSQLString,
		N'@nKeywordNo	int,
		@psKeyword	nvarchar(100),		
		@pnStopWord	decimal(5,2)',
		@nKeywordNo	= @nKeywordNo,
		@psKeyword	= @psKeyword,
		@pnStopWord	= @pnStopWord
		
		if exists (select 1 from LASTINTERNALCODE Where TABLENAME = 'KEYWORDS')			
			Update LASTINTERNALCODE Set INTERNALSEQUENCE = @nKeywordNo Where TABLENAME = 'KEYWORDS'
		else
			Insert into LASTINTERNALCODE(TABLENAME, INTERNALSEQUENCE) values ('KEYWORDS', @nKeywordNo)
	End
End

Return @nErrorCode
GO

Grant execute on dbo.ipw_MaintainKeyword to public
GO
