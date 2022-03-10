using System;
using System.Data.Entity;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Infrastructure.Hosting;
using Inprotech.Integration.Persistence;
using Inprotech.Integration.Schedules;
using Inprotech.Integration.Schedules.Extensions;
using Inprotech.Integration.Uspto.PrivatePair.Sponsorships;

namespace Inprotech.Integration.Innography.PrivatePair
{
    public interface IInnographyPrivatePairSettingsValidator
    {
        Task<(bool isValid, bool alreadyInProgress, Schedule parentSchedule)> HasValidSchedule();
    }

    class InnographyPrivatePairSettingsValidator : IInnographyPrivatePairSettingsValidator
    {
        readonly IInnographyPrivatePairSettings _innographyPrivatePairSettings;
        readonly ISponsorshipProcessor _sponsorshipProcessor;
        readonly Func<HostInfo> _hostInfoResolver;
        readonly IRepository _repository;

        public InnographyPrivatePairSettingsValidator(IInnographyPrivatePairSettings innographyPrivatePairSettings, ISponsorshipProcessor sponsorshipProcessor, Func<HostInfo> hostInfoResolver,
                                                      IRepository repository)
        {
            _innographyPrivatePairSettings = innographyPrivatePairSettings;
            _sponsorshipProcessor = sponsorshipProcessor;
            _hostInfoResolver = hostInfoResolver;
            _repository = repository;
        }

        async Task<(bool envInvalid, SponsorshipModel[] sponsorships)> EnvironmentAndSponsorships()
        {
            var settings = _innographyPrivatePairSettings.Resolve();
            var sponsorships = (await _sponsorshipProcessor.GetSponsorships()).ToArray();
            var dbIdentifier = _hostInfoResolver().DbIdentifier;
            var envInvalid = sponsorships.Any() && !string.Equals(settings.ValidEnvironment, dbIdentifier, StringComparison.CurrentCultureIgnoreCase);

            return (envInvalid, sponsorships);
        }

        public async Task<(bool isValid, bool alreadyInProgress, Schedule parentSchedule)> HasValidSchedule()
        {
            var alreadyInProgress = false;
            var (envInvalid, sponsorships) = await EnvironmentAndSponsorships();
            var parentSchedule = await _repository.Set<Schedule>()
                                                .WhereVisibleToUsers()
                                                .Where(_ => _.ParentId == null && _.Type == ScheduleType.Continuous && _.State != ScheduleState.Paused)
                                                .SchedulesFor(DataSourceType.UsptoPrivatePair)
                                                .FirstOrDefaultAsync();
            var isValid = !envInvalid && sponsorships.Any() && parentSchedule != null;
            if (isValid)
            {
                alreadyInProgress = await _repository.Set<ScheduleExecution>().AnyAsync(_ => _.Status == ScheduleExecutionStatus.Started && _.Schedule.ParentId == parentSchedule.Id);
            }
            return (isValid, alreadyInProgress, parentSchedule);
        }
    }
}