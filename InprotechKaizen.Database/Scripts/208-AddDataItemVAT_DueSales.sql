/**********************************************************************************************************/
/*** DR-46022 Insert new Doc Items [VAT Due Sales] and Group [UK VAT]										***/
/**********************************************************************************************************/
Declare @nGroupCode	int

If NOT exists (select 1 from GROUPS where GROUP_NAME='UK VAT')
Begin
	Update LASTINTERNALCODE
	set @nGroupCode=INTERNALSEQUENCE+1,
		INTERNALSEQUENCE=INTERNALSEQUENCE+1
	Where TABLENAME='GROUPS'

	insert into GROUPS(GROUP_CODE, GROUP_NAME) values (@nGroupCode, 'UK VAT')

	PRINT '**** DR-46022 [UK VAT] group successfully added to the GROUPS table.'
	PRINT ''
End
Else Begin
	Select @nGroupCode=GROUP_CODE
	from GROUPS
	where GROUP_NAME='UK VAT'

	PRINT '**** DR-46022 GROUP for [UK VAT] already exists with code ' + cast(@nGroupCode as varchar)
	PRINT ''
End

If not exists(select 1 from ITEM where ITEM_NAME='VAT Due Sales')
begin
	declare @nItemId	int
		
	update L
	set @nItemId=1+(select MAX(ITEM_ID) from ITEM),
		INTERNALSEQUENCE=@nItemId
	From LASTINTERNALCODE L
	Where L.TABLENAME='ITEM'
		
	insert into ITEM(ITEM_ID, ITEM_NAME, SQL_QUERY, CREATED_BY, DATE_CREATED, DATE_UPDATED, ITEM_TYPE, SQL_DESCRIBE, SQL_INTO, ITEM_DESCRIPTION)
	values(@nItemId, 'VAT Due Sales','VAT_DueSales','SYSADM',getdate(),getdate(),1,'2',':n[0]','Retrieves the value to be reported at Box 1 ''VAT due in the period on sales and other outputs'' in the digital VAT return submitted to HM Revenue and Customs (HMRC).')
		
	-- Link the newly created Item to 
	-- the VAT Group.
	insert into ITEM_GROUP(GROUP_CODE, ITEM_ID)
	select GROUP_CODE, @nItemId
	from GROUPS
	where GROUP_NAME='UK VAT'

	PRINT '**** DR-46022 [VAT Due Sales] data item successfully added to ITEM table.'
	PRINT ''
End
Else Begin
	PRINT '**** DR-46022 ITEM [VAT Due Sales] already exists.' 
	PRINT ''
End
