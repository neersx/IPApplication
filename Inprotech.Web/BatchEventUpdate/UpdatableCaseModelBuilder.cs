using System;
using System.Linq;
using Inprotech.Web.BatchEventUpdate.Models;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Components.Cases;
using InprotechKaizen.Model.Components.Cases.DataEntryTasks;
using InprotechKaizen.Model.Components.Cases.DataEntryTasks.Extensions;
using InprotechKaizen.Model.Components.Cases.DataEntryTasks.Validation;
using InprotechKaizen.Model.Components.Cases.Extensions;
using InprotechKaizen.Model.Rules;

namespace Inprotech.Web.BatchEventUpdate
{
    public interface IUpdatableCaseModelBuilder
    {
        UpdatableCaseModel BuildForDynamicCycle(
            Case @case,
            DataEntryTask dataEntryTask,
            DataEntryTaskPrerequisiteCheckResult checkResult,
            bool useNextCycle, short? actionCycle = null);
    }

    public class UpdatableCaseModelBuilder : IUpdatableCaseModelBuilder
    {
        readonly ICycleSelection _cycleSelection;
        readonly IPrepareAvailableEvents _prepareAvailableEvents;
        readonly IWarnOnlyRestrictionsBuilder _warnOnlyRestrictionsBuilder;

        public UpdatableCaseModelBuilder(
            ICycleSelection cycleSelection,
            IPrepareAvailableEvents prepareAvailableEvents,
            IWarnOnlyRestrictionsBuilder warnOnlyRestrictionsBuilder)
        {
            if(cycleSelection == null) throw new ArgumentNullException("cycleSelection");
            if(prepareAvailableEvents == null) throw new ArgumentNullException("prepareAvailableEvents");
            if(warnOnlyRestrictionsBuilder == null) throw new ArgumentNullException("warnOnlyRestrictionsBuilder");

            _cycleSelection = cycleSelection;
            _prepareAvailableEvents = prepareAvailableEvents;
            _warnOnlyRestrictionsBuilder = warnOnlyRestrictionsBuilder;
        }

        public UpdatableCaseModel BuildForDynamicCycle(
            Case @case,
            DataEntryTask dataEntryTask,
            DataEntryTaskPrerequisiteCheckResult checkResult,
            bool useNextCycle,
            short? actionCycle = null)
        {
            if(@case == null) throw new ArgumentNullException("case");
            if(dataEntryTask == null) throw new ArgumentNullException("dataEntryTask");
            if(checkResult == null) throw new ArgumentNullException("checkResult");

            short controllingCycle = 1;
            if (dataEntryTask.Criteria.Action.IsCyclic)
            {
                if (actionCycle != null)
                {
                    controllingCycle = actionCycle.Value;
                   
                }
                else
                {
                    controllingCycle = @case.OpenActions
                                            .Where(
                                                   oa =>
                                                       oa.Criteria != null && oa.Criteria.Id == dataEntryTask.CriteriaId && oa.IsOpen)
                                            .Min(oa => oa.Cycle);
                }
            }
            else
            {
                var @event = dataEntryTask.EventForCycleConsideration();
                if (_cycleSelection.IsCyclicalFor(@event, dataEntryTask))
                {
                    controllingCycle = _cycleSelection.DeriveControllingCycle(@case, dataEntryTask, @event, useNextCycle);
                }    
            }
            
            var currentOfficialNumber = @case.CurrentOfficialNumberFor(dataEntryTask);

            return new UpdatableCaseModel(@case, controllingCycle)
                   {
                       FileLocationId = GetFileLocation(@case),
                       OfficialNumberDescription =
                           dataEntryTask.OfficialNumberType?.Name,
                       OfficialNumber = currentOfficialNumber?.Number,
                       AvailableEvents = _prepareAvailableEvents.For(@case, dataEntryTask, controllingCycle),
                       WarnOnlyRestrictions = _warnOnlyRestrictionsBuilder.Build(@case, checkResult)
                   };
        }

        static int? GetFileLocation(Case @case)
        {
            return @case.MostRecentCaseLocation()?.FileLocationId;
        }
    }
}