    /**********************************************************************************************************/
    /*** DR-68402 Remove CRM Site Controls component CRM and Marketing from Release 16 onwards in apps												***/
	/**********************************************************************************************************/

    IF EXISTS(SELECT 1 from SITECONTROL SC
				JOIN SITECONTROLCOMPONENTS SCC on SC.ID = SCC.SITECONTROLID
				JOIN COMPONENTS C on SCC.COMPONENTID = C.COMPONENTID
				where SC.CONTROLID in ('CRM Convert Client Name Types', 'CRM Default Lead Status', 'CRM Default Mkting Act Status', 'CRM Default Network Filter', 'CRM Default Opportunity Status', 'CRM Name Screen Program',
				'CRM Opp Conversion Name Types', 'CRM Activity Accept Response', 'CRM Opp Status Closed Won', 'CRM Opportunity Name Group', 'CRM Screen Control Program',
				'Property Type Campaign', 'Property Type Marketing Event', 'Property Type Opportunity')
				and  C.COMPONENTNAME in ('x-obsolete'))
    BEGIN

		IF EXISTS(SELECT 1 from SITECONTROLCOMPONENTS SCC 
					JOIN COMPONENTS C on c.COMPONENTID =scc.COMPONENTID where c.COMPONENTNAME in ('Marketing','CRM'))
        		BEGIN
			
         		 PRINT '**** DR-68402 Removing reference of CRM & Marketing Site Controls component from SITECONTROLCOMPONENTS table'
				 PRINT ''

					DELETE SCC from SITECONTROLCOMPONENTS SCC 
					JOIN COMPONENTS C on c.COMPONENTID =scc.COMPONENTID where c.COMPONENTNAME in ('Marketing','CRM')
            
        		 PRINT '**** DR-68402 Removed reference of CRM & Marketing Site Controls component from SITECONTROLCOMPONENTS table'
				 PRINT ''
         		END
		ELSE
			  PRINT '**** DR-68402 CRM & Marketing Site Controls component does not exits.'
			 PRINT ''
   END
    ELSE
          PRINT '**** DR-68402 Release version is less than 16.'
          PRINT ''

    GO

   	