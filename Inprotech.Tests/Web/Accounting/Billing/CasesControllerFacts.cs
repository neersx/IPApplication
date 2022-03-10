using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Tests.Fakes;
using Inprotech.Web.Accounting.Billing;
using InprotechKaizen.Model.Components.Accounting;
using InprotechKaizen.Model.Components.Accounting.Billing.Cases;
using InprotechKaizen.Model.Components.Accounting.Billing.Items;
using InprotechKaizen.Model.Components.Accounting.Wip;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.Security;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Accounting.Billing
{
    public class CasesControllerFacts
    {
        public class GetOpenItemCasesMethodForSpecificBill : FactBase
        {
            [Fact]
            public async Task ShouldReturnWipTotalsWithTheCases()
            {
                var itemEntityNo = Fixture.Integer();
                var itemTransactionNo = Fixture.Integer();

                var case1 = new CaseData { CaseId = Fixture.Integer() };
                var case2 = new CaseData { CaseId = Fixture.Integer() };

                var case1TotalAvailableWip = Fixture.Decimal();
                var case2UnlockedWip = Fixture.Decimal();

                var fixture = new CasesControllerFixture()
                              .WithOpenItemCases(case1, case2)
                              .WithTotalAvailableWip(new Dictionary<int, decimal?>
                              {
                                  { case1.CaseId, case1TotalAvailableWip }
                              })
                              .WithUnlockedAvailableWip(new Dictionary<int, decimal?>
                              {
                                  { case2.CaseId, case2UnlockedWip }
                              });

                var r = await fixture.Subject.GetOpenItemCases(itemEntityNo, itemTransactionNo);

                var cases = r.CaseList.ToArray();

                Assert.Equal(case1TotalAvailableWip, cases.First().TotalWip);
                Assert.Equal(case2UnlockedWip, cases.Last().UnlockedWip);
            }

            [Fact]
            public async Task ShouldReturnRestrictionsWithTheCasesIfExist()
            {
                var itemEntityNo = Fixture.Integer();
                var itemTransactionNo = Fixture.Integer();

                var case1 = new CaseData { CaseId = Fixture.Integer() };
                var case2 = new CaseData { CaseId = Fixture.Integer() };

                var case2Restriction = new CaseData
                {
                    CaseId = case2.CaseId,
                    CaseStatus = Fixture.String(),
                    OfficialNumber = Fixture.String()
                };

                var fixture = new CasesControllerFixture()
                              .WithOpenItemCases(case1, case2)
                              .WithRestrictedCases(case2Restriction);

                var r = await fixture.Subject.GetOpenItemCases(itemEntityNo, itemTransactionNo);

                var cases = r.CaseList.ToArray();

                Assert.Null(cases.First().CaseStatus);
                Assert.False(cases.First().HasRestrictedStatusForBilling);

                Assert.Equal(case2Restriction.CaseStatus, cases.Last().CaseStatus);
                Assert.Equal(case2Restriction.OfficialNumber, cases.Last().OfficialNumber);
                Assert.True(cases.Last().HasRestrictedStatusForBilling);
            }

            [Fact]
            public async Task ShouldReturnCountryAndPropertyTypeWithTheCases()
            {
                var itemEntityId = Fixture.Integer();
                var itemTransactionId = Fixture.Integer();

                var case1 = new CaseData { CaseId = Fixture.Integer() };
                var case2 = new CaseData { CaseId = Fixture.Integer() };

                var case2ExtendedData = new CaseData
                {
                    CaseId = case2.CaseId,
                    Country = Fixture.String(),
                    PropertyTypeDescription = Fixture.String()
                };

                var fixture = new CasesControllerFixture()
                              .WithOpenItemCases(case1, case2)
                              .WithCountryAndPropertyType(case2ExtendedData);

                var r = await fixture.Subject.GetOpenItemCases(itemEntityId, itemTransactionId);

                var cases = r.CaseList.ToArray();

                Assert.Null(cases.First().CaseStatus);

                Assert.Equal(case2ExtendedData.Country, cases.Last().Country);
                Assert.Equal(case2ExtendedData.PropertyTypeDescription, cases.Last().PropertyTypeDescription);
            }
        }

        public class GetOpenItemCasesMethodForMergingMultipleDraftBills : FactBase
        {
            const string AnyMergeXmlKey = @"<Keys><Key><ItemEntityNo>1</ItemEntityNo><ItemTransNo>1</ItemTransNo></Key></Keys>";

            [Fact]
            public async Task ShouldReturnCases()
            {
                var case1 = new CaseData { CaseId = Fixture.Integer() };
                var case2 = new CaseData { CaseId = Fixture.Integer() };

                var fixture = new CasesControllerFixture()
                    .WithOpenItemCasesFromMergedXmlKeys(case1, case2);

                var r = await fixture.Subject.GetOpenItemCases(AnyMergeXmlKey);

                Assert.Equal(2, r.CaseList.Count());
            }

            [Fact]
            public async Task ShouldReturnRestrictionsWithTheCasesIfExist()
            {
                var case1 = new CaseData { CaseId = Fixture.Integer() };
                var case2 = new CaseData { CaseId = Fixture.Integer() };

                var case2Restriction = new CaseData
                {
                    CaseId = case2.CaseId,
                    CaseStatus = Fixture.String(),
                    OfficialNumber = Fixture.String()
                };

                var fixture = new CasesControllerFixture()
                              .WithOpenItemCasesFromMergedXmlKeys(case1, case2)
                              .WithRestrictedCases(case2Restriction);

                var r = await fixture.Subject.GetOpenItemCases(AnyMergeXmlKey);

                var cases = r.CaseList.ToArray();

                Assert.Null(cases.First().CaseStatus);
                Assert.False(cases.First().HasRestrictedStatusForBilling);

                Assert.Equal(case2Restriction.CaseStatus, cases.Last().CaseStatus);
                Assert.Equal(case2Restriction.OfficialNumber, cases.Last().OfficialNumber);
                Assert.True(cases.Last().HasRestrictedStatusForBilling);
            }
        }

        public class GetCasesMethodWithCaseIds : FactBase
        {
            [Fact]
            public async Task ShouldReturnCases()
            {
                var case1 = new CaseData { CaseId = Fixture.Integer() };
                var case2 = new CaseData { CaseId = Fixture.Integer() };

                var fixture = new CasesControllerFixture()
                    .WithCases(case1, case2);

                var r = await fixture.Subject.GetCases(new CasesController.CaseRequest
                {
                    CaseIds = $"{case1.CaseId},{case2.CaseId}"
                });

                Assert.Equal(2, r.CaseList.Count());
            }

            [Fact]
            public async Task ShouldReturnWipTotalsWithTheCases()
            {
                var itemEntityId = Fixture.Integer();

                var case1 = new CaseData { CaseId = Fixture.Integer() };
                var case2 = new CaseData { CaseId = Fixture.Integer() };

                var case1TotalAvailableWip = Fixture.Decimal();
                var case2UnlockedWip = Fixture.Decimal();

                var fixture = new CasesControllerFixture()
                              .WithCases(case1, case2)
                              .WithTotalAvailableWip(new Dictionary<int, decimal?>
                              {
                                  { case1.CaseId, case1TotalAvailableWip }
                              })
                              .WithUnlockedAvailableWip(new Dictionary<int, decimal?>
                              {
                                  { case2.CaseId, case2UnlockedWip }
                              });

                var r = await fixture.Subject.GetCases(new CasesController.CaseRequest
                {
                    CaseIds = $"{case1.CaseId},{case2.CaseId}",
                    EntityId = itemEntityId
                });

                var cases = r.CaseList.ToArray();

                Assert.Equal(case1TotalAvailableWip, cases.First().TotalWip);
                Assert.Equal(case2UnlockedWip, cases.Last().UnlockedWip);
            }

            [Fact]
            public async Task ShouldReturnRestrictionsWithTheCasesIfExist()
            {
                var itemEntityId = Fixture.Integer();

                var case1 = new CaseData { CaseId = Fixture.Integer() };
                var case2 = new CaseData { CaseId = Fixture.Integer() };

                var case2Restriction = new CaseData
                {
                    CaseId = case2.CaseId,
                    CaseStatus = Fixture.String(),
                    OfficialNumber = Fixture.String()
                };

                var fixture = new CasesControllerFixture()
                              .WithCases(case1, case2)
                              .WithRestrictedCases(case2Restriction);

                var r = await fixture.Subject.GetCases(new CasesController.CaseRequest
                {
                    CaseIds = $"{case1.CaseId},{case2.CaseId}",
                    EntityId = itemEntityId
                });

                var cases = r.CaseList.ToArray();

                Assert.Null(cases.First().CaseStatus);
                Assert.False(cases.First().HasRestrictedStatusForBilling);

                Assert.Equal(case2Restriction.CaseStatus, cases.Last().CaseStatus);
                Assert.Equal(case2Restriction.OfficialNumber, cases.Last().OfficialNumber);
                Assert.True(cases.Last().HasRestrictedStatusForBilling);
            }

            [Fact]
            public async Task ShouldReturnDraftBillsWithTheCaseIfExist()
            {
                var itemEntityId = Fixture.Integer();

                var case1 = new CaseData { CaseId = Fixture.Integer() };
                var case2 = new CaseData { CaseId = Fixture.Integer() };

                var fixture = new CasesControllerFixture()
                              .WithCases(case1, case2)
                              .WithDraftBills(new Dictionary<int, IEnumerable<string>>
                              {
                                  { case2.CaseId, new[] { "D123", "D124" } }
                              });

                var r = await fixture.Subject.GetCases(new CasesController.CaseRequest
                {
                    CaseIds = $"{case1.CaseId},{case2.CaseId}",
                    EntityId = itemEntityId
                });

                var cases = r.CaseList.ToArray();

                Assert.Empty(cases.First().DraftBills);
                Assert.Contains("D124", cases.Last().DraftBills);
                Assert.Contains("D123", cases.Last().DraftBills);
            }

            [Fact]
            public async Task ShouldReturnCountryAndPropertyTypeWithTheCases()
            {
                var itemEntityId = Fixture.Integer();

                var case1 = new CaseData { CaseId = Fixture.Integer() };
                var case2 = new CaseData { CaseId = Fixture.Integer() };

                var case2ExtendedData = new CaseData
                {
                    CaseId = case2.CaseId,
                    Country = Fixture.String(),
                    PropertyTypeDescription = Fixture.String()
                };

                var fixture = new CasesControllerFixture()
                              .WithCases(case1, case2)
                              .WithCountryAndPropertyType(case2ExtendedData);

                var r = await fixture.Subject.GetCases(new CasesController.CaseRequest
                {
                    CaseIds = $"{case1.CaseId},{case2.CaseId}",
                    EntityId = itemEntityId
                });

                var cases = r.CaseList.ToArray();

                Assert.Null(cases.First().CaseStatus);

                Assert.Equal(case2ExtendedData.Country, cases.Last().Country);
                Assert.Equal(case2ExtendedData.PropertyTypeDescription, cases.Last().PropertyTypeDescription);
            }
        }

        public class GetCasesMethodWithCaseListId : FactBase
        {
            [Fact]
            public async Task ShouldReturnCases()
            {
                var caseListId = Fixture.Integer();

                var case1 = new CaseData { CaseId = Fixture.Integer() };
                var case2 = new CaseData { CaseId = Fixture.Integer() };

                var fixture = new CasesControllerFixture()
                    .WithCases(caseListId, case1, case2);

                var r = await fixture.Subject.GetCases(new CasesController.CaseRequest
                {
                    CaseListId = caseListId
                });

                Assert.Equal(2, r.CaseList.Count());
            }

            [Fact]
            public async Task ShouldReturnWipTotalsWithTheCases()
            {
                var caseListId = Fixture.Integer();
                var itemEntityId = Fixture.Integer();

                var case1 = new CaseData { CaseId = Fixture.Integer() };
                var case2 = new CaseData { CaseId = Fixture.Integer() };

                var case1TotalAvailableWip = Fixture.Decimal();
                var case2UnlockedWip = Fixture.Decimal();

                var fixture = new CasesControllerFixture()
                              .WithCases(caseListId, case1, case2)
                              .WithTotalAvailableWip(new Dictionary<int, decimal?>
                              {
                                  { case1.CaseId, case1TotalAvailableWip }
                              })
                              .WithUnlockedAvailableWip(new Dictionary<int, decimal?>
                              {
                                  { case2.CaseId, case2UnlockedWip }
                              });

                var r = await fixture.Subject.GetCases(new CasesController.CaseRequest
                {
                    CaseListId = caseListId,
                    EntityId = itemEntityId
                });

                var cases = r.CaseList.ToArray();

                Assert.Equal(case1TotalAvailableWip, cases.First().TotalWip);
                Assert.Equal(case2UnlockedWip, cases.Last().UnlockedWip);
            }

            [Fact]
            public async Task ShouldReturnRestrictionsWithTheCasesIfExist()
            {
                var caseListId = Fixture.Integer();
                var itemEntityId = Fixture.Integer();

                var case1 = new CaseData { CaseId = Fixture.Integer() };
                var case2 = new CaseData { CaseId = Fixture.Integer() };

                var case2Restriction = new CaseData
                {
                    CaseId = case2.CaseId,
                    CaseStatus = Fixture.String(),
                    OfficialNumber = Fixture.String()
                };

                var fixture = new CasesControllerFixture()
                              .WithCases(caseListId, case1, case2)
                              .WithRestrictedCases(case2Restriction);

                var r = await fixture.Subject.GetCases(new CasesController.CaseRequest
                {
                    CaseListId = caseListId,
                    EntityId = itemEntityId
                });

                var cases = r.CaseList.ToArray();

                Assert.Null(cases.First().CaseStatus);
                Assert.False(cases.First().HasRestrictedStatusForBilling);

                Assert.Equal(case2Restriction.CaseStatus, cases.Last().CaseStatus);
                Assert.Equal(case2Restriction.OfficialNumber, cases.Last().OfficialNumber);
                Assert.True(cases.Last().HasRestrictedStatusForBilling);
            }

            [Fact]
            public async Task ShouldReturnDraftBillsWithTheCaseIfExist()
            {
                var caseListId = Fixture.Integer();
                var itemEntityId = Fixture.Integer();

                var case1 = new CaseData { CaseId = Fixture.Integer() };
                var case2 = new CaseData { CaseId = Fixture.Integer() };

                var fixture = new CasesControllerFixture()
                              .WithCases(caseListId, case1, case2)
                              .WithDraftBills(new Dictionary<int, IEnumerable<string>>
                              {
                                  { case2.CaseId, new[] { "D123", "D124" } }
                              });

                var r = await fixture.Subject.GetCases(new CasesController.CaseRequest
                {
                    CaseListId = caseListId,
                    EntityId = itemEntityId
                });

                var cases = r.CaseList.ToArray();

                Assert.Empty(cases.First().DraftBills);
                Assert.Contains("D124", cases.Last().DraftBills);
                Assert.Contains("D123", cases.Last().DraftBills);
            }

            [Fact]
            public async Task ShouldReturnCountryAndPropertyTypeWithTheCases()
            {
                var caseListId = Fixture.Integer();
                var itemEntityId = Fixture.Integer();

                var case1 = new CaseData { CaseId = Fixture.Integer() };
                var case2 = new CaseData { CaseId = Fixture.Integer() };

                var case2ExtendedData = new CaseData
                {
                    CaseId = case2.CaseId,
                    Country = Fixture.String(),
                    PropertyTypeDescription = Fixture.String()
                };

                var fixture = new CasesControllerFixture()
                              .WithCases(caseListId, case1, case2)
                              .WithCountryAndPropertyType(case2ExtendedData);

                var r = await fixture.Subject.GetCases(new CasesController.CaseRequest
                {
                    CaseListId = caseListId,
                    EntityId = itemEntityId
                });

                var cases = r.CaseList.ToArray();

                Assert.Null(cases.First().CaseStatus);

                Assert.Equal(case2ExtendedData.Country, cases.Last().Country);
                Assert.Equal(case2ExtendedData.PropertyTypeDescription, cases.Last().PropertyTypeDescription);
            }
        }

        public class RestrictedForBillingMethod : FactBase
        {
            [Fact]
            public async Task ShouldReturnRestrictedForBillingCases()
            {
                var caseId = Fixture.Integer();
                var restrictedCase = new CaseData();

                var fixture = new CasesControllerFixture()
                    .WithRestrictedCases(restrictedCase);

                var r = await fixture.Subject.RestrictedForBilling(caseId);

                Assert.Equal(restrictedCase, r.CaseList.Single());
            }
        }

        public class RestrictedForPrepaymentMethod : FactBase
        {
            [Fact]
            public async Task ShouldReturnRestrictedForPrepaymentStatusOfRequestedCase()
            {
                var caseId = Fixture.Integer();
                var isRestricted = Fixture.Boolean();

                var fixture = new CasesControllerFixture();
                fixture.CaseStatusValidator.IsCaseStatusRestrictedForPrepayment(caseId).Returns(isRestricted);

                var r = await fixture.Subject.RestrictedForPrepayment(caseId);

                Assert.Equal(isRestricted, r);
            }
        }

        public class GetValidActionMethod : FactBase
        {
            [Fact]
            public async Task ShouldThrowArgumentNullException()
            {
                var fixture = new CasesControllerFixture();
                var exception = await Assert.ThrowsAsync<ArgumentNullException>(async () => await fixture.Subject.GetValidAction(null));
                Assert.IsType<ArgumentNullException>(exception);
            }

            [Fact]
            public async Task ShouldReturnValidActions()
            {
                var action = new ActionData {Key = Fixture.Integer(), Value = Fixture.String()};

                var fixture = new CasesControllerFixture();
                fixture.CaseDataExtension.GetValidAction(Arg.Any<ValidActionIdentifier>(), Arg.Any<string>()).Returns(action);

                var r = await fixture.Subject.GetValidAction(new ValidActionIdentifier());

                Assert.Equal(action, r);
            }
        }

        public class CasesControllerFixture : IFixture<CasesController>
        {
            public CasesControllerFixture()
            {
                var securityContext = Substitute.For<ISecurityContext>();
                securityContext.User.Returns(new User());

                var preferredCultureResolver = Substitute.For<IPreferredCultureResolver>();
                preferredCultureResolver.Resolve().Returns("en");

                WithRestrictedCases();
                WithUnlockedAvailableWip();
                WithTotalAvailableWip();
                WithDraftBills();
                WithCountryAndPropertyType();

                Subject = new CasesController(securityContext, preferredCultureResolver, CaseDataCommands, RestrictedForBilling, CaseStatusValidator, CaseWipCalculator, CaseDataExtension);
            }

            public ICaseStatusValidator CaseStatusValidator { get; } = Substitute.For<ICaseStatusValidator>();

            public IRestrictedForBilling RestrictedForBilling { get; } = Substitute.For<IRestrictedForBilling>();

            public ICaseWipCalculator CaseWipCalculator { get; } = Substitute.For<ICaseWipCalculator>();

            public ICaseDataCommands CaseDataCommands { get; } = Substitute.For<ICaseDataCommands>();

            public ICaseDataExtension CaseDataExtension { get; } = Substitute.For<ICaseDataExtension>();

            public CasesController Subject { get; }

            public CasesControllerFixture WithRestrictedCases(params CaseData[] bunchOfRestrictedCases)
            {
                RestrictedForBilling.Retrieve(Arg.Any<int[]>())
                                    .Returns(bunchOfRestrictedCases.ToArray().AsDbAsyncEnumerble());

                RestrictedForBilling.Retrieve(Arg.Any<CaseData[]>())
                                    .Returns(bunchOfRestrictedCases.ToArray().AsDbAsyncEnumerble());

                return this;
            }

            public CasesControllerFixture WithTotalAvailableWip(Dictionary<int, decimal?> totalAvailableWipMap = null)
            {
                CaseWipCalculator.GetTotalAvailableWip(Arg.Any<int[]>(), Arg.Any<int?>())
                                 .Returns(totalAvailableWipMap ?? new Dictionary<int, decimal?>());

                return this;
            }

            public CasesControllerFixture WithUnlockedAvailableWip(Dictionary<int, decimal?> unlockedAvailableWipMap = null)
            {
                CaseWipCalculator.GetUnlockedAvailableWip(Arg.Any<int[]>(), Arg.Any<int?>())
                                 .Returns(unlockedAvailableWipMap ?? new Dictionary<int, decimal?>());

                return this;
            }

            public CasesControllerFixture WithDraftBills(Dictionary<int, IEnumerable<string>> draftBills = null)
            {
                CaseWipCalculator.GetDraftBillsByCase(Arg.Any<int[]>())
                                 .Returns(draftBills ?? new Dictionary<int, IEnumerable<string>>());

                return this;
            }

            public CasesControllerFixture WithOpenItemCases(params CaseData[] bunchOfCaseData)
            {
                CaseDataCommands.GetOpenItemCases(Arg.Any<int>(), Arg.Any<string>(), Arg.Any<int>(), Arg.Any<int>())
                                .Returns(bunchOfCaseData);

                return this;
            }

            public CasesControllerFixture WithOpenItemCasesFromMergedXmlKeys(params CaseData[] bunchOfCaseData)
            {
                CaseDataCommands.GetOpenItemCases(Arg.Any<int>(), Arg.Any<string>(), mergeXmlKeys: Arg.Any<MergeXmlKeys>())
                                .Returns(bunchOfCaseData);

                return this;
            }

            public CasesControllerFixture WithCases(int caseListId, params CaseData[] bunchOfCaseData)
            {
                CaseDataCommands.GetCases(Arg.Any<int>(), Arg.Any<string>(), caseListId, Arg.Any<int>())
                                .ReturnsForAnyArgs(bunchOfCaseData);

                return this;
            }

            public CasesControllerFixture WithCases(params CaseData[] bunchOfCaseData)
            {
                foreach (var c in bunchOfCaseData)
                {
                    CaseDataCommands.GetCase(Arg.Any<int>(), Arg.Any<string>(), c.CaseId, Arg.Any<int>())
                                    .Returns(c);
                }

                return this;
            }

            public CasesControllerFixture WithCountryAndPropertyType(params CaseData[] bunchOfCaseData)
            {
                CaseDataExtension.GetPropertyTypeAndCountry(Arg.Any<int[]>(), Arg.Any<string>())
                                 .Returns(bunchOfCaseData.Length > 0
                                              ? bunchOfCaseData.ToDictionary(x => x.CaseId, caseData => caseData)
                                              : new Dictionary<int, CaseData>());

                return this;
            }
        }
    }
}