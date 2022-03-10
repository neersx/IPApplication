using System;
using System.Collections.Generic;
using System.Data.Entity;
using System.Diagnostics.CodeAnalysis;
using System.Linq;
using System.Threading.Tasks;
using Aspose.Pdf;
using Inprotech.Contracts;
using Inprotech.Integration.DmsIntegration.Component.iManage;
using Inprotech.Web.Picklists;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Profiles;
using Newtonsoft.Json;

namespace Inprotech.Web.Configuration.DMSIntegration
{
    public interface IIMangeSettingsManager
    {
        Task<IManageSettingsModel> Resolve();
        Task Save(IManageSettingsModel settings);
        bool ValidateUrl(string url, string integrationType);
    }

    [SuppressMessage("ReSharper", "InconsistentNaming")]
    internal class IManageSettingsManager : IIMangeSettingsManager
    {
        const string ExternalSettingKey = "IManage";
        readonly ICryptoService _cryptoService;
        readonly IDbContext _dbContext;

        public IManageSettingsManager(IDbContext dbContext, ICryptoService cryptoService)
        {
            _dbContext = dbContext;
            _cryptoService = cryptoService;
        }

        public async Task<IManageSettingsModel> Resolve()
        {
            var settings = await GetSettings();
            AddNameTypeIds(settings);
            return settings;
        }

        public async Task Save(IManageSettingsModel settings)
        {
            Validate(settings);
            var json = JsonConvert.SerializeObject(settings, Formatting.None, new JsonSerializerSettings { NullValueHandling = NullValueHandling.Ignore });
            var encrypted = _cryptoService.Encrypt(json);
            var es = _dbContext.Set<ExternalSettings>();
            var setting = await es.SingleOrDefaultAsync(_ => _.ProviderName == ExternalSettingKey) ?? es.Add(new ExternalSettings(ExternalSettingKey));

            setting.Settings = encrypted;
            setting.IsComplete = settings.Databases.Any();
            setting.IsDisabled = !settings.Databases.Any() || settings.Disabled;
            await _dbContext.SaveChangesAsync();
        }

        public bool ValidateUrl(string url, string integrationType)
        {
            if (integrationType == IManageSettings.IntegrationTypes.iManageCOM)
            {
                return Uri.CheckHostName(url) != UriHostNameType.Unknown;
            }

            return Uri.TryCreate(url, UriKind.Absolute, out _);
        }
        void Validate(IManageSettingsModel settings)
        {
            settings.DataItems = null;
            if (settings.Databases != null)
            {
                foreach (var t in settings.Databases)
                {
                    if (t.IntegrationType == null || t.LoginType == null || t.Database == null || t.Server == null)
                    {
                        throw new ArgumentNullException();
                    }

                    if (!IManageSettings.IntegrationTypes.Contains(t.IntegrationType) || !IManageSettings.LoginTypes.Contains(t.LoginType))
                    {
                        throw new Exception("value not supported");
                    }

                    if (!ValidateUrl(t.Server, t.IntegrationType))
                    {
                        throw new InvalidValueFormatException("Invalid value format");
                    }

                    if (t.IntegrationType != IManageSettings.IntegrationTypes.iManageWorkApiV2)
                    {
                        t.CustomerId = null;
                    }
                    else if (t.CustomerId == null)
                    {
                        throw new ArgumentNullException();
                    }

                    if (t.LoginType != IManageSettings.LoginTypes.UsernameWithImpersonation && t.LoginType != IManageSettings.LoginTypes.InprotechUsernameWithImpersonation)
                    {
                        t.Password = null;
                    }
                    else if (t.Password == null)
                    {
                        throw new ArgumentNullException();
                    }

                    var databases = t.Databases;
                    if (databases.Count() != databases.Distinct().Count())
                    {
                        throw new Exception("Unique databases only");
                    }
                }
            }

            foreach (var name in settings.NameTypes) name.ExtractNameTypeCode();
        }

        async Task<IManageSettingsModel> GetSettings()
        {
            var setting = await _dbContext.Set<ExternalSettings>()
                                           .SingleOrDefaultAsync(_ => _.ProviderName == ExternalSettingKey);

            if (string.IsNullOrWhiteSpace(setting?.Settings)) return new IManageSettingsModel();

            var dmsSettings = JsonConvert.DeserializeObject<IManageSettingsModel>(_cryptoService.Decrypt(setting.Settings));

            dmsSettings.Disabled = setting.IsDisabled;
            return dmsSettings;
        }

        static void AddNameTypeIds(IManageSettingsModel settings)
        {
            var index = -1;
            foreach (var settingsNameType in settings.NameTypes) settingsNameType.AutoNumber = ++index;
        }
    }

    [SuppressMessage("ReSharper", "InconsistentNaming")]
    public class IManageSettingsModel : IManageSettings
    {
        public IManageSettingsModel()
        {
            Databases = new SiteDatabaseSettings[0];
            NameTypes = new NameSettings[0];
        }
        public IManageSettingsDataItems DataItems { get; set; }
        public new IEnumerable<NameSettings> NameTypes { get; set; }

        public class NameSettings : NameTypeSettings
        {
            public List<PicklistModel<int>> NameTypePicklist { get; set; }
            public string Names => string.Join(", ", NameTypePicklist?.Select(_ => _.Value) ?? Enumerable.Empty<string>());
            public int AutoNumber { get; set; }

            public void ExtractNameTypeCode()
            {
                NameType = string.Join(",", NameTypePicklist.Select(_ => _.Code));
            }
        }

        public class IManageSettingsDataItems
        {
            public PicklistModel<int> CaseSearch { get; set; }
            public PicklistModel<int> NameSearch { get; set; }
        }
    }
}