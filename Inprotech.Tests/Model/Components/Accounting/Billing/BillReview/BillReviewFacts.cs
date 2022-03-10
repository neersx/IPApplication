using System.Linq;
using System.Threading.Tasks;
using Inprotech.Contracts;
using Inprotech.Infrastructure;
using Inprotech.Infrastructure.Web;
using Inprotech.Tests.Extensions;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web;
using InprotechKaizen.Model.Components.Accounting.Billing.BillReview;
using InprotechKaizen.Model.Components.Accounting.Billing.Generation;
using InprotechKaizen.Model.Components.Integration.Exchange;
using InprotechKaizen.Model.Components.System.Policy.AuditTrails;
using InprotechKaizen.Model.Security;
using NSubstitute;
using Xunit;
using BillReviewComponent = InprotechKaizen.Model.Components.Accounting.Billing.BillReview.BillReview;

namespace Inprotech.Tests.Model.Components.Accounting.Billing.BillReview
{
    public class BillReviewFacts : FactBase
    {
        readonly IBillReviewEmailBuilder _billReviewEmailBuilder = Substitute.For<IBillReviewEmailBuilder>();
        readonly IExchangeIntegrationQueue _exchangeIntegrationQueue = Substitute.For<IExchangeIntegrationQueue>();
        readonly IBillReviewSettingsResolver _billReviewSettingsResolver = Substitute.For<IBillReviewSettingsResolver>();
        readonly IComponentResolver _componentResolver = Substitute.For<IComponentResolver>();
        readonly IContextInfo _contextInfo = Substitute.For<IContextInfo>();

        readonly int _billingComponentId = Fixture.Integer();
        readonly int _staffId = Fixture.Integer();
        readonly int _userIdentityId = Fixture.Integer();
        
        BillReviewComponent CreateSubject(bool createUser = true)
        {
            var logger = Substitute.For<ILogger<BillReviewComponent>>();

            _componentResolver.Resolve(KnownComponents.Billing).Returns(_billingComponentId);

            if (createUser)
            {
                new User(Fixture.String(), false)
                {
                    NameId = _staffId
                }.In(Db).WithKnownId(_userIdentityId);
            }

            return new BillReviewComponent(Db, logger, _billReviewSettingsResolver, _billReviewEmailBuilder, _exchangeIntegrationQueue, _componentResolver, _contextInfo);
        }

        [Fact]
        public async Task ShouldNotProcessIfThereWereNoRequests()
        {
            var subject = CreateSubject();

            await subject.SendBillsForReview(_userIdentityId, Fixture.String());

            _billReviewSettingsResolver.DidNotReceive()
                                       .Resolve(_userIdentityId)
                                       .IgnoreAwaitForNSubstituteAssertion();

            _billReviewEmailBuilder.DidNotReceive()
                                   .Build(_userIdentityId, Arg.Any<string>(), Arg.Any<string>(), Arg.Any<BillGenerationRequest[]>())
                                   .IgnoreAwaitForNSubstituteAssertion();
        }

        [Fact]
        public async Task ShouldNotProcessIfTheReviewerMailboxIsNotSet()
        {
            _billReviewSettingsResolver.Resolve(_userIdentityId)
                                       .Returns(new BillReviewSettings
                                       {
                                           CanReviewBillInEmailDraft = false,
                                           ReviewerMailbox = null
                                       });
            
            var subject = CreateSubject();

            await subject.SendBillsForReview(_userIdentityId, Fixture.String());
            
            _billReviewEmailBuilder.DidNotReceive()
                                   .Build(_userIdentityId, Arg.Any<string>(), Arg.Any<string>(), Arg.Any<BillGenerationRequest[]>())
                                   .IgnoreAwaitForNSubstituteAssertion();
        }

        [Fact]
        public async Task ShouldNotProcessIfExchangeIntegrationConfigurationIsIncomplete()
        {
            _billReviewSettingsResolver.Resolve(_userIdentityId)
                                       .Returns(new BillReviewSettings
                                       {
                                           CanReviewBillInEmailDraft = false,
                                           ReviewerMailbox = "reviewer@lawfirm.com"
                                       });
            
            var subject = CreateSubject();

            await subject.SendBillsForReview(_userIdentityId, Fixture.String());
            
            _billReviewEmailBuilder.DidNotReceive()
                                   .Build(_userIdentityId, Arg.Any<string>(), Arg.Any<string>(), Arg.Any<BillGenerationRequest[]>())
                                   .IgnoreAwaitForNSubstituteAssertion();
        }

        [Theory]
        [InlineData(1)]
        [InlineData(5)]
        public async Task ShouldBuildEmailDraftsThenEnqueueForSavingInExchange(int numberOfRequests)
        {
            _billReviewSettingsResolver.Resolve(_userIdentityId)
                                       .Returns(new BillReviewSettings
                                       {
                                           CanReviewBillInEmailDraft = true,
                                           ReviewerMailbox = "reviewer@lawfirm.com"
                                       });

            _billReviewEmailBuilder.Build(_userIdentityId, Arg.Any<string>(), Arg.Any<string>(), Arg.Any<BillGenerationRequest[]>())
                                   .Returns(x =>
                                   {
                                       var reviewerMailbox = (string)x[2];
                                       var requests = (BillGenerationRequest[])x[3];

                                       var result = (from r in requests
                                                     let caseId = Fixture.Integer()
                                                     let email = new DraftEmailProperties
                                                     {
                                                         Mailbox = reviewerMailbox
                                                     }
                                                     select new
                                                     {
                                                         Email = email,
                                                         Request = r,
                                                         FirstCaseIncluded = (int?)caseId
                                                     }).ToList();

                                       return result.Select(_ => (_.Email, _.Request, _.FirstCaseIncluded));
                                   });

            var requests = Enumerable
                           .Range(0, numberOfRequests)
                           .Select(_ => new BillGenerationRequest())
                           .ToArray();
            
            var subject = CreateSubject();

            await subject.SendBillsForReview(_userIdentityId, Fixture.String(), requests);

            _componentResolver.Received(1).Resolve(KnownComponents.Billing);

            _contextInfo.Received(numberOfRequests).EnsureUserContext(_userIdentityId, componentId: _billingComponentId);

            _exchangeIntegrationQueue.Received(numberOfRequests)
                                     .QueueDraftEmailRequest(Arg.Any<DraftEmailProperties>(), Arg.Any<int?>(), (_staffId, _userIdentityId))
                                     .IgnoreAwaitForNSubstituteAssertion();
        }
    }
}
