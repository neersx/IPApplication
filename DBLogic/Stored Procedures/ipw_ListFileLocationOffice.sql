-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ipw_ListFileLocationOfice									      
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ipw_ListFileLocationOfice]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ipw_ListFileLocationOfice.'
	Drop procedure [dbo].[ipw_ListFileLocationOfice]
End
Print '**** Creating Stored Procedure dbo.ipw_ListFileLocationOfice...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[ipw_ListFileLocationOfice]
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null
)
as
-- PROCEDURE:	ipw_ListFileLocationOfice
-- VERSION:	1
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Populate the File Location Office.

-- MODIFICATIONS :
-- Date		Who	Change	   Version	Description
-- -----------	-------	------	   -------	-----------------------------------------------
-- 26 Jun 2012	MS	R100715	   1	        Procedure created

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare @nErrorCode	int
Declare @sSQLString 	nvarchar(4000)

-- Initialise variables
Set @nErrorCode = 0

-- File Location Office
If @nErrorCode = 0
Begin
        Set @sSQLString = "SELECT 
                        TC.TABLECODE            as FileLocationKey,
                        TC.DESCRIPTION          as FileLocationDescription,
                        FO.OFFICEID             as OfficeKey,
                        O.DESCRIPTION           as OfficeDescription,
                        FO.LOGDATETIMESTAMP     as LastModifiedDate                        
                        FROM TABLECODES TC 
                        left join FILELOCATIONOFFICE FO on (FO.FILELOCATIONID = TC.TABLECODE)
                        left join OFFICE O on (O.OFFICEID = FO.OFFICEID)                        
                        WHERE TABLETYPE = 10
                        ORDER BY FileLocationDescription"

        exec @nErrorCode=sp_executesql @sSQLString        
End

Return @nErrorCode
GO

Grant execute on dbo.ipw_ListFileLocationOfice to public
GO