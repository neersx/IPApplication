using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Contracts;
using Inprotech.Infrastructure.Extensions;
using Inprotech.Infrastructure.Web;
using Inprotech.Integration.DmsIntegration.Component.Domain;
using Inprotech.Integration.DmsIntegration.Component.iManage.v10;

namespace Inprotech.Integration.DmsIntegration.Component.iManage
{
    public class IManageDmsService : IDmsService
    {
        readonly ICredentialsResolver _credentialsResolver;
        readonly IDmsEventEmitter _dmsEventEmitter;
        readonly IDmsSettingsProvider _dmsSettingsProvider;
        readonly ILogger<IManageDmsService> _log;
        readonly IWorkSiteManagerFactory _workSiteManagerFactory;
        readonly IWorkServerClient _workServerClient;
        readonly IAccessTokenManager _accessTokenManager;
        public IManageDmsService(ILogger<IManageDmsService> log,
                                 IWorkSiteManagerFactory workSiteManagerFactory,
                                 ICredentialsResolver credentialsResolver,
                                 IDmsSettingsProvider dmsSettingsProvider, IDmsEventEmitter dmsEventEmitter, IWorkServerClient workServerClient, IAccessTokenManager accessTokenManager)
        {
            _log = log;
            _workSiteManagerFactory = workSiteManagerFactory;
            _credentialsResolver = credentialsResolver;
            _dmsSettingsProvider = dmsSettingsProvider;
            _dmsEventEmitter = dmsEventEmitter;
            _workServerClient = workServerClient;
            _accessTokenManager = accessTokenManager;
        }

        public async Task<IEnumerable<DmsFolder>> GetCaseFolders(string searchString, IManageTestSettings testSettings = null)
        {
            if (string.IsNullOrEmpty(searchString))
            {
                _log.Warning(KnownErrors.CaseSearchFieldEmpty);
                return Enumerable.Empty<DmsFolder>();
            }

            return await GetFolders(SearchType.ByCaseReference, searchString, string.Empty, testSettings);
        }

        public async Task<IEnumerable<DmsFolder>> GetNameFolders(string searchString, string nameType, IManageTestSettings testSettings = null)
        {
            if (string.IsNullOrEmpty(searchString))
            {
                _log.Warning(KnownErrors.NameSearchFieldEmpty);
                return Enumerable.Empty<DmsFolder>();
            }

            return await GetFolders(SearchType.ByNameCode, searchString, nameType, testSettings);
        }

        public async Task<IEnumerable<DmsFolder>> GetSubFolders(string searchStringOrPath, FolderType folderType, bool fetchChild)
        {
            if (string.IsNullOrWhiteSpace(searchStringOrPath)) throw new ArgumentNullException(nameof(searchStringOrPath));

            var (settings, dbSettings, credentials, iWorkSiteManager, _, containerId) = await GetAllComponents(searchStringOrPath);

            return await RefreshTokenOnExpire(async force =>
            {
                if (await iWorkSiteManager.Connect(dbSettings, credentials.UserName, credentials.Password, force))
                {
                    iWorkSiteManager.SetSettings(settings);
                    var folders = (await iWorkSiteManager.GetSubFolders(containerId, folderType, fetchChild))
                                  .GroupBy(v => v.Id)
                                  .Select(group => group.First());
                    return folders;
                }

                return new DmsFolder[0];
            }, dbSettings, credentials);
        }

        public async Task<DmsDocumentCollection> GetDocuments(string searchStringOrPath, FolderType folderType, CommonQueryParameters qp = null)
        {
            if (string.IsNullOrWhiteSpace(searchStringOrPath)) throw new ArgumentNullException(nameof(searchStringOrPath));

            var (settings, dbSettings, credentials, iWorkSiteManager, _, containerId) = await GetAllComponents(searchStringOrPath);

            var documents = new List<DmsDocument>();
            var documentsCount = 0;

            return await RefreshTokenOnExpire(async force =>
            {
                if (await iWorkSiteManager.Connect(dbSettings, credentials.UserName, credentials.Password, force))
                {
                    iWorkSiteManager.SetSettings(settings);
                    var documentCollection = await iWorkSiteManager.GetDocuments(containerId, folderType, qp);
                    if (documentCollection != null)
                    {
                        documentsCount = documentCollection.TotalCount;

                        var folders = documentCollection.DmsDocuments
                                                        .GroupBy(v => v.Id)
                                                        .Select(group => @group.First()).Select(d =>
                                                        {
                                                            d.SiteDbId = dbSettings.SiteDbId;
                                                            return d;
                                                        });
                        documents.AddRange(folders);
                    }
                }

                var docs = new DmsDocumentCollection { DmsDocuments = documents, TotalCount = documentsCount };

                return docs;

            }, dbSettings, credentials);
        }

        public async Task<DmsDocument> GetDocumentDetails(string searchStringOrPath)
        {
            if (string.IsNullOrWhiteSpace(searchStringOrPath)) throw new ArgumentNullException(nameof(searchStringOrPath));

            var (settings, dbSettings, credentials, iWorkSiteManager, _, containerId) = await GetAllComponents(searchStringOrPath);

            var document = new DmsDocument();

            return await RefreshTokenOnExpire(async force =>
            {
                if (await iWorkSiteManager.Connect(dbSettings, credentials.UserName, credentials.Password, force))
                {
                    iWorkSiteManager.SetSettings(settings);
                    document = await iWorkSiteManager.GetDocumentById(containerId);
                    var documents = (await iWorkSiteManager.GetRelatedDocuments(containerId))
                                    .GroupBy(v => v.Id)
                                    .Select(group => group.First());

                    document.RelatedDocuments.AddRange(documents);
                }

                return document;
            }, dbSettings, credentials);
        }

