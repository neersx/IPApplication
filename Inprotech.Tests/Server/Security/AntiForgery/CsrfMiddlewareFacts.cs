using System;
using System.Collections.Generic;
using System.Net;
using System.Threading.Tasks;
using Inprotech.Contracts;
using Inprotech.Infrastructure.Security;
using Inprotech.Infrastructure.Security.AntiForgery;
using Inprotech.Server.Security.AntiForgery;
using Microsoft.Owin;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Server.Security.AntiForgery
{
    public class CsrfMiddlewareFacts : IDisposable
    {
        const string SessionCookieName = ".CPASSInprotech";

        public void Dispose()
        {
            CsrfConfigOptions.IsEnabled = false;
        }

        public class InvokeMethod
        {
            public InvokeMethod()
            {
                CsrfConfigOptions.IsEnabled = true;
            }

            [Fact]
            public async Task ReturnsBadRequestWhenAuthCookieIsNotProvided()
            {
                var fixture = new CsrfMiddlewareFixture();
                fixture.OwinRequest.Headers
                       .Returns(new HeaderDictionary(
                                                     new Dictionary<string, string[]>
                                                     {
                                                         {"Referer", new[] {"something"}}
                                                     }));
                fixture.OwinRequest.Cookies
                       .Returns(new RequestCookieCollection(new Dictionary<string, string>
                       {
                           {"BadCookie", "abcd"}
                       }));

                await fixture.Subject.Invoke(fixture.OwinContext);

                Assert.Equal((int) HttpStatusCode.BadRequest, fixture.OwinResponse.StatusCode);
                Assert.Equal("Auth cookie not sent in the request.", fixture.OwinResponse.ReasonPhrase);
            }

            [Fact]
            public async Task ReturnsBadRequestWhenCsrfCookieIsNotProvided()
            {
                var fixture = new CsrfMiddlewareFixture();
                fixture.OwinRequest.Headers
                       .Returns(new HeaderDictionary(
                                                     new Dictionary<string, string[]>
                                                     {
                                                         {"Referer", new[] {"something"}}
                                                     }));
                fixture.OwinRequest.Cookies
                       .Returns(new RequestCookieCollection(new Dictionary<string, string>
                       {
                           {SessionCookieName, "abcd"}
                       }));

                await fixture.Subject.Invoke(fixture.OwinContext);

                Assert.Equal((int) HttpStatusCode.BadRequest, fixture.OwinResponse.StatusCode);
                Assert.Equal("Csrf cookie not sent in the request.", fixture.OwinResponse.ReasonPhrase);
            }

            [Fact]
            public async Task ReturnsBadRequestWhenCsrfHeaderIsNotCorrect()
            {
                var fixture = new CsrfMiddlewareFixture();
                fixture.OwinRequest.Headers
                       .Returns(new HeaderDictionary(
                                                     new Dictionary<string, string[]>
                                                     {
                                                         {"Referer", new[] {"something"}},
                                                         {CsrfConfigOptions.HeaderName, new[] {"xyz"}}
                                                     }));
                fixture.OwinRequest.Cookies
                       .Returns(new RequestCookieCollection(new Dictionary<string, string>
                       {
                           {SessionCookieName, "abcd"},
                           {CsrfConfigOptions.CookieName, "defg"}
                       }));

                await fixture.Subject.Invoke(fixture.OwinContext);

                Assert.Equal((int) HttpStatusCode.BadRequest, fixture.OwinResponse.StatusCode);
                Assert.Equal("Csrf token in the header and auth cookie token doesnot match.", fixture.OwinResponse.ReasonPhrase);
            }

            [Fact]
            public async Task ReturnsBadRequestWhenCsrfHeaderIsNotProvided()
            {
                var fixture = new CsrfMiddlewareFixture();

                fixture.OwinRequest.Headers
                       .Returns(new HeaderDictionary(
                                                     new Dictionary<string, string[]>
                                                     {
                                                         {"Referer", new[] {"something"}}
                                                     }));
                fixture.OwinRequest.Cookies
                       .Returns(new RequestCookieCollection(new Dictionary<string, string>
                       {
                           {SessionCookieName, "abcd"},
                           {CsrfConfigOptions.CookieName, "abcd"}
                       }));

                await fixture.Subject.Invoke(fixture.OwinContext);

                Assert.Equal((int) HttpStatusCode.BadRequest, fixture.OwinResponse.StatusCode);
                Assert.Equal("Csrf header not present in the request.", fixture.OwinResponse.ReasonPhrase);
            }

            [Fact]
            public async Task ReturnsBadRequestWhenNoCookieIsProvided()
            {
                var fixture = new CsrfMiddlewareFixture();
                fixture.OwinRequest.Headers
                       .Returns(new HeaderDictionary(
                                                     new Dictionary<string, string[]>
                                                     {
                                                         {"Referer", new[] {"something"}}
                                                     }));
                fixture.OwinRequest.Cookies.Returns(new RequestCookieCollection(new Dictionary<string, string>()));

                await fixture.Subject.Invoke(fixture.OwinContext);

                Assert.Equal((int) HttpStatusCode.BadRequest, fixture.OwinResponse.StatusCode);
                Assert.Equal("No cookies in the secured (https) request.", fixture.OwinResponse.ReasonPhrase);
            }
        }

        class CsrfMiddlewareFixture : IFixture<CsrfMiddleware>
        {
            public CsrfMiddlewareFixture()
            {
                OwinContext = Substitute.For<IOwinContext>();

                OwinResponse = Substitute.For<IOwinResponse>();
                OwinRequest = Substitute.For<IOwinRequest>();

                OwinRequest.Uri.Returns(new Uri("http://localhost/apps"));

                Logger = Substitute.For<ILogger<CsrfMiddleware>>();
                AuthSettings = Substitute.For<IAuthSettings>();
                AuthSettings.SessionCookieName.Returns(SessionCookieName);

                OwinContext.Response.Returns(OwinResponse);
                OwinContext.Request.Returns(OwinRequest);

                OwinResponse.Cookies.Returns(new ResponseCookieCollection(Substitute.For<IHeaderDictionary>()));

                Subject = new CsrfMiddleware(null, AuthSettings, Logger);
            }

            public IOwinContext OwinContext { get; }
            public IOwinResponse OwinResponse { get; }
            public IOwinRequest OwinRequest { get; }
            ILogger<CsrfMiddleware> Logger { get; }
            IAuthSettings AuthSettings { get; }
            public CsrfMiddleware Subject { get; }
        }
    }
}