using System;
using System.Collections.Concurrent;
using System.Collections.Generic;
using System.ComponentModel;
using System.Linq;
using System.Net.Http;
using System.Threading.Tasks;
using Inprotech.Infrastructure.Extensions;
using Inprotech.Infrastructure.Web;
using Inprotech.Integration.DmsIntegration.Component.Domain;
using Newtonsoft.Json.Linq;

namespace Inprotech.Integration.DmsIntegration.Component.iManage.v10.v1
{
    public class WorkSiteManager : IWorkSiteManager
    {
        const string NameDefaultSubtype = "work";
        static readonly ConcurrentDictionary<string, string> LifeTimeDictionaryAuthor = new ConcurrentDictionary<string, string>();
        static readonly ConcurrentDictionary<string, string> LifeTimeDictionaryClass = new ConcurrentDictionary<string, string>();
        readonly IDmsEventEmitter _dmsEventEmitter;
        readonly IWorkServerClient _workServerClient;
        IManageSettings.SiteDatabaseSettings _dbSettings;
        IManageSettings _settings;

        public WorkSiteManager(IWorkServerClient workServerClient, IDmsEventEmitter dmsEventEmitter)
        {
            _workServerClient = workServerClient;
            _dmsEventEmitter = dmsEventEmitter;
        }

        public void SetSettings(IManageSettings settings)
        {
            _settings = settings ?? throw new ArgumentNullException(nameof(settings));
        }

        public async Task<bool> Connect(IManageSettings.SiteDatabaseSettings settings, string username, string password, bool force = false)
        {
            if (string.IsNullOrWhiteSpace(username))
            {
                _dmsEventEmitter.Emit(new DocumentManagementEvent { Key = KnownDocumentManagementEvents.MissingLoginPreference, Status = Status.Error });
                throw new ArgumentException(nameof(username));
            }

            _dbSettings = settings ?? throw new ArgumentNullException(nameof(settings));
            return await _workServerClient.Connect(_dmsEventEmitter, settings, username, password, null, force);
        }

        public async Task Disconnect()
        {
            await _workServerClient.Logout(_dbSettings.ServerUrl());
        }

        public async Task<IEnumerable<DmsFolder>> GetTopFolders(SearchType searchType, string searchString, string nameType)
        {
            if (string.IsNullOrWhiteSpace(searchString)) throw new ArgumentNullException(nameof(searchString));
            if (!Enum.IsDefined(typeof(SearchType), searchType)) throw new InvalidEnumArgumentException(nameof(searchType), (int)searchType, typeof(SearchType));

            var folders = new List<DmsFolder>();

            var customFields = PopulateParameters(searchType, searchString, nameType);
            foreach (var database in _dbSettings.Databases)
            {
                var uri = new Uri(_dbSettings.ServerUrl() +
                                  $"api/v1/workspaces/search?scope={database}{customFields}");

                var r = await _workServerClient.Send(HttpMethod.Get, $"GetFoldersByDataBase:{database}", uri);
                if (string.IsNullOrWhiteSpace(r.Data)) continue;

                var folderSubTypeFilter = searchType == SearchType.ByCaseReference ? _settings.Case.SubType : NameDefaultSubtype;

                foreach (var i in JObject.Parse(r.Data)["data"])
                {
                    if (!string.IsNullOrEmpty(folderSubTypeFilter))
                    {
                        var resultSubtype = (string)i["subtype"];
                        if (resultSubtype != folderSubTypeFilter) continue;
                    }

                    var workspaceFolder = new DmsFolder
                    {
                        Id = Id((string)i["id"]),
                        ContainerId = (string)i["id"],
                        Database = (string)i["database"],
                        SiteDbId = _dbSettings.SiteDbId,
                        FolderType = FolderType.Workspace,
                        Name = (string)i["name"],
                        HasChildFolders = (bool)i["has_subfolders"],
                        SubClass = (string)i["sub_class"],
                        CanHaveRelatedDocuments = false,
                        Iwl = string.IsNullOrWhiteSpace((string)i["iwl"]) ? null : new Uri((string)i["iwl"])
                    };

                    folders.Add(workspaceFolder);

                    _dmsEventEmitter.Emit(searchType == SearchType.ByCaseReference
                                              ? new DocumentManagementEvent(Status.Info, KnownDocumentManagementEvents.CaseWorkspace, workspaceFolder.Name)
                                          : new DocumentManagementEvent(Status.Info, KnownDocumentManagementEvents.NameWorkspace, workspaceFolder.Name, nameType));
                }
            }

            return folders;
        }

