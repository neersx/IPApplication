-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ip_ListMultipleEvents
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ip_ListMultipleEvents]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ip_ListMultipleEvents.'
	Drop procedure [dbo].[ip_ListMultipleEvents]
End
Print '**** Creating Stored Procedure dbo.ip_ListMultipleEvents...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.ip_ListMultipleEvents
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pbCalledFromCentura	bit		= 0,
	@psEventKeys		nvarchar(4000)
)
as
-- PROCEDURE:	ip_ListMultipleEvents
-- VERSION:	2
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION: Given a list of comma delimited eventKeys, return matching events as a result set

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 28 Nov 2006	LP	RFC4663	1	Procedure created
-- 04 Feb 2010	DL	18430	2	Grant stored procedure to public


SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare @nErrorCode int
Declare @sSQLString nvarchar(4000)
Declare @sLookupCulture		nvarchar(10)
Declare @Numeric				nchar(1)	-- DataType(N) to indicate Numeric data
Set	@Numeric				='N'

Set @sLookupCulture = dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)

Set @nErrorCode = 0

Set @sSQLString='
Select	E.EVENTNO 						as EventKey,'+char(10)+
	dbo.fn_SqlTranslatedColumn('EVENTS','EVENTDESCRIPTION',null,'E',@sLookupCulture,@pbCalledFromCentura)+' as EventDescription'+char(10)+
'from	EVENTS E
where	E.EVENTNO'+dbo.fn_ConstructOperator(0,@Numeric,@psEventKeys, null,@pbCalledFromCentura)


exec @nErrorCode=sp_executesql @sSQLString,
				N'@psEventKeys		nvarchar(4000)',
				  @psEventKeys		=@psEventKeys


RETURN @nErrorCode

GO

Grant execute on dbo.ip_ListMultipleEvents to public
GO


