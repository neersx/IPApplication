using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.IO;
using System.Linq;
using System.Runtime.InteropServices;
using System.Threading.Tasks;
using IManage;
using Inprotech.Infrastructure.Web;
using Inprotech.Integration.DmsIntegration.Component.Domain;

namespace Inprotech.Integration.DmsIntegration.Component.iManage.v8
{
    public class WorkSiteManager : IWorkSiteManager
    {
        readonly IDmsEventEmitter _dmsEventEmitter;
        IManageSettings.SiteDatabaseSettings _dbSettings;
        bool _disposed;
        IManDMS _iManDms;
        IManSession _iManSession;
        IManageSettings _settings;

        public WorkSiteManager(IDmsEventEmitter dmsEventEmitter)
        {
            _dmsEventEmitter = dmsEventEmitter;
        }

        bool IsConnected => _iManSession != null && _iManSession.Connected;

        public void SetSettings(IManageSettings settings)
        {
            _settings = settings ?? throw new ArgumentNullException(nameof(settings));
        }

        public Task<bool> Connect(IManageSettings.SiteDatabaseSettings settings, string username, string password, bool force = false)
        {
            _dbSettings = settings ?? throw new ArgumentNullException(nameof(settings));

            _iManDms = new ManDMS();
            _iManSession = _iManDms
                           .Sessions.Add(settings.Server)
                           .Connect(_dmsEventEmitter, _dbSettings, username, password);

            return Task.FromResult(IsConnected);
        }

        public Task Disconnect()
        {
            if (_iManSession != null)
            {
                if (_iManSession.Connected)
                {
                    _iManSession.Logout();
                    _iManDms.Close();
                }

                Marshal.ReleaseComObject(_iManSession);
            }

            if (_iManDms != null)
            {
                _iManDms.Close();
                Marshal.ReleaseComObject(_iManDms);
            }

            _iManSession = null;
            _iManDms = null;
            return Task.FromResult<object>(null);
        }

        public Task<IEnumerable<DmsFolder>> GetTopFolders(SearchType searchType, string searchString, string nameType)
        {
            if (searchString == null) throw new ArgumentNullException(nameof(searchString));
            if (!Enum.IsDefined(typeof(SearchType), searchType)) throw new InvalidEnumArgumentException(nameof(searchType), (int)searchType, typeof(SearchType));
            var all = new List<DmsFolder>();

            foreach (var database in _dbSettings.Databases)
                foreach (var folder in GetFoldersByDatabase(database, searchType, searchString, nameType))
                    all.Add(folder);

            return Task.FromResult<IEnumerable<DmsFolder>>(all);
        }

        public Task<IEnumerable<DmsFolder>> GetSubFolders(string containerId, FolderType folderType, bool fetchChild)
        {
            throw new NotImplementedException();
        }

        public Task<DmsDocumentCollection> GetDocuments(string containerId, FolderType folderType, CommonQueryParameters qp = null)
        {
            if (string.IsNullOrWhiteSpace(containerId)) throw new ArgumentException(@"Value cannot be null or whitespace.", nameof(containerId));

            var db = containerId.Substring(0, containerId.IndexOf('!'));
            var folderId = containerId.Substring(containerId.IndexOf('!') + 1);

            var documents = new List<DmsDocument>();

            var manDatabase = _iManSession.Databases.ItemByName(db);
            var manDBs = new ManStrings();
            manDBs.Add(db);
            var workArea = manDatabase.Session.WorkArea;
            var folderParams = workArea.Session.DMS.CreateFolderSearchParameters();
            folderParams.Add(imFolderAttributeID.imFolderID, folderId);
            var manFolders = workArea.SearchFolders(manDBs, folderParams);
            if (manFolders != null && manFolders.Count == 1)
            {
                var manFolder = manFolders.ItemByIndex(1);
                documents = GetContents(db, manFolder.Contents);
                Marshal.ReleaseComObject(manFolder);
            }

            if (manFolders != null)
            {
                Marshal.ReleaseComObject(manFolders);
            }

            Marshal.ReleaseComObject(folderParams);
            Marshal.ReleaseComObject(workArea);
            Marshal.ReleaseComObject(manDBs);
            Marshal.ReleaseComObject(manDatabase);

            var docs = new DmsDocumentCollection { DmsDocuments = documents, TotalCount = documents?.Count ?? 0 };

            return Task.FromResult(docs);
        }

