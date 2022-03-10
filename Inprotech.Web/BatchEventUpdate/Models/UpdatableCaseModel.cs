using System;
using System.Collections.Generic;
using InprotechKaizen.Model.Cases;

namespace Inprotech.Web.BatchEventUpdate.Models
{
    public class UpdatableCaseModel
    {
        public UpdatableCaseModel()
        {
        }

        public UpdatableCaseModel(Case @case, short controllingCycle = 1)
        {
            if(@case == null) throw new ArgumentNullException("case");

            Id = @case.Id;
            CaseReference = @case.Irn;
            Title = @case.Title;
            CurrentOfficialNumber = @case.CurrentOfficialNumber;
            CaseStatusDescription = @case.CaseStatus != null ? @case.CaseStatus.Name : null;
            ControllingCycle = controllingCycle;
        }

        public int Id { get; set; }
        public string CaseReference { get; set; }

        public string CurrentOfficialNumber { get; set; }
        public string OfficialNumber { get; set; }
        public string OfficialNumberDescription { get; set; }

        public string Title { get; set; }
        public int? FileLocationId { get; set; }

        public string CaseStatusDescription { get; set; }

        public short ControllingCycle { get; set; }

        public IEnumerable<CaseNameRestrictionModel> WarnOnlyRestrictions { get; set; }

        public IEnumerable<AvailableEventModel> AvailableEvents { get; set; }
    }
}