-----------------------------------------------------------------------------------------------------------------------------
-- Creation of biw_CalculateNameBillingDiscountRate
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[biw_CalculateNameBillingDiscountRate]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.biw_CalculateNameBillingDiscountRate.'
	Drop procedure [dbo].[biw_CalculateNameBillingDiscountRate]
End
Print '**** Creating Stored Procedure dbo.biw_CalculateNameBillingDiscountRate...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[biw_CalculateNameBillingDiscountRate]
(
	@pnUserIdentityId		int,		-- Mandatory
	@psCulture		        nvarchar(10) 	= null,		
	@pbCalledFromCentura		bit		= 0,
        @pnCaseKey                      int             = null,
	@pnNameKey		        int             = null,		
        @pdAmountToBeBilled             decimal(11,2)   = 0,
	@pdDiscount      		decimal(11,2)   output	
)
as
-- PROCEDURE:	biw_CalculateNameBillingDiscountRate
-- VERSION:	2
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Calculates the Billing Discount based on invoice and
--		number of filings.

-- MODIFICATIONS :
-- Date		Who	Change	        Version	Description
-- -----------	-------	------	        -------	----------------------------------------------- 
-- 26 Jul 2010	MS	RFC7275	        1	Procedure created
-- 29 Oct 2010  MS      RFC7275         2       Added Columns Owner, PropertyType and Instructor
-- 12 Feb 2010  MS      RFC100441       3       Added Property type in Cases billing discount

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare @nErrorCode		int
Declare @sSQLString 		nvarchar(max)
Declare @sLookupCulture		nvarchar(10)
Declare @dDiscountRate		decimal(6,3)
Declare @dtStartDate		datetime
Declare @nPeriod		tinyint
Declare @sPeriodType		nchar(1)
Declare @dInvoice		decimal(11,2)
Declare @bRecurring		bit
Declare @dAmountBilled		decimal(11,2)
Declare @dtActualDate		datetime
Declare @nNoOfFilings		int
Declare @nOwnerKey              int
Declare @nInstructorKey         int
Declare @sPropertyType          nchar(1)
Declare @dDiscountRateCases     decimal(6,3)
Declare @bIsDiscApplied         bit

Declare @sSelect                nvarchar(4000)
Declare @sFrom                  nvarchar(4000)
Declare @sWhere                 nvarchar(4000)

Declare @tblPropertyTypes table 
	(
		RowNo		INT IDENTITY(1,1) NOT NULL PRIMARY KEY CLUSTERED,
		PropertyType	nchar(1),
		NoOfFilings	int 
	)

CREATE TABLE dbo.#tblPropertyTypes
        (
		RowNo		INT IDENTITY(1,1) NOT NULL PRIMARY KEY CLUSTERED,
		PropertyType	nchar(1),
		NoOfFilings	int 
	)

-- Initialise variables
Set @nErrorCode = 0
Set @sLookupCulture = dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)
set @dDiscountRateCases = 0
Set @bIsDiscApplied = 0

If @nErrorCode = 0 and @pnNameKey is null and @pnCaseKey is not null
Begin
        Set @sSQLString = "Select @pnNameKey = NAMENO
        FROM CASENAME where CASEID = @pnCaseKey
        AND NAMETYPE = 'D' 
        AND SEQUENCE = (Select MIN(CN1.SEQUENCE) FROM CASENAME CN1 where CN1.CASEID = @pnCaseKey and CN1.NAMETYPE = 'D')"

        exec @nErrorCode = sp_executesql @sSQLString,
                        N'@pnNameKey	        int             output,                       
			@pnCaseKey		int',
                        @pnNameKey              = @pnNameKey    output,
			@pnCaseKey		= @pnCaseKey
End
print @pnNameKey

