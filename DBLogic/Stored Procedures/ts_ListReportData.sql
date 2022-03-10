-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ts_ListReportData
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ts_ListReportData]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ts_ListReportData.'
	Drop procedure [dbo].[ts_ListReportData]
End
Print '**** Creating Stored Procedure dbo.ts_ListReportData...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.ts_ListReportData
(
	@pnRowCount		int		= null output,	
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@ptXMLFilterCriteria	ntext		= null,	-- The filtering to be performed on the result set.
	@pbCalledFromCentura	bit		= 0
)
as
-- PROCEDURE:	ts_ListReportData
-- VERSION:	6
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	This stored procedure produces the main result set for the Timesheet Worksheet Report. 
--		This result set contains a list of time entries matching the filter criteria

-- MODIFICATIONS :
-- Date		Who	Change		Version	Description
-- -----------	-------	------		-------	----------------------------------------------- 
-- 28 NOV 2009	MS	RFC2530		1	Procedure created
-- 03 MAY 2010	MS	RFC100161	2	Added row with Null values if no data exist
-- 19 JUL 2012	KR	RFC12427	3	Added Logic to order desc by CREATEDON and STARTTIME
-- 05 Jul 2013	vql	R13629		4	Remove string length restriction and use nvarchar on datetime conversions using 106 format.
-- 02 Nov 2015	vql	R53910		5	Adjust formatted names logic (DR-15543).
-- 14 Nov 2018  AV  75198/DR-45358	6   Date conversion errors when creating cases and opening names in Chinese DB

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare @nErrorCode 		int
Declare @sSQLString		nvarchar(max)

-- Declare Filter Variables
Declare @nStaffKey 		int		-- The staff member whose time is to be returned.
Declare @nDateRangeOperator	tinyint		-- Return entries with the date portion of their StartTime between these dates. From and/or To value must be provided.
Declare @dtDateRangeFrom	datetime	-- Return WIP with item dates between these dates. From and/or To value must be provided.
Declare @dtDateRangeTo		datetime
Declare @sFilterCaseKey		int
Declare @sFilterNameKey		int
Declare @bHideContinued		bit	
Declare @sSortedBy		nchar(1)
Declare @sOrderBy		nvarchar(4000)
Declare @nNumberOfDays		int

Declare @sLocalCurrencyCode	nvarchar(3)
Declare @nLocalDecimalPlaces	tinyint

Declare @idoc 			int		-- Declare a document handle of the XML document in memory that is created by sp_xml_preparedocument.		

Declare @sLookupCulture		nvarchar(10)
Declare @Date			nchar(2)
Declare @sFrom			nvarchar(4000)
Declare @sWhere			nvarchar(4000)

set	@sLookupCulture		= dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)
set 	@sFrom			= char(10)+"From DIARY XD"
set 	@sWhere 		= char(10)+"	WHERE 1=1"
Set	@Date   		='DT'
Set     @nErrorCode		= 0	

Create Table #TempTable (EMPLOYEENO int, ENTRYNO int, ISTIMER bit)			

-- Retrieve Local Currency information
If @nErrorCode=0
Begin
	exec @nErrorCode = ac_GetLocalCurrencyDetails 	@psCurrencyCode		= @sLocalCurrencyCode	OUTPUT,
							@pnDecimalPlaces 	= @nLocalDecimalPlaces	OUTPUT,
							@pnUserIdentityId 	= @pnUserIdentityId,
							@pbCalledFromCentura	= @pbCalledFromCentura
End

-- Create an XML document in memory and then retrieve the information 
-- from the rowset using OPENXML
	
exec sp_xml_preparedocument	@idoc OUTPUT, @ptXMLFilterCriteria

