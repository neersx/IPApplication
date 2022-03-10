using System;
using System.Collections.Generic;
using System.Threading.Tasks;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Tests.Extensions;
using Inprotech.Web.Accounting.Billing;
using InprotechKaizen.Model.Accounting;
using InprotechKaizen.Model.Components.Accounting.Billing.Tax;
using InprotechKaizen.Model.Components.Accounting.Billing.Wip;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.Security;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Accounting.Billing
{
    public class WipSelectionControllerFacts
    {
        readonly IWipItemsService _wipItemsService = Substitute.For<IWipItemsService>();
        readonly ITaxRateResolver _taxRateResolver = Substitute.For<ITaxRateResolver>();

        WipSelectionController CreateSubject()
        {
            var securityContext = Substitute.For<ISecurityContext>();
            securityContext.User.Returns(new User());

            var preferredCultureResolver = Substitute.For<IPreferredCultureResolver>();

            return new WipSelectionController(securityContext, preferredCultureResolver, _wipItemsService, _taxRateResolver);
        }

        [Fact]
        public async Task ShouldReturnRequestedWipItems()
        {
            var selectionCriteria = new WipSelectionCriteria();

            var expected = new[] { new AvailableWipItem() };

            _wipItemsService.GetAvailableWipItems(Arg.Any<int>(), Arg.Any<string>(), selectionCriteria)
                            .Returns(expected);

            var subject = CreateSubject();

            var r = await subject.GetWipItems(selectionCriteria);

            Assert.Equal(expected, r);
        }

        [Fact]
        public async Task ShouldReturnRequestedExchangeRates()
        {
            var selectionCriteria = new WipSelectionCriteria();

            var expected = new WipItemExchangeRates();

            _wipItemsService.GetWipItemExchangeRates(Arg.Any<int>(), Arg.Any<string>(),
                                                     Arg.Any<string>(), selectionCriteria)
                            .Returns(expected);

            var subject = CreateSubject();

            var r = await subject.GetWipItemExchangeRates(Fixture.String(), selectionCriteria);

            Assert.Equal(expected, r);
        }

        [Fact]
        public async Task ShouldReturnRecalculatedDiscounts()
        {
            var billedAmount = Fixture.Long();
            var raisedByStaff = Fixture.Integer();
            var discountWipItems = new[] { new AvailableWipItem() };

            var expected = new[] { new AvailableWipItem() };

            _wipItemsService.RecalculateDiscounts(Arg.Any<int>(), Arg.Any<string>(),
                                                  Arg.Any<decimal>(), Arg.Any<int>(), Arg.Any<IEnumerable<AvailableWipItem>>())
                            .Returns(expected);

            var subject = CreateSubject();

            var r = await subject.RecalculateDiscounts(new WipSelectionController.DiscountRecalculationParameters
            {
                BilledAmount = billedAmount,
                RaisedByStaffId = raisedByStaff,
                DiscountWipItems = discountWipItems
            });

            Assert.Equal(expected, r);

            _wipItemsService.Received(1)
                            .RecalculateDiscounts(Arg.Any<int>(), Arg.Any<string>(), billedAmount, raisedByStaff, discountWipItems)
                            .IgnoreAwaitForNSubstituteAssertion();
        }

        [Fact]
        public async Task ShouldReturnTaxRatesBasedOnTransactionDate()
        {
            var entityId = Fixture.Integer();
            var raisedByStaff = Fixture.Integer();
            var transactionDate = Fixture.Today();

            var expected = new[] { new TaxRate() };

            _taxRateResolver.Resolve(Arg.Any<int>(), Arg.Any<string>(),
                                     Arg.Any<int>(), Arg.Any<int>(), Arg.Any<DateTime>())
                            .Returns(expected);

            var subject = CreateSubject();

            var r = await subject.TaxRates(entityId, raisedByStaff, transactionDate);

            Assert.Equal(expected, r);

            _taxRateResolver.Received(1)
                            .Resolve(Arg.Any<int>(), Arg.Any<string>(), raisedByStaff, entityId, transactionDate)
                            .IgnoreAwaitForNSubstituteAssertion();
        }

        [Fact]
        public async Task ShouldReturnDraftWipItemsConvertedToAvailableWipItems()
        {
            var draftWipItems = new[] { new CompleteDraftWipItem() };
            var itemType = ItemType.DebitNote;
            var staffId = Fixture.Integer();
            var billCurrency = Fixture.String();
            var billDate = Fixture.Today();
            var caseId = Fixture.Integer();
            var debtorId = Fixture.Integer();

            var parameters = new WipSelectionController.IncludeDraftWipItemsParameters
            {
                DraftWipItems = draftWipItems,
                ItemType = itemType,
                StaffId = staffId,
                BillCurrency = billCurrency,
                BillDate = billDate,
                CaseId = caseId,
                DebtorId = debtorId
            };

            var expected = new[] { new AvailableWipItem() };

            _wipItemsService.ConvertDraftWipToAvailableWipItems(Arg.Any<int>(), Arg.Any<string>(),
                                                                Arg.Any<CompleteDraftWipItem[]>(),
                                                                Arg.Any<ItemType>(), Arg.Any<int>(), Arg.Any<string>(), Arg.Any<DateTime>(),
                                                                Arg.Any<int?>(), Arg.Any<int>())
                            .Returns(expected);

            var subject = CreateSubject();

            var r = await subject.IncludeDraftWipItems(parameters);

            Assert.Equal(expected, r);

            _wipItemsService.Received(1)
                            .ConvertDraftWipToAvailableWipItems(Arg.Any<int>(), Arg.Any<string>(),
                                                                parameters.DraftWipItems, parameters.ItemType, parameters.StaffId, parameters.BillCurrency, parameters.BillDate,
                                                                parameters.CaseId, parameters.DebtorId)
                            .IgnoreAwaitForNSubstituteAssertion();
        }

        [Fact]
        public async Task ShouldReturnStampFeeConvertedAvailableWipItems()
        {
            var draftWipItem = new DraftWip();
            var raisedByStaffId = Fixture.Integer();
            var billDate = Fixture.Today();

            var expected = new[] { new AvailableWipItem() };

            _wipItemsService.ConvertStampFeeWipToAvailableWipItems(Arg.Any<int>(), Arg.Any<string>(),
                                                                   Arg.Any<DraftWip>(),
                                                                   Arg.Any<int>(), Arg.Any<DateTime>())
                            .Returns(expected);

            var subject = CreateSubject();

            var r = await subject.IncludeStampFees(raisedByStaffId, billDate, draftWipItem);

            Assert.Equal(expected, r);

            _wipItemsService.Received(1)
                            .ConvertStampFeeWipToAvailableWipItems(Arg.Any<int>(), Arg.Any<string>(),
                                                                   draftWipItem, raisedByStaffId, billDate)
                            .IgnoreAwaitForNSubstituteAssertion();
        }
    }
}
