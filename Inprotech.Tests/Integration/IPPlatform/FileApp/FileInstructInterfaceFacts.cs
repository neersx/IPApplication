using System.Collections.Generic;
using System.Net.Http;
using System.Threading.Tasks;
using Inprotech.Infrastructure.Security;
using Inprotech.Integration.IPPlatform.FileApp;
using Inprotech.Tests.Extensions;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Integration.IPPlatform.FileApp
{
    public class FileInstructInterfaceFacts
    {
        public class CreateFilingInstructionMethod
        {
            [Fact]
            public async Task CallsInstructFilingWithTheRightParameters()
            {
                var caseKey = Fixture.Integer();
                var fixture = new FileInstructInterfaceFixture();

                var result = new InstructResult();

                fixture.FileIntegration
                       .InstructFiling(Arg.Any<int>())
                       .Returns(result);

                var r = await fixture.Subject.CreateFilingInstruction(caseKey);

                fixture.FileIntegration.Received(1).InstructFiling(caseKey).IgnoreAwaitForNSubstituteAssertion();

                Assert.Equal(result, r);
            }
        }

        public class ViewFilingInstructionMethod
        {
            [Fact]
            public async Task CallsViewFilingWithTheRightParameters()
            {
                var pctCaseId = Fixture.Integer();
                var fixture = new FileInstructInterfaceFixture();

                var result = new InstructResult();

                fixture.FileIntegration
                       .ViewFiling(Arg.Any<int>())
                       .Returns(result);

                var r = await fixture.Subject.ViewFilingInstruction(pctCaseId);

                fixture.FileIntegration.Received(1).ViewFiling(pctCaseId).IgnoreAwaitForNSubstituteAssertion();

                Assert.Equal(result, r);
            }
        }

        public class CreateFilingInstructionsForPctDesignatesMethod
        {
            [Fact]
            public async Task CallsInstructFilingWithTheRightParameters()
            {
                var caseKey = Fixture.Integer();
                var countryCodesCsv = Fixture.String();
                var fixture = new FileInstructInterfaceFixture();

                var result = new InstructResult();

                fixture.FileIntegration
                       .InstructFilings(Arg.Any<int>(), Arg.Any<string>())
                       .Returns(result);

                var r = await fixture.Subject.CreateFilingInstructions(caseKey, countryCodesCsv);

                fixture.FileIntegration.Received(1).InstructFilings(caseKey, countryCodesCsv).IgnoreAwaitForNSubstituteAssertion();

                Assert.Equal(result, r);
            }
        }

        public class GetFiledCaseIdsForMethod
        {
            readonly HttpRequestMessage _incomingApiCall = new HttpRequestMessage();

            [Theory]
            [InlineData("FileSetting Not Enabled, Logged on via IP Platform", false, false, true)]
            [InlineData("FileSetting Enabled, Not Logged on via IP Platform", false, true, false)]
            [InlineData("FileSetting Enabled, Logged on via IP Platform", true, true, true)]
#pragma warning disable xUnit1026
            public async Task ReturnsAccordingly(string message, bool expected, bool fileSettingEnabled, bool isSignedOnViaTheIpPlatform)
#pragma warning restore xUnit1026
            {
                var fixture = new FileInstructInterfaceFixture();

                fixture.FileSettingsResolver.Resolve().Returns(new FileSettings
                {
                    IsEnabled = fileSettingEnabled
                });

                fixture.FileIntegration.FiledChildCases(Arg.Any<int>(), Arg.Any<FileSettings>())
                       .Returns(new FiledCases());

                fixture.IpPlatformSession.IsActive(Arg.Any<HttpRequestMessage>())
                       .Returns(isSignedOnViaTheIpPlatform);

                var result = await fixture.Subject.GetFiledCaseIdsFor(_incomingApiCall, 10);

                Assert.Equal(expected, result.CanView);
            }

            [Fact]
            public async Task CallsAppropriateMethodsAndPassesOnResults()
            {
                var fileSetting = new FileSettings {IsEnabled = true};
                var fixture = new FileInstructInterfaceFixture();
                var filedCases = new FiledCases
                {
                    FiledCaseIds = new List<int> {10, 20, 30}
                };

                fixture.FileSettingsResolver.Resolve().Returns(fileSetting);

                fixture.FileIntegration.FiledChildCases(10, fileSetting)
                       .Returns(filedCases);

                fixture.IpPlatformSession.IsActive(Arg.Any<HttpRequestMessage>())
                       .Returns(true);

                var result = await fixture.Subject.GetFiledCaseIdsFor(_incomingApiCall, 10);

                fixture.FileSettingsResolver.Received(1).Resolve();
                await fixture.FileIntegration.Received(1).FiledChildCases(10, fileSetting);
                fixture.IpPlatformSession.Received(1).IsActive(Arg.Any<HttpRequestMessage>());

                Assert.True(result.CanView);
                Assert.Equal(filedCases.FiledCaseIds, result.FiledCaseIds);
            }
        }

        public class CanInstructSpecificNationalPhaseMethod
        {
            readonly HttpRequestMessage _incomingApiCall = new HttpRequestMessage();

            [Theory]
            [InlineData("FileSetting Not Enabled, Logged on via IP Platform, Case Allowed", false, false, true, true)]
            [InlineData("FileSetting Not Enabled, Logged on via IP Platform, Case Not Allowed", false, false, true, false)]
            [InlineData("FileSetting Enabled, Not Logged on via IP Platform, Case Allowed", false, true, false, true)]
            [InlineData("FileSetting Enabled, Not Logged on via IP Platform, Case Not Allowed", false, true, false, false)]
            [InlineData("FileSetting Enabled, Logged on via IP Platform, Case Allowed", true, true, true, true)]
            [InlineData("FileSetting Enabled, Logged on via IP Platform, Case not Allowed", false, true, true, false)]
#pragma warning disable xUnit1026
            public async Task ReturnsAccordingly(string message, bool expected, bool fileSettingEnabled, bool isSignedOnViaTheIpPlatform, bool caseAllowed)
#pragma warning restore xUnit1026
            {
                var caseKey = Fixture.Integer();
                var fixture = new FileInstructInterfaceFixture();
                var settings = new FileSettings
                {
                    IsEnabled = fileSettingEnabled
                };

                fixture.FileSettingsResolver.Resolve().Returns(settings);

                fixture.IpPlatformSession.IsActive(Arg.Any<HttpRequestMessage>())
                       .Returns(isSignedOnViaTheIpPlatform);

                fixture.FileIntegration.InstructAllowedFor(caseKey, settings)
                       .Returns(new FileInstruct
                       {
                           CanView = caseAllowed
                       });

                var result = await fixture.Subject.CanInstructOrView(_incomingApiCall, caseKey);

                Assert.Equal(expected, result.CanView);
            }
        }

        public class CanInstructPctDesignatesOfMethod
        {
            readonly HttpRequestMessage _incomingApiCall = new HttpRequestMessage();

            [Theory]
            [InlineData("FileSetting Not Enabled, Logged on via IP Platform, Case Allowed", false, false, true, true)]
            [InlineData("FileSetting Not Enabled, Logged on via IP Platform, Case Not Allowed", false, false, true, false)]
            [InlineData("FileSetting Enabled, Not Logged on via IP Platform, Case Allowed", false, true, false, true)]
            [InlineData("FileSetting Enabled, Not Logged on via IP Platform, Case Not Allowed", false, true, false, false)]
            [InlineData("FileSetting Enabled, Logged on via IP Platform, Case Allowed", true, true, true, true)]
            [InlineData("FileSetting Enabled, Logged on via IP Platform, Case not Allowed", false, true, true, false)]
#pragma warning disable xUnit1026
            public async Task ReturnsAccordingly(string message, bool expected, bool fileSettingEnabled, bool isSignedOnViaTheIpPlatform, bool caseAllowed)
#pragma warning restore xUnit1026
            {
                var parentCaseId = Fixture.Integer();
                var fixture = new FileInstructInterfaceFixture();
                var settings = new FileSettings
                {
                    IsEnabled = fileSettingEnabled
                };

                fixture.FileSettingsResolver.Resolve().Returns(settings);

                fixture.IpPlatformSession.IsActive(Arg.Any<HttpRequestMessage>())
                       .Returns(isSignedOnViaTheIpPlatform);

                fixture.FileIntegration.InstructAllowedChildCases(parentCaseId, settings)
                       .Returns(new FileInstructAllowed
                       {
                           IsEnabled = caseAllowed
                       });

                var result = await fixture.Subject.CanInstructPctDesignatesOf(_incomingApiCall, parentCaseId);

                Assert.Equal(expected, result.IsEnabled);
            }
        }

        public class FileInstructInterfaceFixture : IFixture<FileInstructInterface>
        {
            public FileInstructInterfaceFixture()
            {
                FileIntegration = Substitute.For<IFileIntegration>();
                FileSettingsResolver = Substitute.For<IFileSettingsResolver>();
                IpPlatformSession = Substitute.For<IIpPlatformSession>();
                Subject = new FileInstructInterface(FileSettingsResolver, FileIntegration, IpPlatformSession);
            }

            public IFileSettingsResolver FileSettingsResolver { get; set; }

            public IFileIntegration FileIntegration { get; set; }

            public IIpPlatformSession IpPlatformSession { get; set; }

            public FileInstructInterface Subject { get; }
        }
    }
}