-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ipw_ListQuestions
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ipw_ListQuestions]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ipw_ListQuestions.'
	Drop procedure [dbo].[ipw_ListQuestions]
End
Print '**** Creating Stored Procedure dbo.ipw_ListQuestions...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.ipw_ListQuestions
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pbCalledFromCentura	bit		= 0
)
as
-- PROCEDURE:	ipw_ListQuestions
-- VERSION:	1
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	List Questions to be managed by the Web version software

-- MODIFICATIONS :
-- Date			Who		Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 19 OCT 2010	SF		RFC9193	1		Procedure created

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

declare	@nErrorCode	int
declare @sSQLString nvarchar(4000)
Declare @sLookupCulture		nvarchar(10)

set @sLookupCulture = dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)

Set	@nErrorCode      = 0

-- Initialise variables
Set @nErrorCode = 0

If @nErrorCode = 0
Begin
	Set @sSQLString = "
	Select  Q.QUESTIONNO 	as QuestionKey, 
			Q.QUESTIONCODE	as QuestionCode,
	"+dbo.fn_SqlTranslatedColumn('QUESTION','QUESTION',null, 'Q',@sLookupCulture,@pbCalledFromCentura)
				+ " as Question,
			Q.IMPORTANCELEVEL as ImportanceLevelKey,
			Q.YESNOREQUIRED	as YesNoRequired,
			Q.COUNTREQUIRED as CountRequired,
			Q.PERIODTYPEREQUIRED as PeriodRequired,
			Q.AMOUNTREQUIRED as AmountRequired,
			Q.EMPLOYEEREQUIRED as EmployeeRequired,
			Q.TEXTREQUIRED as TextRequired,
			Q.TABLETYPE as TableTypeKey,
			Q.LOGDATETIMESTAMP as LastModifiedDate
	from QUESTION Q
	order by 2, 3"

	exec @nErrorCode = sp_executesql @sSQLString
End

Return @nErrorCode
GO

Grant execute on dbo.ipw_ListQuestions to public
GO
