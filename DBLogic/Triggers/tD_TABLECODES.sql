if exists (select * from sysobjects where type='TR' and name = 'tD_TABLECODES')
begin
	PRINT 'Refreshing trigger tD_TABLECODES...'
	DROP TRIGGER tD_TABLECODES
end
  go	

CREATE TRIGGER  tD_TABLECODES ON TABLECODES FOR DELETE NOT FOR REPLICATION AS
-- TRIGGER :	tD_TABLECODES
-- VERSION :	1
-- DESCRIPTION:	This trigger deletes corresponding QUERYCOLUMN rows whenever  
-- 		a TABLECODES row is deleted with a TABLETYPE=-500
--
-- Date		Who	Number	Version	Change
-- ------------	-------	------	-------	----------------------------------------------- 	
-- 08 Jun 2010	MF	RFC7008	1	Trigger created 	

Begin
	Delete QUERYCOLUMN
	from QUERYCOLUMN C
	join deleted d		on (d.DESCRIPTION=C.COLUMNLABEL)
	join QUERYDATAITEM DI	on (DI.DATAITEMID      = C.DATAITEMID
				and DI.PROCEDUREITEMID = 'BillMapping'
				and DI.PROCEDURENAME   = N'xml_GetDebitNoteMappedCodes')
	left join TABLECODES TC	on (TC.TABLETYPE  =d.TABLETYPE
				and TC.DESCRIPTION=d.DESCRIPTION
				and TC.TABLECODE <>d.TABLECODE)
	where d.TABLETYPE=-500
	and  TC.TABLECODE is null
End
go
