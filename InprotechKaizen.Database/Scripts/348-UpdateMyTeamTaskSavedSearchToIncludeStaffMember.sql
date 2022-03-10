/** DR-72657 Include Staff Member in 'My Team Task' search saved filter **/
IF EXISTS( SELECT 1 FROM QUERYFILTER 
					WHERE FILTERID = -28 
					AND PROCEDURENAME = 'ipw_TaskPlanner')
BEGIN
	UPDATE QUERYFILTER 
	SET XMLFILTERCRITERIA = '<Search>
   <Filtering>
      <ipw_TaskPlanner>
         <FilterCriteria>
            <Include>
               <IsReminders>1</IsReminders>
               <IsDueDates>1</IsDueDates>
			   <IsAdHocDates>1</IsAdHocDates>
            </Include>
            <BelongsTo>
               <MemberOfGroupKey Operator="0" IsCurrentUser="1" />
               <ActingAs IsReminderRecipient="1" IsResponsibleStaff="1">
			    <NameTypeKey>EMP</NameTypeKey>
               </ActingAs>
            </BelongsTo>
            <Dates UseDueDate="1" UseReminderDate="1">
               <PeriodRange Operator="7">
                  <Type>W</Type>
                  <From>-4</From>
                  <To>2</To>
               </PeriodRange>
            </Dates>            
         </FilterCriteria>
      </ipw_TaskPlanner>
   </Filtering>
</Search>'
WHERE FILTERID = -28 
					AND PROCEDURENAME = 'ipw_TaskPlanner'
END
