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

namespace Inprotech.Integration.DmsIntegration.Component.iManage.v10.v2
{
    public class WorkSiteManager : IWorkSiteManager
    {
        static readonly ConcurrentDictionary<string, string> LifeTimeDictionaryAuthor = new ConcurrentDictionary<string, string>();
        static readonly ConcurrentDictionary<string, string> LifeTimeDictionaryClass = new ConcurrentDictionary<string, string>();
        readonly IAccessTokenManager _accessTokenManager;
        readonly IDmsEventEmitter _dmsEventEmitter;
        readonly IWorkServerClient _workServerClient;
        IManageSettings.SiteDatabaseSettings _dbSettings;

        IManageSettings _settings;

        public WorkSiteManager(IWorkServerClient workServerClient, IDmsEventEmitter dmsEventEmitter, IAccessTokenManager accessTokenManager)
        {
            _workServerClient = workServerClient;
            _dmsEventEmitter = dmsEventEmitter;
            _accessTokenManager = accessTokenManager;
        }

        public async Task<bool> Connect(IManageSettings.SiteDatabaseSettings settings, string username, string password, bool force = false)
        {
            if (string.IsNullOrWhiteSpace(username))
            {
                _dmsEventEmitter.Emit(new DocumentManagementEvent {Key = KnownDocumentManagementEvents.MissingLoginPreference, Status = Status.Error});
                throw new ArgumentException(nameof(username));
            }

            _dbSettings = settings ?? throw new ArgumentNullException(nameof(settings));
            return await _workServerClient.Connect(_dmsEventEmitter, settings, username, password, _accessTokenManager, force);
        }

        public async Task Disconnect()
        {
            await _workServerClient.Logout(_dbSettings.ServerUrl());
        }

        public void SetSettings(IManageSettings settings)
        {
            _settings = settings ?? throw new ArgumentNullException(nameof(settings));
        }

        public async Task<IEnumerable<DmsFolder>> GetTopFolders(SearchType searchType, string searchString, string nameType)
        {
            if (string.IsNullOrWhiteSpace(searchString)) throw new ArgumentNullException(nameof(searchString));
            if (!Enum.IsDefined(typeof(SearchType), searchType)) throw new InvalidEnumArgumentException(nameof(searchType), (int) searchType, typeof(SearchType));

            var uri = Build($"libraries/{_dbSettings.Database}/workspaces/search");
            var folders = new List<DmsFolder>();
            foreach (var database in _dbSettings.Databases)
            {
                var parameters = PopulateParameters(searchType, searchString, nameType, database);
                var r = await _workServerClient.Send(HttpMethod.Post, $"GetFoldersByDataBase:{database}", uri, parameters);
                if (string.IsNullOrWhiteSpace(r.Data)) continue;

                var data = JObject.Parse(r.Data)["data"];
                var resultData = FromDataOrResults(data);

                if (resultData != null && resultData.HasValues)
                {
                    var subclass = searchType == SearchType.ByCaseReference ? _settings.Case.SubClass : _settings.FindSubclassByNameType(nameType);
                    foreach (var i in resultData.AsJEnumerable())
                    {
                        if (!string.IsNullOrEmpty(subclass))
                        {
                            var resultSubclass = (string) i["subclass"];
                            if (resultSubclass != subclass) continue;
                        }

                        var workspaceFolder = new DmsFolder
                        {
                            Id = Id((string) i["id"]),
                            ContainerId = (string) i["id"],
                            Database = (string) i["database"],
                            SiteDbId = _dbSettings.SiteDbId,
                            FolderType = FolderType.Workspace,
                            Name = (string) i["name"],
                            HasChildFolders = (bool) i["has_subfolders"],
                            SubClass = (string) i["sub_class"],
                            Iwl = new Uri((string) i["iwl"])
                        };

                        folders.Add(workspaceFolder);

                        _dmsEventEmitter.Emit(searchType == SearchType.ByCaseReference
                                                  ? new DocumentManagementEvent(Status.Info, KnownDocumentManagementEvents.CaseWorkspace, workspaceFolder.Name)
                                                  : new DocumentManagementEvent(Status.Info, KnownDocumentManagementEvents.NameWorkspace, workspaceFolder.Name, nameType));
                    }
                }
            }

            return folders;
        }

