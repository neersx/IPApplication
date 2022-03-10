using System.Collections.Generic;
using System.Data.Entity;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Integration.DmsIntegration;
using Inprotech.Integration.DmsIntegration.Component.iManage;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Persistence;
using Status = Inprotech.Integration.DmsIntegration.Status;

namespace Inprotech.Web.Configuration.DMSIntegration
{
    public interface IDmsTestDocuments
    {
        Task<DmsFolderTestResponse> GetDmsEventsForTest();
        Task<IEnumerable<DmsSearchParams>> GetDmsSearchParamsForTest();
        Task<DmsFolderTestResponse> TestConnection(ConnectionTestRequestModel settings);
        IManageTestSettings ManageTestSettings(SettingsController.DmsModel model);
    }

    public class DmsTestDocuments : IDmsTestDocuments
    {
        readonly IPreferredCultureResolver _cultureResolver;
        readonly IDbContext _dbContext;
        readonly IDmsEventSink _dmsEventSink;
        readonly ISettingTester _settingTester;

        public DmsTestDocuments(IDbContext dbContext, IDmsEventSink dmsEventSink, ISettingTester settingTester, IPreferredCultureResolver cultureResolver)
        {
            _dbContext = dbContext;
            _dmsEventSink = dmsEventSink;
            _settingTester = settingTester;
            _cultureResolver = cultureResolver;
        }

        public async Task<DmsFolderTestResponse> TestConnection(ConnectionTestRequestModel settings)
        {
            var e = new List<string>();
            var r = (await _settingTester.TestConnections(settings)).ToArray();
            foreach (var r1 in r)
            {
                if (r1.ErrorMessages.Any())
                {
                    e.AddRange(r1.ErrorMessages);
                }
            }

            return new DmsFolderTestResponse
            {
                Errors = e,
                IsConnectionUnsuccessful = !r.Any(_ => _.Success)
            };
        }

        public IManageTestSettings ManageTestSettings(SettingsController.DmsModel model)
        {
            foreach (var name in model.IManageSettings.NameTypes) name.ExtractNameTypeCode();
            var testSettings = new IManageTestSettings { UserName = model.Username, Password = model.Password, Settings = model.IManageSettings };
            testSettings.Settings.DataItemCodes = new IManageSettings.DataItemsSettings
            {
                CaseDataItem = model.IManageSettings.DataItems?.CaseSearch?.Code,
                NameDataItem = model.IManageSettings.DataItems?.NameSearch?.Code
            };
            testSettings.Settings.NameTypes = model.IManageSettings.NameTypes.Select(_ => new IManageSettings.NameTypeSettings
            {
                NameType = _.NameType,
                SubClass = _.SubClass
            });
            return testSettings;
        }

        public async Task<DmsFolderTestResponse> GetDmsEventsForTest()
        {
            var dmsFolderTestResponse = new DmsFolderTestResponse();

            var nameTypes = await GetNameTypes();

            dmsFolderTestResponse.SearchParams = GetDmsSearchParams(nameTypes);

            var eventsRequiredForResults = new[]
            {
                KnownDocumentManagementEvents.CaseWorkspace,
                KnownDocumentManagementEvents.NameWorkspace
            };

            var resultEvents = _dmsEventSink.GetEvents(Status.Info, eventsRequiredForResults);
            var documentManagementEvents = resultEvents as DocumentManagementEvent[] ?? resultEvents.ToArray();
            if (documentManagementEvents.Any())
            {
                dmsFolderTestResponse.Results = documentManagementEvents
                                                .Select(_ =>
                                                            new DocumentManagementEvent(_.Status, _.Key, _.Value)
                                                            {
                                                                NameType = !string.IsNullOrEmpty(_.NameType) ? nameTypes[_.NameType] : null
                                                            })
                                                .Distinct(new DocumentManagementEventComparer())
                                                .ToArray();
            }
            else
            {
                dmsFolderTestResponse.Results = new[]
                {
                    new DocumentManagementEvent(Status.Info, KnownDocumentManagementEvents.NoWorkspaceFound, string.Empty)
                };
            }

            return dmsFolderTestResponse;
        }
        public async Task<IEnumerable<DmsSearchParams>> GetDmsSearchParamsForTest()
        {
            var nameTypes = await GetNameTypes();
            var searchParams = GetDmsSearchParams(nameTypes);
            return searchParams;
        }

