using System;
using System.Threading.Tasks;
using Inprotech.IntegrationServer.DocumentGeneration;
using Inprotech.Tests.Extensions;
using Inprotech.Tests.Fakes;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Components.DocumentGeneration;
using InprotechKaizen.Model.Documents;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.IntegrationServer.DocumentGeneration
{
    public class RequestQueueFacts
    {
        public class NextRequestMethod : FactBase
        {
            readonly IQueueItems _queueItems = Substitute.For<IQueueItems>();

            [Fact]
            public async Task ShouldReturnGenerationRequestForPdfViaReportingServices()
            {
                var letter = new Document
                {
                    Name = Fixture.String(),
                    Template = Fixture.String(),
                    DocumentType = KnownDocumentTypes.PdfViaReportingServices
                }.In(Db);

                var generateRequest = new CaseActivityRequest
                {
                    CaseId = Fixture.Integer(),
                    WhenRequested = Fixture.Today(),
                    SqlUser = Fixture.String(),
                    Processed = 0,
                    HoldFlag = 0,
                    LetterNo = letter.Id
                }.In(Db);

                _queueItems.ForProcessing().Returns(new[] {generateRequest}.AsDbAsyncEnumerble());

                var subject = new RequestQueue(Db, _queueItems);

                var result = await subject.NextRequest(Guid.NewGuid());

                Assert.Equal(generateRequest.Id, result.Id);
                Assert.Equal(generateRequest.CaseId, result.CaseId);
                Assert.Equal(generateRequest.WhenRequested, result.WhenRequested);
                Assert.Equal(generateRequest.SqlUser, result.SqlUser);
                Assert.Equal(letter.Id, result.LetterId);
                Assert.Equal(letter.Name, result.LetterName);
                Assert.Equal(letter.Template, result.TemplateName);
                Assert.Equal(KnownDocumentTypes.PdfViaReportingServices, result.DocumentType);

                /* generation request for PDF don't have delivery ids or delivery types, because it has a Deliver Letter to define that */

                Assert.Null(result.DeliveryId);
                Assert.Null(result.DeliveryType);

                _queueItems.Received(1).Hold(result.Id).IgnoreAwaitForNSubstituteAssertion();
            }

            [Fact]
            public async Task ShouldReturnDeliverRequestForDeliverOnlyLetters()
            {
                var deliveryMethod = new DeliveryMethod
                {
                    Description = Fixture.String(),
                    Type = KnownDeliveryTypes.SaveDraftEmail
                }.In(Db);

                var letter = new Document
                {
                    Name = Fixture.String(),
                    DocumentType = KnownDocumentTypes.DeliveryOnly,
                    DeliveryMethodId = deliveryMethod.Id
                }.In(Db);

                var deliverRequest = new CaseActivityRequest
                {
                    CaseId = Fixture.Integer(),
                    WhenRequested = Fixture.Today(),
                    SqlUser = Fixture.String(),
                    Processed = 0,
                    HoldFlag = 0,
                    LetterNo = letter.Id,
                    DeliveryMethodId = deliveryMethod.Id
                }.In(Db);

                _queueItems.ForProcessing().Returns(new[] {deliverRequest}.AsDbAsyncEnumerble());

                var subject = new RequestQueue(Db, _queueItems);

                var result = await subject.NextRequest(Guid.NewGuid());

                Assert.Equal(deliverRequest.Id, result.Id);
                Assert.Equal(deliverRequest.CaseId, result.CaseId);
                Assert.Equal(deliverRequest.WhenRequested, result.WhenRequested);
                Assert.Equal(deliverRequest.SqlUser, result.SqlUser);
                Assert.Equal(letter.Id, result.LetterId);
                Assert.Equal(letter.Name, result.LetterName);
                
                Assert.Null(result.TemplateName);
                Assert.Equal(deliveryMethod.Id, result.DeliveryId);
                Assert.Equal(KnownDocumentTypes.DeliveryOnly, result.DocumentType);
                Assert.Equal(KnownDeliveryTypes.SaveDraftEmail, result.DeliveryType);

                _queueItems.Received(1).Hold(result.Id).IgnoreAwaitForNSubstituteAssertion();
            }
        }

        public class CompletedMethod : FactBase
        {
            [Fact]
            public async Task ShouldMarkQueueItemComplete()
            {
                var id = Fixture.Integer();

                var queueItems = Substitute.For<IQueueItems>();

                var subject = new RequestQueue(Db, queueItems);

                await subject.Completed(id);

                queueItems.Received(1).Complete(id).IgnoreAwaitForNSubstituteAssertion();
            }

            [Fact]
            public async Task ShouldPassOnFileName()
            {
                var id = Fixture.Integer();
                var fileName = Fixture.String();

                var queueItems = Substitute.For<IQueueItems>();

                var subject = new RequestQueue(Db, queueItems);
                
                await subject.Completed(id, fileName);

                queueItems.Received(1).Complete(id, fileName).IgnoreAwaitForNSubstituteAssertion();
            }
        }

        public class FailedMethod : FactBase
        {
            [Fact]
            public async Task ShouldMarkQueueItemFailed()
            {
                var id = Fixture.Integer();
                var errorMessage = Fixture.String();

                var queueItems = Substitute.For<IQueueItems>();

                var subject = new RequestQueue(Db, queueItems);

                await subject.Failed(id, errorMessage);

                queueItems.Received(1).Error(id, errorMessage).IgnoreAwaitForNSubstituteAssertion();
            }
        }
    }
}