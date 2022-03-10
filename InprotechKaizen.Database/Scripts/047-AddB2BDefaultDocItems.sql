
/**********************************************************************************************************/
/*** RFC45181 Insert default B2B Doc Items to be used by Schema Mapping. ***/
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
-- Insert B2B_IRN
---------------------------------
Set @sItemName='B2B_IRN'
Set @sItemDesc='Returns the Case IRN to be used as reference'

Set @sSQLQuery="SELECT C.IRN"+char(13)+char(10)+
		    "FROM CASES C"+char(13)+char(10)+
		    "WHERE C.IRN = :gstrEntryPoint"

If not exists(	Select 1 
		from ITEM I
		where ITEM_NAME=@sItemName)
Begin
	Set @nItemId=@nItemId+1

	insert into ITEM(ITEM_ID,ITEM_NAME,SQL_QUERY,ITEM_DESCRIPTION,CREATED_BY,DATE_CREATED,DATE_UPDATED,ITEM_TYPE, ENTRY_POINT_USAGE,SQL_DESCRIBE,SQL_INTO)
	values(@nItemId, @sItemName, @sSQLQuery, @sItemDesc, @sCreatedBy ,getdate(),getdate(),0,1,1,':s[0]')

	PRINT '**** RFC45181 Doc Item created for "'+@sItemName+'"'
	PRINT ''
End
Else Begin
	PRINT '**** RFC45181 Doc Item "'+@sItemName+'" already exists'
	PRINT ''
End
	
------------------------------------
-- Insert B2B_CHECKLIST_YESNO_ANSWER
------------------------------------
Set @sItemName='B2B_CHECKLIST_YESNO_ANSWER'
Set @sItemDesc='Accepts Question No as a parameter and returns True for a yes answer or False for a no answer.'

Set @sSQLQuery="SELECT CASE"+char(13)+char(10)+
		    "WHEN CC.YESNOANSWER = 0 THEN 'false'"+char(13)+char(10)+
		    "WHEN CC.YESNOANSWER = 1 THEN 'true'"+char(13)+char(10)+
		    "ELSE NULL END"+char(13)+char(10)+
		    "FROM CASES C"+char(13)+char(10)+
		    "JOIN CASECHECKLIST CC on CC.CASEID = C.CASEID"+char(13)+char(10)+
		    "WHERE C.IRN = :gstrEntryPoint AND CC.QUESTIONNO = :p1"

If not exists(	Select 1 
		from ITEM I
		where ITEM_NAME=@sItemName)
Begin
	Set @nItemId=@nItemId+1

	insert into ITEM(ITEM_ID,ITEM_NAME,SQL_QUERY,ITEM_DESCRIPTION,CREATED_BY,DATE_CREATED,DATE_UPDATED,ITEM_TYPE, ENTRY_POINT_USAGE,SQL_DESCRIBE,SQL_INTO)
	values(@nItemId, @sItemName, @sSQLQuery, @sItemDesc, @sCreatedBy ,getdate(),getdate(),0,1,1,':s[0]')

	PRINT '**** RFC45181 Doc Item created for "'+@sItemName+'"'
	PRINT ''
End
Else Begin
	PRINT '**** RFC45181 Doc Item "'+@sItemName+'" already exists'
	PRINT ''
End

------------------------------------
-- Insert B2B_CHECKLIST_TEXT_ANSWER
------------------------------------
Set @sItemName='B2B_CHECKLIST_TEXT_ANSWER'
Set @sItemDesc='Accepts Question No as a parameter and returns text answer.'

Set @sSQLQuery="SELECT CC.CHECKLISTTEXT "+char(13)+char(10)+
		    "FROM CASES C"+char(13)+char(10)+
		    "JOIN CASECHECKLIST CC ON CC.CASEID = C.CASEID"+char(13)+char(10)+
		    "WHERE C.IRN = :gstrEntryPoint AND CC.QUESTIONNO  = :p1"

If not exists(	Select 1 
		from ITEM I
		where ITEM_NAME=@sItemName)
Begin
	Set @nItemId=@nItemId+1

	insert into ITEM(ITEM_ID,ITEM_NAME,SQL_QUERY,ITEM_DESCRIPTION,CREATED_BY,DATE_CREATED,DATE_UPDATED,ITEM_TYPE, ENTRY_POINT_USAGE,SQL_DESCRIBE,SQL_INTO)
	values(@nItemId, @sItemName, @sSQLQuery, @sItemDesc, @sCreatedBy ,getdate(),getdate(),0,1,1,':s[0]')

	PRINT '**** RFC45181 Doc Item created for "'+@sItemName+'"'
	PRINT ''
