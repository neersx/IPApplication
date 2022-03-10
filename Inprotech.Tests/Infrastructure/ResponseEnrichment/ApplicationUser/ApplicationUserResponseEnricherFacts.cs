using System;
using System.Collections.Generic;
using System.Net.Http;
using System.Security.Claims;
using System.Web.Http.Controllers;
using System.Web.Http.Filters;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Infrastructure.Policy;
using Inprotech.Infrastructure.ResponseEnrichment.ApplicationUser;
using Inprotech.Infrastructure.ResponseEnrichment.Localisation;
using Inprotech.Infrastructure.Security;
using Inprotech.Infrastructure.Web;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Infrastructure.ResponseEnrichment.ApplicationUser
{
    public class ApplicationUserResponseEnricherFacts
    {
        public class ApplicationUserResponseEnricherFixture : IFixture<ApplicationUserResponseEnricher>
        {
            public ApplicationUserResponseEnricherFixture()
            {
                CurrentUser = Substitute.For<ICurrentUser>();

                PreferredCultureResolver = Substitute.For<IPreferredCultureResolver>();

                SiteDateFormat = Substitute.For<ISiteDateFormat>();

                Resources = Substitute.For<IResources>();

                Permissions = Substitute.For<IAccessPermissions>();

                SiteCurrencyFormat = Substitute.For<ISiteCurrencyFormat>();

                KendoLocale = Substitute.For<IKendoLocale>();

                HomeStateResolver = Substitute.For<IHomeStateResolver>();

                Subject = new ApplicationUserResponseEnricher(CurrentUser, PreferredCultureResolver, SiteDateFormat, Resources, Permissions, SiteCurrencyFormat, KendoLocale, HomeStateResolver);
            }

            public ICurrentUser CurrentUser { get; set; }

            public IPreferredCultureResolver PreferredCultureResolver { get; set; }

            public ISiteDateFormat SiteDateFormat { get; set; }

            public IResources Resources { get; set; }

            public IAccessPermissions Permissions { get; set; }

            public ISiteCurrencyFormat SiteCurrencyFormat { get; set; }

            public IKendoLocale KendoLocale { get; set; }

            public IHomeStateResolver HomeStateResolver { get; set; }

            public ApplicationUserResponseEnricher Subject { get; }

            public HttpActionExecutedContext CreateActionExecutedContext(string uri = "/api/uspto/inbox")
            {
                var actionDescriptor = new ReflectedHttpActionDescriptor();

                var controllerContext = new HttpControllerContext
                {
                    Request = new HttpRequestMessage(HttpMethod.Get, new Uri(new Uri("http://myorg/cpainpro/i"), uri))
                };

                var actionContext = new HttpActionContext(controllerContext, actionDescriptor);

                return new HttpActionExecutedContext(actionContext, null);
            }
        }

        public class EnrichMethod
        {
            public EnrichMethod()
            {
                _fixture = new ApplicationUserResponseEnricherFixture();
                _fixture.PreferredCultureResolver.ResolveAll().ReturnsForAnyArgs(new[] { "en-AU" });
                _fixture.CurrentUser.Identity.Returns(new ClaimsIdentity(new[] { new Claim(ClaimTypes.Name, "bob"), new Claim(CustomClaimTypes.DisplayName, "bob"), new Claim(CustomClaimTypes.IsExternalUser, "false"), new Claim(CustomClaimTypes.Id, "45"), new Claim(CustomClaimTypes.NameId, "-487") }));
                _context = new Dictionary<string, object>();
            }

            readonly ApplicationUserResponseEnricherFixture _fixture;
            readonly Dictionary<string, object> _context;

            dynamic Preferences => ((Dictionary<string, object>)_context["intendedFor"])["preferences"];
            
            [Fact]
            public void ReturnsApplicationUser()
            {
                _fixture.Subject.Enrich(_fixture.CreateActionExecutedContext(), _context);

                Assert.Equal("bob", ((Dictionary<string, object>)_context["intendedFor"])["displayName"]);
                Assert.Equal("45", ((Dictionary<string, object>)_context["intendedFor"])["identityId"]);
            }

            [Fact]
            public void ReturnsCulture()
            {
                _fixture.PreferredCultureResolver.ResolveAll().ReturnsForAnyArgs(new[] { "en-AU" });
                _fixture.Subject.Enrich(_fixture.CreateActionExecutedContext(), _context);

                Assert.Equal("en-AU", Preferences.Culture);
            }

            [Fact]
            public void ReturnsDateFormat()
            {
                var dateFormat = Fixture.String();

                _fixture.SiteDateFormat.Resolve().ReturnsForAnyArgs(dateFormat);
                _fixture.Subject.Enrich(_fixture.CreateActionExecutedContext(), _context);

                Assert.Equal(dateFormat, Preferences.DateFormat);
            }

            [Fact]
            public void ReturnsEmptyIfNoPreferredCulture()
            {
                _fixture.PreferredCultureResolver.ResolveAll().ReturnsForAnyArgs(new[] { (string)null });
                _fixture.Subject.Enrich(_fixture.CreateActionExecutedContext(), _context);

                Assert.Null(Preferences.Culture);
            }

            [Fact]
            public void ReturnsResource()
            {
                var resources = new List<Resource>();

                _fixture.PreferredCultureResolver.ResolveAll().Returns(new[] { "fr-FR", "fr" });

                _fixture.Resources.Resolve(Arg.Any<string>(), Arg.Any<string>()).Returns(resources);

                _fixture.Subject.Enrich(_fixture.CreateActionExecutedContext(), _context);

                Assert.Equal(resources, Preferences.Resources);
            }

            [Fact]
            public void ReturnsPermission()
            {
                var permission = new object();
                _fixture.Permissions.GetAccessPermissions().Returns(permission);
                _fixture.Subject.Enrich(_fixture.CreateActionExecutedContext(), _context);
                Assert.Equal(permission, ((Dictionary<string, object>)_context["intendedFor"])["permissions"]);
            }

            [Fact]
            public void ReturnsCurrencyFormat()
            {
                var currencyFormat = new LocalCurrency {LocalCurrencyCode = "BFG", LocalDecimalPlaces = 3};
                _fixture.SiteCurrencyFormat.Resolve().ReturnsForAnyArgs(currencyFormat);
                _fixture.Subject.Enrich(_fixture.CreateActionExecutedContext(), _context);
                Assert.Equal(currencyFormat, Preferences.CurrencyFormat);
            }

            [Fact]
            public void ReturnsKendoLocale()
            {
                var theLocale = Fixture.String();
                _fixture.KendoLocale.Resolve(Fixture.String()).ReturnsForAnyArgs(theLocale);
                _fixture.Subject.Enrich(_fixture.CreateActionExecutedContext(), _context);
                Assert.Equal(theLocale, Preferences.KendoLocale);
            }

            [Fact]
            public void ReturnsHomePage()
            {
                var homePageState = Fixture.String();
                _fixture.HomeStateResolver.Resolve().ReturnsForAnyArgs(homePageState);
                _fixture.Subject.Enrich(_fixture.CreateActionExecutedContext(), _context);
                Assert.Equal(homePageState, Preferences.HomePageState);
            }
        }
    }
}