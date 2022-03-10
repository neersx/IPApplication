-----------------------------------------------------------------------------------------------------------------------------
-- Creation of csw_GetCaseListData 
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[csw_GetCaseListData]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.csw_GetCaseListData.'
	Drop procedure [dbo].[csw_GetCaseListData]
End
Print '**** Creating Stored Procedure dbo.csw_GetCaseListData...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.csw_GetCaseListData
(
	@pnUserIdentityId		int,		-- Mandatory
	@psCulture			nvarchar(10) 	= null,
	@pbCalledFromCentura		bit		= 0,
	@pnListKey				int	
)
as
-- PROCEDURE:	csw_GetCaseListData
-- VERSION:	1
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Retrieve data to be used for setting up a Case List

-- MODIFICATIONS :
-- Date			Who		Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 01 MAR 2011	KR		RFC6563	1		Procedure created

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
	
			Select  L.CASELISTNO 	as ListKey, 
			L.CASELISTNAME	as ListName,
			"+dbo.fn_SqlTranslatedColumn('CASELIST','DESCRIPTION',null, 'L',@sLookupCulture,@pbCalledFromCentura)
				+ " as ListDescription,
			LM.CASEID as CaseKey,
			C.IRN as CaseReference,
			F.LOGDATETIMESTAMP as LastModifiedDate
			from CASELIST L
			Join CASELISTMEMBER LM on (L.CASELISTNO = LM.CASELISTNO and LM.PRIMECASE = 1)
			Join CASES C on (C.CASEID = LM.CASEID)
			where L.CASELISTNO = @pnListKey"		
	
	exec @nErrorCode = sp_executesql @sSQLString,
			N'@pnListKey	int',
			@pnListKey = @pnListKey
End


Return @nErrorCode
GO

Grant execute on dbo.csw_GetCaseListData to public
GO
