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
	/*** RFC72579 Add data SITECONTROL.CONTROLID = Case View Summary Image Type (DR-35518)  ***/
	/******************************************************************************************/     
	If NOT exists(SELECT * FROM SITECONTROL WHERE CONTROLID = N'Case View Summary Image Type')
	BEGIN
		PRINT '**** RFC72579 Add data SITECONTROL.CONTROLID = Case View Summary Image Type (DR-35518) ****'
		 
		If exists(select 1 from INFORMATION_SCHEMA.TABLES where TABLE_NAME ='SITECONTROLCOMPONENTS')
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
				values ('Case','Case')
			---------------------------
			-- Load the Site Control --
			---------------------------
			INSERT INTO SITECONTROL (CONTROLID, DATATYPE, COLCHARACTER, VERSIONID, INITIALVALUE, COMMENTS, NOTES)
			select N'Case View Summary Image Type',
			       N'C',
			       null,
			       VERSIONID,
			       N'None',
			       N'Determines which Image Types can be used in the Case Summary section. You can specify multiple image types here, separated by commas.',
				   N'If multiple image types from this site control exist in a case, then the first matching image type in the list will be used. If multiple images of that type exist for the case, the image with the lowest Order value will be used as the display image.'
			from RELEASEVERSIONS R
			where VERSIONNAME='Inprotech Apps 5.6'
			-------------------------------------
			-- Link Site Control to Components --
			-------------------------------------
			Insert into SITECONTROLCOMPONENTS(SITECONTROLID, COMPONENTID)
			Select S.ID, C.COMPONENTID
			from COMPONENTS C
			join SITECONTROL S on (S.CONTROLID='Case View Summary Image Type')
			where C.COMPONENTNAME in ('Case')

			UPDATE V
			set V.COLCHARACTER = cast(L.COLINTEGER as varchar(10))
			from SITECONTROL V
			left join SITECONTROL L on (L.CONTROLID = 'Image Type for Case Header')
			where V.CONTROLID = 'Case View Summary Image Type'
			
		End
		Else Begin
			INSERT INTO SITECONTROL (CONTROLID, DATATYPE, COLCHARACTER, COMMENTS)
			VALUES (N'Case View Summary Image Type', N'C', null, N'Determines which Image Types can be used in the Case Summary section. You can specify multiple image types here, separated by commas.')

			UPDATE V
			set V.COLCHARACTER = cast(L.COLINTEGER as varchar(10))
			from SITECONTROL V
			left join SITECONTROL L on (L.CONTROLID = 'Image Type for Case Header')
			where V.CONTROLID = 'Case View Summary Image Type'
		End
		 
		PRINT '**** RFC72579 Data successfully added to SITECONTROL table (DR-35518) ****'
		PRINT ''
	END
	ELSE BEGIN 
		PRINT '**** RFC72579 SITECONTROL.CONTROLID = "Case View Summary Image Type" already exists (DR-35518) ****'
		PRINT ''
	END 