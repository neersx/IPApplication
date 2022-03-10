using System;
using System.Collections.Generic;
using System.Threading.Tasks;
using Inprotech.Contracts;
using Inprotech.Tests.Extensions;
using InprotechKaizen.Model.Accounting;
using InprotechKaizen.Model.Components.Accounting.Billing;
using InprotechKaizen.Model.Components.Accounting.Billing.Generation;
using InprotechKaizen.Model.Components.Accounting.Billing.Items;
using InprotechKaizen.Model.Components.Accounting.Billing.Items.Persistence;
using InprotechKaizen.Model.Persistence;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Model.Components.Accounting.Billing.Items.Persistence
{
    public class OrchestratorFacts
    {

        public class SaveNewDraftBillMethod : FactBase
        {
            [Fact]
            public async Task ShouldRunAllNewDraftBillPersistenceComponent()
            {
                var userIdentityId = Fixture.Integer();
                var culture = Fixture.String();
                var itemEntityId = Fixture.Integer();
                var openItemModel = new OpenItemModel
                {
                    ItemEntityId = itemEntityId,
                    ItemType = (int) ItemType.CreditNote
                };

                var fixture = new OrchestratorFixture(Db);
                var requestId = Guid.NewGuid();

                fixture.NewDraftBillComponent1.Run(userIdentityId, culture,
                                                   Arg.Any<BillingSiteSettings>(), Arg.Any<OpenItemModel>(), Arg.Any<SaveOpenItemResult>())
                       .Returns(true);
                fixture.NewDraftBillComponent2.Run(userIdentityId, culture,
                                                   Arg.Any<BillingSiteSettings>(), Arg.Any<OpenItemModel>(), Arg.Any<SaveOpenItemResult>())
                       .Returns(true);
                
                var result = await fixture.Subject.SaveNewDraftBill(userIdentityId, culture, openItemModel, requestId);

                Assert.False(result.HasError);
                
                fixture.NewDraftBillComponent1
                       .Received(1)
                       .Run(userIdentityId, culture, Arg.Any<BillingSiteSettings>(), openItemModel, Arg.Any<SaveOpenItemResult>())
                       .IgnoreAwaitForNSubstituteAssertion();

                fixture.NewDraftBillComponent2
                       .Received(1)
                       .Run(userIdentityId, culture, Arg.Any<BillingSiteSettings>(), openItemModel, Arg.Any<SaveOpenItemResult>())
                       .IgnoreAwaitForNSubstituteAssertion();
            }
        }
        
        public class UpdateDraftBillMethod : FactBase
        {
            [Fact]
            public async Task ShouldRunAllUpdateDraftBillPersistenceComponent()
            {
                var userIdentityId = Fixture.Integer();
                var culture = Fixture.String();
                var itemEntityId = Fixture.Integer();
                var openItemModel = new OpenItemModel
                {
                    ItemEntityId = itemEntityId,
                    ItemType = (int) ItemType.CreditNote
                };

                var fixture = new OrchestratorFixture(Db);
                var requestId = Guid.NewGuid();

                fixture.UpdateDraftBillComponent1.Run(userIdentityId, culture,
                                                      Arg.Any<BillingSiteSettings>(), Arg.Any<OpenItemModel>(), Arg.Any<SaveOpenItemResult>())
                       .Returns(true);
                fixture.UpdateDraftBillComponent2.Run(userIdentityId, culture,
                                                      Arg.Any<BillingSiteSettings>(), Arg.Any<OpenItemModel>(), Arg.Any<SaveOpenItemResult>())
                       .Returns(true);

                var result = await fixture.Subject.UpdateDraftBill(userIdentityId, culture, openItemModel, requestId);

                Assert.False(result.HasError);
                
                fixture.UpdateDraftBillComponent1
                       .Received(1)
                       .Run(userIdentityId, culture, Arg.Any<BillingSiteSettings>(), openItemModel, Arg.Any<SaveOpenItemResult>())
                       .IgnoreAwaitForNSubstituteAssertion();

                fixture.UpdateDraftBillComponent2
                       .Received(1)
                       .Run(userIdentityId, culture, Arg.Any<BillingSiteSettings>(), openItemModel, Arg.Any<SaveOpenItemResult>())
                       .IgnoreAwaitForNSubstituteAssertion();
            }
        }

        public class FinaliseDraftBillMethod : FactBase
        {
            [Fact]
            public async Task ShouldRunAllFinaliseDraftBillPersistenceComponent()
            {
                var userIdentityId = Fixture.Integer();
                var culture = Fixture.String();
                var itemEntityId = Fixture.Integer();
                var itemTransactionId = Fixture.Integer();
                var sendBillToReviewer = Fixture.Boolean();
                var trackingDetails = new BillGenerationTracking();
                var finaliseRequest = new FinaliseRequest
                {
                    ItemEntityId = itemEntityId,
                    ItemTransactionId = itemTransactionId
                };

                var fixture = new OrchestratorFixture(Db);
                var requestId = Guid.NewGuid();

                fixture.FinaliseDraftBillComponent1.Run(userIdentityId, culture,
                                                   Arg.Any<BillingSiteSettings>(), Arg.Any<FinaliseRequest>(), Arg.Any<SaveOpenItemResult>())
                       .Returns(true);
                fixture.FinaliseDraftBillComponent2.Run(userIdentityId, culture,
                                                   Arg.Any<BillingSiteSettings>(), Arg.Any<FinaliseRequest>(), Arg.Any<SaveOpenItemResult>())
                       .Returns(true);

                var result = await fixture.Subject.FinaliseDraftBill(userIdentityId, culture, finaliseRequest, requestId, trackingDetails, sendBillToReviewer);

                Assert.False(result.HasError);
                
                fixture.FinaliseDraftBillComponent1
                       .Received(1)
                       .Run(userIdentityId, culture, Arg.Any<BillingSiteSettings>(), finaliseRequest, Arg.Any<SaveOpenItemResult>())
                       .IgnoreAwaitForNSubstituteAssertion();

                fixture.FinaliseDraftBillComponent2
                       .Received(1)
                       .Run(userIdentityId, culture, Arg.Any<BillingSiteSettings>(), finaliseRequest, Arg.Any<SaveOpenItemResult>())
                       .IgnoreAwaitForNSubstituteAssertion();
            }
        }

        public class GenerateCreditBillMethod : FactBase
        {
            [Fact]
            public async Task ShouldDispatchBackgroundJobToCompleteCreditBillGeneration()
            {
                var userIdentityId = Fixture.Integer();
                var culture = Fixture.String();
                var sendBillsToReviewer = Fixture.Boolean();
                var billGenerationRequests = new[]
                {
                    new BillGenerationRequest()
                };

                var trackingDetails = new BillGenerationTracking();

                var fixture = new OrchestratorFixture(Db);

                await fixture.Subject.GenerateCreditBill(userIdentityId, culture, billGenerationRequests, trackingDetails, sendBillsToReviewer);

                fixture.BillProductionJobDispatcher.Received(1).Dispatch(userIdentityId, culture, trackingDetails, 
                                                                         BillProductionType.ProductionDuringFinalisePhase, 
                                                                         Arg.Any<Dictionary<string, object>>(),
                                                                         billGenerationRequests)
                       .IgnoreAwaitForNSubstituteAssertion();
            }
        }

        public class PrintBillsMethod : FactBase
        {
            [Fact]
            public async Task ShouldDispatchBackgroundJobToCompleteBillGeneration()
            {
                var userIdentityId = Fixture.Integer();
                var culture = Fixture.String();
                var billGenerationRequests = new[]
                {
                    new BillGenerationRequest()
                };

                var trackingDetails = new BillGenerationTracking();

                var sendBillsForReview = Fixture.Boolean();

                var fixture = new OrchestratorFixture(Db);

                await fixture.Subject.PrintBills(userIdentityId, culture, billGenerationRequests, trackingDetails, sendBillsForReview);

                fixture.BillProductionJobDispatcher.Received(1).Dispatch(userIdentityId, culture, trackingDetails, 
                                                                         BillProductionType.ProductionDuringPrintPhase, 
                                                                         Arg.Is<Dictionary<string, object>>(_ => (bool)_[AdditionalBillingOptions.SendFinalisedBillToReviewer] == sendBillsForReview),
                                                                         billGenerationRequests)
                       .IgnoreAwaitForNSubstituteAssertion();
            }
        }
    }

    public class OrchestratorFixture : IFixture<Orchestrator>
    {
        public OrchestratorFixture(IDbContext db)
        {
            Subject = new Orchestrator(db,
                                       BillingSiteSettingsResolver,
                                       new[] { NewDraftBillComponent1, NewDraftBillComponent2 },
                                       new[] { UpdateDraftBillComponent1, UpdateDraftBillComponent2 },
                                       new[] { FinaliseDraftBillComponent1, FinaliseDraftBillComponent2 },
                                       BillProductionJobDispatcher,
                                       Logger
                                      );
        }

        public INewDraftBill NewDraftBillComponent1 { get; } = Substitute.For<INewDraftBill>();

        public INewDraftBill NewDraftBillComponent2 { get; } = Substitute.For<INewDraftBill>();

        public IUpdateDraftBill UpdateDraftBillComponent1 { get; } = Substitute.For<IUpdateDraftBill>();

        public IUpdateDraftBill UpdateDraftBillComponent2 { get; } = Substitute.For<IUpdateDraftBill>();

        public IFinaliseDraftBill FinaliseDraftBillComponent1 { get; } = Substitute.For<IFinaliseDraftBill>();

        public IFinaliseDraftBill FinaliseDraftBillComponent2 { get; } = Substitute.For<IFinaliseDraftBill>();

        public IBillProductionJobDispatcher BillProductionJobDispatcher { get; } = Substitute.For<IBillProductionJobDispatcher>();
        
        public ILogger<Orchestrator> Logger { get; } = Substitute.For<ILogger<Orchestrator>>();

        public IBillingSiteSettingsResolver BillingSiteSettingsResolver { get; } = Substitute.For<IBillingSiteSettingsResolver>();

        public Orchestrator Subject { get; }
    }
}