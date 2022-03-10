using System;
using System.Linq;
using Inprotech.Integration.Persistence;
using Inprotech.Integration.Schedules.Extensions;
using InprotechKaizen.Model.Components.Security;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;

namespace Inprotech.Integration.Schedules
{
    public interface IRecoverableSchedule
    {
        void Recover(int scheduleId);
    }

    public class RecoverableSchedule : IRecoverableSchedule
    {
        readonly Func<DateTime> _now;
        readonly IRecoverableItems _recoverableItems;
        readonly IManageRecoveryInfo _recoveryInfoManager;
        readonly IRecoveryScheduleStatusReader _recoveryScheduleStatusReader;
        readonly IRepository _repository;
        readonly ISecurityContext _securityContext;

        public RecoverableSchedule(IRepository repository,
                                   IRecoveryScheduleStatusReader recoveryScheduleStatusReader,
                                   IRecoverableItems recoverableItems,
                                   ISecurityContext securityContext,
                                   IManageRecoveryInfo recoveryInfoManager,
                                   Func<DateTime> now)
        {
            _repository = repository;
            _recoveryScheduleStatusReader = recoveryScheduleStatusReader;
            _recoverableItems = recoverableItems;
            _securityContext = securityContext;
            _recoveryInfoManager = recoveryInfoManager;
            _now = now;
        }

        public void Recover(int scheduleId)
        {
            var status = _recoveryScheduleStatusReader.Read(scheduleId);
            if (status != RecoveryScheduleStatus.Idle)
            {
                return;
            }

            var recoveryInfo = _recoverableItems.FindBySchedule(scheduleId).ToArray();
            if (recoveryInfo.IsEmpty())
            {
                return;
            }

            var tempStorageId = _recoveryInfoManager.AddIds(recoveryInfo);

            var recoverySchedule = CreateRecoverySchedule(GetSchedule(scheduleId), tempStorageId);

            _repository.Set<Schedule>().Add(recoverySchedule);
            _repository.SaveChanges();
        }

        Schedule GetSchedule(int id)
        {
            var schedule = _repository.Set<Schedule>().Single(_ => _.Id == id);
            if (schedule.State == ScheduleState.Disabled)
            {
                var continuousSchedule = _repository.Set<Schedule>().WhereActive().SingleOrDefault(_ => _.Type == ScheduleType.Continuous && _.DataSourceType == schedule.DataSourceType);
                if (continuousSchedule != null)
                {
                    return continuousSchedule;
                }

                throw new NotSupportedException("Valid Continuous Schedule does not exist to process retry request");
            }

            return schedule;
        }

        Schedule CreateRecoverySchedule(Schedule parent, long tempStorageId)
        {
            var extendedSettings = string.IsNullOrEmpty(parent.ExtendedSettings)
                ? null
                : JObject.Parse(parent.ExtendedSettings);
            extendedSettings = extendedSettings ?? new JObject();
            extendedSettings["TempStorageId"] = tempStorageId;

            var now = _now();
            return new Schedule
            {
                Name = parent.Name,
                DownloadType = parent.DownloadType,
                CreatedOn = now,
                CreatedBy = _securityContext.User.Id,
                IsDeleted = false,
                NextRun = now,
                DataSourceType = parent.DataSourceType,
                ExtendedSettings = JsonConvert.SerializeObject(extendedSettings),
                ExpiresAfter = now,
                Parent = parent,
                State = ScheduleState.RunNow,
                Type = ScheduleType.Retry
            };
        }
    }
}