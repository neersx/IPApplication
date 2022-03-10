-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ipw_GetCPAXMLData
-----------------------------------------------------------------------------------------------------------------------------
If exists (Select * from dbo.sysobjects where id = object_id(N'[dbo].[ipw_GetCPAXMLData]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	Print '**** Drop Stored Procedure dbo.ipw_GetCPAXMLData.'
	Drop procedure [dbo].[ipw_GetCPAXMLData]
end
Print '**** Creating Stored Procedure dbo.ipw_GetCPAXMLData...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO


CREATE  PROCEDURE dbo.ipw_GetCPAXMLData 
		@pnUserIdentityId		int,		-- Mandatory
		@psCulture			nvarchar(10) 	= null,
		@pnProcessId				int		
AS
-- PROCEDURE :	ipw_GetCPAXMLData
-- VERSION :	1
-- DESCRIPTION:	To get the CPAXML data from CPAXMLEXPORTRESULT
-- COPYRIGHT: 	CPA Software Solutions (Australia) Pty Limited
--
-- MODIFICATIONS :
-- Date			Who		SQA#	Version	Change
-- ------------	-------	-----	-------	---------------------------------------------- 
-- 26/06/2013	DV		RFC6623	1		Procedure created

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF
SET ANSI_WARNINGS OFF 

Declare @sSQLString     nvarchar(4000)
Declare @nErrorCode	int	

-- Initialise variables
Set  @nErrorCode    = 0

If @nErrorCode = 0
Begin	
	-- The CPA-XML Export Process is added to the BackgroundProcess list	
		Set @sSQLString="SELECT CPAXMLDATA from CPAXMLEXPORTRESULT
						 WHERE PROCESSID =  @pnProcessId ORDER BY ID"

		exec @nErrorCode=sp_executesql @sSQLString,
				N'@pnProcessId int',
				  @pnProcessId = @pnProcessId

End

GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

grant execute on dbo.ipw_GetCPAXMLData to public
go

