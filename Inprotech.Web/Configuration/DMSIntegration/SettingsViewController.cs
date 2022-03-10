using System;
using System.Collections.Generic;
using System.Configuration;
using System.Data.Entity;
using System.Linq;
using System.Net.Http;
using System.Threading.Tasks;
using System.Web.Http;
using Inprotech.Infrastructure;
using Inprotech.Infrastructure.Extensions;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Infrastructure.ResponseEnrichment;
using Inprotech.Infrastructure.Security;
using Inprotech.Integration;
using Inprotech.Integration.Documents;
using Inprotech.Integration.Jobs;
using Inprotech.Integration.Settings;
using Inprotech.Web.Picklists;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Documents;
using InprotechKaizen.Model.Persistence;

namespace Inprotech.Web.Configuration.DMSIntegration
{
    [Authorize]
    [NoEnrichment]
    [RoutePrefix("api/configuration/DMSIntegration")]
    [RequiresAccessTo(ApplicationTask.ConfigureDmsIntegration)]
    public class SettingsViewController : ApiController
    {
        readonly IConfigureJob _configureJob;
        readonly IDbContext _dbContext;
        readonly IDocumentLoader _documentLoader;
        readonly IIMangeSettingsManager _iMangeSettingsManager;
        readonly IPreferredCultureResolver _preferredCultureResolver;
        readonly IDmsIntegrationSettings _settings;
        readonly ISiteControlReader _siteControlReader;

        public SettingsViewController(IDmsIntegrationSettings settings, IConfigureJob configureJob, IDocumentLoader documentLoader, IIMangeSettingsManager iMangeSettingsManager, ISiteControlReader siteControlReader,
                                      IDbContext dbContext, IPreferredCultureResolver preferredCultureResolver)
        {
            _settings = settings ?? throw new ArgumentNullException(nameof(settings));
            _configureJob = configureJob ?? throw new ArgumentNullException(nameof(configureJob));
            _documentLoader = documentLoader ?? throw new ArgumentNullException(nameof(documentLoader));
            _iMangeSettingsManager = iMangeSettingsManager;
            _siteControlReader = siteControlReader;
            _dbContext = dbContext;
            _preferredCultureResolver = preferredCultureResolver;
        }

        [HttpGet]
        [Route("settingsView")]
        public async Task<dynamic> Get()
        {
            var imanage = await _iMangeSettingsManager.Resolve();
            imanage.DataItems = new IManageSettingsModel.IManageSettingsDataItems
            {
                CaseSearch = await GetDataItem(SiteControls.DMSCaseSearchDocItem),
                NameSearch = await GetDataItem(SiteControls.DMSNameSearchDocItem)
            };
            var bindingUrls = ConfigurationManager.AppSettings["BindingUrls"]?.Split(new[] {','}, StringSplitOptions.RemoveEmptyEntries) ?? new string[0];

            await FillAllNameTypes(imanage);
            return new
            {
                ViewData = new
                {
                    DataDownload = ForDataSources(new[] {DataSourceType.UsptoPrivatePair, DataSourceType.UsptoTsdr}),
                    IManage = imanage,
                    DefaultSiteUrls = bindingUrls.SelectMany(_ => PossiblePaths(_, Request)).Distinct()
                }
            };
        }

        [HttpGet]
        [Route("settingsView/dataDownload")]
        public async Task<dynamic> GetDataDownload(int type)
        {
            return new
            {
                DataDownload = ForDataSource((DataSourceType) type)
            };
        }

        static IEnumerable<string> PossiblePaths(string bindingUrl, HttpRequestMessage request)
        {
            var appPathUri = request.RequestUri
                                    .ReplaceStartingFromSegment("apps", "apps");

            if (bindingUrl.Contains("*:80"))
            {
                yield return new Uri("http://" + Environment.MachineName) + appPathUri.PathAndQuery.TrimStart('/');
            }
            else if (bindingUrl.Contains("*:443"))
            {
                yield return appPathUri.ToString();
            }
            else
            {
                yield return bindingUrl;
            }
        }

        async Task<PicklistModel<int>> GetDataItem(string siteControl)
        {
            var dataItemCode = _siteControlReader.Read<string>(siteControl);
            if (!string.IsNullOrEmpty(dataItemCode))
            {
                var dataItem = await _dbContext.Set<DocItem>().FirstOrDefaultAsync(_ => _.Name == dataItemCode);
                if (dataItem != null)
                {
                    return new PicklistModel<int> {Key = dataItem.Id, Code = dataItem.Name, Value = dataItem.Name};
                }
            }

            return null;
        }

        async Task FillAllNameTypes(IManageSettingsModel settings)
        {
            if (!settings.NameTypes.Any()) return;
            var culture = _preferredCultureResolver.Resolve();
            var nameTypeKeys = string.Join(",", settings.NameTypes.Select(_ => _.NameType)).Split(',').Distinct();

            var nameTypes = await _dbContext.Set<NameType>()
                                            .Where(_ => nameTypeKeys.Contains(_.NameTypeCode))
                                            .Select(_ => new PicklistModel<int>
                                            {
                                                Key = _.Id,
                                                Code = _.NameTypeCode,
                                                Value = DbFuncs.GetTranslation(_.Name, null, _.NameTId, culture) ?? string.Empty
                                            })
                                            .ToArrayAsync();

            foreach (var name in settings.NameTypes) name.NameTypePicklist = nameTypes.Where(_ => name.NameType.Split(',').Contains(_.Code)).ToList();
        }

        IEnumerable<dynamic> ForDataSources(DataSourceType[] dataSourceTypes)
        {
            return dataSourceTypes.Select(_ => new
            {
                type = _,
                DataSourceId = (int) _,
                DataSource = _.ToString(),
                IsEnabled = _settings.IsEnabledFor(_),
                Location = _settings.GetLocationFor(_)
            }).ToArray();
        }

        dynamic ForDataSource(DataSourceType dataSourceType)
        {
            var jobStatus = _configureJob.GetJobStatus(DataSourceHelper.GetJobType(dataSourceType));

            return new
            {
                DataSourceId = (int) dataSourceType,
                DataSource = dataSourceType.ToString(),
                IsEnabled = _settings.IsEnabledFor(dataSourceType),
                Location = _settings.GetLocationFor(dataSourceType),
                Documents = _documentLoader.CountDocumentsFromSource(dataSourceType),
                Job = ForJobStatus(jobStatus)
            };
        }

        dynamic ForJobStatus(JobStatus jobStatus)
        {
            var acknowledged = (bool?) jobStatus.State["Acknowledged"] ?? false;

            var status = "Idle";
            if (acknowledged)
            {
                status = "Idle";
            }
            else if (jobStatus.Status == "Completed" && jobStatus.HasErrors)
            {
                status = "Failed";
            }
            else if (jobStatus.Status == null && jobStatus.IsActive)
            {
                status = "Started";
            }
            else if (jobStatus.Status != null)
            {
                status = jobStatus.Status;
            }

            return new
            {
                Status = status,
                jobStatus.JobExecutionId,
                TotalDocuments = jobStatus.State["TotalDocuments"] ?? 0,
                SentDocuments = jobStatus.State["SentDocuments"] ?? 0,
                Acknowledged = acknowledged
            };
        }
    }
}