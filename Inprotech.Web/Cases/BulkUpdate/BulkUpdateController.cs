
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using System.Web.Http;
using Inprotech.Infrastructure;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Infrastructure.Notifications;
using Inprotech.Infrastructure.ResponseEnrichment;
using Inprotech.Infrastructure.Security;
using Inprotech.Integration.BulkCaseUpdates;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.Configuration;
using InprotechKaizen.Model.Persistence;

namespace Inprotech.Web.Cases.BulkUpdate
{
    [Authorize]
    [NoEnrichment]
    [RoutePrefix("api/search/case/bulkupdate")]
    [RequiresAccessTo(ApplicationTask.MaintainCase, ApplicationTaskAccessLevel.Modify)]
    public class BulkUpdateController : ApiController
    {
        readonly IDbContext _dbContext;
        readonly IPreferredCultureResolver _preferredCultureResolver;
        readonly IUserFilteredTypes _userFilteredTypes;
        readonly IBulkFieldUpdates _bulkFieldUpdates;
        readonly ITaskSecurityProvider _taskSecurityProvider;
        readonly IConfigureBulkCaseUpdatesJob _configureJob;
        readonly IBulkCaseStatusUpdateHandler _statusUpdateHandler;
        readonly ISiteControlReader _siteControlReader;

        public BulkUpdateController(IDbContext dbContext,
                                    IPreferredCultureResolver preferredCultureResolver, IUserFilteredTypes userFilteredTypes,
                                    IBulkFieldUpdates bulkFieldUpdates,
                                    IConfigureBulkCaseUpdatesJob configureJob, 
                                    ITaskSecurityProvider taskSecurityProvider,
                                    IBulkCaseStatusUpdateHandler statusUpdateHandler,
                                    ISiteControlReader siteControlReader)
        {
            _dbContext = dbContext;
            _preferredCultureResolver = preferredCultureResolver;
            _userFilteredTypes = userFilteredTypes;
            _bulkFieldUpdates = bulkFieldUpdates;
            _configureJob = configureJob;
            _taskSecurityProvider = taskSecurityProvider;
            _statusUpdateHandler = statusUpdateHandler;
            _siteControlReader = siteControlReader;
        }

        [Route("viewdata")]
        public dynamic Get()
        {
            var culture = _preferredCultureResolver.Resolve();
            var entitySizes = _dbContext.Set<TableCode>()
                                        .Where(_ => _.TableTypeId == (short)TableTypes.EntitySize);

            var entities = entitySizes.Select(_ => new
            {
                Key = _.Id,
                Value = DbFuncs.GetTranslation(_.Name, null, _.NameTId, culture)
            }).ToList();

            return new
            {
                EntitySizes = entities,
                TextTypes = GetTextTypes(culture),
                CanMaintainFileTracking = _taskSecurityProvider.HasAccessTo(ApplicationTask.MaintainFileTracking, ApplicationTaskAccessLevel.Modify | ApplicationTaskAccessLevel.Create),
                CanUpdateBulkStatus = _taskSecurityProvider.HasAccessTo(ApplicationTask.MaintainBulkCaseStatus),
                allowRichText = _siteControlReader.Read<bool>(SiteControls.EnableRichTextFormatting)
            };
        }

        [Route("policingData")]
        public dynamic GetPolicingViewData()
        {
            var culture = _preferredCultureResolver.Resolve();

            return new
            {
                TextTypes = GetTextTypes(culture),
                AllowRichText = _siteControlReader.Read<bool>(SiteControls.EnableRichTextFormatting)
            };
        }

        dynamic GetTextTypes(string culture)
        {
            return _userFilteredTypes.TextTypes()
                                                     .Where(_=> _.Id != KnownTextTypes.GoodsServices)
                                                     .Select(_ => new
                                                     {
                                                         Key = _.Id,
                                                         Value = DbFuncs.GetTranslation(_.TextDescription, null, _.TextDescriptionTId, culture)
                                                     }).ToList();
        }

        [HttpPost]
        [Route("save")]
        public dynamic ApplyBulkUpdate([FromBody] BulkUpdateRequest request)
        {
            if(request?.CaseIds == null || !request.CaseIds.Any())
                return new { Status = false };

            var subType = !string.IsNullOrWhiteSpace(request.CaseAction) ? BackgroundProcessSubType.Policing : BackgroundProcessSubType.NotSet;
            var processId = _bulkFieldUpdates.AddBackgroundProcess(subType);

            var args = new BulkCaseUpdatesArgs
            {
                ProcessId = processId,
                CaseIds = request.CaseIds,
                SaveData = request.SaveData ?? new BulkUpdateData(),
                CaseAction = request.CaseAction,
                TextType = request.ReasonData?.TextType,
                Notes = request.ReasonData?.Notes
            };

            _configureJob.AddBulkCaseUpdateJob(args);
            return new { Status = true };
        }

        [HttpPost]
        [Route("hasRestrictedCasesForStatus")]
        public async Task<bool> HasRestrictedCasesForStatus([FromBody] RestrictedCasesStatusRequest request)
        { 
            if (request.Cases == null || !request.Cases.Any() || string.IsNullOrWhiteSpace(request.StatusCode)) return false;
            var restrictedCases = await _statusUpdateHandler.GetRestrictedCasesForStatus(request.Cases.ToArray(), request.StatusCode);
            return restrictedCases != null && restrictedCases.Any();
        }

        [HttpPost]
        [Route("checkStatusPassword/{password}")]
        public bool CheckStatusPassword(string password)
        {
            if (string.IsNullOrWhiteSpace(password)) return false;

            var confirmPassword = _siteControlReader.Read<string>(SiteControls.ConfirmationPasswd);
            return string.Equals(password, confirmPassword);
        }
    }

    public class RestrictedCasesStatusRequest
    {
        public List<int> Cases { get; set; }
        public string StatusCode { get; set; }
    }

    public class BulkUpdateRequest
    {
        public int[] CaseIds { get; set; }
        public BulkUpdateData SaveData { get; set; }
        public BulkUpdateReasonData ReasonData { get; set; }
        public string CaseAction { get; set; }
    }

    public class BulkUpdateReasonData
    {
        public string TextType { get; set; }
        public string Notes { get; set; }
    }
}