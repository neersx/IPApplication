/***************************************************************************/
/*** RFC45624 Doc Item to generate document metadata for DMS integration ***/
/***************************************************************************/

if not exists (select 1 from item where item_name = 'DMS_INTEGRATION_DOCUMENT_METADATA')
begin
	print '**** RFC45624 Create Doc Item DMS_INTEGRATION_DOCUMENT_METADATA'

	declare @id as int
	declare @script as nvarchar(max)
	select @id = max(item_id )+1 from item;

	set @script = 
'SELECT
	C.IRN AS MatterRef,
	CASE WHEN NSIG.NAMENO IS NULL 
		THEN dbo.fn_FormatName(NEMP.NAME, NEMP.FIRSTNAME, NULL, NEMP.NAMESTYLE) 
		ELSE dbo.fn_FormatName(NSIG.NAME, NSIG.FIRSTNAME, NULL, NSIG.NAMESTYLE) 
	END AS ResponsibleAttorneyName, 

	CASE WHEN NSIG.NAMENO IS NULL 
		THEN NEMP.NAMECODE
		ELSE NSIG.NAMECODE
	END AS ResponsibleAttorneyCode,

	dbo.fn_FormatName(NPR.NAME, NPR.FIRSTNAME, NULL, NPR.NAMESTYLE) AS ParalegalName,
	NPR.NAMECODE AS ParalegalCode,

	dbo.fn_FormatName(NCLIENT.NAME, NCLIENT.FIRSTNAME, NULL, NCLIENT.NAMESTYLE) AS ClientName,
	NCLIENT.NAMECODE AS ClientCode,

	OFFICE.DESCRIPTION AS ResponsibleOffice
FROM CASES C
LEFT JOIN CASENAME EMP ON (
	EMP.CASEID = C.CASEID
	AND EMP.NAMETYPE = ''EMP''
	AND EMP.SEQUENCE = (SELECT MIN(EMP1.SEQUENCE)
						FROM CASENAME EMP1
						WHERE EMP1.CASEID  =EMP.CASEID
						AND   EMP1.NAMETYPE=EMP.NAMETYPE
						AND  (EMP1.EXPIRYDATE  > GETDATE() OR EMP1.EXPIRYDATE IS NULL)
						AND  (EMP1.COMMENCEDATE <= GETDATE() OR EMP1.COMMENCEDATE IS NULL)))
LEFT JOIN NAME NEMP ON (EMP.NAMENO = NEMP.NAMENO)
LEFT JOIN CASENAME SIG ON (
	SIG.CASEID = C.CASEID
	AND SIG.NAMETYPE = ''SIG''
	AND SIG.SEQUENCE = (SELECT MIN(SIG1.SEQUENCE)
						FROM CASENAME SIG1
						WHERE SIG1.CASEID  =SIG.CASEID
						AND   SIG1.NAMETYPE=SIG.NAMETYPE
						AND  (SIG1.EXPIRYDATE  > GETDATE() OR SIG1.EXPIRYDATE IS NULL)
						AND  (SIG1.COMMENCEDATE <= GETDATE() OR SIG1.COMMENCEDATE IS NULL)))
LEFT JOIN NAME NSIG ON (SIG.NAMENO = NSIG.NAMENO)
LEFT JOIN CASENAME PR ON (
	PR.CASEID = C.CASEID
	AND PR.NAMETYPE = ''PR''
	AND PR.SEQUENCE = (SELECT MIN(PR1.SEQUENCE)
						FROM CASENAME PR1
						WHERE PR1.CASEID  =PR.CASEID
						AND   PR1.NAMETYPE=PR.NAMETYPE
						AND  (PR1.EXPIRYDATE  > GETDATE() OR PR1.EXPIRYDATE IS NULL)
						AND  (PR1.COMMENCEDATE <= GETDATE() OR PR1.COMMENCEDATE IS NULL)))
LEFT JOIN NAME NPR ON (PR.NAMENO = NPR.NAMENO)
LEFT JOIN CASENAME CLIENT ON (
	CLIENT.CASEID = C.CASEID
	AND CLIENT.NAMETYPE = ''I''
	AND CLIENT.SEQUENCE = (SELECT MIN(CLIENT1.SEQUENCE)
						FROM CASENAME CLIENT1
						WHERE CLIENT1.CASEID  = CLIENT.CASEID
						AND   CLIENT1.NAMETYPE= CLIENT.NAMETYPE
						AND  (CLIENT1.EXPIRYDATE  > GETDATE() OR CLIENT1.EXPIRYDATE IS NULL)
						AND  (CLIENT1.COMMENCEDATE <= GETDATE() OR CLIENT1.COMMENCEDATE IS NULL)))
LEFT JOIN NAME NCLIENT ON (CLIENT.NAMENO = NCLIENT.NAMENO)
LEFT JOIN OFFICE ON OFFICE.OFFICEID = C.OFFICEID
WHERE C.IRN = :gstrEntryPoint;
'

	insert into item(item_id, item_name, item_description, item_type, sql_describe, sql_into, sql_query)
	values(@id , 'DMS_INTEGRATION_DOCUMENT_METADATA' , 'Get document metadata for DMS integration' , 0, '1,1,1,1,1,1,1', ':s[0],:s[1],:s[2],:s[3],:s[4],:s[5],:s[6]', @script);

	print '**** RFC45624 Doc Item DMS_INTEGRATION_DOCUMENT_METADATA successfully added to ITEM table.'
    print ''
end
else
        print '**** RFC45624 Doc Item DMS_INTEGRATION_DOCUMENT_METADATA already exists'
        print ''
go