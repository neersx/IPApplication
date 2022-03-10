using System;
using InprotechKaizen.Model.Components.Cases.DataEntryTasks;
using InprotechKaizen.Model.Components.Cases.DataEntryTasks.Validation;

namespace Inprotech.Web.BatchEventUpdate
{
    public class SingleCaseUpdateResult
    {
        public SingleCaseUpdateResult(
            DataEntryTaskCompletionResult dataEntryTaskCompletionResult,
            DataEntryTaskPrerequisiteCheckResult dataEntryTaskPrerequisiteCheckResult,
            int? batchNumberForImmediatePolicing = null)
        {
            if(dataEntryTaskCompletionResult == null) throw new ArgumentNullException("dataEntryTaskCompletionResult");

            DataEntryTaskCompletionResult = dataEntryTaskCompletionResult;
            BatchNumberForImmediatePolicing = batchNumberForImmediatePolicing;
            DataEntryTaskPrerequisiteCheckResult = dataEntryTaskPrerequisiteCheckResult;
        }

        public DataEntryTaskCompletionResult DataEntryTaskCompletionResult { get; private set; }
        public int? BatchNumberForImmediatePolicing { get; private set; }
        public DataEntryTaskPrerequisiteCheckResult DataEntryTaskPrerequisiteCheckResult { get; set; }
    }
}