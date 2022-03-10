using System;
using System.Collections.Generic;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Components.Cases.Extensions;
using InprotechKaizen.Model.Rules;

namespace Inprotech.Web.BatchEventUpdate.Models
{
    public class NonUpdatableCaseModel
    {
        public NonUpdatableCaseModel(Case @case, DataEntryTask dataEntryTask)
        {
            if(@case == null) throw new ArgumentNullException("case");
            if(dataEntryTask == null) throw new ArgumentNullException("dataEntryTask");

            Id = @case.Id;
            CaseReference = @case.Irn;
            Title = @case.Title;
            CurrentOfficialNumber = @case.CurrentOfficialNumber;
            SetOfficialNumber(@case, dataEntryTask);
            CaseNameRestrictions = new CaseNameRestrictionModel[0];
        }

        public int Id { get; set; }
        public string CaseReference { get; set; }
        public string CurrentOfficialNumber { get; set; }
        public string OfficialNumber { get; set; }
        public string OfficialNumberDescription { get; set; }
        public string Title { get; set; }
        public bool HasNoMatchingActionCriteria { get; set; }
        public bool HasAccessRestriction { get; set; }
        public bool HasMultipleOpenActionCycles { get; set; }
        public bool HasNoRecordsForSelectedCycle { get; set; }
        public IEnumerable<CaseNameRestrictionModel> CaseNameRestrictions { get; set; }

        void SetOfficialNumber(Case @case, DataEntryTask dataEntryTask)
        {
            if(dataEntryTask.OfficialNumberType == null) return;

            OfficialNumberDescription = dataEntryTask.OfficialNumberType.Name;

            var officialNumber = @case.CurrentOfficialNumberFor(dataEntryTask);

            if(officialNumber != null)
                OfficialNumber = officialNumber.Number;
        }
    }
}