        public async Task<DmsDocumentCollection> GetDocuments(string folderContainerId, FolderType folderType, CommonQueryParameters qp = null)
        {
            if (string.IsNullOrWhiteSpace(folderContainerId)) throw new ArgumentNullException(nameof(folderContainerId));

            var db = folderContainerId.Substring(0, folderContainerId.IndexOf('!'));

            var uri = new Uri(_dbSettings.ServerUrl() +
                              $"api/v1/folders/{folderContainerId}/documents?scope={db}");
            if (qp != null)
            {
                uri = new Uri(_dbSettings.ServerUrl() +
                                 $"api/v1/folders/{folderContainerId}/documents?scope={db}&offset={qp.Skip}&limit={qp.Take}&total=true");
            }
            var r = await _workServerClient.Send(HttpMethod.Get, "GetDocuments", uri);

            if (string.IsNullOrWhiteSpace(r.Data))
                return new DmsDocumentCollection()
                {
                    DmsDocuments = new DmsDocument[0]
                };

            var allDocuments = new List<DmsDocument>();

            foreach (var i in JObject.Parse(r.Data)["data"])
            {
                /* Not required
                var wsType = (string)i["wstype"];
                if (wsType != "document" && wsType != "email") continue;
            */
                var document = FromDocumentResponse((JObject)i);
                document.ProfileLoaded = true;

                allDocuments.Add(document);
            }

            var count = (JValue)JObject.Parse(r.Data)["total_count"] == null ? 0 : ((JValue)JObject.Parse(r.Data)["total_count"]).ToObject<Int16>();

            return new DmsDocumentCollection
            {
                DmsDocuments = allDocuments,
                TotalCount = count
            };
        }

        public async Task<DownloadDocumentResponse> DownloadDocument(string containerId)
        {
            if (string.IsNullOrWhiteSpace(containerId)) throw new ArgumentNullException(nameof(containerId));

            var args = containerId.Split('.');
            if (args.Length != 2)
            {
                throw new Exception(nameof(containerId));
            }

            var dmsDocument = await GetDocumentById(containerId);
            var uri = new Uri(_dbSettings.ServerUrl() + $"api/v1/documents/{containerId}/download");

            return new DownloadDocumentResponse
            {
                FileName = $"{dmsDocument.Description.Truncate(20)}.{dmsDocument.ApplicationExtension}",
                ApplicationName = dmsDocument.ApplicationName,
                DocumentData = (await _workServerClient.Download("DownloadDocument", uri)).Data
            };
        }

        public void Dispose()
        {
        }

        public Task<IEnumerable<DmsDocument>> GetRelatedDocuments(string containerId)
        {
            return Task.FromResult(Enumerable.Empty<DmsDocument>());
        }

        public async Task<DmsDocument> GetDocumentById(string containerId)
        {
            var uri = new Uri(_dbSettings.ServerUrl() + $"api/v1/documents/{containerId}");
            var r = await _workServerClient.Send(HttpMethod.Get, "GetDocumentById", uri);

            return FromDocumentResponse((JObject)JObject.Parse(r.Data)["data"]);
        }

        public async Task<IEnumerable<DmsFolder>> GetSubFolders(string containerId, FolderType folderType, bool fetchChild)
        {
            var id = containerId.Substring(containerId.IndexOf('!') + 1);
            var db = containerId.Substring(0, containerId.IndexOf('!'));
            var sudoFolder = new DmsFolder
            {
                ContainerId = containerId,
                Database = db,
                Id = int.Parse(id),
                CanHaveRelatedDocuments = false
            };

            await ResolveSubFolders(sudoFolder, true);

            return sudoFolder.ChildFolders;
        }

        string PopulateParameters(SearchType searchType, string searchString, string nameType)
        {
            var customFields = string.Empty;
            if (searchType == SearchType.ByCaseReference)
            {
                var caseElement = _settings.Case;
                switch (caseElement.SearchField)
                {
                    case IManageSettings.SearchFields.CustomField1:
                        customFields = $"&custom1={searchString}";
                        _dmsEventEmitter.Emit(new DocumentManagementEvent(Status.Info, KnownDocumentManagementEvents.CaseWorkspaceCustomField1, searchString));
                        break;
                    case IManageSettings.SearchFields.CustomField2:
                        customFields = $"&custom2={searchString}";
                        _dmsEventEmitter.Emit(new DocumentManagementEvent(Status.Info, KnownDocumentManagementEvents.CaseWorkspaceCustomField2, searchString));
                        break;
                    case IManageSettings.SearchFields.CustomField3:
                        customFields = $"&custom3={searchString}";
                        _dmsEventEmitter.Emit(new DocumentManagementEvent(Status.Info, KnownDocumentManagementEvents.CaseWorkspaceCustomField3, searchString));
                        break;
                    case IManageSettings.SearchFields.CustomField1And2:
                        var searchStrings = searchString.Split('.');
                        if (searchStrings.Length != 2)
                        {
                            throw new DmsConfigurationException(string.Format(KnownErrors.ErrorInvalidSearchStringForCustom1And2Configuration, searchString));
                        }

                        customFields = $"&custom1={searchStrings[0]}&custom2={searchStrings[1]}";
                        _dmsEventEmitter.Emit(new DocumentManagementEvent(Status.Info, KnownDocumentManagementEvents.CaseWorkspaceCustomField1, searchStrings[0]));
                        _dmsEventEmitter.Emit(new DocumentManagementEvent(Status.Info, KnownDocumentManagementEvents.CaseWorkspaceCustomField2, searchStrings[1]));
                        break;
                }

                if (!string.IsNullOrEmpty(caseElement.SubClass))
                {
                    customFields += $"&subclass={caseElement.SubClass}";
                    _dmsEventEmitter.Emit(new DocumentManagementEvent(Status.Info, KnownDocumentManagementEvents.CaseSubClass, caseElement.SubClass));
                }
            }
            else
            {
                customFields = $"&custom1={searchString}";
                _dmsEventEmitter.Emit(new DocumentManagementEvent(Status.Info, KnownDocumentManagementEvents.NameWorkspaceCustomField1, searchString, nameType));
                var subclass = _settings.FindSubclassByNameType(nameType);
                if (!string.IsNullOrEmpty(subclass))
                {
                    customFields += $"&subclass={subclass}";
                    _dmsEventEmitter.Emit(new DocumentManagementEvent(Status.Info, KnownDocumentManagementEvents.NameSubClass, subclass, nameType));
                }
            }

            return customFields;
        }

