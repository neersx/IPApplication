-----------------------------------------------------------------------------------------------------------------------------
-- Creation of csw_FileRequestCheckForLocationChange
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[csw_FileRequestCheckForLocationChange]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.csw_FileRequestCheckForLocationChange.'
	Drop procedure [dbo].[csw_FileRequestCheckForLocationChange]
End
Print '**** Creating Stored Procedure dbo.csw_FileRequestCheckForLocationChange...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[csw_FileRequestCheckForLocationChange]
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pnCaseKey		int, 		-- Mandatory
	@pnFileLocationKey      int,            -- Mandatory
	@pdtWhenMoved           datetime,       -- Mandatory
	@pnFilePartKey          int             = null
)
as
-- PROCEDURE:	csw_FileRequestCheckForLocationChange
-- VERSION:	1
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Populate the File Requests data.

-- MODIFICATIONS :
-- Date		Who	Change	   Version	Description
-- -----------	-------	------	   -------	-----------------------------------------------
-- 28 Mar 2011	MS	R100634    1	        Procedure created                  

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare @nErrorCode	int
Declare @sSQLString 	nvarchar(4000)

Set @sSQLString = "Select top 1             
	F.DATEREQUIRED          as DateRequired
        FROM FILEREQUEST F        
        WHERE F.CASEID = @pnCaseKey
        and F.FILELOCATION != @pnFileLocationKey
        and F.DATEREQUIRED <= @pdtWhenMoved
        and (F.FILEPARTID = @pnFilePartKey or (F.FILEPARTID is null and @pnFilePartKey is null))
        order by DATEREQUIRED desc"

exec @nErrorCode=sp_executesql @sSQLString,
			N'
			@pnCaseKey		int,
			@pnFileLocationKey      int,
			@pdtWhenMoved           datetime,
			@pnFilePartKey          int',
			@pnCaseKey		= @pnCaseKey,
			@pnFileLocationKey      = @pnFileLocationKey,
			@pdtWhenMoved           = @pdtWhenMoved,
			@pnFilePartKey		= @pnFilePartKey


Return @nErrorCode
GO

Grant execute on dbo.csw_FileRequestCheckForLocationChange to public
GO
