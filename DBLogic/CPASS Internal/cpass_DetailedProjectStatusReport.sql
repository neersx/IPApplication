-----------------------------------------------------------------------------------------------------------------------------
-- Creation of cpass_DetailedProjStatusRpt
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[cpass_DetailedProjStatusRpt]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.cpass_DetailedProjStatusRpt.'
	Drop procedure [dbo].[cpass_DetailedProjStatusRpt]
End
Print '**** Creating Stored Procedure dbo.cpass_DetailedProjStatusRpt...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.cpass_DetailedProjStatusRpt
(
	@psFamily			nvarchar(20)	= null  -- the Family of Cases to be reported on
)
AS
-- PROCEDURE :	cpass_DetailedProjStatusRpt
-- DESCRIPTION:	Gets the title values for the Detailed Project Status Report
-- COPYRIGHT:	Copyright 1993 - 2004 CPA Software Solutions (Australia) Pty Limited
-- VERSION:	1
-- MODIFICATION
-- Date		Who	Number	Version	Description
-- ----         ---	------	-------	-----------------------------------------------------------
-- 10 Jun 2006	JD		1	Procedure created


Set nocount on
Set concat_null_yields_null off


-- Declare a temporary table to hold the result returned from 
-- the cs_GetBudgetDetails table

Declare	@ErrorCode	int
declare @ClientName 	nvarchar(254)
declare @Country 	nvarchar(60)
declare @Contact 	nvarchar(254)
declare @ClientSatisfaction 	nvarchar(80)
declare @ProjectStartDate	datetime 
declare @CurrentExpectedLiveDate	datetime  
declare @OriginalExpectedLiveDate	datetime  

Set @ErrorCode=0

If @ErrorCode=0
Begin
	
	SELECT 	@ClientName = 
	  CASE WHEN N.TITLE IS NOT NULL THEN N.TITLE + ' '  END
	+ CASE WHEN N.FIRSTNAME IS NOT NULL THEN N.FIRSTNAME + ' ' END
	+ N.NAME
	FROM  	CASES C
	join	CASENAME CN on ( CN.CASEID=C.CASEID )
	join	NAME N on ( N.NAMENO = CN.NAMENO )
	WHERE 	C.FAMILY     = @psFamily 
	AND   	C.PROPERTYTYPE <> 'I'
	AND   	CN.NAMETYPE  = 'I' 
	AND	CN.SEQUENCE = ( 	SELECT 	MIN(CN2.SEQUENCE) 
					FROM 	CASENAME CN2 
					WHERE 	CN2.NAMETYPE  = 'I' 
					AND	CN2.CASEID=C.CASEID )
	Set @ErrorCode=@@Error

	PRINT 'Client Name'

end

If @ErrorCode=0
Begin
	SELECT 	@Country = CT.COUNTRY
	FROM  	CASES C
	join	COUNTRY CT on ( CT.COUNTRYCODE = C.COUNTRYCODE )
	WHERE 	C.PROPERTYTYPE = 'B'
	AND 	C.FAMILY = @psFamily

	Set @ErrorCode=@@Error

	PRINT 'Country'

End

If @ErrorCode=0
Begin
	SELECT 	@ProjectStartDate = EVENTDATE
	FROM  	CASES C
	JOIN	CASEEVENT E ON ( E.CASEID = C.CASEID )
	WHERE 	C.PROPERTYTYPE = 'B'
	AND 	C.FAMILY = @psFamily
	AND 	E.EVENTNO = -4
	ORDER BY E.CYCLE DESC

	Set @ErrorCode=@@Error

	PRINT 'Project Start Date'

End

If @ErrorCode=0
Begin
	SELECT 	@OriginalExpectedLiveDate = EVENTDATE
	FROM  	CASES C
	JOIN	CASEEVENT E ON ( E.CASEID = C.CASEID )
	WHERE 	C.PROPERTYTYPE = 'B'
	AND 	C.FAMILY = @psFamily
	AND 	E.EVENTNO = -6
	ORDER BY E.CYCLE DESC

	Set @ErrorCode=@@Error

	PRINT 'Original Expected Live Date'

End

If @ErrorCode=0
Begin
	SELECT 	@CurrentExpectedLiveDate = EVENTDATE
	FROM  	CASES C
	JOIN	CASEEVENT E ON ( E.CASEID = C.CASEID )
	WHERE 	C.PROPERTYTYPE = 'B'
	AND 	C.FAMILY = @psFamily
	AND 	E.EVENTNO = -8
	ORDER BY E.CYCLE DESC

	Set @ErrorCode=@@Error

	PRINT 'Current Expected Live Date'

End

If @ErrorCode=0
Begin
	SELECT @Contact = 
	CASE WHEN N.FIRSTNAME IS NOT NULL THEN N.FIRSTNAME + ' ' END
	+ N.NAME 
	FROM  	CASES C
	join	CASENAME CN on ( CN.CASEID=C.CASEID )
	join	NAME N on ( N.NAMENO = CN.NAMENO )
	WHERE  	C.PROPERTYTYPE = 'B'
	AND   	C.FAMILY = @psFamily 
	AND   	CN.NAMETYPE  = 'EMP' 
	AND	CN.SEQUENCE = ( 	SELECT 	MIN(CN2.SEQUENCE) 
					FROM 	CASENAME CN2 
					WHERE 	CN2.NAMETYPE  = 'EMP' 
					AND	CN2.CASEID = C.CASEID )

	Set @ErrorCode=@@Error

	PRINT 'Contact'

End

If @ErrorCode=0
Begin
	SELECT	@ClientSatisfaction = T.DESCRIPTION
	FROM  	CASES C
	join	CASECHECKLIST CC on ( CC.CASEID = C.CASEID )
	join	TABLECODES T on ( T.TABLECODE = CC.TABLECODE )
	WHERE 	C.PROPERTYTYPE = 'B'
	AND 	CC.QUESTIONNO = 611
	AND 	C.FAMILY = @psFamily

	Set @ErrorCode=@@Error

	PRINT 'Client Satisfaction'

End

If @ErrorCode=0
Begin
	SELECT	@psFamily as Family
	, @ProjectStartDate as [Project Start Date] 
	, @OriginalExpectedLiveDate as [Original Expected Live Date] 
	, @CurrentExpectedLiveDate as [Current Expected Live Date] 
	, datediff( Day, @ProjectStartDate, @OriginalExpectedLiveDate ) as [Original Expected Duration] 
	, datediff( Day, @ProjectStartDate, @CurrentExpectedLiveDate ) as [Current Expected Duration]  
	, datediff( Day, @ProjectStartDate, GetDate() ) as [Duration to Date] 
	, @ClientName as [Client Name]
	, @Country as [Country]
	, @Contact as [Contact]
	, @ClientSatisfaction as [Client Satisfaction]

	Set @ErrorCode=@@Error

	PRINT 'Result Set'

End

Return @ErrorCode
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

grant execute on dbo.cpass_DetailedProjStatusRpt to public
go
