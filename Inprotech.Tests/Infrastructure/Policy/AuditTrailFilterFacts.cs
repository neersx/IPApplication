using System.Collections.ObjectModel;
using System.Net.Http;
using System.Security.Principal;
using System.Threading;
using System.Threading.Tasks;
using System.Web.Http;
using System.Web.Http.Controllers;
using System.Web.Http.Hosting;
using Inprotech.Infrastructure;
using Inprotech.Infrastructure.Policy;
using Inprotech.Infrastructure.Web;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Infrastructure.Policy
{
    public class AuditTrailFilterFacts
    {
        [Theory]
        [InlineData("GET")]
        public async Task ShouldStartAuditTrailWithNoComponentIdForAuthorisedRequests(string httpMethod)
        {
            var authorisedPrincipal = new GenericPrincipal(new GenericIdentity(Fixture.String()), new string[0]);

            var auditTrail = Substitute.For<IAuditTrail>();
            var componentResolver = Substitute.For<IComponentResolver>();

            var subject = new AuditTrailFilter(auditTrail, componentResolver);

            await subject.OnActionExecutingAsync(CreateActionContext(httpMethod, authorisedPrincipal), CancellationToken.None);

            auditTrail.Received(1).Start();
        }

        [Theory]
        [InlineData("POST")]
        [InlineData("PUT")]
        [InlineData("DELETE")]
        public async Task ShouldStartAuditTrailWithComponentIdForAuthorisedRequests(string httpMethod)
        {
            var authorisedPrincipal = new GenericPrincipal(new GenericIdentity(Fixture.String()), new string[0]);

            var auditTrail = Substitute.For<IAuditTrail>();
            var componentResolver = Substitute.For<IComponentResolver>();

            var componentId = Fixture.Integer();
            componentResolver.Resolve(Arg.Any<string>()).Returns(componentId);

            var subject = new AuditTrailFilter(auditTrail, componentResolver);

            await subject.OnActionExecutingAsync(CreateActionContext(httpMethod, authorisedPrincipal, true), CancellationToken.None);

            auditTrail.Received(1).Start(componentId);
        }

        [Theory]
        [InlineData("GET")]
        [InlineData("POST")]
        [InlineData("PUT")]
        [InlineData("DELETE")]
        public async Task ShouldNotStartAuditTrailForUnauthorisedRequests(string httpMethod)
        {
            // an unauthorised principal is one that has an empty string as name.
            var unauthorisedPrincipal = new GenericPrincipal(new GenericIdentity(string.Empty), new string[0]);

            var auditTrail = Substitute.For<IAuditTrail>();

            var componentResolver = Substitute.For<IComponentResolver>();

            var subject = new AuditTrailFilter(auditTrail, componentResolver);

            await subject.OnActionExecutingAsync(CreateActionContext(httpMethod, unauthorisedPrincipal), CancellationToken.None);

            auditTrail.DidNotReceive().Start();
        }

        static HttpActionContext CreateActionContext(string httpMethod, IPrincipal principal = null, bool withAttribute = false)
        {
            var controllerDescriptor = new HttpControllerDescriptor();

            var request = new HttpRequestMessage(new HttpMethod(httpMethod), "/anywhere");
            request.Properties[HttpPropertyKeys.HttpConfigurationKey] = new HttpConfiguration();
            request.Properties[HttpPropertyKeys.RequestContextKey] = new HttpRequestContext
            {
                Principal = principal
            };

            var controllerContext = new HttpControllerContext {Request = request, ControllerDescriptor = controllerDescriptor};

            var actionDescriptor = Substitute.For<ReflectedHttpActionDescriptor>();
            actionDescriptor.ControllerDescriptor = controllerDescriptor;

            if(withAttribute)
                actionDescriptor.GetCustomAttributes<AppliesToComponentAttribute>()
                        .Returns(new Collection<AppliesToComponentAttribute>());
            
            return new HttpActionContext(controllerContext, actionDescriptor);
        }
    }
}