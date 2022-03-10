-----------------------------------------------------------------------------------------------------------------------------
-- Creation of naw_FetchDiscountBasedOnInvoice
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[naw_FetchDiscountBasedOnInvoice]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.naw_FetchDiscountBasedOnInvoice.'
	Drop procedure [dbo].[naw_FetchDiscountBasedOnInvoice]
End
Print '**** Creating Stored Procedure dbo.naw_FetchDiscountBasedOnInvoice...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.naw_FetchDiscountBasedOnInvoice
(
	@pnUserIdentityId		int,		-- Mandatory
	@psCulture		        nvarchar(10) 	= null,		
	@pbCalledFromCentura		bit		= 0,
	@pnNameKey		        int		-- Mandatory
)
as
-- PROCEDURE:	naw_FetchDiscountBasedOnInvoice
-- VERSION:	3
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Populate the Disocunt based on Invoice

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 15 Jul 2010	MS	RFC7275	1	Procedure created
-- 25 Oct 2010	MS	RFC7275	2	Added columns OwnerNo, InstructorNo, PropertyType
-- 11 Apr 2013	DV	R13270	3	Increase the length of nvarchar to 11 when casting or declaring integer

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare @nErrorCode		int
Declare @sSQLString 		nvarchar(4000)
Declare @sLookupCulture		nvarchar(10)
Declare @dDiscountRate		decimal(6,3)
Declare @sLocalCurrencyCode	nvarchar(3)
Declare @nLocalDecimalPlaces	tinyint
Declare @dStartDate         datetime

-- Initialise variables
Set @nErrorCode = 0
Set @sLookupCulture = dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)

-- Retrieve Local Currency information
If @nErrorCode=0
Begin
	exec @nErrorCode = ac_GetLocalCurrencyDetails 	@psCurrencyCode		= @sLocalCurrencyCode	OUTPUT,
							@pnDecimalPlaces 	= @nLocalDecimalPlaces	OUTPUT,
							@pnUserIdentityId 	= @pnUserIdentityId,
							@pbCalledFromCentura	= @pbCalledFromCentura
End

If @nErrorCode = 0
Begin
	If not exists (Select 1 from DISCOUNTBASEDONINVOICE where NAMENO = @pnNameKey)
	Begin
		If @nErrorCode = 0
		Begin
			Select 	
				null			as RowKey,
				@pnNameKey		as NameKey,
				null			as StartDate,
				null			as Period,
				null			as PeriodType,
				null			as PeriodTypeDescription,
				null			as Invoice,
				null			as ResetFlag,
				null			as DiscountRate,
				null			as LastModifiedDate,
				null			as OwnerKey,
                                null                    as OwnerCode,
                                null                    as OwnerDescription,
				null			as InstructorKey,
                                null                    as InstructorCode,
                                null                    as InstructorDescription,
				null			as PropertyTypeKey,
				@nLocalDecimalPlaces	as LocalDecimalPlaces,
				@sLocalCurrencyCode	as LocalCurrencyCode			
		End

	End
	Else
	Begin
	    If (Select RESETFLAG from DISCOUNTBASEDONINVOICE where NAMENO = @pnNameKey) = 1
	    Begin
	        exec @nErrorCode = naw_UpdateStartDateForBillingDiscount
	                @pnUserIdentityId       = @pnUserIdentityId,
	                @psCulture              = @psCulture,
	                @pbCalledFromCentura    = @pbCalledFromCentura,
	                @pnNameKey              = @pnNameKey,
	                @pdtStartDate           = @dStartDate output
	    End
	    
	    If @nErrorCode = 0
	    begin
		    Set @sSQLString = "Select	
		    Cast(@pnNameKey as nvarchar(11)) as 'RowKey',
		    D.NAMENO as 'NameKey',		
		    CAST(Round(D.DISCOUNTRATE, @nLocalDecimalPlaces) as decimal(6, "+CAST(@nLocalDecimalPlaces as varchar(2))+"))  as 'DiscountRate',
		    D.STARTDATE as 'StartDate',
		    D.PERIOD as 'Period',
		    D.PERIODTYPE as 'PeriodType',"+
		    dbo.fn_SqlTranslatedColumn('TABLECODES','DESCRIPTION',null,'T',@sLookupCulture,@pbCalledFromCentura)
				    + " as 'PeriodTypeDescription', 		
		    D.INVOICE as 'Invoice',
		    D.RESETFLAG as 'ResetFlag',
		    D.LOGDATETIMESTAMP as 'LastModifiedDate',
		    D.OWNERNO	as 'OwnerKey',
                    OWN.NAME as 'OwnerDescription',
                    OWN.NAMECODE as 'OwnerCode',
		    D.INSTRUCTORNO as 'InstructorKey',
                    INS.NAME as 'InstructorDescription',
                    INS.NAMECODE as 'InstructorCode',
		    D.PROPERTYTYPE as 'PropertyTypeKey',
		    @nLocalDecimalPlaces	as 'LocalDecimalPlaces',
		    @sLocalCurrencyCode	as 'LocalCurrencyCode'
		    from DISCOUNTBASEDONINVOICE D
		    left join TABLECODES T on (T.TABLETYPE = 127 and T.USERCODE = D.PERIODTYPE)
                    left join NAME OWN on (OWN.NAMENO = D.OWNERNO)
                    left join NAME INS on (INS.NAMENO = D.INSTRUCTORNO)
		    where D.NAMENO = @pnNameKey"

		    exec @nErrorCode=sp_executesql @sSQLString,
				    N'@pnNameKey		        int,
				    @nLocalDecimalPlaces	        tinyint,
				    @sLocalCurrencyCode	                nvarchar(3)',
				    @pnNameKey		                = @pnNameKey,
				    @nLocalDecimalPlaces	        = @nLocalDecimalPlaces,
				    @sLocalCurrencyCode	                = @sLocalCurrencyCode
		End
	End
End

Return @nErrorCode
GO

Grant execute on dbo.naw_FetchDiscountBasedOnInvoice to public
GO
