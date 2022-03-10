using System.Collections.Generic;
using System.Linq;
using System.Net;
using System.Net.Http;
using System.Web.Http;
using System.Web.Http.Controllers;
using System.Web.Http.Hosting;
using Inprotech.Integration.Security.Licensing;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Integration.Trinogy.Security
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
            public LicenseAuthorisationFilter Subject { get; private set; }
            public ILicenseAuthorization LicenseAuthorization { get; private set; }

            public LicenseAuthorizationFilterFixture()
            {
                LicenseAuthorization = Substitute.For<ILicenseAuthorization>();
                
                Subject = new LicenseAuthorisationFilter(LicenseAuthorization);
            }

            public HttpActionContext CreateActionContext(HttpRequestMessage request, LicenseAuthorizationOption licenseAuthorizationOption)
            {
                var whichClass = licenseAuthorizationOption == LicenseAuthorizationOption.OptedOut
                                      ? "NotDecoratedClass"
                                      : "DecoratedClass";

                var controllerDescriptor = new HttpControllerDescriptor
                                           {
                                               ControllerType =
                                                   whichClass == "NotDecoratedClass"
                                                       ? typeof (NotDecoratedClass)
                                                       : typeof (DecoratedClass)
                                           };

                request.Properties[HttpPropertyKeys.HttpConfigurationKey] = new HttpConfiguration();;

                var controllerContext = new HttpControllerContext() { Request = request, ControllerDescriptor = controllerDescriptor };

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
            public void ReturnsHttpResponseExceptionWhenLicenseAuthorizationFails()
            {
                var f = new LicenseAuthorizationFilterFixture();

                var httpRequest = new HttpRequestMessage(HttpMethod.Get, "http://localhost/api/products");

                var actionContext = f.CreateActionContext(httpRequest, LicenseAuthorizationOption.OptedFor);

                f.LicenseAuthorization.Authorize(Arg.Any<IEnumerable<RequiresLicenseAttribute>>()).Returns(false);

                var exception =
                   Record.Exception(() => f.Subject.OnAuthorization(actionContext));

                Assert.IsType<HttpResponseException>(exception);
                Assert.Equal(HttpStatusCode.Forbidden, ((HttpResponseException)exception).Response.StatusCode);
            }

            [Fact]
            public void DoesNotThrowHttpResponseExceptionWhenLicenseAuthorizationSucceeds()
            {
                var f = new LicenseAuthorizationFilterFixture();

                var httpRequest = new HttpRequestMessage(HttpMethod.Get, "http://localhost/api/products");

                var actionContext = f.CreateActionContext(httpRequest, LicenseAuthorizationOption.OptedFor);

                f.LicenseAuthorization.Authorize(Arg.Any<IEnumerable<RequiresLicenseAttribute>>()).Returns(true);

                var exception =
                   Record.Exception(() => f.Subject.OnAuthorization(actionContext));

                Assert.True(exception == null);
            }
        }
    }
}
