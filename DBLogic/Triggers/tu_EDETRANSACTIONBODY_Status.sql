/******************************************************************************************************************/
/*** 10856 Create trigger tu_EDETRANSACTIONBODY_Status									***/
/******************************************************************************************************************/     
if exists (select * from sysobjects where type='TR' and name = 'tu_EDETRANSACTIONBODY_Status')
   begin
    PRINT 'Refreshing trigger tu_EDETRANSACTIONBODY_Status...'
    DROP TRIGGER tu_EDETRANSACTIONBODY_Status
   end
  go

CREATE TRIGGER tu_EDETRANSACTIONBODY_Status ON EDETRANSACTIONBODY FOR UPDATE NOT FOR REPLICATION AS
-- TRIGGER :	tu_EDETRANSACTIONBODY_Status
-- VERSION :	3
-- DESCRIPTION:	Set batch status to processed when all transactions of the batch
-- 		have been processed.

-- MODIFICATIONS :
-- Date		Who	Change		Version	Description
-- -----------	-------	------		-------	----------------------------------------------- 
-- 16 Oct 2006	MF	SQA12428	1	Trigger created.
-- 05 Mar 2008	KR	SQA15907	2	Update the status if the status is not output produced.
-- 19 May 2008	MF	SQA16427	3	Exclude BatchNo=-1 which is a reserver batch for manual changes.


-- Trigger is only required if the TRANSSTATUSCODE has changed.
IF UPDATE(TRANSSTATUSCODE) 
Begin
	update EDETRANSACTIONHEADER
	set	BATCHSTATUS = 1281,
		DATEPROCESSED = getdate()
	from EDETRANSACTIONHEADER H
	join inserted i	on (i.BATCHNO=H.BATCHNO)
	left join (	select BATCHNO, count(*) as UNPROCESSED
			from EDETRANSACTIONBODY 
			where isnull(TRANSSTATUSCODE,0)<>3480
			and BATCHNO<>-1
			group by BATCHNO) B	on (B.BATCHNO=H.BATCHNO)
	where i.TRANSSTATUSCODE=3480
	and H.BATCHSTATUS <> 1282
	and H.BATCHNO<>-1
	and isnull(B.UNPROCESSED,0)=0
End
GO