        public async Task<DownloadDocumentResponse> Download(string searchStringOrPath)
        {
            if (string.IsNullOrWhiteSpace(searchStringOrPath)) throw new ArgumentNullException(nameof(searchStringOrPath));
            try
            {
                var (settings, dbSettings, credentials, iWorkSiteManager, _, containerId) = await GetAllComponents(searchStringOrPath);

                return await RefreshTokenOnExpire(async force =>
                {
                    if (await iWorkSiteManager.Connect(dbSettings, credentials.UserName, credentials.Password, force))
                    {
                        iWorkSiteManager.SetSettings(settings);
                        var download = await iWorkSiteManager.DownloadDocument(containerId);
                        download.ContentType = ResolveContentType(download.ApplicationName);

                        return download;
                    }

                    return null;
                }, dbSettings, credentials);
            }
            catch (OAuth2TokenException)
            {
                throw;
            }
            catch (Exception ex)
            {
                _log.Exception(ex);
            }

            return null;
        }

        async Task<T> RefreshTokenOnExpire<T>(Func<bool, Task<T>> action, IManageSettings.SiteDatabaseSettings setting, DmsCredential credentials, bool retry = true)
        {
            try
            {
                return await action(!retry);
            }
            catch (CachedTokenExpiredException)
            {
                if (retry)
                {
                    if (setting.IsOAuth2Enabled)
                    {
                        await _accessTokenManager.RefreshAccessToken(credentials.UserName, setting);
                    }

                    return await RefreshTokenOnExpire(action, setting, credentials, false);
                }

                throw;
            }
        }

        async Task<IEnumerable<DmsFolder>> GetFolders(SearchType searchType, string searchString, string nameType, IManageTestSettings testSettings = null)
        {
            var allFolders = new List<DmsFolder>();

            var setting = testSettings != null ? testSettings.Settings : await _dmsSettingsProvider.Provide() as IManageSettings;
            var testModeBypassOAuthErrors = testSettings != null; // review in DR-61466;

            if (setting == null || !setting.Databases.Any() || setting.Disabled)
            {
                _dmsEventEmitter.Emit(new DocumentManagementEvent { Status = Status.Error, Key = KnownDocumentManagementEvents.IncompleteConfiguration });
                throw new DmsConfigurationException("setting");
            }

            foreach (var dbSettings in setting.Databases)
            {
                var credentials = await _credentialsResolver.Resolve(dbSettings);
                await TryServer(async () =>
                {

                    var iWorkSiteManager = _workSiteManagerFactory.GetWorkSiteManager(dbSettings);

                    allFolders.AddRange(await RefreshTokenOnExpire(async force =>
                    {
                        var username = dbSettings.IsOAuth2Enabled ? credentials.UserName : testSettings?.UserName;
                        var password = dbSettings.IsOAuth2Enabled ? credentials.Password : testSettings?.Password;
                        if (await iWorkSiteManager.Connect(dbSettings, 
                                                           username ?? credentials.UserName, 
                                                           password ?? credentials.Password, force))
                        {
                            iWorkSiteManager.SetSettings(setting);
                            var folders = (await iWorkSiteManager.GetTopFolders(searchType, searchString, nameType))
                                          .GroupBy(v => v.Id)
                                          .Select(group => group.First());
                            return folders;
                        }

                        return new DmsFolder[0];
                    }, dbSettings, credentials));
                }, testModeBypassOAuthErrors);
            }

            return allFolders;
        }

        async Task TryServer(Func<Task> action, bool isTestMode = false)
        {
            try
            {
                await action();
            }
            catch (Exception e)
            {
                if (e is OAuth2TokenException)
                {
                    throw;
                }
                _log.Exception(e);
                _dmsEventEmitter.Emit(new DocumentManagementEvent(Status.Error, KnownDocumentManagementEvents.FailedConnection, string.Empty));
            }
        }

        async Task<(IManageSettings settings, IManageSettings.SiteDatabaseSettings dbSettings, DmsCredential credentials, IWorkSiteManager iWorkSiteManager, string SiteDbId, string containerId)> GetAllComponents(string searchStringOrPath)
        {
            var arg = SplitSearchStringOrPath(searchStringOrPath);
            var settings = await _dmsSettingsProvider.Provide() as IManageSettings;
            var dbSettings = settings?.Databases.SingleOrDefault(d => d.SiteDbId == arg.SiteDbId);
            if (dbSettings == null) throw new ArgumentNullException(nameof(dbSettings));
            var credentials = await _credentialsResolver.Resolve(dbSettings);
            var iWorkSiteManager = _workSiteManagerFactory.GetWorkSiteManager(dbSettings);

            return (settings, dbSettings, credentials, iWorkSiteManager, arg.SiteDbId, arg.ContainerId);
        }

        static (string SiteDbId, string ContainerId) SplitSearchStringOrPath(string searchStringOrPath)
        {
            var args = searchStringOrPath.Split('-');
            if (args.Length != 2) throw new ArgumentException("searchStringOrPath not in the required format");

            return (args[0], args[1]);
        }

        static string ResolveContentType(string applicationName)
        {
            if (string.IsNullOrWhiteSpace(applicationName)) throw new ArgumentNullException(nameof(applicationName));

            var mapping = new Dictionary<string, string>
            {
                {"ACROBAT", "application/pdf"},
                {"EXCEL", "application/vnd.ms-excel"},
                {"MIME", "application/vnd.ms-outlook"},
                {"PPT", "application/vnd.ms-powerpoint"},
                {"WORD", "application/msword"}
            };

            return mapping.Get(applicationName.Trim()) ?? "application/octet-stream";
        }
    }
}