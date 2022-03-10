using System.Linq;
using Inprotech.Integration.Persistence;
using Inprotech.Integration.Uspto.PrivatePair.Sponsorships;

namespace Inprotech.Integration.Schedules.Extensions.Uspto.PrivatePair
{
    public class PrivatePairSchedulePrerequisite : IDataSourceSchedulePrerequisites
    {
        readonly IRepository _repository;

        public PrivatePairSchedulePrerequisite(IRepository repository)
        {
            _repository = repository;
        }

        public bool Validate(out string unmetRequirement)
        {
            unmetRequirement = null;
            if (_repository.NoDeleteSet<Sponsorship>().Any(c => c.ServiceId != null && c.ServiceId.Trim() != string.Empty)) return true;
            
            unmetRequirement = "missing-uspto-sponsorship";
            return false;
        }
    }
}
