using System.Data.Entity;
using System.Threading.Tasks;
using System.Web.Http;
using Inprotech.Infrastructure;
using Inprotech.Infrastructure.ResponseEnrichment;
using Inprotech.Infrastructure.Security;
using Inprotech.Infrastructure.Web;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.Configuration;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Queries;

namespace Inprotech.Web.Search.Case
{
    [Authorize]
    [NoEnrichment]
    [RequiresAccessTo(ApplicationTask.QuickCaseSearch)]
    [RequiresAccessTo(ApplicationTask.AdvancedCaseSearch)]
    [RequiresAccessTo(ApplicationTask.RunSavedCaseSearch)]
    [RoutePrefix("api/search/case")]
    public class CaseSearchResultViewController : ApiController, ISearchResultViewController
    {
        readonly IDbContext _dbContext;
        readonly IListPrograms _listPrograms;
        readonly QueryContext _queryContextDefault;
        readonly ISecurityContext _securityContext;
        readonly ITaskSecurityProvider _taskSecurityProvider;
        readonly ISiteControlReader _siteControlReader;

        public CaseSearchResultViewController(IDbContext dbContext, ISecurityContext securityContext, IListPrograms listPrograms, ITaskSecurityProvider taskSecurityProvider, ISiteControlReader siteControlReader)
        {
            _dbContext = dbContext;
            _securityContext = securityContext;
            _listPrograms = listPrograms;
            _taskSecurityProvider = taskSecurityProvider;
            _siteControlReader = siteControlReader;
            _queryContextDefault = securityContext.User.IsExternalUser
                ? QueryContext.CaseSearchExternal
                : QueryContext.CaseSearch;
        }

        [Route("view")]
        public async Task<dynamic> Get(int? queryKey, QueryContext queryContext)
        {
            if (_queryContextDefault != queryContext)
            {
                return BadRequest();
            }

            var queryName = string.Empty;
            if (queryKey.HasValue)
            {
                queryName = (await _dbContext.Set<Query>().FirstOrDefaultAsync(_ => _.Id == queryKey.Value && _.ContextId == (int)queryContext))?.Name;
            }

            return new
            {
                HasOffices = await _dbContext.Set<Office>().AnyAsync(),
                HasFileLocation = await _dbContext.Set<TableCode>().AnyAsync(tc => tc.TableTypeId == (int)TableTypes.FileLocation),
                isExternal = _securityContext.User.IsExternalUser,
                QueryName = queryName,
                Programs = _listPrograms.GetCasePrograms(),
                QueryContext = (int)queryContext,
                Permissions = new
                {
                    CanMaintainGlobalNameChange = _taskSecurityProvider.HasAccessTo(ApplicationTask.GlobalNameChange),
                    CanMaintainCase = _taskSecurityProvider.HasAccessTo(ApplicationTask.MaintainCase, ApplicationTaskAccessLevel.Modify),
                    CanOpenWorkflowWizard = _taskSecurityProvider.HasAccessTo(ApplicationTask.LaunchWorkflowWizard),
                    CanOpenDocketingWizard = _taskSecurityProvider.HasAccessTo(ApplicationTask.DocketingWizard),
                    CanMaintainFileTracking = _taskSecurityProvider.HasAccessTo(ApplicationTask.MaintainFileTracking),
                    CanOpenFirstToFile = _taskSecurityProvider.HasAccessTo(ApplicationTask.AccessFirstToFile, ApplicationTaskAccessLevel.Execute),
                    CanOpenWipRecord = _taskSecurityProvider.HasAccessTo(ApplicationTask.RecordWip, ApplicationTaskAccessLevel.Create),
                    CanOpenCopyCase = _taskSecurityProvider.HasAccessTo(ApplicationTask.CopyCase, ApplicationTaskAccessLevel.Execute) && _taskSecurityProvider.HasAccessTo(ApplicationTask.MaintainCase, ApplicationTaskAccessLevel.Modify),
                    CanShowLinkforInprotechWeb = _taskSecurityProvider.HasAccessTo(ApplicationTask.ShowLinkstoWeb),
                    CanRecordTime = _taskSecurityProvider.HasAccessTo(ApplicationTask.MaintainTimeViaTimeRecording),
                    CanCreateAdHocDate = _taskSecurityProvider.HasAccessTo(ApplicationTask.MaintainAdHocDate, ApplicationTaskAccessLevel.Create),
                    CanViewCaseDataComparison = _taskSecurityProvider.HasAccessTo(ApplicationTask.ViewCaseDataComparison),
                    CanUpdateEventsInBulk = _taskSecurityProvider.HasAccessTo(ApplicationTask.BatchEventUpdate),
                    CanAccessDocumentsFromDms = _taskSecurityProvider.HasAccessTo(ApplicationTask.AccessDocumentsfromDms),
                    CanOpenReminders = true, // _taskSecurityProvider.HasAccessTo(ApplicationTask.MaintainReminder),
                    CanOpenWebLink = true,
                    CanRequestCaseFile = _taskSecurityProvider.HasAccessTo(ApplicationTask.MaintainFileTracking) && _siteControlReader.Read<bool>(SiteControls.RFIDSystem),
                    CanPoliceInBulk = _taskSecurityProvider.HasAccessTo(ApplicationTask.PoliceActionsOnCase),
                    CanMaintainCaseList = _taskSecurityProvider.HasAccessTo(ApplicationTask.MaintainCaseList, ApplicationTaskAccessLevel.Execute) || (_taskSecurityProvider.HasAccessTo(ApplicationTask.MaintainCaseList, ApplicationTaskAccessLevel.Create) && _taskSecurityProvider.HasAccessTo(ApplicationTask.MaintainCaseList, ApplicationTaskAccessLevel.Modify)),
                    CanUseTimeRecording = _taskSecurityProvider.HasAccessTo(ApplicationTask.MaintainTimeViaTimeRecording)
                },
                ExportLimit = _siteControlReader.Read<int?>(SiteControls.ExportLimit)
            };
        }
    }
}