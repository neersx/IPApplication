using System;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Infrastructure.Notifications.Validation;
using Inprotech.Tests.Extensions;
using Inprotech.Tests.Fakes;
using Inprotech.Web.Accounting.Work;
using InprotechKaizen.Model.Accounting;
using InprotechKaizen.Model.Components.Accounting.Wip;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Accounting.Work
{
    public class WipDisbursementsFacts
    {
        public class WipDisbursementsFixture : IFixture<WipDisbursements>
        {
            public WipDisbursementsFixture(InMemoryDbContext db)
            {
                var preferredCultureResolver = Substitute.For<IPreferredCultureResolver>();

                Subject = new WipDisbursements(db,
                                               preferredCultureResolver,
                                               WipDefaulting, WipCosting, WipDebtorSelector,
                                               ValidatePostDates,
                                               ProtocolDisbursements,
                                               DebtorWipSplitter,
                                               PostWipCommand,
                                               ApplicationAlerts,
                                               Fixture.Today);
            }

            public IWipDefaulting WipDefaulting { get; } = Substitute.For<IWipDefaulting>();
            public IWipCosting WipCosting { get; } = Substitute.For<IWipCosting>();
            public IWipDebtorSelector WipDebtorSelector { get; } = Substitute.For<IWipDebtorSelector>();
            public IValidatePostDates ValidatePostDates { get; } = Substitute.For<IValidatePostDates>();
            public IProtocolDisbursements ProtocolDisbursements { get; } = Substitute.For<IProtocolDisbursements>();
            public IDebtorWipSplitter DebtorWipSplitter { get; } = Substitute.For<IDebtorWipSplitter>();
            public IPostWipCommand PostWipCommand { get; } = Substitute.For<IPostWipCommand>();
            public IApplicationAlerts ApplicationAlerts { get; } = Substitute.For<IApplicationAlerts>();
            public WipDisbursements Subject { get; }

            public WipDisbursementsFixture WithValidPostDate()
            {
                ValidatePostDates.For(Arg.Any<DateTime>(), Arg.Any<SystemIdentifier>())
                                 .Returns((true, false, string.Empty));
                return this;
            }

            public WipDisbursementsFixture WithInvalidPostDate(string code, bool isWarning)
            {
                ValidatePostDates.For(Arg.Any<DateTime>(), Arg.Any<SystemIdentifier>())
                                 .Returns((false, isWarning, code));
                return this;
            }
        }

        public class GetWipDefaultsMethod : FactBase
        {
            [Fact]
            public async Task ShouldReturnDisbursementWipDefaultsSuitableForTheCase()
            {
                var caseKey = Fixture.Integer();

                var f = new WipDisbursementsFixture(Db);

                var _ = await f.Subject.GetWipDefaults(caseKey);

                f.WipDefaulting.Received(1)
                 .ForCase(Arg.Is<WipTemplateFilterCriteria>(
                                                            x => x.ContextCriteria.CaseKey == caseKey
                                                                 && x.UsedByApplication.IsWip == true
                                                                 && x.WipCategory.IsDisbursements == true), caseKey)
                 .IgnoreAwaitForNSubstituteAssertion();
            }
        }

        public class GetSplitWipByDebtorMethod : FactBase
        {
            [Fact]
            public async Task ShouldReturnSplitWipByDebtor()
            {
                var input = new WipCost
                {
                    WipCode = Fixture.String(),
                    CaseKey = Fixture.Integer(),
                    NameKey = Fixture.Integer(),
                    LocalValueBeforeMargin = Fixture.Decimal(),
                    ForeignValueBeforeMargin = Fixture.Decimal(),
                    CurrencyCode = Fixture.String(),
                    StaffKey = Fixture.Integer(),
                    TransactionDate = Fixture.Today()
                };

                var aggregateWip = new UnpostedWip();
                var split1 = new UnpostedWip();
                var split2 = new UnpostedWip();

                var f = new WipDisbursementsFixture(Db);

                f.DebtorWipSplitter.Split(Arg.Any<string>(),
                                          Arg.Any<UnpostedWip>())
                 .Returns(x =>
                 {
                     /*
                        this component will return 1 aggregated wip for UI,
                        then the splits per number of debtors in the case. 
                        For simplicity in testing, just returning 3 copies of the input augmented with values
                     */

                     var wip = (UnpostedWip) x[1];

                     aggregateWip = CreateFakeSplitFromInput((UnpostedWip) wip.Clone());
                     split1 = CreateFakeSplitFromInput((UnpostedWip) wip.Clone());
                     split2 = CreateFakeSplitFromInput((UnpostedWip) wip.Clone());

                     return new[] {aggregateWip, split1, split2};
                 });

                var r = (await f.Subject.GetSplitWipByDebtor(input)).ToArray();

                AssertEqual(input, aggregateWip, r[0]);
                AssertEqual(input, split1, r[1]);
                AssertEqual(input, split2, r[2]);

                void AssertEqual(WipCost cost, UnpostedWip aggregateOrSplit, DisbursementWip result)
                {
                    // assert to ensure all properties are assigned as required.
                    Assert.Equal(cost.CaseKey, result.CaseKey);
                    Assert.Equal(cost.NameKey, result.NameKey);
                    Assert.Equal(cost.TransactionDate, result.TransDate);
                    Assert.Equal(cost.WipCode, result.WIPCode);
                    Assert.Equal(cost.StaffKey, result.StaffKey);
                    Assert.Equal(cost.CaseKey, result.CaseKey);
                    Assert.Equal(aggregateOrSplit.LocalCost, result.Amount);
                    Assert.Equal(aggregateOrSplit.ForeignCost, result.ForeignAmount);
                    Assert.Equal(aggregateOrSplit.ForeignMargin, result.ForeignMargin);
                    Assert.Equal(aggregateOrSplit.DiscountValue, result.Discount);
                    Assert.Equal(aggregateOrSplit.DiscountForMargin, result.LocalDiscountForMargin);
                    Assert.Equal(aggregateOrSplit.ForeignDiscount, result.ForeignDiscount);
                    Assert.Equal(aggregateOrSplit.ForeignDiscountForMargin, result.ForeignDiscountForMargin);
                    Assert.Equal(aggregateOrSplit.Narrative, result.NarrativeText);
                    Assert.Equal(aggregateOrSplit.NarrativeKey, result.NarrativeKey);
                    Assert.Equal(aggregateOrSplit.IsSplitDebtorWip, result.IsSplitDebtorWip);
                    Assert.Equal(aggregateOrSplit.CostCalculation1, result.LocalCost1);
                    Assert.Equal(aggregateOrSplit.CostCalculation2, result.LocalCost2);
                }
            }

            UnpostedWip CreateFakeSplitFromInput(UnpostedWip input)
            {
                var r = (UnpostedWip) input.Clone();

                r.MarginValue = Fixture.Decimal();
                r.ForeignMargin = Fixture.Decimal();
                r.DiscountValue = Fixture.Decimal();
                r.Narrative = Fixture.String();
                r.NarrativeTitle = Fixture.String();
                r.NarrativeKey = Fixture.Short();
                r.DiscountForMargin = Fixture.Decimal();
                r.ForeignDiscountForMargin = Fixture.Decimal();
                r.EnteredQuantity = Fixture.Short();
                r.IsSplitDebtorWip = true;
                r.DebtorSplitPercentage = Fixture.Decimal();
                r.CostCalculation1 = Fixture.Decimal();
                r.CostCalculation2 = Fixture.Decimal();
                r.LocalCost = Fixture.Decimal();
                r.ForeignCost = Fixture.Decimal();

                return r;
            }
        }

        public class GetCaseActivityMultiDebtorStatusMethod : FactBase
        {
            [Fact]
            public async Task ShouldReturnCaseActivityMultiDebtorStatusAccordingly()
            {
                var caseKey = Fixture.Integer();
                var activityKey = Fixture.String();
                var isMultiDebtorWip = Fixture.Boolean();
                var isRenewalWip = Fixture.Boolean();

                var f = new WipDisbursementsFixture(Db);

                f.WipDebtorSelector.CaseActivityMultiDebtorStatus(caseKey, activityKey)
                 .Returns((IsMultiDebtorWip: isMultiDebtorWip, IsRenewalWip: isRenewalWip));

                var r = await f.Subject.GetCaseActivityMultiDebtorStatus(caseKey, activityKey);

                Assert.Equal(isMultiDebtorWip, r.IsMultiDebtorWip);
                Assert.Equal(isRenewalWip, r.IsRenewalWip);
            }
        }

        public class ValidateItemDateMethod : FactBase
        {
            [Fact]
            public async Task ShouldReturnValidIfIndicated()
            {
                var fixture = new WipDisbursementsFixture(Db)
                    .WithValidPostDate();

                var r = await fixture.Subject.ValidateItemDate(Fixture.Date());

                Assert.Empty(r.ValidationErrorList);
            }

            [Theory]
            [InlineData("AC124", "The item date is not within the period it will be posted to.  Please check that the transaction is dated correctly.")]
            public async Task ShouldReturnWarningWithMessageIfIndicated(string warningCode, string warningMessage)
            {
                var fixture = new WipDisbursementsFixture(Db)
                    .WithInvalidPostDate(warningCode, true);

                var r = await fixture.Subject.ValidateItemDate(Fixture.Date());

                Assert.Equal(warningCode, r.ValidationErrorList.Single().WarningCode);
                Assert.Equal(warningMessage, r.ValidationErrorList.Single().WarningDescription);
            }

            [Theory]
            [InlineData("AC126", "An accounting period could not be determined for the given date. Please check the period definitions and try again.")]
            [InlineData("AC208", "The item date cannot be in the future. It must be within the current accounting period or up to and including the current date.")]
            public async Task ShouldReturnErrorWithMessageIfIndicated(string errorCode, string errorMessage)
            {
                var fixture = new WipDisbursementsFixture(Db)
                    .WithInvalidPostDate(errorCode, false);

                var r = await fixture.Subject.ValidateItemDate(Fixture.Date());

                Assert.Equal(errorCode, r.ValidationErrorList.Single().ErrorCode);
                Assert.Equal(errorMessage, r.ValidationErrorList.Single().ErrorDescription);
            }
        }

        public class RetrieveMethod : FactBase
        {
            [Fact]
            public async Task ShouldReturnDisbursementWhenRequested()
            {
                var disbursement = new Disbursement();

                var userIdentityId = Fixture.Integer();
                var culture = Fixture.String();
                var transKey = Fixture.Integer();
                var protocolKey = Fixture.String();
                var protocolDateString = Fixture.String();

                var f = new WipDisbursementsFixture(Db);

                f.ProtocolDisbursements.Retrieve(userIdentityId, culture, transKey, protocolKey, protocolDateString)
                 .Returns(disbursement);

                var r = await f.Subject.Retrieve(userIdentityId, culture, transKey, protocolKey, protocolDateString);

                Assert.Equal(disbursement, r);
            }
        }

        public class SaveMethod : FactBase
        {
            [Fact]
            public async Task ShouldConsolidateThenPostAllWip()
            {
                var userIdentityId = Fixture.Integer();
                var culture = Fixture.String();
                var input = new Disbursement
                {
                    DissectedDisbursements =
                    {
                        new DisbursementWip(), /* 1 */
                        new DisbursementWip()
                    }
                };

                input.DissectedDisbursements.Last().SplitWipItems.AddRange(new[]
                {
                    new DisbursementWip(), /* 2 */
                    new DisbursementWip() /* 3 */
                });

                var f = new WipDisbursementsFixture(Db)
                    .WithValidPostDate();

                var r = await f.Subject.Save(userIdentityId, culture, input);

                Assert.True(r);

                f.PostWipCommand
                 .Received(1)
                 .Post(userIdentityId, culture, Arg.Is<PostWipParameters[]>(x =>
                                                                                x.Length == 3 &&
                                                                                x.All(_ => _.TransactionType == (int) TransactionType.Disbursement)))
                 .IgnoreAwaitForNSubstituteAssertion();
            }

            [Fact]
            public async Task ShouldOnlyPostToGeneralLedgerIfItIsTheLastSplitWipItem()
            {
                var userIdentityId = Fixture.Integer();
                var culture = Fixture.String();
                var input = new Disbursement
                {
                    DissectedDisbursements = {new DisbursementWip()}
                };

                input.DissectedDisbursements.Single().SplitWipItems.AddRange(new[]
                {
                    new DisbursementWip(), /* suppress */
                    new DisbursementWip() /* post-to-GL */
                });

                var f = new WipDisbursementsFixture(Db)
                    .WithValidPostDate();

                var r = await f.Subject.Save(userIdentityId, culture, input);

                Assert.True(r);

                f.PostWipCommand
                 .Received(1)
                 .Post(userIdentityId, culture, Arg.Is<PostWipParameters[]>(x =>
                                                                                x[0].ShouldSuppressPostToGeneralLedger &&
                                                                                x[1].ShouldSuppressPostToGeneralLedger == false))
                 .IgnoreAwaitForNSubstituteAssertion();
            }

            [Fact]
            public async Task ShouldOnlyPostToGeneralLedgerIfItIsTheLastDisbursementDissectionItem()
            {
                var userIdentityId = Fixture.Integer();
                var culture = Fixture.String();
                var input = new Disbursement
                {
                    DissectedDisbursements =
                    {
                        new DisbursementWip(), /* suppress */
                        new DisbursementWip() /* post-to-GL */
                    }
                };

                var f = new WipDisbursementsFixture(Db)
                    .WithValidPostDate();

                var r = await f.Subject.Save(userIdentityId, culture, input);

                Assert.True(r);

                f.PostWipCommand
                 .Received(1)
                 .Post(userIdentityId, culture, Arg.Is<PostWipParameters[]>(x =>
                                                                                x[0].ShouldSuppressPostToGeneralLedger &&
                                                                                x[1].ShouldSuppressPostToGeneralLedger == false))
                 .IgnoreAwaitForNSubstituteAssertion();
            }

            [Fact]
            public async Task ShouldReverseSignForCreditWip()
            {
                var userIdentityId = Fixture.Integer();
                var culture = Fixture.String();
                var input = new Disbursement
                {
                    CreditWIP = true,
                    Currency = "GBP",
                    DissectedDisbursements =
                    {
                        new DisbursementWip
                        {
                            Amount = 100,
                            ForeignAmount = 200,
                            Discount = 10,
                            ForeignDiscount = 20,
                            LocalCost1 = 100,
                            LocalCost2 = 100,
                            Margin = 1,
                            ForeignMargin = 2,
                            LocalDiscountForMargin = 10,
                            ForeignDiscountForMargin = 20
                        }
                    }
                };

                var f = new WipDisbursementsFixture(Db).WithValidPostDate();

                var r = await f.Subject.Save(userIdentityId, culture, input);

                Assert.True(r);

                f.PostWipCommand
                 .Received(1)
                 .Post(userIdentityId, culture, Arg.Is<PostWipParameters[]>(x =>
                                                                                x[0].IsCreditWip &&
                                                                                x[0].LocalValue == -101 && /* local value + margin */
                                                                                x[0].ForeignValue == -202 && /* foreign value + foreign margin) */
                                                                                x[0].DiscountValue == -10 &&
                                                                                x[0].ForeignDiscount == -20 &&
                                                                                x[0].LocalCost == -100 &&
                                                                                x[0].ForeignCost == -200 &&
                                                                                x[0].CostCalculation1 == -100 &&
                                                                                x[0].CostCalculation2 == -100 &&
                                                                                x[0].MarginValue == -1 &&
                                                                                x[0].ForeignMargin == -2 &&
                                                                                x[0].DiscountForMargin == -10 &&
                                                                                x[0].ForeignDiscountForMargin == -20
                                                                           ))
                 .IgnoreAwaitForNSubstituteAssertion();
            }

            [Fact]
            public async Task ShouldPostWipWithCorrectParameters()
            {
                var userIdentityId = Fixture.Integer();
                var culture = Fixture.String();

                var nameKey = Fixture.Integer();
                var caseKey = Fixture.Integer();
                var staffKey = Fixture.Integer();
                var wipCode = Fixture.String();
                var quantity = Fixture.Integer();
                var debtorSplitPercentage = Fixture.Decimal();

                var input = new Disbursement
                {
                    Currency = "GBP",
                    EntityKey = Fixture.Integer(),
                    TransDate = Fixture.Today(),
                    InvoiceNo = Fixture.String(),
                    VerificationNo = Fixture.String(),
                    AssociateKey = Fixture.Integer(),
                    ProtocolDate = Fixture.String(),
                    ProtocolKey = Fixture.String(),
                    DissectedDisbursements =
                    {
                        new DisbursementWip
                        {
                            Amount = 100,
                            ForeignAmount = 200,
                            Discount = 10,
                            ForeignDiscount = 20,
                            LocalCost1 = 100,
                            LocalCost2 = 100,
                            Margin = 1,
                            ForeignMargin = 2,
                            LocalDiscountForMargin = 10,
                            ForeignDiscountForMargin = 20,
                            ExchRate = (decimal) 1.132,
                            NameKey = nameKey,
                            CaseKey = caseKey,
                            StaffKey = staffKey,
                            WIPCode = wipCode,
                            Quantity = quantity,
                            DebtorSplitPercentage = debtorSplitPercentage
                        }
                    }
                };

                var f = new WipDisbursementsFixture(Db).WithValidPostDate();

                var r = await f.Subject.Save(userIdentityId, culture, input);

                Assert.True(r);

                f.PostWipCommand
                 .Received(1)
                 .Post(userIdentityId, culture, Arg.Is<PostWipParameters[]>(x =>
                                                                                x[0].IsCreditWip == input.CreditWIP &&
                                                                                x[0].EntityKey == input.EntityKey &&
                                                                                x[0].TransactionDate == input.TransDate &&
                                                                                x[0].InvoiceNumber == input.InvoiceNo &&
                                                                                x[0].VerificationNumber == input.VerificationNo &&
                                                                                x[0].ProtocolKey == input.ProtocolKey &&
                                                                                x[0].ProtocolDate == input.ProtocolDate &&
                                                                                x[0].NameKey == nameKey &&
                                                                                x[0].CaseKey == caseKey &&
                                                                                x[0].StaffKey == staffKey &&
                                                                                x[0].WipCode == wipCode &&
                                                                                x[0].IsCreditWip == false &&
                                                                                x[0].LocalValue == 101 && /* local value + margin */
                                                                                x[0].ForeignValue == 202 && /* foreign value + foreign margin) */
                                                                                x[0].DiscountValue == 10 &&
                                                                                x[0].ForeignDiscount == 20 &&
                                                                                x[0].LocalCost == 100 &&
                                                                                x[0].ForeignCost == 200 &&
                                                                                x[0].CostCalculation1 == 100 &&
                                                                                x[0].CostCalculation2 == 100 &&
                                                                                x[0].MarginValue == 1 &&
                                                                                x[0].ForeignMargin == 2 &&
                                                                                x[0].DiscountForMargin == 10 &&
                                                                                x[0].ForeignDiscountForMargin == 20 &&
                                                                                x[0].ExchangeRate == (decimal) 1.132 &&
                                                                                x[0].EnteredQuantity == quantity &&
                                                                                x[0].DebtorSplitPercentage == debtorSplitPercentage &&
                                                                                x[0].IsDraftWip == false &&
                                                                                x[0].IsBillingDiscount == false &&
                                                                                x[0].IsSplitDebtorWip == false &&
                                                                                x[0].ShouldSuppressCommit &&
                                                                                x[0].ShouldReturnWipKey
                                                                           ))
                 .IgnoreAwaitForNSubstituteAssertion();
            }

            [Fact]
            public async Task ShouldThrowExceptionIfValidationFailed()
            {
                var f = new WipDisbursementsFixture(Db)
                    .WithInvalidPostDate("AC126", false);

                var exception = await Assert.ThrowsAsync<Exception>(async () => await f.Subject.Save(Fixture.Integer(), Fixture.String(), new Disbursement()));

                Assert.Equal("An accounting period could not be determined for the given date. Please check the period definitions and try again.", exception.Message);
            }
        }
    }
}