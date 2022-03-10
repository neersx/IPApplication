using System;
using System.Collections.Generic;
using System.Diagnostics.CodeAnalysis;
using System.Linq;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Components.Policing;
using InprotechKaizen.Model.Persistence;
using OfficialNumber = InprotechKaizen.Model.Cases.OfficialNumber;
using ValueExt = InprotechKaizen.Model.Components.Cases.Comparison.Results.ValueExt;

namespace InprotechKaizen.Model.Components.Cases.Comparison.Updaters
{
    public interface IOfficialNumberUpdater
    {
        [SuppressMessage("Microsoft.Naming", "CA1716:IdentifiersShouldNotMatchKeywords", MessageId = "case")]
        IEnumerable<PoliceCaseEvent> AddOrUpdateOfficialNumbers(Case @case, IEnumerable<Results.OfficialNumber> numbers);
    }

    public class OfficialNumberUpdater : IOfficialNumberUpdater
    {
        readonly IDbContext _dbContext;
        readonly ICurrentOfficialNumberUpdater _currentOfficialNumberUpdater;
        readonly IEventUpdater _eventUpdater;

        public OfficialNumberUpdater(IDbContext dbContext, ICurrentOfficialNumberUpdater currentOfficialNumberUpdater, IEventUpdater eventUpdater)
        {
            _dbContext = dbContext;
            _currentOfficialNumberUpdater = currentOfficialNumberUpdater;
            _eventUpdater = eventUpdater;
        }

        public IEnumerable<PoliceCaseEvent> AddOrUpdateOfficialNumbers(Case @case, IEnumerable<Results.OfficialNumber> numbers)
        {
            if (@case == null) throw new ArgumentNullException(nameof(@case));
            if (numbers == null) throw new ArgumentNullException(nameof(numbers));

            foreach (var n in numbers)
            {
                if ((n.Number == null || !n.Number.Updated) && (n.EventDate == null || !n.EventDate.Updated)) continue;

                var existing = @case.OfficialNumbers.SingleOrDefault(o => n.Id != null && o.NumberId == n.Id && o.IsCurrent == 1);
                if (existing != null)
                {
                    existing.Number = ValueExt.UpdatedOrDefault(n.Number, existing.Number);
                    existing.DateEntered = ValueExt.UpdatedOrDefault(n.EventDate, existing.DateEntered);
                }
                else
                {
                    var numberType = _dbContext.Set<NumberType>().Single(nt => nt.NumberTypeCode == n.MappedNumberTypeId);
                    var newOfficialNumber = new OfficialNumber(numberType, @case, n.Number.TheirValue);

                    newOfficialNumber.DateEntered = ValueExt.ApplyIfApplicable(n.EventDate);
                    newOfficialNumber.MarkAsCurrent();

                    @case.OfficialNumbers.Add(newOfficialNumber);
                }
                
                _currentOfficialNumberUpdater.Update(@case);

                if (n.EventNo != null && n.EventDate != null && n.EventDate.TheirValue != null)
                    yield return _eventUpdater.AddOrUpdateEvent(@case, n.EventNo.Value, n.EventDate.TheirValue.Value, n.Cycle);
            }
        }
    }
}
