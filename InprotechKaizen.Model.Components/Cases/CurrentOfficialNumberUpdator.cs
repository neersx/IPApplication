using System;
using System.Linq;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Components.Cases.Extensions;
using InprotechKaizen.Model.Persistence;

namespace InprotechKaizen.Model.Components.Cases
{
    public interface ICurrentOfficialNumberUpdater
    {
        void Update(Case @case);
    }

    public class CurrentOfficialNumberUpdater : ICurrentOfficialNumberUpdater
    {
        readonly IChangeTracker _changeTracker;

        public CurrentOfficialNumberUpdater(IChangeTracker changeTracker)
        {
            if(changeTracker == null) throw new ArgumentNullException("changeTracker");
            _changeTracker = changeTracker;
        }

        public void Update(Case @case)
        {
            if(@case == null) throw new ArgumentNullException("case");

            if(!@case.OfficialNumbers.Any(o => _changeTracker.HasChanged(o))) return;

            var officialNumber = @case.CurrentNumbersIssuedByIpOffices()
                                      .OrderBy(o => o.NumberType.DisplayPriority)
                                      .ThenByDescending(o => o.DateEntered)
                                      .FirstOrDefault();

            @case.CurrentOfficialNumber = officialNumber == null ? null : officialNumber.Number;
        }
    }
}