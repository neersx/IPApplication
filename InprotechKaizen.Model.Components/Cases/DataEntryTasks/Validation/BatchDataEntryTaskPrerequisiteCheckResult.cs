namespace InprotechKaizen.Model.Components.Cases.DataEntryTasks.Validation
{
    public class BatchDataEntryTaskPrerequisiteCheckResult : DataEntryTaskPrerequisiteCheckResult
    {
        public BatchDataEntryTaskPrerequisiteCheckResult(
            DataEntryTaskPrerequisiteCheckResult dataEntryTaskPrerequisiteCheckResult = null,
            bool hasMultipleOpenActionCycles = false, bool noRecordsForSelectedCycle = false) : base(dataEntryTaskPrerequisiteCheckResult)
        {
            HasMultipleOpenActionCycles = hasMultipleOpenActionCycles;
            NoRecordsForSelectedCycle = noRecordsForSelectedCycle;
        }

        public bool HasMultipleOpenActionCycles { get; private set; }

        public bool NoRecordsForSelectedCycle { get; }

        public override bool HasErrors => base.HasErrors || HasMultipleOpenActionCycles || NoRecordsForSelectedCycle;
    }
}