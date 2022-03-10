using System.Collections.Generic;
using System.Linq;
using InprotechKaizen.Model.Rules;

namespace Inprotech.Web.Configuration.Rules.Workflow.EntryControlMaintenance
{
    public interface IReorderableSection
    {
        void UpdateDisplayOrder(DataEntryTask entry, EntryControlRecordMovements movements);

        bool PropagateDisplayOrder(EntryReorderSouce source, DataEntryTask target, EntryControlRecordMovements movements);
    }

    public class EntryReorderSouce
    {
        public EntryReorderSouce()
        {
            EntryEvents = new List<EntryEventReorderSource>();
            Steps = new List<StepReorderSource>();
        }

        public int CriteriaId { get; set; }

        public short EntryId { get; set; }

        public string Description { get; set; }

        public IEnumerable<EntryEventReorderSource> EntryEvents { get; set; }

        public IEnumerable<StepReorderSource> Steps { get; set; }
    }

    public class EntryEventReorderSource
    {
        public int EventId { get; set; }

        public string Description { get; set; }

        public short DisplaySequence { get; set; }
    }

    public class StepReorderSource
    {
        public int Hash { get; set; }

        public short DisplaySequence { get; set; }
    }

    public static class ReorderSourceExt
    {
        public static IOrderedEnumerable<EntryEventReorderSource> EventsInDisplayOrder(this EntryReorderSouce source)
        {
            return source.EntryEvents.OrderBy(ae => ae.DisplaySequence);
        }

        public static IOrderedEnumerable<StepReorderSource> StepsInDisplayOrder(this EntryReorderSouce source)
        {
            return source.Steps.OrderBy(ae => ae.DisplaySequence);
        }
    }
}