/** DR-42320 Updating column COMPONENT.INTERNALNAME	and removing default constraint**/

If exists (SELECT 1 FROM COMPONENTS WHERE INTERNALNAME = '')
BEGIN
	PRINT '**** DR-42320 Populating column COMPONENT.INTERNALNAME from COMPONENT.COMPONENTNAME'
	Update COMPONENTS set INTERNALNAME = COMPONENTNAME WHERE INTERNALNAME = ''
	Declare @ConstraintName nvarchar(200)
	Select @ConstraintName = d.Name
	from sys.tables t
		join sys.default_constraints d on (d.parent_object_id = t.object_id)
		join sys.columns c on (c.object_id = t.object_id
		and c.column_id = d.parent_column_id)
	where t.name = 'COMPONENTS'
		and c.name = 'INTERNALNAME'
	IF @ConstraintName IS NOT NULL
	BEGIN
		EXEC('ALTER TABLE COMPONENTS DROP CONSTRAINT ' + @ConstraintName)
		PRINT '**** DR-42320 Column COMPONENT.INTERNALNAME drop default constraint' 
	END
	PRINT '**** DR-42320 Column COMPONENT.INTERNALNAME populated' 

	EXEC ipu_UtilGenerateAuditTriggers 'COMPONENTS'
END
GO


	/******************************************************************************************/
	/*** RFC73505 Add data SITECONTROL.CONTROLID = Case Header Description (DR-38850)  		***/
	/******************************************************************************************/     
	If NOT exists(SELECT * FROM SITECONTROL WHERE CONTROLID = N'Case Header Description')
	BEGIN
		PRINT '**** RFC73505 Add data SITECONTROL.CONTROLID = Case Header Description (DR-38850) ****'
		 
		If exists(select 1 from INFORMATION_SCHEMA.TABLES 
			  where TABLE_NAME ='SITECONTROLCOMPONENTS')
		Begin
			-----------------------------------
			-- Ensure Release Version exists --
			-----------------------------------
			If not exists(select 1 from RELEASEVERSIONS where VERSIONNAME='Inprotech Apps 5.6')
				insert into RELEASEVERSIONS(VERSIONNAME, RELEASEDATE, SEQUENCE)
				values(N'Inprotech Apps 5.6', '20180817', 560000)
			-----------------------------
			-- Ensure Component exists --
			-----------------------------
			If not exists(select 1 from COMPONENTS where COMPONENTNAME='Case')
				insert into COMPONENTS(COMPONENTNAME,INTERNALNAME)
				values ('Case', 'Case')
			---------------------------
			-- Load the Site Control --
			---------------------------
			INSERT INTO SITECONTROL (CONTROLID, DATATYPE, COLCHARACTER, VERSIONID, INITIALVALUE, COMMENTS, NOTES)
			select N'Case Header Description',
			       N'C',
			       N'CASE_HEADER_DESCRIPTION',
			       VERSIONID,
			       N'CASE_HEADER_DESCRIPTION',
			       N'The format of the Case Header Description, that is displayed in the title of Inprotech Apps Case View page.',
			       N'The client can configure a short piece of text to be displayed in the Case View title after the IRN in Inprotech Apps. This Site Control will accept a Doc Item that should return a string that the client wants to see next to the IRN. The Doc Item should accept a :gstrEntryPoint parameter.'
			from RELEASEVERSIONS
			where VERSIONNAME='Inprotech Apps 5.6'
			-------------------------------------
			-- Link Site Control to Components --
			-------------------------------------
			Insert into SITECONTROLCOMPONENTS(SITECONTROLID, COMPONENTID)
			Select S.ID, C.COMPONENTID
			from COMPONENTS C
			join SITECONTROL S on (S.CONTROLID='Case Header Description')
			where C.COMPONENTNAME in ('Case')
		End
		Else Begin
			INSERT INTO SITECONTROL (CONTROLID, DATATYPE, COLCHARACTER, COMMENTS)
			VALUES (N'Case Header Description', N'C', N'CASE_HEADER_DESCRIPTION', N'The format of the Case Header Description, that is displayed in the title of Inprotech Apps Case View page.')
		End
		 
		PRINT '**** RFC73505 Data successfully added to SITECONTROL table (DR-38850) ****'
		PRINT ''
	END
	ELSE BEGIN 
		PRINT '**** RFC73505 SITECONTROL.CONTROLID = "Case Header Description" already exists (DR-38850) ****'
		PRINT ''
	END 



	/**************************************************************************************/
	/*** RFC73505 Add data ITEM.ITEM_NAME = CASE_HEADER_DESCRIPTION (DR-38850)  		***/
	/**************************************************************************************/     
	If not exists(select 1 from ITEM where ITEM_NAME='CASE_HEADER_DESCRIPTION')
	begin
		PRINT '**** RFC73505 Add data ITEM.ITEM_NAME = CASE_HEADER_DESCRIPTION (DR-38850) ****'
		declare @nItemId	int
	
		update L
		set @nItemId=1+(select MAX(ITEM_ID) from ITEM),
			INTERNALSEQUENCE=@nItemId
		From LASTINTERNALCODE L
		Where L.TABLENAME='ITEM'
	
		INSERT into ITEM(ITEM_ID, ITEM_NAME, SQL_QUERY, ITEM_DESCRIPTION, ITEM_TYPE, ENTRY_POINT_USAGE, SQL_DESCRIBE, SQL_INTO, CREATED_BY, DATE_CREATED, DATE_UPDATED)
		Values (@nItemId, 'CASE_HEADER_DESCRIPTION', 
		'select C.COUNTRYADJECTIVE + '' '' + Isnull(V.PROPERTYNAME, P.PROPERTYNAME)
		from COUNTRY C
		left join CASES CS on (CS.COUNTRYCODE = C.COUNTRYCODE)
		left join PROPERTYTYPE P on (P.PROPERTYTYPE = CS.PROPERTYTYPE)
		left join VALIDPROPERTY V on (V.PROPERTYTYPE = P.PROPERTYTYPE and V.COUNTRYCODE = CS.COUNTRYCODE)
		where CS.IRN = :gstrEntryPoint',
		'The format of the Case Header Description.',
		0, 1, 1, ':s[0]', left(system_user, 18), GETDATE(), GETDATE() )

		PRINT '**** RFC73505 Data successfully added to ITEM table (DR-38850) ****'
	END
	go