using System;
using System.Linq;
using System.Web.Http;
using Inprotech.Infrastructure.ResponseEnrichment;
using Inprotech.Infrastructure.Security;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Persistence;

namespace Inprotech.Web.CustomContent
{
    [Authorize]
    [RoutePrefix("api/custom-content")]
    public class CustomContentController : ApiController
    {
        readonly ICustomContentDataResolver _customContentDataResolver;
        readonly IDbContext _dbContext;

        public CustomContentController(IDbContext dbContext, ICustomContentDataResolver customContentDataResolver)
        {
            _dbContext = dbContext;
            _customContentDataResolver = customContentDataResolver;
        }

        [HttpGet]
        [NoEnrichment]
        [RequiresCaseAuthorization]
        [Route("case/{caseKey:int}/item/{itemKey:int}")]
        public CustomContentData GetCustomContentData(int caseKey, int itemKey)
        {
            var @case =_dbContext.Set<Case>().First(_ => _.Id == caseKey);
            return _customContentDataResolver.Resolve(itemKey, @case.Irn);
        }
    }
}