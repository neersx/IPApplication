SET QUOTED_IDENTIFIER OFF
GO	
	
Declare @nItemId	int
Declare @sItemName	nvarchar(40)
Declare @sItemDesc	nvarchar(254)
Declare @sSQLQuery	nvarchar(4000)
Declare @sCreatedBy nvarchar(36)
Declare @crlf nvarchar(3)

set @sCreatedBy = left(system_user, 18)

------------------------------
-- Get the next ITEM_ID to use
------------------------------
Select @nItemId=max(ITEM_ID)
from ITEM

---------------------------------
-- Insert EMAIL_CASE_CC_WEB
---------------------------------
Set @sItemName='EMAIL_CASE_CC_WEB'
Set @sItemDesc='Returns the copies to email when emailing a name associated with the case from Apps. The first parameter :p1 must be the Name Type and the second parameter :p2 must be the Sequence No.'
Set @sSQLQuery="
select substring(
	(select '; ' + CC.Email AS 'data()' 
	 from (
			select isnull(T1.TELECOMNUMBER, T2.TELECOMNUMBER) as Email
			from CASENAME CN
			join CASES C on C.CASEID = CN.CASEID
			join CORRESPONDTO CT on CT.NAMETYPE = CN.NAMETYPE
			left join CASENAME CN1 on CN1.NAMETYPE = CT.COPIESTO and CN.CASEID = CN1.CASEID
			left join NAME N1 on N1.NAMENO = isnull(CN1.CORRESPONDNAME, dbo.fn_GetDerivedAttnNameNo(CN1.NAMENO, CN1.CASEID, CN1.NAMETYPE))
			left join NAME N2 on N2.NAMENO = CN1.NAMENO
			left join TELECOMMUNICATION T1 on N1.MAINEMAIL = T1.TELECODE
			left join TELECOMMUNICATION T2 on N2.MAINEMAIL = T2.TELECODE
			where CN.NAMETYPE = :p1 and CN.SEQUENCE = :p2 and C.IRN = :gstrEntryPoint
	) as CC for xml path('')), 3, 4000)"

If not exists(	Select 1 
		from ITEM I
		where ITEM_NAME=@sItemName)
Begin
	Set @nItemId=@nItemId+1

	insert into ITEM(ITEM_ID,ITEM_NAME,SQL_QUERY,ITEM_DESCRIPTION,CREATED_BY,DATE_CREATED,DATE_UPDATED,ITEM_TYPE, ENTRY_POINT_USAGE,SQL_DESCRIBE,SQL_INTO)
	values(@nItemId, @sItemName, @sSQLQuery, @sItemDesc, @sCreatedBy ,getdate(),getdate(),0,1,1,':s[0]')
End

---------------------------------
-- Insert EMAIL_CASE_SUBJECT_WEB
---------------------------------
Set @sItemName='EMAIL_CASE_SUBJECT_WEB'
Set @sItemDesc='Returns the default text appearing in the subject when emailing a name associated with the case from Apps.  The first parameter :p1 must be the Name Type and the second parameter :p2 must be the Sequence No.'
Set @sSQLQuery="
	select 
		case 
			when UI.ISEXTERNALUSER = 1 and CN.REFERENCENO is not null then 'Regarding Our Reference: ' + CN.REFERENCENO 
			when UI.ISEXTERNALUSER = 0 and CN.REFERENCENO is not null then 'Regarding Your Reference: ' + CN.REFERENCENO
			else 'Regarding Reference: ' + C.IRN
		end
	from CASES C
	join USERIDENTITY UI on UI.IDENTITYID = :gstrUserId
	join CASENAME CN on (CN.CASEID = C.CASEID and CN.NAMETYPE = :p1 and CN.SEQUENCE = :p2)
	where C.IRN = :gstrEntryPoint"

If not exists(	Select 1 
		from ITEM I
		where ITEM_NAME=@sItemName)
Begin
	Set @nItemId=@nItemId+1

	insert into ITEM(ITEM_ID,ITEM_NAME,SQL_QUERY,ITEM_DESCRIPTION,CREATED_BY,DATE_CREATED,DATE_UPDATED,ITEM_TYPE, ENTRY_POINT_USAGE,SQL_DESCRIBE,SQL_INTO)
	values(@nItemId, @sItemName, @sSQLQuery, @sItemDesc, @sCreatedBy ,getdate(),getdate(),0,1,1,':s[0]')
End


---------------------------------
-- Insert EMAIL_CASE_BODY_WEB
---------------------------------
Set @sItemName='EMAIL_CASE_BODY_WEB'
Set @sItemDesc='Returns the default text appearing in the body when emailing a name associated with the case from Apps. The first parameter :p1 must be the Name Type and the second parameter :p2 must be the Sequence No.'
Set @sSQLQuery="
select 
		case 
			when UI.ISEXTERNALUSER = 1 and CN.REFERENCENO is not null then 'Regarding Our Reference: ' + CN.REFERENCENO 
			when UI.ISEXTERNALUSER = 0 and CN.REFERENCENO is not null then 'Regarding Your Reference: ' + CN.REFERENCENO
			else 'Regarding Reference: ' + C.IRN
		end + char(13) + char(10) + C.TITLE
	from CASES C
	join USERIDENTITY UI on UI.IDENTITYID = :gstrUserId
	join CASENAME CN on (CN.CASEID = C.CASEID and CN.NAMETYPE = :p1 and CN.SEQUENCE = :p2)
	where C.IRN = :gstrEntryPoint"

If not exists(	Select 1 
		from ITEM I
		where ITEM_NAME=@sItemName)
Begin
	Set @nItemId=@nItemId+1

	insert into ITEM(ITEM_ID,ITEM_NAME,SQL_QUERY,ITEM_DESCRIPTION,CREATED_BY,DATE_CREATED,DATE_UPDATED,ITEM_TYPE, ENTRY_POINT_USAGE,SQL_DESCRIBE,SQL_INTO)
	values(@nItemId, @sItemName, @sSQLQuery, @sItemDesc, @sCreatedBy ,getdate(),getdate(),0,1,1,':s[0]')
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

