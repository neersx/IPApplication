using System;
using System.Threading.Tasks;
using Inprotech.Contracts;
using Inprotech.Integration.ExchangeIntegration;
using Inprotech.IntegrationServer.DocumentGeneration;
using Inprotech.IntegrationServer.DocumentGeneration.RequestTypes.DeliverAsDraftEmail;
using Inprotech.Tests.Extensions;
using InprotechKaizen.Model.Components.Integration.Exchange;
using InprotechKaizen.Model.Persistence;
using NSubstitute;
using Xunit;
using KnownStatuses = Inprotech.IntegrationServer.DocumentGeneration.KnownStatuses;

namespace Inprotech.Tests.IntegrationServer.DocumentGeneration.DeliverAsDraftEmail
{
    public class DeliverAsDraftEmailHandlerFacts
    {
        readonly IDbContext _dbContext = Substitute.For<IDbContext>();
        readonly IDraftEmail _draftEmail = Substitute.For<IDraftEmail>();
        readonly IExchangeIntegrationQueue _exchangeIntegrationQueue = Substitute.For<IExchangeIntegrationQueue>();
        readonly IExchangeIntegrationSettings _exchangeIntegrationSettings = Substitute.For<IExchangeIntegrationSettings>();
        readonly IDraftEmailValidator _draftEmailValidator = Substitute.For<IDraftEmailValidator>();
        readonly IBackgroundProcessLogger<DeliverAsDraftEmailHandler> _logger = Substitute.For<IBackgroundProcessLogger<DeliverAsDraftEmailHandler>>();
        
        DeliverAsDraftEmailHandler CreateSubject(bool enabled = true)
        {
            _exchangeIntegrationSettings.Resolve()
                                        .Returns(new ExchangeConfigurationSettings
                                        {
                                            IsDraftEmailEnabled = enabled
                                        });

            return new DeliverAsDraftEmailHandler(_logger, _dbContext, _draftEmail, _draftEmailValidator, _exchangeIntegrationQueue, _exchangeIntegrationSettings);
        }

        [Fact]
        public async Task ShouldPrepareDraftEmailThenEnqueueForExchangeIntegration()
        {
            var queueItem = new DocGenRequest {Id = Fixture.Integer()};
            var preparedEmail = new DraftEmailProperties();

            _draftEmail.Prepare(queueItem).Returns(preparedEmail);

            var subject = CreateSubject();

            var result = await subject.Handle(queueItem);

            _exchangeIntegrationQueue.Received(1)
                                     .QueueDraftEmailRequest(preparedEmail, queueItem.Id)
                                     .IgnoreAwaitForNSubstituteAssertion();

            Assert.Equal(KnownStatuses.Success, result.Result);
        }

        [Fact]
        public async Task ShouldLetCallerDealWithExceptionHandling()
        {
            var queueItem = new DocGenRequest {Id = Fixture.Integer()};

            var subject = CreateSubject();

            _draftEmail.WhenForAnyArgs(x => x.Prepare(queueItem))
                       .Do(x => throw new Exception("bummer"));

            await Assert.ThrowsAsync<Exception>(async () => await subject.Handle(queueItem));

            _exchangeIntegrationQueue.DidNotReceive().QueueDraftEmailRequest(Arg.Any<DraftEmailProperties>(), Arg.Any<int>())
                                     .IgnoreAwaitForNSubstituteAssertion();
        }

        [Fact]
        public async Task ShouldReturnFailedStatusIfExchangeIntegrationIsNotEnabled()
        {
            
            var queueItem = new DocGenRequest {Id = Fixture.Integer()};

            const bool exchangeIntegrationEnabled = false;
            var subject = CreateSubject(exchangeIntegrationEnabled);

            var result = await subject.Handle(queueItem);

            _exchangeIntegrationQueue.DidNotReceive()
                                     .QueueDraftEmailRequest(Arg.Any<DraftEmailProperties>(), queueItem.Id)
                                     .IgnoreAwaitForNSubstituteAssertion();

            Assert.Equal(KnownStatuses.Failed, result.Result);
            Assert.Equal("Exchange Integration has not been enabled for 'Send as Draft Email'", result.ErrorMessage);
        }
    }
}