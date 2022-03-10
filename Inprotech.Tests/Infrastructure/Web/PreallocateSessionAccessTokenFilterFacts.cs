using System.Net.Http;
using System.Threading;
using System.Threading.Tasks;
using System.Web.Http;
using System.Web.Http.Controllers;
using System.Web.Http.Hosting;
using Inprotech.Infrastructure.Web;
using Inprotech.Tests.Extensions;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Infrastructure.Web
{
    public class PreallocateOneTimeAccessTokenFilterFacts
    {
        public class Fixtures
        {
            [PreallocateSessionAccessToken]
            public class DecoratedOnClass
            {
                public void DoStuff()
                {
                }
            }

            public class DecoratedOnAction
            {
                [PreallocateSessionAccessToken]
                public void DoStuff()
                {
                }
            }

            public class NotDecoratedClass
            {
                public void DoStuff()
                {
                }
            }

            public class NotDecoratedAction
            {
                public void DoStuff()
                {
                }
            }
        }

        readonly ISessionAccessTokenGenerator _oneTimeAccessTokenGenerator = Substitute.For<ISessionAccessTokenGenerator>();

        HttpActionContext CreateActionContext<T>(T controller)
        {
            var controllerDescriptor = new HttpControllerDescriptor
            {
                ControllerType = controller.GetType()
            };

            var request = new HttpRequestMessage(HttpMethod.Get, "/anywhere");
            request.Properties[HttpPropertyKeys.HttpConfigurationKey] = new HttpConfiguration();

            var controllerContext = new HttpControllerContext {Request = request, ControllerDescriptor = controllerDescriptor};

            var actionDescriptor = new ReflectedHttpActionDescriptor
            {
                ControllerDescriptor = controllerDescriptor,
                MethodInfo = controller.GetType().GetMethod("DoStuff")
            };

            return new HttpActionContext(controllerContext, actionDescriptor);
        }

        [Fact]
        public async Task ShouldGenerateAccessTokenAsIndicatedOnApiControllerAction()
        {
            var subject = new PreallocateSessionAccessTokenFilter(_oneTimeAccessTokenGenerator);

            var actionContext = CreateActionContext(new Fixtures.DecoratedOnAction());

            await subject.OnActionExecutingAsync(actionContext, CancellationToken.None);

            _oneTimeAccessTokenGenerator.Received(1).GetOrCreateAccessToken()
                                        .IgnoreAwaitForNSubstituteAssertion();
        }

        [Fact]
        public async Task ShouldGenerateAccessTokenAsIndicatedOnApiControllerClass()
        {
            var subject = new PreallocateSessionAccessTokenFilter(_oneTimeAccessTokenGenerator);

            var actionContext = CreateActionContext(new Fixtures.DecoratedOnClass());

            await subject.OnActionExecutingAsync(actionContext, CancellationToken.None);

            _oneTimeAccessTokenGenerator.Received(1).GetOrCreateAccessToken()
                                        .IgnoreAwaitForNSubstituteAssertion();
        }

        [Fact]
        public async Task ShouldNotGenerateAccessTokenAsNotIndicatedOnApiControllerAction()
        {
            var subject = new PreallocateSessionAccessTokenFilter(_oneTimeAccessTokenGenerator);

            var actionContext = CreateActionContext(new Fixtures.NotDecoratedAction());

            await subject.OnActionExecutingAsync(actionContext, CancellationToken.None);

            _oneTimeAccessTokenGenerator.DidNotReceive().GetOrCreateAccessToken()
                                        .IgnoreAwaitForNSubstituteAssertion();
        }

        [Fact]
        public async Task ShouldNotGenerateAccessTokenAsNotIndicatedOnApiControllerClass()
        {
            var subject = new PreallocateSessionAccessTokenFilter(_oneTimeAccessTokenGenerator);

            var actionContext = CreateActionContext(new Fixtures.NotDecoratedClass());

            await subject.OnActionExecutingAsync(actionContext, CancellationToken.None);

            _oneTimeAccessTokenGenerator.DidNotReceive().GetOrCreateAccessToken()
                                        .IgnoreAwaitForNSubstituteAssertion();
        }
    }
}