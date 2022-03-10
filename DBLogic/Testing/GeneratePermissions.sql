set quoted_identifier off
set nocount on

-- Generate the SQL in insert new permissions onto the database.
-- Update the <Permissions> XML below with your requirements
-- and run the script with output to text.

Declare @sPermissions 	as varchar(8000)

Set @sPermissions = "
<Permissions>
	<ChangeReference>RFCxxx</ChangeReference>
	<Comment>Add new task xxx</Comment>
	<!-- The level the permissions are granted; e.g. ROLE -->
	<LevelTable>ROLE</LevelTable>
	<!-- The type of object being managed; e.g. TASK -->
	<ObjectTable>TASK</ObjectTable>
	<Permission>
		<ObjectIntegerKey></ObjectIntegerKey>
		<ObjectStringKey></ObjectStringKey>
		<LevelKey></LevelKey>
		<!-- Place 0/1 in appropriate flags -->
		<GrantSelect></GrantSelect>
		<GrantInsert></GrantInsert>
		<GrantUpdate></GrantUpdate>
		<GrantDelete></GrantDelete>
		<GrantExecute></GrantExecute>
		<GrantMandatory></GrantMandatory>
		<DenySelect></DenySelect>
		<DenyInsert></DenyInsert>
		<DenyUpdate></DenyUpdate>
		<DenyDelete></DenyDelete>
		<DenyExecute></DenyExecute>
		<DenyMandatory></DenyMandatory>
		<IsDefinition></IsDefinition>
		<IsPermission></IsPermission>
	</Permission>
</Permissions>
"

Declare @sRFC 		as nvarchar(10)
Declare @sComment	as nvarchar(254)
Declare @sObjectTable 	as nvarchar(30)
Declare @sLevelTable 	as nvarchar(30)
Declare @idoc 		int 		-- Declare a document handle of the XML document in memory that is created by sp_xml_preparedocument		
Declare @tblPermission table
	(ObjectIntegerKey	int,
 	 ObjectStringKey	nvarchar(30),
 	 LevelKey		int,		
 	 GrantSelect		bit,
 	 GrantInsert		bit,
 	 GrantUpdate		bit,
 	 GrantDelete		bit,
 	 GrantExecute		bit,
 	 GrantMandatory		bit,
 	 DenySelect		bit,
 	 DenyInsert		bit,
 	 DenyUpdate		bit,
 	 DenyDelete		bit,
 	 DenyExecute		bit,
 	 DenyMandatory		bit,
	 IsDefinition		bit,
	 IsPermission		bit,
	 GrantPermission	tinyint,
	 DenyPermission		tinyint
)

-- Extract the information from the XML

exec sp_xml_preparedocument	@idoc OUTPUT, @sPermissions

Select 	@sRFC 			= ChangeReference,
	@sComment		= Comment,
	@sLevelTable		= upper(LevelTable),
	@sObjectTable		= upper(ObjectTable)
from	OPENXML (@idoc, '/Permissions',2)
	WITH (
	      ChangeReference		nvarchar(10)	'ChangeReference/text()',
	      Comment			nvarchar(254)	'Comment/text()',
	      LevelTable		nvarchar(30)	'LevelTable/text()',
	      ObjectTable		nvarchar(30)	'ObjectTable/text()'
	     )

