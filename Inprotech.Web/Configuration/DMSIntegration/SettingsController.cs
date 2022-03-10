using System;
using System.Collections.Generic;
using System.Data.Entity;
using System.Diagnostics.CodeAnalysis;
using System.Linq;
using System.Threading.Tasks;
using System.Web.Http;
using Inprotech.Infrastructure;
using Inprotech.Infrastructure.ResponseEnrichment;
using Inprotech.Infrastructure.Security;
using Inprotech.Integration;
using Inprotech.Integration.Jobs;
using Inprotech.Integration.Settings;
using InprotechKaizen.Model.Components.Configuration.SiteControl;
using InprotechKaizen.Model.Configuration.SiteControl;
using InprotechKaizen.Model.Persistence;

namespace Inprotech.Web.Configuration.DMSIntegration
{
    [Authorize]
    [NoEnrichment]
    [RoutePrefix("api/configuration/DMSIntegration/settings")]
    [RequiresAccessTo(ApplicationTask.ConfigureDmsIntegration)]
    [SuppressMessage("ReSharper", "InconsistentNaming")]
    public class SettingsController : ApiController
    {
        readonly IConfigureJob _configureJob;
        readonly IDbContext _dbContext;
        readonly IFileHelpers _fileHelpers;
        readonly IIMangeSettingsManager _iMangeSettingsManager;
        readonly IDmsIntegrationSettings _settings;
        readonly ISettingTester _settingTester;
        readonly ISiteControlCache _siteControlCache;

        public SettingsController(IDmsIntegrationSettings settings, IFileHelpers fileHelpers, IConfigureJob configureJob, IIMangeSettingsManager iMangeSettingsManager, IDbContext dbContext, ISiteControlCache siteControlCache, ISettingTester settingTester)
        {
            _settings = settings;
            _fileHelpers = fileHelpers;
            _configureJob = configureJob;
            _iMangeSettingsManager = iMangeSettingsManager;
            _dbContext = dbContext;
            _siteControlCache = siteControlCache;
            _settingTester = settingTester;
        }

        [HttpPut]
        [Route]
        public async Task<dynamic> Update(DmsModel model)
        {
            if (model == null)
            {
                throw new ArgumentException(nameof(model));
            }

            if (model.IManageSettings == null)
            {
                throw new ArgumentException(nameof(model.IManageSettings));
            }

            if (!model.IManageSettings.Disabled && model.IManageSettings.HasDatabaseChanges)
            {
                var testConnectionResults = (await _settingTester.TestConnections(new ConnectionTestRequestModel {Settings = model.IManageSettings.Databases, Password = model.Password, UserName = model.Username})).ToList();
                if (testConnectionResults.Any(_ => !_.Success))
                {
                    return new
                    {
                        ConnectionResults = testConnectionResults
                    };
                }
            }

            await UpdateSiteControls(model.IManageSettings.DataItems);
            await _iMangeSettingsManager.Save(model.IManageSettings);
            return UpdateDataDownload(model.DataDownload ?? Enumerable.Empty<SettingsForDataSource>());
        }

        [HttpPost]
        [Route("validateurl")]
        public bool ValidateUrl(ValidationModel model)
        {
            return _iMangeSettingsManager.ValidateUrl(model.Url, model.IntegrationType);
        }

        async Task<dynamic> UpdateDataDownload(IEnumerable<SettingsForDataSource> items)
        {
            foreach (var item in items)
            {
                if (item.IsEnabled && (!_fileHelpers.FilePathValid(item.Location) || !_fileHelpers.DirectoryExists(item.Location)))
                {
                    return new {Error = "Invalid" + item.DataSource + "Location"};
                }
            }

            foreach (var item in items)
            {
                _settings.SetEnabledFor(item.DataSource, item.IsEnabled);
                _settings.SetLocationFor(item.DataSource, item.Location ?? string.Empty);

                if (!item.IsEnabled && item.Job?.JobExecutionId != null)
                {
                    await _configureJob.Acknowledge((long) item.Job.JobExecutionId);
                }
            }

            return null;
        }

        async Task UpdateSiteControls(IManageSettingsModel.IManageSettingsDataItems dataItems)
        {
            if (dataItems != null)
            {
                var siteControlsKeys = new[] {SiteControls.DMSCaseSearchDocItem, SiteControls.DMSNameSearchDocItem};
                var siteControls = await _dbContext.Set<SiteControl>().Where(_ => siteControlsKeys.Contains(_.ControlId)).ToArrayAsync();

                var @case = siteControls.FirstOrDefault(_ => _.ControlId == SiteControls.DMSCaseSearchDocItem);
                var name = siteControls.FirstOrDefault(_ => _.ControlId == SiteControls.DMSNameSearchDocItem);

                if (@case != null)
                {
                    @case.StringValue = dataItems.CaseSearch?.Code;
                }

                if (name != null)
                {
                    name.StringValue = dataItems.NameSearch?.Code;
                }

                await _dbContext.SaveChangesAsync();
                _siteControlCache.Clear(SiteControls.DMSCaseSearchDocItem, SiteControls.DMSNameSearchDocItem);
            }
        }

        public class DmsModel
        {
            public string Username { get; set; }
            public string Password { get; set; }
            public SettingsForDataSource[] DataDownload { get; set; }

            public IManageSettingsModel IManageSettings { get; set; }
        }

        public class SettingsForDataSource
        {
            public DataSourceType DataSource { get; set; }

            public bool IsEnabled { get; set; }

            public string Location { get; set; }

            public SettingsForDataSourceJob Job { get; set; }
        }

        public class SettingsForDataSourceJob
        {
            public long? JobExecutionId { get; set; }
        }

        public class ValidationModel
        {
            public string Url { get; set; }
            public string IntegrationType { get; set; }
        }
    }
}