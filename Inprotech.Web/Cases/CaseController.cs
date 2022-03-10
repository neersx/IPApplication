using System.Linq;
using System.Threading.Tasks;
using System.Web.Http;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Infrastructure.ResponseEnrichment;
using Inprotech.Infrastructure.Security;
using Inprotech.Web.Cases.SummaryPreview;
using Inprotech.Web.Images;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Components.Cases.CriticalDates;
using InprotechKaizen.Model.Components.Cases.Reminders;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.Persistence;

namespace Inprotech.Web.Cases
{
    [Authorize]
    [NoEnrichment]
    [RoutePrefix("api/search/case")]
    public class CaseController : ApiController
    {
        readonly ICaseHeaderInfo _caseHeaderInfo;
        readonly IImageService _imageService;
        readonly ICriticalDatesResolver _criticalDatesResolver;
        readonly ITaskPlannerDetailsResolver _taskPlannerDetailsResolver;
        readonly IDbContext _dbContext;
        readonly IPreferredCultureResolver _preferredCultureResolver;
        readonly ISecurityContext _securityContext;

        public CaseController(IDbContext dbContext,
                              ISecurityContext securityContext,
                              IPreferredCultureResolver preferredCultureResolver,
                              ICaseHeaderInfo caseHeaderInfo,
                              ICriticalDatesResolver criticalDatesResolver,
                              IImageService imageService, ITaskPlannerDetailsResolver taskPlannerDetailsResolver)
        {
            _dbContext = dbContext;
            _securityContext = securityContext;
            _preferredCultureResolver = preferredCultureResolver;
            _caseHeaderInfo = caseHeaderInfo;
            _criticalDatesResolver = criticalDatesResolver;
            _imageService = imageService;
            _taskPlannerDetailsResolver = taskPlannerDetailsResolver;
        }

        [HttpGet]
        [RequiresCaseAuthorization]
        [Route("{caseKey:int}/searchsummary")]
        public async Task<dynamic> GetSummary(int caseKey)
        {
            var userId = _securityContext.User.Id;

            var culture = _preferredCultureResolver.Resolve();

            var header = await _caseHeaderInfo.Retrieve(userId, culture, caseKey);

            var criticalDates = await _criticalDatesResolver.Resolve(caseKey);

            return new
            {
                CaseData = header.Summary,
                header.Names,
                Dates = criticalDates
            };
        }

        [HttpGet]
        [Route("{key}/taskDetails")]
        public async Task<TaskDetails> GetTaskDetailsSummary(string key)
        {
            return await _taskPlannerDetailsResolver.Resolve(key);
        }

        [HttpGet]
        [RequiresCaseAuthorization(PropertyName = "itemKey")]
        [Route("image/{imageKey:int}/{itemKey:int}/{maxWidth?}/{maxHeight?}")]
        public dynamic GetImage(int imageKey, int itemKey, int? maxWidth = null, int? maxHeight = null)
        {
            var image = _dbContext.Set<Image>().SingleOrDefault(_ => _.Id == imageKey)?.ImageData;

            return image == null ? null : _imageService.ResizeImage(image, maxWidth, maxHeight);
        }
    }
}