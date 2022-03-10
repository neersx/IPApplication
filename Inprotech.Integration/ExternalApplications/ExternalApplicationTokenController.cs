using System;
using System.Linq;
using System.Web;
using System.Web.Http;
using Inprotech.Infrastructure.Security;
using Inprotech.Infrastructure.Web;
using Inprotech.Integration.Persistence;
using InprotechKaizen.Model.Components.Security;

namespace Inprotech.Integration.ExternalApplications
{
    [Authorize]
    [ViewInitialiser]
    [RequiresAccessTo(ApplicationTask.MaintainApplicationLinkSecurity)]
    [RoutePrefix("api/externalapplication")]
    public class ExternalApplicationTokenController : ApiController
    {
        readonly IRepository _repository;
        readonly ISecurityContext _securityContext;
        readonly Func<DateTime> _systemClock;

        public ExternalApplicationTokenController(
            IRepository repository,
            ISecurityContext securityContext,
            Func<DateTime> systemClock)
        {
            _repository = repository;
            _securityContext = securityContext;
            _systemClock = systemClock;
        }

        [HttpGet]
        [Route("externalapplicationtokenview")]
        public dynamic GetExternalApplications()
        {
            var externalApps =
                _repository.Set<ExternalApplication>()
                           .Where(_ => !_.IsInternalUse)
                           .OrderBy(s => s.Name)
                           .Select(
                                   s => new
                                   {
                                       s.Id,
                                       s.Name,
                                       s.Code,
                                       Token = s.ExternalApplicationToken != null ? s.ExternalApplicationToken.Token : null,
                                       IsActive = s.ExternalApplicationToken != null && s.ExternalApplicationToken.IsActive,
                                       ExpiryDate = s.ExternalApplicationToken != null ? s.ExternalApplicationToken.ExpiryDate : null
                                   }
                    );

            return new
            {
                ExternalApps = externalApps
            };
        }

        [HttpPost]
        [Route("externalapplicationtoken/generatetoken")]
        public dynamic GenerateToken(int externalApplicationId)
        {
            var exApp = _repository.Set<ExternalApplication>().FirstOrDefault(app => app.Id == externalApplicationId);
            if (exApp == null)
                throw new HttpException(404, "Unable to generate token for non-existent external application.");

            var token = Guid.NewGuid().ToString();
            var appToken = exApp.ExternalApplicationToken;
            if (appToken == null)
            {
                appToken = new ExternalApplicationToken
                {
                    ExternalApplication = exApp,
                    ExternalApplicationId = externalApplicationId
                };
                _repository.Set<ExternalApplicationToken>().Add(appToken);
            }
            appToken.Token = token;
            appToken.CreatedBy = _securityContext.User.Id;
            appToken.CreatedOn = _systemClock();
            appToken.IsActive = true;
            if (appToken.ExpiryDate.HasValue && appToken.ExpiryDate < DateTime.Today)
            {
                appToken.ExpiryDate = null;
            }
            
            _repository.SaveChanges();

            return new { Result = "success", appToken.Token, appToken.IsActive, appToken.ExpiryDate };
        }

        [HttpGet]
        [Route("externalapplicationtokeneditview")]
        public dynamic GetExternalApplicationToken(int id)
        {
            var externalApp = _repository.Set<ExternalApplication>().FirstOrDefault(app => app.Id == id);

            if (externalApp == null)
                throw new ArgumentException("Given external application id doesn't exist.");

            return new
            {
                ExternalApplicationId = externalApp.Id,
                externalApp.Name,
                externalApp.Code,
                Token = externalApp.ExternalApplicationToken != null ? externalApp.ExternalApplicationToken.Token : null,
                IsActive = externalApp.ExternalApplicationToken != null && externalApp.ExternalApplicationToken.IsActive,
                ExpiryDate = externalApp.ExternalApplicationToken != null && externalApp.ExternalApplicationToken.ExpiryDate.HasValue
                                        ? externalApp.ExternalApplicationToken.ExpiryDate.Value.ToString("dd-MMM-yyyy") : null

            };
        }

        [HttpPost]
        [Route("externalapplicationtoken/save")]
        public dynamic SaveChanges(ExternalApplicationToken app)
        {
            var exApp = _repository.Set<ExternalApplication>().FirstOrDefault(ex => ex.Id == app.ExternalApplicationId);
            if (exApp == null || exApp.ExternalApplicationToken == null)
                throw new HttpException(404,"Unable to update a non-existent external application token.");

            exApp.ExternalApplicationToken.IsActive = app.IsActive;
            exApp.ExternalApplicationToken.ExpiryDate = app.ExpiryDate;
            _repository.SaveChanges();
            return new { Result = "success" };
        }
    }
}
