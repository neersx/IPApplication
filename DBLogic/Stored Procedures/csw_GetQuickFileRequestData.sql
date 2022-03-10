-----------------------------------------------------------------------------------------------------------------------------
-- Creation of csw_GetQuickFileRequestData									      
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[csw_GetQuickFileRequestData]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.csw_GetQuickFileRequestData.'
	Drop procedure [dbo].[csw_GetQuickFileRequestData]
End
Print '**** Creating Stored Procedure dbo.csw_GetQuickFileRequestData...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.csw_GetQuickFileRequestData
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pnCaseKey              int,            -- Mandatory
	@pnNameKey		int 		-- Mandatory
)
as
-- PROCEDURE:	csw_GetQuickFileRequestData
-- VERSION:	5
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Get data for creating quick file request.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	-----------------------------------------------
-- 28 Jul 2011	MS	R100503	1	Procedure created    
-- 04 Nov 2011	ASH	R11460	2	CAST CaseID to nvarchar(11) 
-- 21 Nov 2011  MS	R11208  3   Return Case Keys along with File Parts  
-- 15 Apr 2013	DV	R13270  4	Increase the length of nvarchar to 11 when casting or declaring integer
-- 04 Nov 2015	KR	R53910	5	Adjust formatted names logic (DR-15543)

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare @nErrorCode	        int
Declare @sSQLString 	        nvarchar(4000)
Declare @sLookupCulture	        nvarchar(10)
Declare @bHasRFIDSystem         bit
Declare @sCaseReference         nvarchar(30)

-- Initialise variables
Set @nErrorCode = 0
If @psCulture is not null
Begin
        Set @sLookupCulture = dbo.fn_GetLookupCulture(@psCulture, null, 0)
End 

If @nErrorCode = 0
Begin
     Set @sSQLString = "Select @bHasRFIDSystem = COLBOOLEAN
                        FROM SITECONTROL
                        WHERE CONTROLID = 'RFID System'"
                        
     exec @nErrorCode=sp_executesql @sSQLString,
                       N'@bHasRFIDSystem        bit                     output',
                       @bHasRFIDSystem          = @bHasRFIDSystem       output
                        
End

If @nErrorCode = 0
Begin
     Set @sSQLString = "Select @sCaseReference = IRN
                        FROM CASES
                        WHERE CASEID = @pnCaseKey"
                        
     exec @nErrorCode=sp_executesql @sSQLString,
                       N'@sCaseReference        nvarchar(30)            output,
                       @pnCaseKey               int',
                       @sCaseReference          = @sCaseReference       output,
                       @pnCaseKey               = @pnCaseKey
                        
End

If @nErrorCode = 0
Begin
        Set @sSQLString = "       
        Select N.NAMENO as NameKey,
        @sCaseReference as CaseReference,
        CAST(@pnCaseKey as nvarchar(11))+'^'+CAST(NL.FILELOCATION as nvarchar(11)) as RowKey,
        dbo.fn_FormatNameUsingNameNo(N.NAMENO, 7101) as DisplayName, 
        NL.FILELOCATION as DefaultLocationKey
        FROM NAME N        
        left join NAMELOCATION NL on (NL.NAMENO = N.NAMENO and NL.ISDEFAULTLOCATION = 1)                 	
        WHERE N.NAMENO = @pnNameKey"

        exec @nErrorCode=sp_executesql @sSQLString,
			N'@pnCaseKey            int,
			@sCaseReference         nvarchar(30),
			@pnNameKey		int',
		        @pnCaseKey              = @pnCaseKey,
		        @sCaseReference         = @sCaseReference,
			@pnNameKey		= @pnNameKey
                
End

If @nErrorCode = 0 and ISNULL(@bHasRFIDSystem,0) = 1
Begin
        Set @sSQLString = "Select 
                        cast(CASEID as nvarchar(11)) + '^' + cast(FILEPART as nvarchar(10))       as RowKey,
                        FILEPART             as FilePartKey,
                        CASEID               as CaseKey,
                        1                    as IsSelected
                        FROM FILEPART                     
                        WHERE CASEID = @pnCaseKey
                        and ISMAINFILE = 1"

        exec @nErrorCode=sp_executesql @sSQLString,
			N'
			@pnCaseKey              int',
			@pnCaseKey		= @pnCaseKey
End 

Return @nErrorCode
GO

Grant execute on dbo.csw_GetQuickFileRequestData to public
GO