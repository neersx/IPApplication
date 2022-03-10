using System;
using System.Collections.Generic;
using System.Threading.Tasks;
using Inprotech.Infrastructure.Storage;
using Inprotech.Integration.Artifacts;
using Inprotech.Integration.IPPlatform.FileApp;
using Inprotech.Integration.IPPlatform.FileApp.Models;
using Inprotech.IntegrationServer.PtoAccess.Activities;
using Inprotech.IntegrationServer.PtoAccess.FileApp.Activities;
using Inprotech.Tests.Extensions;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.IntegrationServer.PtoAccess.FileApp.Activities
{
    public class ResolveEligibleCasesFacts
    {
        readonly ICasesEligibleForDownload _casesEligibleForDownload = Substitute.For<ICasesEligibleForDownload>();
        readonly IDownloadCaseDispatcher _downloadCaseDispatcher = Substitute.For<IDownloadCaseDispatcher>();
        readonly IFileSettingsResolver _fileSettingsResolver = Substitute.For<IFileSettingsResolver>();
        readonly IFileApiClient _fileApiClient = Substitute.For<IFileApiClient>();
        readonly IBufferedStringWriter _bufferedStringWriter = Substitute.For<IBufferedStringWriter>();
        readonly IDataDownloadLocationResolver _dataDownloadLocationResolver = Substitute.For<IDataDownloadLocationResolver>();

        [Fact]
        public async Task ShouldPersistListOfApplicationsThenDispatch()
        {
            var dataDownload = new DataDownload();

            var fileSetting = new FileSettings
            {
                ApiBase = "http://ipplatform.com"
            };

            var fileCases = new[]
            {
                new FileCase(),
                new FileCase(),
                new FileCase()
            };

            var savedQuery = (int?) Fixture.Integer();

            var runAs = (int?) Fixture.Integer();

            var filePath = Fixture.String();

            _fileSettingsResolver.Resolve().Returns(fileSetting);

            _fileApiClient.Get<IEnumerable<FileCase>>(Arg.Any<Uri>())
                          .Returns(fileCases);

            _dataDownloadLocationResolver.ResolveRoot(dataDownload, "applicationlist.json")
                                         .Returns(filePath);

            var subject = new ResolveEligibleCases(
                                                   _casesEligibleForDownload,
                                                   _downloadCaseDispatcher,
                                                   _dataDownloadLocationResolver,
                                                   _bufferedStringWriter,
                                                   _fileSettingsResolver,
                                                   _fileApiClient);

            await subject.From(dataDownload, savedQuery, runAs);

            _casesEligibleForDownload.Received(1)
                                     .ResolveAsync(
                                                   dataDownload,
                                                   savedQuery.Value,
                                                   runAs.Value,
                                                   _downloadCaseDispatcher.Dispatch)
                                     .IgnoreAwaitForNSubstituteAssertion();

            _bufferedStringWriter.Received(1).Write(filePath, Arg.Any<string>())
                                 .IgnoreAwaitForNSubstituteAssertion();
        }
    }
}