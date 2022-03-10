-----------------------------------------------------------------------------------------------------------------------------
-- Creation of dg_GetActivityRequest
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[dg_GetActivityRequest]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.dg_GetActivityRequest.'
	Drop procedure [dbo].[dg_GetActivityRequest]
End
Print '**** Creating Stored Procedure dbo.dg_GetActivityRequest...'
Print ''
GO

Create	procedure dbo.dg_GetActivityRequest
	@psSQLUser		nvarchar(40),
	@pdtWhenRequested	datetime,
	@pnCaseID		int,
	@pnActivityID		int
AS
-- Procedure :	dg_GetActivityRequest
-- VERSION :	2
-- DESCRIPTION:	This stored procedure will return a single Activity Request
-- COPYRIGHT:	Copyright 1993 - 2011 CPA Software Solutions (Australia) Pty Limited
-- MODIFICATIONS :
-- Date		Who	Change		Version	Description
-- -----------	-------	------		-------	----------------------------------------------- 
-- 05 Oct 2011	PK	RFC10708	1	Initial creation
-- 28 May 2012	PK	11572		2	Exclude and activity requests that has a policing activity

-- Declare variables
Declare	@nErrorCode			int

-- Initialise
-- Prevent row counts
Set	NOCOUNT on
Set	CONCAT_NULL_YIELDS_NULL off
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

-- Initialize internal variables
Set	@nErrorCode = 0

If @nErrorCode = 0
Begin
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
	From	ACTIVITYREQUEST ar
	LEFT JOIN (SELECT distinct CASEID  -- implemented the same way as client server to check for policing activity
		FROM POLICING with (nolock)
		WHERE SYSGENERATEDFLAG=1) p
		ON (p.CASEID=ar.CASEID)
	Where SQLUSER = @psSQLUser
	and WHENREQUESTED = @pdtWhenRequested
	and ar.CASEID = @pnCaseID
	and ACTIVITYID = @pnActivityID
	and p.CASEID is null

	Set @nErrorCode = @@error
End

Return @nErrorCode
go

Grant execute on dbo.dg_GetActivityRequest to Public
go
