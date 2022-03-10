/******************************************************************************************************************/
/*** RFC42048 Create a logical program for external users							***/
/******************************************************************************************************************/

PRINT '**** RFC42048 Begin ****'
IF NOT EXISTS (Select 1 from SITECONTROL WHERE CONTROLID = 'Case Program for Client Access')
BEGIN
	/* SiteControl */
	PRINT 'Create SiteControl = Case Program for Client Access'
	
	INSERT INTO SITECONTROL (CONTROLID, DATATYPE, COLCHARACTER, COMMENTS)
	VALUES ('Case Program for Client Access','C', 'CASEEXT', 'The default cases program for Client Access.')
END
ELSE PRINT 'SiteControl already exists'
GO

IF NOT EXISTS (SELECT 1 FROM PROGRAM WHERE PROGRAMID = 'CASEEXT')
BEGIN
	/* Program */
	PRINT 'Create Program = CASEEXT'

	INSERT INTO PROGRAM(PROGRAMID, PROGRAMNAME, PARENTPROGRAM, PROGRAMGROUP)
	VALUES('CASEEXT', 'Case Client Access', 'CASE', 'C')
END
ELSE PRINT 'Program already exists'
GO

IF NOT EXISTS (SELECT 1 FROM PROFILES WHERE PROFILENAME = 'Client Access')
BEGIN TRY
	BEGIN TRANSACTION
	
	/* Profile */
	PRINT 'Create Profile = Client Access'

	INSERT INTO PROFILES(PROFILENAME, [DESCRIPTION])
	VALUES ('Client Access', 'A profile for external (client) users')

	/* ProfileAttribute */
	PRINT 'Create ProfileAttribute'

	INSERT INTO PROFILEATTRIBUTES(PROFILEID, ATTRIBUTEID, ATTRIBUTEVALUE)
	VALUES (SCOPE_IDENTITY(), 2, 'CASEEXT')

	COMMIT TRANSACTION
END TRY
BEGIN CATCH
	IF @@TRANCOUNT > 0
		ROLLBACK

	DECLARE @ErrMsg nvarchar(4000), @ErrSeverity int
	SELECT @ErrMsg = ERROR_MESSAGE(), @ErrSeverity = ERROR_SEVERITY()

	RAISERROR(@ErrMsg, @ErrSeverity, 1)
END CATCH
ELSE PRINT 'Profile already exists'
GO

