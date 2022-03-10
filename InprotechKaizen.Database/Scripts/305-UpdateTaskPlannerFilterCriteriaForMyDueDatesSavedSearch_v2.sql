/** DR-65778 Include Action criteria in 'My Due Dates saved' search saved filter **/
IF EXISTS( SELECT 1 FROM QUERYFILTER 
					WHERE FILTERID = -29 
					AND PROCEDURENAME = 'ipw_TaskPlanner')
BEGIN
	UPDATE QUERYFILTER 
	SET XMLFILTERCRITERIA = '<Search>
   <Filtering>
      <ipw_TaskPlanner>
         <FilterCriteria>
            <Include>
               <IsReminders>0</IsReminders>
               <IsDueDates>1</IsDueDates>
               <IsAdHocDates>1</IsAdHocDates>
            </Include>
            <BelongsTo>
               <NameKey Operator="0" IsCurrentUser="1" />
               <ActingAs IsReminderRecipient="0" IsResponsibleStaff="1">
                  <NameTypeKey>SIG</NameTypeKey>
                  <NameTypeKey>EMP</NameTypeKey>
               </ActingAs>
            </BelongsTo>
            <Dates UseDueDate="1" UseReminderDate="0">
               <PeriodRange Operator="7">
                  <Type>W</Type>
                  <From>-1</From>
                  <To>4</To>
               </PeriodRange>
            </Dates>
			<Actions IsRenewalsOnly="1" IsNonRenewalsOnly="1" IncludeClosed="0" />
         </FilterCriteria>
      </ipw_TaskPlanner>
   </Filtering>
</Search>'
WHERE FILTERID = -29 
					AND PROCEDURENAME = 'ipw_TaskPlanner'
END
