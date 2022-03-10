-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ipw_MaintainQuestion
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ipw_MaintainQuestion]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ipw_MaintainQuestion.'
	Drop procedure [dbo].[ipw_MaintainQuestion]
End
Print '**** Creating Stored Procedure dbo.ipw_MaintainQuestion...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO

-- Allow comparison of null values
-- Procedure uses setting in place before it's created.
SET ANSI_NULLS OFF
GO


CREATE PROCEDURE dbo.ipw_MaintainQuestion
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pbCalledFromCentura	bit		= 0,
	@pnQuestionKey		smallint	= null,
	@psImprotanceLevel	nvarchar(4)	= null,
	@psQuestionCode		nvarchar(20)	= null,
	@psQuestion		nvarchar(200)	= null,
	@pnYesNoRequired	decimal(3,2)	= null,
	@pnCountRequired	decimal(3,2)	= null,
	@pnPeriodTypeRequired	decimal(3,2)	= null,
	@pnAmountRequired	decimal(3,2)	= null,
	@pnEmployeeRequired	decimal(3,2)	= null,
	@pnTextRequired		decimal(3,2)	= null,
	@pnTableType		int		= null,
	@pdtLastModifiedDate	datetime	= null
)
as
-- PROCEDURE:	ipw_MaintainQuestion
-- VERSION:	2
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Insert or Update the checklist item.  Used by the Web version.

-- MODIFICATIONS :
-- Date			Who		Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 08 NOV 2010	SF		RFC9193	1		Procedure created
-- 25 JAN 2011	SF		RFC9193	2		Correction

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

-- Reset so that next procedure gets the default
SET ANSI_NULLS ON

declare	@nErrorCode	int
declare @sSQLString nvarchar(4000)
declare @nQuestionNo int


-- Initialise variables
Set @nErrorCode = 0

If @nErrorCode = 0
Begin
	if @pnQuestionKey is not null
	Begin

		Set @sSQLString = N'
		Update		QUESTION
				Set QUESTIONCODE = @psQuestionCode,
				QUESTION = @psQuestion,
				IMPORTANCELEVEL = @psImprotanceLevel,
				YESNOREQUIRED = @pnYesNoRequired,
				COUNTREQUIRED = @pnCountRequired,
				PERIODTYPEREQUIRED = @pnPeriodTypeRequired,
				AMOUNTREQUIRED = @pnAmountRequired,
				EMPLOYEEREQUIRED = @pnEmployeeRequired,
				TEXTREQUIRED = @pnTextRequired,
				TABLETYPE = @pnTableType
			where	QUESTIONNO = @pnQuestionKey and
				LOGDATETIMESTAMP = @pdtLastModifiedDate'
		
		exec @nErrorCode = sp_executesql @sSQLString,
			 			N'@pnQuestionKey		smallint,
			 			@psQuestionCode			nvarchar(20),	
						@psQuestion			nvarchar(200),
						@psImprotanceLevel		nvarchar(4),
						@pnYesNoRequired		decimal(1,0),
						@pnCountRequired		decimal(1,0),
						@pnPeriodTypeRequired		decimal(1,0),
						@pnAmountRequired		decimal(1,0),
						@pnEmployeeRequired		decimal(1,0),
						@pnTextRequired			decimal(1,0),
						@pnTableType			smallint,
						@pdtLastModifiedDate		datetime',
						@pnQuestionKey			= @pnQuestionKey,
						@psQuestionCode			= @psQuestionCode,
						@psQuestion			= @psQuestion,
						@psImprotanceLevel		= @psImprotanceLevel,
						@pnYesNoRequired		= @pnYesNoRequired,
						@pnCountRequired		= @pnCountRequired,
						@pnPeriodTypeRequired		= @pnPeriodTypeRequired,
						@pnAmountRequired		= @pnAmountRequired,
						@pnEmployeeRequired		= @pnEmployeeRequired,
						@pnTextRequired			= @pnTextRequired,
						@pnTableType			= @pnTableType,
						@pdtLastModifiedDate		= @pdtLastModifiedDate
	End
	Else
	Begin
	If @nErrorCode = 0
	Begin
		-- Generate TABLETYPE primary key
		Exec @nErrorCode = dbo.ip_GetLastInternalCode
			@pnUserIdentityId	= @pnUserIdentityId,
			@psCulture		= @psCulture,
			@psTable		= 'QUESTION',
			@pnLastInternalCode	= @nQuestionNo		OUTPUT
	End

	If @nErrorCode = 0
	Begin
		
		Set @sSQLString = "Insert into QUESTION
		(
		QUESTIONNO,
		QUESTIONCODE,
		QUESTION,		
		IMPORTANCELEVEL,
		YESNOREQUIRED,
		COUNTREQUIRED,
		PERIODTYPEREQUIRED,
		AMOUNTREQUIRED,
		EMPLOYEEREQUIRED,
		TEXTREQUIRED,
		TABLETYPE
		)
		Values
		(
		@nQuestionNo,
		@psQuestionCode,
		@psQuestion,		
		@psImprotanceLevel,
		@pnYesNoRequired,
		@pnCountRequired,
		@pnPeriodTypeRequired,
		@pnAmountRequired,
		@pnEmployeeRequired,
		@pnTextRequired,
		@pnTableType
		)"
		
		exec @nErrorCode=sp_executesql @sSQLString,
		N'@nQuestionNo int,		
		@psQuestionCode			nvarchar(20),	
		@psQuestion			nvarchar(200),
		@psImprotanceLevel		nvarchar(4),
		@pnYesNoRequired		decimal(1,0),
		@pnCountRequired		decimal(1,0),
		@pnPeriodTypeRequired		decimal(1,0),
		@pnAmountRequired		decimal(1,0),
		@pnEmployeeRequired		decimal(1,0),
		@pnTextRequired			decimal(1,0),
		@pnTableType			smallint',
		@nQuestionNo = @nQuestionNo,
		@psQuestionCode			= @psQuestionCode,
		@psQuestion			= @psQuestion,
		@psImprotanceLevel		= @psImprotanceLevel,
		@pnYesNoRequired		= @pnYesNoRequired,
		@pnCountRequired		= @pnCountRequired,
		@pnPeriodTypeRequired		= @pnPeriodTypeRequired,
		@pnAmountRequired		= @pnAmountRequired,
		@pnEmployeeRequired		= @pnEmployeeRequired,
		@pnTextRequired			= @pnTextRequired,
		@pnTableType			= @pnTableType
		
	End
	End
	
End

Return @nErrorCode
GO

Grant execute on dbo.ipw_MaintainQuestion to public
GO