        public Task<DmsDocument> GetDocumentById(string containerId)
        {
            var db = containerId.Substring(0, containerId.IndexOf('!'));
            var documentIdWithVersion = containerId.Substring(containerId.IndexOf('!') + 1).Split('.');

            DmsDocument document = null;
            var manDatabase = _iManSession.Databases.ItemByName(db);
            var profParams = manDatabase.Session.DMS.CreateProfileSearchParameters();
            profParams.Add(imProfileAttributeID.imProfileDocNum, documentIdWithVersion[0]);
            var iManContents = manDatabase.SearchDocuments(profParams, false);
            if (!iManContents.Empty)
            {
                var iManContent = iManContents.ItemByIndex(1);
                if (iManContent.ObjectType.ObjectType == imObjectType.imTypeDocument)
                {
                    var iManDocument = (IManDocument)iManContent;
                    document = GetDocument(_dbSettings.Database, iManDocument);
                    Marshal.ReleaseComObject(iManDocument);
                }

                Marshal.ReleaseComObject(iManContent);
            }

            Marshal.ReleaseComObject(iManContents);
            Marshal.ReleaseComObject(profParams);
            Marshal.ReleaseComObject(manDatabase);

            return Task.FromResult(document);
        }

        public async Task<IEnumerable<DmsDocument>> GetRelatedDocuments(string containerId)
        {
            if (string.IsNullOrWhiteSpace(containerId)) throw new ArgumentException(@"Value cannot be null or whitespace.", nameof(containerId));
            var db = containerId.Substring(0, containerId.IndexOf('!'));

            var documentIdWithVersion = containerId.Replace(db + '!', string.Empty).Split('.');

            var document = await GetDocument(int.Parse(documentIdWithVersion[0]), db, true);

            var results = new List<DmsDocument>();

            if (!document.HasRelatedDocuments) return results;

            foreach (var t in document.RelatedDocuments) results.Add(await GetDocument(t.Id, db));

            return results;
        }

        public Task<DownloadDocumentResponse> DownloadDocument(string containerId)
        {
            if (string.IsNullOrWhiteSpace(containerId)) throw new ArgumentException(@"Value cannot be null or whitespace.", nameof(containerId));
            var db = containerId.Substring(0, containerId.IndexOf('!'));
            var documentId = containerId.Replace(db + '!', string.Empty);

            var response = new DownloadDocumentResponse();
            var manDatabase = _iManSession.Databases.ItemByName(db);
            var profParams = manDatabase.Session.DMS.CreateProfileSearchParameters();
            profParams.Add(imProfileAttributeID.imProfileDocNum, documentId);
            var iManContents = manDatabase.SearchDocuments(profParams, false);
            if (!iManContents.Empty)
            {
                var iManContent = iManContents.ItemByIndex(1);
                if (iManContent.ObjectType.ObjectType == imObjectType.imTypeDocument)
                {
                    var iManDocument = (IManDocument)iManContent;
                    var fileName = Path.GetTempFileName();
                    iManDocument.GetCopy(fileName, imGetCopyOptions.imNativeFormat);
                    response.FileName = string.Format("{0}.{1}", containerId, iManDocument.Type.ApplicationExtension);
                    response.ApplicationName = iManDocument.Type.Name;
                    Marshal.ReleaseComObject(iManDocument);
                    response.DocumentData = StreamFile(fileName);
                    File.Delete(fileName);
                }

                Marshal.ReleaseComObject(iManContent);
            }

            Marshal.ReleaseComObject(iManContents);
            Marshal.ReleaseComObject(profParams);
            Marshal.ReleaseComObject(manDatabase);

            return Task.FromResult(response);
        }

        public void Dispose()
        {
            Dispose(true);
            GC.SuppressFinalize(this);
        }

