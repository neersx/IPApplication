using System.Collections.Generic;
using System.Linq;
using Inprotech.Integration.Persistence;
using Inprotech.Integration.Schedules;
using Inprotech.Integration.Uspto.PrivatePair.Sponsorships;

namespace Inprotech.Integration.Innography.PrivatePair
{
    class UsptoSponsorshipScheduleMessages : IScheduleMessages
    {
        readonly IRepository _repository;

        public UsptoSponsorshipScheduleMessages(IRepository repository)
        {
            _repository = repository;
        }

        public ScheduleMessage Resolve(int scheduleId)
        {
            return Resolve(new[] { scheduleId }).FirstOrDefault();
        }

        public IEnumerable<ScheduleMessage> Resolve(IEnumerable<int> scheduleIds)
        {
            if (_repository.NoDeleteSet<Sponsorship>().Any(_ => _.Status == SponsorshipStatus.Error))
                return new[]
                {
                    new ScheduleMessage("sponsorshipError", "sponsorshipLink", "#/integration/ptoaccess/uspto-private-pair-sponsorships")
                };
            return Enumerable.Empty<ScheduleMessage>();
        }
    }
}