End
Else Begin
	PRINT '**** RFC45181 Doc Item "'+@sItemName+'" already exists'
	PRINT ''
End

-------------------------------------
-- Insert B2B_CHECKLIST_TABLE_ANSWER
-------------------------------------
Set @sItemName='B2B_CHECKLIST_TABLE_ANSWER'
Set @sItemDesc='Accepts Question No as a parameter and returns table description and table user code. The return values will need to be customized depending on the response required by the IP office.'

Set @sSQLQuery="SELECT T.DESCRIPTION,T.USERCODE"+char(13)+char(10)+
		    "FROM CASES C"+char(13)+char(10)+
		    "JOIN CASECHECKLIST CC ON CC.CASEID = C.CASEID"+char(13)+char(10)+
		    "JOIN TABLECODES T ON T.TABLECODE = CC.TABLECODE"+char(13)+char(10)+
		    "WHERE C.IRN = :gstrEntryPoint AND CC.QUESTIONNO  = :p1"

If not exists(	Select 1 
		from ITEM I
		where ITEM_NAME=@sItemName)
Begin
	Set @nItemId=@nItemId+1

	insert into ITEM(ITEM_ID,ITEM_NAME,SQL_QUERY,ITEM_DESCRIPTION,CREATED_BY,DATE_CREATED,DATE_UPDATED,ITEM_TYPE, ENTRY_POINT_USAGE,SQL_DESCRIBE,SQL_INTO)
	values(@nItemId, @sItemName, @sSQLQuery, @sItemDesc, @sCreatedBy ,getdate(),getdate(),0,1,'1,1',':s[0],s[1]')

	PRINT '**** RFC45181 Doc Item created for "'+@sItemName+'"'
	PRINT ''
End
Else Begin
	PRINT '**** RFC45181 Doc Item "'+@sItemName+'" already exists'
	PRINT ''
End

-------------------------------------
-- Insert B2B_EVENT_YESNO_ANSWER
-------------------------------------
Set @sItemName='B2B_EVENT_YESNO_ANSWER'
Set @sItemDesc='Accepts Event No as a parameter and returns True if the event has occurred otherwise returns False.'

Set @sSQLQuery="SELECT CASE"+char(13)+char(10)+
		    "When CE.EVENTDATE IS NULL THEN 'false'"+char(13)+char(10)+
		    "ELSE 'true' END"+char(13)+char(10)+
		    "FROM CASES C"+char(13)+char(10)+
		    "JOIN CASEEVENT CE ON CE.CASEID = C.CASEID"+char(13)+char(10)+
		    "WHERE C.IRN = :gstrEntryPoint AND CE.EVENTNO = :p1"

If not exists(	Select 1 
		from ITEM I
		where ITEM_NAME=@sItemName)
Begin
	Set @nItemId=@nItemId+1

	insert into ITEM(ITEM_ID,ITEM_NAME,SQL_QUERY,ITEM_DESCRIPTION,CREATED_BY,DATE_CREATED,DATE_UPDATED,ITEM_TYPE, ENTRY_POINT_USAGE,SQL_DESCRIBE,SQL_INTO)
	values(@nItemId, @sItemName, @sSQLQuery, @sItemDesc, @sCreatedBy ,getdate(),getdate(),0,1,1,':s[0]')

	PRINT '**** RFC45181 Doc Item created for "'+@sItemName+'"'
	PRINT ''
End
Else Begin
	PRINT '**** RFC45181 Doc Item "'+@sItemName+'" already exists'
	PRINT ''
End

-------------------------------------
-- Insert B2B_SYSTEM_DATE
-------------------------------------
Set @sItemName='B2B_SYSTEM_DATE'
Set @sItemDesc='Returns the current system date. No entry point required.'

Set @sSQLQuery="Select getdate() as SystemDate"

If not exists(	Select 1 
		from ITEM I
		where ITEM_NAME=@sItemName)
