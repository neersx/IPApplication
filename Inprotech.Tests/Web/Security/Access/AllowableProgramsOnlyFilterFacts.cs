using System.Net.Http;
using System.Threading;
using System.Threading.Tasks;
using System.Web.Http;
using System.Web.Http.Controllers;
using System.Web.Http.Hosting;
using Inprotech.Infrastructure.Security;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Security.Access
{
    public class AllowableProgramsOnlyFilterFacts
    {
        readonly HttpRequestMessage _requestMessage = new HttpRequestMessage(HttpMethod.Get, "http://localhost/api/products");
        public HttpActionContext CreateActionContext(string whichMethod)
        {
            var controllerDescriptor = new HttpControllerDescriptor {ControllerType = typeof(SomeController)};

            _requestMessage.Properties[HttpPropertyKeys.HttpConfigurationKey] = new HttpConfiguration();

            var controllerContext = new HttpControllerContext {Request = _requestMessage, ControllerDescriptor = controllerDescriptor};

            var actionDescriptor = new ReflectedHttpActionDescriptor
            {
                ControllerDescriptor = controllerDescriptor,
                MethodInfo = typeof(SomeController).GetMethod(whichMethod)
            };

            return new HttpActionContext(controllerContext, actionDescriptor);
        }
        public class SomeController
        {
            public void NotProtected(int programId)
            {
            }

            [AllowableProgramsOnly]
            public void ProtectedDefaultParameter()
            {
            }
        }
        
        readonly IAllowableProgramsResolver _allowableProgramsResolver = Substitute.For<IAllowableProgramsResolver>();
        AllowableProgramsOnlyFilter CreateSubject(params string[] values)
        {
            _allowableProgramsResolver.Resolve().Returns(x => values);

            return new AllowableProgramsOnlyFilter(_allowableProgramsResolver);
        }

        [Fact]
        public async Task ShouldThrowExceptionIfProgramIdIsNotOneOfTheAvailablePrograms()
        {
            var programId = Fixture.String();
            var actionContext = CreateActionContext(nameof(SomeController.ProtectedDefaultParameter));

            actionContext.ActionArguments["programId"] = programId;

            var subject = CreateSubject(Fixture.String(), Fixture.String());

            await Assert.ThrowsAsync<HttpResponseException>(async () => await subject.OnActionExecutingAsync(actionContext, CancellationToken.None));
        }

        [Fact]
        public async Task ShouldNotThrowExceptionIfNoAttribute()
        {
            var programId = Fixture.String();
            var actionContext = CreateActionContext(nameof(SomeController.NotProtected));

            actionContext.ActionArguments["programId"] = programId;

            var subject = CreateSubject(Fixture.String(), Fixture.String());

            await subject.OnActionExecutingAsync(actionContext, CancellationToken.None);
        }

        [Fact]
        public async Task ShouldNotThrowExceptionIfProgramIdIsOneOfTheAvailablePrograms()
        {
            var programId = Fixture.String();
            var actionContext = CreateActionContext(nameof(SomeController.ProtectedDefaultParameter));

            actionContext.ActionArguments["programId"] = programId;

            var subject = CreateSubject(programId, Fixture.String(), Fixture.String());

            await subject.OnActionExecutingAsync(actionContext, CancellationToken.None);
        }
    }
}
