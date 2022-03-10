using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Contracts;
using Inprotech.Infrastructure.Policy;
using InprotechKaizen.Model.Components.Accounting.Billing;
using InprotechKaizen.Model.Components.Accounting.Wip;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Accounting.Work
{
    public class DebtorWipSplitterFacts
    {
        public class DebtorWipSplitterFixture : IFixture<DebtorWipSplitter>
        {
            readonly Queue<decimal> _chargeOutRates = new Queue<decimal>();
            readonly Queue<string> _foreignCurrencies = new Queue<string>();

            public DebtorWipSplitterFixture()
            {
                var siteCurrencyFormat = Substitute.For<ISiteCurrencyFormat>();
                siteCurrencyFormat.Resolve().Returns(new LocalCurrency {LocalCurrencyCode = "AUD", LocalDecimalPlaces = 2});

                WipCosting = Substitute.For<IWipCosting>();

                WipDebtorSelector = Substitute.For<IWipDebtorSelector>();

                BestNarrativeResolver = Substitute.For<IBestTranslatedNarrativeResolver>();

                Logger = Substitute.For<ILogger<DebtorWipSplitter>>();

                Subject = new DebtorWipSplitter(Logger, WipCosting, WipDebtorSelector, BestNarrativeResolver, siteCurrencyFormat);
            }

            public IWipCosting WipCosting { get; }

            public IWipDebtorSelector WipDebtorSelector { get; }

            public IBestTranslatedNarrativeResolver BestNarrativeResolver { get; }

            public ILogger<DebtorWipSplitter> Logger { get; set; }

            public DebtorWipSplitter Subject { get; }

            void ConfigureCosting()
            {
                WipCosting.For(Arg.Any<UnpostedWip>())
                          .Returns(x =>
                          {
                              var wip = (UnpostedWip) x[0];

                              var costed = new WipCost
                              {
                                  UnitsPerHour = wip.TotalUnits,
                                  LocalValue = wip.LocalValue,
                                  LocalDiscount = wip.DiscountValue,
                                  LocalDiscountForMargin = wip.DiscountForMargin,
                                  MarginNo = wip.MarginNo,
                                  ForeignValue = wip.ForeignValue,
                                  ForeignDiscount = wip.ForeignDiscount,
                                  ForeignDiscountForMargin = wip.ForeignDiscountForMargin,
                                  ExchangeRate = wip.ExchangeRate,
                                  ChargeOutRate = _chargeOutRates.Any() ? _chargeOutRates.Dequeue() : wip.ChargeOutRate,
                                  CurrencyCode = _foreignCurrencies.Any() ? _foreignCurrencies.Dequeue() : wip.ForeignCurrency
                              };

                              if (!string.IsNullOrWhiteSpace(costed.CurrencyCode))
                              {
                                  costed.ForeignValue = wip.ForeignValue ?? wip.ForeignCost + wip.ForeignMargin.GetValueOrDefault();
                              }

                              return costed;
                          });
            }

            public DebtorWipSplitterFixture WithCosting(params decimal[] chargeOutRates)
            {
                foreach (var chargeOutRate in chargeOutRates)
                    _chargeOutRates.Enqueue(chargeOutRate);

                ConfigureCosting();

                return this;
            }

            public DebtorWipSplitterFixture WithCostingForForeignDebtors(params string[] currencyCodes)
            {
                /*
                 * this is so that we can ensure at least one foreign currency is set
                 * to the costed wip return as parent wip
                 */

                foreach (var currencyCode in currencyCodes)
                    _foreignCurrencies.Enqueue(currencyCode);

                ConfigureCosting();

                return this;
            }

            public DebtorWipSplitterFixture WithCostingForLocalDebtors()
            {
                ConfigureCosting();

                return this;
            }
        }

        public class AggregateSplits
        {
            [Fact]
            public async Task ShouldReturnAggregatedLocalAmounts()
            {
                var caseKey = Fixture.Integer();
                var wipCode = Fixture.String();
                var debtor1 = new Debtor {CaseId = caseKey, NameId = Fixture.Integer(), NameType = "D", BillingPercentage = 60};
                var debtor2 = new Debtor {CaseId = caseKey, NameId = Fixture.Integer(), NameType = "D", BillingPercentage = 40};

                var wipToSplit = new UnpostedWip {CaseKey = caseKey, NameKey = debtor1.NameId, WipCode = wipCode, LocalCost = (decimal?) 100.00};

                var f = new DebtorWipSplitterFixture().WithCostingForLocalDebtors();

                f.WipDebtorSelector.GetDebtorsForCaseWip(caseKey, wipCode)
                 .Returns(new[] {debtor1, debtor2}.AsQueryable());

                var result = (await f.Subject.Split("en", wipToSplit)).ToArray();

                var aggregate = result.First();
                var splits = result.Skip(1).ToArray();

                Assert.Equal(splits.Sum(_ => _.LocalCost), aggregate.LocalCost);
                Assert.Equal(splits.Sum(_ => _.LocalValue), aggregate.LocalValue);
                Assert.Equal(splits.Sum(_ => _.DiscountValue), aggregate.DiscountValue);
                Assert.Equal(splits.Sum(_ => _.DiscountForMargin), aggregate.DiscountForMargin);
                Assert.Equal(splits.Sum(_ => _.MarginValue), aggregate.MarginValue);
            }

            [Fact]
            public async Task ShouldReturnAggregatedForeignAmounts()
            {
                var caseKey = Fixture.Integer();
                var wipCode = Fixture.String();
                var debtor1 = new Debtor {CaseId = caseKey, NameId = Fixture.Integer(), NameType = "D", BillingPercentage = 60};
                var debtor2 = new Debtor {CaseId = caseKey, NameId = Fixture.Integer(), NameType = "D", BillingPercentage = 40};

                var wipToSplit = new UnpostedWip {CaseKey = caseKey, NameKey = debtor1.NameId, WipCode = wipCode, ForeignCost = (decimal?) 100.00, ForeignCurrency = "GBP"};

                var f = new DebtorWipSplitterFixture().WithCostingForForeignDebtors("GBP");

                f.WipDebtorSelector.GetDebtorsForCaseWip(caseKey, wipCode)
                 .Returns(new[] {debtor1, debtor2}.AsQueryable());

                var result = (await f.Subject.Split("en", wipToSplit)).ToArray();

                var aggregate = result.First();
                var splits = result.Skip(1).ToArray();

                Assert.Equal(splits.Sum(_ => _.ForeignDiscount), aggregate.ForeignDiscount);
                Assert.Equal(splits.Sum(_ => _.ForeignMargin), aggregate.ForeignMargin);
                Assert.Equal(splits.Sum(_ => _.ForeignDiscountForMargin), aggregate.ForeignDiscountForMargin);
                Assert.Equal(splits.Sum(_ => _.ForeignCost), aggregate.ForeignCost);
                Assert.Equal("GBP", aggregate.ForeignCurrency);
            }

            [Fact(Skip = "TO REVIEW - original wip should have foreign cost already.")]
            public async Task ShouldNotAggregateForeignPropertiesBecauseSplitWipHaveDifferentCurrencyCodes()
            {
                var caseKey = Fixture.Integer();
                var wipCode = Fixture.String();
                var debtor1 = new Debtor {CaseId = caseKey, NameId = Fixture.Integer(), NameType = "D", BillingPercentage = 60}; /* GBP */
                var debtor2 = new Debtor {CaseId = caseKey, NameId = Fixture.Integer(), NameType = "D", BillingPercentage = 40}; /* US */

                var wipToSplit = new UnpostedWip {CaseKey = caseKey, NameKey = debtor1.NameId, WipCode = wipCode, ForeignCost = (decimal?) 100.00, ForeignCurrency = "GBP"};

                var f = new DebtorWipSplitterFixture().WithCostingForForeignDebtors("GBP", "US");

                f.WipDebtorSelector.GetDebtorsForCaseWip(caseKey, wipCode)
                 .Returns(new[] {debtor1, debtor2}.AsQueryable());

                var result = await f.Subject.Split("en", wipToSplit);

                var aggregate = result.First();

                Assert.Null(aggregate.ForeignCost);
                Assert.Null(aggregate.ForeignCurrency);
            }

            [Fact]
            public async Task ShouldNotAggregateChargeRateBecauseSplitsHaveDifferentChargeRates()
            {
                var caseKey = Fixture.Integer();
                var wipCode = Fixture.String();
                var debtor1 = new Debtor {CaseId = caseKey, NameId = Fixture.Integer(), NameType = "D", BillingPercentage = 60};
                var debtor2 = new Debtor {CaseId = caseKey, NameId = Fixture.Integer(), NameType = "D", BillingPercentage = 40};

                var chargeOutRate1 = Fixture.Decimal();
                var chargeOutRate2 = Fixture.Decimal();

                var wipToSplit = new UnpostedWip {CaseKey = caseKey, NameKey = debtor1.NameId, WipCode = wipCode, ForeignCost = (decimal?) 100.00};

                var f = new DebtorWipSplitterFixture().WithCosting(chargeOutRate1, chargeOutRate2);

                f.WipDebtorSelector.GetDebtorsForCaseWip(caseKey, wipCode)
                 .Returns(new[] {debtor1, debtor2}.AsQueryable());

                var result = await f.Subject.Split("en", wipToSplit);

                var aggregate = result.First();

                Assert.Null(aggregate.ChargeOutRate);
            }

            [Fact]
            public async Task ShouldReturnAggregatedChargeRateEqualsFirstSplitChargeRate()
            {
                var caseKey = Fixture.Integer();
                var wipCode = Fixture.String();
                var debtor1 = new Debtor {CaseId = caseKey, NameId = Fixture.Integer(), NameType = "D", BillingPercentage = 60};
                var debtor2 = new Debtor {CaseId = caseKey, NameId = Fixture.Integer(), NameType = "D", BillingPercentage = 40};

                var chargeOutRate1 = Fixture.Decimal();
                var chargeOutRate2 = chargeOutRate1;

                var wipToSplit = new UnpostedWip {CaseKey = caseKey, NameKey = debtor1.NameId, WipCode = wipCode, ForeignCost = (decimal?) 100.00};

                var f = new DebtorWipSplitterFixture().WithCosting(chargeOutRate1, chargeOutRate2);

                f.WipDebtorSelector.GetDebtorsForCaseWip(caseKey, wipCode)
                 .Returns(new[] {debtor1, debtor2}.AsQueryable());

                var result = await f.Subject.Split("en", wipToSplit);

                var aggregate = result.First();

                Assert.Equal(chargeOutRate1, aggregate.ChargeOutRate);
            }
        }

        public class SplitForDebtor
        {
            [Fact]
            public async Task ShouldSplitLocalWipCostByDebtorBillPercentage()
            {
                var caseKey = Fixture.Integer();
                var wipCode = Fixture.String();
                var debtor1 = new Debtor {CaseId = caseKey, NameId = Fixture.Integer(), NameType = "D", BillingPercentage = 60};
                var debtor2 = new Debtor {CaseId = caseKey, NameId = Fixture.Integer(), NameType = "D", BillingPercentage = 40};

                var wipToSplit = new UnpostedWip {CaseKey = caseKey, NameKey = debtor1.NameId, WipCode = wipCode, LocalCost = (decimal?) 100.00};

                var f = new DebtorWipSplitterFixture().WithCosting();

                f.WipDebtorSelector.GetDebtorsForCaseWip(caseKey, wipCode)
                 .Returns(new[] {debtor1, debtor2}.AsQueryable());

                var result = (await f.Subject.Split("en", wipToSplit)).ToArray();

                var splits = result.Skip(1).ToArray();

                Assert.Equal(60, splits[0].LocalCost);
                Assert.Equal(40, splits[1].LocalCost);
            }

            [Fact]
            public async Task ShouldSplitForeignWipCostByDebtorBillPercentage()
            {
                var caseKey = Fixture.Integer();
                var wipCode = Fixture.String();
                var debtor1 = new Debtor {CaseId = caseKey, NameId = Fixture.Integer(), NameType = "D", BillingPercentage = 60};
                var debtor2 = new Debtor {CaseId = caseKey, NameId = Fixture.Integer(), NameType = "D", BillingPercentage = 40};

                var wipToSplit = new UnpostedWip {CaseKey = caseKey, NameKey = debtor1.NameId, WipCode = wipCode, ForeignCost = (decimal?) 100.00, ForeignCurrency = "GBP"};

                var f = new DebtorWipSplitterFixture().WithCostingForForeignDebtors("GBP", "GBP");

                f.WipDebtorSelector.GetDebtorsForCaseWip(caseKey, wipCode)
                 .Returns(new[] {debtor1, debtor2}.AsQueryable());

                var result = (await f.Subject.Split("en", wipToSplit)).ToArray();

                var splits = result.Skip(1).ToArray();

                Assert.Equal(60, splits[0].ForeignCost);
                Assert.Equal(40, splits[1].ForeignCost);
            }

            [Fact]
            public async Task ShouldSplitBothLocalAndForeignWipCostByDebtorBillPercentage()
            {
                var caseKey = Fixture.Integer();
                var wipCode = Fixture.String();
                var debtor1 = new Debtor {CaseId = caseKey, NameId = Fixture.Integer(), NameType = "D", BillingPercentage = 60}; /* Foreign */
                var debtor2 = new Debtor {CaseId = caseKey, NameId = Fixture.Integer(), NameType = "D", BillingPercentage = 40}; /* Local */

                var wipToSplit = new UnpostedWip
                {
                    CaseKey = caseKey,
                    NameKey = debtor1.NameId,
                    WipCode = wipCode,
                    ForeignCost = 100, /* debtor1 is foreign with 60% split, 60% of 100 is 60 */
                    LocalCost = 200, /* debtor2 is local with 40% split, 40% of 200 is 80 */
                    ShouldUseSuppliedValues = true
                };

                var f = new DebtorWipSplitterFixture().WithCostingForForeignDebtors("GBP", string.Empty);

                f.WipDebtorSelector.GetDebtorsForCaseWip(caseKey, wipCode)
                 .Returns(new[] {debtor1, debtor2}.AsQueryable());

                var result = (await f.Subject.Split("en", wipToSplit)).ToArray();

                var splits = result.Skip(1).ToArray();

                Assert.Equal(60, splits[0].ForeignCost);
                Assert.Equal(80, splits[1].LocalCost);
            }
        }

        public class Narratives
        {
            [Fact]
            public async Task ShouldDefaultNarrativeIfItHasNotBeenOverridden()
            {
                BestNarrative BuildNarrative()
                {
                    return new BestNarrative {Key = Fixture.Short(), Text = Fixture.String(), Value = Fixture.String()};
                }

                var caseKey = Fixture.Integer();
                var activityKey = Fixture.String();
                var staffKey = Fixture.Integer();
                var wipToSplit = new UnpostedWip
                {
                    CaseKey = caseKey,
                    WipCode = activityKey,
                    StaffKey = staffKey,
                    ShouldUseSuppliedValues = true,
                    NarrativeKey = Fixture.Short(), /* the narrative is picked and/or NarrativeTitle and Narrative has not been changed */
                    NarrativeTitle = Fixture.String(),
                    Narrative = Fixture.String()
                };

                var debtor1 = new Debtor {CaseId = caseKey, NameId = Fixture.Integer(), NameType = "D", BillingPercentage = 60};
                var debtor2 = new Debtor {CaseId = caseKey, NameId = Fixture.Integer(), NameType = "D", BillingPercentage = 40};

                var bestNarrativeForDebtor1 = BuildNarrative();
                var bestNarrativeForDebtor2 = BuildNarrative();

                var f = new DebtorWipSplitterFixture().WithCosting();

                f.WipDebtorSelector.GetDebtorsForCaseWip(caseKey, Arg.Any<string>())
                 .Returns(new[] {debtor1, debtor2}.AsQueryable());

                f.BestNarrativeResolver.Resolve(Arg.Any<string>(), activityKey, staffKey, caseKey, debtor1.NameId)
                 .Returns(bestNarrativeForDebtor1);

                f.BestNarrativeResolver.Resolve(Arg.Any<string>(), activityKey, staffKey, caseKey, debtor2.NameId)
                 .Returns(bestNarrativeForDebtor2);

                var result = (await f.Subject.Split("en", wipToSplit)).ToArray();

                var split1 = result.Skip(1).First();
                var split2 = result.Skip(1).Last();

                Assert.Equal(bestNarrativeForDebtor1.Key, split1.NarrativeKey);
                Assert.Equal(bestNarrativeForDebtor1.Value, split1.NarrativeTitle);
                Assert.Equal(bestNarrativeForDebtor1.Text, split1.Narrative);

                Assert.Equal(bestNarrativeForDebtor2.Key, split2.NarrativeKey);
                Assert.Equal(bestNarrativeForDebtor2.Value, split2.NarrativeTitle);
                Assert.Equal(bestNarrativeForDebtor2.Text, split2.Narrative);
            }

            [Fact]
            public async Task ShouldPreserveOverridenNarratives()
            {
                BestNarrative BuildNarrative()
                {
                    return new BestNarrative {Key = Fixture.Short(), Text = Fixture.String(), Value = Fixture.String()};
                }

                var caseKey = Fixture.Integer();
                var activityKey = Fixture.String();
                var staffKey = Fixture.Integer();
                var wipToSplit = new UnpostedWip
                {
                    CaseKey = caseKey,
                    WipCode = activityKey,
                    StaffKey = staffKey,
                    ShouldUseSuppliedValues = true,
                    NarrativeKey = null, /* user typed in own Narrative Title and Narrative */
                    NarrativeTitle = Fixture.String(),
                    Narrative = Fixture.String()
                };

                var debtor1 = new Debtor {CaseId = caseKey, NameId = Fixture.Integer(), NameType = "D", BillingPercentage = 60};
                var debtor2 = new Debtor {CaseId = caseKey, NameId = Fixture.Integer(), NameType = "D", BillingPercentage = 40};

                var bestNarrativeForDebtor1 = BuildNarrative();
                var bestNarrativeForDebtor2 = BuildNarrative();

                var f = new DebtorWipSplitterFixture().WithCosting();

                f.WipDebtorSelector.GetDebtorsForCaseWip(caseKey, Arg.Any<string>())
                 .Returns(new[] {debtor1, debtor2}.AsQueryable());

                f.BestNarrativeResolver.Resolve(Arg.Any<string>(), activityKey, staffKey, caseKey, debtor1.NameId)
                 .Returns(bestNarrativeForDebtor1);

                f.BestNarrativeResolver.Resolve(Arg.Any<string>(), activityKey, staffKey, caseKey, debtor2.NameId)
                 .Returns(bestNarrativeForDebtor2);

                var result = (await f.Subject.Split("en", wipToSplit)).ToArray();

                var split1 = result.Skip(1).First();
                var split2 = result.Skip(1).Last();

                Assert.Null(split1.NarrativeKey);
                Assert.Equal(wipToSplit.NarrativeTitle, split1.NarrativeTitle);
                Assert.Equal(wipToSplit.Narrative, split1.Narrative);

                Assert.Null(split2.NarrativeKey);
                Assert.Equal(wipToSplit.NarrativeTitle, split2.NarrativeTitle);
                Assert.Equal(wipToSplit.Narrative, split2.Narrative);
            }
        }

        public class AllocateRemainder : FactBase
        {
            [Fact]
            public async Task ShouldAllocateRemainderLocalWipCostRegardlessOrBillPercentage()
            {
                var caseKey = Fixture.Integer();
                var wipCode = Fixture.String();
                var debtor1 = new Debtor {CaseId = caseKey, NameId = Fixture.Integer(), NameType = "D", BillingPercentage = (decimal) 66.6};
                var debtor2 = new Debtor {CaseId = caseKey, NameId = Fixture.Integer(), NameType = "D"};

                var wipToSplit = new UnpostedWip {CaseKey = caseKey, NameKey = debtor1.NameId, WipCode = wipCode, LocalCost = (decimal?) 100.00};

                var f = new DebtorWipSplitterFixture().WithCosting();

                f.WipDebtorSelector.GetDebtorsForCaseWip(caseKey, wipCode)
                 .Returns(new[] {debtor1, debtor2}.AsQueryable());

                var result = (await f.Subject.Split("en", wipToSplit)).ToArray();

                var splits = result.Skip(1).ToArray();

                Assert.Equal((decimal) 66.6, splits[0].LocalCost);
                Assert.Equal((decimal) 33.4, splits[1].LocalCost);
            }

            [Fact]
            public async Task ShouldAllocateForeignWipCostRegardlessOfBillPercentage()
            {
                var caseKey = Fixture.Integer();
                var wipCode = Fixture.String();
                var debtor1 = new Debtor {CaseId = caseKey, NameId = Fixture.Integer(), NameType = "D", BillingPercentage = (decimal) 66.6};
                var debtor2 = new Debtor {CaseId = caseKey, NameId = Fixture.Integer(), NameType = "D"};

                var wipToSplit = new UnpostedWip {CaseKey = caseKey, NameKey = debtor1.NameId, WipCode = wipCode, ForeignCost = (decimal?) 100.00, ForeignCurrency = "GBP"};

                var f = new DebtorWipSplitterFixture().WithCostingForForeignDebtors("GBP", "GBP");

                f.WipDebtorSelector.GetDebtorsForCaseWip(caseKey, wipCode)
                 .Returns(new[] {debtor1, debtor2}.AsQueryable());

                var result = (await f.Subject.Split("en", wipToSplit)).ToArray();

                var splits = result.Skip(1).ToArray();

                Assert.Equal((decimal) 66.6, splits[0].ForeignCost);
                Assert.Equal((decimal) 33.4, splits[1].ForeignCost);
            }

            [Fact]
            public async Task ShouldAllocateRemainderBothLocalAndForeignWipCostRegardlessOfBillPercentage()
            {
                var caseKey = Fixture.Integer();
                var wipCode = Fixture.String();
                var debtor1 = new Debtor {CaseId = caseKey, NameId = Fixture.Integer(), NameType = "D", BillingPercentage = (decimal) 66.6}; /* Foreign */
                var debtor2 = new Debtor {CaseId = caseKey, NameId = Fixture.Integer(), NameType = "D", BillingPercentage = 10}; /* Local */
                var debtor3 = new Debtor {CaseId = caseKey, NameId = Fixture.Integer(), NameType = "D"}; /* Local */

                var wipToSplit = new UnpostedWip
                {
                    CaseKey = caseKey,
                    NameKey = debtor1.NameId,
                    WipCode = wipCode,
                    ForeignCost = 100,
                    LocalCost = 200,
                    ShouldUseSuppliedValues = true
                };

                var f = new DebtorWipSplitterFixture().WithCostingForForeignDebtors("GBP", string.Empty, string.Empty);

                f.WipDebtorSelector.GetDebtorsForCaseWip(caseKey, wipCode)
                 .Returns(new[] {debtor1, debtor2, debtor3}.AsQueryable());

                var result = (await f.Subject.Split("en", wipToSplit)).ToArray();

                var splits = result.Skip(1).ToArray();

                /*
                 * debtor1 is foreign, has 66.6% bill percentage.   ForeignCost 100 * 66.6% = 66.6;         LocalCost 200 * 66.6 = 133.2. 
                 * debtor2 is local, has 10% bill percentage.       ForeignCost 100 * 10.0% = 10.0;         LocalCost 200 * 10.0 =  20.0.
                 * debtor3 takes remainder of local costs.          ForeignCost 100 - (66.6 + 10.0) = 23.4; LocalCost 200 - (133.2 + 20) = 46.8
                 */

                Assert.Equal((decimal) 66.6, splits[0].ForeignCost);
                Assert.Equal((decimal) 20.0, splits[1].LocalCost);
                Assert.Equal((decimal) 46.8, splits[2].LocalCost);
            }
        }
    }
}