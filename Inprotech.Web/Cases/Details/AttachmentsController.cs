using System.Collections.Generic;
using System.Data.Entity;
using System.Linq;
using System.Net;
using System.Threading.Tasks;
using System.Web.Http;
using System.Web.Http.ModelBinding;
using Inprotech.Infrastructure.Extensions;
using Inprotech.Infrastructure.ResponseEnrichment;
using Inprotech.Infrastructure.Security;
using Inprotech.Infrastructure.Web;

namespace Inprotech.Web.Cases.Details
{
    [Authorize]
    [NoEnrichment]
    [RoutePrefix("api/case")]
    public class AttachmentsController : ApiController
    {
        readonly ICaseViewAttachmentsProvider _caseViewAttachmentsProvider;
        readonly ISubjectSecurityProvider _subjectSecurityProvider;

        public AttachmentsController(ICaseViewAttachmentsProvider caseViewAttachmentsProvider, ISubjectSecurityProvider subjectSecurityProvider)
        {
            _caseViewAttachmentsProvider = caseViewAttachmentsProvider;
            _subjectSecurityProvider = subjectSecurityProvider;
        }

        [HttpGet]
        [RequiresCaseAuthorization]
        [Route("{caseKey}/attachments")]
        public async Task<PagedResults> GetCaseViewAttachments(string caseKey,
                                                               [ModelBinder(BinderType = typeof(JsonQueryBinder), Name = "params")]
                                                               CommonQueryParameters queryParameters = null)
        {
            if (string.IsNullOrWhiteSpace(caseKey) || !int.TryParse(caseKey, out var caseId))
            {
                throw new HttpResponseException(HttpStatusCode.BadRequest);
            }

            if (!_subjectSecurityProvider.HasAccessToSubject(ApplicationSubject.Attachments))
            {
                throw new HttpResponseException(HttpStatusCode.Unauthorized);
            }

            var attachments = _caseViewAttachmentsProvider.GetAttachments(caseId).OrderByProperty(queryParameters);

            return attachments.Filter(queryParameters).AsPagedResults(queryParameters);
        }

        [HttpGet]
        [RequiresCaseAuthorization]
        [Route("{caseKey}/{eventNo}/{eventCycle}/attachments-recent")]
        public async Task<IEnumerable<AttachmentItem>> GetCaseViewAttachments(string caseKey, int eventNo, int eventCycle)
        {
            if (string.IsNullOrWhiteSpace(caseKey) || !int.TryParse(caseKey, out var caseId))
            {
                throw new HttpResponseException(HttpStatusCode.BadRequest);
            }

            if (!_subjectSecurityProvider.HasAccessToSubject(ApplicationSubject.Attachments))
            {
                throw new HttpResponseException(HttpStatusCode.Unauthorized);
            }

            return _caseViewAttachmentsProvider.GetAttachments(caseId)
                                                     .Where(x => x.EventNo == eventNo && x.EventCycle == eventCycle)
                                                     .Take(3);
        }
    }
}