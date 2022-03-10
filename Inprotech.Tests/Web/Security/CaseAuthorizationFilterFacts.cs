using System.Net;
using System.Net.Http;
using System.Threading;
using System.Threading.Tasks;
using System.Web.Http;
using System.Web.Http.Controllers;
using System.Web.Http.Hosting;
using Inprotech.Infrastructure.Caching;
using Inprotech.Infrastructure.Diagnostics;
using Inprotech.Infrastructure.Extensions;
using Inprotech.Infrastructure.Security;
using Inprotech.Tests.Extensions;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Security
{
    public class CaseAuthorizationFilterFacts
    {
        readonly int _caseId = Fixture.Integer();
        readonly int _userIdentityId = Fixture.Integer();
        readonly ICaseAuthorization _caseAuthorization = Substitute.For<ICaseAuthorization>();
        readonly ICurrentIdentity _currentIdentity = Substitute.For<ICurrentIdentity>();
        readonly IAuthorizationResultCache _authorizationResultCache = Substitute.For<IAuthorizationResultCache>();
        readonly HttpRequestMessage _requestMessage = new HttpRequestMessage(HttpMethod.Get, "http://localhost/api/products");

        CaseAuthorizationFilter CreateSubject(bool? caseExists = true, bool? authorised = true, string unauthorisedReason = null, AccessPermissionLevel? level = AccessPermissionLevel.Select)
        {
            var levelConcrete = level.GetValueOrDefault();
            var caseExistsReturn = caseExists.GetValueOrDefault();
            var authorisedReturn = authorised.GetValueOrDefault();

            var authorizationResult = new AuthorizationResult(_caseId, caseExistsReturn, !authorisedReturn, unauthorisedReason);

            _caseAuthorization.Authorize(_caseId, levelConcrete).Returns(x => authorizationResult);

            _currentIdentity.IdentityId.Returns(_userIdentityId);

            _authorizationResultCache.TryGetCaseAuthorizationResult(_userIdentityId, _caseId, levelConcrete, out var result)
                                     .Returns(x =>
                                     {
                                         x[3] = null;
                                         return false;
                                     });

            return new CaseAuthorizationFilter(_currentIdentity, _caseAuthorization, _authorizationResultCache);
        }

        public class SomeController
        {
            public const string SpecificParameter = "specificParameter";

            public const string SimplePropertyPathTopLevelParameter = "simpleData";
            public const string SimplePropertyPathParameter = SimplePropertyPathTopLevelParameter + ".SomeCaseId";

            public const string ComplexPropertyPathTopLevelParameter = "complexData";
            public const string ComplexPropertyPathParameter = ComplexPropertyPathTopLevelParameter + ".Deeper.Jackpot.SomeCaseId";

            public void NotProtected(int caseId)
            {
            }

            [RequiresCaseAuthorization]
            public void ProtectedDefaultParameter()
            {
            }

            [RequiresCaseAuthorization(PropertyName = SpecificParameter)]
            public void ProtectedSepecificParameter()
            {
            }

            [RequiresCaseAuthorization(PropertyPath = SimplePropertyPathParameter)]
            public void ProtectedSpecificSimplePropertyPathParameter(SimplePropertyPath simpleData)
            {
            }

            [RequiresCaseAuthorization(PropertyPath = ComplexPropertyPathParameter)]
            public void ProtectedSpecificComplexPropertyPathParameter(ComplexPropertyPath complexData)
            {
            }
        }

        public class SimplePropertyPath
        {
            public int SomeCaseId { get; set; }
        }

        public class ComplexPropertyPath
        {
            public Level Deeper { get; set; }
        }

        public class Level
        {
            public SimplePropertyPath Jackpot { get; set; }
        }

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

        [Theory]
        [InlineData("CaseId")]
        [InlineData("CaseKey")]
        [InlineData("caseId")]
        [InlineData("caseKey")]
        public async Task ShouldFindCaseIdOrCaseKeyFromPayload(string parameterName)
        {
            var actionContext = CreateActionContext(nameof(SomeController.ProtectedDefaultParameter));

            actionContext.ActionArguments[parameterName] = _caseId;

            var subject = CreateSubject();

            await subject.OnActionExecutingAsync(actionContext, CancellationToken.None);

            _caseAuthorization.Received(1).Authorize(_caseId, AccessPermissionLevel.Select)
                              .IgnoreAwaitForNSubstituteAssertion();
        }

        [Theory]
        [InlineData("SomeId", null)]
        [InlineData("SomeOtherId", null)]
        [InlineData(null, "unknownOtherId")]
        public async Task ShouldIgnoreUnrecognisedIdsFromPayload(string defaultParameter, string customParameter)
        {
            var parameterName = !string.IsNullOrWhiteSpace(defaultParameter) ? defaultParameter : customParameter;

            var action = !string.IsNullOrWhiteSpace(defaultParameter)
                ? nameof(SomeController.ProtectedDefaultParameter)
                : nameof(SomeController.ProtectedSepecificParameter);

            var actionContext = CreateActionContext(action);

            actionContext.ActionArguments[parameterName] = _caseId;

            var subject = CreateSubject();

            await subject.OnActionExecutingAsync(actionContext, CancellationToken.None);

            _caseAuthorization.DidNotReceive().Authorize(Arg.Any<int>(), Arg.Any<AccessPermissionLevel>())
                              .IgnoreAwaitForNSubstituteAssertion();
        }

        [Fact]
        public async Task ShouldFindPropertyFromComplexPropertyPathFromPayloadObject()
        {
            var actionContext = CreateActionContext(nameof(SomeController.ProtectedSpecificComplexPropertyPathParameter));

            actionContext.ActionArguments[SomeController.ComplexPropertyPathTopLevelParameter] = new ComplexPropertyPath
            {
                Deeper = new Level
                {
                    Jackpot = new SimplePropertyPath
                    {
                        SomeCaseId = _caseId
                    }
                }
            };

            var subject = CreateSubject();

            await subject.OnActionExecutingAsync(actionContext, CancellationToken.None);

            _caseAuthorization.Received(1).Authorize(_caseId, AccessPermissionLevel.Select)
                              .IgnoreAwaitForNSubstituteAssertion();
        }

        [Fact]
        public async Task ShouldFindPropertyFromPayload()
        {
            var actionContext = CreateActionContext(nameof(SomeController.ProtectedSepecificParameter));

            actionContext.ActionArguments[SomeController.SpecificParameter] = _caseId;

            var subject = CreateSubject();

            await subject.OnActionExecutingAsync(actionContext, CancellationToken.None);

            _caseAuthorization.Received(1).Authorize(_caseId, AccessPermissionLevel.Select)
                              .IgnoreAwaitForNSubstituteAssertion();
        }

        [Fact]
        public async Task ShouldFindPropertyFromSimplePropertyPathFromPayloadObject()
        {
            var actionContext = CreateActionContext(nameof(SomeController.ProtectedSpecificSimplePropertyPathParameter));

            actionContext.ActionArguments[SomeController.SimplePropertyPathTopLevelParameter] = new SimplePropertyPath {SomeCaseId = _caseId};

            var subject = CreateSubject();

            await subject.OnActionExecutingAsync(actionContext, CancellationToken.None);

            _caseAuthorization.Received(1).Authorize(_caseId, AccessPermissionLevel.Select)
                              .IgnoreAwaitForNSubstituteAssertion();
        }

        [Fact]
        public async Task ShouldReturnNotFoundResponse()
        {
            var actionContext = CreateActionContext(nameof(SomeController.ProtectedDefaultParameter));

            actionContext.ActionArguments["caseKey"] = _caseId;

            var subject = CreateSubject(false);

            await subject.OnActionExecutingAsync(actionContext, CancellationToken.None);

            Assert.Equal(HttpStatusCode.NotFound, actionContext.Response.StatusCode);
        }

        [Fact]
        public async Task ShouldThrowDataSecurityExceptionWithReason()
        {
            var unauthorisedReason = Fixture.String();

            var actionContext = CreateActionContext(nameof(SomeController.ProtectedDefaultParameter));

            actionContext.ActionArguments["caseKey"] = _caseId;

            var subject = CreateSubject(authorised: false, unauthorisedReason: unauthorisedReason);

            var exception = await Assert.ThrowsAsync<DataSecurityException>(
                                                                            async () => await subject.OnActionExecutingAsync(actionContext, CancellationToken.None));

            Assert.Equal(unauthorisedReason.CamelCaseToUnderscore(), exception.Message);
        }
    }
}