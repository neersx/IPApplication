using System;
using System.Web.Http;
using System.Web.Http.ModelBinding;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Infrastructure.ResponseEnrichment;
using Inprotech.Infrastructure.ResponseShaping.Picklists;
using Inprotech.Infrastructure.Security;
using Inprotech.Infrastructure.Web;

namespace Inprotech.Web.Picklists
{
    [Authorize]
    [NoEnrichment]
    [RoutePrefix("api/picklists/fileParts")]
    public class FilePartPicklistController : ApiController
    {
        readonly IPreferredCultureResolver _preferredCultureResolver;
        readonly IFilePartPicklistMaintenance _iFilePartPicklistMaintenance;

        public FilePartPicklistController(IPreferredCultureResolver preferredCultureResolver, IFilePartPicklistMaintenance iFilePartPicklistMaintenance)
        {
            _preferredCultureResolver = preferredCultureResolver;
            _iFilePartPicklistMaintenance = iFilePartPicklistMaintenance ?? throw new ArgumentNullException(nameof(iFilePartPicklistMaintenance));
        }

        [HttpGet]
        [Route("meta")]
        [PicklistPayload(typeof(FilePartPicklistItem), ApplicationTask.MaintainFileTracking)]
        public dynamic Metadata()
        {
            return null;
        }

        [HttpGet]
        [Route]
        [RequiresCaseAuthorization(PropertyName = "caseId")]
        [PicklistPayload(typeof(FilePartPicklistItem), ApplicationTask.MaintainFileTracking)]
        public PagedResults Search([ModelBinder(BinderType = typeof(JsonQueryBinder), Name = "params")] CommonQueryParameters queryParameters = null, string search = "", int caseId = 0)
        {
            _preferredCultureResolver.Resolve();

            return _iFilePartPicklistMaintenance.Search(queryParameters, search, caseId);
        }

        [HttpPost]
        [Route]
        [RequiresCaseAuthorization(PropertyPath = "saveDetails.CaseId")]
        public dynamic Save(FilePartPicklistItem saveDetails)
        {
            return _iFilePartPicklistMaintenance.Save(saveDetails);
        }

        [HttpPut]
        [Route("{id}")]
        [RequiresCaseAuthorization(PropertyPath = "saveDetails.CaseId")]
        public dynamic Update(short id, FilePartPicklistItem saveDetails)
        {
            return _iFilePartPicklistMaintenance.Update(id, saveDetails);
        }

        [HttpGet]
        [Route("{id}/case/{caseId}")]
        [RequiresCaseAuthorization(PropertyName = "caseId")]
        [PicklistPayload(typeof(FilePartPicklistItem), ApplicationTask.MaintainFileTracking)]
        public FilePartPicklistItem GetFile(short id, int caseId)
        {
            return _iFilePartPicklistMaintenance.GetFile(id, caseId);
        }

        [HttpDelete]
        [Route("{filePartId}")]
        public dynamic Delete(int filePartId)
        {
            return _iFilePartPicklistMaintenance.Delete(filePartId);
        }

    }
}
