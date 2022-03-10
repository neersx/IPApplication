-----------------------------------------------------------------------------------------------------------------------------
-- Creation of csw_ListValidStatuses
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[csw_ListValidStatuses]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop Stored Procedure dbo.csw_ListValidStatuses.'
	drop procedure [dbo].[csw_ListValidStatuses]
	print '**** Creating Stored Procedure dbo.csw_ListValidStatuses...'
	print ''
end
go

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.csw_ListValidStatuses
(
	@pnRowCount		int		= null output,
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pnCaseKey  		int,		-- Mandatory
	@pbCalledFromCentura	bit		= 0
)
-- PROCEDURE:	csw_ListValidStatuses
-- VERSION:	1
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- SCOPE:	Inpro.Net
-- DESCRIPTION:	Returns a list of valid statuses of the case.

-- MODIFICATIONS :
-- Date		Who	Number	Version	Change
-- ------------	-------	------	-------	----------------------------------------------- 
-- 17 Oct 2005  TM	RFC3144	1	Procedure created
AS

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare @sSQLString		nvarchar(4000)
Declare @nErrorCode		int
Declare @sLookupCulture		nvarchar(10)

-- Initialise variables
Set @nErrorCode = 0
set @sLookupCulture = dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)
	
If @nErrorCode = 0
Begin
	Set @sSQLString="
	Select  V.STATUSCODE 	as StatusKey,
		"+dbo.fn_SqlTranslatedColumn('STATUS','INTERNALDESC',null,'S',@sLookupCulture,@pbCalledFromCentura)
				+ " as StatusDescription
	from 	CASES C 	
	join  	VALIDSTATUS V 	on  (V.PROPERTYTYPE = C.PROPERTYTYPE	
				and  V.CASETYPE = C.CASETYPE
			 	and  V.COUNTRYCODE = (	Select min (V1.COUNTRYCODE) 	
							from VALIDSTATUS V1 
							where V1.PROPERTYTYPE = V.PROPERTYTYPE 
							and   V1.CASETYPE = V.CASETYPE  
							and   V1.COUNTRYCODE in ('ZZZ',C.COUNTRYCODE)))
	join STATUS S		on (S.STATUSCODE = V.STATUSCODE)
	where C.CASEID = @pnCaseKey
	order by StatusDescription"

	exec @nErrorCode = sp_executesql @sSQLString,
					N'@pnCaseKey	int',
					  @pnCaseKey
	
	Set @pnRowCount = @@Rowcount
End

Return @nErrorCode
go

grant execute on dbo.csw_ListValidStatuses  to public
go
