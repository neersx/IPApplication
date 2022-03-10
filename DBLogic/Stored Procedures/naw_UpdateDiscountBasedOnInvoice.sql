-----------------------------------------------------------------------------------------------------------------------------
-- Creation of naw_UpdateDiscountBasedOnInvoice
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[naw_UpdateDiscountBasedOnInvoice]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.naw_UpdateDiscountBasedOnInvoice.'
	Drop procedure [dbo].[naw_UpdateDiscountBasedOnInvoice]
End
Print '**** Creating Stored Procedure dbo.naw_UpdateDiscountBasedOnInvoice...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.naw_UpdateDiscountBasedOnInvoice
(	
	@pnUserIdentityId		int,		-- Mandatory
	@psCulture			nvarchar(10) 	= null,
	@pbCalledFromCentura		bit		= 0,
	@pnNameKey			int,		-- Mandatory
	@pdStartDate                    datetime        = null,
	@pnPeriod                       int             = null,
	@psPeriodType                   nchar(1)        = null,
	@pnInvoice                      decimal(11,2)   = null,
	@pnDiscountRate                 decimal(6,3)    = null,
	@pbResetFlag			bit		= null,
	@pdLastModifiedDate             datetime        = null,
	@pnOwnerKey                     int             = null,
	@pnInstructorKey                int             = null,
	@psPropertyType                 nchar(1)        = null  
)
as
-- PROCEDURE:	naw_UpdateDiscountBasedOnInvoice
-- VERSION:	3
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Programmer comments here

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 10 Jun 2010	MS	RFC7275	1	Procedure created
-- 25 Oct 2010	MS	RFC7275	2	Added columns OwnerNo, InstructorNo, PropertyType
-- 06 Feb 2013  MS      R100593 3       Set nocount off and remove the select for LastModifieddate

SET NOCOUNT OFF
SET CONCAT_NULL_YIELDS_NULL OFF

Declare @nErrorCode		int
Declare @sSQLString 		nvarchar(4000)

-- Initialise variables
Set @nErrorCode = 0

If @nErrorCode = 0
Begin                
	If not Exists (Select 1 from DISCOUNTBASEDONINVOICE where NAMENO = @pnNameKey)
	Begin
	        Set  @sSQLString = 
	        "Insert into DISCOUNTBASEDONINVOICE 
	        (
	                NAMENO, 
	                STARTDATE, 
	                PERIOD, 
	                PERIODTYPE, 
	                INVOICE, 
	                DISCOUNTRATE,
	                RESETFLAG,
	                OWNERNO,
	                INSTRUCTORNO,
	                PROPERTYTYPE
	        )
	        values
	        (
	                @pnNameKey, 
	                @pdStartDate, 
	                @pnPeriod, 
	                @psPeriodType, 
	                @pnInvoice, 
	                @pnDiscountRate,
	                @pbResetFlag,
	                @pnOwnerKey,
	                @pnInstructorKey,
	                @psPropertyType
	        )"
	End
	Else 
	Begin
	       Set  @sSQLString = 
	                 "Update DISCOUNTBASEDONINVOICE SET
	                        STARTDATE               = @pdStartDate,
	                        PERIOD                  = @pnPeriod,
	                        PERIODTYPE              = @psPeriodType,
	                        INVOICE                 = @pnInvoice,
	                        DISCOUNTRATE            = @pnDiscountRate,
	                        RESETFLAG		= @pbResetFlag,
	                        OWNERNO                 = @pnOwnerKey,
	                        INSTRUCTORNO            = @pnInstructorKey,
	                        PROPERTYTYPE            = @psPropertyType
	                  where NAMENO = @pnNameKey
	                  and (CAST(LOGDATETIMESTAMP as nvarchar(20)) = CAST(@pdLastModifiedDate as nvarchar(20)))"		        
	        
	End
	
	exec @nErrorCode = sp_executesql @sSQLString,
	                N'@pdStartDate                  datetime,
	                  @pnPeriod                     tinyint,
	                  @psPeriodType                 nchar(1),
	                  @pnInvoice                    decimal(11,2),
	                  @pnDiscountRate               decimal(6,3),
	                  @pnNameKey                    int,	                  
	                  @pdLastModifiedDate           datetime,
	                  @pbResetFlag		        bit,
	                  @pnOwnerKey                   int,
	                  @pnInstructorKey              int,
	                  @psPropertyType               nchar(1)',
	                  @pdStartDate                  = @pdStartDate,
	                  @pnPeriod                     = @pnPeriod,
	                  @psPeriodType                 = @psPeriodType, 
	                  @pnInvoice                    = @pnInvoice,
	                  @pnDiscountRate               = @pnDiscountRate, 
	                  @pnNameKey                    = @pnNameKey,
	                  @pdLastModifiedDate           = @pdLastModifiedDate,
	                  @pbResetFlag		        = @pbResetFlag,
	                  @pnOwnerKey                   = @pnOwnerKey,
	                  @pnInstructorKey              = @pnInstructorKey,
	                  @psPropertyType               = @psPropertyType
	
End

Return @nErrorCode
GO

Grant execute on dbo.naw_UpdateDiscountBasedOnInvoice to public
GO
