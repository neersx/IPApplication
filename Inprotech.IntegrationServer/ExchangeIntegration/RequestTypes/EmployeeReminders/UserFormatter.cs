using System;
using System.Collections.Generic;
using System.Linq;
using Inprotech.Infrastructure.Security;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Profiles;
using InprotechKaizen.Model.Security;

namespace Inprotech.IntegrationServer.ExchangeIntegration.RequestTypes.EmployeeReminders
{
    public interface IUserFormatter
    {
        List<ExchangeUser> Users(int staffId);
    }

    public class UserFormatter : IUserFormatter
    {
        readonly IDbContext _dbContext;
        readonly Func<DateTime> _now;

        public UserFormatter(IDbContext dbContext, Func<DateTime> now)
        {
            _dbContext = dbContext;
            _now = now;
        }

        public List<ExchangeUser> Users(int staffId)
        {
            var users = _dbContext.Set<User>()
                                  .Join(_dbContext.PermissionsGrantedAll("TASK", (int) ApplicationTask.ExchangeIntegration, null, _now()),
                                        user => user.Id, item => item.IdentityKey, (user, item) => new {user.Id, StaffId = user.Name.Id, item.CanExecute})
                                  .Where(_ => _.CanExecute && _.StaffId == staffId)
                                  .Select(_ => _.Id)
                                  .ToArray();

            var defaultAlertSetting = _dbContext.Set<SettingValues>().SingleOrDefault(_ => _.SettingId == KnownSettingIds.ExchangeAlertTime && _.User == null)?.DecimalValue.GetValueOrDefault();

            var userSettings = new List<ExchangeUser>();
            foreach (var uId in users)
            {
                var settings = _dbContext.Set<SettingValues>().Where(_ => _.User.Id == uId);
                userSettings.Add(ExchangeUser(uId, settings, defaultAlertSetting));
            }

            return userSettings;
        }

        public ExchangeUser ExchangeUser(int uId, IQueryable<SettingValues> settings, decimal? defaultAlertSetting)
        {
            var newSetting = new ExchangeUser
            {
                UserIdentityId = uId,
                Culture = settings.SingleOrDefault(_ => _.SettingId == KnownSettingIds.PreferredCulture)?.CharacterValue,
                IsUserInitialised = settings.SingleOrDefault(_ => _.SettingId == KnownSettingIds.IsExchangeInitialised)?.BooleanValue ?? false,
                IsAlertRequired = settings.SingleOrDefault(_ => _.SettingId == KnownSettingIds.AreExchangeAlertsRequired)?.BooleanValue ?? false,
                Mailbox = settings.SingleOrDefault(_ => _.SettingId == KnownSettingIds.ExchangeMailbox)?.CharacterValue
            };
            var alertTimeSetting = settings.SingleOrDefault(_ => _.SettingId == KnownSettingIds.ExchangeAlertTime)?.DecimalValue ?? defaultAlertSetting ?? 0;
            var alertHours = Convert.ToInt32(Math.Round(alertTimeSetting * 60, 0, MidpointRounding.AwayFromZero) / 60);
            var alertMinutes = Convert.ToInt32(Math.Round(alertTimeSetting * 60, 0, MidpointRounding.AwayFromZero) % 60);
            newSetting.AlertTime = new TimeSpan(alertHours, alertMinutes, 0);
            return newSetting;
        }
    }
}