declare @nItemId           int

if not exists (select * from ITEM where ITEM_NAME = 'EMAIL_CASE_TO_ADMIN')
begin
                                
    update L
    set		@nItemId=1+(select MAX(ITEM_ID) from ITEM),
            INTERNALSEQUENCE=@nItemId
    from	LASTINTERNALCODE L
    where	L.TABLENAME='ITEM'

	insert into ITEM(ITEM_ID, ITEM_NAME, SQL_QUERY, ITEM_DESCRIPTION, ITEM_TYPE, ENTRY_POINT_USAGE, SQL_DESCRIBE, SQL_INTO)
	values (@nItemId, 'EMAIL_CASE_TO_ADMIN','		select case 
			when U.ISEXTERNALUSER = 1 then ''support@my-org.com''
			when U.ISEXTERNALUSER = 0 then ''internal-administrator@my-org.com''
		end
		from USERIDENTITY U
		where U.IDENTITYID = :gstrUserId', 'Returns the Inprotech administrator''s email address - can be different for internal and external users based on the UserIdentityID passed.', 0, 1, 1, ':s[0]' )

	print '**** DR-32629 EMAIL_CASE_TO_ADMIN successfully added to ITEM table.'
	print ''

end

if not exists (select * from ITEM where ITEM_NAME = 'EMAIL_CASE_SUBJECT_ADMIN')
begin
	
	update L
    set		@nItemId=1+(select MAX(ITEM_ID) from ITEM),
            INTERNALSEQUENCE=@nItemId
    from	LASTINTERNALCODE L
    where	L.TABLENAME='ITEM'

	insert into ITEM(ITEM_ID, ITEM_NAME, SQL_QUERY, ITEM_DESCRIPTION, ITEM_TYPE, ENTRY_POINT_USAGE, SQL_DESCRIBE, SQL_INTO)
	values (@nItemId, 'EMAIL_CASE_SUBJECT_ADMIN',
		'select ''Regarding Case: '' + :gstrEntryPoint', 'Returns the default text appearing in the subject when emailing the administrator from a case from Apps.', 0, 1, 1, ':s[0]' )

	print '**** DR-32629 EMAIL_CASE_SUBJECT_ADMIN successfully added to ITEM table.'
	print ''

end

if not exists (select * from ITEM where ITEM_NAME = 'EMAIL_CASE_BODY_ADMIN')
begin
	
	update L
    set		@nItemId=1+(select MAX(ITEM_ID) from ITEM),
            INTERNALSEQUENCE=@nItemId
    from	LASTINTERNALCODE L
    where	L.TABLENAME='ITEM'

	insert into ITEM(ITEM_ID, ITEM_NAME, SQL_QUERY, ITEM_DESCRIPTION, ITEM_TYPE, ENTRY_POINT_USAGE, SQL_DESCRIBE, SQL_INTO)
	values (@nItemId, 'EMAIL_CASE_BODY_ADMIN', '		select ''Regarding Case: '' + :gstrEntryPoint + '' '' + C.TITLE
		from CASES C
		where C.IRN = :gstrEntryPoint', 'Returns the default text appearing in the body when emailing the administrator from a case from Apps.', 0, 1, 1, ':s[0]' )

	print '**** DR-32629 EMAIL_CASE_BODY_ADMIN successfully added to ITEM table.'
	print ''

end

go
