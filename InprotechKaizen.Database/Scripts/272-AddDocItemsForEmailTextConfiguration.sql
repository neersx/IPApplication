
/**********************************************************************************************************/
/*** DR-59477 Insert Doc Items for user password expiry and for forgot password.						***/
/**********************************************************************************************************/
SET QUOTED_IDENTIFIER OFF
GO	
	
Declare @nItemId	int
Declare @sItemName	nvarchar(40)
Declare @sItemDesc	nvarchar(254)
Declare @sSQLQuery	nvarchar(4000)
Declare @sCreatedBy nvarchar(36)

set @sCreatedBy = left(system_user, 18)

------------------------------
-- Get the next ITEM_ID to use
------------------------------
Select @nItemId=max(ITEM_ID)
from ITEM

---------------------------------
-- Insert EMAIL_PASSWORD_EXPIRY
---------------------------------
Set @sItemName='EMAIL_PASSWORD_EXPIRY'
Set @sItemDesc='Returns the Email body text for password expiry. :gstrUserId is for userid and :gstrEntryPoint is for days to expire.'

Set @sSQLQuery="Select CASE WHEN :gstrEntryPoint > 0"+char(13)+char(10)+
							"THEN CASE WHEN U.ISEXTERNALUSER = 1"+char(13)+char(10)+
								"THEN 'Your password will expire in ' + cast(:gstrEntryPoint as nvarchar(10)) + ' day(s). You can change your password any time by using the Change Password option in Inprotech.'"+char(13)+char(10)+
								"ELSE 'Your password will expire in ' + cast(:gstrEntryPoint as nvarchar(10)) + ' day(s). You can change your password any time by using the Change Password option in Inprotech.'"+char(13)+char(10)+
								"END"+char(13)+char(10)+
							"WHEN :gstrEntryPoint = 0"+char(13)+char(10)+
							"THEN CASE WHEN U.ISEXTERNALUSER = 1"+char(13)+char(10)+
								"THEN 'Your password will expire today. You can change your password any time by using the Change Password option in Inprotech.'"+char(13)+char(10)+
								"ELSE 'Your password will expire today. You can change your password any time by using the Change Password option in Inprotech.'"+char(13)+char(10)+
								"END"+char(13)+char(10)+
							"ELSE CASE WHEN U.ISEXTERNALUSER = 1"+char(13)+char(10)+
								"THEN 'Your password has expired.  You will be prompted to change and confirm your password the next time you sign in to Inprotech.'"+char(13)+char(10)+
								"ELSE 'Your password has expired. You will be prompted to change and confirm your password the next time you sign in to Inprotech.'"+char(13)+char(10)+
								"END"+char(13)+char(10)+
							"END"+char(13)+char(10)+
				"FROM USERIDENTITY U"+char(13)+char(10)+
				"where U.IDENTITYID = :gstrUserId"

If not exists(	Select 1 
		from ITEM I
		where ITEM_NAME=@sItemName)
Begin
	Set @nItemId=@nItemId+1

	insert into ITEM(ITEM_ID,ITEM_NAME,SQL_QUERY,ITEM_DESCRIPTION,CREATED_BY,DATE_CREATED,DATE_UPDATED,ITEM_TYPE, ENTRY_POINT_USAGE,SQL_DESCRIBE,SQL_INTO)
	values(@nItemId, @sItemName, @sSQLQuery, @sItemDesc, @sCreatedBy ,getdate(),getdate(),0,1,1,':s[0]')

	PRINT '**** DR-59477 Doc Item created for "'+@sItemName+'"'
	PRINT ''
End
Else Begin
	PRINT '**** DR-59477 Doc Item "'+@sItemName+'" already exists'
	PRINT ''
End

------------------------------------
-- Insert EMAIL_PASSWORD_FORGOT  
------------------------------------
Set @sItemName='EMAIL_PASSWORD_RESET'
Set @sItemDesc='Returns the Email body text for forgot password. :gstrUserId is for userid and :gstrEntryPoint is for number of minutes till the link will be active.'

