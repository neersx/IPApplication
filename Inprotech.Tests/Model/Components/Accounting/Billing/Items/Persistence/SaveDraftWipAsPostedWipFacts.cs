using System;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Contracts;
using Inprotech.Infrastructure.Notifications.Validation;
using Inprotech.Tests.Extensions;
using InprotechKaizen.Model.Accounting;
using InprotechKaizen.Model.Components.Accounting.Billing.Items.Persistence;
using InprotechKaizen.Model.Components.Accounting.Billing.Wip;
using InprotechKaizen.Model.Components.Accounting.Wip;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Model.Components.Accounting.Billing.Items.Persistence
{
    public class SaveDraftWipAsPostedWipFacts
    {
        readonly IPostWipCommand _postWipCommand = Substitute.For<IPostWipCommand>();

        SaveDraftWipAsPostedWip CreateSubject(ApplicationAlert alert = null)
        {
            var applicationAlerts = Substitute.For<IApplicationAlerts>();
            applicationAlerts.TryParse(Arg.Any<string>(), out var alerts)
                             .Returns(x =>
                             {
                                 x[1] = alert == null ? null : new[] { alert };
                                 return alert != null;
                             });
            var logger = Substitute.For<ILogger<SaveDraftWipAsPostedWip>>();
            return new SaveDraftWipAsPostedWip(_postWipCommand, applicationAlerts, logger);
        }

        [Fact]
        public async Task ShouldPostStampFeeWip()
        {
            var userIdentityId = Fixture.Integer();
            var culture = Fixture.String();
            var itemTransactionId = Fixture.Integer();

            var draftWipItem = new DraftWip
            {
                DraftWipRefId = Fixture.Integer(),
                EntityId = Fixture.Integer(),
                EntryDate = Fixture.PastDate(),
                NameId = Fixture.Integer(),
                CaseId = Fixture.Integer(),
                StaffId = Fixture.Integer(),
                LocalValue = Fixture.Decimal(),
                ForeignValue = Fixture.Decimal(),
                ForeignCurrencyCode = Fixture.String(),
                ExchangeRate = Fixture.Decimal(),
                LocalDiscount = Fixture.Decimal(),
                ForeignDiscount = Fixture.Decimal(),
                LocalCost = Fixture.Decimal(),
                ForeignCost = Fixture.Decimal(),
                NarrativeId = Fixture.Integer(),
                Narrative = Fixture.String(),
                IsOneFeePerDebtor = Fixture.Boolean(),
                IsGeneratedFromTaxCode = Fixture.String()
            };

            var wipPosted = new WipPosted
            {
                RefId = draftWipItem.DraftWipRefId,
                TransNo = Fixture.Integer(),
                WipCode = Fixture.String(),
                WipSeqNo = Fixture.Short(),
                IsDraft = Fixture.Boolean()
            };

            _postWipCommand.Post(Arg.Any<int>(), Arg.Any<string>(), Arg.Any<PostWipParameters[]>())
                           .Returns(new[] { wipPosted });

            var subject = CreateSubject();

            var r = await subject.Save(userIdentityId, culture, new[] { draftWipItem }, itemTransactionId, ItemType.DebitNote, Guid.NewGuid());

            var saved = r.PersistedWipDetails.Single();

            Assert.Equal(wipPosted.RefId, saved.DraftWipRefId);
            Assert.Equal(wipPosted.RefId, saved.UniqueReferenceId);
            Assert.Equal(wipPosted.TransNo, saved.TransactionId);
            Assert.Equal(wipPosted.WipCode, saved.WipCode);
            Assert.Equal(wipPosted.WipSeqNo, saved.WipSeqNo);

            _postWipCommand.Received(1)
                           .Post(userIdentityId, culture, Arg.Is<PostWipParameters[]>(_ =>
                                                                                          _.Single().IsDraftWip == true &&
                                                                                          _.Single().ShouldReturnWipKey == true &&
                                                                                          _.Single().ShouldSuppressCommit == true &&
                                                                                          _.Single().ShouldSuppressPostToGeneralLedger == true &&
                                                                                          _.Single().EntityKey == draftWipItem.EntityId &&
                                                                                          _.Single().TransactionDate == draftWipItem.EntryDate &&
                                                                                          _.Single().NameKey == draftWipItem.NameId &&
                                                                                          _.Single().CaseKey == draftWipItem.CaseId &&
                                                                                          _.Single().StaffKey == draftWipItem.StaffId &&
                                                                                          _.Single().WipCode == draftWipItem.ActivityId &&
                                                                                          _.Single().LocalValue == draftWipItem.LocalValue &&
                                                                                          _.Single().ForeignValue == draftWipItem.ForeignValue &&
                                                                                          _.Single().ForeignCurrency == draftWipItem.ForeignCurrencyCode &&
                                                                                          _.Single().ExchangeRate == draftWipItem.ExchangeRate &&
                                                                                          _.Single().ForeignDiscount == draftWipItem.ForeignDiscount &&
                                                                                          _.Single().LocalCost == draftWipItem.LocalCost &&
                                                                                          _.Single().ForeignCost == draftWipItem.ForeignCost &&
                                                                                          _.Single().NarrativeKey == draftWipItem.NarrativeId &&
                                                                                          _.Single().Narrative == draftWipItem.Narrative))
                           .IgnoreAwaitForNSubstituteAssertion();
        }

        [Fact]
        public async Task ShouldLinkSplitsTogetherByTransactionNumber()
        {
            DraftWip DraftWipBuilder(int? splitGroupKey)
            {
                return new DraftWip
                {
                    SplitGroupKey = splitGroupKey,
                    EntityId = Fixture.Integer(),
                    EntryDate = Fixture.PastDate(),
                    DraftWipRefId = Fixture.Integer()
                };
            }

            var userIdentityId = Fixture.Integer();
            var culture = Fixture.String();
            var itemTransactionId = Fixture.Integer();

            var simulatedTransNo = 20;
            _postWipCommand.Post(Arg.Any<int>(), Arg.Any<string>(), Arg.Any<PostWipParameters[]>())
                           .ReturnsForAnyArgs(x =>
                           {
                               var thisParameter = ((PostWipParameters[])x[2])[0];
                               return new[]
                               {
                                   new WipPosted
                                   {
                                       RefId = thisParameter.RefId,
                                       TransNo = thisParameter.ItemTransNo ?? simulatedTransNo++,
                                       WipCode = thisParameter.WipCode,
                                       IsDraft = thisParameter.IsDraftWip
                                   }
                               };
                           });

            var subject = CreateSubject();

            var r = await subject.Save(userIdentityId, culture, new[]
            {
                DraftWipBuilder(1),
                DraftWipBuilder(1),
                DraftWipBuilder(null)
            }, itemTransactionId, ItemType.DebitNote, Guid.NewGuid());

            var allTransNosReturned = r.PersistedWipDetails
                                       .Select(p => p.TransactionId).ToArray();

            Assert.Equal(2, allTransNosReturned.Distinct().Count());

            Assert.Equal(r.PersistedWipDetails.ElementAt(0).TransactionId, r.PersistedWipDetails.ElementAt(1).TransactionId);

            Assert.NotEqual(r.PersistedWipDetails.ElementAt(0).TransactionId, r.PersistedWipDetails.ElementAt(2).TransactionId);
        }

        [Fact]
        public async Task SavesDraftDebitWipAsPostedWip()
        {
            var userIdentityId = Fixture.Integer();
            var culture = Fixture.String();
            var itemTransactionId = Fixture.Integer();

            var draftWipItem = new DraftWip
            {
                DraftWipRefId = Fixture.Integer(),
                EntityId = Fixture.Integer(),
                EntryDate = Fixture.PastDate(),
                NameId = Fixture.Integer(),
                CaseId = Fixture.Integer(),
                StaffId = Fixture.Integer(),
                AssociateNameId = Fixture.Integer(),
                InvoiceNumber = Fixture.String(),
                VerificationCode = Fixture.String(),
                RateId = Fixture.Integer(),
                ActivityId = Fixture.String(),
                TotalUnits = Fixture.Short(100),
                UnitsPerHour = Fixture.Short(60),
                ChargeOutRate = Fixture.Decimal(),
                LocalValue = Fixture.Decimal(),
                ForeignValue = Fixture.Decimal(),
                ForeignCurrencyCode = Fixture.String(),
                ExchangeRate = Fixture.Decimal(),
                LocalDiscount = Fixture.Decimal(),
                ForeignDiscount = Fixture.Decimal(),
                LocalCost = Fixture.Decimal(),
                ForeignCost = Fixture.Decimal(),
                CostCalculation1 = Fixture.Decimal(),
                CostCalculation2 = Fixture.Decimal(),
                ProductId = Fixture.Integer(),
                NarrativeId = Fixture.Integer(),
                Narrative = Fixture.String(),
                Margin = Fixture.Decimal(),
                IsSeparateMargin = Fixture.Boolean(),
                ForeignMargin = Fixture.Decimal(),
                LocalDiscountForMargin = Fixture.Decimal(),
                ForeignDiscountForMargin = Fixture.Decimal(),
                IsBillingDiscount = Fixture.Boolean(),
                ProfitCentreCode = Fixture.String()
            };

            var wipPosted = new WipPosted
            {
                RefId = draftWipItem.DraftWipRefId,
                TransNo = Fixture.Integer(),
                WipCode = Fixture.String(),
                WipSeqNo = Fixture.Short(),
                DiscountFlag = Fixture.Boolean(),
                MarginFlag = Fixture.Boolean(),
                IsDraft = Fixture.Boolean(),
                IsBillingDiscount = Fixture.Boolean()
            };

            _postWipCommand.Post(Arg.Any<int>(), Arg.Any<string>(), Arg.Any<PostWipParameters[]>())
                           .Returns(new[] { wipPosted });

            var subject = CreateSubject();

            var r = await subject.Save(userIdentityId, culture, new[] { draftWipItem }, itemTransactionId, ItemType.DebitNote, Guid.NewGuid());

            var saved = r.PersistedWipDetails.Single();

            Assert.Equal(wipPosted.RefId, saved.DraftWipRefId);
            Assert.Equal(wipPosted.RefId, saved.UniqueReferenceId);
            Assert.Equal(wipPosted.TransNo, saved.TransactionId);
            Assert.Equal(wipPosted.WipCode, saved.WipCode);
            Assert.Equal(wipPosted.WipSeqNo, saved.WipSeqNo);
            Assert.Equal(wipPosted.DiscountFlag, saved.IsDiscount);
            Assert.Equal(wipPosted.MarginFlag, saved.IsMargin);
            Assert.Equal(wipPosted.IsBillingDiscount, saved.IsBillingDiscount);
            Assert.Equal(wipPosted.IsDraft, saved.IsDraft);

            _postWipCommand.Received(1)
                           .Post(userIdentityId, culture, Arg.Is<PostWipParameters[]>(_ =>
                                                                                          _.Single().IsDraftWip == false &&
                                                                                          _.Single().ShouldReturnWipKey == true &&
                                                                                          _.Single().ShouldSuppressCommit == true &&
                                                                                          _.Single().ShouldSuppressPostToGeneralLedger == false && /* only item in group */
                                                                                          _.Single().EntityKey == draftWipItem.EntityId &&
                                                                                          _.Single().TransactionDate == draftWipItem.EntryDate &&
                                                                                          _.Single().NameKey == draftWipItem.NameId &&
                                                                                          _.Single().CaseKey == draftWipItem.CaseId &&
                                                                                          _.Single().StaffKey == draftWipItem.StaffId &&
                                                                                          _.Single().AssociateKey == draftWipItem.AssociateNameId &&
                                                                                          _.Single().InvoiceNumber == draftWipItem.InvoiceNumber &&
                                                                                          _.Single().VerificationNumber == draftWipItem.VerificationCode &&
                                                                                          _.Single().RateNo == draftWipItem.RateId &&
                                                                                          _.Single().WipCode == draftWipItem.ActivityId &&
                                                                                          _.Single().TotalUnits == draftWipItem.TotalUnits &&
                                                                                          _.Single().UnitsPerHour == draftWipItem.UnitsPerHour &&
                                                                                          _.Single().ChargeOutRate == draftWipItem.ChargeOutRate &&
                                                                                          _.Single().LocalValue == draftWipItem.LocalValue &&
                                                                                          _.Single().ForeignValue == draftWipItem.ForeignValue &&
                                                                                          _.Single().ForeignCurrency == draftWipItem.ForeignCurrencyCode &&
                                                                                          _.Single().ExchangeRate == draftWipItem.ExchangeRate &&
                                                                                          _.Single().DiscountValue == draftWipItem.LocalDiscount &&
                                                                                          _.Single().ForeignDiscount == draftWipItem.ForeignDiscount &&
                                                                                          _.Single().LocalCost == draftWipItem.LocalCost &&
                                                                                          _.Single().ForeignCost == draftWipItem.ForeignCost &&
                                                                                          _.Single().CostCalculation1 == draftWipItem.CostCalculation1 &&
                                                                                          _.Single().CostCalculation2 == draftWipItem.CostCalculation2 &&
                                                                                          _.Single().ProductCode == draftWipItem.ProductId &&
                                                                                          _.Single().NarrativeKey == draftWipItem.NarrativeId &&
                                                                                          _.Single().Narrative == draftWipItem.Narrative &&
                                                                                          _.Single().MarginValue == draftWipItem.Margin &&
                                                                                          _.Single().IsSeparateMargin == draftWipItem.IsSeparateMargin.GetValueOrDefault() &&
                                                                                          _.Single().ForeignMargin == draftWipItem.ForeignMargin &&
                                                                                          _.Single().DiscountForMargin == draftWipItem.LocalDiscountForMargin &&
                                                                                          _.Single().ForeignDiscountForMargin == draftWipItem.ForeignDiscountForMargin &&
                                                                                          _.Single().IsBillingDiscount == draftWipItem.IsBillingDiscount &&
                                                                                          _.Single().ProfitCentreCode == draftWipItem.ProfitCentreCode))
                           .IgnoreAwaitForNSubstituteAssertion();
        }

        [Fact]
        public async Task ShouldOnlyPostToGeneralLedgerForTheLastWipPostedInGroup()
        {
            DraftWip DraftWipBuilder(int? splitGroupKey)
            {
                return new DraftWip
                {
                    SplitGroupKey = splitGroupKey,
                    EntityId = Fixture.Integer(),
                    EntryDate = Fixture.PastDate(),
                    DraftWipRefId = Fixture.Integer()
                };
            }

            var userIdentityId = Fixture.Integer();
            var culture = Fixture.String();
            var itemTransactionId = Fixture.Integer();

            _postWipCommand.Post(Arg.Any<int>(), Arg.Any<string>(), Arg.Any<PostWipParameters[]>())
                           .ReturnsForAnyArgs(x =>
                           {
                               var thisParameter = ((PostWipParameters[])x[2])[0];
                               return new[]
                               {
                                   new WipPosted
                                   {
                                       RefId = thisParameter.RefId,
                                       TransNo = Fixture.Integer(),
                                       WipSeqNo = Fixture.Short(),
                                       WipCode = thisParameter.WipCode,
                                       IsDraft = thisParameter.IsDraftWip
                                   }
                               };
                           });

            var subject = CreateSubject();

            var draftWipGroup1 = new[]
            {
                DraftWipBuilder(1),
                DraftWipBuilder(1)
            };

            var draftWipGroup2 = new[]
            {
                DraftWipBuilder(2),
                DraftWipBuilder(2)
            };

            var draftWipGroup3 = new[]
            {
                DraftWipBuilder(null)
            };

            var draftWipItemsToSave = draftWipGroup1.Union(draftWipGroup2).Union(draftWipGroup3);

            var _ = await subject.Save(userIdentityId, culture, draftWipItemsToSave, itemTransactionId, ItemType.DebitNote, Guid.NewGuid());

            var parametersSentToPostWipCommands = _postWipCommand.ReceivedCalls().Select(rc => (rc.GetArguments()[2] as PostWipParameters[])[0]).ToArray();

            Assert.Equal(2, parametersSentToPostWipCommands.Count(p => p.ShouldSuppressPostToGeneralLedger));
            Assert.Equal(1, parametersSentToPostWipCommands.Count(p => p.ShouldSuppressPostToGeneralLedger == false && p.RefId == draftWipGroup1.Last().DraftWipRefId));
            Assert.Equal(1, parametersSentToPostWipCommands.Count(p => p.ShouldSuppressPostToGeneralLedger == false && p.RefId == draftWipGroup2.Last().DraftWipRefId));
            Assert.Equal(1, parametersSentToPostWipCommands.Count(p => p.ShouldSuppressPostToGeneralLedger == false && p.RefId == draftWipGroup3.Last().DraftWipRefId));
        }

        [Fact]
        public async Task ShouldReturnsErrorDetails()
        {
            var userIdentityId = Fixture.Integer();
            var culture = Fixture.String();
            var itemTransactionId = Fixture.Integer();

            var alert = new ApplicationAlert
            {
                AlertID = "AC208",
                Message = "The item date cannot be in the future. It must be within the current accounting period or up to and including the current date."
            };

            _postWipCommand.When(s => s.Post(Arg.Any<int>(), Arg.Any<string>(), Arg.Any<PostWipParameters[]>()))
                           .Do(_ => throw new SqlExceptionBuilder()
                                          .WithApplicationAlert(alert)
                                          .Build());

            var subject = CreateSubject(alert);

            var r = await subject.Save(userIdentityId, culture, new[]
            {
                new DraftWip
                {
                    EntityId = Fixture.Integer(),
                    EntryDate = Fixture.PastDate(),
                    DraftWipRefId = Fixture.Integer()
                }
            }, itemTransactionId, ItemType.DebitNote, Guid.NewGuid());

            Assert.Equal("AC208", r.ErrorCode);
            Assert.Equal("The item date cannot be in the future. It must be within the current accounting period or up to and including the current date.", r.ErrorDescription);
        }

        [Fact]
        public async Task ShouldCreateCreditWipForBillInAdvanceWip()
        {
            var userIdentityId = Fixture.Integer();
            var culture = Fixture.String();
            var itemTransactionId = Fixture.Integer();

            var original = new DraftWip
            {
                IsAdvanceBill = true,

                DraftWipRefId = Fixture.Integer(),
                EntityId = Fixture.Integer(),
                EntryDate = Fixture.PastDate(),
                NameId = Fixture.Integer(),
                CaseId = Fixture.Integer(),
                StaffId = Fixture.Integer(),
                AssociateNameId = Fixture.Integer(),
                InvoiceNumber = Fixture.String(),
                VerificationCode = Fixture.String(),
                RateId = Fixture.Integer(),
                ActivityId = Fixture.String(),
                TotalUnits = Fixture.Short(100),
                UnitsPerHour = Fixture.Short(60),
                ChargeOutRate = Fixture.Decimal(),
                LocalValue = Fixture.Decimal(),
                ForeignValue = Fixture.Decimal(),
                ForeignCurrencyCode = Fixture.String(),
                ExchangeRate = Fixture.Decimal(),
                LocalDiscount = Fixture.Decimal(),
                ForeignDiscount = Fixture.Decimal(),
                LocalCost = Fixture.Decimal(),
                ForeignCost = Fixture.Decimal(),
                CostCalculation1 = Fixture.Decimal(),
                CostCalculation2 = Fixture.Decimal(),
                ProductId = Fixture.Integer(),
                NarrativeId = Fixture.Integer(),
                Narrative = Fixture.String(),
                Margin = Fixture.Decimal(),
                IsSeparateMargin = Fixture.Boolean(),
                ForeignMargin = Fixture.Decimal(),
                LocalDiscountForMargin = Fixture.Decimal(),
                ForeignDiscountForMargin = Fixture.Decimal(),
                IsBillingDiscount = Fixture.Boolean(),
                ProfitCentreCode = Fixture.String()
            };

            var draftWipItem = (DraftWip)original.Clone();

            var wipPosted = new WipPosted
            {
                RefId = draftWipItem.DraftWipRefId,
                TransNo = Fixture.Integer(),
                WipCode = Fixture.String(),
                WipSeqNo = Fixture.Short(),
                DiscountFlag = Fixture.Boolean(),
                MarginFlag = Fixture.Boolean(),
                IsDraft = Fixture.Boolean(),
                IsBillingDiscount = Fixture.Boolean()
            };

            _postWipCommand.Post(Arg.Any<int>(), Arg.Any<string>(), Arg.Any<PostWipParameters[]>())
                           .Returns(new[] { wipPosted });

            var subject = CreateSubject();

            var r = await subject.Save(userIdentityId, culture, new[] { draftWipItem }, itemTransactionId, ItemType.DebitNote, Guid.NewGuid());

            var debitWipPosted = r.PersistedWipDetails.First();

            // should create 1 pair, debit wip + matching credit wip
            Assert.Equal(2, r.PersistedWipDetails.Count);

            Assert.Equal(wipPosted.RefId, debitWipPosted.DraftWipRefId);
            Assert.Equal(wipPosted.RefId, debitWipPosted.UniqueReferenceId);
            Assert.Equal(wipPosted.TransNo, debitWipPosted.TransactionId);
            Assert.Equal(wipPosted.WipCode, debitWipPosted.WipCode);
            Assert.Equal(wipPosted.WipSeqNo, debitWipPosted.WipSeqNo);
            Assert.Equal(wipPosted.DiscountFlag, debitWipPosted.IsDiscount);
            Assert.Equal(wipPosted.MarginFlag, debitWipPosted.IsMargin);
            Assert.Equal(wipPosted.IsBillingDiscount, debitWipPosted.IsBillingDiscount);
            Assert.Equal(wipPosted.IsDraft, debitWipPosted.IsDraft);

            // Model return should NOT have side-effect ( -ve modifier applied )

            Assert.Equal(original.LocalValue, draftWipItem.LocalValue);
            Assert.Equal(original.ForeignValue, draftWipItem.ForeignValue);
            Assert.Equal(original.ExchangeRate, draftWipItem.ExchangeRate);
            Assert.Equal(original.LocalDiscount, draftWipItem.LocalDiscount);
            Assert.Equal(original.ForeignDiscount, draftWipItem.ForeignDiscount);
            Assert.Equal(original.LocalCost, draftWipItem.LocalCost);
            Assert.Equal(original.ForeignCost, draftWipItem.ForeignCost);
            Assert.Equal(original.CostCalculation1, draftWipItem.CostCalculation1);
            Assert.Equal(original.CostCalculation2, draftWipItem.CostCalculation2);
            Assert.Equal(original.ForeignMargin, draftWipItem.ForeignMargin);
            Assert.Equal(original.LocalDiscountForMargin, draftWipItem.LocalDiscountForMargin);
            Assert.Equal(original.ForeignDiscountForMargin, draftWipItem.ForeignDiscountForMargin);

            var receivedCalls = _postWipCommand.ReceivedCalls().ToArray();
            var firstPostWipCallParameters = (PostWipParameters[])receivedCalls.First().GetArguments()[2];
            var secondPostWipCallParameters = (PostWipParameters[])receivedCalls.Last().GetArguments()[2];

            Assert.Equal(firstPostWipCallParameters.Single().IsDraftWip, false);
            Assert.Equal(firstPostWipCallParameters.Single().ShouldReturnWipKey, true);
            Assert.Equal(firstPostWipCallParameters.Single().ShouldSuppressCommit, true);
            Assert.Equal(firstPostWipCallParameters.Single().ShouldSuppressPostToGeneralLedger, false); /* only item in group */
            Assert.Equal(firstPostWipCallParameters.Single().LocalValue, original.LocalValue);
            Assert.Equal(firstPostWipCallParameters.Single().ForeignValue, original.ForeignValue);
            Assert.Equal(firstPostWipCallParameters.Single().ForeignCurrency, original.ForeignCurrencyCode);
            Assert.Equal(firstPostWipCallParameters.Single().ExchangeRate, original.ExchangeRate);
            Assert.Equal(firstPostWipCallParameters.Single().LocalCost, original.LocalCost);
            Assert.Equal(firstPostWipCallParameters.Single().ForeignCost, original.ForeignCost);
            Assert.Equal(firstPostWipCallParameters.Single().CostCalculation1, original.CostCalculation1);
            Assert.Equal(firstPostWipCallParameters.Single().CostCalculation2, original.CostCalculation2);
            Assert.Equal(firstPostWipCallParameters.Single().ForeignMargin, original.ForeignMargin);
            Assert.Equal(firstPostWipCallParameters.Single().DiscountValue, original.LocalDiscount);
            Assert.Equal(firstPostWipCallParameters.Single().ForeignDiscount, original.ForeignDiscount);
            Assert.Equal(firstPostWipCallParameters.Single().DiscountForMargin, original.LocalDiscountForMargin);
            Assert.Equal(firstPostWipCallParameters.Single().ForeignDiscountForMargin, original.ForeignDiscountForMargin);
            Assert.Equal(firstPostWipCallParameters.Single().EntityKey, draftWipItem.EntityId);
            Assert.Equal(firstPostWipCallParameters.Single().TransactionDate, draftWipItem.EntryDate);
            Assert.Equal(firstPostWipCallParameters.Single().NameKey, draftWipItem.NameId);
            Assert.Equal(firstPostWipCallParameters.Single().CaseKey, draftWipItem.CaseId);
            Assert.Equal(firstPostWipCallParameters.Single().StaffKey, draftWipItem.StaffId);
            Assert.Equal(firstPostWipCallParameters.Single().AssociateKey, draftWipItem.AssociateNameId);
            Assert.Equal(firstPostWipCallParameters.Single().InvoiceNumber, draftWipItem.InvoiceNumber);
            Assert.Equal(firstPostWipCallParameters.Single().VerificationNumber, draftWipItem.VerificationCode);
            Assert.Equal(firstPostWipCallParameters.Single().RateNo, draftWipItem.RateId);
            Assert.Equal(firstPostWipCallParameters.Single().WipCode, draftWipItem.ActivityId);
            Assert.Equal(firstPostWipCallParameters.Single().TotalUnits, draftWipItem.TotalUnits);
            Assert.Equal(firstPostWipCallParameters.Single().UnitsPerHour, draftWipItem.UnitsPerHour);
            Assert.Equal(firstPostWipCallParameters.Single().ChargeOutRate, draftWipItem.ChargeOutRate);
            Assert.Equal(firstPostWipCallParameters.Single().ProductCode, draftWipItem.ProductId);
            Assert.Equal(firstPostWipCallParameters.Single().NarrativeKey, draftWipItem.NarrativeId);
            Assert.Equal(firstPostWipCallParameters.Single().Narrative, draftWipItem.Narrative);
            Assert.Equal(firstPostWipCallParameters.Single().IsSeparateMargin, draftWipItem.IsSeparateMargin.GetValueOrDefault());
            Assert.Equal(firstPostWipCallParameters.Single().IsBillingDiscount, draftWipItem.IsBillingDiscount);
            Assert.Equal(firstPostWipCallParameters.Single().ProfitCentreCode, draftWipItem.ProfitCentreCode);

            // Matching credit wip persisted, with sign reversals
            Assert.Equal(secondPostWipCallParameters.Single().IsDraftWip, false);
            Assert.Equal(secondPostWipCallParameters.Single().IsCreditWip, false);
            Assert.Equal(secondPostWipCallParameters.Single().ShouldReturnWipKey, true);
            Assert.Equal(secondPostWipCallParameters.Single().ShouldSuppressCommit, true);
            Assert.Equal(secondPostWipCallParameters.Single().ShouldSuppressPostToGeneralLedger, false); /* only item in group */
            Assert.Equal(secondPostWipCallParameters.Single().LocalValue, original.LocalValue * -1);
            Assert.Equal(secondPostWipCallParameters.Single().ForeignValue, original.ForeignValue * -1);
            Assert.Equal(secondPostWipCallParameters.Single().ForeignCurrency, original.ForeignCurrencyCode);
            Assert.Equal(secondPostWipCallParameters.Single().ExchangeRate, original.ExchangeRate);
            Assert.Equal(secondPostWipCallParameters.Single().LocalCost, original.LocalCost * -1);
            Assert.Equal(secondPostWipCallParameters.Single().ForeignCost, original.ForeignCost * -1);
            Assert.Equal(secondPostWipCallParameters.Single().CostCalculation1, original.CostCalculation1 * -1);
            Assert.Equal(secondPostWipCallParameters.Single().CostCalculation2, original.CostCalculation2 * -1);
            Assert.Equal(secondPostWipCallParameters.Single().ForeignMargin, original.ForeignMargin * -1);
            Assert.Equal(secondPostWipCallParameters.Single().DiscountValue, original.LocalDiscount); /* discounts signs not reversed */
            Assert.Equal(secondPostWipCallParameters.Single().ForeignDiscount, original.ForeignDiscount); /* discounts signs not reversed */
            Assert.Equal(secondPostWipCallParameters.Single().DiscountForMargin, original.LocalDiscountForMargin); /* discounts signs not reversed */
            Assert.Equal(secondPostWipCallParameters.Single().ForeignDiscountForMargin, original.ForeignDiscountForMargin); /* discounts signs not reversed */
            Assert.Equal(secondPostWipCallParameters.Single().EntityKey, draftWipItem.EntityId);
            Assert.Equal(secondPostWipCallParameters.Single().TransactionDate, draftWipItem.EntryDate);
            Assert.Equal(secondPostWipCallParameters.Single().NameKey, draftWipItem.NameId);
            Assert.Equal(secondPostWipCallParameters.Single().CaseKey, draftWipItem.CaseId);
            Assert.Equal(secondPostWipCallParameters.Single().StaffKey, draftWipItem.StaffId);
            Assert.Equal(secondPostWipCallParameters.Single().AssociateKey, draftWipItem.AssociateNameId);
            Assert.Equal(secondPostWipCallParameters.Single().InvoiceNumber, draftWipItem.InvoiceNumber);
            Assert.Equal(secondPostWipCallParameters.Single().VerificationNumber, draftWipItem.VerificationCode);
            Assert.Equal(secondPostWipCallParameters.Single().RateNo, draftWipItem.RateId);
            Assert.Equal(secondPostWipCallParameters.Single().WipCode, draftWipItem.ActivityId);
            Assert.Equal(secondPostWipCallParameters.Single().TotalUnits, draftWipItem.TotalUnits);
            Assert.Equal(secondPostWipCallParameters.Single().UnitsPerHour, draftWipItem.UnitsPerHour);
            Assert.Equal(secondPostWipCallParameters.Single().ChargeOutRate, draftWipItem.ChargeOutRate);
            Assert.Equal(secondPostWipCallParameters.Single().ProductCode, draftWipItem.ProductId);
            Assert.Equal(secondPostWipCallParameters.Single().NarrativeKey, draftWipItem.NarrativeId);
            Assert.Equal(secondPostWipCallParameters.Single().Narrative, draftWipItem.Narrative);
            Assert.Equal(secondPostWipCallParameters.Single().IsSeparateMargin, draftWipItem.IsSeparateMargin.GetValueOrDefault());
            Assert.Equal(secondPostWipCallParameters.Single().IsBillingDiscount, draftWipItem.IsBillingDiscount);
            Assert.Equal(secondPostWipCallParameters.Single().ProfitCentreCode, draftWipItem.ProfitCentreCode);
        }

        [Fact]
        public async Task SaveDraftCreditWipAsPostedWipWithSignsReversed()
        {
            var userIdentityId = Fixture.Integer();
            var culture = Fixture.String();
            var itemTransactionId = Fixture.Integer();

            var original = new DraftWip
            {
                IsCreditWip = true,

                DraftWipRefId = Fixture.Integer(),
                EntityId = Fixture.Integer(),
                EntryDate = Fixture.PastDate(),
                NameId = Fixture.Integer(),
                CaseId = Fixture.Integer(),
                StaffId = Fixture.Integer(),
                AssociateNameId = Fixture.Integer(),
                InvoiceNumber = Fixture.String(),
                VerificationCode = Fixture.String(),
                RateId = Fixture.Integer(),
                ActivityId = Fixture.String(),
                TotalUnits = Fixture.Short(100),
                UnitsPerHour = Fixture.Short(60),
                ChargeOutRate = Fixture.Decimal(),
                LocalValue = Fixture.Decimal(),
                ForeignValue = Fixture.Decimal(),
                ForeignCurrencyCode = Fixture.String(),
                ExchangeRate = Fixture.Decimal(),
                LocalDiscount = Fixture.Decimal(),
                ForeignDiscount = Fixture.Decimal(),
                LocalCost = Fixture.Decimal(),
                ForeignCost = Fixture.Decimal(),
                CostCalculation1 = Fixture.Decimal(),
                CostCalculation2 = Fixture.Decimal(),
                ProductId = Fixture.Integer(),
                NarrativeId = Fixture.Integer(),
                Narrative = Fixture.String(),
                Margin = Fixture.Decimal(),
                IsSeparateMargin = Fixture.Boolean(),
                ForeignMargin = Fixture.Decimal(),
                LocalDiscountForMargin = Fixture.Decimal(),
                ForeignDiscountForMargin = Fixture.Decimal(),
                IsBillingDiscount = Fixture.Boolean(),
                ProfitCentreCode = Fixture.String()
            };

            var draftWipItem = (DraftWip)original.Clone();

            var wipPosted = new WipPosted
            {
                RefId = draftWipItem.DraftWipRefId,
                TransNo = Fixture.Integer(),
                WipCode = Fixture.String(),
                WipSeqNo = Fixture.Short(),
                DiscountFlag = Fixture.Boolean(),
                MarginFlag = Fixture.Boolean(),
                IsDraft = Fixture.Boolean(),
                IsBillingDiscount = Fixture.Boolean()
            };

            _postWipCommand.Post(Arg.Any<int>(), Arg.Any<string>(), Arg.Any<PostWipParameters[]>())
                           .Returns(new[] { wipPosted });

            var subject = CreateSubject();

            var r = await subject.Save(userIdentityId, culture, new[] { draftWipItem }, itemTransactionId, ItemType.DebitNote, Guid.NewGuid());

            var saved = r.PersistedWipDetails.Single();

            Assert.Equal(wipPosted.RefId, saved.DraftWipRefId);
            Assert.Equal(wipPosted.RefId, saved.UniqueReferenceId);
            Assert.Equal(wipPosted.TransNo, saved.TransactionId);
            Assert.Equal(wipPosted.WipCode, saved.WipCode);
            Assert.Equal(wipPosted.WipSeqNo, saved.WipSeqNo);
            Assert.Equal(wipPosted.DiscountFlag, saved.IsDiscount);
            Assert.Equal(wipPosted.MarginFlag, saved.IsMargin);
            Assert.Equal(wipPosted.IsBillingDiscount, saved.IsBillingDiscount);
            Assert.Equal(wipPosted.IsDraft, saved.IsDraft);

            // Model return should NOT have side-effect ( -ve modifier applied )

            Assert.Equal(original.LocalValue, draftWipItem.LocalValue);
            Assert.Equal(original.ForeignValue, draftWipItem.ForeignValue);
            Assert.Equal(original.ExchangeRate, draftWipItem.ExchangeRate);
            Assert.Equal(original.LocalDiscount, draftWipItem.LocalDiscount);
            Assert.Equal(original.ForeignDiscount, draftWipItem.ForeignDiscount);
            Assert.Equal(original.LocalCost, draftWipItem.LocalCost);
            Assert.Equal(original.ForeignCost, draftWipItem.ForeignCost);
            Assert.Equal(original.CostCalculation1, draftWipItem.CostCalculation1);
            Assert.Equal(original.CostCalculation2, draftWipItem.CostCalculation2);
            Assert.Equal(original.ForeignMargin, draftWipItem.ForeignMargin);
            Assert.Equal(original.LocalDiscountForMargin, draftWipItem.LocalDiscountForMargin);
            Assert.Equal(original.ForeignDiscountForMargin, draftWipItem.ForeignDiscountForMargin);

            _postWipCommand.Received(1)
                           .Post(userIdentityId, culture, Arg.Is<PostWipParameters[]>(_ =>
                                                                                          _.Single().IsDraftWip == false &&
                                                                                          _.Single().IsCreditWip == true &&
                                                                                          _.Single().ShouldReturnWipKey == true &&
                                                                                          _.Single().ShouldSuppressCommit == true &&
                                                                                          _.Single().ShouldSuppressPostToGeneralLedger == false && /* only item in group */
                                                                                          _.Single().LocalValue == original.LocalValue * -1 &&
                                                                                          _.Single().ForeignValue == original.ForeignValue * -1 &&
                                                                                          _.Single().ForeignCurrency == original.ForeignCurrencyCode &&
                                                                                          _.Single().ExchangeRate == original.ExchangeRate &&
                                                                                          _.Single().LocalCost == original.LocalCost * -1 &&
                                                                                          _.Single().ForeignCost == original.ForeignCost * -1 &&
                                                                                          _.Single().CostCalculation1 == original.CostCalculation1 * -1 &&
                                                                                          _.Single().CostCalculation2 == original.CostCalculation2 * -1 &&
                                                                                          _.Single().ForeignMargin == original.ForeignMargin * -1 &&
                                                                                          _.Single().DiscountValue == original.LocalDiscount && /* discounts should not reverse signs */
                                                                                          _.Single().ForeignDiscount == original.ForeignDiscount && /* discounts should not reverse signs */
                                                                                          _.Single().DiscountForMargin == original.LocalDiscountForMargin && /* discounts should not reverse signs */
                                                                                          _.Single().ForeignDiscountForMargin == original.ForeignDiscountForMargin && /* discounts should not reverse signs */
                                                                                          _.Single().EntityKey == draftWipItem.EntityId &&
                                                                                          _.Single().TransactionDate == draftWipItem.EntryDate &&
                                                                                          _.Single().NameKey == draftWipItem.NameId &&
                                                                                          _.Single().CaseKey == draftWipItem.CaseId &&
                                                                                          _.Single().StaffKey == draftWipItem.StaffId &&
                                                                                          _.Single().AssociateKey == draftWipItem.AssociateNameId &&
                                                                                          _.Single().InvoiceNumber == draftWipItem.InvoiceNumber &&
                                                                                          _.Single().VerificationNumber == draftWipItem.VerificationCode &&
                                                                                          _.Single().RateNo == draftWipItem.RateId &&
                                                                                          _.Single().WipCode == draftWipItem.ActivityId &&
                                                                                          _.Single().TotalUnits == draftWipItem.TotalUnits &&
                                                                                          _.Single().UnitsPerHour == draftWipItem.UnitsPerHour &&
                                                                                          _.Single().ChargeOutRate == draftWipItem.ChargeOutRate &&
                                                                                          _.Single().ProductCode == draftWipItem.ProductId &&
                                                                                          _.Single().NarrativeKey == draftWipItem.NarrativeId &&
                                                                                          _.Single().Narrative == draftWipItem.Narrative &&
                                                                                          _.Single().IsSeparateMargin == draftWipItem.IsSeparateMargin.GetValueOrDefault() &&
                                                                                          _.Single().IsBillingDiscount == draftWipItem.IsBillingDiscount &&
                                                                                          _.Single().ProfitCentreCode == draftWipItem.ProfitCentreCode))
                           .IgnoreAwaitForNSubstituteAssertion();
        }
    }
}