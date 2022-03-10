using System;
using System.Collections.Generic;
using System.Data.Entity;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Contracts;
using Inprotech.Contracts.Messages.Security;
using Inprotech.Infrastructure.Messaging;
using Inprotech.Infrastructure.Security;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Security;
using Newtonsoft.Json;

namespace InprotechKaizen.Model.Components.Security
{
    internal class UserIdentityAccessManager : IUserIdentityAccessManager
    {
        const int AbsoluteExpiryDays = 2;
        readonly IBus _bus;
        readonly ICryptoService _cryptoService;
        readonly IDbContext _dbContext;
        readonly Func<DateTime> _now;

        public UserIdentityAccessManager(IDbContext dbContext, ICryptoService cryptoService, Func<DateTime> now, IBus bus)
        {
            _dbContext = dbContext;
            _cryptoService = cryptoService;
            _now = now;
            _bus = bus;
        }

        public async Task<(UserIdentityAccessData data, DateTime? lastExtension)> GetSigninData(long logId, int identityId, string authProvider)
        {
            var log = await GetOpenLog(logId, identityId, authProvider);
            var encrypted = log.Data;
            var data = string.IsNullOrEmpty(encrypted) ? null : JsonConvert.DeserializeObject<UserIdentityAccessData>(_cryptoService.Decrypt(encrypted));
            return (data, log.LastExtension);
        }

        public async Task ExtendProviderSession(long logId, int identityId, string authProvider, UserIdentityAccessData data)
        {
            var log = await GetOpenLog(logId, identityId, authProvider);
            await ExtendProviderSession(log, data);
        }

        public async Task<bool> TryExtendProviderSession(long logId, int identityId, string authProvider, UserIdentityAccessData data, int defaultExtensionToleranceMinutes)
        {
            var log = await GetOpenLog(logId, identityId, authProvider);
            if (log.LastExtension != null && log.LastExtension > _now().AddMinutes(-defaultExtensionToleranceMinutes))
            {
                return false;
            }

            await ExtendProviderSession(log, data);
            return true;
        }

        public long StartSession(int identityId, string authProvider, UserIdentityAccessData data, string application, string source)
        {
            var log = new UserIdentityAccessLog(identityId, authProvider, application, _now());
            if (data != null)
            {
                log.Data = _cryptoService.Encrypt(data.ToString());
            }

            if (source != null)
            {
                log.Source = source;
            }

            _dbContext.Set<UserIdentityAccessLog>().Add(log);
            _dbContext.SaveChanges();

            _bus.Publish(new UserSessionStartedMessage
            {
                IdentityId = identityId
            });

            return log.LogId;
        }

        public async Task EndSession(long logId)
        {
            var log = await _dbContext.Set<UserIdentityAccessLog>().SingleOrDefaultAsync(_ => _.LogId == logId);
            await EndSession(log);
        }

        public async Task EndSessionIfOpen(long logId)
        {
            var log = await _dbContext.Set<UserIdentityAccessLog>().SingleOrDefaultAsync(_ => _.LogId == logId && _.LogoutTime == null);
            await EndSession(log);
        }

        public async Task EndExpiredSessions()
        {
            var now = _now();
            var absTimeoutLimit = now.AddDays(-AbsoluteExpiryDays);
            var oldOpenedSessions = _dbContext.Set<UserIdentityAccessLog>()
                                              .Where(_ => _.LogoutTime == null && _.LoginTime < absTimeoutLimit);

            var ids = new HashSet<int>();
            await oldOpenedSessions.ForEachAsync(log =>
            {
                log.LogoutTime = now;
                log.Data = null;

                ids.Add(log.IdentityId);
            });

            await _dbContext.SaveChangesAsync();

            _bus.Publish(new UserSessionsInvalidatedMessage
            {
                IdentityIds = ids.ToArray()
            });
        }

        async Task EndSession(UserIdentityAccessLog log)
        {
            if (log != null)
            {
                log.LogoutTime = _now();
                log.Data = null;
                await _dbContext.SaveChangesAsync();

                _bus.Publish(new UserSessionInvalidatedMessage
                {
                    IdentityId = log.IdentityId
                });
            }
        }

        async Task<UserIdentityAccessLog> GetOpenLog(long logId, int identityId, string authProvider)
        {
            var log = await GetLog(logId, identityId, authProvider);
            if (log.LogoutTime != null)
            {
                throw new Exception($"No active session found for user:{identityId} against authentication method{authProvider}");
            }

            return log;
        }

        async Task<UserIdentityAccessLog> GetLog(long logId, int identityId, string authProvider)
        {
            var log = await _dbContext.Set<UserIdentityAccessLog>().SingleAsync(_ => _.LogId == logId);
            if (log.IdentityId != identityId || log.Provider != authProvider)
            {
                throw new Exception($"No matching Login found for user:{identityId} against authentication method{authProvider}");
            }

            return log;
        }

        async Task ExtendProviderSession(UserIdentityAccessLog log, UserIdentityAccessData data)
        {
            log.LastExtension = _now();
            log.TotalExtensions = log.TotalExtensions.GetValueOrDefault() + 1;
            var json = data?.ToString();
            log.Data = string.IsNullOrEmpty(json) ? null : _cryptoService.Encrypt(json);
            await _dbContext.SaveChangesAsync();

            _bus.Publish(new UserSessionInvalidatedMessage
            {
                IdentityId = log.IdentityId
            });
        }
    }
}