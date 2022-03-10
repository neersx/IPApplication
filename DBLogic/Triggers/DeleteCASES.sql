if exists (select * from sysobjects where type='TR' and name = 'DeleteCASES')
begin
	PRINT 'Refreshing trigger DeleteCASES...'
	DROP TRIGGER DeleteCASES
end
go
Create trigger DeleteCASES on CASES instead of DELETE NOT FOR REPLICATION as 
Begin
-- TRIGGER:	DeleteCASES
-- VERSION:	2
-- DESCRIPTION:	

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 29 Dec 2015	MF	56585 	1	Created
-- 07 Sep 2017	MF	72319	2	Delete any references to the Case.

	------------------------------------------------
	-- Cases that have been created as a result
	-- of a Case Import require the imported batch
	-- to be updated to indicate that the Case has
	-- been reversed and the reference to the CASEID
	-- removed from the database.
	------------------------------------------------
	Update B
	Set TRANSACTIONRETURNCODE=isnull(M.DESCRIPTION,'Case Reversed'),
	    TRANSNARRATIVECODE   =TC.TABLECODE
	from deleted d
	join EDECASEDETAILS CD    on (CD.CASEID=d.CASEID)
	join EDETRANSACTIONBODY B on (B.BATCHNO=CD.BATCHNO
				  and B.TRANSACTIONIDENTIFIER=CD.TRANSACTIONIDENTIFIER)
	left join TRANSACTIONMESSAGE M
				  on (M.TRANSACTIONMESSAGENO=11)
	left join TABLECODES TC   on (TC.TABLECODE=-42847000
				  and TC.TABLETYPE=402)

	------------------------------------------------
	-- Remove the references to the CASEID.
	------------------------------------------------
	Delete RC
	from RELATEDCASE RC
	join deleted d on (d.CASEID=RC.RELATEDCASEID)

	Update CD
	Set CASEID=NULL
	from deleted d
	join EDECASEDETAILS CD    on (CD.CASEID=d.CASEID)

	------------------------------------------------
	-- Now delete the CASE.
	------------------------------------------------
	Delete C
	from deleted d
	join CASES C on (C.CASEID=d.CASEID)

End
go