        IEnumerable<DmsFolder> GetFoldersByDatabase(string database, SearchType searchType, string searchString, string nameType)
        {
            var folders = new List<DmsFolder>();

            var manDatabase = _iManSession.Databases.ItemByName(database);

            var profParams = manDatabase.Session.DMS.CreateProfileSearchParameters();
            var oWParams = manDatabase.Session.DMS.CreateWorkspaceSearchParameters();

            if (searchType == SearchType.ByCaseReference)
            {
                var caseElement = _settings.Case;
                if (!string.IsNullOrEmpty(caseElement.SubClass))
                {
                    profParams.Add(imProfileAttributeID.imProfileSubClass, caseElement.SubClass);
                    _dmsEventEmitter.Emit(new DocumentManagementEvent(Status.Info, KnownDocumentManagementEvents.CaseSubClass, caseElement.SubClass));
                }

                switch (caseElement.SearchField)
                {
                    case IManageSettings.SearchFields.CustomField1:
                        profParams.Add(imProfileAttributeID.imProfileCustom1, searchString);
                        _dmsEventEmitter.Emit(new DocumentManagementEvent(Status.Info, KnownDocumentManagementEvents.CaseWorkspaceCustomField1, searchString));
                        break;
                    case IManageSettings.SearchFields.CustomField3:
                        profParams.Add(imProfileAttributeID.imProfileCustom3, searchString);
                        _dmsEventEmitter.Emit(new DocumentManagementEvent(Status.Info, KnownDocumentManagementEvents.CaseWorkspaceCustomField3, searchString));
                        break;
                    case IManageSettings.SearchFields.CustomField1And2:
                        var searchStrings = searchString.Split('.');
                        if (searchStrings.Length != 2)
                        {
                            throw new DmsConfigurationException(
                                                                string.Format(KnownErrors.ErrorInvalidSearchStringForCustom1And2Configuration, searchString));
                        }

                        profParams.Add(imProfileAttributeID.imProfileCustom1, searchStrings[0]);
                        profParams.Add(imProfileAttributeID.imProfileCustom2, searchStrings[1]);
                        _dmsEventEmitter.Emit(new DocumentManagementEvent(Status.Info, KnownDocumentManagementEvents.CaseWorkspaceCustomField1, searchString[0].ToString()));
                        _dmsEventEmitter.Emit(new DocumentManagementEvent(Status.Info, KnownDocumentManagementEvents.CaseWorkspaceCustomField2, searchString[1].ToString()));
                        break;
                    default:
                        profParams.Add(imProfileAttributeID.imProfileCustom2, searchString);
                        _dmsEventEmitter.Emit(new DocumentManagementEvent(Status.Info, KnownDocumentManagementEvents.CaseWorkspaceCustomField2, searchString));
                        break;
                }

                if (!string.IsNullOrEmpty(caseElement.SubType))
                {
                    oWParams.Add(imFolderAttributeID.imFolderSubtype, caseElement.SubType);
                    _dmsEventEmitter.Emit(new DocumentManagementEvent(Status.Info, KnownDocumentManagementEvents.CaseSubType, caseElement.SubType));
                }
            }
            else
            {
                var subclass = _settings.FindSubclassByNameType(nameType);
                if (!string.IsNullOrEmpty(subclass))
                {
                    profParams.Add(imProfileAttributeID.imProfileSubClass, subclass);
                    _dmsEventEmitter.Emit(new DocumentManagementEvent(Status.Info, KnownDocumentManagementEvents.NameSubClass, subclass, nameType));
                }

                profParams.Add(imProfileAttributeID.imProfileCustom1, searchString);
                _dmsEventEmitter.Emit(new DocumentManagementEvent(Status.Info, KnownDocumentManagementEvents.NameWorkspaceCustomField1, searchString, nameType));

                oWParams.Add(imFolderAttributeID.imFolderSubtype, "work");
                _dmsEventEmitter.Emit(new DocumentManagementEvent(Status.Info, KnownDocumentManagementEvents.NameSubType, "work", nameType));
            }

            var manFolders = manDatabase.SearchWorkspaces(profParams, oWParams);
            if (!manFolders.Empty)
            {
                for (var iWorkspace = 1; iWorkspace <= manFolders.Count; iWorkspace++)
                {
                    var manFolder = manFolders.ItemByIndex(iWorkspace);
                    var workspaceFolder = new DmsFolder
                    {
                        Id = manFolder.FolderID,
                        ContainerId = $"{database}!{manFolder.FolderID}",
                        SiteDbId = _dbSettings.SiteDbId,
                        Database = database,
                        FolderType = FolderType.Workspace,
                        Name = manFolder.Name
                    };
                    folders.Add(workspaceFolder);
                    workspaceFolder.HasDocuments = !manFolder.Contents.Empty;
                    GetSubFolders(workspaceFolder, manFolder.SubFolders);
                    Marshal.ReleaseComObject(manFolder);

                    _dmsEventEmitter.Emit(searchType == SearchType.ByCaseReference
                                              ? new DocumentManagementEvent(Status.Info, KnownDocumentManagementEvents.CaseWorkspace, workspaceFolder.Name)
                                              : new DocumentManagementEvent(Status.Info, KnownDocumentManagementEvents.NameWorkspace, workspaceFolder.Name, nameType));
                }
            }

            Marshal.ReleaseComObject(profParams);
            Marshal.ReleaseComObject(oWParams);
            Marshal.ReleaseComObject(manFolders);
            Marshal.ReleaseComObject(manDatabase);

            return folders.AsEnumerable();
        }

