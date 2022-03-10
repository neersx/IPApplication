using System;
using System.Threading.Tasks;
using Inprotech.Contracts;
using Inprotech.IntegrationServer.ExchangeIntegration;
using Inprotech.IntegrationServer.ExchangeIntegration.RequestTypes;
using Inprotech.IntegrationServer.ExchangeIntegration.RequestTypes.SaveDraftEmails;
using Inprotech.IntegrationServer.ExchangeIntegration.Strategy;
using Inprotech.Tests.Extensions;
using Inprotech.Tests.Fakes;
using InprotechKaizen.Model.Components.Integration.Exchange;
using InprotechKaizen.Model.ExchangeIntegration;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.IntegrationServer.ExchangeIntegration.RequestTypes.SaveDraftEmails
{
    public class SaveDraftEmailRequestHandlerFacts : FactBase
    {
        readonly IExchangeService _exchangeService = Substitute.For<IExchangeService>();
        readonly IBackgroundProcessLogger<SaveDraftEmailRequestHandler> _logger = Substitute.For<IBackgroundProcessLogger<SaveDraftEmailRequestHandler>>();

        SaveDraftEmailRequestHandler CreateSubject(string serviceType)
        {
            var strategy = Substitute.For<IStrategy>();

            strategy.GetService(Arg.Any<Guid>(), serviceType)
                    .Returns(_exchangeService);

            return new SaveDraftEmailRequestHandler(Db, strategy, _logger);
        }

        [Theory]
        [InlineData(KnownImplementations.Ews)]
        public async Task ShouldPassDetailsToExchangeServiceInOrderToSaveDraftEmail(string serviceType)
        {
            var original = new ExchangeRequestQueueItem
            {
                MailBox = Fixture.String(),
                Recipients = Fixture.String(),
                CcRecipients = Fixture.String(),
                BccRecipients = Fixture.String(),
                Subject = Fixture.String(),
                Body = Fixture.String(),
                IsBodyHtml = Fixture.Boolean(),
                Attachments = Fixture.String()
            }.In(Db);

            var request = new ExchangeRequest { Id = original.Id, RequestType = ExchangeRequestType.SaveDraftEmail, UserId = Fixture.Integer() };

            var subject = CreateSubject(serviceType);

            var result = await subject.Process(request, new ExchangeConfigurationSettings
            {
                ServiceType = serviceType
            });

            Assert.Equal(KnownStatuses.Success, result.Result);

            _exchangeService.Received(1)
                            .SaveDraftEmail(Arg.Any<ExchangeConfigurationSettings>(),
                                            Arg.Is<ExchangeItemRequest>(_ => _.Mailbox == original.MailBox &&
                                                                             _.RecipientEmail == original.Recipients &&
                                                                             _.CcRecipientEmails == original.CcRecipients &&
                                                                             _.BccRecipientEmails == original.BccRecipients &&
                                                                             _.Subject == original.Subject &&
                                                                             _.Body == original.Body &&
                                                                             _.IsBodyHtml == original.IsBodyHtml &&
                                                                             _.Attachments == original.Attachments), Arg.Any<int>())
                            .IgnoreAwaitForNSubstituteAssertion();
        }

        [Theory]
        [InlineData(KnownImplementations.Ews)]
        public async Task ShouldFailWhenExceptionsOccur(string serviceType)
        {
            var original = new ExchangeRequestQueueItem().In(Db);

            var request = new ExchangeRequest { Id = original.Id, RequestType = ExchangeRequestType.SaveDraftEmail, UserId = Fixture.Integer() };

            var subject = CreateSubject(serviceType);

            _exchangeService.When(x => x.SaveDraftEmail(Arg.Any<ExchangeConfigurationSettings>(), Arg.Any<ExchangeItemRequest>(), Arg.Any<int>()))
                            .Do(x => throw new Exception("bummer"));

            var result = await subject.Process(request, new ExchangeConfigurationSettings
            {
                ServiceType = serviceType
            });

            Assert.Equal(KnownStatuses.Failed, result.Result);
            Assert.Equal("bummer", result.ErrorMessage);

            _logger.Received(1).Exception(Arg.Any<Exception>());
        }
    }
}