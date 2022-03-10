using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Autofac.Features.Indexed;
using Inprotech.Infrastructure;
using Inprotech.Integration.DataSources;
using Inprotech.Integration.Persistence;
using InprotechKaizen.Model.Components.Security;
using Newtonsoft.Json.Linq;

namespace Inprotech.Integration.Schedules.Extensions
{
    public interface ICreateSchedule
    {
        Task<DataSourceScheduleResult> TryCreateFrom(JObject scheduleRequest);
    }

    public interface IDataSourceSchedule
    {
        Task<DataSourceScheduleResult> TryCreateFrom(JObject schedule);

        dynamic View(Schedule schedule);

        IEnumerable<dynamic> View(IQueryable<Schedule> schedules);
    }

    public enum Details
    {
        Normal,
        WithStatus
    }

    public class DataSourceSchedule : IDataSourceSchedule
    {
        public enum Recurrence
        {
            Recurring,
            RunOnce,
            Continuous
        }

        readonly IAvailableDataSources _availableDataSources;
        readonly IPopulateNextRun _populateNextRun;

        readonly IRepository _repository;
        readonly IIndex<DataSourceType, Func<ICreateSchedule>> _scheduleCreators;
        readonly ISecurityContext _securityContext;
        readonly Func<DateTime> _systemClock;
        readonly ISiteControlReader _siteControlReader;

        public DataSourceSchedule(IIndex<DataSourceType, Func<ICreateSchedule>> scheduleCreators,
                                  IRepository repository,
                                  IAvailableDataSources availableDataSources, IPopulateNextRun populateNextRun,
                                  ISecurityContext securityContext, Func<DateTime> systemClock, ISiteControlReader siteControlReader)
        {
            _scheduleCreators = scheduleCreators;
            _repository = repository;
            _availableDataSources = availableDataSources;
            _populateNextRun = populateNextRun;
            _securityContext = securityContext;
            _systemClock = systemClock;
            _siteControlReader = siteControlReader;
        }

        public async Task<DataSourceScheduleResult> TryCreateFrom(JObject scheduleData)
        {
            var scheduleRequest = scheduleData.ToObject<ScheduleRequest>();

            if (!ValidateNewSchedule(scheduleRequest, out var result)) return result;

            var dataSourceSchedule = _scheduleCreators[scheduleRequest.DataSource]();

            result = await dataSourceSchedule.TryCreateFrom(scheduleData);
            if (!result.IsValid)
            {
                return result;
            }

            result.Schedule.Name = scheduleRequest.Name;
            result.Schedule.DataSourceType = scheduleRequest.DataSource;
            result.Schedule.DownloadType = scheduleRequest.DownloadType;

            result.Schedule.CreatedOn = _systemClock();
            result.Schedule.CreatedBy = _securityContext.User.Id;
            if (scheduleRequest.Recurrence != Recurrence.RunOnce)
            {
                result.Schedule.StartTime = scheduleRequest.StartTime;
                result.Schedule.ExpiresAfter = scheduleRequest.ExpiresAfter;
                result.Schedule.RunOnDays = scheduleRequest.RunOnDays;
                if (scheduleRequest.Recurrence != Recurrence.Continuous)
                {
                    _populateNextRun.For(result.Schedule);
                }
                else
                {
                    result.Schedule.Type = ScheduleType.Continuous;
                }
            }
            else
            {
                result.Schedule.NextRun = scheduleRequest.RunNow
                    ? result.Schedule.CreatedOn
                    : scheduleRequest.RunOn + scheduleRequest.StartTime;

                result.Schedule.StartTime = result.Schedule.NextRun.GetValueOrDefault().TimeOfDay;
                result.Schedule.ExpiresAfter = result.Schedule.NextRun;
            }

            return result;
        }

        public IEnumerable<dynamic> View(IQueryable<Schedule> schedules)
        {
            var childSchedules = _repository.Set<Schedule>();
            var childExecutions = _repository.Set<ScheduleExecution>();

            return schedules
                   .Select(
                           main => new

                           {
                               Schedule = main,
                               BestStatus = (from e in main.Executions
                                                           .Union(from ce in childExecutions
                                                                  join s in childSchedules on main.Id equals s.ParentId into child
                                                                  from s in child.DefaultIfEmpty()
                                                                  where s != null && ce.ScheduleId == s.Id
                                                                  select ce)
                                             where e != null
                                             select new
                                             {
                                                 Text = e.Status.ToString(),
                                                 e.Finished,
                                                 Priority = e.Status == ScheduleExecutionStatus.Started ? 1 : e.Status == ScheduleExecutionStatus.Cancelling ? 2 : 3
                                             }).OrderByDescending(_ => _.Finished ?? DateTime.MaxValue)
                                               .ThenBy(_ => _.Priority)
                                               .FirstOrDefault()
                           })
                   .ToArray()
                   .Select(s => new ScheduleView
                   {
                       Id = s.Schedule.Id,
                       State = s.Schedule.State,
                       Type = (int) s.Schedule.Type,
                       Name = s.Schedule.Name,
                       RunOnDays = s.Schedule.RunOnDays,
                       DataSource = s.Schedule.DataSourceType.ToString(),
                       DownloadType = s.Schedule.DownloadType.ToString(),
                       StartTime = s.Schedule.StartTime,
                       NextRun = s.Schedule.NextRun,
                       ExpiresAfter = s.Schedule.ExpiresAfter,
                       Extension = s.Schedule.GetExtendedSettings(),
                       ExecutionStatus = GetStatus(s.BestStatus, s.Schedule.Type, s.Schedule.State)
                   });
        }