If @nErrorCode = 0
Begin
	Set @sSQLString = "Select	
	@dtStartDate	        = STARTDATE,
	@nPeriod	        = PERIOD,
	@sPeriodType	        = PERIODTYPE,
	@dInvoice	        = INVOICE,
	@dDiscountRate	        = DISCOUNTRATE,
	@bRecurring	        = RESETFLAG,
        @nOwnerKey              = OWNERNO,
        @nInstructorKey         = INSTRUCTORNO,
        @sPropertyType          = PROPERTYTYPE
	from DISCOUNTBASEDONINVOICE D
	where D.NAMENO = @pnNameKey"
			

	exec @nErrorCode=sp_executesql @sSQLString,
			N'@dtStartDate		datetime		output,
			@nPeriod		tinyint			output,
			@sPeriodType		nchar(1)		output,
			@dInvoice		decimal(11,2)		output,
			@dDiscountRate		decimal(6,3)		output,
			@bRecurring		bit			output,
                        @nOwnerKey              int                     output,
                        @nInstructorKey         int                     output,
                        @sPropertyType          nchar(1)                output,
			@pnNameKey		int',
			@dtStartDate		= @dtStartDate		output,
			@nPeriod		= @nPeriod		output,
			@sPeriodType		= @sPeriodType		output,
			@dInvoice		= @dInvoice		output,
			@dDiscountRate		= @dDiscountRate	output,
			@bRecurring		= @bRecurring		output,
                        @nOwnerKey              = @nOwnerKey            output,
                        @nInstructorKey         = @nInstructorKey       output,
                        @sPropertyType          = @sPropertyType        output,
			@pnNameKey		= @pnNameKey
END

If @nErrorCode = 0 and @bRecurring = 1
Begin
    exec @nErrorCode = naw_UpdateStartDateForBillingDiscount
	                @pnUserIdentityId       = @pnUserIdentityId,
	                @psCulture              = @psCulture,
	                @pbCalledFromCentura    = @pbCalledFromCentura,
	                @pnNameKey              = @pnNameKey,
	                @pdtStartDate           = @dtStartDate output
End

If @nErrorCode = 0 and @pnCaseKey is not null
Begin
        Set @sSQLString = "Select @bIsDiscApplied = 1
        FROM CASES C 
        JOIN CASENAME CN1 on (CN1.CASEID = C.CASEID
                                        AND CN1.NAMETYPE = 'I' 
                                        AND (CN1.NAMENO = @nInstructorKey OR @nInstructorKey is NULL))
        JOIN CASENAME CN2 on (CN2.CASEID = C.CASEID
                                        AND CN2.NAMETYPE = 'O'
                                        AND (CN2.NAMENO = @nOwnerKey OR @nOwnerKey is NULL))        
        WHERE C.CASEID = @pnCaseKey
        and (C.PROPERTYTYPE = @sPropertyType or @sPropertyType is null)"

        exec @nErrorCode = sp_executesql @sSQLString,
                        N'@bIsDiscApplied	bit			output,                       
                        @nOwnerKey              int,
                        @nInstructorKey         int,
                        @sPropertyType          nchar(1),
			@pnCaseKey		int',			
			@bIsDiscApplied		= @bIsDiscApplied	output,                       
                        @nOwnerKey              = @nOwnerKey,
                        @nInstructorKey         = @nInstructorKey,
                        @sPropertyType          = @sPropertyType,
			@pnCaseKey		= @pnCaseKey
                       
End
Else If @nErrorCode = 0
Begin
        Set @bIsDiscApplied = 1
End 