        async Task ResolveSubFolders(DmsFolder parentFolder, bool recursive)
        {
            var uri = new Uri(_dbSettings.ServerUrl() +
                              $"api/v1/workspaces/{parentFolder.ContainerId}/children?scope={_dbSettings.Database}");
            var r = await _workServerClient.Send(HttpMethod.Get, "GetSubFolders", uri);

            if (string.IsNullOrWhiteSpace(r.Data)) return;

            foreach (var i in JObject.Parse(r.Data)["data"])
            {
                var folderType = (string)i["folder_type"];
                if (string.IsNullOrWhiteSpace(folderType))
                {
                    continue;
                }

                var childFolder = parentFolder.AddChildFolder(new DmsFolder
                {
                    Id = Id((string)i["id"]),
                    ContainerId = (string)i["id"],
                    Database = (string)i["database"],
                    Name = (string)i["name"],
                    HasDocuments = (bool)i["has_documents"],
                    HasChildFolders = (bool)i["has_subfolders"],
                    FolderType = FolderTypeMap.Map(folderType, (string)i["email"]),
                    SubClass = (string)i["sub_class"],
                    CanHaveRelatedDocuments = false,
                    SiteDbId = _dbSettings.SiteDbId,
                    Iwl = string.IsNullOrWhiteSpace((string)i["iwl"]) ? null : new Uri((string)i["iwl"])
                });

                if (recursive && childFolder.HasChildFolders)
                {
                    await ResolveSubFolders(childFolder, true);
                }
            }
        }

        DmsDocument FromDocumentResponse(JObject i)
        {
            if (!string.IsNullOrWhiteSpace((string)i["author"]))
            {
                LifeTimeDictionaryAuthor.TryAdd((string)i["author"], (string)i["author_description"]);
            }

            if (!string.IsNullOrWhiteSpace((string)i["class"]))
            {
                LifeTimeDictionaryClass.TryAdd((string)i["class"], (string)i["class_description"]);
            }

            return new DmsDocument
            {
                SiteDbId = _dbSettings.SiteDbId,
                ContainerId = (string)i["id"],
                Id = (int)i["document_number"],
                Database = (string)i["database"],
                Description = (string)i["name"],
                Version = (int)i["version"],
                Size = (int)i["size"],
                DateCreated = (DateTime?)i["create_date"],
                DateEdited = (DateTime?)i["edit_date"],
                DocTypeName = (string)i["class"],
                DocTypeDescription = (string)i["class_description"] ?? (LifeTimeDictionaryClass.TryGetValue((string)i["class"] ?? string.Empty, out var _class) ? _class : null),
                AuthorInitials = (string)i["author"],
                AuthorFullName = (string)i["author_description"] ?? (LifeTimeDictionaryAuthor.TryGetValue((string)i["author"] ?? string.Empty, out var author) ? author : null),
                ApplicationExtension = (string)i["extension"],
                ApplicationName = (string)i["type"],
                ApplicationDescription = (string)i["type_description"],
                Comment = (string)i["comment"],
                SubClass = (string)i["sub_class"],
                HasAttachments = ((bool?)i["has_attachment"]).GetValueOrDefault(),
                HasRelatedDocuments = ((bool?)i["is_related"]).GetValueOrDefault(),
                EmailFrom = (string)i["from"],
                EmailTo = (string)i["to"],
                EmailCc = (string)i["cc"],
                EmailDateSent = (DateTime?)i["sent_date"],
                EmailDateReceived = (DateTime?)i["received_date"],
                Iwl = new Uri((string)i["iwl"])
            };
        }

        static int Id(string containerId)
        {
            return int.Parse(containerId.Split('!')[1]);
        }
    }
}