	/******************************************************************************************/
	/*** DR-73546 Update data SITECONTROL.CONTROLID = Alert Spawning Blocked ***/
	/******************************************************************************************/     
	IF EXISTS(SELECT 1 FROM SITECONTROL WHERE CONTROLID = N'Alert Spawning Blocked')
	BEGIN
		PRINT '**** DR-73546 Update data SITECONTROL.CONTROLID = Alert Spawning Blocked ****'
		 
			UPDATE SITECONTROL SET 
			COMMENTS = N'If set to True, Ad Hoc Dates configured for multiple reminder recipients will remain controlled by the owner of the Ad Hoc Date. If set to False, separate Ad Hoc Dates and reminders will be generated for each recipient.',
			NOTES = N'When an Ad Hoc Date (Alert) is configured to generate reminders to different recipients, the default position is for the system to create a separate Ad Hoc Date for each reminder recipient. This then allows recipients to directly control the generation of their own reminders. However, if this Site Control is set to True, only the original Ad Hoc Date will exist and will remain controlled by its owner. Other reminder recipients will not have any control over the generation of their reminders. Therefore, for example, if the owner finalises the Ad Hoc Date, it will be finalised for all recipients. Note that in Web Apps, any recipients manually selected in Additional name(s) will not be affected by this Site Control - a separate Ad Hoc Date and reminder will be generated for each name.'
			WHERE CONTROLID = N'Alert Spawning Blocked'
		 
		PRINT '**** DR-73546 Data successfully updated to SITECONTROL table for Alert Spawning Blocked****'
	END