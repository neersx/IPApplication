-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ipw_GetSanityCheckResults
-----------------------------------------------------------------------------------------------------------------------------
If exists (Select * from dbo.sysobjects where id = object_id(N'[dbo].[ipw_GetSanityCheckResults]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	Print '**** Drop Stored Procedure dbo.ipw_GetSanityCheckResults.'
	Drop procedure [dbo].[ipw_GetSanityCheckResults]
end
Print '**** Creating Stored Procedure dbo.ipw_GetSanityCheckResults...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO


CREATE  PROCEDURE dbo.ipw_GetSanityCheckResults 
		@pnUserIdentityId		int,		-- Mandatory
		@psCulture			nvarchar(10) 	= null,
		@pnProcessId				int		
AS
-- PROCEDURE :	ipw_GetSanityCheckResults
-- VERSION :	2
-- DESCRIPTION:	To get the CPAXML data from SANITYCHECKRESULT
-- COPYRIGHT: 	CPA Software Solutions (Australia) Pty Limited
--
-- MODIFICATIONS :
-- Date			Who		SQA#	Version	Change
-- ------------	-------	-----	-------	---------------------------------------------- 
-- 11/07/2013	        SW		RFC11114	1		Procedure created
-- 11/07/2013           SW              RFC11114        2               Added order by clause for CaseId and changed ResultSet column names

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF
SET ANSI_WARNINGS OFF 

Declare @sSQLString     nvarchar(4000)
Declare @nErrorCode	int	

-- Initialise variables
Set  @nErrorCode    = 0

If @nErrorCode = 0
Begin
		Set @sSQLString="SELECT S.ID as Id,
		                        S.PROCESSID as ProcessKey,
		                        S.CASEID as CaseKey,
		                        C.IRN as CaseReference,
		                        CASE WHEN(S.ISWARNING = 0 and S.CANOVERRIDE = 1) 
			                THEN cast(1 as bit)
			                ELSE cast(0 as bit)
		                        END  as ByPassError,
		                        CASE WHEN(S.ISWARNING = 0 and S.CANOVERRIDE = 0) 
			                THEN cast(1 as bit)
			                ELSE cast(0 as bit)
		                        END  as Error,		                         
		                        CASE WHEN(S.ISWARNING = 1)
		                        THEN cast(1 as bit)
		                        ELSE cast(0 as bit)
		                        END  as Information,		                        
		                        S.DISPLAYMESSAGE as DisplayMessage		                                        
		                        from SANITYCHECKRESULT S 
		                        left join CASES C on (C.CASEID = S.CASEID)
			                WHERE PROCESSID =  @pnProcessId ORDER BY S.CASEID"

		exec @nErrorCode=sp_executesql @sSQLString,
				N'@pnProcessId int',
				  @pnProcessId = @pnProcessId

End

GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

grant execute on dbo.ipw_GetSanityCheckResults to public
go

