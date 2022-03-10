	PRINT '*** RFC74330 Start - Create table variable @CONFIGURATIONITEMIMPORT to store flat file data ***'

	Declare @CONFIGURATIONITEMIMPORT table
			(	[ID] [int] NULL,
				[TASKID] [smallint] NULL,
				[CONTEXTID] [int] NULL,
				[GENERICPARAM] [nvarchar](500) NULL,
				[TITLE] [nvarchar](600) NULL,
				[DESCRIPTION] [nvarchar](2500) NULL
			)
	PRINT '*** RFC74330 End - Successfully created table variable @CONFIGURATIONITEMIMPORT ***'

	PRINT '*** RFC74330 Start - Insert CONFIGURATIONITEM flat file data to table variable @CONFIGURATIONITEMIMPORT ***'

		INSERT @CONFIGURATIONITEMIMPORT ([ID], [TASKID], [CONTEXTID], [GENERICPARAM], [TITLE], [DESCRIPTION]) VALUES (2, 57, 280, NULL, N'Ad Hoc Templates', N'Maintain Ad Hoc Templates for Ad Hoc Reminders.')
		INSERT @CONFIGURATIONITEMIMPORT ([ID], [TASKID], [CONTEXTID], [GENERICPARAM], [TITLE], [DESCRIPTION]) VALUES (3, 75, 350, NULL, N'Standing Instructions', N'Maintain rules defining the Standing Instructions that may be provided by your firm''s clients.')
		INSERT @CONFIGURATIONITEMIMPORT ([ID], [TASKID], [CONTEXTID], [GENERICPARAM], [TITLE], [DESCRIPTION]) VALUES (4, 83, 390, NULL, N'Document Request Types', N'Maintain Document Request Types.')
		INSERT @CONFIGURATIONITEMIMPORT ([ID], [TASKID], [CONTEXTID], [GENERICPARAM], [TITLE], [DESCRIPTION]) VALUES (5, 115, NULL, NULL, N'Lists', N'Maintain Table Codes in the system.')
		INSERT @CONFIGURATIONITEMIMPORT ([ID], [TASKID], [CONTEXTID], [GENERICPARAM], [TITLE], [DESCRIPTION]) VALUES (7, 131, NULL, N'Case', N'Protected Rules - Case Windows', N'Maintain protected and firm-specific Case Window rules via Screen Designer.')
		INSERT @CONFIGURATIONITEMIMPORT ([ID], [TASKID], [CONTEXTID], [GENERICPARAM], [TITLE], [DESCRIPTION]) VALUES (8, 130, NULL, N'Case', N'Rules - Case Windows', N'Maintain user-defined Case Window rules via Screen Designer.')
		INSERT @CONFIGURATIONITEMIMPORT ([ID], [TASKID], [CONTEXTID], [GENERICPARAM], [TITLE], [DESCRIPTION]) VALUES (10, 131, NULL, N'Name', N'Protected Rules - Name Windows', N'Maintain protected and firm-specific Name Window rules via Screen Designer.')
		INSERT @CONFIGURATIONITEMIMPORT ([ID], [TASKID], [CONTEXTID], [GENERICPARAM], [TITLE], [DESCRIPTION]) VALUES (11, 130, NULL, N'Name', N'Rules - Name Windows', N'Maintain user-defined Name Window rules via Screen Designer.')
		INSERT @CONFIGURATIONITEMIMPORT ([ID], [TASKID], [CONTEXTID], [GENERICPARAM], [TITLE], [DESCRIPTION]) VALUES (12, 140, 610, NULL, N'Available Attribute List - Cases', N'Maintain Attribute Lists that are available for a Case.')
		INSERT @CONFIGURATIONITEMIMPORT ([ID], [TASKID], [CONTEXTID], [GENERICPARAM], [TITLE], [DESCRIPTION]) VALUES (13, 141, 620, NULL, N'Available Attribute List - Names', N'Maintain Attribute Lists that are available for a Name.')
		INSERT @CONFIGURATIONITEMIMPORT ([ID], [TASKID], [CONTEXTID], [GENERICPARAM], [TITLE], [DESCRIPTION]) VALUES (14, 147, NULL, NULL, N'Privileges', N'Maintain function security rules which control user privileges.')
		INSERT @CONFIGURATIONITEMIMPORT ([ID], [TASKID], [CONTEXTID], [GENERICPARAM], [TITLE], [DESCRIPTION]) VALUES (15, 148, NULL, NULL, N'Bill Formats', N'Maintain Bill Formats.')
		INSERT @CONFIGURATIONITEMIMPORT ([ID], [TASKID], [CONTEXTID], [GENERICPARAM], [TITLE], [DESCRIPTION]) VALUES (16, 152, 730, NULL, N'Function Terminology', N'Update terminology for business functions.')
		INSERT @CONFIGURATIONITEMIMPORT ([ID], [TASKID], [CONTEXTID], [GENERICPARAM], [TITLE], [DESCRIPTION]) VALUES (17, 153, 290, NULL, N'Images', N'Maintain Images.')
		INSERT @CONFIGURATIONITEMIMPORT ([ID], [TASKID], [CONTEXTID], [GENERICPARAM], [TITLE], [DESCRIPTION]) VALUES (18, 154, 810, NULL, N'Currencies', N'Maintain Currencies.')
		INSERT @CONFIGURATIONITEMIMPORT ([ID], [TASKID], [CONTEXTID], [GENERICPARAM], [TITLE], [DESCRIPTION]) VALUES (19, 155, 820, NULL, N'Exchange Rate Schedule', N'Maintain Exchange Rate Schedules.')
		INSERT @CONFIGURATIONITEMIMPORT ([ID], [TASKID], [CONTEXTID], [GENERICPARAM], [TITLE], [DESCRIPTION]) VALUES (20, 156, NULL, NULL, N'Bill Format Profiles', N'Maintain Bill Format Profiles.')
		INSERT @CONFIGURATIONITEMIMPORT ([ID], [TASKID], [CONTEXTID], [GENERICPARAM], [TITLE], [DESCRIPTION]) VALUES (21, 157, NULL, NULL, N'Bill Map Profiles', N'Maintain Bill Map Profiles.')
		INSERT @CONFIGURATIONITEMIMPORT ([ID], [TASKID], [CONTEXTID], [GENERICPARAM], [TITLE], [DESCRIPTION]) VALUES (22, 160, NULL, NULL, N'Case Search Columns', N'Maintain Case Search columns.')
		INSERT @CONFIGURATIONITEMIMPORT ([ID], [TASKID], [CONTEXTID], [GENERICPARAM], [TITLE], [DESCRIPTION]) VALUES (23, 161, NULL, NULL, N'Name Search Columns', N'Maintain Name Search columns.')
		INSERT @CONFIGURATIONITEMIMPORT ([ID], [TASKID], [CONTEXTID], [GENERICPARAM], [TITLE], [DESCRIPTION]) VALUES (24, 162, NULL, NULL, N'Opportunity Search Columns', N'Maintain Opportunity Search columns.')
		INSERT @CONFIGURATIONITEMIMPORT ([ID], [TASKID], [CONTEXTID], [GENERICPARAM], [TITLE], [DESCRIPTION]) VALUES (25, 163, NULL, NULL, N'Campaign Search Columns', N'Maintain Campaign Search columns.')
		INSERT @CONFIGURATIONITEMIMPORT ([ID], [TASKID], [CONTEXTID], [GENERICPARAM], [TITLE], [DESCRIPTION]) VALUES (26, 164, NULL, NULL, N'Marketing Event Search Columns', N'Maintain Marketing Event Search columns.')
		INSERT @CONFIGURATIONITEMIMPORT ([ID], [TASKID], [CONTEXTID], [GENERICPARAM], [TITLE], [DESCRIPTION]) VALUES (27, 165, NULL, NULL, N'Case Fee Search Columns', N'Maintain Case Fee Search columns.')
		INSERT @CONFIGURATIONITEMIMPORT ([ID], [TASKID], [CONTEXTID], [GENERICPARAM], [TITLE], [DESCRIPTION]) VALUES (28, 166, NULL, NULL, N'Case Instructions Search Columns', N'Maintain Case Instructions Search columns.')
		INSERT @CONFIGURATIONITEMIMPORT ([ID], [TASKID], [CONTEXTID], [GENERICPARAM], [TITLE], [DESCRIPTION]) VALUES (29, 167, NULL, NULL, N'Lead Search Columns', N'Maintain Lead Search columns.')
		INSERT @CONFIGURATIONITEMIMPORT ([ID], [TASKID], [CONTEXTID], [GENERICPARAM], [TITLE], [DESCRIPTION]) VALUES (30, 168, NULL, NULL, N'Activity Search Columns', N'Maintain Activity Search columns.')
		INSERT @CONFIGURATIONITEMIMPORT ([ID], [TASKID], [CONTEXTID], [GENERICPARAM], [TITLE], [DESCRIPTION]) VALUES (31, 169, NULL, NULL, N'WIP Overview Search Columns', N'Maintain WIP Overview Search columns.')
		INSERT @CONFIGURATIONITEMIMPORT ([ID], [TASKID], [CONTEXTID], [GENERICPARAM], [TITLE], [DESCRIPTION]) VALUES (32, 170, NULL, NULL, N'Client Request Search Columns', N'Maintain Client Request Search columns.')
		INSERT @CONFIGURATIONITEMIMPORT ([ID], [TASKID], [CONTEXTID], [GENERICPARAM], [TITLE], [DESCRIPTION]) VALUES (33, 171, NULL, NULL, N'Reciprocity Search Columns', N'Maintain Reciprocity Search columns.')
		INSERT @CONFIGURATIONITEMIMPORT ([ID], [TASKID], [CONTEXTID], [GENERICPARAM], [TITLE], [DESCRIPTION]) VALUES (34, 172, NULL, NULL, N'Work History Search Columns', N'Maintain Work History Search columns.')
		INSERT @CONFIGURATIONITEMIMPORT ([ID], [TASKID], [CONTEXTID], [GENERICPARAM], [TITLE], [DESCRIPTION]) VALUES (35, 173, NULL, NULL, N'External Case Search Columns', N'Maintain External Case Search columns.')
		INSERT @CONFIGURATIONITEMIMPORT ([ID], [TASKID], [CONTEXTID], [GENERICPARAM], [TITLE], [DESCRIPTION]) VALUES (36, 174, NULL, NULL, N'External Name Search Columns', N'Maintain External Name Search columns.')
		INSERT @CONFIGURATIONITEMIMPORT ([ID], [TASKID], [CONTEXTID], [GENERICPARAM], [TITLE], [DESCRIPTION]) VALUES (37, 175, NULL, NULL, N'External Client Request Search Columns', N'Maintain External Client Request Search columns.')
		INSERT @CONFIGURATIONITEMIMPORT ([ID], [TASKID], [CONTEXTID], [GENERICPARAM], [TITLE], [DESCRIPTION]) VALUES (38, 176, NULL, NULL, N'External Case Instructions Search Columns', N'Maintain External Case Instructions Search columns.')
		INSERT @CONFIGURATIONITEMIMPORT ([ID], [TASKID], [CONTEXTID], [GENERICPARAM], [TITLE], [DESCRIPTION]) VALUES (39, 177, NULL, NULL, N'External Case Fee Search Columns', N'Maintain External Case Fee Search columns.')
		INSERT @CONFIGURATIONITEMIMPORT ([ID], [TASKID], [CONTEXTID], [GENERICPARAM], [TITLE], [DESCRIPTION]) VALUES (40, 178, NULL, NULL, N'Keep on Top Notes - Case Types', N'Associate Keep on Top Text Types with Case Types.')
		INSERT @CONFIGURATIONITEMIMPORT ([ID], [TASKID], [CONTEXTID], [GENERICPARAM], [TITLE], [DESCRIPTION]) VALUES (41, 179, NULL, NULL, N'Keep on Top Notes - Name Types', N'Associate Keep on Top Text Types with Name Types.')
		INSERT @CONFIGURATIONITEMIMPORT ([ID], [TASKID], [CONTEXTID], [GENERICPARAM], [TITLE], [DESCRIPTION]) VALUES (42, 131, NULL, N'Checklist', N'Protected Rules - Checklists', N'Maintain protected and firm-specific Checklist rules.')
		INSERT @CONFIGURATIONITEMIMPORT ([ID], [TASKID], [CONTEXTID], [GENERICPARAM], [TITLE], [DESCRIPTION]) VALUES (43, 130, NULL, N'Checklist', N'Rules - Checklists', N'Maintain user-defined Checklist rules.')
		INSERT @CONFIGURATIONITEMIMPORT ([ID], [TASKID], [CONTEXTID], [GENERICPARAM], [TITLE], [DESCRIPTION]) VALUES (44, 180, NULL, NULL, N'Questions', N'Maintain Questions.')
		INSERT @CONFIGURATIONITEMIMPORT ([ID], [TASKID], [CONTEXTID], [GENERICPARAM], [TITLE], [DESCRIPTION]) VALUES (45, 181, NULL, NULL, N'Offices', N'Maintain Offices that are available for the firm.')
		INSERT @CONFIGURATIONITEMIMPORT ([ID], [TASKID], [CONTEXTID], [GENERICPARAM], [TITLE], [DESCRIPTION]) VALUES (46, 158, NULL, NULL, N'Sanity Check Rules - Cases', N'Maintain Sanity Check rules for Cases in the system.')
		INSERT @CONFIGURATIONITEMIMPORT ([ID], [TASKID], [CONTEXTID], [GENERICPARAM], [TITLE], [DESCRIPTION]) VALUES (47, 187, NULL, NULL, N'Case Families', N'Maintain Case Families.')
		INSERT @CONFIGURATIONITEMIMPORT ([ID], [TASKID], [CONTEXTID], [GENERICPARAM], [TITLE], [DESCRIPTION]) VALUES (48, 32, NULL, NULL, N'Links', N'Maintain firm-wide Web Quick Links.')
		INSERT @CONFIGURATIONITEMIMPORT ([ID], [TASKID], [CONTEXTID], [GENERICPARAM], [TITLE], [DESCRIPTION]) VALUES (49, 188, NULL, NULL, N'Case List', N'Maintain Case Lists.')
		INSERT @CONFIGURATIONITEMIMPORT ([ID], [TASKID], [CONTEXTID], [GENERICPARAM], [TITLE], [DESCRIPTION]) VALUES (50, 190, NULL, NULL, N'Tax Codes', N'Maintain Tax Codes.')
		INSERT @CONFIGURATIONITEMIMPORT ([ID], [TASKID], [CONTEXTID], [GENERICPARAM], [TITLE], [DESCRIPTION]) VALUES (51, 156, NULL, N'BillCase', N'Bill Case Columns', N'Maintain Bill Case columns.')
		INSERT @CONFIGURATIONITEMIMPORT ([ID], [TASKID], [CONTEXTID], [GENERICPARAM], [TITLE], [DESCRIPTION]) VALUES (52, 195, NULL, NULL, N'What''s Due Search Columns', N'Maintain What''s Due Search columns.')
		INSERT @CONFIGURATIONITEMIMPORT ([ID], [TASKID], [CONTEXTID], [GENERICPARAM], [TITLE], [DESCRIPTION]) VALUES (53, 196, NULL, NULL, N'Ad Hoc Search Columns', N'Maintain Ad Hoc Search columns.')
		INSERT @CONFIGURATIONITEMIMPORT ([ID], [TASKID], [CONTEXTID], [GENERICPARAM], [TITLE], [DESCRIPTION]) VALUES (54, 197, NULL, NULL, N'To Do Search Columns', N'Maintain To Do search columns.')
		INSERT @CONFIGURATIONITEMIMPORT ([ID], [TASKID], [CONTEXTID], [GENERICPARAM], [TITLE], [DESCRIPTION]) VALUES (55, 198, NULL, NULL, N'Staff Reminders Search Columns', N'Maintain Staff Reminders Search columns.')
		INSERT @CONFIGURATIONITEMIMPORT ([ID], [TASKID], [CONTEXTID], [GENERICPARAM], [TITLE], [DESCRIPTION]) VALUES (59, 206, NULL, NULL, N'Keywords', N'Maintain Keywords.')
		INSERT @CONFIGURATIONITEMIMPORT ([ID], [TASKID], [CONTEXTID], [GENERICPARAM], [TITLE], [DESCRIPTION]) VALUES (60, 207, NULL, NULL, N'Sanity Check Rules - Names', N'Maintain Sanity Check rules for Names in the system.')
		INSERT @CONFIGURATIONITEMIMPORT ([ID], [TASKID], [CONTEXTID], [GENERICPARAM], [TITLE], [DESCRIPTION]) VALUES (58, 204, NULL, NULL, N'WIP Types', N'Maintain WIP Types.')
		INSERT @CONFIGURATIONITEMIMPORT ([ID], [TASKID], [CONTEXTID], [GENERICPARAM], [TITLE], [DESCRIPTION]) VALUES (61, 208, NULL, NULL, N'Office File Locations', N'Associate Offices with File Locations.')
		INSERT @CONFIGURATIONITEMIMPORT ([ID], [TASKID], [CONTEXTID], [GENERICPARAM], [TITLE], [DESCRIPTION]) VALUES (62, 218, NULL, NULL, N'First To File Access', N'Configure settings to enable integration with First To File (FTF).')
		INSERT @CONFIGURATIONITEMIMPORT ([ID], [TASKID], [CONTEXTID], [GENERICPARAM], [TITLE], [DESCRIPTION]) VALUES (63, 218, NULL, N'AdminTool', N'First To File Document Uploads', N'View and manage the progress of documents being uploaded to First To File (FTF).')
		INSERT @CONFIGURATIONITEMIMPORT ([ID], [TASKID], [CONTEXTID], [GENERICPARAM], [TITLE], [DESCRIPTION]) VALUES (64, 223, 960, NULL, N'Activity Templates', N'Maintain Activity Templates for Contact Activity management.')
		INSERT @CONFIGURATIONITEMIMPORT ([ID], [TASKID], [CONTEXTID], [GENERICPARAM], [TITLE], [DESCRIPTION]) VALUES (65, 245, NULL, NULL, N'Site Controls', N'Maintain Site Controls for the firm.')
		INSERT @CONFIGURATIONITEMIMPORT ([ID], [TASKID], [CONTEXTID], [GENERICPARAM], [TITLE], [DESCRIPTION]) VALUES (66, 215, NULL, NULL, N'USPTO Practitioner Sponsorship', N'Set up your USPTO Private PAIR Practitioner Sponsorship to allow Inprotech to access the USPTO on your firm''s behalf.')
		INSERT @CONFIGURATIONITEMIMPORT ([ID], [TASKID], [CONTEXTID], [GENERICPARAM], [TITLE], [DESCRIPTION]) VALUES (67, 216, NULL, NULL, N'Schedule USPTO Private PAIR Data Download', N'Schedule tasks to automatically download selected case data from the USPTO Private PAIR.')
		INSERT @CONFIGURATIONITEMIMPORT ([ID], [TASKID], [CONTEXTID], [GENERICPARAM], [TITLE], [DESCRIPTION]) VALUES (68, 225, NULL, NULL, N'Application Link Security', N'Generate and update security tokens for Application Links.')
		INSERT @CONFIGURATIONITEMIMPORT ([ID], [TASKID], [CONTEXTID], [GENERICPARAM], [TITLE], [DESCRIPTION]) VALUES (69, 228, NULL, NULL, N'Event Note Types', N'Maintain Event Note Types.')
		INSERT @CONFIGURATIONITEMIMPORT ([ID], [TASKID], [CONTEXTID], [GENERICPARAM], [TITLE], [DESCRIPTION]) VALUES (70, 232, NULL, NULL, N'Schedule EPO Data Download', N'Schedule tasks to automatically download selected case data from the European Patent Office.')
		INSERT @CONFIGURATIONITEMIMPORT ([ID], [TASKID], [CONTEXTID], [GENERICPARAM], [TITLE], [DESCRIPTION]) VALUES (71, 236, NULL, NULL, N'DMS Integration', N'Configure settings to enable integration with a Document Management System.')
		INSERT @CONFIGURATIONITEMIMPORT ([ID], [TASKID], [CONTEXTID], [GENERICPARAM], [TITLE], [DESCRIPTION]) VALUES (72, 227, NULL, NULL, N'Schedule USPTO TSDR Data Download', N'Schedule tasks to automatically download selected case data from the USPTO TSDR.')
		INSERT @CONFIGURATIONITEMIMPORT ([ID], [TASKID], [CONTEXTID], [GENERICPARAM], [TITLE], [DESCRIPTION]) VALUES (73, 239, NULL, N'EPO', N'Data Mapping for European Patent Office', N'Maintain data mapping for the European Patent Office.')
		INSERT @CONFIGURATIONITEMIMPORT ([ID], [TASKID], [CONTEXTID], [GENERICPARAM], [TITLE], [DESCRIPTION]) VALUES (74, 239, NULL, N'USPTO.PP', N'Data Mapping for USPTO Private PAIR', N'Maintain data mapping for USPTO Private PAIR.')
		INSERT @CONFIGURATIONITEMIMPORT ([ID], [TASKID], [CONTEXTID], [GENERICPARAM], [TITLE], [DESCRIPTION]) VALUES (75, 239, NULL, N'USPTO.TSDR', N'Data Mapping for USPTO TSDR', N'Maintain data mapping for USPTO TSDR.')
		INSERT @CONFIGURATIONITEMIMPORT ([ID], [TASKID], [CONTEXTID], [GENERICPARAM], [TITLE], [DESCRIPTION]) VALUES (77, 246, NULL, NULL, N'Statuses', N'Maintain Case and Renewal statuses.')
		INSERT @CONFIGURATIONITEMIMPORT ([ID], [TASKID], [CONTEXTID], [GENERICPARAM], [TITLE], [DESCRIPTION]) VALUES (78, 250, NULL, NULL, N'Rules - Workflow Designer', N'Maintain Workflow rules for the firm via Workflow Designer.')
		INSERT @CONFIGURATIONITEMIMPORT ([ID], [TASKID], [CONTEXTID], [GENERICPARAM], [TITLE], [DESCRIPTION]) VALUES (76, 244, NULL, NULL, N'Standing Instruction Definitions', N'Create and modify Standing Instructions,  including Instruction Types and Characteristics.')
		INSERT @CONFIGURATIONITEMIMPORT ([ID], [TASKID], [CONTEXTID], [GENERICPARAM], [TITLE], [DESCRIPTION]) VALUES (79, 251, NULL, NULL, N'Protected Rules - Workflow Designer', N'Maintain protected Workflow rules for the firm via Workflow Designer.')
		INSERT @CONFIGURATIONITEMIMPORT ([ID], [TASKID], [CONTEXTID], [GENERICPARAM], [TITLE], [DESCRIPTION]) VALUES (80, 252, NULL, NULL, N'Name Types', N'Maintain Name Types.')
		INSERT @CONFIGURATIONITEMIMPORT ([ID], [TASKID], [CONTEXTID], [GENERICPARAM], [TITLE], [DESCRIPTION]) VALUES (81, 253, NULL, NULL, N'Valid Combinations', N'View, create and maintain Valid Combinations for the following Characteristics: Action, Basis, Category, Checklist, Property Type, Case Relationship, Status and Sub Type.')
		INSERT @CONFIGURATIONITEMIMPORT ([ID], [TASKID], [CONTEXTID], [GENERICPARAM], [TITLE], [DESCRIPTION]) VALUES (82, 254, NULL, NULL, N'Jurisdictions', N'Maintain Jurisdictions for the firm (includes countries and country groups).')
		INSERT @CONFIGURATIONITEMIMPORT ([ID], [TASKID], [CONTEXTID], [GENERICPARAM], [TITLE], [DESCRIPTION]) VALUES (83, 237, NULL, NULL, N'Name Relationships', N'Maintain Name Relationships.')
		INSERT @CONFIGURATIONITEMIMPORT ([ID], [TASKID], [CONTEXTID], [GENERICPARAM], [TITLE], [DESCRIPTION]) VALUES (84, 238, NULL, NULL, N'Name Alias Types', N'Maintain Name Alias Types.')
		INSERT @CONFIGURATIONITEMIMPORT ([ID], [TASKID], [CONTEXTID], [GENERICPARAM], [TITLE], [DESCRIPTION]) VALUES (85, 234, NULL, NULL, N'Localities', N'Maintain Localities.')
		INSERT @CONFIGURATIONITEMIMPORT ([ID], [TASKID], [CONTEXTID], [GENERICPARAM], [TITLE], [DESCRIPTION]) VALUES (86, 241, NULL, NULL, N'Number Types', N'Maintain Number Types.')
		INSERT @CONFIGURATIONITEMIMPORT ([ID], [TASKID], [CONTEXTID], [GENERICPARAM], [TITLE], [DESCRIPTION]) VALUES (87, 260, NULL, NULL, N'Text Types', N'Maintain Text Types.')
		INSERT @CONFIGURATIONITEMIMPORT ([ID], [TASKID], [CONTEXTID], [GENERICPARAM], [TITLE], [DESCRIPTION]) VALUES (88, 261, NULL, NULL, N'Name Restrictions', N'Maintain Name Restrictions.')
		INSERT @CONFIGURATIONITEMIMPORT ([ID], [TASKID], [CONTEXTID], [GENERICPARAM], [TITLE], [DESCRIPTION]) VALUES (89, 262, NULL, NULL, N'Importance Levels', N'Maintain Importance Levels.')
		INSERT @CONFIGURATIONITEMIMPORT ([ID], [TASKID], [CONTEXTID], [GENERICPARAM], [TITLE], [DESCRIPTION]) VALUES (90, 266, NULL, NULL, N'Schedule Innography Data Download', N'Schedule tasks to automatically download selected case data from Innography.')
		INSERT @CONFIGURATIONITEMIMPORT ([ID], [TASKID], [CONTEXTID], [GENERICPARAM], [TITLE], [DESCRIPTION]) VALUES (91, 232, NULL, N'EPO', N'EPO Integration Settings', N'Configure required settings for EPO integration and data download.')
		INSERT @CONFIGURATIONITEMIMPORT ([ID], [TASKID], [CONTEXTID], [GENERICPARAM], [TITLE], [DESCRIPTION]) VALUES (92, 268, NULL, NULL, N'Jurisdictions', N'View Jurisdictions for the firm (includes countries and country groups).')
		INSERT @CONFIGURATIONITEMIMPORT ([ID], [TASKID], [CONTEXTID], [GENERICPARAM], [TITLE], [DESCRIPTION]) VALUES (93, 271, NULL, NULL, N'Schedule FILE Data Download', N'Schedule tasks to automatically download selected case data from FILE in the IP Platform.')
		INSERT @CONFIGURATIONITEMIMPORT ([ID], [TASKID], [CONTEXTID], [GENERICPARAM], [TITLE], [DESCRIPTION]) VALUES (94, 272, NULL, NULL, N'Data Items', N'Maintain Data Items (previously known as Doc Items).')
		INSERT @CONFIGURATIONITEMIMPORT ([ID], [TASKID], [CONTEXTID], [GENERICPARAM], [TITLE], [DESCRIPTION]) VALUES (95, 239, NULL, N'FILE', N'Data Mapping for FILE', N'Maintain data mapping for FILE.')
		INSERT @CONFIGURATIONITEMIMPORT ([ID], [TASKID], [CONTEXTID], [GENERICPARAM], [TITLE], [DESCRIPTION]) VALUES (96, 239, NULL, N'Innography', N'Data Mapping for Innography', N'Maintain data mapping for Innography.')
		INSERT @CONFIGURATIONITEMIMPORT ([ID], [TASKID], [CONTEXTID], [GENERICPARAM], [TITLE], [DESCRIPTION]) VALUES (97, 274, NULL, NULL, N'Screen Translations Utility', N'Maintain screen translations for different languages and cultures.')

	PRINT '*** RFC74330 End - Successfully inserted CONFIGURATIONITEM data to table variable @CONFIGURATIONITEMIMPORT ***'


	PRINT '*** RFC74330 Start - Create table variable @CONFIGURATIONITEMGROUPIMPORT to store CONFIGURATIONITEMGROUP flat file data ***'

		Declare @CONFIGURATIONITEMGROUPIMPORT table
			([ID] [int],
			[PREVTITLE] [varchar](8000),
			[TITLE] [varchar](8000),
			[DESCRIPTION] [varchar](8000)
			)

	PRINT '*** RFC74330 End - Successfully created table variable table @CONFIGURATIONITEMGROUPIMPORT ***'


	PRINT '*** RFC74330 Start - Insert CONFIGURATIONITEMGROUP flat file data to temp table @CONFIGURATIONITEMGROUPIMPORT ***'

		INSERT @CONFIGURATIONITEMGROUPIMPORT ([ID], [PREVTITLE], [TITLE], [DESCRIPTION]) VALUES (1, N'Schedule Data Download', N'Schedule Data Downloads', N'Schedule tasks to download data from external sources for use with Case Data Comparison.')
		INSERT @CONFIGURATIONITEMGROUPIMPORT ([ID], [PREVTITLE], [TITLE], [DESCRIPTION]) VALUES (2 , N'Rules - Workflows', N'Rules - Workflow Designer', N'Maintain Workflow rules for the firm via Workflow Designer.')
		INSERT @CONFIGURATIONITEMGROUPIMPORT ([ID], [PREVTITLE], [TITLE], [DESCRIPTION]) VALUES (3 , N'Jurisdictions', N'Jurisdictions', N'Maintain Jurisdictions for the firm (includes countries and country groups).')
	
	PRINT '*** RFC74330 End - Successfully inserted data to table variable @CONFIGURATIONITEMGROUPIMPORT ***'
	

	PRINT '*** RFC74330 Check if CONFIGURATIONITEM records need to be updated ***'

	IF EXISTS(SELECT * FROM  CONFIGURATIONITEM CI
		JOIN @CONFIGURATIONITEMIMPORT CII ON CI.TASKID = CII.TASKID 
											 AND ISNULL(CI.CONTEXTID,0) = ISNULL(CII.CONTEXTID,0) 
											 AND ISNULL(CI.GENERICPARAM,0) = ISNULL(CII.GENERICPARAM,0))
			BEGIN
				PRINT '*** RFC74330 Start - Update CONFIGURATIONITEM data from table variable @CONFIGURATIONITEMIMPORT table ***'
				UPDATE CI SET CI.TITLE = CII.TITLE,
							  CI.DESCRIPTION = CII.[DESCRIPTION]
				FROM CONFIGURATIONITEM CI
				JOIN @CONFIGURATIONITEMIMPORT CII ON CI.TASKID = CII.TASKID 
													 AND ISNULL(CI.CONTEXTID,0) = ISNULL(CII.CONTEXTID,0) 
													 AND ISNULL(CI.GENERICPARAM,0) = ISNULL(CII.GENERICPARAM,0)
				PRINT '*** RFC74330 End - Updated CONFIGURATIONITEM successfully ***'
			END
	ELSE
			PRINT '*** RFC74330 End - No CONFIGURATIONITEM records updated ***'

	PRINT '*** RFC74330 Check if CONFIGURATIONITEMGROUP records need to be updated  ***'

	IF EXISTS(SELECT *  FROM CONFIGURATIONITEMGROUP CIG
		JOIN @CONFIGURATIONITEMGROUPIMPORT CIGI ON CIG.TITLE = CIGI.PREVTITLE)
			BEGIN
				PRINT '*** RFC74330 Start - Update CONFIGURATIONITEMGROUP data from table variable @CONFIGURATIONITEMGROUPIMPORT table  ***'
				UPDATE CIG SET CIG.TITLE = CIGI.TITLE,
							   CIG.DESCRIPTION = CIGI.[DESCRIPTION]
				FROM CONFIGURATIONITEMGROUP CIG
				JOIN @CONFIGURATIONITEMGROUPIMPORT CIGI ON CIG.TITLE = CIGI.PREVTITLE
				PRINT '*** RFC74330 End - Updated CONFIGURATIONITEMGROUP successfully  ***'
			END
	ELSE
			PRINT '*** RFC74330 End - No CONFIGURATIONITEMGROUP records updated ***'
	

