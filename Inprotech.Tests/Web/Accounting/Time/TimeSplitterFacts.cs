using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Tests.Extensions;
using Inprotech.Web.Accounting.Time;
using Inprotech.Web.Accounting.Work;
using InprotechKaizen.Model.Components.Accounting.Billing;
using InprotechKaizen.Model.Components.Accounting.Time;
using InprotechKaizen.Model.Components.Accounting.Wip;
using NSubstitute;
using NSubstitute.ReturnsExtensions;
using Xunit;

namespace Inprotech.Tests.Web.Accounting.Time
{
    public class TimeSplitterFacts
    {
        public class TimeSplitterFixture : IFixture<TimeSplitter>
        {
            public TimeSplitterFixture()
            {
                WipDebtorSelector = Substitute.For<IWipDebtorSelector>();
                WipCosting = Substitute.For<IWipCosting>();
                BestNarrativeResolver = Substitute.For<IBestTranslatedNarrativeResolver>();
                Subject = new TimeSplitter(WipDebtorSelector, WipCosting, BestNarrativeResolver);
            }

            public IWipDebtorSelector WipDebtorSelector { get; set; }

            public IWipCosting WipCosting { get; set; }

            public IBestTranslatedNarrativeResolver BestNarrativeResolver { get; set; }

            public TimeSplitter Subject { get; }
        }

        public class SplitTime : FactBase
        {
            [Fact]
            public async Task GeneratesTimeValuesForEachDebtor()
            {
                var debtorNameType = Fixture.RandomString(2);
                var firstDebtor = new Debtor {NameId = 888, NameType = debtorNameType};
                var lastDebtor = new Debtor {NameId = 999, NameType = debtorNameType};
                var time = new RecordableTime {CaseKey = 1, ActivityKey = Fixture.RandomString(6)};

                var f = new TimeSplitterFixture();
                f.WipDebtorSelector.GetDebtorsForCaseWip(Arg.Any<int>(), Arg.Any<string>())
                 .Returns(new[] {firstDebtor, lastDebtor}.AsQueryable());

                f.WipCosting.For(Arg.Any<RecordableTime>()).Returns(new WipCost
                {
                    LocalValue = Fixture.Decimal()
                });
                f.BestNarrativeResolver.Resolve(Arg.Any<string>(), Arg.Any<string>(), Arg.Any<int>(), Arg.Any<int>(), Arg.Any<int>()).ReturnsNull();

                await f.Subject.SplitTime("en", time, 1);

                Assert.Equal(time.IsSplitDebtorWip, true);
                Assert.Equal(time.DebtorSplits.Count, 2);
                Assert.Equal(time.DebtorSplits.First().DebtorNameNo, firstDebtor.NameId);
                Assert.Equal(time.DebtorSplits.Last().DebtorNameNo, lastDebtor.NameId);

                f.WipCosting.Received(2).For(Arg.Any<RecordableTime>())
                 .IgnoreAwaitForNSubstituteAssertion();
            }