Begin
	Set @nItemId=@nItemId+1

	insert into ITEM(ITEM_ID,ITEM_NAME,SQL_QUERY,ITEM_DESCRIPTION,CREATED_BY,DATE_CREATED,DATE_UPDATED,ITEM_TYPE, ENTRY_POINT_USAGE,SQL_DESCRIBE,SQL_INTO)
	values(@nItemId, @sItemName, @sSQLQuery, @sItemDesc, @sCreatedBy ,getdate(),getdate(),0,1,3,':d[0]')

	PRINT '**** RFC45181 Doc Item created for "'+@sItemName+'"'
	PRINT ''
End
Else Begin
	PRINT '**** RFC45181 Doc Item "'+@sItemName+'" already exists'
	PRINT ''
End

------------------------------------
-- Insert B2B_TEXT
------------------------------------
Set @sItemName='B2B_TEXT'
Set @sItemDesc='Accepts Text Type as a parameter and returns case text. It will return the long text if available otherwise will return the short text. Doc item may be customized to derive the language code applicable.'

Set @sSQLQuery="SELECT CASE When CT.LONGFLAG = 1 THEN CT.TEXT"+char(13)+char(10)+
		    "ELSE CT.SHORTTEXT END"+char(13)+char(10)+
		    "FROM CASES C"+char(13)+char(10)+
		    "JOIN CASETEXT CT ON CT.CASEID = C.CASEID"+char(13)+char(10)+
		    "WHERE C.IRN = :gstrEntryPoint AND CT.TEXTTYPE = :p1"

If not exists(	Select 1 
		from ITEM I
		where ITEM_NAME=@sItemName)
Begin
	Set @nItemId=@nItemId+1

	insert into ITEM(ITEM_ID,ITEM_NAME,SQL_QUERY,ITEM_DESCRIPTION,CREATED_BY,DATE_CREATED,DATE_UPDATED,ITEM_TYPE, ENTRY_POINT_USAGE,SQL_DESCRIBE,SQL_INTO)
	values(@nItemId, @sItemName, @sSQLQuery, @sItemDesc, @sCreatedBy ,getdate(),getdate(),0,1,4,':l[0]')

	PRINT '**** RFC45181 Doc Item created for "'+@sItemName+'"'
	PRINT ''
End
Else Begin
	PRINT '**** RFC45181 Doc Item "'+@sItemName+'" already exists'
	PRINT ''
End

------------------------------------
-- Insert B2B_TITLE
------------------------------------
Set @sItemName='B2B_TITLE'
Set @sItemDesc='Will return case text where text type is T otherwise will return the value of Short Title field.'

Set @sSQLQuery="SELECT CASE WHEN CT.CASEID IS NOT NULL AND CT.LONGFLAG = 1 THEN CT.TEXT"+char(13)+char(10)+
		    "When CT.CASEID IS NOT NULL AND CT.LONGFLAG = 0 THEN CT.SHORTTEXT"+char(13)+char(10)+
		    "ELSE C.TITLE END"+char(13)+char(10)+
		    "FROM CASES C"+char(13)+char(10)+
		    "LEFT JOIN CASETEXT CT ON CT.CASEID = C.CASEID AND CT.TEXTTYPE = 'T'"+char(13)+char(10)+
		    "WHERE C.IRN = :gstrEntryPoint"

If not exists(	Select 1 
		from ITEM I
		where ITEM_NAME=@sItemName)
Begin
	Set @nItemId=@nItemId+1

	insert into ITEM(ITEM_ID,ITEM_NAME,SQL_QUERY,ITEM_DESCRIPTION,CREATED_BY,DATE_CREATED,DATE_UPDATED,ITEM_TYPE, ENTRY_POINT_USAGE,SQL_DESCRIBE,SQL_INTO)
	values(@nItemId, @sItemName, @sSQLQuery, @sItemDesc, @sCreatedBy ,getdate(),getdate(),0,1,4,':l[0]')

	PRINT '**** RFC45181 Doc Item created for "'+@sItemName+'"'
	PRINT ''
End
Else Begin
	PRINT '**** RFC45181 Doc Item "'+@sItemName+'" already exists'
	PRINT ''
End

------------------------------------
-- Insert B2B_EVENT 
------------------------------------
Set @sItemName='B2B_EVENT '
Set @sItemDesc='Accepts Event No as a parameter and returns the event date for this event.  The assumption is that this will be used for single cycle events.'

