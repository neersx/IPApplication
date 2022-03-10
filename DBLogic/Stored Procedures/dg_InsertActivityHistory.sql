-----------------------------------------------------------------------------------------------------------------------------
-- Creation of dg_InsertActivityHistory
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'dbo.dg_InsertActivityHistory') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.dg_InsertActivityHistory.'
	Drop procedure dbo.dg_InsertActivityHistory
End
Print '**** Creating Stored Procedure dbo.dg_InsertActivityHistory...'
Print ''
GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

Create	procedure dbo.dg_InsertActivityHistory

	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@psSQLUser		nvarchar(40),
	@pdtWhenRequested	datetime
AS
-- Procedure :	dg_InsertActivityHistory
-- VERSION :	1
-- DESCRIPTION:	This stored procedure will insert a row into the ActivityHistory table
-- COPYRIGHT:	Copyright 1993 - 2011 CPA Software Solutions (Australia) Pty Limited
-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 5 Aug 2011	PK	R10708	1	Initial creation

-- Declare variables
Declare	@nErrorCode			int,
	@sSQLString			nvarchar(4000),
	@sInsertString			nvarchar(4000),
	@sValuesString			nvarchar(4000)

-- Initialise
-- Prevent row counts
Set	NOCOUNT OFF
Set	CONCAT_NULL_YIELDS_NULL off

-- Initialize internal variables
Set	@nErrorCode = 0

If @nErrorCode = 0
Begin
	Set @sInsertString = "Insert into ACTIVITYHISTORY
				("


	/*Set @sInsertString = @sInsertString+CHAR(10)+"
					           (
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

			"*/

	Set @sInsertString = @sInsertString+CHAR(10)+"
		WHENREQUESTED,
		SQLUSER
		"

	Set @sValuesString = @sValuesString+CHAR(10)+"(
					@pdtWhenRequested,
					@psSQLUser
			"

	Set @sInsertString = @sInsertString+CHAR(10)+")"
	Set @sValuesString = @sValuesString+CHAR(10)+")"

	Set @sSQLString = @sInsertString + ' values ' + @sValuesString

	exec @nErrorCode=sp_executesql @sSQLString,
			N'
			@psSQLUser		nvarchar(40),
			@pdtWhenRequested	datetime',
			@psSQLUser		= @psSQLUser,
			@pdtWhenRequested	= @pdtWhenRequested

	Set @nErrorCode = @@error
End

Return @nErrorCode
go

Grant execute on dbo.dg_InsertActivityHistory to Public
go
