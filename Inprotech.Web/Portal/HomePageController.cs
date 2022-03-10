using System.Web.Http;
using Inprotech.Infrastructure;
using Inprotech.Infrastructure.ResponseEnrichment;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.Profiles;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;

namespace Inprotech.Web.Portal
{
    [Authorize]
    [NoEnrichment]
    [RoutePrefix("api/portal/home")]
    public class HomePageController : ApiController
    {
        readonly ISecurityContext _securityContext;
        readonly IUserPreferenceManager _userPreferences;

        public HomePageController(ISecurityContext securityContext, IUserPreferenceManager userPreferences)
        {
            _securityContext = securityContext;
            _userPreferences = userPreferences;
        }

        [HttpPut]
        [Route("set")]
        public void SetHomePage(JObject homePageState)
        {
            var param = JsonConvert.SerializeObject(homePageState);
            _userPreferences.SetPreference(_securityContext.User.Id, KnownSettingIds.AppsHomePage, param);
        }

        [HttpDelete]
        [Route("reset")]
        public void ResetHomePage()
        {
            _userPreferences.ResetUserPreferences(_securityContext.User.Id, new[] {KnownSettingIds.AppsHomePage});
        }
    }
}