        public dynamic View(Schedule schedule)
        {
            return new ScheduleView
            {
                Id = schedule.Id,
                Name = schedule.Name,
                Type = (int) schedule.Type,
                RunOnDays = schedule.RunOnDays,
                DataSource = schedule.DataSourceType.ToString(),
                DownloadType = schedule.DownloadType.ToString(),
                StartTime = schedule.StartTime,
                NextRun = schedule.NextRun,
                ExpiresAfter = schedule.ExpiresAfter,
                State = schedule.State,
                Extension = schedule.GetExtendedSettings()
            };
        }

        bool ValidateNewSchedule(ScheduleRequest scheduleRequest, out DataSourceScheduleResult result)
        {
            result = new DataSourceScheduleResult();

            if (string.IsNullOrEmpty(scheduleRequest.Name))
            {
                result.ValidationResult = "invalid-schedule-name";
                return false;
            }

            if (scheduleRequest.Recurrence != Recurrence.RunOnce && string.IsNullOrEmpty(scheduleRequest.RunOnDays))
            {
                result.ValidationResult = "invalid-run-on-days";
                return false;
            }

            if (scheduleRequest.Recurrence == Recurrence.Continuous && scheduleRequest.DataSource != DataSourceType.UsptoPrivatePair)
            {
                result.ValidationResult = "invalid-continuous-not-private-pair";
                return false;
            }

            if (scheduleRequest.Recurrence == Recurrence.Continuous && _repository.Set<Schedule>().WithoutDeleted().Any(s => s.Type == ScheduleType.Continuous))
            {
                result.ValidationResult = "duplicate-continuous";
                return false;
            }

            if (_repository.Set<Schedule>().WithoutDeleted().Any(s => s.Name == scheduleRequest.Name))
            {
                result.ValidationResult = "duplicate-schedule-name";
                return false;
            }

            if (!_availableDataSources.List().Contains(scheduleRequest.DataSource))
            {
                result.ValidationResult = "unauthorised-schedule-datasource";
                return false;
            }
            
            if (string.IsNullOrWhiteSpace(_siteControlReader.Read<string>(SiteControls.BackgroundProcessLoginId)))
            {
                result.ValidationResult = "background-process-loginid";
                return false;
            }

            return true;
        }

        string GetStatus(dynamic bestStatus, ScheduleType type, ScheduleState state)
        {
            if (type == ScheduleType.Continuous && state == ScheduleState.Paused)
            {
                return ScheduleState.Paused.ToString();
            }

            if (state == ScheduleState.Disabled)
            {
                return ScheduleState.Disabled.ToString();
            }

            return bestStatus == null ? string.Empty : bestStatus.Text;
        }

        public class ScheduleView
        {
            public int Id { get; set; }

            public string Name { get; set; }

            public int Type { get; set; }

            public string RunOnDays { get; set; }

            public string DataSource { get; set; }

            public string DownloadType { get; set; }

            public TimeSpan StartTime { get; set; }

            public DateTime? NextRun { get; set; }

            public DateTime? ExpiresAfter { get; set; }

            public ScheduleState State { get; set; }

            public dynamic Extension { get; set; }

            public string ExecutionStatus { get; set; }
        }

        public class ScheduleRequest
        {
            public string Name { get; set; }

            public DataSourceType DataSource { get; set; }

            public DownloadType DownloadType { get; set; }

            public TimeSpan StartTime { get; set; }

            public string RunOnDays { get; set; }

            public DateTime? ExpiresAfter { get; set; }

            public Recurrence Recurrence { get; set; }

            public bool RunNow { get; set; }

            public DateTime? RunOn { get; set; }
        }
    }

    public class DataSourceScheduleResult
    {
        public bool IsValid => string.IsNullOrWhiteSpace(ValidationResult) || ValidationResult == "success";

        public Schedule Schedule { get; set; }

        public string ValidationResult { get; set; }
    }
}