using System;
using System.Collections.Generic;
using System.Linq;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Rules;

namespace Inprotech.Web.BatchEventUpdate.Models
{
    public class OpenActionModel
    {
        public OpenActionModel(
            OpenAction openAction,
            ValidAction validAction,
            Case @case,
            IEnumerable<DataEntryTask> restrictedEntryList,
            IEnumerable<int> cyclicalEvents, 
            IEnumerable<short> openCycles)
        {
            if(openAction == null) throw new ArgumentNullException("openAction");
            if(validAction == null) throw new ArgumentNullException("validAction");
            if(@case == null) throw new ArgumentNullException("case");
            if(restrictedEntryList == null) throw new ArgumentNullException("restrictedEntryList");
            if(cyclicalEvents == null) throw new ArgumentNullException("cyclicalEvents");

            Id = validAction.ActionId;
            Name = validAction.ActionName;
            Action = new ValidActionModel(validAction.ActionId, validAction.ActionName);
            Cycle = openAction.Cycle;
            Status = openAction.Status;
            IsOpen = openAction.IsOpen;
            CriteriaId = openAction.Criteria.Id;
            IsCyclic = validAction.Action.IsCyclic;
            OpenCycles = openCycles;

            if(openAction.Criteria != null)
            {
                DataEntryTasks = openAction.Criteria.DataEntryTasks
                                           .Where(restrictedEntryList.Contains)
                                           .OrderBy(det => det.DisplaySequence)
                                           .Select(dc => new DataEntryTaskModel(dc, Cycle, @case, cyclicalEvents));
            }
        }

        public short Cycle { get; private set; }

        public int CriteriaId { get; private set; }

        public string Status { get; set; }

        public bool IsOpen { get; set; }

        public ValidActionModel Action { get; private set; }

        public string Name { get; set; }

        public string Id { get; set; }

        public IEnumerable<DataEntryTaskModel> DataEntryTasks { get; private set; }

        public bool IsCyclic { get; set; }

        public IEnumerable<short> OpenCycles { get; set; }
    }
}