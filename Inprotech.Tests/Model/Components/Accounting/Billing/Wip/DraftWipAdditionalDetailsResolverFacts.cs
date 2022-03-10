using System;
using System.Threading.Tasks;
using Inprotech.Infrastructure;
using Inprotech.Tests.Extensions;
using Inprotech.Tests.Fakes;
using InprotechKaizen.Model.Accounting.Work;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Components.Accounting.Billing;
using InprotechKaizen.Model.Components.Accounting.Billing.Tax;
using InprotechKaizen.Model.Components.Accounting.Billing.Wip;
using InprotechKaizen.Model.Names;
using InprotechKaizen.Model.Security;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Model.Components.Accounting.Billing.Wip
{
    public class DraftWipAdditionalDetailsResolverFacts : FactBase
    {
        readonly IExchangeDetailsResolver _exchangeDetailsResolver = Substitute.For<IExchangeDetailsResolver>();
        readonly IDefaultTaxCodeResolver _defaultTaxCodeResolver = Substitute.For<IDefaultTaxCodeResolver>();
        readonly ITaxRateResolver _taxRateResolver = Substitute.For<ITaxRateResolver>();

        DraftWipAdditionalDetailsResolver CreateSubject(int? wipProfitCenterSource = null)
        {
            var siteControlReader = Substitute.For<ISiteControlReader>();
            siteControlReader.Read<int?>(SiteControls.WIPProfitCentreSource).Returns(wipProfitCenterSource);

            return new DraftWipAdditionalDetailsResolver(Db, siteControlReader, _exchangeDetailsResolver, _defaultTaxCodeResolver, _taxRateResolver);
        }

        [Fact]
        public async Task ShouldResolveStaffDetailsFromStaffWhoRecordedTheWip()
        {
            var profitCentre = new ProfitCentre(Fixture.String(), Fixture.String()).In(Db);

            var employee = new Employee { ProfitCentre = profitCentre.Id, SignOffName = Fixture.String() }.In(Db);

            var user = new User().In(Db);

            var subject = CreateSubject(1);

            var r = await subject.Resolve(user.Id, Fixture.String(), Fixture.Integer(), null, null, Fixture.Today(),
                                          employee.Id, /* staff who recorded the wip */
                                          Fixture.Integer(), Fixture.Today(), null, null, Fixture.String());

            Assert.Equal(employee.SignOffName, r.StaffSignOffName);
            Assert.Equal(employee.ProfitCentre, r.ProfitCentreCode);
            Assert.Equal(profitCentre.Name, r.ProfitCentre);
        }

        [Fact]
        public async Task ShouldResolveProfitCenterFromSignedInUser()
        {
            var profitCentre = new ProfitCentre(Fixture.String(), Fixture.String()).In(Db);

            var employee = new Employee { ProfitCentre = profitCentre.Id, SignOffName = Fixture.String() }.In(Db);

            var user = new User { NameId = employee.Id }.In(Db);

            var subject = CreateSubject(); /* WIP profit centre site control is unset */

            var r = await subject.Resolve(user.Id, Fixture.String(), Fixture.Integer(), null, null, Fixture.Today(),
                                          employee.Id,
                                          Fixture.Integer(), Fixture.Today(), null, null, Fixture.String());

            Assert.Equal(employee.SignOffName, r.StaffSignOffName);
            Assert.Equal(employee.ProfitCentre, r.ProfitCentreCode);
            Assert.Equal(profitCentre.Name, r.ProfitCentre);
        }

        [Fact]
        public async Task ShouldResolveExchangeDetails()
        {
            var billCurrency = Fixture.String();
            var wipCategory = Fixture.String();
            var wipTypeId = Fixture.String();
            var wipCode = Fixture.String();
            var staffId = Fixture.Integer();
            var billDate = Fixture.Today();
            var caseId = Fixture.Integer();
            var debtorId = Fixture.Integer();
            var user = new User().In(Db);

            var exchangeDetails = new ExchangeDetails
            {
                BuyRate = Fixture.Decimal(),
                SellRate = Fixture.Decimal()
            };

            _exchangeDetailsResolver.Resolve(user.Id, Arg.Any<string>(), Arg.Any<string>(), Arg.Any<string>(), Arg.Any<DateTime?>(), Arg.Any<int?>(), Arg.Any<int>())
                                    .Returns(exchangeDetails);

            var subject = CreateSubject();

            var r = await subject.Resolve(user.Id, Fixture.String(), debtorId, caseId, billCurrency, billDate, staffId, null, Fixture.Today(), wipTypeId, wipCategory, wipCode);

            Assert.Equal(exchangeDetails.BuyRate, r.BillBuyRate);
            Assert.Equal(exchangeDetails.SellRate, r.BillSellRate);
        }

        [Fact]
        public async Task ShouldResolveWipDetails()
        {
            var billCurrency = Fixture.String();
            var staffId = Fixture.Integer();
            var billDate = Fixture.Today();
            var caseId = Fixture.Integer();
            var debtorId = Fixture.Integer();
            var user = new User().In(Db);

            var wipCategory = new WipCategory
            {
                Id = Fixture.String(),
                Description = Fixture.String(),
                CategorySortOrder = Fixture.Short()
            }.In(Db);

            var wipType = new WipType
            {
                Id = Fixture.String(),
                Description = Fixture.String(),
                WipTypeSortOrder = Fixture.Short(),
                CategoryId = wipCategory.Id
            }.In(Db);

            var wipTemplate = new WipTemplate
            {
                WipTypeId = wipType.Id,
                Description = Fixture.String(),
                WipCode = Fixture.String(),
                WipCodeSortOrder = Fixture.Short()
            }.In(Db);

            var subject = CreateSubject();

            var r = await subject.Resolve(user.Id, Fixture.String(), debtorId, caseId, billCurrency, billDate, staffId, null, Fixture.Today(), wipType.Id, wipCategory.Id, wipTemplate.WipCode);

            Assert.Equal(wipCategory.CategorySortOrder, (short?)r.WipCategorySortOrder);
            Assert.Equal(wipCategory.Description, r.WipCategoryDescription);

            Assert.Equal(wipType.WipTypeSortOrder, (short?)r.WipTypeSortOrder);
            Assert.Equal(wipType.Description, r.WipTypeDescription);

            Assert.Equal(wipTemplate.WipCodeSortOrder, (short?)r.WipCodeSortOrder);
        }

        [Fact]
        public async Task ShouldResolveTaxDetails()
        {
            var billCurrency = Fixture.String();
            var wipCategory = Fixture.String();
            var wipTypeId = Fixture.String();
            var wipCode = Fixture.String();
            var staffId = Fixture.Integer();
            var billDate = Fixture.Today();
            var itemDate = Fixture.PastDate();
            var caseId = Fixture.Integer();
            var debtorId = Fixture.Integer();
            var entityId = Fixture.Integer();
            var user = new User().In(Db);

            var taxCode = Fixture.String();
            var taxRate = new TaxRate { Code = taxCode, Rate = Fixture.Decimal() };

            _defaultTaxCodeResolver.Resolve(user.Id, Arg.Any<string>(), Arg.Any<int>(), Arg.Any<int?>(), Arg.Any<string>(), Arg.Any<int?>(), Arg.Any<int?>())
                                   .Returns(taxCode);

            _taxRateResolver.Resolve(user.Id, Arg.Any<string>(), Arg.Any<string>(), Arg.Any<int?>(), Arg.Any<int?>(), Arg.Any<DateTime>())
                            .Returns(taxRate);

            var subject = CreateSubject();

            var r = await subject.Resolve(user.Id, Fixture.String(), debtorId, caseId, billCurrency, billDate, staffId, entityId, itemDate, wipTypeId, wipCategory, wipCode);

            Assert.Equal(taxCode, r.TaxCode);
            Assert.Equal(taxRate.Rate, r.TaxRate);

            _defaultTaxCodeResolver.Received(1)
                                   .Resolve(user.Id, Arg.Any<string>(), debtorId, caseId, wipCode, staffId, entityId)
                                   .IgnoreAwaitForNSubstituteAssertion();

            _taxRateResolver.Received(1)
                            .Resolve(user.Id, Arg.Any<string>(), taxCode, staffId, entityId, itemDate)
                            .IgnoreAwaitForNSubstituteAssertion();
        }
    }
}