Set @sSQLQuery="SELECT CE.EVENTDATE"+char(13)+char(10)+
		    "FROM CASES C"+char(13)+char(10)+
		    "JOIN CASEEVENT CE ON CE.CASEID = C.CASEID"+char(13)+char(10)+
		    "WHERE C.IRN = :gstrEntryPoint AND CE.EVENTNO  = :p1"

If not exists(	Select 1 
		from ITEM I
		where ITEM_NAME=@sItemName)
Begin
	Set @nItemId=@nItemId+1

	insert into ITEM(ITEM_ID,ITEM_NAME,SQL_QUERY,ITEM_DESCRIPTION,CREATED_BY,DATE_CREATED,DATE_UPDATED,ITEM_TYPE, ENTRY_POINT_USAGE,SQL_DESCRIBE,SQL_INTO)
	values(@nItemId, @sItemName, @sSQLQuery, @sItemDesc, @sCreatedBy ,getdate(),getdate(),0,1,3,':d[0]')

	PRINT '**** RFC45181 Doc Item created for "'+@sItemName+'"'
	PRINT ''
End
Else Begin
	PRINT '**** RFC45181 Doc Item "'+@sItemName+'" already exists'
	PRINT ''
End

------------------------------------
-- Insert B2B_OFFICIAL_NUMBER  
------------------------------------
Set @sItemName='B2B_OFFICIAL_NUMBER'
Set @sItemDesc='Accepts Number Type as a parameter and returns the official number for this number type where the current flag is on. '

Set @sSQLQuery="SELECT O.OFFICIALNUMBER"+char(13)+char(10)+
		    "FROM CASES C"+char(13)+char(10)+
		    "JOIN OFFICIALNUMBERS O ON O.CASEID = C.CASEID AND O.ISCURRENT = 1"+char(13)+char(10)+
		    "WHERE C.IRN = :gstrEntryPoint AND O.NUMBERTYPE  = :p1"

If not exists(	Select 1 
		from ITEM I
		where ITEM_NAME=@sItemName)
Begin
	Set @nItemId=@nItemId+1

	insert into ITEM(ITEM_ID,ITEM_NAME,SQL_QUERY,ITEM_DESCRIPTION,CREATED_BY,DATE_CREATED,DATE_UPDATED,ITEM_TYPE, ENTRY_POINT_USAGE,SQL_DESCRIBE,SQL_INTO)
	values(@nItemId, @sItemName, @sSQLQuery, @sItemDesc, @sCreatedBy ,getdate(),getdate(),0,1,1,':s[0]')

	PRINT '**** RFC45181 Doc Item created for "'+@sItemName+'"'
	PRINT ''
End
Else Begin
	PRINT '**** RFC45181 Doc Item "'+@sItemName+'" already exists'
	PRINT ''
End

------------------------------------
-- Insert B2B_NAME_IDENTIFIER  
------------------------------------
Set @sItemName='B2B_NAME_IDENTIFIER'
Set @sItemDesc='Accepts Name Type and Alias Type as parameters. Returns the name alias of the case name.'

Set @sSQLQuery="SELECT A.ALIAS"+char(13)+char(10)+
		    "FROM CASES C"+char(13)+char(10)+
		    "JOIN CASENAME N ON N.CASEID = C.CASEID"+char(13)+char(10)+
		    "JOIN NAMEALIAS A ON A.NAMENO = N.NAMENO"+char(13)+char(10)+
		    "WHERE C.IRN = :gstrEntryPoint AND N.NAMETYPE = :p1 AND A.ALIASTYPE = :p2"

If not exists(	Select 1 
		from ITEM I
		where ITEM_NAME=@sItemName)
Begin
	Set @nItemId=@nItemId+1

	insert into ITEM(ITEM_ID,ITEM_NAME,SQL_QUERY,ITEM_DESCRIPTION,CREATED_BY,DATE_CREATED,DATE_UPDATED,ITEM_TYPE, ENTRY_POINT_USAGE,SQL_DESCRIBE,SQL_INTO)
	values(@nItemId, @sItemName, @sSQLQuery, @sItemDesc, @sCreatedBy ,getdate(),getdate(),0,1,1,':s[0]')

	PRINT '**** RFC45181 Doc Item created for "'+@sItemName+'"'
	PRINT ''
End
Else Begin
	PRINT '**** RFC45181 Doc Item "'+@sItemName+'" already exists'
	PRINT ''
End

