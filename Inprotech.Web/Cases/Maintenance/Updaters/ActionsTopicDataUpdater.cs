using System.Linq;
using Inprotech.Web.Cases.Maintenance.Models;
using Inprotech.Web.Maintenance.Topics;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Persistence;
using Microsoft.Rest;
using Newtonsoft.Json.Linq;

namespace Inprotech.Web.Cases.Maintenance.Updaters
{
    public class ActionsTopicDataUpdater : ITopicDataUpdater<Case>
    {
        public void UpdateData(JObject topicData, MaintenanceSaveModel model, Case @case)
        {
            var topic = topicData.ToObject<EventTopicSaveModel>();
            var caseEvents = @case.CaseEvents.ToList();
            foreach (var e in topic.Rows)
            {
                var editedEvent = caseEvents.SingleOrDefault(x => x.EventNo == e.EventNo && x.Cycle == e.Cycle);
                if (editedEvent == null)
                {
                    editedEvent = new CaseEvent(@case.Id, e.EventNo, (short)(e.Cycle ?? 1));
                    @case.CaseEvents.Add(editedEvent);
                }
                editedEvent.EventDate = e.EventDate?.Date;
                editedEvent.IsOccurredFlag = editedEvent.EventDate.HasValue ? 1 : 0;
                if (editedEvent.EventDueDate != e.EventDueDate?.Date)
                {
                    editedEvent.EventDueDate = e.EventDueDate?.Date;
                    editedEvent.IsDateDueSaved = editedEvent.EventDueDate.HasValue ? 1 : 0;
                }

                editedEvent.DueDateResponsibilityNameType = e.NameTypeKey;
                editedEvent.EmployeeNo = e.NameId;

            }
        }

        public void PostSaveData(JObject topicData, MaintenanceSaveModel model, Case @case)
        {
        }
    }
}