IF NOT EXISTS (SELECT 1 FROM CRITERIA WHERE PROGRAMID='CASEEXT')
BEGIN TRY
	BEGIN TRANSACTION

	DECLARE @newCriteriaId INT
	DECLARE @windowControlNo INT
	DECLARE @topicControlNo INT

	PRINT 'Create Criteria for CASEEXT'
	
	SELECT @newCriteriaId = INTERNALSEQUENCE - 1 FROM LASTINTERNALCODE
	WHERE TABLENAME = 'CRITERIA_MAXIM'

	INSERT INTO CRITERIA(CRITERIANO, PURPOSECODE, PROGRAMID, [DESCRIPTION], PROPERTYUNKNOWN, COUNTRYUNKNOWN, CATEGORYUNKNOWN, SUBTYPEUNKNOWN, USERDEFINEDRULE, RULEINUSE, ISPUBLIC)
	VALUES (@newCriteriaId, 'W', 'CASEEXT', 'Default Case Windows for Client Access', 0, 0, 0, 0, 1, 1, 0)

	PRINT 'Update LastInternalCode'

	UPDATE LASTINTERNALCODE SET INTERNALSEQUENCE = @newCriteriaId
	WHERE TABLENAME = 'CRITERIA_MAXIM'

	PRINT 'Create WindowControl'

	INSERT INTO WINDOWCONTROL(CRITERIANO, WINDOWNAME, ISEXTERNAL, ISINHERITED)
	VALUES (@newCriteriaId, 'CaseDetails', 0, 0)
	
	SET @windowControlNo = SCOPE_IDENTITY()

	PRINT 'Create TopicControl for case header'
	
	INSERT INTO TOPICCONTROL(WINDOWCONTROLNO, TOPICNAME)
	VALUES (@windowControlNo, 'Case_HeaderTopic')
	
	SET @topicControlNo = SCOPE_IDENTITY()

	/* Case header */
	PRINT 'Create ElementControls for case header'

	INSERT INTO ELEMENTCONTROL(TOPICCONTROLNO, ELEMENTNAME, ISHIDDEN, ISMANDATORY, ISREADONLY, ISINHERITED)
	VALUES (@topicControlNo, 'cbLocalClientFlag', 1, 0, 1, 0)

	INSERT INTO ELEMENTCONTROL(TOPICCONTROLNO, ELEMENTNAME, ISHIDDEN, ISMANDATORY, ISREADONLY, ISINHERITED)
	VALUES (@topicControlNo, 'lblCaseOffice', 1, 0, 1, 0)

	INSERT INTO ELEMENTCONTROL(TOPICCONTROLNO, ELEMENTNAME, ISHIDDEN, ISMANDATORY, ISREADONLY, ISINHERITED)
	VALUES (@topicControlNo, 'lblClasses', 1, 0, 1, 0)

	INSERT INTO ELEMENTCONTROL(TOPICCONTROLNO, ELEMENTNAME, ISHIDDEN, ISMANDATORY, ISREADONLY, ISINHERITED)
	VALUES (@topicControlNo, 'lblClientName', 1, 0, 1, 0)

	INSERT INTO ELEMENTCONTROL(TOPICCONTROLNO, ELEMENTNAME, ISHIDDEN, ISMANDATORY, ISREADONLY, ISINHERITED)
	VALUES (@topicControlNo, 'lblFileLocation', 1, 0, 1, 0)

	INSERT INTO ELEMENTCONTROL(TOPICCONTROLNO, ELEMENTNAME, ISHIDDEN, ISMANDATORY, ISREADONLY, ISINHERITED)
	VALUES (@topicControlNo, 'lblFirstApplicant', 1, 0, 1, 0)

	INSERT INTO ELEMENTCONTROL(TOPICCONTROLNO, ELEMENTNAME, ISHIDDEN, ISMANDATORY, ISREADONLY, ISINHERITED)
	VALUES (@topicControlNo, 'lblNoInSeries', 1, 0, 1, 0)

	INSERT INTO ELEMENTCONTROL(TOPICCONTROLNO, ELEMENTNAME, ISHIDDEN, ISMANDATORY, ISREADONLY, ISINHERITED)
	VALUES (@topicControlNo, 'lblWorkingAttorney', 1, 0, 1, 0)

	INSERT INTO ELEMENTCONTROL(TOPICCONTROLNO, ELEMENTNAME, ISHIDDEN, ISMANDATORY, ISREADONLY, ISINHERITED)
	VALUES (@topicControlNo, 'pkProfitCentre', 1, 0, 1, 0)

	INSERT INTO ELEMENTCONTROL(TOPICCONTROLNO, ELEMENTNAME, FULLLABEL, ISHIDDEN, ISMANDATORY, ISREADONLY, ISINHERITED)
	VALUES (@topicControlNo, 'lblCaseReference', 'Our Reference', 0, 0, 1, 0)

	/* Names */
	PRINT 'Create TabControl for Names'

	INSERT INTO TABCONTROL(WINDOWCONTROLNO, TABNAME, TABTITLE, DISPLAYSEQUENCE, ISINHERITED)
	VALUES(@windowControlNo, 'Names_Component', 'Names', 0, 0)

	PRINT 'Create TopicControl for Names'

	INSERT INTO TOPICCONTROL(WINDOWCONTROLNO, TABCONTROLNO, TOPICNAME, ROWPOSITION, COLPOSITION, ISHIDDEN, ISMANDATORY, ISINHERITED)
	VALUES(@windowControlNo, SCOPE_IDENTITY(), 'Names_Component', 0, 0, 0, 0, 0)

	/* Events */
	PRINT 'Create TabControl for Events'

	INSERT INTO TABCONTROL(WINDOWCONTROLNO, TABNAME, TABTITLE, DISPLAYSEQUENCE, ISINHERITED)
	VALUES(@windowControlNo, 'Events_Component', 'Events', 1, 0)

	PRINT 'Create TopicControl for Events'

	INSERT INTO TOPICCONTROL(WINDOWCONTROLNO, TABCONTROLNO, TOPICNAME, ROWPOSITION, COLPOSITION, ISHIDDEN, ISMANDATORY, ISINHERITED)
	VALUES(@windowControlNo, SCOPE_IDENTITY(), 'Events_Component', 0, 0, 0, 0, 0)

	/* WorkInProgress */
	PRINT 'Create TabControl for WorkInProgress'

	INSERT INTO TABCONTROL(WINDOWCONTROLNO, TABNAME, TABTITLE, DISPLAYSEQUENCE, ISINHERITED)
	VALUES(@windowControlNo, 'WIP_Component', 'Work In Progress', 2, 0)

	PRINT 'Create TopicControl for WorkInProgress'

	INSERT INTO TOPICCONTROL(WINDOWCONTROLNO, TABCONTROLNO, TOPICNAME, ROWPOSITION, COLPOSITION, ISHIDDEN, ISMANDATORY, ISINHERITED)
	VALUES(@windowControlNo, SCOPE_IDENTITY(), 'WIP_Component', 0, 0, 0, 0, 0)

	/* Images */
	PRINT 'Create TabControl for Images'

	INSERT INTO TABCONTROL(WINDOWCONTROLNO, TABNAME, TABTITLE, DISPLAYSEQUENCE, ISINHERITED)
	VALUES(@windowControlNo, 'Images_Component', 'Images', 3, 0)

	PRINT 'Create TopControl for Images'
	
	INSERT INTO TOPICCONTROL(WINDOWCONTROLNO, TABCONTROLNO, TOPICNAME, ROWPOSITION, COLPOSITION, ISHIDDEN, ISMANDATORY, ISINHERITED)
	VALUES(@windowControlNo, SCOPE_IDENTITY(), 'Images_Component', 0, 0, 0, 0, 0)

	/* StandingInstructions */
	PRINT 'Create TabControl for StandingInstructions'

	INSERT INTO TABCONTROL(WINDOWCONTROLNO, TABNAME, TABTITLE, DISPLAYSEQUENCE, ISINHERITED)
	VALUES(@windowControlNo, 'CaseStandingInstructions_Component', 'Standing Instructions', 4, 0)

	PRINT 'Create TopControl for StandingInstructions'

	INSERT INTO TOPICCONTROL(WINDOWCONTROLNO, TABCONTROLNO, TOPICNAME, ROWPOSITION, COLPOSITION, ISHIDDEN, ISMANDATORY, ISINHERITED)
	VALUES(@windowControlNo, SCOPE_IDENTITY(), 'CaseStandingInstructions_Component', 0, 0, 0, 0, 0)
	
	/* Official Numbers */
	PRINT 'Create TabControl for OfficialNumbers'

	INSERT INTO TABCONTROL(WINDOWCONTROLNO, TABNAME, TABTITLE, DISPLAYSEQUENCE, ISINHERITED)
	VALUES(@windowControlNo, 'OfficialNumbers_Component', 'Official Numbers', 5, 0)

	PRINT 'Create TopControl for OfficialNumbers'

	INSERT INTO TOPICCONTROL(WINDOWCONTROLNO, TABCONTROLNO, TOPICNAME, ROWPOSITION, COLPOSITION, ISHIDDEN, ISMANDATORY, ISINHERITED)
	VALUES(@windowControlNo, SCOPE_IDENTITY(), 'OfficialNumbers_Component', 0, 0, 0, 0, 0)

	/* Case Text */
	PRINT 'Create TabControl for CaseText'

	INSERT INTO TABCONTROL(WINDOWCONTROLNO, TABNAME, TABTITLE, DISPLAYSEQUENCE, ISINHERITED)
	VALUES(@windowControlNo, 'Case_TextTopic', 'Case Text', 6, 0)

	PRINT 'Create TopControl for CaseText'

	INSERT INTO TOPICCONTROL(WINDOWCONTROLNO, TABCONTROLNO, TOPICNAME, ROWPOSITION, COLPOSITION, ISHIDDEN, ISMANDATORY, ISINHERITED)
	VALUES(@windowControlNo, SCOPE_IDENTITY(), 'Case_TextTopic', 0, 0, 0, 0, 0)

	/* BillingInstructions */
	PRINT 'Create TabControl for BillingInstructions'

	INSERT INTO TABCONTROL(WINDOWCONTROLNO, TABNAME, TABTITLE, DISPLAYSEQUENCE, ISINHERITED)
	VALUES(@windowControlNo, 'BillingInstructions_Component', 'Billing Instructions', 7, 0)

	PRINT 'Create TopControl for BillingInstructions'

	INSERT INTO TOPICCONTROL(WINDOWCONTROLNO, TABCONTROLNO, TOPICNAME, ROWPOSITION, COLPOSITION, ISHIDDEN, ISMANDATORY, ISINHERITED)
	VALUES(@windowControlNo, SCOPE_IDENTITY(), 'BillingInstructions_Component', 0, 0, 0, 0, 0)

	/* Classes */
	PRINT 'Create TabControl for Classes'

	INSERT INTO TABCONTROL(WINDOWCONTROLNO, TABNAME, TABTITLE, DISPLAYSEQUENCE, ISINHERITED)
	VALUES(@windowControlNo, 'Classes_Component', 'Classes', 8, 0)

	PRINT 'Create TopControl for Classes'

	INSERT INTO TOPICCONTROL(WINDOWCONTROLNO, TABCONTROLNO, TOPICNAME, ROWPOSITION, COLPOSITION, ISHIDDEN, ISMANDATORY, ISINHERITED)
	VALUES(@windowControlNo, SCOPE_IDENTITY(), 'Classes_Component', 0, 0, 0, 0, 0)

	/* Renewals */
	PRINT 'Create TabControl for Renewals'

	INSERT INTO TABCONTROL(WINDOWCONTROLNO, TABNAME, TABTITLE, DISPLAYSEQUENCE, ISINHERITED)
	VALUES(@windowControlNo, 'CaseRenewals_Component', 'Renewals', 9, 0)

	PRINT 'Create TopControl for Renewals'

	INSERT INTO TOPICCONTROL(WINDOWCONTROLNO, TABCONTROLNO, TOPICNAME, ROWPOSITION, COLPOSITION, ISHIDDEN, ISMANDATORY, ISINHERITED)
	VALUES(@windowControlNo, SCOPE_IDENTITY(), 'CaseRenewals_Component', 0, 0, 0, 0, 0)

	/* RelatedCases */
	PRINT 'Create TabControl for RelatedCases'

	INSERT INTO TABCONTROL(WINDOWCONTROLNO, TABNAME, TABTITLE, DISPLAYSEQUENCE, ISINHERITED)
	VALUES(@windowControlNo, 'RelatedCases_Component', 'Related Cases', 10, 0)

	PRINT 'Create TopControl for RelatedCases'

	INSERT INTO TOPICCONTROL(WINDOWCONTROLNO, TABCONTROLNO, TOPICNAME, ROWPOSITION, COLPOSITION, ISHIDDEN, ISMANDATORY, ISINHERITED)
	VALUES(@windowControlNo, SCOPE_IDENTITY(), 'RelatedCases_Component', 0, 0, 0, 0, 0)

	/* PriorArt */
	PRINT 'Create TabControl for PriorArt'

	INSERT INTO TABCONTROL(WINDOWCONTROLNO, TABNAME, TABTITLE, DISPLAYSEQUENCE, ISINHERITED)
	VALUES(@windowControlNo, 'PriorArt_Component', 'Prior Art', 11, 0)

	PRINT 'Create TopControl for PriorArt'

	INSERT INTO TOPICCONTROL(WINDOWCONTROLNO, TABCONTROLNO, TOPICNAME, ROWPOSITION, COLPOSITION, ISHIDDEN, ISMANDATORY, ISINHERITED)
	VALUES(@windowControlNo, SCOPE_IDENTITY(), 'PriorArt_Component', 0, 0, 0, 0, 0)

	/* CriticalDates */
	PRINT 'Create TabControl for CriticalDates'

	INSERT INTO TABCONTROL(WINDOWCONTROLNO, TABNAME, TABTITLE, DISPLAYSEQUENCE, ISINHERITED)
	VALUES(@windowControlNo, 'CriticalDates_Component', 'Critical Dates', 12, 0)

	PRINT 'Create TopControl for CriticalDates'

	INSERT INTO TOPICCONTROL(WINDOWCONTROLNO, TABCONTROLNO, TOPICNAME, ROWPOSITION, COLPOSITION, ISHIDDEN, ISMANDATORY, ISINHERITED)
	VALUES(@windowControlNo, SCOPE_IDENTITY(), 'CriticalDates_Component', 0, 0, 0, 0, 0)

	COMMIT TRANSACTION
