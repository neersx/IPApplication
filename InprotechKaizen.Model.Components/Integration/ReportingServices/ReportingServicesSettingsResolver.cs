using System;
using System.Data.Entity;
using System.Threading.Tasks;
using Inprotech.Contracts;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Profiles;
using Newtonsoft.Json;

namespace InprotechKaizen.Model.Components.Integration.ReportingServices
{
    public interface IReportingServicesSettingsResolver
    {
        Task<ReportingServicesSetting> Resolve();
    }

    public interface IReportingServicesSettingsPersistence
    {
        Task<bool> Save(ReportingServicesSetting settings);
    }

    public class ReportingServicesSettingsResolver : IReportingServicesSettingsResolver, IReportingServicesSettingsPersistence
    {
        readonly Func<IDbContext> _dbContextFunc;
        readonly ICryptoService _cryptoService;

        const string ProviderName = "ReportingServicesSetting";

        ReportingServicesSetting _settings;

        public ReportingServicesSettingsResolver(Func<IDbContext> dbContextFunc, ICryptoService cryptoService)
        {
            _dbContextFunc = dbContextFunc;
            _cryptoService = cryptoService;
        }

        public async Task<ReportingServicesSetting> Resolve()
        {
            if (_settings != null) return _settings;

            var settings = await _dbContextFunc().Set<ExternalSettings>().SingleOrDefaultAsync(_ => _.ProviderName == ProviderName);
            
            var interim = settings == null
                ? new ReportingServicesSetting()
                : JsonConvert.DeserializeObject<ReportingServicesSetting>(_cryptoService.Decrypt(settings.Settings));

            interim.Security ??= new SecurityElement();

            _settings = interim;

            return _settings;
        }

        public async Task<bool> Save(ReportingServicesSetting settings)
        {
            if (settings == null) throw new ArgumentNullException(nameof(settings));

            var dbContext = _dbContextFunc();
            
            var settingsDb = await dbContext.Set<ExternalSettings>().SingleOrDefaultAsync(_ => _.ProviderName == ProviderName);
            
            var newSetting = _cryptoService.Encrypt(JsonConvert.SerializeObject(settings));

            if (settingsDb != null)
            {
                settingsDb.Settings = newSetting;
            }
            else
            {
                dbContext.Set<ExternalSettings>()
                         .Add(new ExternalSettings(ProviderName)
                         {
                             IsComplete = !string.IsNullOrEmpty(settings.ReportServerBaseUrl) && !string.IsNullOrEmpty(settings.RootFolder),
                             Settings = newSetting
                         });
            }

            await dbContext.SaveChangesAsync();

            _settings = null;

            return true;
        }
    }
}
