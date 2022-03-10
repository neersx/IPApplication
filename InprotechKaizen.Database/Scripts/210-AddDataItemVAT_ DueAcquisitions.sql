/**********************************************************************************************************/
/*** DR-46023 Insert new Doc Items [VAT Due Acquisitions] for Group [UK VAT]										***/
/**********************************************************************************************************/
If not exists(select 1 from ITEM where ITEM_NAME='VAT Due Acquisitions')
begin
	declare @nItemId	int
		
	update L
	set @nItemId=1+(select MAX(ITEM_ID) from ITEM),
		INTERNALSEQUENCE=@nItemId
	From LASTINTERNALCODE L
	Where L.TABLENAME='ITEM'
		
	insert into ITEM(ITEM_ID, ITEM_NAME, SQL_QUERY, CREATED_BY, DATE_CREATED, DATE_UPDATED, ITEM_TYPE, SQL_DESCRIBE, SQL_INTO, ITEM_DESCRIPTION)
	values(@nItemId, 'VAT Due Acquisitions','VAT_DueAcquisitions','SYSADM',getdate(),getdate(),1,'2',':n[0]','Retrieves the value to be reported at Box 2 ''VAT due in the period on acquisitions from other EU member states'' in the digital VAT return submitted to HM Revenue and Customs (HMRC).')
		
	-- Link the newly created Item to 
	-- the VAT Group.
	insert into ITEM_GROUP(GROUP_CODE, ITEM_ID)
	select GROUP_CODE, @nItemId
	from GROUPS
	where GROUP_NAME='UK VAT'

	PRINT '**** DR-46023 [VAT Due Acquisitions] data item successfully added to ITEM table.'
	PRINT ''
End
Else Begin
	PRINT '**** DR-46023 ITEM [VAT Due Acquisitions] already exists.' 
	PRINT ''
End
