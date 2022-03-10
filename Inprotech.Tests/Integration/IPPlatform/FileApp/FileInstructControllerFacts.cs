using System.Linq;
using System.Net;
using System.Net.Http;
using System.Reflection;
using System.Threading.Tasks;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Infrastructure.Security;
using Inprotech.Integration.IPPlatform.FileApp;
using Inprotech.Tests.Extensions;
using Inprotech.Tests.Web;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Integration.IPPlatform.FileApp
{
    public class FileInstructControllerFacts
    {
        public class CreateFilingInstructionMethod
        {
            [Fact]
            public async Task CallsFileInstructInterfaceWithTheRightParameters()
            {
                var caseKey = Fixture.Integer();
                var fixture = new FileInstructControllerFixture();

                var result = new InstructResult();

                fixture.FileInstructInterface
                       .CreateFilingInstruction(caseKey)
                       .Returns(result);

                var r = await fixture.Subject.CreateFilingInstruction(caseKey);

                fixture.FileInstructInterface.Received(1).CreateFilingInstruction(caseKey).IgnoreAwaitForNSubstituteAssertion();

                Assert.Equal(result, r);
            }

            [Fact]
            public void HandleResponseDueToAccessIssues()
            {
                var methodInfo = typeof(FileInstructController).GetMethod(nameof(FileInstructController.CreateFilingInstruction));

                Assert.NotEmpty(methodInfo.GetCustomAttributes<HandleFileIntegrationErrorAttribute>());

                var statusCodeToMonitor = methodInfo.GetCustomAttributes<HandleFileIntegrationErrorAttribute>().Single().StatusCodes;

                Assert.Contains(HttpStatusCode.Forbidden, statusCodeToMonitor);
                Assert.Contains(HttpStatusCode.Unauthorized, statusCodeToMonitor);
            }

            [Fact]
            public void RequiresCreateFileCasePermission()
            {
                TaskSecurity.Secures<FileInstructController>(ApplicationTask.CreateFileCase);
            }

            [Fact]
            public void RequiresIpPlatformSession()
            {
                var methodInfo = typeof(FileInstructController).GetMethod(nameof(FileInstructController.CreateFilingInstruction));
                Assert.NotEmpty(methodInfo.GetCustomAttributes<RequiresIpPlatformSessionAttribute>());
            }

            [Fact]
            public async Task ReturnsTranslatedErrorDescription()
            {
                var caseKey = Fixture.Integer();
                var errorCode = Fixture.String();
                var fixture = new FileInstructControllerFixture();

                var result = new InstructResult
                {
                    ErrorCode = errorCode
                };

                fixture.Translations["ip-platform.file.instruct.errors." + errorCode].Returns("Translated Error Description");

                fixture.FileInstructInterface
                       .CreateFilingInstruction(caseKey)
                       .Returns(result);

                var r = await fixture.Subject.CreateFilingInstruction(caseKey);

                Assert.Equal(result, r);
                Assert.Equal("Translated Error Description", r.ErrorDescription);
            }
        }

        public class ViewFilingInstructionMethod
        {
            [Fact]
            public async Task CallsViewFilingInstructionWithTheRightParameters()
            {
                var pctCaseId = Fixture.Integer();
                var fixture = new FileInstructControllerFixture();

                var result = new InstructResult();

                fixture.FileInstructInterface
                       .ViewFilingInstruction(pctCaseId)
                       .Returns(result);

                var r = await fixture.Subject.ViewFilingInstruction(pctCaseId);

                fixture.FileInstructInterface.Received(1).ViewFilingInstruction(pctCaseId).IgnoreAwaitForNSubstituteAssertion();

                Assert.Equal(result, r);
            }

            [Fact]
            public void HandleResponseDueToAccessIssuesforViewRequest()
            {
                var methodInfo = typeof(FileInstructController).GetMethod(nameof(FileInstructController.ViewFilingInstruction));

                Assert.NotEmpty(methodInfo.GetCustomAttributes<HandleFileIntegrationErrorAttribute>());

                var statusCodeToMonitor = methodInfo.GetCustomAttributes<HandleFileIntegrationErrorAttribute>().Single().StatusCodes;

                Assert.Contains(HttpStatusCode.Forbidden, statusCodeToMonitor);
                Assert.Contains(HttpStatusCode.Unauthorized, statusCodeToMonitor);
            }

            [Fact]
            public void RequiresIpPlatformSession()
            {
                var methodInfo = typeof(FileInstructController).GetMethod(nameof(FileInstructController.ViewFilingInstruction));
                Assert.NotEmpty(methodInfo.GetCustomAttributes<RequiresIpPlatformSessionAttribute>());
            }

            [Fact]
            public void RequiresViewFileCasePermission()
            {
                TaskSecurity.Secures<FileInstructController>(nameof(FileInstructController.ViewFilingInstruction), ApplicationTask.ViewFileCase);
            }

            [Fact]
            public async Task ReturnsTranslatedErrorDescription()
            {
                var caseKey = Fixture.Integer();
                var errorCode = Fixture.String();
                var fixture = new FileInstructControllerFixture();

                var result = new InstructResult
                {
                    ErrorCode = errorCode
                };

                fixture.Translations["ip-platform.file.instruct.errors." + errorCode].Returns("Translated Error Description");

                fixture.FileInstructInterface
                       .ViewFilingInstruction(caseKey)
                       .Returns(result);

                var r = await fixture.Subject.ViewFilingInstruction(caseKey);

                Assert.Equal(result, r);
                Assert.Equal("Translated Error Description", r.ErrorDescription);
            }
        }

        public class CreateFilingInstructionsForPctDesignatesMethod
        {
            [Fact]
            public async Task CallsCreateFilingInstructionsWithTheRightParameters()
            {
                var caseKey = Fixture.Integer();
                var countryCodesCsv = Fixture.String();
                var fixture = new FileInstructControllerFixture();

                var result = new InstructResult();

                fixture.FileInstructInterface
                       .CreateFilingInstructions(Arg.Any<int>(), Arg.Any<string>())
                       .Returns(result);

                var r = await fixture.Subject.CreateFilingInstructions(caseKey, countryCodesCsv);

                fixture.FileInstructInterface.Received(1).CreateFilingInstructions(caseKey, countryCodesCsv).IgnoreAwaitForNSubstituteAssertion();

                Assert.Equal(result, r);
            }

            [Fact]
            public void HandleResponseDueToAccessIssues()
            {
                var methodInfo = typeof(FileInstructController).GetMethod(nameof(FileInstructController.CreateFilingInstructions));

                Assert.NotEmpty(methodInfo.GetCustomAttributes<HandleFileIntegrationErrorAttribute>());

                var statusCodeToMonitor = methodInfo.GetCustomAttributes<HandleFileIntegrationErrorAttribute>().Single().StatusCodes;

                Assert.Contains(HttpStatusCode.Forbidden, statusCodeToMonitor);
                Assert.Contains(HttpStatusCode.Unauthorized, statusCodeToMonitor);
            }

            [Fact]
            public void RequiresCreateFileCasePermission()
            {
                TaskSecurity.Secures<FileInstructController>(nameof(FileInstructController.CreateFilingInstructions), ApplicationTask.CreateFileCase);
            }

            [Fact]
            public void RequiresIpPlatformSession()
            {
                var methodInfo = typeof(FileInstructController).GetMethod(nameof(FileInstructController.CreateFilingInstructions));
                Assert.NotEmpty(methodInfo.GetCustomAttributes<RequiresIpPlatformSessionAttribute>());
            }

            [Fact]
            public async Task ReturnsTranslatedErrorDescription()
            {
                var caseKey = Fixture.Integer();
                var countryCodesCsv = Fixture.String();
                var errorCode = Fixture.String();
                var fixture = new FileInstructControllerFixture();

                var result = new InstructResult
                {
                    ErrorCode = errorCode
                };

                fixture.Translations["ip-platform.file.instruct.errors." + errorCode].Returns("Translated Error Description");

                fixture.FileInstructInterface
                       .CreateFilingInstructions(Arg.Any<int>(), Arg.Any<string>())
                       .Returns(result);

                var r = await fixture.Subject.CreateFilingInstructions(caseKey, countryCodesCsv);

                Assert.Equal(result, r);
                Assert.Equal("Translated Error Description", r.ErrorDescription);
            }
        }

        public class GetFiledCaseIdsForMethod
        {
            [Fact]
            public async Task ReturnsAccordingly()
            {
                var caseKey = Fixture.Integer();
                var fixture = new FileInstructControllerFixture();
                var expected = new FiledCases();

                fixture.FileInstructInterface.GetFiledCaseIdsFor(Arg.Any<HttpRequestMessage>(), caseKey)
                       .Returns(expected);

                var result = await fixture.Subject.GetFiledCaseIdsFor(caseKey);

                Assert.Equal(expected, result);
            }
        }

        public class CanInstructSpecificNationalPhaseMethod
        {
            [Fact]
            public async Task ReturnsAccordingly()
            {
                var caseKey = Fixture.Integer();
                var fixture = new FileInstructControllerFixture();
                var expected = new FileInstruct();

                fixture.FileInstructInterface.CanInstructOrView(Arg.Any<HttpRequestMessage>(), caseKey)
                       .Returns(expected);

                var result = await fixture.Subject.CanInstructOrView(caseKey);

                Assert.Equal(expected, result);
            }
        }

        public class CanInstructPctDesignatesOfMethod
        {
            [Fact]
            public void RequiresIpPlatformSession()
            {
                var methodInfo = typeof(FileInstructController).GetMethod(nameof(FileInstructController.CanInstructPctDesignatesOf));
                Assert.NotEmpty(methodInfo.GetCustomAttributes<RequiresIpPlatformSessionAttribute>());
            }

            [Fact]
            public async Task ReturnsAccordingly()
            {
                var parentCaseId = Fixture.Integer();
                var fixture = new FileInstructControllerFixture();
                var expected = new FileInstructAllowed();

                fixture.FileInstructInterface.CanInstructPctDesignatesOf(Arg.Any<HttpRequestMessage>(), parentCaseId)
                       .Returns(expected);

                var result = await fixture.Subject.CanInstructPctDesignatesOf(parentCaseId);

                Assert.Equal(expected, result);
            }
        }

        public class FileInstructControllerFixture : IFixture<FileInstructController>
        {
            public FileInstructControllerFixture()
            {
                FileInstructInterface = Substitute.For<IFileInstructInterface>();
                Translations = Substitute.For<IResolvedCultureTranslations>();
                Subject = new FileInstructController(FileInstructInterface, Translations);
            }

            public IFileInstructInterface FileInstructInterface { get; set; }

            public IResolvedCultureTranslations Translations { get; set; }

            public FileInstructController Subject { get; }
        }
    }
}