------------------------------------
-- Insert B2B_HOME_NAME_IDENTIFIER  
------------------------------------
Set @sItemName='B2B_HOME_NAME_IDENTIFIER'
Set @sItemDesc='Accepts Alias Type as a parameter. Returns the name alias of the home name.'

Set @sSQLQuery="SELECT A.ALIAS"+char(13)+char(10)+
		    "FROM SITECONTROL S"+char(13)+char(10)+
		    "JOIN NAMEALIAS A ON A.NAMENO = S.COLINTEGER"+char(13)+char(10)+
		    "WHERE S.CONTROLID = 'HOMENAMENO'AND A.ALIASTYPE = :p1"

If not exists(	Select 1 
		from ITEM I
		where ITEM_NAME=@sItemName)
Begin
	Set @nItemId=@nItemId+1

	insert into ITEM(ITEM_ID,ITEM_NAME,SQL_QUERY,ITEM_DESCRIPTION,CREATED_BY,DATE_CREATED,DATE_UPDATED,ITEM_TYPE, ENTRY_POINT_USAGE,SQL_DESCRIBE,SQL_INTO)
	values(@nItemId, @sItemName, @sSQLQuery, @sItemDesc, @sCreatedBy ,getdate(),getdate(),0,1,1,':s[0]')

	PRINT '**** RFC45181 Doc Item created for "'+@sItemName+'"'
	PRINT ''
End
Else Begin
	PRINT '**** RFC45181 Doc Item "'+@sItemName+'" already exists'
	PRINT ''
End

------------------------------------
-- Insert B2B_GOODS_SERVICES  
------------------------------------
Set @sItemName='B2B_GOODS_SERVICES'
Set @sItemDesc='Will return multiple Class Codes and Goods & Services Text applicable for the case.'

Set @sSQLQuery="SELECT T.CLASS, CASE WHEN T.LONGFLAG = 1 THEN T.TEXT ELSE T.SHORTTEXT END"+char(13)+char(10)+
		    "FROM CASES C"+char(13)+char(10)+
		    "JOIN CASETEXT T ON T.CASEID = C.CASEID AND T.TEXTTYPE = 'G'"+char(13)+char(10)+
		    "WHERE C.IRN = :gstrEntryPoint"+char(13)+char(10)+
		    "ORDER BY T.TEXTNO"

If not exists(	Select 1 
		from ITEM I
		where ITEM_NAME=@sItemName)
Begin
	Set @nItemId=@nItemId+1

	insert into ITEM(ITEM_ID,ITEM_NAME,SQL_QUERY,ITEM_DESCRIPTION,CREATED_BY,DATE_CREATED,DATE_UPDATED,ITEM_TYPE, ENTRY_POINT_USAGE,SQL_DESCRIBE,SQL_INTO)
	values(@nItemId, @sItemName, @sSQLQuery, @sItemDesc, @sCreatedBy ,getdate(),getdate(),0,1,'1,4',':s[0],:l[0]')

	PRINT '**** RFC45181 Doc Item created for "'+@sItemName+'"'
	PRINT ''
End
Else Begin
	PRINT '**** RFC45181 Doc Item "'+@sItemName+'" already exists'
	PRINT ''
End

------------------------------------
-- Insert B2B_RELATED_CASE  
------------------------------------
Set @sItemName='B2B_RELATED_CASE'
Set @sItemDesc='Accepts Relationship code as a parameter. Returns Country Code, Official Number and Date of related case. Will return country code, application number and application date of the internal related case. Can return multiple related cases.'

Set @sSQLQuery="SELECT R.COUNTRYCODE, R.OFFICIALNUMBER, R.PRIORITYDATE"+char(13)+char(10)+
		    "FROM CASES C"+char(13)+char(10)+
		    "JOIN RELATEDCASE R ON R.CASEID = C.CASEID AND R.RELATEDCASEID IS NULL"+char(13)+char(10)+
		    "WHERE C.IRN = :gstrEntryPoint AND R.RELATIONSHIP = :p1"+char(13)+char(10)+
		    "UNION"+char(13)+char(10)+
		    "SELECT C1.COUNTRYCODE, O.OFFICIALNUMBER, CE.EVENTDATE"+char(13)+char(10)+
		    "FROM CASES C"+char(13)+char(10)+
		    "JOIN RELATEDCASE R ON R.CASEID = C.CASEID AND R.RELATEDCASEID IS NOT NULL"+char(13)+char(10)+
		    "JOIN CASES C1 ON C1.CASEID = R.RELATEDCASEID"+char(13)+char(10)+
		    "LEFT JOIN OFFICIALNUMBERS O ON O.CASEID = C1.CASEID AND O.NUMBERTYPE = 'A'"+char(13)+char(10)+
		    "LEFT JOIN CASEEVENT CE ON CE.CASEID = C1.CASEID AND CE.EVENTNO = -4"+char(13)+char(10)+
		    "WHERE C.IRN = :gstrEntryPoint AND R.RELATIONSHIP = :p1"

