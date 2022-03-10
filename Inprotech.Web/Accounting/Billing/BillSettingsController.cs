using System;
using System.IdentityModel;
using System.Linq;
using System.Threading.Tasks;
using System.Web.Http;
using Inprotech.Infrastructure.Formatting;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Infrastructure.ResponseEnrichment;
using Inprotech.Infrastructure.Security;
using Inprotech.Infrastructure.Security.Licensing;
using InprotechKaizen.Model.Components.Accounting.Billing;
using InprotechKaizen.Model.Components.Security;

namespace Inprotech.Web.Accounting.Billing
{
    [Authorize]
    [NoEnrichment]
    [UseDefaultContractResolver]
    [RoutePrefix("api/accounting/billing")]
    [RequiresLicense(LicensedModule.Billing)]
    [RequiresLicense(LicensedModule.TimeandBillingModule)]
    public class BillSettingsController : ApiController
    {
        readonly ISecurityContext _securityContext;
        readonly IBillSettingsResolver _billSettingsResolver;
        readonly IBillingSiteSettingsResolver _billingSiteSettingsResolver;
        readonly IBillingUserPermissionSettingsResolver _billingUserPermissionSettingsResolver;
        readonly IPreferredCultureResolver _preferredCultureResolver;

        public BillSettingsController(
            ISecurityContext securityContext,
            IBillSettingsResolver billSettingsResolver,
            IBillingSiteSettingsResolver billingSiteSettingsResolver,
            IBillingUserPermissionSettingsResolver billingUserPermissionSettingsResolver,
            IPreferredCultureResolver preferredCultureResolver)
        {
            _securityContext = securityContext;
            _billSettingsResolver = billSettingsResolver;
            _billingSiteSettingsResolver = billingSiteSettingsResolver;
            _billingUserPermissionSettingsResolver = billingUserPermissionSettingsResolver;
            _preferredCultureResolver = preferredCultureResolver;
        }

        [HttpGet]
        [Route("settings")]
        [RequiresCaseAuthorization]
        [RequiresNameAuthorization(PropertyName = "debtorId")]
        public async Task<Settings> GetSettings(string scope, int? debtorId = null, int? caseId = null, int? entityId = null, string action = null)
        {
            var scopeRequested = (scope ?? "site")
                                 .Split(new[] { "," }, StringSplitOptions.RemoveEmptyEntries)
                                 .ToArray();

            var settings = new Settings();

            if (scopeRequested.Contains("site"))
            {
                settings.Site = await _billingSiteSettingsResolver.Resolve(new BillingSiteSettingsScope
                {
                    Scope = SettingsResolverScope.IncludeUserSpecificSettings,
                    UserIdentityId = _securityContext.IdentityId,
                    Culture = _preferredCultureResolver.Resolve()
                });
            }

            if (scopeRequested.Contains("user"))
            {
                settings.User = await _billingUserPermissionSettingsResolver.Resolve();
            }

            if (scopeRequested.Contains("bill"))
            {
                if (debtorId == null)
                {
                    throw new BadRequestException("bill setting requires DebtorId as a parameter");
                }

                settings.Bill = await _billSettingsResolver.Resolve((int)debtorId, caseId, action, entityId);
            }

            return settings;
        }
        
        public class Settings
        {
            public BillingSiteSettings Site { get; set; }

            public BillingUserPermissionsSettings User { get; set; }

            public BillSettings Bill { get; set; }
        }
    }
}