            [Theory]
            [InlineData(false, false)]
            [InlineData(true, false)]
            [InlineData(false, true)]
            public async Task AppliesDefaultNarrativeToEachNewSplitIfNoSplitsWerePassed(bool withNewNarrativeNo, bool withNewNarrativeText)
            {
                var firstDebtor = new Debtor {NameId = 888};
                var lastDebtor = new Debtor {NameId = 999};
                var newNarrativeNo = withNewNarrativeNo ? 4 : 3;
                var newNarrativeText = withNewNarrativeText ? Fixture.RandomString(20) : null;

                var time = new RecordableTime {CaseKey = 1, ActivityKey = Fixture.RandomString(6), NarrativeNo = (short) newNarrativeNo, NarrativeText = newNarrativeText};

                var f = new TimeSplitterFixture();

                f.WipDebtorSelector.GetDebtorsForCaseWip(Arg.Any<int>(), Arg.Any<string>())
                 .Returns(new[] {firstDebtor, lastDebtor}.AsQueryable());
                f.WipCosting.For(Arg.Any<RecordableTime>()).Returns(new WipCost
                {
                    LocalValue = Fixture.Decimal()
                });
                f.BestNarrativeResolver.Resolve(Arg.Any<string>(), Arg.Any<string>(), Arg.Any<int>(), Arg.Any<int>()).Returns(new BestNarrative {Key = 3, Value = "default", Text = "defaulted activity narrative"});
                f.BestNarrativeResolver.Resolve(Arg.Any<string>(), Arg.Any<string>(), Arg.Any<int>(), Arg.Any<int>(), firstDebtor.NameId).Returns(new BestNarrative {Key = 1, Value = "text1", Text = "text1"});
                f.BestNarrativeResolver.Resolve(Arg.Any<string>(), Arg.Any<string>(), Arg.Any<int>(), Arg.Any<int>(), lastDebtor.NameId).Returns(new BestNarrative {Key = 2, Value = "text2", Text = "text2"});

                await f.Subject.SplitTime("en", time, 1);

                var split1 = time.DebtorSplits.Single(d => d.DebtorNameNo == firstDebtor.NameId);
                Assert.Equal((short) (withNewNarrativeNo ? newNarrativeNo : 1), split1.NarrativeNo);
                Assert.Equal(withNewNarrativeNo ? newNarrativeText : "text1", split1.Narrative);

                var split2 = time.DebtorSplits.Single(d => d.DebtorNameNo == lastDebtor.NameId);
                Assert.Equal((short) (withNewNarrativeNo ? newNarrativeNo : 2), split2.NarrativeNo);
                Assert.Equal(withNewNarrativeNo ? newNarrativeText : "text2", split2.Narrative);
            }

            [Fact]
            public async Task KeepsOverridenNarrativeAgainstEachSplitIfSplitsWerePassed()
            {
                var firstDebtor = new Debtor {NameId = 888};
                var lastDebtor = new Debtor {NameId = 999};
                var costedWip = new WipCost {TimeUnits = 10};

                var f = new TimeSplitterFixture();
                f.WipDebtorSelector.GetDebtorsForCaseWip(Arg.Any<int>(), Arg.Any<string>())
                 .Returns(new[] {firstDebtor, lastDebtor}.AsQueryable());

                f.WipCosting.For(Arg.Any<RecordableTime>()).Returns(costedWip);

                var splitWip = new List<DebtorSplit>
                {
                    new DebtorSplit
                    {
                        DebtorNameNo = firstDebtor.NameId,
                        NarrativeNo = 3,
                        Narrative = "ABC"
                    },
                    new DebtorSplit
                    {
                        DebtorNameNo = lastDebtor.NameId,
                        NarrativeNo = 4,
                        Narrative = "DEF"
                    }
                };
                var time = new RecordableTime {CaseKey = 1, ActivityKey = "WIPABC", DebtorSplits = splitWip};

                await f.Subject.SplitTime("en", time, 1);

                // first narrative applied
                Assert.Equal((short) 3, time.DebtorSplits.Single(d => d.DebtorNameNo == firstDebtor.NameId).NarrativeNo);
                Assert.Equal("ABC", time.DebtorSplits.Single(d => d.DebtorNameNo == firstDebtor.NameId).Narrative);
                // second narrative applied
                Assert.Equal((short) 4, time.DebtorSplits.Single(d => d.DebtorNameNo == lastDebtor.NameId).NarrativeNo);
                Assert.Equal("DEF", time.DebtorSplits.Single(d => d.DebtorNameNo == lastDebtor.NameId).Narrative);
            }

            [Fact]
            public async Task ReturnsTheTotalUnitsCalculated()
            {
                var firstDebtor = new Debtor {NameId = 888};
                var lastDebtor = new Debtor {NameId = 999};
                var costedWip = new WipCost {TimeUnits = 10};
                var time = new RecordableTime {CaseKey = 1};

                var f = new TimeSplitterFixture();
                f.WipDebtorSelector.GetDebtorsForCaseWip(Arg.Any<int>(), Arg.Any<string>())
                 .Returns(new[] {firstDebtor, lastDebtor}.AsQueryable());
                f.WipCosting.For(Arg.Any<RecordableTime>()).Returns(costedWip);

                var result = await f.Subject.SplitTime("en", time, 1);
                Assert.Equal(costedWip.TimeUnits, result.TotalUnits);
            }

