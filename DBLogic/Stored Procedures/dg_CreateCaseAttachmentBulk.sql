-----------------------------------------------------------------------------------------------------------------------------
-- Creation of dg_CreateCaseAttachmentBulk
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[dg_CreateCaseAttachmentBulk]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop Stored Procedure dbo.dg_CreateCaseAttachmentBulk.'
	drop procedure [dbo].[dg_CreateCaseAttachmentBulk]
	print '**** Creating Stored Procedure dbo.dg_CreateCaseAttachmentBulk...'
	print ''
end
go

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.dg_CreateCaseAttachmentBulk
(
	@pnActivityId			int,		
	@psAttachmentName		nvarchar(508), 	
	@psFileName			nvarchar(508)
)
AS
-- PROCEDURE :	dg_CreateCaseAttachmentBulk
-- VERSION :	5
-- DESCRIPTION:	create attachment for cases that processed in bulk by docgen
-- CALLED BY :	DOCSVR32.EXE
-- MODIFICATIONS :
-- Date		Who	SQA	Version	Change
-- ------------	-------	-----	-------	----------------------------------------------- 
-- 08/08/2008	DL	16723	1	Procedure created
-- 04/02/2010	DL	18430	2	Grant stored procedure to public
-- 14/05/2010	DL	18559	3	Create attachment for all cases included in a bill
-- 29/04/2014	SF	33461	4	Activity created for an ActivityRequest / ActivityHistory should populate SQLUSER and WHENREQUESTED
-- 30/04/2014	SF	33461	5	Use the collate database_default clause

Set NOCOUNT ON
Set CONCAT_NULL_YIELDS_NULL OFF
 
CREATE TABLE dbo.#TEMPCASE (
        CASEID			int,
        WHENREQUESTED		datetime,
        SQLUSER			nvarchar(40) collate database_default,
        ROWID			int identity(1,1)
)

declare @nErrorCode		int
declare @nFirstActivityNo	int
declare @nCaseCount		int 
declare @nDebitNoteNo		nvarchar(20)
declare @nCaseId		int

select @nErrorCode = 0, @nCaseCount = 0


-- Get all the cases that processed in bulk to attach the file
-- NOTE: User customised SP may have already moved request to history so need to also extract cases from ACTIVITYHISTORY
If @nErrorCode = 0
Begin
	insert into #TEMPCASE(CASEID, WHENREQUESTED, SQLUSER)
	select CASEID, WHENREQUESTED, SQLUSER 
	from ACTIVITYREQUEST 
	where GROUPACTIVITYID = @pnActivityId
	and ACTIVITYID <> @pnActivityId
	union all 
	select CASEID, WHENREQUESTED, SQLUSER 
	from ACTIVITYHISTORY
	where GROUPACTIVITYID = @pnActivityId

	Select @nErrorCode = @@ERROR, @nCaseCount = @@ROWCOUNT
End

-- Get all the cases included in the bill to attach the file
-- Note: an ACTIVITYREQUEST is a bill if the column DEBITNOTENO is not null
If @nErrorCode = 0  and @nCaseCount = 0
Begin
	select @nDebitNoteNo = DEBITNOTENO, @nCaseId = CASEID
	from ACTIVITYREQUEST
	where ACTIVITYID = @pnActivityId
	Set @nErrorCode = @@ERROR
	
	If @nErrorCode = 0  and @nDebitNoteNo is not null
	Begin
		Insert into #TEMPCASE(CASEID)
		select DISTINCT WH.CASEID
		from OPENITEM O
		join (	select  REFENTITYNO, REFTRANSNO, CASEID
			from WORKHISTORY
			group by REFENTITYNO, REFTRANSNO, CASEID) WH
					on (WH.REFENTITYNO=O.ITEMENTITYNO
					and WH.REFTRANSNO =O.ITEMTRANSNO)
		where O.OPENITEMNO = @nDebitNoteNo
		and WH.CASEID <> @nCaseId

		Select @nErrorCode = @@ERROR, @nCaseCount = @@ROWCOUNT
	End
End

-- There are no cases processed in bulk or included in bill so end the process
If @nCaseCount = 0
	RETURN 0


-- Create the attachments for all cases 
If @nErrorCode = 0
Begin
	begin transaction 

	Select @nFirstActivityNo = INTERNALSEQUENCE                     
	FROM LASTINTERNALCODE                          
	WHERE TABLENAME =  'ACTIVITY'
	Set @nErrorCode = @@ERROR

	-- reserve all the ids to use
	If @nErrorCode = 0 
	Begin
		UPDATE LASTINTERNALCODE                       
		SET INTERNALSEQUENCE = INTERNALSEQUENCE + @nCaseCount + 1                                      
		WHERE TABLENAME = 'ACTIVITY'		
		Set @nErrorCode = @@ERROR
	End

	If @nErrorCode = 0 
	Begin
		insert into ACTIVITY( ACTIVITYNO, ACTIVITYDATE, CASEID, INCOMPLETE, SUMMARY, ACTIVITYCATEGORY, ACTIVITYTYPE, WHENREQUESTED, SQLUSER )
		select ROWID + @nFirstActivityNo, GETDATE(), CASEID, 0, @psAttachmentName, 5902, 5806, WHENREQUESTED, SQLUSER
		from #TEMPCASE                          

		Set @nErrorCode = @@ERROR
	End

	If @nErrorCode = 0
	Begin
		insert into ACTIVITYATTACHMENT(ACTIVITYNO, SEQUENCENO, ATTACHMENTNAME, [FILENAME] )
		select ROWID + @nFirstActivityNo, 0, @psAttachmentName, @psFileName
		from #TEMPCASE                          

		Set @nErrorCode = @@ERROR
	End

	if @nErrorCode = 0
		commit transaction
	else
		rollback transaction
End


RETURN @nErrorCode
go

grant execute on dbo.dg_CreateCaseAttachmentBulk to public
go

