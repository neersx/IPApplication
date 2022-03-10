using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Dependable;
using Inprotech.Integration;
using Inprotech.Integration.Jobs;
using Inprotech.Integration.Persistence;
using Inprotech.Integration.Schedules;
using Newtonsoft.Json.Linq;

namespace Inprotech.IntegrationServer.PtoAccess.CleanUp
{
    public class ProcessIdDetails
    {
        const string ProcessIdKey = "ProcessId";

        public ProcessIdDetails(int scheduleId, string settingsString)
        {
            if (string.IsNullOrWhiteSpace(settingsString))
                return;

            var settings = JObject.Parse(settingsString);
            if (!settings.ContainsKey(ProcessIdKey))
                return;

            ProcessId = (long) settings[ProcessIdKey];
            ScheduleId = scheduleId;
        }

        public int ScheduleId { get; set; }

        public long ProcessId { get; set; }
    }

    public class IdentifyProcessIdsToCleanup : IPerformBackgroundJob
    {
        readonly IRepository _repository;
        readonly Func<DateTime> _now;

        public IdentifyProcessIdsToCleanup(IRepository repository, Func<DateTime> now)
        {
            _repository = repository;
            _now = now;
        }

        public string Type => "IdentifyProcessIdsToCleanup";

        public SingleActivity GetJob(long jobExecutionId, JObject jobArguments)
        {
            return Activity.Run<IdentifyProcessIdsToCleanup>(fc => fc.MarkProcessIdsToCleanup());
        }

        public IEnumerable<ProcessIdDetails> GetEligibleProcessIdDetails()
        {
            var before6Months = _now().Date.AddMonths(-6);

            var schedules = _repository.Set<Schedule>()
                                       .Where(_ => _.DataSourceType == DataSourceType.UsptoPrivatePair);

            var scheduleExecutions = _repository.Set<ScheduleExecution>()
                                                .Where(_ => _.IsTidiedUp && _.Finished < before6Months);

            var processIdsToClean = _repository.Set<ProcessIdsToCleanup>();

            var processIdDetails = (from s in schedules
                                    join se in scheduleExecutions on s.Id equals se.ScheduleId
                                    join pi in processIdsToClean on s.Id equals pi.ScheduleId into piRecord
                                    from piDetail in piRecord.DefaultIfEmpty(null)
                                    where piDetail == null
                                    select new {ScheduleId = s.Id, Settings = s.ExtendedSettings})
                                   .ToList()
                                   .Select(_ => new ProcessIdDetails(_.ScheduleId, _.Settings))
                                   .ToList();

            return processIdDetails;
        }

        public Task MarkProcessIdsToCleanup()
        {
            var eligibleProcessIds = GetEligibleProcessIdDetails().ToList();
            if (!eligibleProcessIds.Any())
                return Task.FromResult(0);

            foreach (var processDetail in eligibleProcessIds)
            {
                var data = new ProcessIdsToCleanup(processDetail.ScheduleId, processDetail.ProcessId, _now());
                _repository.Set<ProcessIdsToCleanup>().Add(data);
            }

            _repository.SaveChanges();

            return Task.FromResult(0);
        }
    }
}