Set @sSQLQuery="SELECT  CASE WHEN U.ISEXTERNALUSER = 1"+char(13)+char(10)+
								"THEN 'We received a request to change your password. Click on the link below to set a new password. This link is active for ' + cast(:gstrEntryPoint as nvarchar(10)) + ' minutes.'"+char(13)+char(10)+
								"ELSE 'We received a request to change your password. Click on the link below to set a new password. This link is active for ' + cast(:gstrEntryPoint as nvarchar(10)) + ' minutes.'"+char(13)+char(10)+
								"END"+char(13)+char(10)+
		    "FROM USERIDENTITY U"+char(13)+char(10)+
		    "WHERE U.IDENTITYID = :gstrUserId"

If not exists(	Select 1 
		from ITEM I
		where ITEM_NAME=@sItemName)
Begin
	Set @nItemId=@nItemId+1

	insert into ITEM(ITEM_ID,ITEM_NAME,SQL_QUERY,ITEM_DESCRIPTION,CREATED_BY,DATE_CREATED,DATE_UPDATED,ITEM_TYPE, ENTRY_POINT_USAGE,SQL_DESCRIBE,SQL_INTO)
	values(@nItemId, @sItemName, @sSQLQuery, @sItemDesc, @sCreatedBy ,getdate(),getdate(),0,1,'1',':s[0]')

	PRINT '**** DR-59477 Doc Item created for "'+@sItemName+'"'
	PRINT ''
End
Else Begin
	PRINT '**** DR-59477 Doc Item "'+@sItemName+'" already exists'
	PRINT ''
End


------------------------------------
-- Insert EMAIL_PASSWORD_FORGOT  
------------------------------------
Set @sItemName='EMAIL_ACCOUNT_LOCKED'
Set @sItemDesc='Returns the Email body text for user account locked. :gstrEntryPoint is for username whose account is locked. First text is subject, second is email content.'

Set @sSQLQuery="SELECT  'The user account ''' + :gstrEntryPoint + ''' has been locked', 'The following Inprotech user has exceeded the maximum number of login attempts:'"

If not exists(	Select 1 
		from ITEM I
		where ITEM_NAME=@sItemName)
Begin
	Set @nItemId=@nItemId+1

	insert into ITEM(ITEM_ID,ITEM_NAME,SQL_QUERY,ITEM_DESCRIPTION,CREATED_BY,DATE_CREATED,DATE_UPDATED,ITEM_TYPE, ENTRY_POINT_USAGE,SQL_DESCRIBE,SQL_INTO)
	values(@nItemId, @sItemName, @sSQLQuery, @sItemDesc, @sCreatedBy ,getdate(),getdate(),0,1,'1',':s[0]')

	PRINT '**** DR-59477 Doc Item created for "'+@sItemName+'"'
	PRINT ''
End
Else Begin
	PRINT '**** DR-59477 Doc Item "'+@sItemName+'" already exists'
	PRINT ''
End

------------------------------------
-- Insert EMAIL_PASSWORD_FORGOT  
------------------------------------
Set @sItemName='EMAIL_TwoFactor'
Set @sItemDesc='Returns the Email body text for 2 factor authentication :gstrEntryPoint is for user verification code. The first text is email subject, second is email content and third is footer.'

Set @sSQLQuery="SELECT 'Inprotech Verification Code',  :gstrEntryPoint + ' - Use this code for Inprotech verification.', 'This is a system generated email.'"

If not exists(	Select 1 
		from ITEM I
		where ITEM_NAME=@sItemName)
Begin
	Set @nItemId=@nItemId+1

	insert into ITEM(ITEM_ID,ITEM_NAME,SQL_QUERY,ITEM_DESCRIPTION,CREATED_BY,DATE_CREATED,DATE_UPDATED,ITEM_TYPE, ENTRY_POINT_USAGE,SQL_DESCRIBE,SQL_INTO)
	values(@nItemId, @sItemName, @sSQLQuery, @sItemDesc, @sCreatedBy ,getdate(),getdate(),0,1,'1',':s[0]')

	PRINT '**** DR-59477 Doc Item created for "'+@sItemName+'"'
	PRINT ''
End
Else Begin
	PRINT '**** DR-59477 Doc Item "'+@sItemName+'" already exists'
	PRINT ''
End

------------------------------
-- Update the LASTINTERNALCODE
-- for the ITEM table
------------------------------
Update LASTINTERNALCODE
set INTERNALSEQUENCE=@nItemId
Where TABLENAME='ITEM'
and INTERNALSEQUENCE<>@nItemId

go
