using System;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Infrastructure;
using Inprotech.Tests.Extensions;
using InprotechKaizen.Model.Components.Accounting.Billing;
using InprotechKaizen.Model.Components.Accounting.Billing.Wip;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Model.Components.Accounting.Billing.Wip
{
    public class WipItemsServiceFacts
    {
        public class GetAvailableWipItemsMethod
        {
            [Fact]
            public async Task ShouldReturnResultFromAvailableWipItemCommandsComponent()
            {
                var userId = Fixture.Integer();
                var culture = Fixture.String();
                var selectionCriteria = new WipSelectionCriteria();

                var wipItems = new[] { new AvailableWipItem() };

                var fixture = new WipItemServiceFixture();

                fixture.AvailableWipItemCommands.GetAvailableWipItems(Arg.Any<int>(), Arg.Any<string>(), Arg.Any<WipSelectionCriteria>())
                       .Returns(wipItems);

                var result = await fixture.Subject.GetAvailableWipItems(userId, culture, selectionCriteria);

                Assert.Equal(wipItems, result);

                fixture.AvailableWipItemCommands
                       .Received(1)
                       .GetAvailableWipItems(userId, culture, selectionCriteria)
                       .IgnoreAwaitForNSubstituteAssertion();
            }
        }
        
        public class GetWipItemExchangeRatesMethod
        {
            [Fact]
            public async Task ShouldResolveExchangeDetailsThenReturnRequestedWipItemsWithUpdatedExchangeRateDetails()
            {
                var userId = Fixture.Integer();
                var culture = Fixture.String();
                var currencyCode = Fixture.String();

                var selectionCriteria = new WipSelectionCriteria
                {
                    ItemDate = Fixture.Today(),
                    CaseIds = new []{ Fixture.Integer() },
                    DebtorId = Fixture.Integer()
                };

                var exchangeDetails = new ExchangeDetails
                {
                    SellRate = Fixture.Decimal()
                };

                var wipItem = new AvailableWipItem
                {
                    EntityId = Fixture.Integer(),
                    TransactionId = Fixture.Integer(),
                    WipSeqNo = Fixture.Short(),
                    BillBuyRate = Fixture.Decimal(),
                    BillSellRate = Fixture.Decimal()
                };

                var fixture = new WipItemServiceFixture();

                fixture.ExchangeDetailsResolver.Resolve(userId, 
                                                        currencyCode,
                                                        transactionDate: selectionCriteria.ItemDate,
                                                        caseId: selectionCriteria.CaseIds.Single(),
                                                        nameId: selectionCriteria.DebtorId)
                       .Returns(exchangeDetails);

                fixture.AvailableWipItemCommands.GetAvailableWipItems(userId, culture, selectionCriteria)
                       .Returns(new[] { wipItem });

                var result = await fixture.Subject.GetWipItemExchangeRates(userId, culture, currencyCode, selectionCriteria);

                Assert.Equal(exchangeDetails.SellRate, result.DebtorExchangeRate);
                Assert.Equal(wipItem.EntityId, result.WipItems.First().WipEntityId);
                Assert.Equal(wipItem.TransactionId, result.WipItems.First().WipTransactionId);
                Assert.Equal(wipItem.WipSeqNo, result.WipItems.First().WipSequenceNo);
                Assert.Equal(wipItem.BillBuyRate, result.WipItems.First().BillBuyRate);
                Assert.Equal(wipItem.BillSellRate, result.WipItems.First().BillSellRate);
            }
        }

        public class RecalculateDiscountsMethod
        {
            readonly int _userId = Fixture.Integer();
            readonly string _culture = Fixture.String();
            readonly decimal _billedAmount = Fixture.Decimal();
            readonly int _raisedByStaffId = Fixture.Integer();

            [Theory]
            [InlineData(true)]
            [InlineData(false)]
            public async Task ShouldReturnWithNullLocalBilledValue(bool discountNotInBillingValue)
            {
                var wipItem = new AvailableWipItem
                {
                    EntityId = Fixture.Integer(),
                    TransactionId = Fixture.Integer(),
                    WipSeqNo = Fixture.Short(),
                    DebtorId = Fixture.Integer(),
                    CaseId = Fixture.Integer(),
                    LocalBilled = Fixture.Decimal()
                };

                var fixture = new WipItemServiceFixture();

                fixture.SiteControlReader.Read<bool>(SiteControls.DiscountNotInBilling).Returns(discountNotInBillingValue);

                fixture.DiscountAndMargins.GetDiscountDetails(Arg.Any<int>(), Arg.Any<string>(), Arg.Any<int>(), Arg.Any<int?>(), Arg.Any<int?>(), Arg.Any<int>())
                       .Returns(new DiscountDetails());

                var result = await fixture.Subject.RecalculateDiscounts(_userId, _culture, _billedAmount, _raisedByStaffId, new[] { wipItem });

                Assert.Null(result.Single().LocalBilled);
            }

            [Fact]
            public async Task ShouldReturnWithCalculatedBillingDiscounts()
            {
                var wipItem = new AvailableWipItem
                {
                    EntityId = Fixture.Integer(),
                    TransactionId = Fixture.Integer(),
                    WipSeqNo = Fixture.Short(),
                    DebtorId = Fixture.Integer(),
                    CaseId = Fixture.Integer(),
                    LocalBilled = Fixture.Decimal(),
                    TransactionDate = Fixture.Today(),
                    StaffId = Fixture.Integer(),
                    StaffName = Fixture.String()
                };

                var discountDetails = new DiscountDetails
                {
                    WipCode = Fixture.String(),
                    WipDescription = Fixture.String(),
                    WipCodeSortOrder = Fixture.Integer(),
                    WipTypeId = Fixture.String(),
                    WipTypeSortOrder = Fixture.Integer(),
                    WipCategory = Fixture.String(),
                    WipCategorySortOrder = Fixture.Integer(),
                    WipTaxCode = Fixture.String(),
                    NarrativeId = Fixture.Integer(),
                    NarrativeText = Fixture.String(),
                    NarrativeCode = Fixture.String(),
                    NarrativeTitle = Fixture.String()
                };

                var calculatedDiscount = Fixture.Decimal();

                var fixture = new WipItemServiceFixture();

                fixture.SiteControlReader.Read<bool>(SiteControls.DiscountNotInBilling).Returns(false);

                fixture.DiscountAndMargins.GetDiscountDetails(Arg.Any<int>(), Arg.Any<string>(), Arg.Any<int>(), Arg.Any<int?>(), Arg.Any<int?>(), Arg.Any<int>())
                       .Returns(discountDetails);

                fixture.DiscountAndMargins.GetBillingDiscount(Arg.Any<int>(), Arg.Any<string>(), Arg.Any<int>(), Arg.Any<int?>(), Arg.Any<decimal?>())
                       .Returns(calculatedDiscount);

                var result = (await fixture.Subject.RecalculateDiscounts(_userId, _culture, _billedAmount, _raisedByStaffId, new[] { wipItem })).ToArray();
                
                Assert.Equal(Fixture.Today(), result.Single().TransactionDate);
                Assert.Equal(discountDetails.WipDescription, result.Single().Description);
                Assert.Equal(discountDetails.WipCode, result.Single().WipCode);
                Assert.Equal(discountDetails.WipCategory, result.Single().WipCategory);
                Assert.Equal(discountDetails.WipTypeId, result.Single().WipTypeId);
                Assert.Equal(discountDetails.WipCategorySortOrder, result.Single().WipCategorySortOrder);
                Assert.Equal(discountDetails.WipTaxCode, result.Single().TaxCode);
                Assert.Equal(discountDetails.NarrativeId, result.Single().NarrativeId);
                Assert.Equal(discountDetails.NarrativeText, result.Single().ShortNarrative);
                Assert.Equal(calculatedDiscount * -1, result.Single().LocalBilled);
                Assert.Equal(calculatedDiscount * -1, result.Single().Balance);
                
                Assert.True(result.Single().IsDraft);
                Assert.True(result.Single().DraftWipData.IsDiscount);
                Assert.True(result.Single().DraftWipData.IsWipItem);
                Assert.True(result.Single().DraftWipData.IsBillingDiscount);

                Assert.Equal(discountDetails.WipCode, result.Single().DraftWipData.ActivityId);
                Assert.Equal(discountDetails.WipDescription, result.Single().DraftWipData.Activity);
                Assert.Equal(discountDetails.WipCategory, result.Single().DraftWipData.WipCategory);
                Assert.Equal(discountDetails.WipTypeId, result.Single().DraftWipData.WipTypeId);
                Assert.Equal(discountDetails.WipCategorySortOrder, result.Single().DraftWipData.WipCategorySortOrder);
                Assert.Equal(discountDetails.NarrativeId, result.Single().DraftWipData.NarrativeId);
                Assert.Equal(discountDetails.NarrativeText, result.Single().DraftWipData.Narrative);

                Assert.Equal(wipItem.CaseId, result.Single().DraftWipData.CaseId);
                Assert.Equal(wipItem.TransactionDate, result.Single().DraftWipData.EntryDate);
                Assert.Equal(wipItem.EntityId, result.Single().DraftWipData.EntityId);
                Assert.Equal(wipItem.StaffId, result.Single().DraftWipData.StaffId);
                Assert.Equal(wipItem.DebtorId, result.Single().DraftWipData.NameId);

                Assert.Equal(calculatedDiscount * -1, result.Single().DraftWipData.LocalValue);
                Assert.Equal(calculatedDiscount * -1, result.Single().DraftWipData.Balance);
            }
        }
        
        public class ConvertStampFeeWipToAvailableWipItemsMethod
        {
            [Fact]
            public async Task ShouldReturnResultFromDraftWipItemComponent()
            {
                var userId = Fixture.Integer();
                var culture = Fixture.String();
                var draftWip = new DraftWip { NameId = Fixture.Integer(), CaseId = Fixture.Integer() };
                var staffId = Fixture.Integer();
                var billDate = Fixture.Today();

                var wipItems = new[] { new AvailableWipItem() };

                var fixture = new WipItemServiceFixture();

                fixture.DraftWipItem.ConvertToAvailableWipItems(Arg.Any<int>(), Arg.Any<string>(), 
                                                                Arg.Any<DraftWip>(), Arg.Any<string>(), Arg.Any<DateTime>(), Arg.Any<int>(), Arg.Any<int>(), Arg.Any<int?>()
                                                                )
                       .Returns(wipItems);

                var result = await fixture.Subject.ConvertStampFeeWipToAvailableWipItems(userId, culture, draftWip, staffId, billDate);

                Assert.Equal(wipItems, result);

                fixture.DraftWipItem
                       .Received(1)
                       .ConvertToAvailableWipItems(userId, culture, draftWip, null, billDate, staffId, (int) draftWip.NameId, draftWip.CaseId)
                       .IgnoreAwaitForNSubstituteAssertion();
            }
        }
        
        class WipItemServiceFixture : IFixture<WipItemsService>
        {
            public ISiteControlReader SiteControlReader { get; } = Substitute.For<ISiteControlReader>();

            public IAvailableWipItemCommands AvailableWipItemCommands { get; } = Substitute.For<IAvailableWipItemCommands>();

            public IExchangeDetailsResolver ExchangeDetailsResolver { get; } = Substitute.For<IExchangeDetailsResolver>();

            public IDiscountsAndMargins DiscountAndMargins { get; } = Substitute.For<IDiscountsAndMargins>();

            public IDraftWipItem DraftWipItem { get; } = Substitute.For<IDraftWipItem>();

            public WipItemsService Subject { get; }

            public WipItemServiceFixture()
            {
                Subject = new WipItemsService(SiteControlReader, AvailableWipItemCommands, ExchangeDetailsResolver, DiscountAndMargins, DraftWipItem, Fixture.Today);
            }
        }
    }
}
