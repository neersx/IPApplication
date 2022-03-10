-----------------------------------------------------------------------------------------------------------------------------
-- Creation of csw_ListCaseLists 
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[csw_ListCaseLists]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.csw_ListCaseLists.'
	Drop procedure [dbo].[csw_ListCaseLists]
End
Print '**** Creating Stored Procedure dbo.csw_ListCaseLists...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.csw_ListCaseLists
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pbCalledFromCentura	bit		= 0
)
as
-- PROCEDURE:	csw_ListCaseLists
-- VERSION:	2
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	List Questions to be managed by the Web version software

-- MODIFICATIONS :
-- Date		Who	Change		Version	Description
-- -----------	-------	------		-------	----------------------------------------------- 
-- 01 MAR 2011	KR	RFC6563		1	Procedure created
-- 09 SEP 2011	KR	RFC11100	2	Procedure created


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
	Select  L.CASELISTNO 	as ListKey, 
			L.CASELISTNAME	as ListName,
		"+dbo.fn_SqlTranslatedColumn('CASELIST','DESCRIPTION',null, 'L',@sLookupCulture,@pbCalledFromCentura)
				+ " as ListDescription,
			LM.CASEID as CaseKey,
			C.IRN as CaseReference,
			L.LOGDATETIMESTAMP as LastModifiedDate
	from CASELIST L
	Left Join CASELISTMEMBER LM on (L.CASELISTNO = LM.CASELISTNO and LM.PRIMECASE = 1)
	Left Join CASES C on (C.CASEID = LM.CASEID)
	order by 1"

	exec @nErrorCode = sp_executesql @sSQLString
End

Return @nErrorCode
GO

Grant execute on dbo.csw_ListCaseLists to public
GO
