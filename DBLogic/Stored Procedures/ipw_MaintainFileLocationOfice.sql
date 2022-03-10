-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ipw_MaintainFileLocationOfice									      
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ipw_MaintainFileLocationOfice]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ipw_MaintainFileLocationOfice.'
	Drop procedure [dbo].[ipw_MaintainFileLocationOfice]
End
Print '**** Creating Stored Procedure dbo.ipw_MaintainFileLocationOfice...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[ipw_MaintainFileLocationOfice]
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pnFileLocationKey      int,            -- Mandatory
	@pnOfficeKey            int             = null,
	@pdtLogDateTimeStamp    datetime        = null                       
)
as
-- PROCEDURE:	ipw_MaintainFileLocationOfice
-- VERSION:	1
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Insert, Update or delete the File Location Office.

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
If @nErrorCode = 0 and @pnOfficeKey is not null and @pnOfficeKey <> 0
Begin
        If exists (Select 1 from FILELOCATIONOFFICE where FILELOCATIONID = @pnFileLocationKey)
        Begin
                Set @sSQLString = "UPDATE FILELOCATIONOFFICE
                                SET OFFICEID = @pnOfficeKey
                                WHERE FILELOCATIONID = @pnFileLocationKey
                                and (LOGDATETIMESTAMP = @pdtLogDateTimeStamp or (LOGDATETIMESTAMP is null and @pdtLogDateTimeStamp is null))" 
                                
                exec @nErrorCode=sp_executesql @sSQLString,
                        N'@pnOfficeKey          int,
                        @pnFileLocationKey      int,
                        @pdtLogDateTimeStamp    datetime',
                        @pnOfficeKey            = @pnOfficeKey,
                        @pnFileLocationKey      = @pnFileLocationKey,
                        @pdtLogDateTimeStamp    = @pdtLogDateTimeStamp
        
        End
        ELSE 
        BEGIN
                Set @sSQLString = "INSERT INTO FILELOCATIONOFFICE (FILELOCATIONID, OFFICEID)
                                VALUES (@pnFileLocationKey, @pnOfficeKey)"
                                
                exec @nErrorCode=sp_executesql @sSQLString,
                        N'@pnOfficeKey          int,
                        @pnFileLocationKey      int' ,
                        @pnOfficeKey            = @pnOfficeKey,
                        @pnFileLocationKey      = @pnFileLocationKey
        END 
        
        Set @sSQLString = "Select LOGDATETIMESTAMP as LastModifiedDate
                        FROM FILELOCATIONOFFICE
                        where FILELOCATIONID = @pnFileLocationKey"
                        
        exec @nErrorCode=sp_executesql @sSQLString,
                        N'@pnFileLocationKey      int,
                        @pdtLogDateTimeStamp    datetime        output',
                        @pnFileLocationKey      = @pnFileLocationKey,
                        @pdtLogDateTimeStamp    = @pdtLogDateTimeStamp output
                     
End     
Else
Begin

        If exists (Select 1 from FILELOCATIONOFFICE where FILELOCATIONID = @pnFileLocationKey)
        Begin
        Set @sSQLString = "DELETE FROM FILELOCATIONOFFICE 
                        WHERE FILELOCATIONID = @pnFileLocationKey
                        and (LOGDATETIMESTAMP = @pdtLogDateTimeStamp or (LOGDATETIMESTAMP is null and @pdtLogDateTimeStamp is null))" 
                                
                exec @nErrorCode=sp_executesql @sSQLString,
                        N'@pnFileLocationKey      int,
                        @pdtLogDateTimeStamp    datetime',
                        @pnFileLocationKey      = @pnFileLocationKey,
                        @pdtLogDateTimeStamp    = @pdtLogDateTimeStamp
        End
        
        Select null as LastModifiedDate

End

Return @nErrorCode
GO

Grant execute on dbo.ipw_MaintainFileLocationOfice to public
GO