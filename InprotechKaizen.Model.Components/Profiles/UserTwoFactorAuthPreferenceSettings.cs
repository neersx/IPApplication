using System;
using System.Data.Entity;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Contracts;
using Inprotech.Infrastructure.Security;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Profiles;
using InprotechKaizen.Model.Security;
using OtpNet;

namespace InprotechKaizen.Model.Components.Profiles
{
    public class UserTwoFactorAuthPreferenceSettings : IUserTwoFactorAuthPreference
    {
        readonly ICryptoService _cryptoService;
        readonly IDbContext _dbContext;

        public UserTwoFactorAuthPreferenceSettings(IDbContext dbContext, ICryptoService cryptoService)
        {
            _dbContext = dbContext;
            _cryptoService = cryptoService;
        }

        public async Task<string> ResolvePreferredMethod(int userId)
        {
            return await _dbContext.Set<SettingValues>()
                                   .Where(
                                          s => s.SettingId == KnownSettingIds.PreferredTwoFactorMode &&
                                               s.CharacterValue != null &&
                                               (s.User == null || s.User.Id == userId))
                                   .OrderByDescending(s => s.User.Id)
                                   .Select(s => s.CharacterValue)
                                   .FirstOrDefaultAsync() ?? "email";
        }

        public async Task SetPreference(int userId, string preference)
        {
            var setting = await _dbContext.Set<SettingValues>()
                                          .Where(
                                                 s => s.SettingId == KnownSettingIds.PreferredTwoFactorMode &&
                                                      s.CharacterValue != null &&
                                                      (s.User == null || s.User.Id == userId))
                                          .OrderByDescending(s => s.User.Id).FirstOrDefaultAsync();
            if (setting == null)
            {
                setting = new SettingValues
                {
                    CharacterValue = preference,
                    User = await GetUser(userId),
                    SettingId = KnownSettingIds.PreferredTwoFactorMode
                };
                _dbContext.Set<SettingValues>().Add(setting);
            }

            setting.CharacterValue = preference;
            await _dbContext.SaveChangesAsync();
        }

        public async Task<string> ResolveAppSecretKey(int userId)
        {
            var secretKey = await _dbContext.Set<SettingValues>()
                                            .Where(
                                                   s => s.SettingId == KnownSettingIds.AppSecretKey &&
                                                        s.CharacterValue != null &&
                                                        (s.User == null || s.User.Id == userId))
                                            .Select(s => s.CharacterValue)
                                            .FirstOrDefaultAsync();
            if (!string.IsNullOrWhiteSpace(secretKey))
            {
                secretKey = _cryptoService.Decrypt(secretKey);
            }

            return secretKey;
        }

        public async Task SaveAppSecretKeyFromTemp(int userId)
        {
            var secretKey = await ResolveAppTempSecretKey(userId);
            var setting = await _dbContext.Set<SettingValues>()
                                          .FirstOrDefaultAsync(s => s.SettingId == KnownSettingIds.AppTempSecretKey &&
                                                                    s.CharacterValue != null &&
                                                                    (s.User == null || s.User.Id == userId));

            if (setting != null)
            {
                var newSetting = await _dbContext.Set<SettingValues>()
                                                 .FirstOrDefaultAsync(s => s.SettingId == KnownSettingIds.AppSecretKey &&
                                                                           s.CharacterValue != null &&
                                                                           (s.User == null || s.User.Id == userId));
                if (newSetting == null)
                {
                    newSetting = new SettingValues
                    {
                        User = await GetUser(userId),
                        SettingId = KnownSettingIds.AppSecretKey
                    };
                    _dbContext.Set<SettingValues>().Add(newSetting);
                }

                newSetting.CharacterValue = _cryptoService.Encrypt(secretKey);
                _dbContext.Set<SettingValues>().Remove(setting);
                await _dbContext.SaveChangesAsync();
            }
        }

        public async Task RemoveAppSecretKey(int userId)
        {
            var existingKey = await _dbContext.Set<SettingValues>()
                                              .Where(
                                                     s => s.SettingId == KnownSettingIds.AppSecretKey &&
                                                          s.CharacterValue != null &&
                                                          (s.User == null || s.User.Id == userId))
                                              .FirstOrDefaultAsync();
            if (existingKey != null)
            {
                existingKey.CharacterValue = string.Empty;
                await _dbContext.SaveChangesAsync();
            }

            await SetPreference(userId, "email");
        }

        public async Task<string> ResolveAppTempSecretKey(int userId)
        {
            var secretKey = await _dbContext.Set<SettingValues>()
                                            .Where(
                                                   s => s.SettingId == KnownSettingIds.AppTempSecretKey &&
                                                        s.CharacterValue != null &&
                                                        (s.User == null || s.User.Id == userId))
                                            .Select(s => s.CharacterValue)
                                            .FirstOrDefaultAsync();
            if (!string.IsNullOrWhiteSpace(secretKey))
            {
                secretKey = _cryptoService.Decrypt(secretKey);
            }

            return secretKey;
        }

        public async Task<string> GenerateAppTempSecretKey(int userId)
        {
            var secretKey = _cryptoService.Encrypt(Base32Encoding.ToString(Guid.NewGuid().ToByteArray()));
            var setting = await _dbContext.Set<SettingValues>()
                                          .FirstOrDefaultAsync(s => s.SettingId == KnownSettingIds.AppTempSecretKey &&
                                                                    s.CharacterValue != null &&
                                                                    (s.User == null || s.User.Id == userId));

            if (setting == null)
            {
                setting = new SettingValues
                {
                    CharacterValue = secretKey,
                    User = await GetUser(userId),
                    SettingId = KnownSettingIds.AppTempSecretKey
                };
                _dbContext.Set<SettingValues>().Add(setting);
            }

            await _dbContext.SaveChangesAsync();

            return _cryptoService.Decrypt(secretKey);
        }

        public async Task<string> ResolveEmailSecretKey(int userId)
        {
            var configuredKey = await _dbContext.Set<SettingValues>()
                                                .Where(
                                                       s => s.SettingId == KnownSettingIds.EmailSecretKey &&
                                                            s.CharacterValue != null &&
                                                            (s.User == null || s.User.Id == userId))
                                                .OrderByDescending(s => s.User.Id)
                                                .Select(s => s.CharacterValue)
                                                .FirstOrDefaultAsync();

            if (string.IsNullOrWhiteSpace(configuredKey))
            {
                var user = await GetUser(userId);
                configuredKey = _cryptoService.Encrypt(Base32Encoding.ToString(Guid.NewGuid().ToByteArray()));
                var newSetting = new SettingValues
                {
                    SettingId = KnownSettingIds.EmailSecretKey,
                    CharacterValue = configuredKey,
                    User = user
                };
                _dbContext.Set<SettingValues>().Add(newSetting);
                await _dbContext.SaveChangesAsync();
            }

            return _cryptoService.Decrypt(configuredKey);
        }

        async Task<User> GetUser(int userId)
        {
            return await _dbContext.Set<User>().SingleAsync(v => v.Id == userId);
        }
    }
}