-- Extract the FromDate and ToDate from the filter criteria:
If (datalength(@ptXMLFilterCriteria) > 0)
and @nErrorCode = 0
Begin
	Set @sSQLString = 	
	"Select @nStaffKey			= StaffKey,"+CHAR(10)+				
	"	@nDateRangeOperator		= DateRangeOperator,"+CHAR(10)+
	"	@dtDateRangeFrom		= DateRangeFrom,"+CHAR(10)+
	"	@dtDateRangeTo			= DateRangeTo,"+CHAR(10)+
	"	@sFilterCaseKey			= CaseKey,"+CHAR(10)+
	"	@sFilterNameKey			= NameKey,"+CHAR(10)+
	"	@bHideContinued			= HideContinued,"+CHAR(10)+
	"	@sSortedBy			= SortedBy"+CHAR(10)+
	"from	OPENXML (@idoc, '/ts_ListReportData/FilterCriteria',2)"+CHAR(10)+
	"	WITH ("+CHAR(10)+
	"	      StaffKey			int		'StaffKey/text()',"+CHAR(10)+	
	"	      DateRangeOperator		tinyint		'DateRange/@Operator/text()',"+CHAR(10)+	
	"	      DateRangeFrom		datetime	'DateRange/From/text()',"+CHAR(10)+	
	"	      DateRangeTo		datetime	'DateRange/To/text()',"+CHAR(10)+
	"	      CaseKey			int		'CaseKey/text()',"+CHAR(10)+
	"	      NameKey			int		'NameKey/text()',"+CHAR(10)+
	"	      HideContinued		bit		'HideContinued/text()',"+CHAR(10)+
	"	      SortedBy			nchar(1)	'SortedBy/text()'"+CHAR(10)+
     	"     	     )"

	exec @nErrorCode = sp_executesql @sSQLString,
				N'@idoc				int,
				  @nStaffKey 			int			output,			  		
				  @nDateRangeOperator		tinyint			output,
				  @dtDateRangeFrom		datetime		output,		
				  @dtDateRangeTo		datetime		output,					 
				  @sFilterCaseKey		int			output,
				  @sFilterNameKey		int			output,
				  @bHideContinued		bit			output,
				  @sSortedBy			nchar(1)		output',
				  @idoc				= @idoc,
				  @nStaffKey 			= @nStaffKey		output,			 		
				  @nDateRangeOperator		= @nDateRangeOperator	output,
				  @dtDateRangeFrom 		= @dtDateRangeFrom	output,
				  @dtDateRangeTo		= @dtDateRangeTo	output,
				  @sFilterCaseKey		= @sFilterCaseKey	output,
				  @sFilterNameKey		= @sFilterNameKey	output,
				  @bHideContinued		= @bHideContinued	output,
				  @sSortedBy			= @sSortedBy		output

	-- deallocate the xml document handle when finished.
	exec sp_xml_removedocument @idoc	

	Set @nErrorCode=@@Error
End

/***********************************************/
/****                                       ****/
/****    CONSTRUCTION OF THE WHERE  clause  ****/
/****                                       ****/
/***********************************************/
If @nStaffKey is not NULL
Begin
	Set @sWhere = @sWhere+char(10)+" and XD.EMPLOYEENO = "+ convert(varchar,@nStaffKey)
End

If @dtDateRangeFrom is not null
or @dtDateRangeTo   is not null
Begin
	Set @sWhere =  @sWhere+char(10)+" and XD.STARTTIME"+dbo.fn_ConstructOperator(@nDateRangeOperator,@Date,convert(nvarchar,@dtDateRangeFrom,112), convert(nvarchar,@dtDateRangeTo,112),@pbCalledFromCentura)
End

If @bHideContinued = 1
Begin
	Set @sWhere = @sWhere+char(10)+" and XD.TOTALTIME is not null" 		
End

If @sFilterCaseKey is not null
Begin
	Set @sWhere = @sWhere+char(10)+" and XD.CASEID = "+ convert(varchar,@sFilterCaseKey) 
End

If @sFilterNameKey is not null
Begin
	Set @sFrom  = @sFrom +char(10)+ " left join CASES C on (C.CASEID = XD.CASEID)
		       left join CASENAME CN on (CN.CASEID = C.CASEID
				and CN.NAMETYPE = 'I' 
				and (CN.EXPIRYDATE is null or CN.EXPIRYDATE>getdate()))
		       left join NAME N on (N.NAMENO = ISNULL(CN.NAMENO, XD.NAMENO))"
	Set @sWhere = @sWhere+char(10)+" and N.NAMENO = "+ convert(varchar,@sFilterNameKey)  

