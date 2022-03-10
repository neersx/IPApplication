using System;
using System.Collections.Generic;
using System.Linq;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Components.Cases.Extensions;
using InprotechKaizen.Model.Rules;

namespace InprotechKaizen.Model.Components.Cases.PostModificationTasks
{
    public class OfficialNumberDateInForceUpdateTask : IPostCaseDetailModificationTask
    {
        public PostCaseDetailModificationTaskResult Run(
            Case @case,
            DataEntryTask dataEntryTask,
            AvailableEventToConsider[] eventsToConsider)
        {
            if(@case == null) throw new ArgumentNullException("case");
            if(dataEntryTask == null) throw new ArgumentNullException("dataEntryTask");

            var returnResult = new PostCaseDetailModificationTaskResult();

            if(dataEntryTask.OfficialNumberType == null) return returnResult;
            if(dataEntryTask.OfficialNumberType.RelatedEventId == null) return returnResult;

            var relatedCaseEvent = GetDatefromCaseEvent(dataEntryTask.OfficialNumberType.RelatedEventId, @case.CaseEvents);
            var currentOfficialNumber = @case.CurrentOfficialNumberFor(dataEntryTask);

            if(relatedCaseEvent == null) return returnResult;
            if(currentOfficialNumber == null) return returnResult;

            currentOfficialNumber.DateEntered = relatedCaseEvent.EventDate;

            return returnResult;
        }

        static CaseEvent GetDatefromCaseEvent(int? relatedEventNo, IEnumerable<CaseEvent> caseEvents)
        {
            return caseEvents.OrderByDescending(ce => ce.Cycle)
                             .FirstOrDefault(ce => ce.EventNo == relatedEventNo);
        }
    }
}