using System.Linq;
using System.Net;
using System.Threading.Tasks;
using System.Web.Http;
using System.Web.Http.ModelBinding;
using Inprotech.Infrastructure.Extensions;
using Inprotech.Infrastructure.ResponseEnrichment;
using Inprotech.Infrastructure.Security;
using Inprotech.Infrastructure.Web;
using Inprotech.Web.Cases.Details;
using InprotechKaizen.Model.Configuration;
using InprotechKaizen.Model.ContactActivities;
using InprotechKaizen.Model.Persistence;

namespace Inprotech.Web.PriorArt
{
    [Authorize]
    [NoEnrichment]
    [RoutePrefix("api/priorart")]
    public class PriorArtAttachmentsController : ApiController
    {
        readonly IDbContext _dbContext;
        readonly ISubjectSecurityProvider _subjectSecurityProvider;

        public PriorArtAttachmentsController(IDbContext dbContext, ISubjectSecurityProvider subjectSecurityProvider)
        {
            _subjectSecurityProvider = subjectSecurityProvider;
            _dbContext = dbContext;
        }

        [HttpGet]
        [Route("{priorart}/attachments")]
        public async Task<PagedResults> GetPriorArtViewAttachments(string priorArt, [ModelBinder(BinderType = typeof(JsonQueryBinder), Name = "params")] CommonQueryParameters queryParameters = null)
        {
            if (string.IsNullOrWhiteSpace(priorArt) || !int.TryParse(priorArt, out var priorArtId))
            {
                throw new HttpResponseException(HttpStatusCode.BadRequest);
            }

            if (!_subjectSecurityProvider.HasAccessToSubject(ApplicationSubject.Attachments))
            {
                throw new HttpResponseException(HttpStatusCode.Unauthorized);
            }

            var result = (from act in _dbContext.Set<Activity>()
            join tc in _dbContext.Set<TableCode>() on act.ActivityCategoryId equals tc.Id into tc1
            join tc2 in _dbContext.Set<TableCode>() on act.ActivityTypeId equals tc2.Id into tcc
            join at in _dbContext.Set<ActivityAttachment>() on act.Id equals at.ActivityId into at1
            from at in at1
            join tc3 in _dbContext.Set<TableCode>() on at.AttachmentTypeId equals tc3.Id into tccc
            from tc3 in tccc.DefaultIfEmpty()
            join tc4 in _dbContext.Set<TableCode>() on at.LanguageId equals tc4.Id into tcx4
            from tc4 in tcx4.DefaultIfEmpty()
            where act.PriorartId == priorArtId
            select new AttachmentItem
            {
                 ActivityCategory = act.ActivityCategory.Name,
                 ActivityDate = act.ActivityDate,
                 ActivityType = act.ActivityType.Name,
                 RawAttachmentName = at.AttachmentName,
                 AttachmentType = tc3 != null ? tc3.Name : null,
                 FilePath = at.FileName,
                 IsPublic = (at.PublicFlag ?? 0m) == 1m,
                 Language = tc4 != null ? tc4.Name : null,
                 PageCount = at.PageCount,
                 ActivityId = at.ActivityId,
                 SequenceNo = at.SequenceNo,
                 IsPriorArt = act.PriorartId != null
            }).OrderByDescending(_ => _.ActivityDate).ThenBy(_ => _.RawAttachmentName);

            var attachments = result.OrderByProperty(queryParameters);

            return attachments.Filter(queryParameters).AsPagedResults(queryParameters);
        }
    }
}
