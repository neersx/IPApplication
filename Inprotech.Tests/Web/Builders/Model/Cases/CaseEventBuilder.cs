using System;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Cases.Events;

namespace Inprotech.Tests.Web.Builders.Model.Cases
{
    public class CaseEventBuilder : IBuilder<CaseEvent>
    {
        public long Id { get; set; }
        public int? CaseId { get; set; }
        public int? EventNo { get; set; }
        public short? Cycle { get; set; }
        public DateTime? EventDate { get; set; }
        public DateTime? DueDate { get; set; }
        public int IsOccurredFlag { get; set; }
        public int IsDateDueSaved { get; set; }
        public int? EnteredDeadline { get; set; }
        public string PeriodTypeId { get; set; }
        public string DueDateResponsibilityNameType { get; set; }
        public int? EmployeeNo { get; set; }
        public Event Event { get; set; }
        public int? CreatedByCriteriaKey { get; set; }
        public string CreatedByActionKey { get; set; }

        public CaseEvent Build()
        {
            return new CaseEvent(
                                 CaseId ?? Fixture.Integer(),
                                 Event?.Id ?? EventNo ?? Fixture.Integer(),
                                 Cycle ?? Fixture.Short())
            {
                EventDate = EventDate,
                EventDueDate = DueDate,
                IsOccurredFlag = IsOccurredFlag,
                IsDateDueSaved = IsDateDueSaved,
                EnteredDeadline = EnteredDeadline,
                PeriodType = PeriodTypeId,
                DueDateResponsibilityNameType = DueDateResponsibilityNameType,
                EmployeeNo = EmployeeNo,
                Event = Event,
                CreatedByCriteriaKey = CreatedByCriteriaKey,
                CreatedByActionKey = CreatedByActionKey,
                Id = Id
            };
        }
    }

    public static class CaseEventBuilderExt
    {
        public static CaseEventBuilder AsEventOccurred(
            this CaseEventBuilder source,
            DateTime? occurredEventDate = default(DateTime?))
        {
            source.EventDate = occurredEventDate;
            source.IsOccurredFlag = 1; /* must be between 1 and 8 */
            return source;
        }

        public static CaseEvent BuildForCase(this CaseEventBuilder source, Case @case)
        {
            source.CaseId = @case.Id;
            var returnEvent = source.Build();
            @case.CaseEvents.Add(returnEvent);
            return returnEvent;
        }
    }
}