If not exists(	Select 1 
		from ITEM I
		where ITEM_NAME=@sItemName)
Begin
	Set @nItemId=@nItemId+1

	insert into ITEM(ITEM_ID,ITEM_NAME,SQL_QUERY,ITEM_DESCRIPTION,CREATED_BY,DATE_CREATED,DATE_UPDATED,ITEM_TYPE, ENTRY_POINT_USAGE,SQL_DESCRIBE,SQL_INTO)
	values(@nItemId, @sItemName, @sSQLQuery, @sItemDesc, @sCreatedBy ,getdate(),getdate(),0,1,'1,1,3',':s[0],:s[1],:d[2]')

	PRINT '**** RFC45181 Doc Item created for "'+@sItemName+'"'
	PRINT ''
End
Else Begin
	PRINT '**** RFC45181 Doc Item "'+@sItemName+'" already exists'
	PRINT ''
End


------------------------------------
-- Insert B2B_NAME_DETAILS_BASIC
------------------------------------
Set @sItemName='B2B_NAME_DETAILS_BASIC'
Set @sItemDesc='Accepts Name Type as parameter. Returns the name, address and contact details of the case name. There can be multiple of them.'

Set @sSQLQuery="SELECT N.NAMECODE, N.FIRSTNAME, N.NAME, A.STREET1, A.CITY, A.STATE, A.POSTCODE, A.COUNTRYCODE,"+char(13)+char(10)+
		    "T1.TELECOMNUMBER as Phone, T2.TELECOMNUMBER as Fax, T3.TELECOMNUMBER as Email"+char(13)+char(10)+
		    "FROM CASES C"+char(13)+char(10)+
		    "JOIN CASENAME CN ON CN.CASEID = C.CASEID"+char(13)+char(10)+
		    "JOIN NAME N ON N.NAMENO = CN.NAMENO"+char(13)+char(10)+
		    "JOIN ADDRESS A ON A.ADDRESSCODE = ISNULL(CN.ADDRESSCODE, N.POSTALADDRESS)"+char(13)+char(10)+
		    "LEFT JOIN TELECOMMUNICATION T1 ON T1.TELECODE = N.MAINPHONE"+char(13)+char(10)+
		    "LEFT JOIN TELECOMMUNICATION T2 ON T2.TELECODE = N.FAX"+char(13)+char(10)+
		    "LEFT JOIN TELECOMMUNICATION T3 ON T3.TELECODE = N.MAINEMAIL"+char(13)+char(10)+
		    "WHERE C.IRN = :gstrEntryPoint AND CN.NAMETYPE = :p1"

If not exists(	Select 1 
		from ITEM I
		where ITEM_NAME=@sItemName)
Begin
	Set @nItemId=@nItemId+1

	insert into ITEM(ITEM_ID,ITEM_NAME,SQL_QUERY,ITEM_DESCRIPTION,CREATED_BY,DATE_CREATED,DATE_UPDATED,ITEM_TYPE, ENTRY_POINT_USAGE,SQL_DESCRIBE,SQL_INTO)
	values(@nItemId, @sItemName, @sSQLQuery, @sItemDesc, @sCreatedBy ,getdate(),getdate(),0,1,'1,1,1,1,1,1,1,1,1',':s[0],:s[1],:s[2],:s[3],:s[4],:s[5],:s[6],:s[7],:s[8]')

	PRINT '**** RFC45181 Doc Item created for "'+@sItemName+'"'
	PRINT ''
End
Else Begin
	PRINT '**** RFC45181 Doc Item "'+@sItemName+'" already exists'
	PRINT ''
End
------------------------------------
-- Insert B2B_HOME_NAME   
------------------------------------
Set @sItemName='B2B_HOME_NAME'
Set @sItemDesc='Returns the name and address details of the home name.  Use Home No site control to determine the name number. No entry point is required.'