End


-- Number of days between the date range
SET @nNumberOfDays = DATEDIFF(d,ISNULL(@dtDateRangeFrom,0),ISNULL(@dtDateRangeTo,0)) + 1


-- Set the Order By
IF @sSortedBy = 'C' -- Sorted By Case
Begin
	Set @sOrderBy = " order by C.IRN, dbo.fn_FormatNameUsingNameNo(N.NAMENO, null), D.STARTTIME, 'Activity'"
End
Else IF @sSortedBy = 'N' -- Sorted By Name
Begin
	Set @sOrderBy = " order by dbo.fn_FormatNameUsingNameNo(N.NAMENO, null), C.IRN, D.STARTTIME, 'Activity'"
End
ELSE -- Sorted By Time
Begin
	Set @sOrderBy = " order by TimeUnitOnlyOrder, D.STARTTIME desc, D.CREATEDON desc, Reference,'Activity'"
End	

-- Insert the data into temporary table
If @nErrorCode = 0
Begin
	Set @sSQLString = "Insert into #TempTable (EMPLOYEENO, ENTRYNO, ISTIMER)
		Select XD.EMPLOYEENO, XD.ENTRYNO, XD.ISTIMER"+char(10)+
		ltrim(rtrim(@sFrom +char(10)+ @sWhere))
	
	exec @nErrorCode = sp_executesql @sSQLString		
End


