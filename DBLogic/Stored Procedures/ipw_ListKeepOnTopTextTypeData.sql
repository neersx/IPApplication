-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ipw_ListKeepOnTopTextTypeData
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ipw_ListKeepOnTopTextTypeData]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ipw_ListKeepOnTopTextTypeData.'
	Drop procedure [dbo].[ipw_ListKeepOnTopTextTypeData]
End
Print '**** Creating Stored Procedure dbo.ipw_ListKeepOnTopTextTypeData...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO

SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.ipw_ListKeepOnTopTextTypeData
(
        @pnRowCount                     int             = null          output,                 
	@pnUserIdentityId		int,			        -- Mandatory
	@psCulture			nvarchar(10)	= null,         -- the language in which output is to be expressed
	@pnType		                tinyint		= 0,	        -- 0 - Case, 1 - Name
	@pbCalledFromCentura	        bit		= 0			
)
as
-- PROCEDURE:	ipw_ListKeepOnTopTextTypeData
-- VERSION:	2
-- DESCRIPTION:	Returns the requested Keep on Top Notes

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 17 Oct 2010	MS	RFC5885	1	Procedure created
-- 18 Oct 2011  MS      R10177  2       Return Program column

-- Programs
-- Case - 1
-- Name - 2
-- Billimg - 4
-- Timesheet - 8

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare	@nErrorCode		int
Declare @sSQLString		nvarchar(4000)
Declare @sLookupCulture		nvarchar(10)


-- Initialise variables
Set 	@nErrorCode = 0
set 	@sLookupCulture = dbo.fn_GetLookupCulture(@psCulture, null, 0)

If @nErrorCode = 0
Begin
        If @pnType = 0  -- Case Type
        Begin
                Set @sSQLString = "Select 
                                CASETYPE                                as TypeKey,
                                dbo.fn_GetTranslationLimited(CASETYPEDESC,null,CASETYPEDESC_TID,@sLookupCulture)
                                                                        as TypeDescription,
                                KOTTEXTTYPE                             as TextType,
                                cast((ISNULL(PROGRAM,0)&1) as bit)      as UsedInCase,
                                cast((ISNULL(PROGRAM,0)&2) as bit)      as UsedInName,
                                cast((ISNULL(PROGRAM,0)&4) as bit)      as UsedInBilling,
                                cast((ISNULL(PROGRAM,0)&8) as bit)      as UsedInTimesheet,
                                LOGDATETIMESTAMP                        as LogDateTimeStamp
                From CASETYPE
                order by TypeDescription"
        End
        Else  -- Name Type
        Begin
                Set @sSQLString = "Select 
                                NAMETYPE                                as TypeKey,
                                DESCRIPTION                             as TypeDescription,
                                KOTTEXTTYPE                             as TextType,
                                cast((ISNULL(PROGRAM,0)&1) as bit)      as UsedInCase,
                                cast((ISNULL(PROGRAM,0)&2) as bit)      as UsedInName,
                                cast((ISNULL(PROGRAM,0)&4) as bit)      as UsedInBilling,
                                cast((ISNULL(PROGRAM,0)&8) as bit)      as UsedInTimesheet,
                                LOGDATETIMESTAMP                        as LogDateTimeStamp
                From NAMETYPE
                order by TypeDescription"
        End

        exec @nErrorCode = sp_executesql @sSQLString,
                                N'@sLookupCulture       nvarchar(10)',
                                @sLookupCulture         = @sLookupCulture
End

Return @nErrorCode
GO

Grant execute on dbo.ipw_ListKeepOnTopTextTypeData to public
GO
