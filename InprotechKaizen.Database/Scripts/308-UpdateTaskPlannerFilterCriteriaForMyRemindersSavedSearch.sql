/** DR-68815 Include Action criteria and remove staff or signatory	from 'My Reminders' search saved filter **/
IF EXISTS( SELECT 1 FROM QUERYFILTER 
					WHERE FILTERID = -31 
					AND PROCEDURENAME = 'ipw_TaskPlanner')
BEGIN
	UPDATE QUERYFILTER 
	SET XMLFILTERCRITERIA = '<Search>
   <Filtering>
      <ipw_TaskPlanner>
         <FilterCriteria>
            <Include>
               <IsReminders>1</IsReminders>
               <IsDueDates>0</IsDueDates>
			   <IsAdHocDates>1</IsAdHocDates>
            </Include>
            <BelongsTo>
               <NameKey Operator="0" IsCurrentUser="1" />
               <ActingAs IsReminderRecipient="1" IsResponsibleStaff="1">                
               </ActingAs>
            </BelongsTo>
            <Dates UseDueDate="1" UseReminderDate="1">
               <PeriodRange Operator="7">
                  <Type>W</Type>
                  <From>-4</From>
                  <To>2</To>
               </PeriodRange>
            </Dates>           
			<Actions IsRenewalsOnly="1" IsNonRenewalsOnly="1" IncludeClosed="0" />
         </FilterCriteria>
      </ipw_TaskPlanner>
   </Filtering>
</Search>'
WHERE FILTERID = -31 
					AND PROCEDURENAME = 'ipw_TaskPlanner'
END
