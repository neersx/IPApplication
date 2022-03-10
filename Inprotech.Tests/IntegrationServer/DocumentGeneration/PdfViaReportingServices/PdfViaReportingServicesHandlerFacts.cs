using System;
using System.IO;
using System.Threading.Tasks;
using Inprotech.Contracts;
using Inprotech.Infrastructure.Formatting.Exports;
using Inprotech.Integration.Reports;
using Inprotech.IntegrationServer.DocumentGeneration;
using Inprotech.IntegrationServer.DocumentGeneration.RequestTypes.PdfViaReportingServices;
using Inprotech.Tests.Extensions;
using Inprotech.Tests.Fakes;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Components.DocumentGeneration.Classic;
using InprotechKaizen.Model.Components.DocumentGeneration.Delivery;
using InprotechKaizen.Model.Components.Reporting;
using InprotechKaizen.Model.Documents;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.IntegrationServer.DocumentGeneration.PdfViaReportingServices
{
    public class PdfViaReportingServicesHandlerFacts : FactBase
    {
        readonly IDocumentGenerator _documentGenerator = Substitute.For<IDocumentGenerator>();
        readonly IFileSystem _fileSystem = Substitute.For<IFileSystem>();
        readonly IBackgroundProcessLogger<PdfViaReportingServicesHandler> _logger = Substitute.For<IBackgroundProcessLogger<PdfViaReportingServicesHandler>>();
        readonly IPdfReportRequestResolver _pdfReportRequestResolver = Substitute.For<IPdfReportRequestResolver>();
        readonly IDeliveryDestinationResolver _deliveryDestinationResolver = Substitute.For<IDeliveryDestinationResolver>();
        readonly IReportClient _reportClient = Substitute.For<IReportClient>();
        readonly IStorageLocationResolver _storageLocationResolver = Substitute.For<IStorageLocationResolver>();

        PdfViaReportingServicesHandler CreateSubject()
        {
            return new PdfViaReportingServicesHandler(_logger, _pdfReportRequestResolver, _deliveryDestinationResolver, _storageLocationResolver, _reportClient, _fileSystem, Db, _documentGenerator);
        }

        [Fact]
        public async Task ShouldStopProcessingWhenReportClientReturnsError()
        {
            var outputFileName = Fixture.String();

            var queueRequest = new DocGenRequest
            {
                Id = Fixture.Integer()
            };

            var reportDefinition = new ReportDefinition
            {
                ReportPath = Fixture.String(),
                ReportExportFormat = ReportExportFormat.Pdf
            };

            _pdfReportRequestResolver.Resolve(queueRequest)
                                     .Returns(reportDefinition);

            _storageLocationResolver.UniqueDirectory("reporting-services", Arg.Any<string>()).Returns(outputFileName);

            _reportClient.GetReportAsync(reportDefinition, Arg.Any<MemoryStream>())
                         .Returns(new ContentResult
                         {
                             Exception = new Exception("bummer")
                         });

            _deliveryDestinationResolver.Resolve(queueRequest.Id, Arg.Any<int>(), Arg.Any<short>())
                                        .Returns(new DeliveryDestination());

            var subject = CreateSubject();

            var result = await subject.Handle(queueRequest);

            Assert.Equal(KnownStatuses.Failed, result.Result);
            Assert.Equal("bummer", result.ErrorMessage);

            _documentGenerator.DidNotReceive().QueueDocument(queueRequest.Id, Arg.Any<Action<CaseActivityRequest, CaseActivityRequest>>())
                              .IgnoreAwaitForNSubstituteAssertion();
        }

        [Fact]
        public async Task ShouldEnqueueForDeliveryFollowingSuccessfulGeneration()
        {
            var outputFileName = Fixture.String();

            var deliverLetterForTheCurrentLetter = new Document
            {
                DeliveryMethodId = Fixture.Short()
            }.In(Db);

            var currentLetterInRequest = new Document
            {
                DeliverLetterId = deliverLetterForTheCurrentLetter.Id
            }.In(Db);

            var queueRequest = new DocGenRequest
            {
                Id = Fixture.Integer(),
                LetterId = currentLetterInRequest.Id
            };

            var reportDefinition = new ReportDefinition
            {
                ReportExportFormat = ReportExportFormat.Pdf,
                ReportPath = Fixture.String()
            };

            _deliveryDestinationResolver.Resolve(queueRequest.Id, Arg.Any<int>(), deliverLetterForTheCurrentLetter.Id)
                                        .Returns(new DeliveryDestination());
            
            _pdfReportRequestResolver.Resolve(queueRequest)
                                     .Returns(reportDefinition);

            _storageLocationResolver.UniqueDirectory(fileNameOrPath: "reporting-services").Returns(outputFileName);

            _reportClient.GetReportAsync(reportDefinition, Arg.Any<MemoryStream>())
                         .Returns(new ContentResult());

            var currentRequest = new CaseActivityRequest();
            var nextRequest = new CaseActivityRequest();

            _documentGenerator.When(x => x.QueueDocument(queueRequest.Id, Arg.Any<Action<CaseActivityRequest, CaseActivityRequest>>()))
                              .Do(_ => _.Arg<Action<CaseActivityRequest, CaseActivityRequest>>().Invoke(currentRequest, nextRequest));

            var subject = CreateSubject();

            var result = await subject.Handle(queueRequest);

            Assert.Equal(deliverLetterForTheCurrentLetter.Id, nextRequest.LetterNo);
            Assert.Equal(deliverLetterForTheCurrentLetter.DeliveryMethodId, nextRequest.DeliveryMethodId);
            Assert.Equal(Path.Combine(outputFileName, reportDefinition.ReportPath + ".pdf"), nextRequest.FileName);
            Assert.Equal(KnownStatuses.Success, result.Result);

            _documentGenerator.Received(1).QueueDocument(queueRequest.Id, Arg.Any<Action<CaseActivityRequest, CaseActivityRequest>>())
                              .IgnoreAwaitForNSubstituteAssertion();
        }

        [Fact]
        public async Task ShouldUseDestinationFolderSpecifiedInDeliverLetterDeliveryMethod()
        {
            var outputFileName = Fixture.String();
            
            var deliverLetterForTheCurrentLetter = new Document
            {
                DeliveryMethodId = Fixture.Short()
            }.In(Db);

            var currentLetterInRequest = new Document
            {
                DeliverLetterId = deliverLetterForTheCurrentLetter.Id
            }.In(Db);

            var queueRequest = new DocGenRequest
            {
                Id = Fixture.Integer(),
                LetterId = currentLetterInRequest.Id
            };

            var reportDefinition = new ReportDefinition
            {
                ReportExportFormat = ReportExportFormat.Pdf,
                ReportPath = Fixture.String()
            };

            _deliveryDestinationResolver.Resolve(queueRequest.Id, Arg.Any<int>(), deliverLetterForTheCurrentLetter.Id)
                                        .Returns(new DeliveryDestination
                                        {
                                            DirectoryName = outputFileName
                                        });
            
            _pdfReportRequestResolver.Resolve(queueRequest)
                                     .Returns(reportDefinition);
            
            _reportClient.GetReportAsync(reportDefinition, Arg.Any<MemoryStream>())
                         .Returns(new ContentResult());

            var currentRequest = new CaseActivityRequest();
            var nextRequest = new CaseActivityRequest();

            _documentGenerator.When(x => x.QueueDocument(queueRequest.Id, Arg.Any<Action<CaseActivityRequest, CaseActivityRequest>>()))
                              .Do(_ => _.Arg<Action<CaseActivityRequest, CaseActivityRequest>>().Invoke(currentRequest, nextRequest));

            var subject = CreateSubject();

            var result = await subject.Handle(queueRequest);

            Assert.Equal(deliverLetterForTheCurrentLetter.Id, nextRequest.LetterNo);
            Assert.Equal(deliverLetterForTheCurrentLetter.DeliveryMethodId, nextRequest.DeliveryMethodId);
            Assert.Equal(Path.Combine(outputFileName, reportDefinition.ReportPath + ".pdf"), nextRequest.FileName);
            Assert.Equal(KnownStatuses.Success, result.Result);

            _documentGenerator.Received(1).QueueDocument(queueRequest.Id, Arg.Any<Action<CaseActivityRequest, CaseActivityRequest>>())
                              .IgnoreAwaitForNSubstituteAssertion();
        }

        [Fact]
        public async Task ShouldUseDestinationFileNameSpecifiedInDeliverLetterDeliveryMethod()
        {
            var outputFileName = Fixture.String();
            var outputFolderName = Fixture.String();
            
            var deliverLetterForTheCurrentLetter = new Document
            {
                DeliveryMethodId = Fixture.Short()
            }.In(Db);

            var currentLetterInRequest = new Document
            {
                DeliverLetterId = deliverLetterForTheCurrentLetter.Id
            }.In(Db);

            var queueRequest = new DocGenRequest
            {
                Id = Fixture.Integer(),
                LetterId = currentLetterInRequest.Id
            };

            var reportDefinition = new ReportDefinition
            {
                ReportExportFormat = ReportExportFormat.Pdf,
                ReportPath = Fixture.String()
            };

            _deliveryDestinationResolver.Resolve(queueRequest.Id, Arg.Any<int>(), deliverLetterForTheCurrentLetter.Id)
                                        .Returns(new DeliveryDestination
                                        {
                                            FileName = outputFileName
                                        });
            
            _storageLocationResolver.UniqueDirectory(fileNameOrPath: "reporting-services").Returns(outputFolderName);

            _pdfReportRequestResolver.Resolve(queueRequest)
                                     .Returns(reportDefinition);
            
            _reportClient.GetReportAsync(reportDefinition, Arg.Any<MemoryStream>())
                         .Returns(new ContentResult());

            var currentRequest = new CaseActivityRequest();
            var nextRequest = new CaseActivityRequest();

            _documentGenerator.When(x => x.QueueDocument(queueRequest.Id, Arg.Any<Action<CaseActivityRequest, CaseActivityRequest>>()))
                              .Do(_ => _.Arg<Action<CaseActivityRequest, CaseActivityRequest>>().Invoke(currentRequest, nextRequest));

            var subject = CreateSubject();

            var result = await subject.Handle(queueRequest);

            Assert.Equal(deliverLetterForTheCurrentLetter.Id, nextRequest.LetterNo);
            Assert.Equal(deliverLetterForTheCurrentLetter.DeliveryMethodId, nextRequest.DeliveryMethodId);
            Assert.Equal(Path.Combine(outputFolderName, outputFileName), nextRequest.FileName);
            Assert.Equal(KnownStatuses.Success, result.Result);

            _documentGenerator.Received(1).QueueDocument(queueRequest.Id, Arg.Any<Action<CaseActivityRequest, CaseActivityRequest>>())
                              .IgnoreAwaitForNSubstituteAssertion();
        }
    }
}