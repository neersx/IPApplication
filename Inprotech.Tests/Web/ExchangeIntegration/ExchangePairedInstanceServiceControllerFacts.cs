using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Net.Http;
using System.Net.Http.Headers;
using System.Text;
using System.Threading.Tasks;
using System.Web.Http;
using Inprotech.Contracts.Messages.Analytics;
using Inprotech.Infrastructure.Messaging;
using Inprotech.Integration.Analytics;
using Inprotech.Tests.Extensions;
using Inprotech.Tests.Fakes;
using Inprotech.Web.ExchangeIntegration;
using InprotechKaizen.Model.Components.Accounting.Billing.Delivery;
using InprotechKaizen.Model.Components.Integration.Exchange;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.Security;
using Newtonsoft.Json;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.ExchangeIntegration
{
    public class ExchangePairedInstanceServiceControllerFacts : FactBase
    {
        [Fact]
        public async Task ThrowsIfRequestIsNotMultipartForm()
        {
            var f = new ExchangePairedInstanceServiceControllerFixture(Db);

            var subject = f.Subject;

            subject.Request = new HttpRequestMessage(HttpMethod.Post, Fixture.String())
            {
                Content = new StringContent(Fixture.String())
            };

            await Assert.ThrowsAsync<HttpResponseException>(async () => await f.Subject.UploadDocument());
        }

        [Fact]
        public async Task ThrowsIfRequestDoesNotHaveParameterAndFile()
        {
            var f = new ExchangePairedInstanceServiceControllerFixture(Db);

            f.Subject.Request = new HttpRequestMessage(HttpMethod.Post, Fixture.String())
            {
                Content = new MultipartFormDataContent()
            };

            await Assert.ThrowsAsync<HttpResponseException>(async () => await f.Subject.UploadDocument());
        }

        [Fact]
        public async Task ThrowsIfRequestDoesNotHaveParameterParams()
        {
            var f = new ExchangePairedInstanceServiceControllerFixture(Db);
            var content = new MultipartFormDataContent
            {
                new FormUrlEncodedContent(new[]
                {
                    new KeyValuePair<string, string>("NotParams", Fixture.String())
                })
            };

            f.Subject.Request = new HttpRequestMessage(HttpMethod.Post, Fixture.String())
            {
                Content = content
            };

            await Assert.ThrowsAsync<HttpResponseException>(async () => await f.Subject.UploadDocument());
        }

        [Fact]
        public async Task ThrowsIfRequestParamsDoesNotHAveRequiredData()
        {
            var f = new ExchangePairedInstanceServiceControllerFixture(Db);
            var content = new MultipartFormDataContent
            {
                new FormUrlEncodedContent(new[]
                {
                    new KeyValuePair<string, string>("params", "{}")
                })
            };

            f.Subject.Request = new HttpRequestMessage(HttpMethod.Post, Fixture.String())
            {
                Content = content
            };

            await Assert.ThrowsAsync<HttpResponseException>(async () => await f.Subject.UploadDocument());
        }

        [Fact]
        public async Task ThrowsIfMailboxNotValidated()
        {
            var f = new ExchangePairedInstanceServiceControllerFixture(Db);
            var content = new MultipartFormDataContent();
            var subject = Fixture.String();
            var mailbox = Fixture.String();
            content.Add(new FormUrlEncodedContent(new[]
            {
                new KeyValuePair<string, string>("params", JsonConvert.SerializeObject(new
                {
                    Mailbox = mailbox,
                    EmailSubject = subject
                }))
            }));

            f.Subject.Request = new HttpRequestMessage(HttpMethod.Post, Fixture.String())
            {
                Content = content
            };

            f.RequestValidator.ValidateMailbox(Arg.Any<int>(), mailbox).Returns(false);

            await Assert.ThrowsAsync<HttpResponseException>(async () => await f.Subject.UploadDocument());
        }

        [Fact]
        public async Task SavesExchangeRequest()
        {
            var f = new ExchangePairedInstanceServiceControllerFixture(Db);
            var content = new MultipartFormDataContent();
            var subject = Fixture.String();
            content.Add(new FormUrlEncodedContent(new[]
            {
                new KeyValuePair<string, string>("params", JsonConvert.SerializeObject(new
                {
                    Mailbox = Fixture.String(),
                    EmailSubject = subject
                }))
            }));

            f.Subject.Request = new HttpRequestMessage(HttpMethod.Post, Fixture.String())
            {
                Content = content
            };

            await f.Subject.UploadDocument();

            f.ExchangeIntegrationQueue.Received(1)
             .QueueDraftEmailRequest(Arg.Is<DraftEmailProperties>(p =>
                                                                      p.Subject == subject
                                                                      && !p.Attachments.Any()
                                                                      && !p.IsBodyHtml
                                                                 ), Arg.Any<int?>(), Arg.Any<(int staffId, int userId)>()).IgnoreAwaitForNSubstituteAssertion();

            Db.Received(1).SaveChangesAsync().IgnoreAwaitForNSubstituteAssertion();
        }
        
        [Fact]
        public async Task ThrowsIfFileExtensionNotValid()
        {
            var f = new ExchangePairedInstanceServiceControllerFixture(Db);
            var content = new MultipartFormDataContent();
            var subject = Fixture.String();
            content.Add(new FormUrlEncodedContent(new[]
            {
                new KeyValuePair<string, string>("params", JsonConvert.SerializeObject(new
                {
                    Mailbox = Fixture.String(),
                    EmailSubject = subject
                }))
            }));

            var fileContent = new ByteArrayContent(Encoding.ASCII.GetBytes("These are some test bytes"));
            fileContent.Headers.ContentDisposition = new ContentDispositionHeaderValue("attachment")
            {
                FileName = "abc"
            };

            content.Add(fileContent);
            f.Subject.Request = new HttpRequestMessage(HttpMethod.Post, Fixture.String())
            {
                Content = content
            };

            f.RequestValidator.ValidateFileExtension(Arg.Any<Stream>()).Returns(false);

            await Assert.ThrowsAsync<HttpResponseException>(async () => await f.Subject.UploadDocument());
        }

        [Fact]
        public async Task SavesExchangeRequestWithFiles()
        {
            var f = new ExchangePairedInstanceServiceControllerFixture(Db);
            var content = new MultipartFormDataContent();
            var subject = Fixture.String();
            content.Add(new FormUrlEncodedContent(new[]
            {
                new KeyValuePair<string, string>("params", JsonConvert.SerializeObject(new
                {
                    Mailbox = Fixture.String(),
                    EmailSubject = subject
                }))
            }));

            var fileName = Fixture.String();
            var fileBytes = Encoding.ASCII.GetBytes("These are some test bytes");
            var fileContent = new ByteArrayContent(fileBytes);
            fileContent.Headers.ContentDisposition = new ContentDispositionHeaderValue("attachment")
            { FileName = fileName };

            content.Add(fileContent);
            f.Subject.Request = new HttpRequestMessage(HttpMethod.Post, Fixture.String())
            {
                Content = content
            };

            await f.Subject.UploadDocument();

            f.ExchangeIntegrationQueue.Received(1)
             .QueueDraftEmailRequest(Arg.Is<DraftEmailProperties>(p =>
                                                                      p.Subject == subject
                                                                      && p.Attachments.Count == 1
                                                                      && p.Attachments.First().FileName == fileName
                                                                      && p.Attachments.First().Content == Convert.ToBase64String(fileBytes)
                                                                      && !p.IsBodyHtml
                                                                 ), Arg.Any<int?>(), Arg.Any<(int staffId, int userId)>()).IgnoreAwaitForNSubstituteAssertion();
            
            f.Bus.Received(1).PublishAsync(Arg.Is<TransactionalAnalyticsMessage>(_ => _.EventType == TransactionalEventTypes.ExchangeEmailDraftViaApi))
             .IgnoreAwaitForNSubstituteAssertion();
        }

        public class ExchangePairedInstanceServiceControllerFixture : IFixture<ExchangePairedInstanceServiceController>
        {
            public ExchangePairedInstanceServiceControllerFixture(InMemoryDbContext db)
            {
                var securityContext = Substitute.For<ISecurityContext>();
                securityContext.User.Returns(new User(Fixture.String(), false));

                ExchangeIntegrationQueue = Substitute.For<IExchangeIntegrationQueue>();

                RequestValidator = Substitute.For<IExchangePairedInstanceRequestValidator>();
                RequestValidator.ValidateFileExtension(Arg.Any<Stream>()).Returns(true);
                RequestValidator.ValidateMailbox(Arg.Any<int>(), Arg.Any<string>()).Returns(true);

                Bus = Substitute.For<IBus>();

                DeliveryCapabilitiesResolver = Substitute.For<ICapabilitiesResolver>();

                Subject = new ExchangePairedInstanceServiceController(db, ExchangeIntegrationQueue, securityContext, RequestValidator, Bus, DeliveryCapabilitiesResolver);
            }

            public IBus Bus { get; set; }

            public IExchangeIntegrationQueue ExchangeIntegrationQueue { get; set; }

            public IExchangePairedInstanceRequestValidator RequestValidator { get; set; }

            public ICapabilitiesResolver DeliveryCapabilitiesResolver { get; set; }

            public ExchangePairedInstanceServiceController Subject { get; }
        }
    }
}