-- TRIGGER:	tu_DeleteEBillRequest
-- VERSION:	1
-- DESCRIPTION:	Delete requests in ACTIVITYREQUEST table associated with the bill being reversed.

-- MODIFICATIONS :
-- Date			Who		Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 11 Jul 2019	DL		DR-42718	1	Delete EBILL request in ACTIVITYREQUEST table when ebill is reversed

If exists (select * from sysobjects where type='TR' and name = 'tu_DeleteEBillRequest')
Begin
    	PRINT 'Refreshing trigger tu_DeleteEBillRequest...'
    	DROP TRIGGER tu_DeleteEBillRequest
End
go

Create trigger tu_DeleteEBillRequest on OPENITEM for UPDATE NOT FOR REPLICATION as

-- Trigger is only required if the STATUS has changed.
If NOT UPDATE(LOGDATETIMESTAMP) and UPDATE(STATUS) 
Begin
	If exists( select 1 from inserted where STATUS = 9 )
	Begin
		/* Delete ANY requests in ACTIVITYREQUEST table associated with this bill being reversed */
		delete A
		from 	ACTIVITYREQUEST A
		join	deleted d on d.OPENITEMNO = A.DEBITNOTENO
	End
End
go
