-----------------------------------------------------------------------------------------------------------------------------
-- Creation of dg_CopyActivityRequestToActivityHistory
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'dbo.dg_CopyActivityRequestToActivityHistory') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.dg_CopyActivityRequestToActivityHistory.'
	Drop procedure dbo.dg_CopyActivityRequestToActivityHistory
End
Print '**** Creating Stored Procedure dbo.dg_CopyActivityRequestToActivityHistory...'
Print ''
GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

Create	procedure dbo.dg_CopyActivityRequestToActivityHistory
	@psSQLUser		nvarchar(40),
	@pdtWhenRequested	datetime,
	@pnCaseID		int,
	@pnActivityID		int,
	@pdtWhenOccurred	datetime = null,
	@pbProcessed		bit = null,
	@pbDeleteRequest	bit = null
AS
-- Procedure :	dg_CopyActivityRequestToActivityHistory
-- VERSION :	1
-- DESCRIPTION:	This stored procedure will copy a row from the ActivityRequest table
--		into the ActivityHistory table and then delete it from the ActivityRequest table
-- COPYRIGHT:	Copyright 1993 - 2011 CPA Software Solutions (Australia) Pty Limited
-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 5 Aug 2011	PK	R10708	1	Initial creation
-- 19 Dec 2011	PK	11035	2	Add functionality to delete activity request row after copied to history

-- Declare variables
Declare	@nErrorCode			int,
	@sSQLString			nvarchar(4000),
	@nRowCountInsert		int,
	@nRowCountDelete		int

-- Initialise
-- Prevent row counts
Set	NOCOUNT OFF
Set	CONCAT_NULL_YIELDS_NULL off

-- Initialize internal variables
Set	@nErrorCode = 0