Set @sSQLQuery="SELECT N.NAMECODE, N.NAME, A.STREET1, A.CITY, A.STATE, A.POSTCODE, A.COUNTRYCODE,"+char(13)+char(10)+
		    "T1.TELECOMNUMBER as Phone, T2.TELECOMNUMBER as Fax, T3.TELECOMNUMBER as Email"+char(13)+char(10)+
		    "FROM SITECONTROL S1"+char(13)+char(10)+
		    "JOIN NAME N ON N.NAMENO = S1.COLINTEGER"+char(13)+char(10)+
		    "JOIN ADDRESS A ON A.ADDRESSCODE = N.POSTALADDRESS"+char(13)+char(10)+
		    "LEFT JOIN TELECOMMUNICATION T1 ON T1.TELECODE = N.MAINPHONE"+char(13)+char(10)+
		    "LEFT JOIN TELECOMMUNICATION T2 ON T2.TELECODE = N.FAX"+char(13)+char(10)+
		    "LEFT JOIN TELECOMMUNICATION T3 ON T3.TELECODE = N.MAINEMAIL"+char(13)+char(10)+
		    "WHERE S1.CONTROLID = 'HOMENAMENO'"

If not exists(	Select 1 
		from ITEM I
		where ITEM_NAME=@sItemName)
Begin
	Set @nItemId=@nItemId+1

	insert into ITEM(ITEM_ID,ITEM_NAME,SQL_QUERY,ITEM_DESCRIPTION,CREATED_BY,DATE_CREATED,DATE_UPDATED,ITEM_TYPE, ENTRY_POINT_USAGE,SQL_DESCRIBE,SQL_INTO)
	values(@nItemId, @sItemName, @sSQLQuery, @sItemDesc, @sCreatedBy ,getdate(),getdate(),0,1,'1,1,1,1,1,1,1,1',':s[0],:s[1],:s[2],:s[3],:s[4],:s[5],:s[6],:s[7]')

	PRINT '**** RFC45181 Doc Item created for "'+@sItemName+'"'
	PRINT ''
End
Else Begin
	PRINT '**** RFC45181 Doc Item "'+@sItemName+'" already exists'
	PRINT ''
End

------------------------------------
-- Insert B2B_OFFICE_DETAILS  
------------------------------------
Set @sItemName='B2B_OFFICE_DETAILS'
Set @sItemDesc='Returns the name and address of the office associated with the case. Uses CASES.OFFICEID'

Set @sSQLQuery="SELECT N.NAMECODE, N.NAME, A.STREET1, A.CITY, A.STATE, A.POSTCODE, A.COUNTRYCODE,"+char(13)+char(10)+
		    "T1.TELECOMNUMBER as Phone, T2.TELECOMNUMBER as Fax, T3.TELECOMNUMBER as Email"+char(13)+char(10)+
		    "FROM CASES C"+char(13)+char(10)+
		    "JOIN OFFICE O ON O.OFFICEID = C.OFFICEID"+char(13)+char(10)+
		    "JOIN NAME N ON N.NAMENO = O.ORGNAMENO"+char(13)+char(10)+
		    "JOIN ADDRESS A ON A.ADDRESSCODE = N.POSTALADDRESS"+char(13)+char(10)+
		    "JOIN COUNTRY CO ON CO.COUNTRYCODE = A.COUNTRYCODE"+char(13)+char(10)+
		    "LEFT JOIN TELECOMMUNICATION T1 ON T1.TELECODE = N.MAINPHONE"+char(13)+char(10)+
		    "LEFT JOIN TELECOMMUNICATION T2 ON T2.TELECODE = N.FAX"+char(13)+char(10)+
		    "LEFT JOIN TELECOMMUNICATION T3 ON T3.TELECODE = N.MAINEMAIL"+char(13)+char(10)+
		    "WHERE C.IRN = :gstrEntryPoint"

If not exists(	Select 1 
		from ITEM I
		where ITEM_NAME=@sItemName)
Begin
	Set @nItemId=@nItemId+1

	insert into ITEM(ITEM_ID,ITEM_NAME,SQL_QUERY,ITEM_DESCRIPTION,CREATED_BY,DATE_CREATED,DATE_UPDATED,ITEM_TYPE, ENTRY_POINT_USAGE,SQL_DESCRIBE,SQL_INTO)
	values(@nItemId, @sItemName, @sSQLQuery, @sItemDesc, @sCreatedBy ,getdate(),getdate(),0,1,'1,1,1,1,1,1,1,1',':s[0],:s[1],:s[2],:s[3],:s[4],:s[5],:s[6],:s[7]')

	PRINT '**** RFC45181 Doc Item created for "'+@sItemName+'"'
	PRINT ''
