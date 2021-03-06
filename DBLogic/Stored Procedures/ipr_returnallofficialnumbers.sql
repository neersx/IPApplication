-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ipr_ReturnAllOfficialNumbers
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ipr_ReturnAllOfficialNumbers]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ipr_ReturnAllOfficialNumbers.'
	Drop procedure [dbo].[ipr_ReturnAllOfficialNumbers]
End
Print '**** Creating Stored Procedure dbo.ipr_ReturnAllOfficialNumbers...'
Print ''
go

SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO

create procedure dbo.ipr_ReturnAllOfficialNumbers
		@psEntryPoint varchar(254), 
		@psWhenRequested varchar(254),
		@psSqlUser nvarchar(40), 
		@psCaseId varchar(254),
		@pnUserIdentityId int	= null 
as
-- PROCEDURE :	ipr_ReturnAllOfficialNumbers
-- VERSION :	6
-- COPYRIGHT: 	Copyright 1993 - 2004 CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	This is a sample stored procedure - for instructions see SQA6290.
-- MODIFICATIONS :
-- Date		Who	SQA#	Version	Change
-- ------------	-------	-----	-------	----------------------------------------------- 
-- 17/01/2001	CStory		1	Created
-- 13/12/2004	AB	10793	2	Put grant and go statement at end of sp.
-- 07/02/2005	AB	10981	3	Insert data item.itemid = 500 removed from end of sp.
-- 16/11/2005	vql	9704	4	When updating ACTIVITYHISTORY table insert @pnUserIdentityId. Create @pnUserIdentityId also.
-- 21 Oct 2011	DL	19708	5	Change @psSqlUser from varchar(20) to nvarchar(40) to match ACTIVITYREQUEST.SQLUSER
-- 02 May 2014	SF 	33461	6	IDENTITYID from the ACTIVITYREQUEST should not be lost.

	declare @IRN			varchar(20)
	declare @CurrentLetterDate	datetime
	declare @OldLetterDate		datetime
	declare @WhenOccurred 		datetime
	declare @ProcessedFlag		int
	declare @LetterNo		int
	declare @WhenRequested		datetime
	
	select @IRN = @psEntryPoint
	select @CurrentLetterDate = getdate()
	select @WhenRequested = convert(datetime,@psWhenRequested)
	select	@OldLetterDate = NULL, @ProcessedFlag = NULL, @LetterNo = NULL, @WhenOccurred = NULL
	
	-- Check the activityRequest row, if it has a letter date then it is a reprint.
	
	select	@OldLetterDate = LETTERDATE, @WhenOccurred = WHENOCCURRED, @LetterNo = LETTERNO
	from	ACTIVITYREQUEST AR
	where	WHENREQUESTED = @psWhenRequested
	and	AR.CASEID = @psCaseId
	
	if @WhenOccurred is null
	   Begin

		insert into ACTIVITYHISTORY (
			CASEID,			WHENREQUESTED,		SQLUSER,		QUESTIONNO,
			INSTRUCTOR,		OWNER,			EMPLOYEENO,		PROGRAMID,
			ACTION,			EVENTNO,		CYCLE,			LETTERNO,
			ALTERNATELETTER,	COVERINGLETTERNO,	HOLDFLAG,		SPLITBILLFLAG,
			BILLPERCENTAGE,		DEBITNOTENO,		ENTITYNO,		DEBTORNAMETYPE,
			DEBITNOTEDETAIL,	LETTERDATE,		DELIVERYID,		ACTIVITYTYPE,
			ACTIVITYCODE,		PROCESSED,		TRANSACTIONFLAG,	PRODUCECHARGES,
			WHENOCCURRED,		STATUSCODE,		RATENO,			PAYFEECODE,
			ENTEREDQUANTITY,	ENTEREDAMOUNT,		DISBCURRENCY,		DISBEXCHANGERATE,
			SERVICECURRENCY,	SERVEXCHANGERATE,	BILLCURRENCY,		BILLEXCHANGERATE,
			DISBTAXCODE,		SERVICETAXCODE,		DISBNARRATIVE,		SERVICENARRATIVE,
			DISBAMOUNT,		SERVICEAMOUNT,		DISBTAXAMOUNT,		SERVICETAXAMOUNT,
			TOTALDISCOUNT,		DISBWIPCODE,		SERVICEWIPCODE,		SYSTEMMESSAGE,
			DISBEMPLOYEENO,		SERVEMPLOYEENO,		IDENTITYID
			)

		select 	AR.CASEID,		WHENREQUESTED,		SQLUSER,		QUESTIONNO,
			INSTRUCTOR,		OWNER,			EMPLOYEENO,		PROGRAMID,
			ACTION,			EVENTNO,		CYCLE,			LETTERNO,
			ALTERNATELETTER,	COVERINGLETTERNO,	HOLDFLAG,		SPLITBILLFLAG,
			AR.BILLPERCENTAGE,	DEBITNOTENO,		ENTITYNO,		DEBTORNAMETYPE,
			DEBITNOTEDETAIL,	@CurrentLetterDate,	DELIVERYID,		ACTIVITYTYPE,
			ACTIVITYCODE,		1,			TRANSACTIONFLAG,	PRODUCECHARGES,
			@CurrentLetterDate,	AR.STATUSCODE,		RATENO,			PAYFEECODE,
			ENTEREDQUANTITY,	ENTEREDAMOUNT,		DISBCURRENCY,		DISBEXCHANGERATE,
			SERVICECURRENCY,	SERVEXCHANGERATE,	BILLCURRENCY,		BILLEXCHANGERATE,
			DISBTAXCODE,		SERVICETAXCODE,		DISBNARRATIVE,		SERVICENARRATIVE,
			DISBAMOUNT,		SERVICEAMOUNT,		DISBTAXAMOUNT,		SERVICETAXAMOUNT,
			TOTALDISCOUNT,		DISBWIPCODE,		SERVICEWIPCODE,		SYSTEMMESSAGE,
			DISBEMPLOYEENO,		SERVEMPLOYEENO,		isnull(AR.IDENTITYID, @pnUserIdentityId)
		from	CASENAME CN, ACTIVITYREQUEST AR
		where	@psCaseId = CN.CASEID
		and	CN.NAMETYPE = 'I'
		and	AR.CASEID in (select	CASEID
					from	CASENAME CN1
					where	NAMETYPE = 'I'
					and	CN1.NAMENO = CN.NAMENO
					and	CN1.CASEID <> CN.CASEID)
		and	LETTERNO = @LetterNo
	
		update	ACTIVITYREQUEST
		set	WHENOCCURRED = @CurrentLetterDate, LETTERDATE = @CurrentLetterDate
		from	ACTIVITYREQUEST AR
		where	WHENREQUESTED = @WhenRequested
		and	AR.CASEID = @psCaseId
	  end
	else
	  begin
	--	select convert(varchar(5),@LetterNo)+'@@@'+@IRN+'@@@'+@OldLetterDate
	--	select 'In here'
		update	ACTIVITYHISTORY
		set	WHENOCCURRED = @CurrentLetterDate, LETTERDATE = @CurrentLetterDate
		from	CASENAME CN, ACTIVITYHISTORY AH
		where	AH.CASEID = CN.CASEID
		and	NAMETYPE = 'I'
		and	AH.LETTERNO = @LetterNo
		and	LETTERDATE = @OldLetterDate
		and	NAMENO in (Select NAMENO
				 from	CASENAME CN1
				 where	CN1.CASEID = @psCaseId
				 and	NAMETYPE = 'I')
	
		update	ACTIVITYREQUEST
		set	WHENOCCURRED = @CurrentLetterDate, LETTERDATE = @CurrentLetterDate
		from	ACTIVITYREQUEST AR
		where	WHENREQUESTED = @WhenRequested
		and	AR.CASEID = @psCaseId
	  end
	
	delete	ACTIVITYREQUEST
	from	CASES C, CASENAME CN, ACTIVITYREQUEST AR
	where	C.IRN = @IRN
	and	C.CASEID = CN.CASEID
	and	CN.NAMETYPE = 'I'
	and	AR.CASEID in (select	CASEID
				from	CASENAME CN1
				where	NAMETYPE = 'I'
				and	CN1.NAMENO = CN.NAMENO
				and	CN1.CASEID <> C.CASEID)
	and	AR.LETTERNO = @LetterNo
	
	select	OFFICIALNUMBER
	from	ACTIVITYREQUEST AR, OFFICIALNUMBERS O
	where	AR.WHENREQUESTED = @WhenRequested
	and	AR.CASEID = @psCaseId
	and	AR.CASEID = O.CASEID
	and	O.NUMBERTYPE = 'A'
	union
	select	OFFICIALNUMBER
	from	CASES C, CASENAME CN, ACTIVITYHISTORY AH, OFFICIALNUMBERS O
	where	C.IRN = @IRN
	and	C.CASEID = CN.CASEID
	and	CN.NAMETYPE = 'I'
	and	AH.CASEID in (select	CASEID
				from	CASENAME CN1
				where	NAMETYPE = 'I'
				and	CN1.NAMENO = CN.NAMENO)
	and	AH.LETTERNO = @LetterNo
	and	AH.LETTERDATE = @CurrentLetterDate
	and	AH.CASEID = O.CASEID
	and	O.NUMBERTYPE = 'A'
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

grant execute on [dbo].[ipr_ReturnAllOfficialNumbers] to public
go
