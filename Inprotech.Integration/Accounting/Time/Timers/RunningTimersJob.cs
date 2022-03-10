using System;
using System.Data.Entity;
using System.Linq;
using System.Threading.Tasks;
using AutoMapper;
using Dependable;
using Inprotech.Infrastructure.Messaging;
using Inprotech.Infrastructure.Notifications;
using Inprotech.Integration.Jobs;
using InprotechKaizen.Model.Accounting;
using InprotechKaizen.Model.BackgroundProcess;
using InprotechKaizen.Model.Components.Accounting.Time;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Profiles;
using InprotechKaizen.Model.Security;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;
using Newtonsoft.Json.Serialization;

namespace Inprotech.Integration.Accounting.Time.Timers
{
    public class RunningTimersJob : IPerformBackgroundJob
    {
        public string Type => nameof(RunningTimersJob);

        public SingleActivity GetJob(long jobExecutionId, JObject jobArguments)
        {
            return Activity.Run<StopRunningTimers>(_ => _.Run());
        }
    }

    public class StopRunningTimers
    {
        readonly IBus _bus;
        readonly IValueTime _valueTime;
        readonly IMapper _mapper;
        readonly IDebtorSplitUpdater _splitUpdater;
        readonly IDbContext _dbContext;
        readonly Func<DateTime> _now;

        public StopRunningTimers(IDbContext dbContext, Func<DateTime> now, IBus bus, IValueTime valueTime, IMapper mapper, IDebtorSplitUpdater splitUpdater)
        {
            _dbContext = dbContext;
            _now = now;
            _bus = bus;
            _valueTime = valueTime;
            _mapper = mapper;
            _splitUpdater = splitUpdater;
        }

        public async Task Run()
        {
            var currentDate = _now().Date;
            var oldTimers = _dbContext.Set<Diary>()
                                      .Where(_ => _.IsTimer > 0 && DbFuncs.TruncateTime(_.TimerStarted) != currentDate);
            var timers = await (from d in oldTimers
                                join i in _dbContext.Set<User>() on d.EmployeeNo equals i.NameId
                                select new
                                {
                                    Timer = d,
                                    UserId = i.Id
                                }).ToArrayAsync();

            if (!timers.Any())
                return;

            foreach (var timer in timers)
            {
                var culture = _dbContext.Set<SettingValues>()
                                        .Where(v => (v.User == null || v.User.Id == timer.UserId) && v.SettingId == KnownSettingIds.PreferredCulture)
                                        .OrderByDescending(_ => _.User != null)
                                        .FirstOrDefault()?.CharacterValue;

                timer.Timer.TryStopTimer(_now());
                var entry = _mapper.Map<RecordableTime>(timer.Timer);
                var costedEntry = await _valueTime.For(entry, culture ?? "en", timer.UserId);
                _mapper.Map(costedEntry, timer.Timer);
                _splitUpdater.UpdateSplits(timer.Timer, costedEntry?.DebtorSplits);
                timer.Timer.IsTimer = 0;
                timer.Timer.TimerStarted = null;

                UpdateBackgroundStatus(timer.UserId, timer.Timer);

                await _dbContext.SaveChangesAsync();
            }

            void UpdateBackgroundStatus(int userId, Diary timer)
            {
                var message = new StoppedTimerInfo
                {
                    EntryNo = timer.EntryNo,
                    Start = timer.StartTime.Value,
                    StaffId = timer.EmployeeNo,
                    EntryDate = timer.StartTime.Value.Date
                };
                var bgProcess = new BackgroundProcess
                {
                    IdentityId = userId,
                    ProcessType = BackgroundProcessType.General.ToString(),
                    ProcessSubType = BackgroundProcessSubType.TimerStopped.ToString(),
                    Status = (int)StatusType.Completed,
                    StatusDate = _now(),
                    StatusInfo = JsonConvert.SerializeObject(message, new JsonSerializerSettings { ContractResolver = new CamelCasePropertyNamesContractResolver() })
                };
                _dbContext.Set<BackgroundProcess>().Add(bgProcess);
            }
        }
    }
}