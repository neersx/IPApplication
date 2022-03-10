-----------------------------------------------------------------------------------------------------------------------------
-- Creation of dg_ListActivityRequests
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[dg_ListActivityRequests]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.dg_ListActivityRequests.'
	Drop procedure [dbo].[dg_ListActivityRequests]
End
Print '**** Creating Stored Procedure dbo.dg_ListActivityRequests...'
Print ''
GO

Create	procedure dbo.dg_ListActivityRequests

AS
-- Procedure :	dg_ListActivityRequests
-- VERSION :	4
-- DESCRIPTION:	This stored procedure will return a set of  Activity Requests on the queue
-- COPYRIGHT:	Copyright 1993 - 2011 CPA Software Solutions (Australia) Pty Limited
-- MODIFICATIONS :
-- Date		Who	Change		Version	Description
-- -----------	-------	------		-------	----------------------------------------------- 
-- 29 July 2011	PK	RFC10708	1	Initial creation
-- 23 Dec 2011	PK	RFC11035	2	Add support for send as draft email requests
-- 03 July 2012	PK	RFC11572	3	Exclude requests with an outstanding policing activity
-- 21 Sep 2012	DL	R12763		4	Fix collation error by adding 'collate database_default' to character based columns in temp table definition.


-- Declare variables
Declare	@nErrorCode			int

Declare @tbl table (
	ACTIVITYID		int,
	CASEID			int,
        WHENREQUESTED		datetime,
        SQLUSER			nvarchar(40) collate database_default,
        QUESTIONNO		smallint,
        INSTRUCTOR		int,
        OWNER			int,
        EMPLOYEENO		int,
        PROGRAMID		nvarchar(8) collate database_default,
        ACTION			nvarchar(2) collate database_default,
        EVENTNO			int,
        CYCLE			smallint,
        LETTERNO		smallint,
        ALTERNATELETTER		smallint,
        COVERINGLETTERNO	smallint,
        HOLDFLAG		decimal(1,0),
        DELIVERYID		smallint,
        ACTIVITYTYPE		smallint,
        ACTIVITYCODE		int,
        PROCESSED		decimal(1,0),
        WHENOCCURRED		datetime,
        STATUSCODE		smallint,
        SYSTEMMESSAGE		nvarchar(254) collate database_default,
        EMAILOVERRIDE		nvarchar(50) collate database_default,
        IDENTITYID		int,
        FILENAME		nvarchar(254) collate database_default,
        XMLFILTER		nvarchar(254) collate database_default
)
-- Initialise
-- Prevent row counts
Set	NOCOUNT on
Set	CONCAT_NULL_YIELDS_NULL off
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

-- Initialize internal variables
Set	@nErrorCode = 0

If @nErrorCode = 0
Begin
	Insert into @tbl
		(
		ACTIVITYID,
		CASEID,
		WHENREQUESTED,
		SQLUSER,
		QUESTIONNO,
		INSTRUCTOR,
		OWNER,
		EMPLOYEENO,
		PROGRAMID,
		ACTION,
		EVENTNO,
		CYCLE,
		LETTERNO,
		ALTERNATELETTER,
		COVERINGLETTERNO,
		HOLDFLAG,
		DELIVERYID,
		ACTIVITYTYPE,
		ACTIVITYCODE,
		PROCESSED,
		WHENOCCURRED,
		STATUSCODE,
		SYSTEMMESSAGE,
		EMAILOVERRIDE,
		IDENTITYID,
		FILENAME,
		XMLFILTER		
		)
	Select 
		ar.ACTIVITYID,
		ar.CASEID,
		ar.WHENREQUESTED,
		ar.SQLUSER,
		ar.QUESTIONNO,
		ar.INSTRUCTOR,
		ar.OWNER,
		ar.EMPLOYEENO,
		ar.PROGRAMID,
		ar.ACTION,
		ar.EVENTNO,
		ar.CYCLE,
		ar.LETTERNO,
		ar.ALTERNATELETTER,
		ar.COVERINGLETTERNO,
		ar.HOLDFLAG,
		ar.DELIVERYID,
		ar.ACTIVITYTYPE,
		ar.ACTIVITYCODE,
		ar.PROCESSED,
		ar.WHENOCCURRED,
		ar.STATUSCODE,
		ar.SYSTEMMESSAGE,
		ar.EMAILOVERRIDE,
		ar.IDENTITYID,
		ar.FILENAME,
		ar.XMLFILTER		
	From	ACTIVITYREQUEST ar
	left join (SELECT distinct CASEID  -- implemented the same way as client server to check for policing activity
		FROM POLICING with (nolock)
		WHERE SYSGENERATEDFLAG=1) p
		ON (p.CASEID=ar.CASEID)
	join	LETTER l
		on l.LETTERNO = ar.LETTERNO
	left join DELIVERYMETHOD dm
		on dm.DELIVERYID = l.DELIVERYID
	Where	isnull(ar.PROCESSED,0) = 0
		and isnull(ar.HOLDFLAG,0) = 0
		and (l.DOCUMENTTYPE = 5	--reporting services report
		or (dm.DELIVERYTYPE = -5300 and (l.DOCUMENTTYPE = 5 or l.DOCUMENTTYPE = 6))) -- send as draft email and (documenttype = reporting services report or documenttype = deliver only
		and p.CASEID is null

	Update	ACTIVITYREQUEST Set HOLDFLAG = 1
	Where	ACTIVITYID in (Select ACTIVITYID from @tbl)
	
	Update	@tbl Set HOLDFLAG = 1
	
	Select	ar.ACTIVITYID as ActivityID,
		ar.CASEID as CaseID,
		ar.WHENREQUESTED as WhenRequested,
		ar.SQLUSER as SQLUser,
		ar.QUESTIONNO as QuestionNo,
		ar.INSTRUCTOR as Instructor,
		ar.OWNER as Owner,
		ar.EMPLOYEENO as EmployeeNo,
		ar.PROGRAMID as ProgramID,
		ar.ACTION as Action,
		ar.EVENTNO as EventNo,
		ar.CYCLE as Cycle,
		ar.LETTERNO as LetterNo,
		ar.ALTERNATELETTER as AlternateLetter,
		ar.COVERINGLETTERNO as CoveringLetterNo,
		ar.HOLDFLAG as HoldFlag,
		ar.DELIVERYID as DeliveryID,
		ar.STATUSCODE as StatusCode,
		ar.FILENAME as FileName,
		ar.XMLFILTER as XMLFilter,
		ar.SYSTEMMESSAGE as SystemMessage,
		ar.WHENOCCURRED as WhenOccurred
	From	@tbl ar

	Set @nErrorCode = @@error
End

Return @nErrorCode
go

Grant execute on dbo.dg_ListActivityRequests to Public
go