If @nErrorCode = 0
Begin
	Begin transaction tran1
		Insert into ACTIVITYHISTORY (
		   CASEID
		   ,WHENREQUESTED
		   ,SQLUSER
		   ,QUESTIONNO
		   ,INSTRUCTOR
		   ,OWNER
		   ,EMPLOYEENO
		   ,PROGRAMID
		   ,ACTION
		   ,EVENTNO
		   ,CYCLE
		   ,LETTERNO
		   ,ALTERNATELETTER
		   ,COVERINGLETTERNO
		   ,HOLDFLAG
		   ,SPLITBILLFLAG
		   ,BILLPERCENTAGE
		   ,DEBITNOTENO
		   ,ENTITYNO
		   ,DEBTORNAMETYPE
		   ,DEBITNOTEDETAIL
		   ,LETTERDATE
		   ,DELIVERYID
		   ,ACTIVITYTYPE
		   ,ACTIVITYCODE
		   ,PROCESSED
		   ,TRANSACTIONFLAG
		   ,PRODUCECHARGES
		   ,WHENOCCURRED
		   ,STATUSCODE
		   ,RATENO
		   ,PAYFEECODE
		   ,ENTEREDQUANTITY
		   ,ENTEREDAMOUNT
		   ,DISBCURRENCY
		   ,DISBEXCHANGERATE
		   ,SERVICECURRENCY
		   ,SERVEXCHANGERATE
		   ,BILLCURRENCY
		   ,BILLEXCHANGERATE
		   ,DISBTAXCODE
		   ,SERVICETAXCODE
		   ,DISBNARRATIVE
		   ,SERVICENARRATIVE
		   ,DISBAMOUNT
		   ,SERVICEAMOUNT
		   ,DISBTAXAMOUNT
		   ,SERVICETAXAMOUNT
		   ,TOTALDISCOUNT
		   ,DISBWIPCODE
		   ,SERVICEWIPCODE
		   ,SYSTEMMESSAGE
		   ,DISBEMPLOYEENO
		   ,SERVEMPLOYEENO
		   ,DISBORIGINALAMOUNT
		   ,SERVORIGINALAMOUNT
		   ,DISBBILLAMOUNT
		   ,SERVBILLAMOUNT
		   ,DISCBILLAMOUNT
		   ,TAKENUPAMOUNT
		   ,DISBDISCOUNT
		   ,SERVDISCOUNT
		   ,DISBBILLDISCOUNT
		   ,SERVBILLDISCOUNT
		   ,DISBCOSTLOCAL
		   ,DISBCOSTORIGINAL
		   ,DISBDISCORIGINAL
		   ,SERVDISCORIGINAL
		   ,ESTIMATEFLAG
		   ,EMAILOVERRIDE
		   ,DISBCOSTCALC1
		   ,DISBCOSTCALC2
		   ,SERVCOSTCALC1
		   ,SERVCOSTCALC2
		   ,IDENTITYID
		   ,DEBTOR
		   ,SEPARATEDEBTORFLAG
		   ,PRODUCTCODE
		   ,XMLINSTRUCTIONID
		   ,CHECKLISTTYPE
		   ,SERVCOSTLOCAL
		   ,SERVCOSTORIGINAL
		   ,FILENAME
		   ,DIRECTPAYFLAG
		   ,BATCHNO
		   ,EDEOUTPUTTYPE
		   ,REQUESTID
		   ,XMLFILTER
		   ,DISBSTATETAXCODE
		   ,SERVSTATETAXCODE
		   ,DISBSTATETAXAMT
		   ,SERVSTATETAXAMT
		   ,LOGUSERID
		   ,LOGIDENTITYID
		   ,LOGTRANSACTIONNO
		   ,LOGDATETIMESTAMP
		   ,LOGAPPLICATION
		   ,LOGOFFICEID
		   ,GROUPACTIVITYID
		   ,DISBMARGINNO
		   ,SERVMARGINNO
		   ,DISBMARGIN
		   ,DISBHOMEMARGIN
		   ,DISBBILLMARGIN
		   ,SERVMARGIN
		   ,SERVHOMEMARGIN
		   ,SERVBILLMARGIN
		   ,DISBDISCFORMARGIN
		   ,DISBHOMEDISCFORMARGIN
		   ,DISBBILLDISCFORMARGIN
		   ,SERVDISCFORMARGIN
		   ,SERVHOMEDISCFORMARGIN
		   ,SERVBILLDISCFORMARGIN)
		Select 		    
		   CASEID
		   ,WHENREQUESTED
		   ,SQLUSER
		   ,QUESTIONNO
		   ,INSTRUCTOR
		   ,OWNER
		   ,EMPLOYEENO
		   ,PROGRAMID
		   ,ACTION
		   ,EVENTNO
		   ,CYCLE
		   ,LETTERNO
		   ,ALTERNATELETTER
		   ,COVERINGLETTERNO
		   ,HOLDFLAG
		   ,SPLITBILLFLAG
		   ,BILLPERCENTAGE
		   ,DEBITNOTENO
		   ,ENTITYNO
		   ,DEBTORNAMETYPE
		   ,DEBITNOTEDETAIL
		   ,LETTERDATE
		   ,DELIVERYID
		   ,ACTIVITYTYPE
		   ,ACTIVITYCODE
		   ,isnull(@pbProcessed,PROCESSED)
		   ,TRANSACTIONFLAG
		   ,PRODUCECHARGES
		   ,isnull(@pdtWhenOccurred,WHENOCCURRED)
		   ,STATUSCODE
		   ,RATENO
		   ,PAYFEECODE
		   ,ENTEREDQUANTITY
		   ,ENTEREDAMOUNT
		   ,DISBCURRENCY
		   ,DISBEXCHANGERATE
		   ,SERVICECURRENCY
		   ,SERVEXCHANGERATE
		   ,BILLCURRENCY
		   ,BILLEXCHANGERATE
		   ,DISBTAXCODE
		   ,SERVICETAXCODE
		   ,DISBNARRATIVE
		   ,SERVICENARRATIVE
		   ,DISBAMOUNT
		   ,SERVICEAMOUNT
		   ,DISBTAXAMOUNT
		   ,SERVICETAXAMOUNT
		   ,TOTALDISCOUNT
		   ,DISBWIPCODE
		   ,SERVICEWIPCODE
		   ,SYSTEMMESSAGE
		   ,DISBEMPLOYEENO
		   ,SERVEMPLOYEENO
		   ,DISBORIGINALAMOUNT
		   ,SERVORIGINALAMOUNT
		   ,DISBBILLAMOUNT
		   ,SERVBILLAMOUNT
		   ,DISCBILLAMOUNT
		   ,TAKENUPAMOUNT
		   ,DISBDISCOUNT
		   ,SERVDISCOUNT
		   ,DISBBILLDISCOUNT
		   ,SERVBILLDISCOUNT
		   ,DISBCOSTLOCAL
		   ,DISBCOSTORIGINAL
		   ,DISBDISCORIGINAL
		   ,SERVDISCORIGINAL
		   ,ESTIMATEFLAG
		   ,EMAILOVERRIDE
		   ,DISBCOSTCALC1
		   ,DISBCOSTCALC2
		   ,SERVCOSTCALC1
		   ,SERVCOSTCALC2
		   ,IDENTITYID
		   ,DEBTOR
		   ,SEPARATEDEBTORFLAG
		   ,PRODUCTCODE
		   ,XMLINSTRUCTIONID
		   ,CHECKLISTTYPE
		   ,SERVCOSTLOCAL
		   ,SERVCOSTORIGINAL
		   ,FILENAME
		   ,DIRECTPAYFLAG
		   ,BATCHNO
		   ,EDEOUTPUTTYPE
		   ,REQUESTID
		   ,XMLFILTER
		   ,DISBSTATETAXCODE
		   ,SERVSTATETAXCODE
		   ,DISBSTATETAXAMT
		   ,SERVSTATETAXAMT
		   ,LOGUSERID
		   ,LOGIDENTITYID
		   ,LOGTRANSACTIONNO
		   ,LOGDATETIMESTAMP
		   ,LOGAPPLICATION
		   ,LOGOFFICEID
		   ,GROUPACTIVITYID
		   ,DISBMARGINNO
		   ,SERVMARGINNO
		   ,DISBMARGIN
		   ,DISBHOMEMARGIN
		   ,DISBBILLMARGIN
		   ,SERVMARGIN
		   ,SERVHOMEMARGIN
		   ,SERVBILLMARGIN
		   ,DISBDISCFORMARGIN
		   ,DISBHOMEDISCFORMARGIN
		   ,DISBBILLDISCFORMARGIN
		   ,SERVDISCFORMARGIN
		   ,SERVHOMEDISCFORMARGIN
		   ,SERVBILLDISCFORMARGIN
           From ACTIVITYREQUEST
           Where SQLUSER = @psSQLUser
           and WHENREQUESTED = @pdtWhenRequested
           and CASEID = @pnCaseID
           and ACTIVITYID = @pnActivityID

	Set @nErrorCode = @@error
	
	Set @nRowCountInsert = @@ROWCOUNT
	
	If @pbDeleteRequest = 1
	and @nErrorCode = 0 
		Delete
		From ACTIVITYREQUEST
		Where SQLUSER = @psSQLUser
		and WHENREQUESTED = @pdtWhenRequested
		and CASEID = @pnCaseID
		and ACTIVITYID = @pnActivityID
	
	If @nRowCountInsert > 0
	and @nErrorCode = 0 
		COMMIT TRANSACTION tran1
	Else
		ROLLBACK TRANSACTION tran1
	
End

Return @nRowCountInsert
go

Grant execute on dbo.dg_CopyActivityRequestToActivityHistory to Public
go
