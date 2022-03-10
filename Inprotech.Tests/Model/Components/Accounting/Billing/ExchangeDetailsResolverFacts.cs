using System;
using System.Collections.Generic;
using System.Threading.Tasks;
using Inprotech.Infrastructure;
using Inprotech.Tests.Extensions;
using Inprotech.Tests.Fakes;
using InprotechKaizen.Model.Accounting;
using InprotechKaizen.Model.Components.Accounting.Billing;
using NSubstitute;
using Xunit;
using WipCategory = InprotechKaizen.Model.Accounting.Work.WipCategory;

namespace Inprotech.Tests.Model.Components.Accounting.Billing
{
    public class ExchangeDetailsResolverFacts : FactBase
    {
        readonly int _userId = Fixture.Integer();
        readonly IGetExchangeDetailsCommand _getExchangeDetailsCommand = Substitute.For<IGetExchangeDetailsCommand>();
        
        ExchangeDetailsResolver CreateSubject(ExchangeDetails exchangeDetails = null, bool? historicalExchangeRateSiteControl = false, bool? historicalExchangeForOpenPeriod = false)
        {
            _getExchangeDetailsCommand.Run(Arg.Any<int>(), Arg.Any<string>(), Arg.Any<DateTime?>(), Arg.Any<bool>(), Arg.Any<int?>(), Arg.Any<int?>(), Arg.Any<bool?>(), Arg.Any<string>())
                                      .Returns(exchangeDetails ?? new ExchangeDetails());
            
            var siteControlReader = Substitute.For<ISiteControlReader>();
            siteControlReader.ReadMany<bool>(SiteControls.HistoricalExchRate, SiteControls.HistExchForOpenPeriod)
                             .Returns(new Dictionary<string, bool>()
                                      {
                                          { SiteControls.HistoricalExchRate, historicalExchangeRateSiteControl ?? false},
                                          { SiteControls.HistExchForOpenPeriod, historicalExchangeForOpenPeriod ?? false}
                                      });

            return new ExchangeDetailsResolver(Db, siteControlReader, _getExchangeDetailsCommand, Fixture.Today);
        }
        
        [Fact]
        public async Task ShouldUseWipCategoryHistoricalExchangeRateIfProvided()
        {
            var wipCategory = new WipCategory
            {
                Id = Fixture.String(),
                HistoricalExchangeRate = Fixture.Boolean()
            }.In(Db);

            var subject = CreateSubject();

            var _ = await subject.Resolve(_userId, wipCategory: wipCategory.Id);

            _getExchangeDetailsCommand.Received(1)
                                      .Run(_userId, Arg.Any<string>(), Arg.Any<DateTime?>(), 
                                           wipCategory.HistoricalExchangeRate.GetValueOrDefault(), 
                                           Arg.Any<int?>(), Arg.Any<int?>(), Arg.Any<bool?>(), Arg.Any<string>())
                                      .IgnoreAwaitForNSubstituteAssertion();
        }

        [Fact]
        public async Task ShouldUseHistoricalExchangeRateSiteControlWhenWipCategoryIsNotProvided()
        {
            var scValue = Fixture.Boolean();

            var subject = CreateSubject(historicalExchangeRateSiteControl: scValue);

            var _ = await subject.Resolve(_userId);

            _getExchangeDetailsCommand.Received(1)
                                      .Run(_userId, Arg.Any<string>(), Arg.Any<DateTime?>(), 
                                           scValue, 
                                           Arg.Any<int?>(), Arg.Any<int?>(), Arg.Any<bool?>(), Arg.Any<string>())
                                      .IgnoreAwaitForNSubstituteAssertion();
        }

        [Fact]
        public async Task ShouldUseTransactionDateInputWhenHistoricalExchangeRateForOpenPeriodIsFalse()
        {
            var transactionDate = Fixture.PastDate();

            var subject = CreateSubject(historicalExchangeForOpenPeriod: false);

            var _ = await subject.Resolve(_userId, transactionDate: transactionDate);

            _getExchangeDetailsCommand.Received(1)
                                      .Run(_userId, Arg.Any<string>(), 
                                           transactionDate, 
                                           Arg.Any<bool>(), 
                                           Arg.Any<int?>(), Arg.Any<int?>(), Arg.Any<bool?>(), Arg.Any<string>())
                                      .IgnoreAwaitForNSubstituteAssertion();
        }

        [Fact] 
        public async Task ShouldUseDefaultTransactionDateAsTodayWhenHistoricalExchangeRateForOpenPeriodIsFalse()
        {
            var expectedTransactionDate = Fixture.Today();

            var subject = CreateSubject(historicalExchangeForOpenPeriod: false);

            var _ = await subject.Resolve(_userId, transactionDate: null);

            _getExchangeDetailsCommand.Received(1)
                                      .Run(_userId, Arg.Any<string>(), 
                                           expectedTransactionDate, 
                                           Arg.Any<bool>(), 
                                           Arg.Any<int?>(), Arg.Any<int?>(), Arg.Any<bool?>(), Arg.Any<string>())
                                      .IgnoreAwaitForNSubstituteAssertion();
        }

        [Fact] 
        public async Task ShouldUseOpenPeriodStartDateWhenTransactionDateIsEarlierAndHistoricalExchangeRateForOpenPeriodIsFalse()
        {
            var inputTransactionDate = Fixture.Today().AddDays(-1);

            var expectedDerivedTransactionDate = Fixture.Today();

            new Period
            {
                StartDate = expectedDerivedTransactionDate,
                EndDate = Fixture.FutureDate(),
                PostingCommenced = Fixture.PastDate()
            }.In(Db);

            var subject = CreateSubject(historicalExchangeForOpenPeriod: true);

            var _ = await subject.Resolve(_userId, transactionDate: inputTransactionDate);

            _getExchangeDetailsCommand.Received(1)
                                      .Run(_userId, Arg.Any<string>(), 
                                           expectedDerivedTransactionDate, 
                                           Arg.Any<bool>(), 
                                           Arg.Any<int?>(), Arg.Any<int?>(), Arg.Any<bool?>(), Arg.Any<string>())
                                      .IgnoreAwaitForNSubstituteAssertion();
        }

        [Fact] 
        public async Task ShouldUseOpenPeriodTransactionDateIfItIsLaterThanOpenPeriodStartDateAndHistoricalExchangeRateForOpenPeriodIsFalse()
        {
            var inputTransactionDate = Fixture.Today();
            
            new Period
            {
                StartDate = Fixture.Today().AddDays(-1),
                EndDate = Fixture.FutureDate(),
                PostingCommenced = Fixture.PastDate()
            }.In(Db);

            var subject = CreateSubject(historicalExchangeForOpenPeriod: true);

            var _ = await subject.Resolve(_userId, transactionDate: inputTransactionDate);

            _getExchangeDetailsCommand.Received(1)
                                      .Run(_userId, Arg.Any<string>(), 
                                           inputTransactionDate, 
                                           Arg.Any<bool>(), 
                                           Arg.Any<int?>(), Arg.Any<int?>(), Arg.Any<bool?>(), Arg.Any<string>())
                                      .IgnoreAwaitForNSubstituteAssertion();
        }

        [Fact] 
        public async Task ShouldReturnResultFromGetExchangeDetailsCommand()
        {
            var expected = new ExchangeDetails();

            var subject = CreateSubject(expected);

            var r = await subject.Resolve(_userId);

            Assert.Equal(expected, r);
        }
    }
}
