using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Web.BatchEventUpdate.Models;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Components.Cases.DataEntryTasks.Validation;
using InprotechKaizen.Model.Components.Configuration.Extensions;
using InprotechKaizen.Model.Configuration;
using InprotechKaizen.Model.Configuration.SiteControl;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Rules;

namespace Inprotech.Web.BatchEventUpdate
{
    public interface IBatchEventsModelBuilder
    {
        Task<BatchEventsModel> Build(Case[] cases, DataEntryTask dataEntryTask, bool useNextCycle, short? actionCycle = null);
    }

    public class BatchEventsModelBuilder : IBatchEventsModelBuilder
    {
        readonly IBatchDataEntryTaskPrerequisiteCheck _batchDataEntryTaskPrerequisiteCheck;
        readonly IDbContext _dbContext;
        readonly IUpdatableCaseModelBuilder _updatableCaseModelBuilder;

        public BatchEventsModelBuilder(
            IDbContext dbContext,
            IBatchDataEntryTaskPrerequisiteCheck batchDataEntryTaskPrerequisiteCheck,
            IUpdatableCaseModelBuilder updatableCaseModelBuilder)
        {
            _dbContext = dbContext;
            _batchDataEntryTaskPrerequisiteCheck = batchDataEntryTaskPrerequisiteCheck;
            _updatableCaseModelBuilder = updatableCaseModelBuilder;
        }

        public async Task<BatchEventsModel> Build(Case[] cases, DataEntryTask dataEntryTask, bool useNextCycle, short? actionCycle = null)
        {
            var fileLocations = _dbContext.Set<TableCode>()
                                          .Where(tc => tc.TableTypeId == (short)TableTypes.FileLocation)
                                          .ToArray();

            var sortedCases = await SortOutCases(useNextCycle, cases, dataEntryTask, actionCycle);
            var updatableCases = sortedCases.Item1.ToArray();
            var nonUpdatableCases = sortedCases.Item2.ToArray();

            var isConfirmationRequired =
                updatableCases.Any(vc => dataEntryTask.ShouldConfirmStatusChangeOnSave(cases.First(c => c.Id == vc.Id)));
            var hasConfirmationPassword = false;
            var newStatus = string.Empty;

            if (isConfirmationRequired)
            {
                hasConfirmationPassword = _dbContext.Set<SiteControl>().RequiresPasswordOnConfirmation();
                newStatus = dataEntryTask.CaseStatus.Name;
            }

            return new BatchEventsModel(
                updatableCases,
                nonUpdatableCases,
                isConfirmationRequired,
                hasConfirmationPassword)
            {
                NewStatus = newStatus,
                FileLocations = fileLocations.Select(f => new FileLocationModel(f))
            };
        }

        async Task<Tuple<IEnumerable<UpdatableCaseModel>, IEnumerable<NonUpdatableCaseModel>>> SortOutCases(
            bool useNextCycle,
            IEnumerable<Case> cases,
            DataEntryTask dataEntryTask,
            short? actionCycle)
        {
            var nonUpdatableCases = new List<NonUpdatableCaseModel>();
            var updatableCases = new List<UpdatableCaseModel>();

            foreach (var c in cases)
            {
                var checkResult = await _batchDataEntryTaskPrerequisiteCheck.Run(c, dataEntryTask, actionCycle);

                if (checkResult.HasErrors)
                {
                    if (!checkResult.CaseAccessSelectSecurityFailed)
                    {
                        var nonUpdatableCase = CreateNonUpdatableCase(c, dataEntryTask, checkResult);
                        nonUpdatableCases.Add(nonUpdatableCase);
                    }
                }
                else
                {
                    updatableCases.Add(
                                       _updatableCaseModelBuilder.BuildForDynamicCycle(
                                                                                       c,
                                                                                       dataEntryTask,
                                                                                       checkResult,
                                                                                       useNextCycle, actionCycle));
                }
            }

            return new Tuple<IEnumerable<UpdatableCaseModel>, IEnumerable<NonUpdatableCaseModel>>(
                updatableCases,
                nonUpdatableCases);
        }

        static NonUpdatableCaseModel CreateNonUpdatableCase(
            Case @case,
            DataEntryTask dataEntryTask,
            BatchDataEntryTaskPrerequisiteCheckResult checkResult)
        {
            var severeRestrictions = new[]
                                     {
                                         KnownDebtorRestrictions.DisplayError,
                                         KnownDebtorRestrictions.DisplayWarningWithPasswordConfirmation
                                     };

            return new NonUpdatableCaseModel(@case, dataEntryTask)
            {
                HasAccessRestriction = checkResult.CaseAccessSecurityFailed,
                HasNoMatchingActionCriteria = checkResult.DataEntryTaskIsUnavailable,
                CaseNameRestrictions =
                    checkResult.CaseNameRestrictions.Select(
                                                            cnr =>
                                                            new CaseNameRestrictionModel(
                                                                cnr.CaseName,
                                                                severeRestrictions,
                                                                false)).ToArray(),
                HasMultipleOpenActionCycles = checkResult.HasMultipleOpenActionCycles,
                HasNoRecordsForSelectedCycle = checkResult.NoRecordsForSelectedCycle
            };
        }
    }
}