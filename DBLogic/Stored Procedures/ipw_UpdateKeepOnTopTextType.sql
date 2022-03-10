-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ipw_UpdateKeepOnTopTextType
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ipw_UpdateKeepOnTopTextType]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ipw_UpdateKeepOnTopTextType.'
	Drop procedure [dbo].[ipw_UpdateKeepOnTopTextType]
End
Print '**** Creating Stored Procedure dbo.ipw_UpdateKeepOnTopTextType...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO

SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.ipw_UpdateKeepOnTopTextType
(
        @pnUserIdentityId		int,			        -- Mandatory
	@psCulture			nvarchar(10)	= null,         -- the language in which output is to be expressed	
	@pbCalledFromCentura	        bit		= 0,
        @pnType		                tinyint		= 0,	        -- 0 - Case, 1 - Name
        @psTypeKey                      nvarchar(3),                    -- Mandatory
        @psTextType                     nvarchar(2)     = null,
        @pbUsedInCase                   bit             = null,         -- Is used in case program
        @pbUsedInName                   bit             = null,         -- Is used in name program
        @pbUsedInBilling                bit             = null,         -- Is used in billing program
        @pbUsedInTimesheet              bit             = null,         -- Is used in timesheet program        
        @pdLogDateTimeStamp             datetime        = null			
)
as
-- PROCEDURE:	ipw_UpdateKeepOnTopTextType
-- VERSION:	2
-- DESCRIPTION:	Updates the Keep on Top Text Types for the Case Type / Name Type

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 17 Oct 2010	MS	RFC5885	1	Procedure created
-- 18 Oct 2011  MS      R10177  2       Update Program column

-- Programs
-- Case - 1
-- Name - 2
-- Billimg - 4
-- Timesheet - 8

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare	@nErrorCode		int
Declare @sSQLString		nvarchar(4000)
Declare @nProgram               int

-- Initialise variables
Set @nErrorCode =       0
Set @nProgram   =       ISNULL(@pbUsedInCase,0) * 1 | 
                        ISNULL(@pbUsedInName,0) * 2 | 
                        ISNULL(@pbUsedInBilling,0) * 4 | 
                        ISNULL(@pbUsedInTimesheet,0) * 8

If @nErrorCode = 0
Begin
        If @pnType = 0 -- Case Type
        Begin
                Set @sSQLString = "UPDATE  CASETYPE
                                SET KOTTEXTTYPE         = @psTextType,
                                    PROGRAM             = CASE WHEN @psTextType is null then null else @nProgram end
                                WHERE CASETYPE          = @psTypeKey                                      
                                AND (CAST(LOGDATETIMESTAMP as nvarchar(20)) = CAST(@pdLogDateTimeStamp as nvarchar(20))
                                or (LOGDATETIMESTAMP is null and @pdLogDateTimeStamp is null))"

                exec @nErrorCode = sp_executesql @sSQLString,
                                N'@psTypeKey            nvarchar(1),
                                @psTextType             nvarchar(2),                                
                                @nProgram               int,
                                @pdLogDateTimeStamp     datetime',
                                @psTypeKey              = @psTypeKey,
                                @psTextType             = @psTextType,
                                @nProgram               = @nProgram,
                                @pdLogDateTimeStamp     = @pdLogDateTimeStamp

                If @nErrorCode = 0 and @@RowCount > 0
	        Begin
		        Set  @sSQLString ="Select LOGDATETIMESTAMP as LogDateTimeStamp 
				           from CASETYPE 
				           where CASETYPE  = @psTypeKey"
        	                           
		        exec @nErrorCode = sp_executesql @sSQLString,
			        N'@psTypeKey          nvarchar(1)',
			        @psTypeKey            = @psTypeKey
	        End   
        End
        Else  -- Name Type
        Begin
                Set @sSQLString = "UPDATE  NAMETYPE
                                SET KOTTEXTTYPE         = @psTextType,
                                    PROGRAM             = CASE WHEN @psTextType is null then null else @nProgram end
                                WHERE NAMETYPE          = @psTypeKey
                                AND (CAST(LOGDATETIMESTAMP as nvarchar(20)) = CAST(@pdLogDateTimeStamp as nvarchar(20))
                                or (LOGDATETIMESTAMP is null and @pdLogDateTimeStamp is null))"  

                exec @nErrorCode = sp_executesql @sSQLString,
                                N'@psTypeKey            nvarchar(3),
                                @psTextType             nvarchar(2),
                                @nProgram               int,
                                @pdLogDateTimeStamp     datetime',
                                @psTypeKey              = @psTypeKey,
                                @psTextType             = @psTextType,
                                @nProgram               = @nProgram,
                                @pdLogDateTimeStamp     = @pdLogDateTimeStamp   

                If @nErrorCode = 0 and @@RowCount > 0
	        Begin
		        Set  @sSQLString ="Select LOGDATETIMESTAMP as LogDateTimeStamp 
				           from NAMETYPE 
				           where NAMETYPE  = @psTypeKey"
        	                           
		        exec @nErrorCode = sp_executesql @sSQLString,
			        N'@psTypeKey          nvarchar(3)',
			        @psTypeKey            = @psTypeKey
	        End            
        End        
End

Return @nErrorCode
GO

Grant execute on dbo.ipw_UpdateKeepOnTopTextType to public
GO
