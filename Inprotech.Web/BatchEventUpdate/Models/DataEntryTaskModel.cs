using System;
using System.Collections.Generic;
using System.Linq;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Rules;

namespace Inprotech.Web.BatchEventUpdate.Models
{
    public class DataEntryTaskModel
    {
        public DataEntryTaskModel(
            DataEntryTask dataEntryTask,
            short actionCycle,
            Case @case,
            IEnumerable<int> cyclicalEvents)
        {
            if(dataEntryTask == null) throw new ArgumentNullException("dataEntryTask");
            if(@case == null) throw new ArgumentNullException("case");
            if(cyclicalEvents == null) throw new ArgumentNullException("cyclicalEvents");

            Id = dataEntryTask.Id;
            Description = dataEntryTask.Description;
            DisplaySequence = dataEntryTask.DisplaySequence;
            UserInstruction = dataEntryTask.UserInstruction;

            CaseEvent dimEvent = null;

            if(dataEntryTask.DimEventNo.HasValue)
            {
                dimEvent = @case.CaseEvents.FirstOrDefault(
                                                           ce => ce.EventNo == dataEntryTask.DimEventNo &&
                                                                 ce.EventDate.HasValue &&
                                                                 ce.HasOccurred() &&
                                                                 ce.Cycle ==
                                                                 (cyclicalEvents.Contains(ce.EventNo) ? actionCycle : 1));
                IsDimmed = dimEvent != null;
            }

            if(dataEntryTask.HideEventNo.HasValue)
            {
                /* hide when HIDEEVENTNO has occurred and the DIMEVENTNO has not occurred */
                IsHidden = @case.CaseEvents.Any(
                                                ce => ce.EventNo == dataEntryTask.HideEventNo &&
                                                      ce.EventDate.HasValue &&
                                                      ce.HasOccurred() &&
                                                      ce.Cycle ==
                                                      (cyclicalEvents.Contains(ce.EventNo) ? actionCycle : 1)) &&
                           dimEvent == null;
            }

            if(!IsHidden)
            {
                /* display event only when DISPLAYEVENTNO has occurred */
                IsHidden = !(!dataEntryTask.DisplayEventNo.HasValue || @case.CaseEvents.Any(
                                                                                            ce =>
                                                                                            ce.EventNo ==
                                                                                            dataEntryTask.DisplayEventNo &&
                                                                                            ce.EventDate.HasValue &&
                                                                                            ce.HasOccurred() &&
                                                                                            ce.Cycle ==
                                                                                            (cyclicalEvents.Contains(ce.EventNo)
                                                                                                 ? actionCycle
                                                                                                 : 1)));
            }

            InitializeAssociatedEvent(dataEntryTask);

            CanUpdateAsToday = dataEntryTask.AvailableEvents.All(e => e.CanUpdateAsToday);

            ShouldConfirmOnSave = dataEntryTask.ShouldConfirmStatusChangeOnSave(@case);

            FileLocationId = dataEntryTask.FileLocationId;
        }

        public short Id { get; set; }

        public string Description { get; set; }

        public short DisplaySequence { get; set; }

        public bool IsDimmed { get; set; }

        public bool IsHidden { get; set; }

        public string OfficialNumberTypeDescription { get; set; }

        public string OfficialNumber { get; set; }

        public IEnumerable<string> AvailableEventNames { get; set; }

        public bool CanUpdateAsToday { get; set; }

        public bool ShouldConfirmOnSave { get; set; }

        public string UserInstruction { get; set; }

        public int? FileLocationId { get; set; }

        void InitializeAssociatedEvent(DataEntryTask dataEntryTask)
        {
            var validEventsMap = dataEntryTask.Criteria.ValidEvents.ToDictionary(ec => ec.EventId, ec => ec);

            AvailableEventNames = dataEntryTask.AvailableEvents
                                               .OrderBy(dd => dd.DisplaySequence)
                                               .Select(
                                                       dd =>
                                                       validEventsMap.ContainsKey(dd.Event.Id)
                                                           ? validEventsMap[dd.Event.Id].Description
                                                           : dd.Event.Description)
                                               .ToArray();
        }
    }
}