        public async Task<IEnumerable<DmsFolder>> GetSubFolders(string containerId, FolderType folderType, bool fetchChild)
        {
            var id = containerId.Substring(containerId.IndexOf('!') + 1);
            var db = containerId.Substring(0, containerId.IndexOf('!'));
            var sudoFolder = new DmsFolder
            {
                ContainerId = containerId,
                Database = db,
                Id = int.Parse(id)
            };

            await ResolveSubFolders(sudoFolder, folderType, fetchChild);

            return sudoFolder.ChildFolders;
        }

        public async Task<DmsDocumentCollection> GetDocuments(string folderContainerId, FolderType folderType, CommonQueryParameters qp = null)
        {
            if (string.IsNullOrWhiteSpace(folderContainerId)) throw new ArgumentNullException(nameof(folderContainerId));

            if (folderType == FolderType.SearchFolder)
            {
                return await GetSearchFolderDocuments(folderContainerId, qp);
            }

            var db = folderContainerId.Substring(0, folderContainerId.IndexOf('!'));

            var path = qp != null
                ? $"libraries/{db}/folders/{folderContainerId}/documents?offset={qp.Skip}&limit={qp.Take}&total=true"
                : $"libraries/{db}/folders/{folderContainerId}/documents";

            var uri = Build(path);
            var r = await _workServerClient.Send(HttpMethod.Get, "GetDocuments", uri);

            if (string.IsNullOrWhiteSpace(r.Data)) return new DmsDocumentCollection {DmsDocuments = new DmsDocument[0], TotalCount = 0};

            var allDocuments = new List<DmsDocument>();

            foreach (var i in JObject.Parse(r.Data)["data"])
            {
                var document = FromDocumentResponse((JObject) i);

                allDocuments.Add(document);
            }

            var count = (JValue) JObject.Parse(r.Data)["total_count"] == null ? 0 : ((JValue) JObject.Parse(r.Data)["total_count"]).ToObject<short>();

            return new DmsDocumentCollection {DmsDocuments = allDocuments, TotalCount = count};
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
            var uri = Build($"libraries/{_dbSettings.Database}/documents/{containerId}/download");

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

        public async Task<IEnumerable<DmsDocument>> GetRelatedDocuments(string containerId)
        {
            if (string.IsNullOrWhiteSpace(containerId)) throw new ArgumentNullException(nameof(containerId));

            var relatedDocuments = new List<DmsDocument>();

            var uri = Build($"libraries/{_dbSettings.Database}/documents/{containerId}/related-documents");
            var r = await _workServerClient.Send(HttpMethod.Get, "PopulateRelatedDocuments", uri);

            foreach (var i in JObject.Parse(r.Data)["data"])
            {
                var doc = FromDocumentResponse((JObject) i);

                if (string.IsNullOrWhiteSpace(doc.DocTypeDescription) || string.IsNullOrWhiteSpace(doc.AuthorFullName))
                {
                    relatedDocuments.Add(await GetDocumentById(doc.ContainerId));
                    continue;
                }

                relatedDocuments.Add(FromDocumentResponse((JObject) i));
            }

            return relatedDocuments;
        }

        public async Task<DmsDocument> GetDocumentById(string containerId)
        {
            var uri = Build($"libraries/{_dbSettings.Database}/documents/{containerId}");
            var r = await _workServerClient.Send(HttpMethod.Get, "GetDocumentById", uri);

            return FromDocumentResponse((JObject) JObject.Parse(r.Data)["data"]);
        }

        JToken FromDataOrResults(JToken data)
        {
            var resultType = data.GetType();
            return resultType.Name == "JArray" ? data : data["results"];
        }

        async Task<DmsDocumentCollection> GetSearchFolderDocuments(string folderContainerId, CommonQueryParameters qp)
        {
            var uri = Build($"libraries/{_dbSettings.Database}/folders/{folderContainerId}/children/browse");
            var r = await _workServerClient.Send(HttpMethod.Post, "GetDocuments", uri, PopulateSearchFolderParameters());

            if (string.IsNullOrWhiteSpace(r.Data)) return new DmsDocumentCollection {DmsDocuments = new DmsDocument[0], TotalCount = 0};

            var allDocuments = new List<DmsDocument>();
            JToken data = JObject.Parse(r.Data)["data"];
            var total = data.Count();

            foreach (var i in data.Skip(qp.Skip ?? 0).Take(qp.Take ?? total))
            {
                var document = FromDocumentResponse((JObject) i);
                allDocuments.Add(document);
            }

            return new DmsDocumentCollection {DmsDocuments = allDocuments, TotalCount = total};
        }

        WorkspaceSearchParameter PopulateParameters(SearchType searchType, string searchString, string nameType, string database)
        {
            var parameters = new WorkspaceSearchParameter
            {
                ProfileFields =
                {
                    Workspace = new List<string> {"name", "custom1", "custom2", "has_subfolders", "database", "iwl"}
                },
                Filters =
                {
                    Libraries = database
                }
            };

            if (searchType == SearchType.ByCaseReference)
            {
                if (!string.IsNullOrWhiteSpace(_settings.Case.SubClass))
                {
                    parameters.ProfileFields.Workspace.AddRange(new List<string> {"subclass", "subclass_description"});
                }

                var caseElement = _settings.Case;
                if (!string.IsNullOrEmpty(caseElement.SubClass))
                {
                    parameters.Filters.SubClass = caseElement.SubClass;
                    _dmsEventEmitter.Emit(new DocumentManagementEvent(Status.Info, KnownDocumentManagementEvents.CaseSubClass, caseElement.SubClass));
                }

                switch (caseElement.SearchField)
                {
                    case IManageSettings.SearchFields.CustomField1:
                        parameters.Filters.Custom1 = searchString;
                        _dmsEventEmitter.Emit(new DocumentManagementEvent(Status.Info, KnownDocumentManagementEvents.CaseWorkspaceCustomField1, searchString));
                        break;
                    case IManageSettings.SearchFields.CustomField2:
                        parameters.Filters.Custom2 = searchString;
                        _dmsEventEmitter.Emit(new DocumentManagementEvent(Status.Info, KnownDocumentManagementEvents.CaseWorkspaceCustomField2, searchString));
                        break;
                    case IManageSettings.SearchFields.CustomField3:
                        parameters.Filters.Custom3 = searchString;
                        _dmsEventEmitter.Emit(new DocumentManagementEvent(Status.Info, KnownDocumentManagementEvents.CaseWorkspaceCustomField3, searchString));
                        break;
                    case IManageSettings.SearchFields.CustomField1And2:
                        var searchStrings = searchString.Split('.');
                        if (searchStrings.Length != 2)
                        {
                            throw new DmsConfigurationException(string.Format(KnownErrors.ErrorInvalidSearchStringForCustom1And2Configuration, searchString));
                        }

                        parameters.Filters.Custom1 = searchStrings[0];
                        parameters.Filters.Custom2 = searchStrings[1];
                        _dmsEventEmitter.Emit(new DocumentManagementEvent(Status.Info, KnownDocumentManagementEvents.CaseWorkspaceCustomField1, searchStrings[0]));
                        _dmsEventEmitter.Emit(new DocumentManagementEvent(Status.Info, KnownDocumentManagementEvents.CaseWorkspaceCustomField2, searchStrings[1]));
                        break;
                }
            }
            else
            {
                var subclass = _settings.FindSubclassByNameType(nameType);
                if (!string.IsNullOrWhiteSpace(subclass))
                {
                    parameters.ProfileFields.Workspace.AddRange(new List<string> {"subclass", "subclass_description"});
                    parameters.Filters.SubClass = subclass;
                    _dmsEventEmitter.Emit(new DocumentManagementEvent(Status.Info, KnownDocumentManagementEvents.NameSubClass, subclass, nameType));
                }

                _dmsEventEmitter.Emit(new DocumentManagementEvent(Status.Info, KnownDocumentManagementEvents.NameWorkspaceCustomField1, searchString, nameType));

                parameters.Filters.Custom1 = searchString;
            }

            return parameters;
        }

        dynamic PopulateSearchFolderParameters()
        {
            return new
            {
                profile_fields = new
                {
                    document = new[] {"version", "document_number", "is_in_use", "in_use_by", "in_use_by_description", "edit_date", "create_date", "file_edit_date", "file_create_date", "size", "iwl", "is_declared", "database", "author", "author_description", "class", "class_description", "is_checked_out", "checkout_date", "last_user", "last_user_description", "id", "name", "extension", "wstype", "type", "received_date", "sent_date", "subject", "from", "to", "conversation_id", "conversation_name", "conversation_count", "has_attachment"},
                    folder = new[] {"owner", "owner_description", "database", "edit_date", "id", "name", "folder_type", "wstype", "has_documents", "has_subfolders", "parent_id", "view_type", "category_type", "workspace_id", "workspace_name"}
                }
            };
        }

        async Task ResolveSubFolders(DmsFolder parentFolder, FolderType selectedFolderType, bool recursive)
        {
            var path = selectedFolderType == FolderType.Workspace
                ? $"libraries/{parentFolder.Database}/workspaces/{parentFolder.ContainerId}/children"
                : $"libraries/{parentFolder.Database}/folders/{parentFolder.ContainerId}/children";

            var uri = Build(path);
            var r = await _workServerClient.Send(HttpMethod.Get, "GetSubFolders", uri);

            if (string.IsNullOrWhiteSpace(r.Data)) return;

            foreach (var i in JObject.Parse(r.Data)["data"])
            {
                var folderType = (string) i["folder_type"];
                if (string.IsNullOrWhiteSpace(folderType))
                {
                    continue;
                }

                var childFolder = parentFolder.AddChildFolder(new DmsFolder
                {
                    Id = Id((string) i["id"]),
                    ContainerId = (string) i["id"],
                    Database = (string) i["database"],
                    Name = (string) i["name"],
                    HasDocuments = (bool) i["has_documents"],
                    HasChildFolders = (bool) i["has_subfolders"],
                    FolderType = FolderTypeMap.Map(folderType, (string) i["email"]),
                    SubClass = (string) i["sub_class"],
                    SiteDbId = _dbSettings.SiteDbId,
                    ParentId = (string) i["parent_id"]
                });

                if (recursive && childFolder.HasChildFolders)
                {
                    await ResolveSubFolders(childFolder, childFolder.FolderType, true);
                }
            }
        }

        DmsDocument FromDocumentResponse(JObject i)
        {
            if (!string.IsNullOrWhiteSpace((string) i["author"]))
            {
                LifeTimeDictionaryAuthor.TryAdd((string) i["author"], (string) i["author_description"]);
            }

            if (!string.IsNullOrWhiteSpace((string) i["class"]))
            {
                LifeTimeDictionaryClass.TryAdd((string) i["class"], (string) i["class_description"]);
            }

            return new DmsDocument
            {
                SiteDbId = _dbSettings.SiteDbId,
                ContainerId = (string) i["id"],
                Id = (int) i["document_number"],
                Database = (string) i["database"],
                Description = (string) i["name"],
                Version = (int) i["version"],
                Size = (int) i["size"],
                DateCreated = (DateTime?) i["create_date"],
                DateEdited = (DateTime?) i["edit_date"],
                DocTypeName = (string) i["class"],
                DocTypeDescription = (string) i["class_description"] ?? (LifeTimeDictionaryClass.TryGetValue((string) i["class"] ?? string.Empty, out var _class) ? _class : null),
                AuthorInitials = (string) i["author"],
                AuthorFullName = (string) i["author_description"] ?? (LifeTimeDictionaryAuthor.TryGetValue((string) i["author"] ?? string.Empty, out var author) ? author : null),
                ApplicationExtension = (string) i["extension"],
                ApplicationName = (string) i["type"],
                ApplicationDescription = (string) i["type_description"],
                Comment = (string) i["comment"],
                SubClass = (string) i["sub_class"],
                HasAttachments = ((bool?) i["has_attachment"]).GetValueOrDefault(),
                HasRelatedDocuments = ((bool?) i["is_related"]).GetValueOrDefault(),
                EmailFrom = (string) i["from"], //TODO ADD
                EmailTo = (string) i["to"],
                EmailCc = (string) i["cc"],
                EmailDateSent = (DateTime?) i["sent_date"],
                EmailDateReceived = (DateTime?) i["received_date"],
                Iwl = new Uri((string) i["iwl"])
            };
        }

        List<DmsDocument> ClientFilter(List<DmsDocument> allDocuments, CommonQueryParameters qp)
        {
            if (qp == null) return allDocuments;

            return allDocuments.Skip(qp.Skip ?? 0).Take(qp.Take ?? allDocuments.Count).ToList();
        }

        Uri Build(string path)
        {
            return new Uri(_dbSettings.ServerUrl(), $"work/api/v2/customers/{_dbSettings.CustomerId}/{path}");
        }

        static int Id(string containerId)
        {
            return int.Parse(containerId.Split('!')[1]);
        }
    }
}