        public Task<DmsDocument> GetDocument(int documentId, string database, bool addRelatedDocument = false)
        {
            DmsDocument document = null;
            var manDatabase = _iManSession.Databases.ItemByName(database);
            var profParams = manDatabase.Session.DMS.CreateProfileSearchParameters();
            profParams.Add(imProfileAttributeID.imProfileDocNum, documentId.ToString());
            var iManContents = manDatabase.SearchDocuments(profParams, false);
            if (!iManContents.Empty)
            {
                var iManContent = iManContents.ItemByIndex(1);
                if (iManContent.ObjectType.ObjectType == imObjectType.imTypeDocument)
                {
                    var iManDocument = (IManDocument)iManContent;
                    document = GetDocument(database, iManDocument, addRelatedDocument);
                    Marshal.ReleaseComObject(iManDocument);
                }

                Marshal.ReleaseComObject(iManContent);
            }

            Marshal.ReleaseComObject(iManContents);
            Marshal.ReleaseComObject(profParams);
            Marshal.ReleaseComObject(manDatabase);

            return Task.FromResult(document);
        }

        ~WorkSiteManager()
        {
            Dispose(false);
        }

        void GetSubFolders(DmsFolder parentFolder, IManFolders iManFolders)
        {
            if (iManFolders.Empty) return;
            iManFolders.Sort(new SortFolder());
            for (var iSubFolder = 1; iSubFolder <= iManFolders.Count; iSubFolder++)
            {
                var manSubFolder = iManFolders.ItemByIndex(iSubFolder);
                var childFolder = new DmsFolder
                {
                    Id = manSubFolder.FolderID,
                    Database = parentFolder.Database,
                    Name = manSubFolder.Name,
                    ContainerId = $"{parentFolder.Database}!{manSubFolder.FolderID}",
                    SiteDbId = _dbSettings.SiteDbId
                };
                switch (manSubFolder.ObjectType.ObjectType)
                {
                    case imObjectType.imTypeTab:
                        childFolder.FolderType = FolderType.Tab;
                        break;
                    case imObjectType.imTypeDocumentFolder:
                        childFolder.FolderType = FolderType.Folder;
                        break;
                    case imObjectType.imTypeDocumentSearchFolder:
                        childFolder.FolderType = FolderType.SearchFolder;
                        break;
                    default:
                        childFolder.FolderType = FolderType.NotSet;
                        break;
                }

                if (!string.IsNullOrEmpty(manSubFolder.FullEmail))
                {
                    childFolder.FolderType = FolderType.EmailFolder;
                }

                parentFolder.AddChildFolder(childFolder);
                childFolder.HasDocuments = !manSubFolder.Contents.Empty;
                GetSubFolders(childFolder, manSubFolder.SubFolders);
                Marshal.ReleaseComObject(manSubFolder);
            }
        }

        List<DmsDocument> GetContents(string database, IManContents iManContents)
        {
            if (string.IsNullOrWhiteSpace(database)) throw new ArgumentException(@"Value cannot be null or whitespace.", nameof(database));

            var documents = new List<DmsDocument>();
            if (iManContents.Empty) return documents;
            iManContents.Sort(new SortDocument());

            for (var iContent = 1; iContent <= iManContents.Count; iContent++)
            {
                var iManContent = iManContents.ItemByIndex(iContent);
                if (iManContent.ObjectType.ObjectType == imObjectType.imTypeDocument)
                {
                    var iManDocument = (IManDocument)iManContent;
                    documents.Add(GetDocument(database, iManDocument));
                    Marshal.ReleaseComObject(iManDocument);
                }

                Marshal.ReleaseComObject(iManContent);
            }

            return documents;
        }

