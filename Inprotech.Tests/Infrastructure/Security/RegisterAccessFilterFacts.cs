using System.Net.Http;
using System.Threading;
using System.Threading.Tasks;
using System.Web.Http;
using System.Web.Http.Controllers;
using System.Web.Http.Hosting;
using Inprotech.Infrastructure.Security;
using Inprotech.Tests.Extensions;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Infrastructure.Security
{
    public class RegisterAccessFilterFacts
    {
        readonly int _caseId = Fixture.Integer();
        readonly IRegisterAccess _registerAccess = Substitute.For<IRegisterAccess>();
        readonly HttpRequestMessage _requestMessage = new HttpRequestMessage(HttpMethod.Get, "http://localhost/api/products");

        class SomeController
        {
            public const string SpecificParameter = "specificParameter";

            public const string SimplePropertyPathTopLevelParameter = "simpleData";
            const string SimplePropertyPathParameter = SimplePropertyPathTopLevelParameter + ".SomeCaseId";

            public const string ComplexPropertyPathTopLevelParameter = "complexData";
            const string ComplexPropertyPathParameter = ComplexPropertyPathTopLevelParameter + ".Deeper.Jackpot.SomeCaseId";

            public void NotProtected(int caseId)
            {
            }

            [RegisterAccess]
            public void ProtectedDefaultParameter()
            {
            }

            [RegisterAccess(PropertyName = SpecificParameter)]
            public void ProtectedSepecificParameter()
            {
            }

            [RegisterAccess(PropertyPath = SimplePropertyPathParameter)]
            public void ProtectedSpecificSimplePropertyPathParameter(SimplePropertyPath simpleData)
            {
            }

            [RegisterAccess(PropertyPath = ComplexPropertyPathParameter)]
            public void ProtectedSpecificComplexPropertyPathParameter(ComplexPropertyPath complexData)
            {
            }
        }

        HttpActionContext CreateActionContext(string whichMethod)
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

        class SimplePropertyPath
        {
            public int SomeCaseId { get; set; }
        }

        class ComplexPropertyPath
        {
            public Level Deeper { get; set; }
        }

        class Level
        {
            public SimplePropertyPath Jackpot { get; set; }
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

            var subject = new RegisterAccessFilter(_registerAccess);

            await subject.OnActionExecutingAsync(actionContext, CancellationToken.None);

            _registerAccess.Received(1).ForCase(_caseId)
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

            var subject = new RegisterAccessFilter(_registerAccess);

            await subject.OnActionExecutingAsync(actionContext, CancellationToken.None);

            _registerAccess.DidNotReceive().ForCase(Arg.Any<int>())
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

            var subject = new RegisterAccessFilter(_registerAccess);

            await subject.OnActionExecutingAsync(actionContext, CancellationToken.None);

            _registerAccess.Received(1).ForCase(_caseId)
                           .IgnoreAwaitForNSubstituteAssertion();
        }

        [Fact]
        public async Task ShouldFindPropertyFromPayload()
        {
            var actionContext = CreateActionContext(nameof(SomeController.ProtectedSepecificParameter));

            actionContext.ActionArguments[SomeController.SpecificParameter] = _caseId;

            var subject = new RegisterAccessFilter(_registerAccess);

            await subject.OnActionExecutingAsync(actionContext, CancellationToken.None);

            _registerAccess.Received(1).ForCase(_caseId)
                           .IgnoreAwaitForNSubstituteAssertion();
        }

        [Fact]
        public async Task ShouldFindPropertyFromSimplePropertyPathFromPayloadObject()
        {
            var actionContext = CreateActionContext(nameof(SomeController.ProtectedSpecificSimplePropertyPathParameter));

            actionContext.ActionArguments[SomeController.SimplePropertyPathTopLevelParameter] = new SimplePropertyPath {SomeCaseId = _caseId};

            var subject = new RegisterAccessFilter(_registerAccess);

            await subject.OnActionExecutingAsync(actionContext, CancellationToken.None);

            _registerAccess.Received(1).ForCase(_caseId)
                           .IgnoreAwaitForNSubstituteAssertion();
        }

        [Fact]
        public async Task ShouldNotProcessFilterIfAttributeNotPresent()
        {
            var actionContext = CreateActionContext(nameof(SomeController.NotProtected));

            var subject = new RegisterAccessFilter(_registerAccess);

            await subject.OnActionExecutingAsync(actionContext, CancellationToken.None);

            _registerAccess.DidNotReceiveWithAnyArgs().ForCase(_caseId)
                           .IgnoreAwaitForNSubstituteAssertion();
        }
    }
}