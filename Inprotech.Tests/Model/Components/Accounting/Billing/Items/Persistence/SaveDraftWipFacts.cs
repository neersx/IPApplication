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
    public class SaveDraftWipFacts : FactBase
    {
        readonly IPostWipCommand _postWipCommand = Substitute.For<IPostWipCommand>();

        SaveDraftWip CreateSubject(ApplicationAlert alert = null)
        {
            var applicationAlerts = Substitute.For<IApplicationAlerts>();
            applicationAlerts.TryParse(Arg.Any<string>(), out var alerts)
                             .Returns(x =>
                             {
                                 x[1] = alert == null ? null : new[] { alert };
                                 return alert != null;
                             });

            var logger = Substitute.For<ILogger<SaveDraftWip>>();
            return new SaveDraftWip(_postWipCommand, applicationAlerts, logger);
        }

        [Fact]
        public async Task ShouldCallPostWipComponentForDebitNoteDebitWipThenReturnResult()
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
                                                                                          _.Single().ShouldReturnWipKey == true &&
                                                                                          _.Single().ShouldSuppressCommit == true &&
                                                                                          _.Single().ShouldSuppressPostToGeneralLedger == true &&
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
        public async Task ShouldCallPostWipComponentForDebitNoteDebitFeeItemThenReturnResult()
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
                ActivityId = Fixture.String(),
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
                ProfitCentreCode = Fixture.String(),
                EnteredChargeQuantity = Fixture.Integer(),
                IsFeeType = true,
                FeeType = Fixture.String(),
                BasicAmount = Fixture.Decimal(),
                ExtendedAmount = Fixture.Decimal(),
                Cycle = Fixture.Short(20),
                TaxCode = Fixture.String(),
                TaxAmount = Fixture.Decimal()
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
                                                                                          _.Single().ProfitCentreCode == draftWipItem.ProfitCentreCode &&
                                                                                          _.Single().EnteredQuantity == draftWipItem.EnteredChargeQuantity &&
                                                                                          _.Single().FeeType == draftWipItem.FeeType &&
                                                                                          _.Single().BaseFeeAmount == draftWipItem.BasicAmount &&
                                                                                          _.Single().AdditionalFee == draftWipItem.ExtendedAmount &&
                                                                                          _.Single().AgeOfCase == draftWipItem.Cycle &&
                                                                                          _.Single().FeeTaxCode == draftWipItem.TaxCode &&
                                                                                          _.Single().FeeTaxAmount == draftWipItem.TaxAmount
                                                                                     ))
                           .IgnoreAwaitForNSubstituteAssertion();
        }

        [Fact]
        public async Task ShouldCallPostWipComponentForAdvancedBillWithSignsReversedThenReturnResult()
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
                Margin = Fixture.Decimal(),
                ForeignMargin = Fixture.Decimal(),
                LocalDiscountForMargin = Fixture.Decimal(),
                ForeignDiscountForMargin = Fixture.Decimal()
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

            // Model return should have side-effect ( -ve modifier applied )

            Assert.Equal(original.LocalValue, draftWipItem.LocalValue * -1);
            Assert.Equal(original.ForeignValue, draftWipItem.ForeignValue * -1);
            Assert.Equal(original.ForeignCurrencyCode, draftWipItem.ForeignCurrencyCode);
            Assert.Equal(original.ExchangeRate, draftWipItem.ExchangeRate);
            Assert.Equal(original.LocalDiscount, draftWipItem.LocalDiscount * -1);
            Assert.Equal(original.ForeignDiscount, draftWipItem.ForeignDiscount * -1);
            Assert.Equal(original.LocalCost, draftWipItem.LocalCost * -1);
            Assert.Equal(original.ForeignCost, draftWipItem.ForeignCost * -1);
            Assert.Equal(original.CostCalculation1, draftWipItem.CostCalculation1 * -1);
            Assert.Equal(original.CostCalculation2, draftWipItem.CostCalculation2 * -1);
            Assert.Equal(original.ForeignMargin, draftWipItem.ForeignMargin * -1);
            Assert.Equal(original.LocalDiscountForMargin, draftWipItem.LocalDiscountForMargin * -1);
            Assert.Equal(original.ForeignDiscountForMargin, draftWipItem.ForeignDiscountForMargin * -1);

            _postWipCommand.Received(1)
                           .Post(userIdentityId, culture, Arg.Is<PostWipParameters[]>(_ =>
                                                                                          _.Single().ShouldReturnWipKey == true &&
                                                                                          _.Single().ShouldSuppressCommit == true &&
                                                                                          _.Single().ShouldSuppressPostToGeneralLedger == true &&
                                                                                          _.Single().EntityKey == draftWipItem.EntityId &&
                                                                                          _.Single().TransactionDate == draftWipItem.EntryDate &&
                                                                                          _.Single().LocalValue == original.LocalValue * -1 &&
                                                                                          _.Single().ForeignValue == original.ForeignValue * -1 &&
                                                                                          _.Single().ForeignCurrency == original.ForeignCurrencyCode &&
                                                                                          _.Single().ExchangeRate == original.ExchangeRate &&
                                                                                          _.Single().DiscountValue == original.LocalDiscount * -1 &&
                                                                                          _.Single().ForeignDiscount == original.ForeignDiscount * -1 &&
                                                                                          _.Single().LocalCost == original.LocalCost * -1 &&
                                                                                          _.Single().ForeignCost == original.ForeignCost * -1 &&
                                                                                          _.Single().CostCalculation1 == original.CostCalculation1 * -1 &&
                                                                                          _.Single().CostCalculation2 == original.CostCalculation2 * -1 &&
                                                                                          _.Single().ForeignMargin == original.ForeignMargin * -1 &&
                                                                                          _.Single().DiscountForMargin == original.LocalDiscountForMargin * -1 &&
                                                                                          _.Single().ForeignDiscountForMargin == original.ForeignDiscountForMargin * -1
                                                                                     ))
                           .IgnoreAwaitForNSubstituteAssertion();
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
    }
}
