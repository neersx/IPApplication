using System.Linq;
using System.Web.Http;
using Inprotech.Infrastructure;
using Inprotech.Infrastructure.Compatibility;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Infrastructure.ResponseEnrichment;
using Inprotech.Infrastructure.Security;
using Inprotech.Infrastructure.Web;
using Inprotech.Web.CaseSupportData;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Cases.Events;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.Configuration;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Queries;

namespace Inprotech.Web.Search.Case.CaseSearch
{
    [Authorize]
    [NoEnrichment]
    [RequiresAccessTo(ApplicationTask.AdvancedCaseSearch)]
    [RoutePrefix("api/search/case/casesearch")]
    public class CaseSearchViewController : ApiController
    {
        readonly IDbContext _dbContext;
        readonly ISecurityContext _securityContext;
        readonly IPreferredCultureResolver _preferredCultureResolver;
        readonly IUserFilteredTypes _userFilteredTypes;
        readonly ICaseAttributes _caseAttributes;
        readonly IInprotechVersionChecker _inprotechVersionChecker;
        readonly ICaseSavedSearch _caseSavedSearch;
        readonly ISiteControlReader _siteControlReader;
        readonly ICaseSearchService _caseSearch;
        readonly ITaskSecurityProvider _taskSecurityProvider;

        public CaseSearchViewController(IDbContext dbContext, ISecurityContext securityContext,
                                            IPreferredCultureResolver preferredCultureResolver, IUserFilteredTypes userFilteredTypes,
                                            ICaseAttributes caseAttributes, IInprotechVersionChecker inprotechVersionChecker, ICaseSavedSearch caseSavedSearch,
                                            ISiteControlReader siteControlReader, ICaseSearchService caseSearch, ITaskSecurityProvider taskSecurityProvider)
        {
            _dbContext = dbContext;
            _securityContext = securityContext;
            _preferredCultureResolver = preferredCultureResolver;
            _userFilteredTypes = userFilteredTypes;
            _caseAttributes = caseAttributes;
            _inprotechVersionChecker = inprotechVersionChecker;
            _caseSavedSearch = caseSavedSearch;
            _siteControlReader = siteControlReader;
            _caseSearch = caseSearch;
            _taskSecurityProvider = taskSecurityProvider;
        }

        [Route("view/{queryKey}")]
        public dynamic Get(int? queryKey = null)
        {
            var culture = _preferredCultureResolver.Resolve();
            var numberTypes = _userFilteredTypes.NumberTypes()
                .Select(_ => new
                {
                    Key = _.NumberTypeCode,
                    Value = DbFuncs.GetTranslation(_.Name, null, _.NameTId, culture)
                });

            var nameTypes = _userFilteredTypes.NameTypes()
                .Select(_ => new
                {
                    Key = _.NameTypeCode,
                    Value = DbFuncs.GetTranslation(_.Name, null, _.NameTId, culture)
                });

            var textTypes = _userFilteredTypes.TextTypes(true)
                .Select(_ => new
                {
                    Key = _.Id,
                    Value = DbFuncs.GetTranslation(_.TextDescription, null, _.TextDescriptionTId, culture)
                });

            var importanceOptions = _caseSearch.GetImportanceLevels();

            var attributes = _caseAttributes.Get();

            var sentToCpaBatchNo = GetSentToCpaBatchDetails();

            var isPatentTermAdjustmentTopicVisible = _siteControlReader.Read<bool?>(SiteControls.PatentTermAdjustments);

            var allowMultipleCaseTypeSelection = _inprotechVersionChecker.CheckMinimumVersion(14);

            var showCeasedNames = _siteControlReader.Read<bool>(SiteControls.DisplayCeasedNames);

            var eventNoteVisibility = EventNoteVisibility();

            var dueDatePresentationColumn = _caseSearch.DueDatePresentationColumn(queryKey);

            var entitySizes = _dbContext.Set<TableCode>()
                                        .Where(_ => _.TableTypeId == (short)TableTypes.EntitySize)
                                        .Select(_ => new
                                              {
                                                  Key = _.Id,
                                                  Value = DbFuncs.GetTranslation(_.Name, null, _.NameTId, culture)
                                              });

            return new
            {
                IsExternal = _securityContext.User.IsExternalUser,
                QueryContextKey = (int)(_securityContext.User.IsExternalUser ? QueryContext.CaseSearchExternal : QueryContext.CaseSearch),
                NumberTypes = numberTypes,
                NameTypes = nameTypes,
                TextTypes = textTypes,
                ImportanceOptions = importanceOptions,
                Attributes = attributes,
                SentToCpaBatchNo = sentToCpaBatchNo,
                DesignElementTopicVisible = DesignElementTopicVisible(),
                IsPatentTermAdjustmentTopicVisible = isPatentTermAdjustmentTopicVisible,
                AllowMultipleCaseTypeSelection = allowMultipleCaseTypeSelection,
                ShowCeasedNames = showCeasedNames,
                eventNoteVisibility.ShowEventNoteType,
                eventNoteVisibility.ShowEventNoteSection,
                dueDatePresentationColumn.HasDueDatePresentationColumn,
                dueDatePresentationColumn.HasAllDatePresentationColumn,
                CanCreateSavedSearch = _taskSecurityProvider.HasAccessTo(ApplicationTask.MaintainCaseSearch, ApplicationTaskAccessLevel.Create),
                CanMaintainPublicSearch = _taskSecurityProvider.HasAccessTo(ApplicationTask.MaintainPublicSearch),
                CanUpdateSavedSearch = _taskSecurityProvider.HasAccessTo(ApplicationTask.MaintainCaseSearch, ApplicationTaskAccessLevel.Modify),
                CanDeleteSavedSearch = _taskSecurityProvider.HasAccessTo(ApplicationTask.MaintainCaseSearch, ApplicationTaskAccessLevel.Delete),
                EntitySizes = entitySizes
            };
        }

        bool DesignElementTopicVisible()
        {
            return _dbContext.Set<QueryDataItem>().Any(_ => _.ProcedureItemId == "FirmElementId" && _.ProcedureName == "csw_ListCase");
        }

        dynamic EventNoteVisibility()
        {
            var hasPublicEventNote = _dbContext.Set<EventNoteType>().Any(_ => _.IsExternal);
            var clientEventText = _siteControlReader.Read<bool>(SiteControls.ClientEventText);

            return new
            {
                ShowEventNoteType = !_securityContext.User.IsExternalUser || hasPublicEventNote,
                ShowEventNoteSection = !_securityContext.User.IsExternalUser || hasPublicEventNote || clientEventText
            };
        }

        dynamic GetSentToCpaBatchDetails()
        {
            return _dbContext.Set<CpaSend>()
                                       .Select(_ => new
                                       {
                                           _.BatchNo,
                                       })
                                       .Distinct().OrderByDescending(s => s.BatchNo)
                                       .ToArray();

        }

        [Route("builder/{queryKey}")]
        public dynamic GetCaseSavedSearchData(int queryKey)
        {
            var query = _dbContext.Set<Query>().FirstOrDefault(_ => _.Id == queryKey);
            if (query?.Filter == null) return null;
            var filter = query.Filter;

            var data = _caseSavedSearch.GetCaseSavedSearchData(filter.XmlFilterCriteria);

            var dueDateData = _caseSavedSearch.GetSavedDueDateData(filter.XmlFilterCriteria);

            return new
            {
                QueryName = query.Name,
                IsPublic = query.IdentityId == null,
                Steps = data,
                DueDateFormData = dueDateData
            };
        }
    }
}