using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Contracts;
using Inprotech.Infrastructure.ContentManagement;
using Inprotech.Infrastructure.Formatting.Exports;
using Inprotech.Infrastructure.Notifications;
using Inprotech.Infrastructure.Storage;
using Inprotech.Integration.Reports;
using Inprotech.Integration.Reports.Engine;
using Inprotech.Tests.Extensions;
using InprotechKaizen.Model.Components.Reporting;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Integration.Reports.Engine
{
    public class ReportServiceFacts : FactBase
    {
        readonly IReportContentManager _reportContentManager = Substitute.For<IReportContentManager>();
        readonly IBackgroundProcessLogger<ReportService> _logger = Substitute.For<IBackgroundProcessLogger<ReportService>>();
        readonly IReportClient _reportClient = Substitute.For<IReportClient>();
        readonly IChunkedStreamWriter _chunkedStreamWriter = Substitute.For<IChunkedStreamWriter>();
        readonly IFileSystem _fileSystem = Substitute.For<IFileSystem>();
        readonly IPdfUtility _pdfUtility = Substitute.For<IPdfUtility>();

        ReportService CreateSubject()
        {
            return new ReportService(_logger, _reportClient, _reportContentManager, _chunkedStreamWriter, _fileSystem, _pdfUtility);
        }
        
        [Fact]
        public async Task ShouldCalledSaveAndTryToPutIntoBackground()
        {
            var subject = CreateSubject();

            var standardReportRequest = new ReportRequest(new ReportDefinition
            {
                ReportPath = "http://localhost/reportserver",
                ReportExportFormat = ReportExportFormat.Excel,
                Parameters = new Dictionary<string, string>()
            })
            {
                ContentId = Fixture.Integer(),
                UserIdentityKey = Fixture.Integer(),
                UserCulture = "en-US"
            };

            var contentResult = new ContentResult {Exception = null};
           
            _reportClient.GetReportAsync(Arg.Any<ReportDefinition>(), Arg.Any<Stream>()).Returns(contentResult);
            
            await subject.Render(standardReportRequest);
            
            _reportContentManager.Received()
                                 .Save(standardReportRequest.ContentId, Arg.Any<string>(), Arg.Any<string>())
                                 .IgnoreAwaitForNSubstituteAssertion();

            _reportContentManager.Received().TryPutInBackground(standardReportRequest.UserIdentityKey, standardReportRequest.ContentId,
                                                                 Arg.Any<BackgroundProcessType>())
                                 .IgnoreAwaitForNSubstituteAssertion();
        }

        [Theory]
        [InlineData(ReportExportFormat.Excel, false)]
        [InlineData(ReportExportFormat.Excel, true)]
        [InlineData(ReportExportFormat.Word, false)]
        [InlineData(ReportExportFormat.Word, true)]
        public async Task ShouldNotProtectReportOutputForTheseExportFormatsEvenIfIndicated(ReportExportFormat format, bool indicatedToProtect)
        {
            var subject = CreateSubject();

            var request = new ReportRequest(new ReportDefinition
            {
                ReportPath = Fixture.String(),
                ReportExportFormat = format,
                ShouldMakeContentModifiable = !indicatedToProtect
            });
            
            _reportClient.GetReportAsync(Arg.Any<ReportDefinition>(), Arg.Any<Stream>()).Returns(new ContentResult());
            
            await subject.Render(request);

            _pdfUtility.DidNotReceive().Protect(Arg.Any<Stream>());
        }

        [Fact]
        public async Task ShouldProtectPdfOutputByDefault()
        {
            var subject = CreateSubject();

            var request = new ReportRequest(new ReportDefinition
            {
                ReportPath = Fixture.String(),
                ReportExportFormat = ReportExportFormat.Pdf
            });
            
            _reportClient.GetReportAsync(Arg.Any<ReportDefinition>(), Arg.Any<Stream>()).Returns(new ContentResult());
            
            await subject.Render(request);

            _pdfUtility.Received(1).Protect(Arg.Any<Stream>());
        }
        
        [Fact]
        public async Task ShouldNotProtectPdfOutputIfIndicated()
        {
            var subject = CreateSubject();

            var request = new ReportRequest(new ReportDefinition
            {
                ReportPath = Fixture.String(),
                ReportExportFormat = ReportExportFormat.Pdf,
                ShouldMakeContentModifiable = true
            });

            _reportClient.GetReportAsync(Arg.Any<ReportDefinition>(), Arg.Any<Stream>()).Returns(new ContentResult());
            
            await subject.Render(request);

            _pdfUtility.DidNotReceive().Protect(Arg.Any<Stream>());
        }

        [Fact]
        public async Task ShouldConcatenateIfIndicated()
        {
            var subject = CreateSubject();

            var request = new ReportRequest(
                                            new ReportDefinition
                                            {
                                                ReportPath = Fixture.String(),
                                                ReportExportFormat = ReportExportFormat.Pdf
                                            }, new ReportDefinition
                                            {
                                                ReportPath = Fixture.String(),
                                                ReportExportFormat = ReportExportFormat.Pdf
                                            })
            {
                ShouldConcatenate = true,
                NotificationProcessType = BackgroundProcessType.BillPrint
            };

            var reportFileNames = new List<string>();

            _reportClient.GetReportAsync(Arg.Any<ReportDefinition>(), Arg.Any<Stream>())
                         .Returns(x =>
                                  {
                                      reportFileNames.Add(((ReportDefinition)x[0]).FileName);
                                      return new ContentResult();
                                  });

            var _ = Arg.Any<Exception>();
            _pdfUtility.Concatenate(null, null, out _).ReturnsForAnyArgs(true);
            
            await subject.Render(request);

            // file names are generated

            Assert.NotNull(request.ReportDefinitions.ElementAt(0).FileName);
            Assert.NotNull(request.ReportDefinitions.ElementAt(1).FileName);
            Assert.NotNull(request.ConcatenateFileName);

            _pdfUtility.Received(1).Concatenate(Arg.Is<string[]>(_ => reportFileNames.SequenceEqual(_)), request.ConcatenateFileName, out _);
        }

        [Fact]
        public async Task ShouldExcludeFromConcatenationIfIndicated()
        {
            var subject = CreateSubject();

            var request = new ReportRequest(
                                            new ReportDefinition
                                            {
                                                ReportPath = Fixture.String(),
                                                ReportExportFormat = ReportExportFormat.Pdf
                                            }, new ReportDefinition
                                            {
                                                ReportPath = Fixture.String(),
                                                ReportExportFormat = ReportExportFormat.Pdf,
                                                ShouldExcludeFromConcatenation = true
                                            }, new ReportDefinition
                                            {
                                                ReportPath = Fixture.String(),
                                                ReportExportFormat = ReportExportFormat.Pdf
                                            })
            {
                ShouldConcatenate = true,
                NotificationProcessType = BackgroundProcessType.BillPrint
            };

            var reportFileNames = new List<string>();

            _reportClient.GetReportAsync(Arg.Any<ReportDefinition>(), Arg.Any<Stream>())
                         .Returns(x =>
                         {
                             reportFileNames.Add(((ReportDefinition)x[0]).FileName);
                             return new ContentResult();
                         });
            
            var _ = Arg.Any<Exception>();
            _pdfUtility.Concatenate(null, null, out _).ReturnsForAnyArgs(true);
            
            await subject.Render(request);

            _pdfUtility.Received(1).Concatenate(Arg.Is<string[]>(_ => _.Contains(reportFileNames.First())
                                                                      && _.Contains(reportFileNames.Last())
                                                                      && !_.Contains(reportFileNames.ElementAt(1))), request.ConcatenateFileName, out _);
        }

        [Fact]
        public async Task ShouldProtectConcatenatedOutputByDefault()
        {
            var subject = CreateSubject();

            var request = new ReportRequest(
                                            new ReportDefinition
                                            {
                                                ReportPath = Fixture.String(),
                                                ReportExportFormat = ReportExportFormat.Pdf
                                            }, new ReportDefinition
                                            {
                                                ReportPath = Fixture.String(),
                                                ReportExportFormat = ReportExportFormat.Pdf
                                            })
            {
                ShouldConcatenate = true,
                NotificationProcessType = BackgroundProcessType.BillPrint
            };
            
            _reportClient.GetReportAsync(Arg.Any<ReportDefinition>(), Arg.Any<Stream>()).Returns(new ContentResult());
            
            var _ = Arg.Any<Exception>();
            _pdfUtility.Concatenate(null, null, out _).ReturnsForAnyArgs(true);
            
            _fileSystem.OpenRead(request.ReportDefinitions.First().FileName).Returns(new MemoryStream());
            _fileSystem.OpenRead(request.ReportDefinitions.Last().FileName).Returns(new MemoryStream());
            _fileSystem.OpenRead(request.ConcatenateFileName).Returns(new MemoryStream());

            await subject.Render(request);
            
            _pdfUtility.Received(3).Protect(Arg.Any<Stream>());
        }

        [Fact]
        public async Task ShouldNotProtectConcatenatedOutputIfAnyOfTheReportDefinitionIsIndicatedNotTo()
        {
            var subject = CreateSubject();

            var request = new ReportRequest(
                                            new ReportDefinition
                                            {
                                                ReportPath = Fixture.String(),
                                                ReportExportFormat = ReportExportFormat.Pdf,
                                                ShouldMakeContentModifiable = true
                                            }, new ReportDefinition
                                            {
                                                ReportPath = Fixture.String(),
                                                ReportExportFormat = ReportExportFormat.Pdf
                                            })
            {
                ShouldConcatenate = true,
                NotificationProcessType = BackgroundProcessType.BillPrint
            };
            
            _reportClient.GetReportAsync(Arg.Any<ReportDefinition>(), Arg.Any<Stream>()).Returns(new ContentResult());
            
            var _ = Arg.Any<Exception>();
            _pdfUtility.Concatenate(null, null, out _).ReturnsForAnyArgs(true);
            
            _fileSystem.OpenRead(request.ReportDefinitions.First().FileName).Returns(new MemoryStream());
            _fileSystem.OpenRead(request.ReportDefinitions.Last().FileName).Returns(new MemoryStream());
            _fileSystem.OpenRead(request.ConcatenateFileName).Returns(new MemoryStream());

            await subject.Render(request);
            
            _pdfUtility.Received(1).Protect(Arg.Any<Stream>());
        }

        [Fact]
        public async Task ShouldNotProtectConcatenatedOutputIfAnyOfTheReportDefinitionIsNotPdf()
        {
            var subject = CreateSubject();

            var request = new ReportRequest(
                                            new ReportDefinition
                                            {
                                                ReportPath = Fixture.String(),
                                                ReportExportFormat = ReportExportFormat.Excel,
                                                ShouldMakeContentModifiable = true
                                            }, new ReportDefinition
                                            {
                                                ReportPath = Fixture.String(),
                                                ReportExportFormat = ReportExportFormat.Word
                                            })
            {
                ShouldConcatenate = true,
                NotificationProcessType = BackgroundProcessType.BillPrint
            };
            
            _reportClient.GetReportAsync(Arg.Any<ReportDefinition>(), Arg.Any<Stream>()).Returns(new ContentResult());
            
            var _ = Arg.Any<Exception>();
            _pdfUtility.Concatenate(null, null, out _).ReturnsForAnyArgs(true);
            
            _fileSystem.OpenRead(request.ReportDefinitions.First().FileName).Returns(new MemoryStream());
            _fileSystem.OpenRead(request.ReportDefinitions.Last().FileName).Returns(new MemoryStream());
            _fileSystem.OpenRead(request.ConcatenateFileName).Returns(new MemoryStream());

            await subject.Render(request);
            
            _pdfUtility.DidNotReceive().Protect(Arg.Any<Stream>());
        }

        [Fact]
        public async Task ShouldLogException()
        {
            var subject = CreateSubject();

            var standardReportRequest = new ReportRequest(new ReportDefinition
            {
                ReportPath = "http://localhost/reportserver",
                ReportExportFormat = ReportExportFormat.Excel,
                Parameters = new Dictionary<string, string>()
            })
            {
                ContentId = Fixture.Integer(),
                UserIdentityKey = 45,
                UserCulture = "en-US"
            };
            
            var contentResult = new ContentResult {Exception = new InvalidOperationException("report not found")};
            
            _reportClient.GetReportAsync(Arg.Any<ReportDefinition>(), Arg.Any<Stream>()).Returns(contentResult);
            
            await subject.Render(standardReportRequest);

            _reportContentManager.Received()
                                 .LogException(Arg.Any<Exception>(), Arg.Any<int>(),
                                               Arg.Any<string>(),  Arg.Any<BackgroundProcessType>());
        }
    }
}