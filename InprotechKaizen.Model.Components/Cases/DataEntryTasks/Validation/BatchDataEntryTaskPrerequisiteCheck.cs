using System;
using System.Diagnostics.CodeAnalysis;
using System.Linq;
using System.Threading.Tasks;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Components.Cases.Extensions;
using InprotechKaizen.Model.Rules;

namespace InprotechKaizen.Model.Components.Cases.DataEntryTasks.Validation
{
    public interface IBatchDataEntryTaskPrerequisiteCheck
    {
        [SuppressMessage("Microsoft.Naming", "CA1716:IdentifiersShouldNotMatchKeywords", MessageId = "case")]
        Task<BatchDataEntryTaskPrerequisiteCheckResult> Run(Case @case, DataEntryTask dataEntryTask, short? actionCycle = null);
    }

    public class BatchDataEntryTaskPrerequisiteCheck : IBatchDataEntryTaskPrerequisiteCheck
    {
        readonly IDataEntryTaskPrerequisiteCheck _dataEntryTaskPrerequisiteCheck;

        public BatchDataEntryTaskPrerequisiteCheck(IDataEntryTaskPrerequisiteCheck dataEntryTaskPrerequisiteCheck)
        {
            _dataEntryTaskPrerequisiteCheck = dataEntryTaskPrerequisiteCheck;
        }

        public async Task<BatchDataEntryTaskPrerequisiteCheckResult> Run(Case @case, DataEntryTask dataEntryTask, short? actionCycle = null)
        {
            if(@case == null) throw new ArgumentNullException(nameof(@case));
            if(dataEntryTask == null) throw new ArgumentNullException(nameof(dataEntryTask));

            var dataEntryTaskPrerequisiteCheckResult = await _dataEntryTaskPrerequisiteCheck.Run(@case, dataEntryTask);

            var openActions = @case.OpenActions.ByCriteria(dataEntryTask.CriteriaId).ToArray();

            var hasMultipleOpenActionCycles = actionCycle == null && !dataEntryTaskPrerequisiteCheckResult.DataEntryTaskIsUnavailable && openActions.Count(oa => oa.IsOpen) > 1;

            var noRecordsForSelectedCycle = actionCycle != null && !dataEntryTaskPrerequisiteCheckResult.DataEntryTaskIsUnavailable && !openActions.Any(oa => oa.IsOpen && oa.Cycle == actionCycle);
            
            return new BatchDataEntryTaskPrerequisiteCheckResult(
                dataEntryTaskPrerequisiteCheckResult,
                hasMultipleOpenActionCycles, noRecordsForSelectedCycle);
        }
    }
}