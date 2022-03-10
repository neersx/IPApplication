using System;
using System.Collections.Generic;
using System.Threading.Tasks;
using Inprotech.Contracts;
using Inprotech.Tests.Extensions;
using InprotechKaizen.Model.Components.Accounting.Billing;
using InprotechKaizen.Model.Components.Accounting.Billing.Generation;
using InprotechKaizen.Model.Components.Accounting.Billing.Items;
using InprotechKaizen.Model.Components.Accounting.Billing.Items.Persistence;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Model.Components.Accounting.Billing.Items.Persistence
{
    public class GenerateBillThenSendForReviewFacts
    {
        readonly IBillProductionJobDispatcher _billProductionJobDispatcher = Substitute.For<IBillProductionJobDispatcher>();

        GenerateBillThenSendForReview CreateSubject()
        {
            var logger = Substitute.For<ILogger<GenerateBillThenSendForReview>>();

            return new GenerateBillThenSendForReview(logger, _billProductionJobDispatcher);
        }

        [Fact]
        public async Task ShouldDispatchBackgroundBillPrintingJobFromDebtorOpenItemNos()
        {
            var userIdentityId = Fixture.Integer();
            var culture = Fixture.String();
            var sendBillsToReviewerForReview = Fixture.Boolean();
            var trackingDetails = new BillGenerationTracking();
            var siteSettings = new BillingSiteSettings
            {
                CanReviewBillInEmailDraft = true,
                Options = new Dictionary<string, object>
                {
                    { AdditionalBillingOptions.BillGenerationTracking, trackingDetails },
                    { AdditionalBillingOptions.SendFinalisedBillToReviewer, sendBillsToReviewerForReview }
                }
            };
            
            var finaliseRequest = new FinaliseRequest
            {
                ItemEntityId = Fixture.Integer(),
                ItemTransactionId = Fixture.Integer()
            };

            var debtorOpenItemNo1 = new DebtorOpenItemNo(Fixture.Integer()) { OpenItemNo = Fixture.String() };
            var debtorOpenItemNo2 = new DebtorOpenItemNo(Fixture.Integer()) { OpenItemNo = Fixture.String() };

            var finaliseBillResult = new SaveOpenItemResult
            {
                DebtorOpenItemNos = new List<DebtorOpenItemNo>
                {
                    debtorOpenItemNo1, debtorOpenItemNo2
                }
            };

            var subject = CreateSubject();

            await subject.Run(userIdentityId, culture, siteSettings, finaliseRequest, finaliseBillResult);

            _billProductionJobDispatcher.Received(1)
                                        .Dispatch(userIdentityId, culture, trackingDetails, 
                                                  BillProductionType.ProductionDuringFinalisePhase, siteSettings.Options,
                                                  Arg.Is<BillGenerationRequest[]>(_ => _[0].ShouldPrintAsOriginal == true 
                                                                                       && _[0].OpenItemNo == debtorOpenItemNo1.OpenItemNo 
                                                                                       && _[0].ItemEntityId == finaliseRequest.ItemEntityId 
                                                                                       && _[0].ItemTransactionId == finaliseRequest.ItemTransactionId 
                                                                                       && _[1].ShouldPrintAsOriginal == true 
                                                                                       && _[1].OpenItemNo == debtorOpenItemNo2.OpenItemNo 
                                                                                       && _[1].ItemEntityId == finaliseRequest.ItemEntityId 
                                                                                       && _[1].ItemTransactionId == finaliseRequest.ItemTransactionId))
                                        .IgnoreAwaitForNSubstituteAssertion();
        }

        [Fact]
        public async Task ShouldDispatchOneBillPrintingJobIfNoDebtorOpenItemNosAvailable()
        {

            var userIdentityId = Fixture.Integer();
            var culture = Fixture.String();
            var sendBillsToReviewerForReview = Fixture.Boolean();
            var trackingDetails = new BillGenerationTracking();
            var siteSettings = new BillingSiteSettings
            {
                CanReviewBillInEmailDraft = true,
                Options = new Dictionary<string, object>()
                {
                    { AdditionalBillingOptions.BillGenerationTracking, trackingDetails },
                    { AdditionalBillingOptions.SendFinalisedBillToReviewer, sendBillsToReviewerForReview }
                }
            };

            var finaliseRequest = new FinaliseRequest
            {
                ItemEntityId = Fixture.Integer(),
                ItemTransactionId = Fixture.Integer(),
                OpenItemNo = Fixture.String()
            };

            var subject = CreateSubject();

            await subject.Run(userIdentityId, culture, siteSettings, finaliseRequest, new SaveOpenItemResult());

            _billProductionJobDispatcher.Received(1)
                                        .Dispatch(userIdentityId, culture, trackingDetails, 
                                                  BillProductionType.ProductionDuringFinalisePhase, siteSettings.Options,
                                                  Arg.Is<BillGenerationRequest[]>(_ => _[0].ShouldPrintAsOriginal == true 
                                                                                       && _[0].OpenItemNo == finaliseRequest.OpenItemNo 
                                                                                       && _[0].ItemEntityId == finaliseRequest.ItemEntityId 
                                                                                       && _[0].ItemTransactionId == finaliseRequest.ItemTransactionId))
                                        .IgnoreAwaitForNSubstituteAssertion();
        }

        [Fact]
        public async Task ShouldPreventPrintingIfIndicatedToSendForReviewerButIsNotConfiguredToDoSo()
        {
            const bool sendBillsToReviewerForReview = true;
            const bool canReviewBillInEmailDraft = false;

            var userIdentityId = Fixture.Integer();
            var culture = Fixture.String();
            
            var trackingDetails = new BillGenerationTracking();
            var siteSettings = new BillingSiteSettings
            {
                CanReviewBillInEmailDraft = canReviewBillInEmailDraft,
                Options = new Dictionary<string, object>
                {
                    { AdditionalBillingOptions.BillGenerationTracking, trackingDetails },
                    { AdditionalBillingOptions.SendFinalisedBillToReviewer, sendBillsToReviewerForReview }
                }
            };
            
            var finaliseRequest = new FinaliseRequest
            {
                ItemEntityId = Fixture.Integer(),
                ItemTransactionId = Fixture.Integer()
            };
          
            var subject = CreateSubject();

            var r = await Assert.ThrowsAsync<NotSupportedException>(async () => await subject.Run(userIdentityId, culture, siteSettings, finaliseRequest, new SaveOpenItemResult()));

            Assert.Equal("The system has not been configured to review invoice in billing.", r.Message);
        }
    }
}