        IEnumerable<DmsSearchParams> GetDmsSearchParams(IDictionary<string, string> nameTypes)
        {
            var eventsRequiredForSearchParams = new[]
            {
                KnownDocumentManagementEvents.CaseWorkspaceCustomField1,
                KnownDocumentManagementEvents.CaseWorkspaceCustomField2,
                KnownDocumentManagementEvents.CaseWorkspaceCustomField3,
                KnownDocumentManagementEvents.CaseSubClass,
                KnownDocumentManagementEvents.CaseSubType,
                KnownDocumentManagementEvents.NameWorkspaceCustomField1,
                KnownDocumentManagementEvents.NameSubClass
            };

            var searchParamsEvents = _dmsEventSink.GetEvents(Status.Info, eventsRequiredForSearchParams).ToArray();
            if (!searchParamsEvents.Any())
            {
                return null;
            }

            var searchParams = searchParamsEvents.Select(_ => new DmsSearchParams
            {
                Key = _.Key,
                Value = _.Value,
                NameType = !string.IsNullOrEmpty(_.NameType) ? nameTypes[_.NameType] : string.Empty
            }).Distinct(new DmsSearchParamsComparer()).ToArray();
            return searchParams;
        }

        async Task<Dictionary<string, string>> GetNameTypes()
        {
            var culture = _cultureResolver.Resolve();
            var nameTypesUsed = _dmsEventSink.GetNameTypes(); // should not pull from the sink.

            return await (from nt in _dbContext.Set<NameType>()
                          where nameTypesUsed.Any(x => x == nt.NameTypeCode)
                          select new
                          {
                              nt.NameTypeCode,
                              Description = DbFuncs.GetTranslation(nt.Name, null, nt.NameTId, culture)
                          })
                         .Distinct()
                         .ToDictionaryAsync(k => k.NameTypeCode,
                                            v => v.Description);
        }
    }

    public class DmsFolderTestResponse
    {
        public IEnumerable<DmsSearchParams> SearchParams { get; set; }
        public IEnumerable<DocumentManagementEvent> Results { get; set; }
        public IEnumerable<string> Errors { get; set; }
        public bool IsConnectionUnsuccessful { get; set; }
        public IEnumerable<string> ConfigErrors { get; set; }
    }

    public class DmsSearchParams
    {
        public string Key { get; set; }
        public string Value { get; set; }
        public string NameType { get; set; }
    }

    public class DmsSearchParamsComparer : IEqualityComparer<DmsSearchParams>
    {
        public bool Equals(DmsSearchParams x, DmsSearchParams y)
        {
            if (ReferenceEquals(x, y))
            {
                return true;
            }

            if (x == null || y == null)
            {
                return false;
            }

            return x.Key == y.Key && x.Value == y.Value && x.NameType == y.NameType;
        }

        public int GetHashCode(DmsSearchParams obj)
        {
            return new { obj.Key, obj.Value, obj.NameType }.GetHashCode();
        }
    }

    public class DocumentManagementEventComparer : IEqualityComparer<DocumentManagementEvent>
    {
        public bool Equals(DocumentManagementEvent x, DocumentManagementEvent y)
        {
            if (ReferenceEquals(x, y))
            {
                return true;
            }

            if (x == null || y == null)
            {
                return false;
            }

            return x.Key == y.Key && x.Value == y.Value && x.NameType == y.NameType;
        }

        public int GetHashCode(DocumentManagementEvent obj)
        {
            return new { obj.Key, obj.Value, obj.NameType }.GetHashCode();
        }
    }
}