Insert into @tblPermission (ObjectIntegerKey,ObjectStringKey,LevelKey,GrantSelect,GrantInsert,GrantUpdate,GrantDelete,GrantExecute,GrantMandatory,
	DenySelect,DenyInsert,DenyUpdate,DenyDelete,DenyExecute,DenyMandatory,IsDefinition,IsPermission)
	Select  *   
	from	OPENXML(@idoc, '/Permissions/Permission',1)
		WITH (
		      ObjectIntegerKey	int	'ObjectIntegerKey/text()',
		      ObjectStringKey	nvarchar(30) 'ObjectStringKey/text()',
		      LevelKey		int	'LevelKey/text()',
		      GrantSelect	bit	'GrantSelect/text()',
		      GrantInsert	bit	'GrantInsert/text()',
		      GrantUpdate	bit	'GrantUpdate/text()',
		      GrantDelete	bit	'GrantDelete/text()',
		      GrantExecute	bit	'GrantExecute/text()',
		      GrantMandatory	bit	'GrantMandatory/text()',
		      DenySelect	bit	'DenySelect/text()',
		      DenyInsert	bit	'DenyInsert/text()',
		      DenyUpdate	bit	'DenyUpdate/text()',
		      DenyDelete	bit	'DenyDelete/text()',
		      DenyExecute	bit	'DenyExecute/text()',
		      DenyMandatory	bit	'DenyMandatory/text()',
		      IsDefinition	bit	'IsDefinition/text()',
		      IsPermission	bit	'IsPermission/text()'
		     )	

exec sp_xml_removedocument @idoc

-- Calculate bitwise fields for permissions

UPDATE @tblPermission
	SET GrantPermission = 
		case when GrantSelect = 1 then 1 else 0 end |
		case when GrantInsert = 1 then 8 else 0 end |
		case when GrantUpdate = 1 then 2 else 0 end |
		case when GrantDelete = 1 then 16 else 0 end |
		case when GrantExecute = 1 then 32 else 0 end |
		case when GrantMandatory = 1 then 64 else 0 end,
	DenyPermission = 
		case when DenySelect = 1 then 1 else 0 end |
		case when DenyInsert = 1 then 8 else 0 end |
		case when DenyUpdate = 1 then 2 else 0 end |
		case when DenyDelete = 1 then 16 else 0 end |
		case when DenyExecute = 1 then 32 else 0 end |
		case when DenyMandatory = 1 then 64 else 0 end

-- Add definitions comment if necessary
If exists(select 1 FROM @tblPermission where IsDefinition = 1)
Begin
	select "
    	/**********************************************************************************************************/
    	/*** "+@sRFC+" "+@sComment+" - Definition									***/
	/**********************************************************************************************************/"
End

-- Generate definitions SQL
SELECT 
"	If NOT exists(SELECT * FROM PERMISSIONS WHERE OBJECTTABLE = '"+@sObjectTable+"'"+CHAR(10)+
CASE 	WHEN ObjectStringKey is not null then
"				and OBJECTSTRINGKEY = '"+ObjectStringKey+"'" +CHAR(10)
     	WHEN ObjectIntegerKey is not null then
"				and OBJECTINTEGERKEY = "+CAST(ObjectIntegerKey AS nvarchar)+CHAR(10)
	ELSE
"				and OBJECTINTEGERKEY IS NULL"+CHAR(10)+
"				and OBJECTSTRINGKEY IS NULL"+CHAR(10)
	end+
"				and LEVELTABLE IS NULL"+CHAR(10)+
"				and LEVELKEY IS NULL)"+CHAR(10)+
"        	BEGIN"+CHAR(10)+
"         	 PRINT '**** "+@sRFC+" Adding "+@sObjectTable+" definition data PERMISSIONS"+
			case when (ObjectStringKey is not null or ObjectIntegerKey is not null)
			then ".OBJECTKEY = "+
				case when ObjectStringKey is null then CAST(ObjectIntegerKey AS nvarchar) else ObjectStringKey end+"'"
			else "'"
			end+CHAR(10)+
"		 INSERT	PERMISSIONS (OBJECTTABLE, OBJECTINTEGERKEY, OBJECTSTRINGKEY, LEVELTABLE, LEVELKEY, GRANTPERMISSION, DENYPERMISSION) "+CHAR(10)+
"		 VALUES ('"+@sObjectTable+"', "+
			case when ObjectIntegerKey is null then "NULL" else CAST(ObjectIntegerKey AS nvarchar) end+", "+
			case when ObjectStringKey is null then "NULL" else "'"+ObjectStringKey+"'" end+", NULL, NULL, "+CAST(GrantPermission AS nvarchar)+", 0)"+CHAR(10)+
