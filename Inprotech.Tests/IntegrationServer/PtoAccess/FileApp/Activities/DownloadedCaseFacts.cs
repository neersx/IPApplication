using System;
using System.Threading.Tasks;
using Inprotech.Integration.Artifacts;
using Inprotech.Integration.CaseSource;
using Inprotech.Integration.IPPlatform.FileApp;
using Inprotech.Integration.IPPlatform.FileApp.Models;
using Inprotech.IntegrationServer.PtoAccess;
using Inprotech.IntegrationServer.PtoAccess.Activities;
using Inprotech.IntegrationServer.PtoAccess.Diagnostics;
using Inprotech.IntegrationServer.PtoAccess.FileApp.Activities;
using Inprotech.Tests.Extensions;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.IntegrationServer.PtoAccess.FileApp.Activities
{
    public class DownloadedCaseFacts : FactBase
    {
        readonly IDetailsAvailable _detailsAvailable = Substitute.For<IDetailsAvailable>();
        readonly INewCaseDetailsNotification _newCaseDetailsNotification = Substitute.For<INewCaseDetailsNotification>();
        readonly IPtoAccessCase _ptoAccessCase = Substitute.For<IPtoAccessCase>();
        readonly IFileSettingsResolver _fileSettingsResolver = Substitute.For<IFileSettingsResolver>();
        readonly IFileApiClient _fileApiClient = Substitute.For<IFileApiClient>();
        readonly IRuntimeEvents _runtimeEvents = Substitute.For<IRuntimeEvents>();
        readonly IFileCaseUpdator _fileCaseUpdator = Substitute.For<IFileCaseUpdator>();

        DownloadedCase CreateSubject()
        {
            return new DownloadedCase(
                                      _ptoAccessCase,
                                      _fileSettingsResolver,
                                      _fileApiClient,
                                      _detailsAvailable,
                                      _newCaseDetailsNotification,
                                      _runtimeEvents,
                                      _fileCaseUpdator, Db);
        }

        [Theory]
        [InlineData(FileStatuses.Draft)]
        [InlineData("SELECT_COUNTRIES")]
        [InlineData("CONFIRM_AGENTS")]
        [InlineData("REQUIREMENTS")]
        [InlineData("CONFIRMATION")]
        [InlineData("COMPLETED")]
        public async Task ShouldProcessDownloadedCase(string fileCaseStatus)
        {
            var dataDownload = new DataDownload
            {
                Case = new EligibleCase
                {
                    CaseKey = Fixture.Integer(),
                    CountryCode = Fixture.String()
                }
            }.WithExtendedDetails(new FileCase
            {
                Status = fileCaseStatus
            });

            var subject = CreateSubject();

            await subject.Process(dataDownload);

            _ptoAccessCase.Received(1).EnsureAvailable(dataDownload.Case)
                          .IgnoreAwaitForNSubstituteAssertion();

            _detailsAvailable.Received(1).ConvertToCpaXml(dataDownload, null)
                             .IgnoreAwaitForNSubstituteAssertion();

            _newCaseDetailsNotification.Received(1).NotifyIfChanged(dataDownload)
                                       .IgnoreAwaitForNSubstituteAssertion();

            _runtimeEvents.Received(1).CaseProcessed(dataDownload)
                          .IgnoreAwaitForNSubstituteAssertion();

            _fileApiClient.DidNotReceive().Get<Instruction>(Arg.Any<Uri>())
                          .IgnoreAwaitForNSubstituteAssertion();

            _fileSettingsResolver.DidNotReceive().Resolve();
        }

        [Fact]
        public async Task ShouldRetrieveInstructionsForCpaXmlConversion()
        {
            var dataDownload = new DataDownload
            {
                Case = new EligibleCase
                {
                    CaseKey = Fixture.Integer(),
                    CountryCode = Fixture.String()
                }
            }.WithExtendedDetails(new FileCase
            {
                Id = Fixture.String(),
                Status = FileStatuses.Instructed
            });

            var instruction = new Instruction();

            var subject = CreateSubject();

            _fileSettingsResolver.Resolve().Returns(new FileSettings
            {
                ApiBase = "http://ipplatform.com/"
            });

            _fileApiClient.Get<Instruction>(Arg.Any<Uri>())
                          .Returns(instruction);

            await subject.Process(dataDownload);

            _fileApiClient.Received(1).Get<Instruction>(Arg.Any<Uri>())
                          .IgnoreAwaitForNSubstituteAssertion();

            _fileSettingsResolver.Received(1).Resolve();

            _fileCaseUpdator.Received(1).UpdateFileCase(dataDownload, instruction)
                            .IgnoreAwaitForNSubstituteAssertion();

            _detailsAvailable.Received(1).ConvertToCpaXml(dataDownload, instruction)
                             .IgnoreAwaitForNSubstituteAssertion();
        }
    }
}