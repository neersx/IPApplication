using System;
using System.Collections.Generic;
using System.Linq;
using Inprotech.Web.CaseSupportData;
using InprotechKaizen.Model.Components.Names;
using InprotechKaizen.Model.Names;
using Newtonsoft.Json;

namespace Inprotech.Web.Cases.Details
{
    public class ActionEventData
    {
        public int AttachmentCount { get; set; }
        public int EventNo { get; set; }
        public string EventCompositeKey => $"{EventNo}-{(Cycle.HasValue ? Cycle.Value.ToString() : string.Empty)}";
        public string EventDescription { get; set; }
        public DateTime? EventDate { get; set; }
        public DateTime? EventDueDate { get; set; }
        public DateTime? NextPoliceDate { get; set; }
        public int? Cycle { get; set; }
        public string CreatedByAction { get; set; }
        public string CreatedByActionDesc { get; set; }
        public int? CreatedByCriteria { get; set; }
        public string Name => RespName?.FormattedNameOrNull();
        public string NameType { get; set; }
        public int? NameTypeId { get; set; }
        public int? NameId => RespName?.Id;

        public bool IsNew { get; set; }

        public string FromCaseIrn { get; set; }

        public int? FromCaseKey { get; set; }
        public int? CaseKey { get; set; }

        public string Period { get; set; }

        public string ImportanceLevel { get; set; }

        public bool IsProtentialEvents { get; set; }
        public bool IsManuallyEntered { get; set; }
        public bool HasEventHistory { get; set; }

        [JsonIgnore]
        public string EventImportanceLevel { get; set; }
        public int? DisplaySequence { get; set; }

        public string Responsibility => NameType ?? Name;

        public decimal? IsOccurredFlag { get; set; }

        public bool StopPolicing { get; set; } // => EventDate == null && CaseEventExt.HasOccured(IsOccurredFlag);

        public bool CanLinkToWorkflow { get; set; }

        public string DefaultEventText => EventNotes?.FirstOrDefault(_ => _.IsDefault == true)?.EventText;
        public IEnumerable<CaseEventNotesData> EventNotes { get; set; }

        [JsonIgnore]
        public Name RespName { get; set; }
    }

    public static class ActionEventDataExtensions
    {
        public static IOrderedQueryable<ActionEventData> Sort(this IQueryable<ActionEventData> source, string siteControlValue)
        {
            switch (siteControlValue)
            {
                case "ED":
                    return source.OrderBy(_ => _.EventDate).ThenBy(_ => _.Cycle).ThenBy(_ => _.DisplaySequence);
                case "DD":
                    return source.OrderBy(_ => _.EventDueDate).ThenBy(_ => _.Cycle).ThenBy(_ => _.DisplaySequence);
                case "NR":
                    return source.OrderBy(_ => _.NextPoliceDate).ThenBy(_ => _.Cycle).ThenBy(_ => _.DisplaySequence);
                case "IL":
                    return source.OrderBy(_ => _.ImportanceLevel ?? _.EventImportanceLevel).ThenBy(_ => _.Cycle).ThenBy(_ => _.DisplaySequence);
                case "CD":
                    return source.OrderBy(_ => _.Cycle).ThenBy(_ => _.EventDate ?? _.EventDueDate).ThenBy(_ => _.Cycle);
                default:
                    return source.OrderBy(_ => _.DisplaySequence).ThenBy(_ => _.Cycle);
            }
        }

    }
}