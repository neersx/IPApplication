	/**********************************************************************************************************/
	/*** RFC74578 Add data to SITECONTROLCOMPONENTS to link some Policing related Site Controls.   		***/
	/**********************************************************************************************************/   
	If exists(select 1 from INFORMATION_SCHEMA.TABLES 
			  where TABLE_NAME ='SITECONTROLCOMPONENTS')
	Begin

		If exists (select 1 from COMPONENTS where COMPONENTNAME='Policing')
		Begin
			If exists (select 1 from SITECONTROL where CONTROLID='Policing Retry After Minutes')
			Begin
				If not exists (	select 1 
						from COMPONENTS C
						join SITECONTROL S            on (S.CONTROLID ='Policing Retry After Minutes')
						join SITECONTROLCOMPONENTS SC on (SC.COMPONENTID=C.COMPONENTID
									      and SC.SITECONTROLID=S.ID)
						where C.COMPONENTNAME='Policing')
				Begin
					
					PRINT '**** RFC74578 Adding data SITECONTROLCOMPONENTS linking "Policing Retry After Minutes" to "Policing"'
					----------------------------------
					-- Link Site Control to Components
					----------------------------------
					Insert into SITECONTROLCOMPONENTS(SITECONTROLID, COMPONENTID)
					Select S.ID, C.COMPONENTID
					from COMPONENTS C
					join SITECONTROL S on (S.CONTROLID='Policing Retry After Minutes')
					where C.COMPONENTNAME in ('Policing')
				End
				Else Begin 
					PRINT '**** RFC74578 SITECONTROLCOMPONENTS linking "Policing Retry After Minutes" to "Policing" already exists.'
					PRINT ''
				END 
			End
			
			If exists (select 1 from SITECONTROL where CONTROLID='Policing Recalculates Event')
			Begin
				If not exists (	select 1 
						from COMPONENTS C
						join SITECONTROL S            on (S.CONTROLID ='Policing Recalculates Event')
						join SITECONTROLCOMPONENTS SC on (SC.COMPONENTID=C.COMPONENTID
									      and SC.SITECONTROLID=S.ID)
						where C.COMPONENTNAME='Policing')
				Begin
					
					PRINT '**** RFC74578 Adding data SITECONTROLCOMPONENTS linking "Policing Recalculates Event" to "Policing"'
					----------------------------------
					-- Link Site Control to Components
					----------------------------------
					Insert into SITECONTROLCOMPONENTS(SITECONTROLID, COMPONENTID)
					Select S.ID, C.COMPONENTID
					from COMPONENTS C
					join SITECONTROL S on (S.CONTROLID='Policing Recalculates Event')
					where C.COMPONENTNAME in ('Policing')
				End
				Else Begin 
					PRINT '**** RFC74578 SITECONTROLCOMPONENTS linking "Policing Recalculates Event" to "Policing" already exists.'
					PRINT ''
				END 
			End
		End
	End
	Go