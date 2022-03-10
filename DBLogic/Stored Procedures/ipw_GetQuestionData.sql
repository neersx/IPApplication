-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ipw_GetQuestionData
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ipw_GetQuestionData]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ipw_GetQuestionData.'
	Drop procedure [dbo].[ipw_GetQuestionData]
End
Print '**** Creating Stored Procedure dbo.ipw_GetQuestionData...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.ipw_GetQuestionData
(
	@pnUserIdentityId		int,		-- Mandatory
	@psCulture			nvarchar(10) 	= null,
	@pbCalledFromCentura		bit		= 0,
	@pnQuestionKey			int	
)
as
-- PROCEDURE:	ipw_GetQuestionData
-- VERSION:	1
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Retrieve data to be used for setting up a Checklist

-- MODIFICATIONS :
-- Date			Who		Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 03 NOV 2010	SF		RFC9193	1		Procedure created

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

declare	@nErrorCode	int
declare @sSQLString nvarchar(4000)
Declare @sLookupCulture		nvarchar(10)

-- Initialise variables
Set @nErrorCode = 0
Set @sLookupCulture = dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)

If @nErrorCode = 0
Begin
	Set @sSQLString = "
			Select  Q.QUESTIONNO 	as QuestionKey, 
			Q.QUESTIONCODE	as QuestionCode,
	"+dbo.fn_SqlTranslatedColumn('QUESTION','QUESTION',null, 'Q',@sLookupCulture,@pbCalledFromCentura)
				+ " as DisplayLiteral,
			Q.IMPORTANCELEVEL as ImportanceLevelKey,
			Q.YESNOREQUIRED	as YesNoRequired,
			Q.COUNTREQUIRED as CountRequired,
			Q.PERIODTYPEREQUIRED as PeriodRequired,
			Q.AMOUNTREQUIRED as AmountRequired,
			Q.EMPLOYEEREQUIRED as EmployeeRequired,
			Q.TEXTREQUIRED as TextRequired,
			Q.TABLETYPE as ListItemRequired,
			Q.LOGDATETIMESTAMP as LastModifiedDate
			from QUESTION Q
		where Q.QUESTIONNO = @pnQuestionKey"		
	
	exec @nErrorCode = sp_executesql @sSQLString,
			N'@pnQuestionKey	int',
			@pnQuestionKey = @pnQuestionKey
End


Return @nErrorCode
GO

Grant execute on dbo.ipw_GetQuestionData to public
GO