            [Fact]
            public async Task ReturnsTheCostCalculationsPerDebtor()
            {
                var firstDebtor = new Debtor {NameId = 888};
                var lastDebtor = new Debtor {NameId = 999};
                var costedWip1 = new WipCost {TimeUnits = 10, CostCalculation1 = Fixture.Decimal(), CostCalculation2 = Fixture.Decimal()};
                var costedWip2 = new WipCost {TimeUnits = 10, CostCalculation1 = Fixture.Decimal(), CostCalculation2 = Fixture.Decimal()};
                var time = new RecordableTime {CaseKey = 1};

                var f = new TimeSplitterFixture();
                f.WipDebtorSelector.GetDebtorsForCaseWip(Arg.Any<int>(), Arg.Any<string>())
                 .Returns(new[] {firstDebtor, lastDebtor}.AsQueryable());
                f.WipCosting.For(Arg.Is<RecordableTime>(x => x.NameKey == 888)).Returns(costedWip1);
                f.WipCosting.For(Arg.Is<RecordableTime>(x => x.NameKey == 999)).Returns(costedWip2);

                var result = await f.Subject.SplitTime("en", time, 1);
                Assert.Equal(costedWip1.CostCalculation1, result.DebtorSplits[0].CostCalculation1);
                Assert.Equal(costedWip1.CostCalculation2, result.DebtorSplits[0].CostCalculation2);
                Assert.Equal(costedWip2.CostCalculation1, result.DebtorSplits[1].CostCalculation1);
                Assert.Equal(costedWip2.CostCalculation2, result.DebtorSplits[1].CostCalculation2);
            }

            [Fact]
            public async Task RefreshDebtorSplitDiaryWhenTimeIsSplitForSingleDebtor()
            {
                var firstDebtor = new Debtor {NameId = 888};
                var lastDebtor = new Debtor {NameId = 999};
                
                var debtorSplitDiary1 = new DebtorSplit
                {
                    LocalValue = 1,
                    LocalDiscount = 2,
                    DebtorNameNo = firstDebtor.NameId
                };

                var debtorSplitDiary2 = new DebtorSplit
                {
                    LocalValue = 7,
                    LocalDiscount = 3,
                    DebtorNameNo = lastDebtor.NameId
                };

                var costedWip1 = new WipCost {TimeUnits = 10, CostCalculation1 = Fixture.Decimal(), CostCalculation2 = Fixture.Decimal()};
                var costedWip2 = new WipCost {TimeUnits = 10, CostCalculation1 = Fixture.Decimal(), CostCalculation2 = Fixture.Decimal()};
                var f = new TimeSplitterFixture();
                f.WipCosting.For(Arg.Is<RecordableTime>(x => x.NameKey == 888)).Returns(costedWip1);
                f.WipCosting.For(Arg.Is<RecordableTime>(x => x.NameKey == 999)).Returns(costedWip2);
                f.WipDebtorSelector.GetDebtorsForCaseWip(Arg.Any<int>(), Arg.Any<string>())
                 .Returns(new[] {firstDebtor, lastDebtor}.AsQueryable());

                var time = new RecordableTime
                {
                    CaseKey = 1,
                    StaffId = 1,
                    DebtorSplits =
                        new List<DebtorSplit>
                        {
                            debtorSplitDiary1,
                            debtorSplitDiary2
                        }
                };

                var result = await f.Subject.SplitTime("en", time, 1);
                Assert.Equal(result.DebtorSplits.Count, 2);

                f.WipDebtorSelector.GetDebtorsForCaseWip(Arg.Any<int>(), Arg.Any<string>())
                 .Returns(new[] {firstDebtor}.AsQueryable());

                time.CaseKey = 2;
                result = await f.Subject.SplitTime("en", time, 1);
                Assert.Empty(result.DebtorSplits);
            }
        }