End
Else Begin
	PRINT '**** RFC45181 Doc Item "'+@sItemName+'" already exists'
	PRINT ''
End

------------------------------------
-- Insert B2B_OHIM_KIND_OF_MARK  
------------------------------------
Set @sItemName='B2B_OHIM_KIND_OF_MARK'
Set @sItemDesc='Will return the kind of mark applicable for OHIM. The valid values are Individual or Collective. Will return Collective if the sub-type is Collective Mark, otherwise will return Individual.'

Set @sSQLQuery="SELECT CASE WHEN C.SUBTYPE = 'L' THEN 'Collective'"+char(13)+char(10)+
		    "ELSE 'Individual' END"+char(13)+char(10)+
		    "FROM CASES C"+char(13)+char(10)+
		    "WHERE C.IRN = :gstrEntryPoint"

If not exists(	Select 1 
		from ITEM I
		where ITEM_NAME=@sItemName)
Begin
	Set @nItemId=@nItemId+1

	insert into ITEM(ITEM_ID,ITEM_NAME,SQL_QUERY,ITEM_DESCRIPTION,CREATED_BY,DATE_CREATED,DATE_UPDATED,ITEM_TYPE, ENTRY_POINT_USAGE,SQL_DESCRIBE,SQL_INTO)
	values(@nItemId, @sItemName, @sSQLQuery, @sItemDesc, @sCreatedBy ,getdate(),getdate(),0,1,'1',':s[0]')

	PRINT '**** RFC45181 Doc Item created for "'+@sItemName+'"'
	PRINT ''
End
Else Begin
	PRINT '**** RFC45181 Doc Item "'+@sItemName+'" already exists'
	PRINT ''
End

------------------------------------
-- Insert B2B_OHIM_MARK_FEATURE  
------------------------------------
Set @sItemName='B2B_OHIM_MARK_FEATURE'
Set @sItemDesc='Will return the mark feature type applicable for OHIM.'

Set @sSQLQuery="SELECT CASE"+char(13)+char(10)+
		    "WHEN C.TYPEOFMARK = 5101 THEN 'Figurative'"+char(13)+char(10)+
		    "WHEN C.TYPEOFMARK = 5102 THEN 'Word'"+char(13)+char(10)+
		    "WHEN C.TYPEOFMARK = 5103 THEN 'Sound'"+char(13)+char(10)+
		    "WHEN C.TYPEOFMARK = 5104 THEN 'Olfactory'"+char(13)+char(10)+
		    "WHEN C.TYPEOFMARK = 5105 THEN '3-D'"+char(13)+char(10)+
		    "WHEN C.TYPEOFMARK = 5106 THEN 'Colour'"+char(13)+char(10)+
		    "WHEN C.TYPEOFMARK = 5108 THEN 'Stylized characters'"+char(13)+char(10)+
		    "WHEN C.TYPEOFMARK = 5109 THEN 'Hologram'"+char(13)+char(10)+
		    "WHEN C.TYPEOFMARK = 5111 THEN 'Combined'"+char(13)+char(10)+
		    "ELSE 'Other' END"+char(13)+char(10)+
		    "FROM CASES C"+char(13)+char(10)+
		    "WHERE C.IRN = :gstrEntryPoint"

If not exists(	Select 1 
		from ITEM I
		where ITEM_NAME=@sItemName)
Begin
	Set @nItemId=@nItemId+1

	insert into ITEM(ITEM_ID,ITEM_NAME,SQL_QUERY,ITEM_DESCRIPTION,CREATED_BY,DATE_CREATED,DATE_UPDATED,ITEM_TYPE, ENTRY_POINT_USAGE,SQL_DESCRIBE,SQL_INTO)
	values(@nItemId, @sItemName, @sSQLQuery, @sItemDesc, @sCreatedBy ,getdate(),getdate(),0,1,'1',':s[0]')

	PRINT '**** RFC45181 Doc Item created for "'+@sItemName+'"'
	PRINT ''
End
Else Begin
	PRINT '**** RFC45181 Doc Item "'+@sItemName+'" already exists'
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
