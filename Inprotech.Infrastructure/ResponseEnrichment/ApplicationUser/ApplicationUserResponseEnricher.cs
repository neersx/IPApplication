using System;
using System.Collections.Generic;
using System.Globalization;
using System.Linq;
using System.Threading.Tasks;
using System.Web.Http.Filters;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Infrastructure.Policy;
using Inprotech.Infrastructure.ResponseEnrichment.Localisation;
using Inprotech.Infrastructure.Security;
using Inprotech.Infrastructure.Web;

namespace Inprotech.Infrastructure.ResponseEnrichment.ApplicationUser
{
    public class ApplicationUserResponseEnricher : IResponseEnricher
    {
        readonly ICurrentUser _currentUser;
        readonly IPreferredCultureResolver _preferredCultureResolver;
        readonly IResources _resources;
        readonly ISiteDateFormat _siteDateFormat;
        readonly IAccessPermissions _accessPermissions;
        readonly ISiteCurrencyFormat _currencyFormat;
        readonly IKendoLocale _kendoLocale;
        readonly IHomeStateResolver _homeStateResolver;

        public ApplicationUserResponseEnricher(ICurrentUser currentUser,
                                               IPreferredCultureResolver preferredCultureResolver,
                                               ISiteDateFormat siteDateFormat,
                                               IResources resources,
                                               IAccessPermissions accessPermissions,
                                               ISiteCurrencyFormat currencyFormat,
                                               IKendoLocale kendoLocale,
                                               IHomeStateResolver homeStateResolver)
        {
            _currentUser = currentUser;
            _preferredCultureResolver = preferredCultureResolver;
            _siteDateFormat = siteDateFormat;
            _resources = resources;
            _accessPermissions = accessPermissions;
            _currencyFormat = currencyFormat;
            _kendoLocale = kendoLocale;
            _homeStateResolver = homeStateResolver;
        }

        public Task Enrich(HttpActionExecutedContext actionExecutedContext, Dictionary<string, object> enrichment)
        {
            if (actionExecutedContext == null) throw new ArgumentNullException(nameof(actionExecutedContext));
            if (enrichment == null) throw new ArgumentNullException(nameof(enrichment));

            if (_currentUser.Identity != null)
            {
                var displayName = _currentUser.Identity.Claims.Single(c => c.Type == CustomClaimTypes.DisplayName).Value;
                var identityId = _currentUser.Identity.Claims.Single(c => c.Type == CustomClaimTypes.Id).Value;
                var nameId = _currentUser.Identity.Claims.Single(c => c.Type == CustomClaimTypes.NameId).Value;
                var cultures = _preferredCultureResolver.ResolveAll().ToArray();
                var specificCulture = cultures.ElementAtOrDefault(0);
                var fallbackLanguage = cultures.ElementAtOrDefault(1);
                enrichment.Add(
                               "intendedFor",
                               new Dictionary<string, object>
                               {
                                   {"name", _currentUser.Identity.Name},
                                   {"nameId", nameId},
                                   {"identityId", identityId},
                                   {
                                       "preferences", new
                                       {
                                           Culture = specificCulture,
                                           CultureName = CultureInfo.GetCultures(CultureTypes.AllCultures).FirstOrDefault(_ => _.Name == specificCulture)?.DisplayName ?? specificCulture,
                                           Resources = _resources.Resolve(specificCulture, fallbackLanguage),
                                           DateFormat = _siteDateFormat.Resolve(specificCulture),
                                           CurrencyFormat = _currencyFormat.Resolve(),
                                           KendoLocale = _kendoLocale.Resolve(specificCulture),
                                           HomePageState = _homeStateResolver.Resolve()
                                       }
                                   },
                                   {"displayName", displayName},
                                   {"isExternal", Convert.ToBoolean(_currentUser.Identity.Claims.Single(c => c.Type == CustomClaimTypes.IsExternalUser).Value)},
                                   {"permissions", _accessPermissions.GetAccessPermissions()}
                               });
            }

            return Task.FromResult(0);
        }
    }
}