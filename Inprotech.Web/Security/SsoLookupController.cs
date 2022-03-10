using System.Net;
using System.Net.Http;
using System.Threading.Tasks;
using System.Web.Http;
using Inprotech.Infrastructure.Extensions;
using Inprotech.Infrastructure.ResponseEnrichment;
using Inprotech.Infrastructure.Security;
using InprotechKaizen.Model.Components.Security.SingleSignOn;

namespace Inprotech.Web.Security
{
    [Authorize]
    [RoutePrefix("api/ip-platform")]
    [RequiresAuthenticationSettings(AuthenticationModeKeys.Sso)]
    [RequiresAccessTo(ApplicationTask.MaintainUser, ApplicationTaskAccessLevel.Create | ApplicationTaskAccessLevel.Modify)]
    //To strengthen security, calls to SSO are removed. This controller returns default messages to support the version 12.1
    public class SsoLookupController : ApiController
    {
        readonly ISsoUserIdentifier _userIdentifier;

        public SsoLookupController(ISsoUserIdentifier userIdentifier)
        {
            _userIdentifier = userIdentifier;
        }

        [HttpGet]
        [NoEnrichment]
        [Route("user/{email}")]
        public HttpResponseMessage ByEmail(string email)
        {
            if (string.IsNullOrWhiteSpace(email)) return new HttpResponseMessage(HttpStatusCode.BadRequest);

            return new HttpResponseMessage(HttpStatusCode.NotFound);
        }

        [HttpPut]
        [NoEnrichment]
        [Route("link/{id}")]
        public dynamic Link(int id)
        {
            return new
            {
                Code = SsoUserLinkResultType.Success.ToString().ToHyphenatedLowerCase()
            };
        }

        [HttpPut]
        [NoEnrichment]
        [Route("unlink/{id}")]
        public async Task<dynamic> Unlink(int id)
        {
            var r = await _userIdentifier.UnlinkUser(id);

            return new
            {
                Code = r.ToString().ToHyphenatedLowerCase()
            };
        }
    }
}