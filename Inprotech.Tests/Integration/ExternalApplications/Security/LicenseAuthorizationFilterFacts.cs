using System.Collections.Generic;
using System.Net;
using System.Net.Http;
using System.Threading;
using System.Threading.Tasks;
using System.Web.Http;
using System.Web.Http.Controllers;
using System.Web.Http.Hosting;
using Inprotech.Infrastructure.Security;
using Inprotech.Infrastructure.Security.Licensing;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Integration.ExternalApplications.Security
{
    public class LicenseAuthorizationFilterFacts
    {
        public enum LicenseAuthorizationOption
        {
            OptedOut,
            OptedFor
        }

        public class LicenseAuthorizationFilterFixture : IFixture<LicenseAuthorisationFilter>
        {
            public LicenseAuthorizationFilterFixture()
            {
                LicenseAuthorization = Substitute.For<ILicenseAuthorization>();

                Subject = new LicenseAuthorisationFilter(LicenseAuthorization);
            }

            public ILicenseAuthorization LicenseAuthorization { get; }
            public LicenseAuthorisationFilter Subject { get; }

            public HttpActionContext CreateActionContext(HttpRequestMessage request, LicenseAuthorizationOption licenseAuthorizationOption)
            {
                var whichClass = licenseAuthorizationOption == LicenseAuthorizationOption.OptedOut
                    ? "NotDecoratedClass"
                    : "DecoratedClass";

                var controllerDescriptor = new HttpControllerDescriptor
                {
                    ControllerType =
                        whichClass == "NotDecoratedClass"
                            ? typeof(NotDecoratedClass)
                            : typeof(DecoratedClass)
                };

                request.Properties[HttpPropertyKeys.HttpConfigurationKey] = new HttpConfiguration();

                var controllerContext = new HttpControllerContext {Request = request, ControllerDescriptor = controllerDescriptor};

                var actionDescriptor = new ReflectedHttpActionDescriptor {ControllerDescriptor = controllerDescriptor};

                return new HttpActionContext(
                                             controllerContext, actionDescriptor);
            }

            public class NotDecoratedClass
            {
            }

            [RequiresLicense(LicensedModule.CrmWorkBench)]
            public class DecoratedClass
            {
            }
        }

        public class OnAuthorizationMethod : FactBase
        {
            [Fact]
            public async Task DoesNotThrowHttpResponseExceptionWhenLicenseAuthorizationSucceeds()
            {
                var f = new LicenseAuthorizationFilterFixture();

                var httpRequest = new HttpRequestMessage(HttpMethod.Get, "http://localhost/api/products");

                var actionContext = f.CreateActionContext(httpRequest, LicenseAuthorizationOption.OptedFor);

                f.LicenseAuthorization.Authorize(Arg.Any<IEnumerable<RequiresLicenseAttribute>>()).Returns(true);

                await f.Subject.OnAuthorizationAsync(actionContext, CancellationToken.None);
            }

            [Fact]
            public async Task ReturnsHttpResponseExceptionWhenLicenseAuthorizationFails()
            {
                var f = new LicenseAuthorizationFilterFixture();

                var httpRequest = new HttpRequestMessage(HttpMethod.Get, "http://localhost/api/products");

                var actionContext = f.CreateActionContext(httpRequest, LicenseAuthorizationOption.OptedFor);

                f.LicenseAuthorization.Authorize(Arg.Any<IEnumerable<RequiresLicenseAttribute>>()).Returns(false);

                var exception = await Assert.ThrowsAsync<HttpResponseException>(
                                                                                async () => await f.Subject.OnAuthorizationAsync(actionContext, CancellationToken.None));

                Assert.Equal(HttpStatusCode.Forbidden, exception.Response.StatusCode);
            }

            [Fact]
            public async Task ReturnsWithoutExecutingAuthorizeMethod()
            {
                var f = new LicenseAuthorizationFilterFixture();

                var httpRequest = new HttpRequestMessage(HttpMethod.Get, "http://localhost/api/products");

                var actionContext = f.CreateActionContext(httpRequest, LicenseAuthorizationOption.OptedOut);

                f.LicenseAuthorization.Authorize(Arg.Any<IEnumerable<RequiresLicenseAttribute>>()).Returns(true);

                await f.Subject.OnAuthorizationAsync(actionContext, CancellationToken.None);
            }
        }
    }
}