"        	 PRINT '**** "+@sRFC+" Data successfully added to PERMISSIONS table.'"+CHAR(10)+
"		 PRINT ''"+CHAR(10)+
"         	END"+CHAR(10)+
"    	ELSE"+CHAR(10)+
"        	BEGIN"+CHAR(10)+
"         	 PRINT '**** "+@sRFC+" "+@sObjectTable+" definition data PERMISSIONS"+
			case when (ObjectStringKey is not null or ObjectIntegerKey is not null)
			then ".OBJECTKEY = "+
				case when ObjectStringKey is null then CAST(ObjectIntegerKey AS nvarchar) else ObjectStringKey end
			else ""
			end+" already exists'"+CHAR(10)+
"		 PRINT ''"+CHAR(10)+
"         	END"+CHAR(10)+
"    	go"+CHAR(10)+
""
FROM @tblPermission
where IsDefinition = 1

-- Add permissions comment if necessary
If exists(select 1 FROM @tblPermission where IsPermission = 1)
Begin
	select "
    	/**********************************************************************************************************/
    	/*** "+@sRFC+" "+@sComment+" - Permissions									***/
	/**********************************************************************************************************/"
End

-- Generate permissions SQL

SELECT 
"	If NOT exists(SELECT * FROM PERMISSIONS WHERE OBJECTTABLE = '"+@sObjectTable+"'"+CHAR(10)+
CASE WHEN ObjectIntegerKey is null
	then
"				and OBJECTSTRINGKEY = '"+ObjectStringKey+"'" +CHAR(10)
	else
"				and OBJECTINTEGERKEY = "+CAST(ObjectIntegerKey AS nvarchar)+CHAR(10)
	end+
"				and LEVELTABLE = '"+@sLevelTable+"'"+CHAR(10)+
"				and LEVELKEY = "+CAST(LevelKey AS nvarchar) +")"+CHAR(10)+
"        	BEGIN"+CHAR(10)+
"         	 PRINT '**** "+@sRFC+" Adding "+@sObjectTable+" data PERMISSIONS.OBJECTKEY = "+
				case when ObjectStringKey is null then CAST(ObjectIntegerKey AS nvarchar) else ObjectStringKey end+"'"+CHAR(10)+
"		 INSERT	PERMISSIONS (OBJECTTABLE, OBJECTINTEGERKEY, OBJECTSTRINGKEY, LEVELTABLE, LEVELKEY, GRANTPERMISSION, DENYPERMISSION) "+CHAR(10)+
"		 VALUES ('"+@sObjectTable+"', "+
			case when ObjectIntegerKey is null then "NULL" else CAST(ObjectIntegerKey AS nvarchar) end+", "+
			case when ObjectStringKey is null then "NULL" else "'"+ObjectStringKey+"'" end+", '"+@sLevelTable+"', "+
			CAST(LevelKey AS nvarchar)+", "+CAST(GrantPermission AS nvarchar)+", "+CAST(DenyPermission AS nvarchar)+")"+CHAR(10)+
"        	 PRINT '**** "+@sRFC+" Data successfully added to PERMISSIONS table.'"+CHAR(10)+
"		 PRINT ''"+CHAR(10)+
"         	END"+CHAR(10)+
"    	ELSE"+CHAR(10)+
"         	BEGIN"+CHAR(10)+
"         	 PRINT '**** "+@sRFC+" "+@sObjectTable+" data PERMISSIONS.OBJECTKEY = "+
				case when ObjectStringKey is null then CAST(ObjectIntegerKey AS nvarchar) else ObjectStringKey end+" already exists'"+CHAR(10)+
"		 PRINT ''"+CHAR(10)+
"         	END"+CHAR(10)+
"    	go"+CHAR(10)+
""
FROM @tblPermission
where IsPermission = 1




