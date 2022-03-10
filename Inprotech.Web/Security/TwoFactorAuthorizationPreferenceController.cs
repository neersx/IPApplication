using System.Collections.Generic;
using System.Linq;
using System.Net;
using System.Net.Http;
using System.Threading.Tasks;
using System.Web.Http;
using Inprotech.Infrastructure.ResponseEnrichment;
using Inprotech.Infrastructure.Security;
using Inprotech.Web.Security.TwoFactorAuth;
using InprotechKaizen.Model.Components.Security;

namespace Inprotech.Web.Security
{
    [Authorize]
    [RoutePrefix("api/twoFactorAuthPreference")]
    public class TwoFactorAuthorizationPreferenceController : ApiController
    {
        readonly ISecurityContext _securityContext;
        readonly IUserTwoFactorAuthPreference _twoFactorAuthPreference;
        readonly IAuthSettings _authSettings;
        readonly ITwoFactorApp _twoFactorApp;
        public TwoFactorAuthorizationPreferenceController(IUserTwoFactorAuthPreference twoFactorAuthPreference, ISecurityContext securityContext, IAuthSettings authSettings, ITwoFactorApp twoFactorApp)
        {
            _twoFactorAuthPreference = twoFactorAuthPreference;
            _securityContext = securityContext;
            _authSettings = authSettings;
            _twoFactorApp = twoFactorApp;
        }

        [HttpGet]
        [Route("")]
        [NoEnrichment]
        public async Task<UserTwoFactorAuthenticationPreferenceModel> GetPreferenceModel()
        {
            var configuredModes = new List<string>() { TwoFactorAuthVerify.Email };
            if (!string.IsNullOrWhiteSpace(await _twoFactorAuthPreference.ResolveAppSecretKey(_securityContext.User.Id)))
            {
                configuredModes.Add(TwoFactorAuthVerify.App);
            }

            return new UserTwoFactorAuthenticationPreferenceModel()
            {
                Enabled = _authSettings.TwoFactorAuthenticationEnabled(_securityContext.User.IsExternalUser) && Request.ParseAuthCookie(_authSettings).AuthMode == "Forms",
                Preference = await _twoFactorAuthPreference.ResolvePreferredMethod(_securityContext.User.Id),
                ConfiguredModes = configuredModes
            };
        } 

        [HttpPost]
        [Route("twoFactorAppKeyDelete")]
        [NoEnrichment]
        public async Task<bool> DeleteTwoFactorKey()
        {
            await _twoFactorAuthPreference.RemoveAppSecretKey(_securityContext.User.Id);
            return true;
        }

        [HttpGet]
        [Route("twoFactorTempKey")]
        [NoEnrichment]
        public async Task<string> GetTwoFactorTempKey()
        {
            return await _twoFactorAuthPreference.ResolveAppTempSecretKey(_securityContext.User.Id) ?? await _twoFactorAuthPreference.GenerateAppTempSecretKey(_securityContext.User.Id);
        }

        [HttpPost]
        [Route("twoFactorTempKeyVerify")]
        [NoEnrichment]
        public async Task<TwoFactorTempKeyVerifyResponse> TwoFactorTempKeyVerify(VerifyRequestModel req)
        {
            var verified = _twoFactorApp.VerifyCode(await _twoFactorAuthPreference.ResolveAppTempSecretKey(_securityContext.User.Id), req.AppCode);
            
            if (!verified)
                return new TwoFactorTempKeyVerifyResponse(TwoFactorTempKeyVerifyResponseStatus.Fail);

            await _twoFactorAuthPreference.SaveAppSecretKeyFromTemp(_securityContext.User.Id);
            return new TwoFactorTempKeyVerifyResponse(TwoFactorTempKeyVerifyResponseStatus.Success);
        }

        public class VerifyRequestModel
        {
            public string AppCode { get; set; }
        }

        public class TwoFactorTempKeyVerifyResponse
        {
            public TwoFactorTempKeyVerifyResponseStatus Status { get; set; }
            public TwoFactorTempKeyVerifyResponse(TwoFactorTempKeyVerifyResponseStatus status)
            {
                Status = status;
            }
        }

        public enum TwoFactorTempKeyVerifyResponseStatus
        {
            Success = 1,
            Fail = 2
        }

        public class UserTwoFactorAuthenticationPreferenceModel
        {
            public List<string> ConfiguredModes { get; set; }
            public string Preference { get; set; }
            public bool Enabled { get; set; }
        }

        [HttpPut]
        [Route("")]
        [NoEnrichment]
        public async Task<HttpResponseMessage> UpdatePreference(TwoFactorPreferenceRequest request)
        {
            var validPreferences = new[] { TwoFactorAuthVerify.App, TwoFactorAuthVerify.Email };
            if (!validPreferences.Contains(request.Preference))
            {
                return Request.CreateResponse(HttpStatusCode.OK, new TwoFactorPreferenceUpdateResponse(TwoFactorAuthPreferenceUpdateStatus.InvalidPreference));
            }

            if (request.Preference == TwoFactorAuthVerify.App && string.IsNullOrWhiteSpace(await _twoFactorAuthPreference.ResolveAppSecretKey(_securityContext.User.Id)))
            {
                return Request.CreateResponse(HttpStatusCode.OK, new TwoFactorPreferenceUpdateResponse(TwoFactorAuthPreferenceUpdateStatus.NoApp));
            }

            await _twoFactorAuthPreference.SetPreference(_securityContext.User.Id, request.Preference);
            return Request.CreateResponse(HttpStatusCode.OK, new TwoFactorPreferenceUpdateResponse(TwoFactorAuthPreferenceUpdateStatus.Success));
        }

        public class TwoFactorPreferenceRequest
        {
            public string Preference { get; set; }
        }

        public class TwoFactorPreferenceUpdateResponse
        {
            public TwoFactorAuthPreferenceUpdateStatus Status { get; set; }
            public TwoFactorPreferenceUpdateResponse(TwoFactorAuthPreferenceUpdateStatus status)
            {
                Status = status;
            }
        }

        public enum TwoFactorAuthPreferenceUpdateStatus
        {
            Undefined = 0,
            Success = 1,
            NoApp = 2,
            InvalidPreference = 3
        }
    }
}