        public class AggregateSplitIntoTime : FactBase
        {
            [Fact]
            public void AggregatesSplitLocalValuesAndCosts()
            {
                var debtorSplitDiary1 = new DebtorSplit
                {
                    LocalValue = 1,
                    LocalDiscount = 2,
                    CostCalculation1 = Fixture.Decimal(),
                    CostCalculation2 = Fixture.Decimal()
                };

                var debtorSplitDiary2 = new DebtorSplit
                {
                    LocalValue = 1,
                    LocalDiscount = 2,
                    CostCalculation1 = Fixture.Decimal(),
                    CostCalculation2 = Fixture.Decimal()
                };

                var f = new TimeSplitterFixture();

                var time = new RecordableTime
                {
                    NameKey = 2,
                    DebtorSplits =
                        new List<DebtorSplit>
                        {
                            debtorSplitDiary1,
                            debtorSplitDiary2
                        }
                };

                var result = f.Subject.AggregateSplitIntoTime(time);

                Assert.Equal(debtorSplitDiary1.LocalValue + debtorSplitDiary2.LocalValue, result.LocalValue);
                Assert.Equal(debtorSplitDiary1.LocalDiscount + debtorSplitDiary2.LocalDiscount, result.LocalDiscount);
                Assert.Equal(debtorSplitDiary1.CostCalculation1 + debtorSplitDiary2.CostCalculation1, result.CostCalculation1);
                Assert.Equal(debtorSplitDiary1.CostCalculation2 + debtorSplitDiary2.CostCalculation2, result.CostCalculation2);
            }

            [Fact]
            public void AggregatesSplitForeignValuesWhenCurrencyIsTheSame()
            {
                var debtorSplitDiary1 = new DebtorSplit
                {
                    DebtorNameNo = 1,
                    ForeignCurrency = "abc",
                    ExchRate = (decimal) 1.111,
                    ForeignValue = 1,
                    ForeignDiscount = 2,
                    LocalValue = 3,
                    CostCalculation1 = Fixture.Decimal(),
                    CostCalculation2 = Fixture.Decimal()
                };

                var debtorSplitDiary2 = new DebtorSplit
                {
                    DebtorNameNo = 2,
                    ForeignCurrency = "abc",
                    ExchRate = (decimal) 1.122,
                    ForeignValue = 1,
                    ForeignDiscount = 2,
                    LocalValue = 3,
                    CostCalculation1 = Fixture.Decimal(),
                    CostCalculation2 = Fixture.Decimal()
                };

                var time = new RecordableTime
                {
                    DebtorSplits = new List<DebtorSplit>
                        {debtorSplitDiary1, debtorSplitDiary2}
                };

                var f = new TimeSplitterFixture();

                var result = f.Subject.AggregateSplitIntoTime(time);

                Assert.Equal(debtorSplitDiary1.ForeignCurrency, result.ForeignCurrency);
                Assert.Equal(debtorSplitDiary1.ForeignValue + debtorSplitDiary2.ForeignValue, result.ForeignValue);
                Assert.Equal(debtorSplitDiary1.ForeignDiscount + debtorSplitDiary2.ForeignDiscount, result.ForeignDiscount);
                Assert.Equal(result.ForeignValue / result.LocalValue, result.ExchangeRate);
                Assert.Equal(debtorSplitDiary1.CostCalculation1 + debtorSplitDiary2.CostCalculation1, result.CostCalculation1);
                Assert.Equal(debtorSplitDiary1.CostCalculation2 + debtorSplitDiary2.CostCalculation2, result.CostCalculation2);
            }