-- Output
If   @nErrorCode = 0
Begin
	If exists (Select 1 from #TempTable)
	Begin
		Set @sSQLString = "
			Select convert(char(10),convert(datetime,D.STARTTIME,120),120)
						as 'Date',
			D.STARTTIME		as 'StartDateTime',
			D.FINISHTIME		as 'FinishDateTime',
			D.EMPLOYEENO		as 'StaffKey',
			D.CASEID		as 'CaseKey',
			D.NAMENO		as 'NameKey',
			ISNULL(convert(nvarchar(max),D.LONGNARRATIVE), D.SHORTNARRATIVE)
						as 'Narrative',
			D.NOTES			as 'Notes',
			CASE WHEN D.CASEID is not null THEN C.IRN 
				ELSE dbo.fn_FormatNameUsingNameNo(N.NAMENO, null) 
				END as 'Reference',
			"+dbo.fn_SqlTranslatedColumn('WIPTEMPLATE','DESCRIPTION',null,'W',@sLookupCulture,@pbCalledFromCentura)+"
						as 'Activity',	
			isnull(DATEPART(HOUR,D.TOTALTIME ),0)*60 + isnull(DATEPART(HOUR,D.TIMECARRIEDFORWARD ),0)*60 + 
				isnull(DATEPART(MINUTE, D.TOTALTIME),0) + isnull(DATEPART(MINUTE, D.TIMECARRIEDFORWARD),0)
						as 'TotalTime',
			CASE WHEN D.TIMEVALUE > 0 THEN
				isnull(DATEPART(HOUR,D.TOTALTIME ),0)*60 + isnull(DATEPART(MINUTE, D.TOTALTIME),0)
				+
				isnull(DATEPART(HOUR,D.TIMECARRIEDFORWARD ),0)*60 + isnull(DATEPART(MINUTE, D.TIMECARRIEDFORWARD),0) 
				ELSE 0
				END 		as 'ChargeableMinutes',
			CASE WHEN D.TIMEVALUE = 0 or D.TIMEVALUE is null THEN
				isnull(DATEPART(HOUR,D.TOTALTIME ),0)*60 + isnull(DATEPART(MINUTE, D.TOTALTIME),0)
				+
				isnull(DATEPART(HOUR,D.TIMECARRIEDFORWARD ),0)*60 + isnull(DATEPART(MINUTE, D.TIMECARRIEDFORWARD),0) 
				ELSE 0
				END 			as 'NonChargeableMinutes',
			(CAST(CASE WHEN D.TIMEVALUE > 0 THEN
				isnull(DATEPART(HOUR,D.TOTALTIME ),0)*60 + isnull(DATEPART(MINUTE, D.TOTALTIME),0)
				+
				isnull(DATEPART(HOUR,D.TIMECARRIEDFORWARD ),0)*60 + isnull(DATEPART(MINUTE, D.TIMECARRIEDFORWARD),0)
				ELSE 0 END AS FLOAT)
				/
				(CAST(ISNULL((SC.COLDECIMAL*60), (8.00*60)) AS FLOAT)) / @nNumberOfDays) as 'ChargeablePercent',	     
			D.TOTALUNITS		as 'TotalUnits',
			CASE WHEN D.TIMEVALUE = 0 THEN null 
				ELSE D.TIMEVALUE 
				END		as 'Value',
			D.DISCOUNTVALUE		as 'Discount',
			D.FOREIGNCURRENCY	as 'ForeignCurrency',
			D.FOREIGNVALUE		as 'ForeignValue',
			D.FOREIGNDISCOUNT	as 'ForeignDiscount',
			@sLocalCurrencyCode	as LocalCurrencyCode,
			@nLocalDecimalPlaces	as LocalDecimalPlaces,
			D.CREATEDON,
			2 as TimeUnitOnlyOrder,
			C.IRN,
			dbo.fn_FormatNameUsingNameNo(N.NAMENO, null)
		from 	DIARY D			
		left join CASES C		on (C.CASEID = D.CASEID)
		left join NAME N 		on (N.NAMENO = D.NAMENO)		
		left join WIPTEMPLATE W 	on (W.WIPCODE = D.ACTIVITY)
		left join SITECONTROL SC 	on (SC.CONTROLID = 'Standard Daily Hours')	
		where exists ("+char(10)+
			"Select 1 from  #TempTable as XD" +char(10)+
			"where XD.EMPLOYEENO=D.EMPLOYEENO"+char(10)+
			"and XD.ENTRYNO=D.ENTRYNO"+char(10)+
			"and XD.ISTIMER = 0)
		AND convert(varchar(8), D.STARTTIME, 108) != '00:00:00'"	
		
		Set @sSQLString = @sSQLString +
		" Union " +
		"
			Select convert(char(10),convert(datetime,D.STARTTIME,120),120)
						as 'Date',
			D.STARTTIME		as 'StartDateTime',
			D.FINISHTIME		as 'FinishDateTime',
			D.EMPLOYEENO		as 'StaffKey',
			D.CASEID		as 'CaseKey',
			D.NAMENO		as 'NameKey',
			ISNULL(convert(nvarchar(max),D.LONGNARRATIVE), D.SHORTNARRATIVE)
						as 'Narrative',
			D.NOTES			as 'Notes',
			CASE WHEN D.CASEID is not null THEN C.IRN 
				ELSE dbo.fn_FormatNameUsingNameNo(N.NAMENO, null) 
				END as 'Reference',
			"+dbo.fn_SqlTranslatedColumn('WIPTEMPLATE','DESCRIPTION',null,'W',@sLookupCulture,@pbCalledFromCentura)+"
						as 'Activity',	
			isnull(DATEPART(HOUR,D.TOTALTIME ),0)*60 + isnull(DATEPART(HOUR,D.TIMECARRIEDFORWARD ),0)*60 + 
				isnull(DATEPART(MINUTE, D.TOTALTIME),0) + isnull(DATEPART(MINUTE, D.TIMECARRIEDFORWARD),0)
						as 'TotalTime',
			CASE WHEN D.TIMEVALUE > 0 THEN
				isnull(DATEPART(HOUR,D.TOTALTIME ),0)*60 + isnull(DATEPART(MINUTE, D.TOTALTIME),0)
				+
				isnull(DATEPART(HOUR,D.TIMECARRIEDFORWARD ),0)*60 + isnull(DATEPART(MINUTE, D.TIMECARRIEDFORWARD),0) 
				ELSE 0
				END 		as 'ChargeableMinutes',
			CASE WHEN D.TIMEVALUE = 0 or D.TIMEVALUE is null THEN
				isnull(DATEPART(HOUR,D.TOTALTIME ),0)*60 + isnull(DATEPART(MINUTE, D.TOTALTIME),0)
				+
				isnull(DATEPART(HOUR,D.TIMECARRIEDFORWARD ),0)*60 + isnull(DATEPART(MINUTE, D.TIMECARRIEDFORWARD),0) 
				ELSE 0
				END 			as 'NonChargeableMinutes',
			(CAST(CASE WHEN D.TIMEVALUE > 0 THEN
				isnull(DATEPART(HOUR,D.TOTALTIME ),0)*60 + isnull(DATEPART(MINUTE, D.TOTALTIME),0)
				+
				isnull(DATEPART(HOUR,D.TIMECARRIEDFORWARD ),0)*60 + isnull(DATEPART(MINUTE, D.TIMECARRIEDFORWARD),0)
				ELSE 0 END AS FLOAT)
				/
				(CAST(ISNULL((SC.COLDECIMAL*60), (8.00*60)) AS FLOAT)) / @nNumberOfDays) as 'ChargeablePercent',	     
			D.TOTALUNITS		as 'TotalUnits',
			CASE WHEN D.TIMEVALUE = 0 THEN null 
				ELSE D.TIMEVALUE 
				END		as 'Value',
			D.DISCOUNTVALUE		as 'Discount',
			D.FOREIGNCURRENCY	as 'ForeignCurrency',
			D.FOREIGNVALUE		as 'ForeignValue',
			D.FOREIGNDISCOUNT	as 'ForeignDiscount',
			@sLocalCurrencyCode	as LocalCurrencyCode,
			@nLocalDecimalPlaces	as LocalDecimalPlaces,
			D.CREATEDON,
			1 as TimeUnitOnlyOrder,
			C.IRN,
			dbo.fn_FormatNameUsingNameNo(N.NAMENO, null)
		from 	DIARY D			
		left join CASES C		on (C.CASEID = D.CASEID)
		left join NAME N 		on (N.NAMENO = D.NAMENO)		
		left join WIPTEMPLATE W 	on (W.WIPCODE = D.ACTIVITY)
		left join SITECONTROL SC 	on (SC.CONTROLID = 'Standard Daily Hours')	
		where exists ("+char(10)+
			"Select 1 from  #TempTable as XD" +char(10)+
			"where XD.EMPLOYEENO=D.EMPLOYEENO"+char(10)+
			"and XD.ENTRYNO=D.ENTRYNO"+char(10)+
			"and XD.ISTIMER = 0)
		AND convert(varchar(8), D.STARTTIME, 108) = '00:00:00'"

		Set @sSQLString = @sSQLString + @sOrderBy

		exec @nErrorCode = sp_executesql @sSQLString,
						N'@pnUserIdentityId 		int,
						  @nNumberOfDays		int,
						  @sLocalCurrencyCode		nvarchar(3),
						  @nLocalDecimalPlaces		tinyint',					 
						  @pnUserIdentityId 		= @pnUserIdentityId,
						  @nNumberOfDays		= @nNumberOfDays,
						  @sLocalCurrencyCode		= @sLocalCurrencyCode,
						  @nLocalDecimalPlaces		= @nLocalDecimalPlaces
		Set @pnRowCount=@@Rowcount
	
	END
	ELSE 
	BEGIN
		Set @sSQLString = "
			Select 
			null 		as 'Date',
			null		as 'StartDateTime',
			null		as 'FinishDateTime',
			null		as 'StaffKey',
			null		as 'CaseKey',
			null		as 'NameKey',
			null		as 'Narrative',
			null		as 'Notes',
			null		as 'Reference',
			null		as 'Activity',	
			null		as 'TotalTime',
			null		as 'ChargeableMinutes',
			null		as 'NonChargeableMinutes',
			null		as 'ChargeablePercent',	     
			null		as 'TotalUnits',
			null		as 'Value',
			null		as 'Discount',
			null		as 'ForeignCurrency',
			null		as 'ForeignValue',
			null		as 'ForeignDiscount',
			null		as LocalCurrencyCode,
			null		as LocalDecimalPlaces"
		
		
		exec @nErrorCode = sp_executesql @sSQLString
		
		Set @pnRowCount=@@Rowcount	
	END

End	

Return @nErrorCode
GO

Grant execute on dbo.ts_ListReportData to public
GO