END TRY
BEGIN CATCH
	IF @@TRANCOUNT > 0
		ROLLBACK

	DECLARE @ErrMsg nvarchar(4000), @ErrSeverity int
	SELECT @ErrMsg = ERROR_MESSAGE(), @ErrSeverity = ERROR_SEVERITY()

	RAISERROR(@ErrMsg, @ErrSeverity, 1)
END CATCH
ELSE BEGIN
	PRINT 'CRITERIA already exists'
	DECLARE @currentWindowControlNo INT 
	SELECT TOP 1 @currentWindowControlNo = w.WINDOWCONTROLNO FROM WINDOWCONTROL w inner join CRITERIA c on w.CRITERIANO = c.CRITERIANO and w.WINDOWNAME = 'CaseDetails' and C.PURPOSECODE = 'W' and C.PROGRAMID = 'CASEEXT'
	
	IF NOT EXISTS (SELECT 1 FROM TABCONTROL WHERE TABNAME='Case_TextTopic' and WINDOWCONTROLNO = @currentWindowControlNo) 
	BEGIN TRY
		BEGIN TRANSACTION
		/* Case Text */
		PRINT 'Create TabControl for CaseText for existing CRITERIA'
		INSERT INTO TABCONTROL(WINDOWCONTROLNO, TABNAME, TABTITLE, DISPLAYSEQUENCE, ISINHERITED)
		VALUES(@currentWindowControlNo, 'Case_TextTopic', 'Case Text', 6, 0)

		PRINT 'Create TopControl for CaseText for existing CRITERIA'
		INSERT INTO TOPICCONTROL(WINDOWCONTROLNO, TABCONTROLNO, TOPICNAME, ROWPOSITION, COLPOSITION, ISHIDDEN, ISMANDATORY, ISINHERITED)
		VALUES(@currentWindowControlNo, SCOPE_IDENTITY(), 'Case_TextTopic', 0, 0, 0, 0, 0) 

		PRINT 'Update TabControl Display Order for Existing BillingInstructions'
		UPDATE TABCONTROL SET DISPLAYSEQUENCE = 7 WHERE TABNAME = 'BillingInstructions_Component' and WINDOWCONTROLNO = @currentWindowControlNo

		PRINT 'Update TabControl Display Order for Existing Classes'
		UPDATE TABCONTROL SET DISPLAYSEQUENCE = 8 WHERE TABNAME = 'Classes_Component' and WINDOWCONTROLNO = @currentWindowControlNo

		PRINT 'Update TabControl Display Order for Existing Renewals'
		UPDATE TABCONTROL SET DISPLAYSEQUENCE = 9 WHERE TABNAME = 'CaseRenewals_Component' and WINDOWCONTROLNO = @currentWindowControlNo

		PRINT 'Update TabControl Display Order for Existing RelatedCases'
		UPDATE TABCONTROL SET DISPLAYSEQUENCE = 10 WHERE TABNAME = 'RelatedCases_Component' and WINDOWCONTROLNO = @currentWindowControlNo

		PRINT 'Update TabControl Display Order for Existing PriorArt'
		UPDATE TABCONTROL SET DISPLAYSEQUENCE = 11 WHERE TABNAME = 'PriorArt_Component' and WINDOWCONTROLNO = @currentWindowControlNo

		PRINT 'Update TabControl Display Order for Existing CriticalDates'
		UPDATE TABCONTROL SET DISPLAYSEQUENCE = 12 WHERE TABNAME = 'CriticalDates_Component' and WINDOWCONTROLNO = @currentWindowControlNo

		COMMIT TRANSACTION
	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT > 0
			ROLLBACK

		DECLARE @ErrMsg2 nvarchar(4000), @ErrSeverity2 int
		SELECT @ErrMsg2 = ERROR_MESSAGE(), @ErrSeverity2 = ERROR_SEVERITY()

		RAISERROR(@ErrMsg2, @ErrSeverity2, 1)
	END CATCH
END
GO

PRINT '**** RFC42048 End ****'
PRINT ''

/******************************************************************************************************************/
/*** RFC72942 Make Default Case Client Access screen control rule unprotected									***/
/*** Note: CASETYPE is null if the rule has not been updated since its initial delivery							***/
/******************************************************************************************************************/

IF EXISTS (SELECT 1 FROM CRITERIA WHERE PROGRAMID='CASEEXT' and PURPOSECODE = 'W' and USERDEFINEDRULE = 0 and CASETYPE IS NULL)
BEGIN
	PRINT 'Setting Default Case Client Access screen control rule to be unprotected...'
	UPDATE CRITERIA
	SET USERDEFINEDRULE = 1
	WHERE PROGRAMID='CASEEXT' and PURPOSECODE = 'W' and USERDEFINEDRULE = 0 and CASETYPE IS NULL
	PRINT 'Default Case Client Access screen control rule is now unprotected.'
	PRINT ''
END
ELSE BEGIN
	PRINT 'Default Case Client Access screen control rule is unprotected.'
	PRINT ''
END