If @nErrorCode = 0 and @bIsDiscApplied = 1 and @dtStartDate is not null
Begin

	SET @dtActualDate = case when @sPeriodType = 'D' then DATEADD(d,@nPeriod, @dtStartDate)
			when @sPeriodType = 'W' then DATEADD(ww,@nPeriod, @dtStartDate)
			when @sPeriodType = 'M' then DATEADD(mm,@nPeriod, @dtStartDate)
			when @sPeriodType= 'Y' then DATEADD(yy,@nPeriod, @dtStartDate)
			end	
       
	If @dtActualDate >= getDate() and ISNULL(@dDiscountRate,0) > 0
	Begin
		Set @sSelect = "select @dAmountBilled = ISNULL(sum(BilledToDate),0)"

                Set @sFrom = "from CASES C                        
                                join (select CASEID, isnull(sum(CASE WHEN(WT.CATEGORYCODE='SC') THEN isnull(-WH.LOCALTRANSVALUE,0) ELSE 0 END),0) as BilledToDate
				        from WORKHISTORY WH                              
		                        left join WIPTEMPLATE WTP	on (WTP.WIPCODE = WH.WIPCODE)
		                        left join WIPTYPE WT		on (WT.WIPTYPEID= WTP.WIPTYPEID)	
				        where WH.STATUS <> 0 			                        
                                                and   WH.MOVEMENTCLASS = 2
                                                and POSTDATE >= @dtStartDate
				        group by CASEID) CT on (CT.CASEID = C.CASEID)"

                Set @sWhere = "where CT.BilledToDate > 0"
                        
                If @nInstructorKey is not null
                Begin
                        Set @sFrom = @sFrom + nchar(10) + "join CASENAME CN1 on (C.CASEID = CN1.CASEID and CN1.NAMETYPE = 'I' and CN1.NAMENO = @nInstructorKey)"
                End

                If @nOwnerKey is not null
                Begin
                        Set @sFrom = @sFrom + nchar(10) + "join CASENAME CN2 on (C.CASEID = CN2.CASEID and CN2.NAMETYPE = 'O' and CN2.NAMENO = @nOwnerKey)"
                End

                If @nInstructorKey is null and @nOwnerKey is null
                Begin
                        Set @sFrom = @sFrom + nchar(10) + "join CASENAME CN on (C.CASEID = CN.CASEID and CN.NAMETYPE = 'D' and CN.NAMENO = @pnNameKey)"
                End
        
                If @sPropertyType is not null
                Begin
                        Set @sWhere = @sWhere + nchar(10) + "and (C.PROPERTYTYPE = @sPropertyType)"
                End			 

                Set @sSQLString = @sSelect + nchar(10) + @sFrom + nchar(10) + @sWhere

                exec @nErrorCode=sp_executesql @sSQLString,
					N'@dAmountBilled	decimal(11,2)		OUTPUT,
					@dtStartDate		datetime,
					@pnNameKey		int,
                                        @nInstructorKey         int,
                                        @nOwnerKey              int,
                                        @sPropertyType          nchar(1)',
					@dAmountBilled	        = @dAmountBilled 	OUTPUT,
					@dtStartDate		= @dtStartDate,
					@pnNameKey		= @pnNameKey,
                                        @nInstructorKey         = @nInstructorKey,
                                        @nOwnerKey              = @nOwnerKey,
                                        @sPropertyType          = @sPropertyType

                If @nOwnerKey is null and @nInstructorKey is null and @sPropertyType is null
                Begin
                        Set @sSQLString = "select @dAmountBilled = ISNULL(@dAmountBilled,0) + 
                                        isnull(sum(CASE WHEN(WT.CATEGORYCODE='SC') THEN isnull(-WH.LOCALTRANSVALUE,0) ELSE 0 END),0)
				        from WORKHISTORY WH                              
		                        left join WIPTEMPLATE WTP	on (WTP.WIPCODE = WH.WIPCODE)
		                        left join WIPTYPE WT		on (WT.WIPTYPEID= WTP.WIPTYPEID)	
				        where ACCTCLIENTNO = @pnNameKey 
                                                and WH.STATUS <> 0 			                        
                                                and WH.MOVEMENTCLASS = 2
                                                and POSTDATE >= @dtStartDate"   

                        exec @nErrorCode=sp_executesql @sSQLString,
					        N'@dAmountBilled	decimal(11,2)		OUTPUT,
					        @dtStartDate		datetime,
					        @pnNameKey		int',
					        @dAmountBilled	        = @dAmountBilled 	OUTPUT,
					        @dtStartDate		= @dtStartDate,
					        @pnNameKey		= @pnNameKey
                                               
                End
		
                IF @nErrorCode = 0
                Begin
	                If @dAmountBilled >= @dInvoice
	                Begin
		                Set @pdDiscount = (@pdAmountToBeBilled * @dDiscountRate)/100		
	                End
                        Else If @dAmountBilled + @pdAmountToBeBilled >= @dInvoice
                        Begin
                                Set @pdDiscount = ((@dAmountBilled + @pdAmountToBeBilled - @dInvoice) * @dDiscountRate)/100	   
                        End
                End
        End

        If @nErrorCode = 0 and (@dtActualDate >= getDate())
        Begin
	        Set @sSQLString = "INSERT INTO #tblPropertyTypes
	        Select C.PROPERTYTYPE, count(*) 
	        from CASES C"
                
                If @nInstructorKey is not null
                Begin
                        Set @sSQLString = @sSQLString + nchar(10) + "join CASENAME CN1 on (C.CASEID = CN1.CASEID 
                                                                                                and CN1.NAMETYPE = 'I' 
                                                                                                and CN1.NAMENO = @nInstructorKey)"
                End

                If @nOwnerKey is not null
                Begin
                        Set @sSQLString = @sSQLString + nchar(10) + "join CASENAME CN2 on (C.CASEID = CN2.CASEID 
                                                                                                and CN2.NAMETYPE = 'O' 
                                                                                                and CN2.NAMENO = @nOwnerKey)"
                End

                If @nInstructorKey is null and @nOwnerKey is null
                Begin
                        Set @sSQLString = @sSQLString + nchar(10) + "join CASENAME CN on (C.CASEID = CN.CASEID 
                                                                                                and CN.NAMETYPE = 'D' 
                                                                                                and CN.NAMENO = @pnNameKey)"
                End 

                Set @sSQLString = @sSQLString + nchar(10) + 
	        "join CASEEVENT CE on (C.CASEID = CE.CASEID  
			        and (CE.EVENTDATE >= @dtStartDate or @dtStartDate is null) 
			        and CE.EVENTNO = -4)
	        join VALIDPROPERTY P on (P.PROPERTYTYPE = C.PROPERTYTYPE and P.COUNTRYCODE = 'ZZZ')
	        join PROPERTYTYPE PT on (PT.PROPERTYTYPE = P.PROPERTYTYPE and (PT.CRMONLY = 0 or PT.CRMONLY is null))
	        Group by C.PROPERTYTYPE"

                If @sPropertyType is not null
                Begin
                        Set @sSQLString = @sSQLString + nchar(10) + "having (C.PROPERTYTYPE = @sPropertyType)"
                End 

                exec @nErrorCode=sp_executesql @sSQLString,
                        N'@dtStartDate          datetime,
                        @pnNameKey              int,
                        @nInstructorKey         int,
                        @nOwnerKey              int,
                        @sPropertyType          nchar(1)',
                        @dtStartDate            = @dtStartDate,
                        @pnNameKey              = @pnNameKey,
                        @nInstructorKey         = @nInstructorKey,
                        @nOwnerKey              = @nOwnerKey,
                        @sPropertyType          = @sPropertyType 
        	
                If @nErrorCode = 0 and exists(Select 1 from #tblPropertyTypes)
	        Begin
		        DECLARE @I INT
		        SET @I = 1		

		        WHILE (@I <= (SELECT COUNT(RowNo) FROM #tblPropertyTypes))
		        Begin
			        Declare @PropertyType nchar(1)
			        Set @dDiscountRate = null			
        			
			        Select	@PropertyType = PropertyType, 
				        @nNoOfFilings = NoOfFilings 
			        From #tblPropertyTypes 
			        where RowNo = @I
        			
			        If @nErrorCode = 0 and @nNoOfFilings > 0
			        Begin
				        Set @sSQLString = "Select @dDiscountRate = DISCOUNTRATE
				        FROM DISCOUNTBASEDONNOOFCASES
				        Where NAMENO = @pnNameKey
				        and (@nNoOfFilings >= FROMCASES) 
				        and (@nNoOfFilings <= TOCASES or ISNULL(TOCASES,0) = 0)
				        and (PROPERTYTYPE = @PropertyType)"				

				        exec @nErrorCode=sp_executesql @sSQLString,
					        N'@dDiscountRate	decimal(6,3)	OUTPUT,
					        @PropertyType		nchar(1),
					        @pnNameKey		int,
					        @nNoOfFilings		int',
					        @dDiscountRate		= @dDiscountRate OUTPUT,
					        @PropertyType		= @PropertyType,
					        @pnNameKey		= @pnNameKey,
					        @nNoOfFilings		= @nNoOfFilings
        					
				        If @nErrorCode = 0 and @dDiscountRate is null
				        Begin
					        Set @sSQLString = "Select @dDiscountRate = DISCOUNTRATE
					        FROM DISCOUNTBASEDONNOOFCASES
					        Where NAMENO = @pnNameKey
					        and (@nNoOfFilings >= FROMCASES) 
					        and (@nNoOfFilings <= TOCASES or ISNULL(TOCASES,0) = 0)
					        and (PROPERTYTYPE = '*')"
        					
					        exec @nErrorCode=sp_executesql @sSQLString,
						        N'@dDiscountRate	decimal(6,3)	OUTPUT,
						        @PropertyType		nchar(1),
						        @pnNameKey		int,
						        @nNoOfFilings		int',
						        @dDiscountRate		= @dDiscountRate OUTPUT,
						        @PropertyType		= @PropertyType,
						        @pnNameKey		= @pnNameKey,
						        @nNoOfFilings		= @nNoOfFilings
				        End
			        End		

			        Set @dDiscountRateCases = ISNULL(@dDiscountRateCases,0) + ISNULL(@dDiscountRate,0)
        			
			        Set @I = @I + 1			
		        End
	        End

                If @dDiscountRateCases > 0
	        Begin
		        Set @pdDiscount = ISNULL(@pdDiscount,0) + ((@pdAmountToBeBilled * @dDiscountRateCases)/100)		
	        End
        End
End

Return @nErrorCode
GO
Grant execute on dbo.biw_CalculateNameBillingDiscountRate to public
GO