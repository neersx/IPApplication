using System;
using System.Linq;
using System.Threading.Tasks;
using System.Transactions;
using Inprotech.Web.BatchEventUpdate.Models;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Components.Cases.DataEntryTasks;
using InprotechKaizen.Model.Components.Cases.DataEntryTasks.Policing;
using InprotechKaizen.Model.Components.Cases.DataEntryTasks.Validation;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Rules;

namespace Inprotech.Web.BatchEventUpdate
{
    public interface ISingleCaseUpdate
    {
        Task<SingleCaseUpdateResult> Update(
            CaseDataEntryTaskModel updatedCase,
            Case nonTrackedCase,
            DataEntryTask nonTrackedDataEntryTask, short? actionCycle = null);
    }

    public class SingleCaseUpdate : ISingleCaseUpdate
    {
        readonly IBatchDataEntryTaskPrerequisiteCheck _batchDataEntryTaskPrerequisiteCheck;
        readonly IDataEntryTaskDispatcher _dataEntryTaskDispatcher;
        readonly IDbContext _dbContext;
        readonly IDataEntryTaskHandlerInputFormatter _inputFormatter;
        readonly IPolicingRequestProcessor _policingRequestProcessor;

        public SingleCaseUpdate(
            IDbContext dbContext,
            IDataEntryTaskDispatcher dataEntryTaskDispatcher,
            IDataEntryTaskHandlerInputFormatter inputFormatter,
            IPolicingRequestProcessor policingRequestProcessor,
            IBatchDataEntryTaskPrerequisiteCheck batchDataEntryTaskPrerequisiteCheck)
        {
            _dbContext = dbContext;
            _dataEntryTaskDispatcher = dataEntryTaskDispatcher;
            _inputFormatter = inputFormatter;
            _policingRequestProcessor = policingRequestProcessor;
            _batchDataEntryTaskPrerequisiteCheck = batchDataEntryTaskPrerequisiteCheck;
        }

        public async Task<SingleCaseUpdateResult> Update(
            CaseDataEntryTaskModel updatedCase,
            Case nonTrackedCase,
            DataEntryTask nonTrackedDataEntryTask,
            short? actionCycle = null)
        {
            if(updatedCase == null) throw new ArgumentNullException(nameof(updatedCase));
            if(nonTrackedCase == null) throw new ArgumentNullException(nameof(nonTrackedCase));
            if(nonTrackedDataEntryTask == null) throw new ArgumentNullException(nameof(nonTrackedDataEntryTask));

            var @case = _dbContext.Set<Case>().Attach(nonTrackedCase);
            var dataEntryTask = _dbContext.Set<DataEntryTask>().Attach(nonTrackedDataEntryTask);

            var checkResult = await _batchDataEntryTaskPrerequisiteCheck.Run(@case, dataEntryTask, actionCycle);

            if(checkResult.HasErrors)
            {
                return new SingleCaseUpdateResult(
                    new DataEntryTaskCompletionResult(
                        new ValidationResult(
                            "Case data has changed. Some cases are no longer updatable. Please refresh the list to show only updatable cases.")),
                    checkResult);
            }

            using(var tcs = _dbContext.BeginTransaction(asyncFlowOption: TransactionScopeAsyncFlowOption.Enabled))
            {
                var input = _inputFormatter.Format(updatedCase.Data);

                var dispatchResult = _dataEntryTaskDispatcher.ApplyChanges(
                                                                           new DataEntryTaskInput(
                                                                               @case,
                                                                               dataEntryTask,
                                                                               updatedCase.ConfirmationPassword,
                                                                               input,
                                                                               updatedCase.AreWarningsConfirmed,
                                                                               updatedCase.SanityCheckResultIds));

                if(!dispatchResult.IsCompleted)
                    return new SingleCaseUpdateResult(dispatchResult, checkResult);

                var batchNumberForImmediatePolicing = _policingRequestProcessor
                    .Process(
                             dataEntryTask,
                             dispatchResult.HandlerResults
                                           .Select(r => r.Output.PolicingRequests)
                                           .ToArray());

                tcs.Complete();

                return new SingleCaseUpdateResult(dispatchResult, checkResult, batchNumberForImmediatePolicing);
            }
        }
    }
}