        DmsDocument GetDocument(string database, IManDocument iManDocument, bool addRelatedDocument = false)
        {
            var document = new DmsDocument
            {
                Id = iManDocument.Number,
                Database = database,
                ContainerId = $"{database}!{iManDocument.Number}",
                Description = iManDocument.Description,
                Version = iManDocument.Version,
                Size = iManDocument.Size,
                DateCreated = iManDocument.CreationDate,
                DateEdited = iManDocument.EditDate,
                DocTypeName = iManDocument.Class.Name,
                DocTypeDescription = iManDocument.Class.Description,
                AuthorInitials = iManDocument.Author.Name,
                AuthorFullName = iManDocument.Author.FullName,
                ApplicationExtension = iManDocument.Type.ApplicationExtension,
                ApplicationName = iManDocument.Type.Name,
                ApplicationDescription = iManDocument.Type.Description,
                Comment = iManDocument.Comment,
                HasAttachments = iManDocument.HasAttachments,
                SiteDbId = _dbSettings.SiteDbId,
                Iwl = new Uri($"iwl:dms={_iManSession.ServerName}&&lib={database}&&num={iManDocument.Number}&&ver={iManDocument.Version}")
            };
            if (!iManDocument.RelatedDocuments.Empty && addRelatedDocument)
            {
                for (var iRelatedDoc = 1; iRelatedDoc <= iManDocument.RelatedDocuments.Count; iRelatedDoc++)
                {
                    var manRelatedDocContent = iManDocument.RelatedDocuments.ItemByIndex(iRelatedDoc);
                    if (manRelatedDocContent.ObjectType.ObjectType == imObjectType.imTypeDocument)
                    {
                        var iManRelatedDocument = (IManDocument)manRelatedDocContent;
                        document.AddRelatedDocument(iManRelatedDocument.Number, database, iManRelatedDocument.Version);
                        Marshal.ReleaseComObject(iManRelatedDocument);
                    }

                    Marshal.ReleaseComObject(manRelatedDocContent);
                }
            }

            if (!iManDocument.CustomAttributes.Empty)
            {
                for (var iAttribute = 1; iAttribute <= iManDocument.CustomAttributes.Count; iAttribute++)
                {
                    var customAttribute = iManDocument.CustomAttributes.ItemByIndex(iAttribute);
                    if (customAttribute.Type == imProfileAttributeID.imProfileCustom13)
                    {
                        document.EmailFrom = customAttribute.Name;
                    }
                    else if (customAttribute.Type == imProfileAttributeID.imProfileCustom14)
                    {
                        document.EmailTo = customAttribute.Name;
                    }
                    else if (customAttribute.Type == imProfileAttributeID.imProfileCustom15)
                    {
                        document.EmailCc = customAttribute.Name;
                    }
                    else if (customAttribute.Type == imProfileAttributeID.imProfileCustom21)
                    {
                        DateTime dateSent;
                        if (DateTime.TryParse(customAttribute.Name, out dateSent))
                        {
                            document.EmailDateSent = dateSent;
                        }
                    }
                    else if (customAttribute.Type == imProfileAttributeID.imProfileCustom22)
                    {
                        DateTime dateReceived;
                        if (DateTime.TryParse(customAttribute.Name, out dateReceived))
                        {
                            document.EmailDateReceived = dateReceived;
                        }
                    }

                    Marshal.ReleaseComObject(customAttribute);
                }
            }

            return document;
        }

        static byte[] StreamFile(string filename)
        {
            byte[] data;
            using (var fs = new FileStream(filename, FileMode.Open, FileAccess.Read))
            {
                data = new byte[fs.Length];
                fs.Read(data, 0, Convert.ToInt32(fs.Length));
                fs.Close();
            }

            return data;
        }

        protected virtual void Dispose(bool disposing)
        {
            if (!_disposed)
            {
                if (disposing)
                {
                    //Dispose managed objects here
                }

                //Dispose unmanaged objects here
                Disconnect();
            }

            _disposed = true;
        }

        class SortFolder : IManObjectSort
        {
            public bool Less(IManObject object1, IManObject object2)
            {
                var folder1 = object1 as IManFolder;
                var folder2 = object2 as IManFolder;
                if (folder1 != null && folder2 != null)
                {
                    return string.Compare(folder1.Name, folder2.Name, StringComparison.Ordinal) < 0;
                }

                return false;
            }
        }

        class SortDocument : IManObjectSort
        {
            public bool Less(IManObject object1, IManObject object2)
            {
                var document1 = object1 as IManDocument;
                var document2 = object2 as IManDocument;
                if (document1 != null && document2 != null)
                {
                    return document1.Number < document2.Number;
                }

                return false;
            }
        }
    }
}