            [Fact]
            public void DoesNotAggregateSplitForeignValuesWhenCurrencyIsDifferent()
            {
                var debtorSplitDiary1 = new DebtorSplit
                {
                    DebtorNameNo = 1,
                    ForeignCurrency = "abcd",
                    ExchRate = (decimal) 1.111,
                    ForeignValue = 1,
                    ForeignDiscount = 2
                };

                var debtorSplitDiary2 = new DebtorSplit
                {
                    DebtorNameNo = 2,
                    ForeignCurrency = "abc",
                    ExchRate = (decimal) 1.111,
                    ForeignValue = 1,
                    ForeignDiscount = 2
                };

                var time = new RecordableTime
                {
                    DebtorSplits = new List<DebtorSplit>
                        {debtorSplitDiary1, debtorSplitDiary2}
                };

                var f = new TimeSplitterFixture();

                var result = f.Subject.AggregateSplitIntoTime(time);

                Assert.Equal(null, result.ForeignCurrency);
                Assert.Equal(null, result.ForeignValue);
                Assert.Equal(null, result.ForeignDiscount);
                Assert.Equal(null, result.ExchangeRate);
            }

            [Fact]
            public void ReturnsChargeRateWhenTheyAreTheSame()
            {
                var debtorSplitDiary1 = new DebtorSplit
                {
                    DebtorNameNo = 1,
                    ChargeOutRate = 2
                };

                var debtorSplitDiary2 = new DebtorSplit
                {
                    DebtorNameNo = 2,
                    ChargeOutRate = 2
                };

                var time = new RecordableTime
                {
                    DebtorSplits = new List<DebtorSplit>
                        {debtorSplitDiary1, debtorSplitDiary2}
                };

                var f = new TimeSplitterFixture();
                
                var result = f.Subject.AggregateSplitIntoTime(time);
                
                Assert.Equal(2, result.ChargeOutRate);
            }

            [Fact]
            public void DoesNotReturnChargeRatesWhenTheyAreDifferent()
            {
                var debtorSplitDiary1 = new DebtorSplit
                {
                    DebtorNameNo = 1,
                    ChargeOutRate = 2
                };

                var debtorSplitDiary2 = new DebtorSplit
                {
                    DebtorNameNo = 2,
                    ChargeOutRate = 3
                };

                var time = new RecordableTime
                {
                    DebtorSplits = new List<DebtorSplit>
                        {debtorSplitDiary1, debtorSplitDiary2}
                };

                var f = new TimeSplitterFixture();
                var result = f.Subject.AggregateSplitIntoTime(time);
                Assert.Equal(null, result.ChargeOutRate);
            }

            [Fact]
            public void ReturnsMarginNoWhenTheyAreTheSame()
            {
                var marginNo = Fixture.Integer();
                var debtorSplitDiary1 = new DebtorSplit
                {
                    DebtorNameNo = 1,
                    ChargeOutRate = Fixture.Decimal(),
                    MarginNo = marginNo
                };

                var debtorSplitDiary2 = new DebtorSplit
                {
                    DebtorNameNo = 2,
                    ChargeOutRate = debtorSplitDiary1.ChargeOutRate - 1,
                    MarginNo = marginNo
                };

                var time = new RecordableTime
                {
                    DebtorSplits = new List<DebtorSplit>
                        {debtorSplitDiary1, debtorSplitDiary2}
                };

                var f = new TimeSplitterFixture();
                var result = f.Subject.AggregateSplitIntoTime(time);

                Assert.Equal(marginNo, result.MarginNo);
            }

            [Fact]
            public void ReturnNullMarginNoIfTheyAreDifferent()
            {
                var chargeRate = Fixture.Decimal();
                var marginNo = Fixture.Integer();
                var debtorSplitDiary1 = new DebtorSplit
                {
                    DebtorNameNo = 1,
                    ChargeOutRate = chargeRate,
                    MarginNo = marginNo
                };

                var debtorSplitDiary2 = new DebtorSplit
                {
                    DebtorNameNo = 2,
                    ChargeOutRate = chargeRate,
                    MarginNo = marginNo + 1
                };

                var time = new RecordableTime
                {
                    DebtorSplits = new List<DebtorSplit>
                        {debtorSplitDiary1, debtorSplitDiary2}
                };

                var f = new TimeSplitterFixture();
                var result = f.Subject.AggregateSplitIntoTime(time);

                Assert.Equal(null, result.MarginNo);
            }
        }
    }
}