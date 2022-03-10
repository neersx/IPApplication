using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Infrastructure.Extensions;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Infrastructure.Notifications.Validation;
using Inprotech.Tests.Extensions;
using Inprotech.Web.Accounting.Billing;
using InprotechKaizen.Model.Accounting;
using InprotechKaizen.Model.Components.Accounting.Billing;
using InprotechKaizen.Model.Components.Accounting.Billing.Debtors;
using InprotechKaizen.Model.Components.Accounting.Billing.Items;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.Security;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Accounting.Billing
{
    public class DebtorsControllerFacts
    {
        public class GetDebtorsMethodSummeryOnly
        {
            [Fact]
            public async Task ShouldRetrieveDebtorsFromCasesWithCaseId()
            {
                var caseId = Fixture.Integer();

                var debtor1 = new DebtorData();
                var debtor2 = new DebtorData();

                var fixture = new DebtorsControllerFixture()
                    .WithDebtorsFromCases(null, debtor1, debtor2);

                var r = await fixture.Subject.GetDebtors(caseId: caseId);

                Assert.Contains(debtor1, r.DebtorList);
                Assert.Contains(debtor2, r.DebtorList);
            }

            [Fact]
            public async Task ShouldRetrieveDebtorsFromCasesWithCaseIds()
            {
                var caseId = Fixture.Integer();
                var caseIdCsv = "1,2,3,4";

                var debtor1 = new DebtorData();
                var debtor2 = new DebtorData();

                var fixture = new DebtorsControllerFixture()
                    .WithDebtorsFromCases(null, debtor1, debtor2);

                var r = await fixture.Subject.GetDebtors(caseId: caseId, caseIds: caseIdCsv);

                Assert.Contains(debtor1, r.DebtorList);
                Assert.Contains(debtor2, r.DebtorList);
            }

            [Fact]
            public async Task ShouldRetrieveDebtorsFromCasesWithCaseListId()
            {
                var caseListId = Fixture.Integer();

                var debtor1 = new DebtorData();
                var debtor2 = new DebtorData();

                var fixture = new DebtorsControllerFixture()
                    .WithDebtorsFromCases(null, debtor1, debtor2);

                var r = await fixture.Subject.GetDebtors(caseListId: caseListId);

                Assert.Contains(debtor1, r.DebtorList);
                Assert.Contains(debtor2, r.DebtorList);
            }

            [Fact]
            public async Task ShouldRelayApplicationAlerts()
            {
                var caseId = Fixture.Integer();
                var caseIdCsv = "1,2,3,4";

                var debtor1 = new DebtorData();
                var debtor2 = new DebtorData();

                var applicationAlert = new ApplicationAlert
                {
                    Message = "yikes!"
                };

                var fixture = new DebtorsControllerFixture()
                    .WithDebtorsFromCases(applicationAlert, debtor1, debtor2);

                var r = await fixture.Subject.GetDebtors(caseId: caseId, caseIds: caseIdCsv);

                Assert.Equal("yikes!", r.ErrorMessage);
            }
        }

        public class GetDebtorsMethodWithDetails
        {
            [Fact]
            public async Task ShouldRetrieveDebtorDetailsForDraftBillWithBillingLanguageForEachDebtor()
            {
                var caseId = Fixture.Integer();

                var debtor1 = new DebtorData {NameId = Fixture.Integer()};
                var debtor2 = new DebtorData {NameId = Fixture.Integer()};

                var debtor1LanguageKey = Fixture.Integer();
                var debtor2LanguageKey = Fixture.Integer();

                var billDate = Fixture.Today();
                var entityId = Fixture.Integer();
                var transactionId = Fixture.Integer();

                var fixture = new DebtorsControllerFixture()
                              .WithDebtorDetails(null, debtor1, debtor2)
                              .WithOpenItemStatus(entityId, transactionId, TransactionStatus.Draft)
                              .WithBillingLanguage(debtor1.NameId, caseId, debtor1LanguageKey)
                              .WithBillingLanguage(debtor2.NameId, caseId, debtor2LanguageKey)
                              .WithBillDebtorRestriction(new Dictionary<int, DebtorRestrictionStatus>
                              {
                                  {debtor1.NameId, new DebtorRestrictionStatus()},
                                  {debtor2.NameId, new DebtorRestrictionStatus()}
                              });

                var r = await fixture.Subject.GetDebtors(DebtorsController.TypeOfDetails.Detailed,
                                                         caseId: caseId,
                                                         billDate: billDate,
                                                         entityId: entityId,
                                                         transactionId: transactionId);

                Assert.Contains(debtor1, r.DebtorList);
                Assert.Contains(debtor2, r.DebtorList);

                Assert.Equal(debtor1LanguageKey, r.DebtorList.First().LanguageId);
                Assert.Equal(debtor2LanguageKey, r.DebtorList.Last().LanguageId);
            }

            [Fact]
            public async Task ShouldRetrieveDebtorDetailsForDraftBillWithTotalWipPopulatedForEachDebtor()
            {
                var caseId = Fixture.Integer();

                var debtor1 = new DebtorData {NameId = Fixture.Integer()};
                var debtor2 = new DebtorData {NameId = Fixture.Integer()};

                var debtor1WipTotal = Fixture.Decimal();
                var debtor2WipTotal = Fixture.Decimal();

                var billDate = Fixture.Today();
                var entityId = Fixture.Integer();
                var transactionId = Fixture.Integer();

                var fixture = new DebtorsControllerFixture()
                              .WithDebtorDetails(null, debtor1, debtor2)
                              .WithOpenItemStatus(entityId, transactionId, TransactionStatus.Draft)
                              .WithDraftBillAvailableWipTotals(new Dictionary<int, decimal?>
                              {
                                  {debtor1.NameId, debtor1WipTotal},
                                  {debtor2.NameId, debtor2WipTotal}
                              })
                              .WithBillDebtorRestriction(new Dictionary<int, DebtorRestrictionStatus>
                              {
                                  {debtor1.NameId, new DebtorRestrictionStatus()},
                                  {debtor2.NameId, new DebtorRestrictionStatus()}
                              });

                var r = await fixture.Subject.GetDebtors(DebtorsController.TypeOfDetails.Detailed,
                                                         caseId: caseId,
                                                         billDate: billDate,
                                                         entityId: entityId,
                                                         transactionId: transactionId);

                Assert.Contains(debtor1, r.DebtorList);
                Assert.Contains(debtor2, r.DebtorList);

                Assert.Equal(debtor1WipTotal, r.DebtorList.First().TotalWip);
                Assert.Equal(debtor2WipTotal, r.DebtorList.Last().TotalWip);
            }

            [Fact]
            public async Task ShouldRetrieveDebtorDetailsForNewBillWithTotalWipPopulatedForEachDebtor()
            {
                var caseId = Fixture.Integer();

                var debtor1 = new DebtorData {NameId = Fixture.Integer()};
                var debtor2 = new DebtorData {NameId = Fixture.Integer()};

                var debtor1WipTotal = Fixture.Decimal();
                var debtor2WipTotal = Fixture.Decimal();

                var billDate = Fixture.Today();
                var entityId = Fixture.Integer();

                var fixture = new DebtorsControllerFixture()
                              .WithDebtorDetails(null, debtor1, debtor2)
                              .WithOpenItemStatus(entityId)
                              .WithNewBillAvailableWipTotals(new Dictionary<int, decimal?>
                              {
                                  {debtor1.NameId, debtor1WipTotal},
                                  {debtor2.NameId, debtor2WipTotal}
                              })
                              .WithBillDebtorRestriction(new Dictionary<int, DebtorRestrictionStatus>
                              {
                                  {debtor1.NameId, new DebtorRestrictionStatus()},
                                  {debtor2.NameId, new DebtorRestrictionStatus()}
                              });

                var r = await fixture.Subject.GetDebtors(DebtorsController.TypeOfDetails.Detailed,
                                                         caseId: caseId,
                                                         billDate: billDate,
                                                         entityId: entityId);

                Assert.Contains(debtor1, r.DebtorList);
                Assert.Contains(debtor2, r.DebtorList);

                Assert.Equal(debtor1WipTotal, r.DebtorList.First().TotalWip);
                Assert.Equal(debtor2WipTotal, r.DebtorList.Last().TotalWip);
            }

            [Fact]
            public async Task ShouldRetrieveDebtorDetailsForFinalisedBillWithTotalWipNullForEachDebtor()
            {
                var caseId = Fixture.Integer();

                var debtor1 = new DebtorData {NameId = Fixture.Integer()};
                var debtor2 = new DebtorData {NameId = Fixture.Integer()};

                var billDate = Fixture.Today();
                var entityId = Fixture.Integer();
                var transactionId = Fixture.Integer();

                var fixture = new DebtorsControllerFixture()
                              .WithDebtorDetails(null, debtor1, debtor2)
                              .WithOpenItemStatus(entityId, transactionId, TransactionStatus.Active)
                              .WithBillDebtorRestriction(new Dictionary<int, DebtorRestrictionStatus>
                              {
                                  {debtor1.NameId, new DebtorRestrictionStatus()},
                                  {debtor2.NameId, new DebtorRestrictionStatus()}
                              });

                var r = await fixture.Subject.GetDebtors(DebtorsController.TypeOfDetails.Detailed,
                                                         caseId: caseId,
                                                         billDate: billDate,
                                                         entityId: entityId,
                                                         transactionId: transactionId);

                Assert.Contains(debtor1, r.DebtorList);
                Assert.Contains(debtor2, r.DebtorList);

                Assert.Null(r.DebtorList.First().TotalWip);
                Assert.Null(r.DebtorList.Last().TotalWip);

                fixture.DebtorAvailableWipTotals.DidNotReceiveWithAnyArgs().ForDraftBill(null, 0, null, 0)
                       .IgnoreAwaitForNSubstituteAssertion();

                fixture.DebtorAvailableWipTotals.DidNotReceiveWithAnyArgs().ForNewBill(null, 0, null)
                       .IgnoreAwaitForNSubstituteAssertion();
            }

            [Fact]
            public async Task ShouldRelayApplicationAlerts()
            {
                var caseId = Fixture.Integer();
                var debtor1 = new DebtorData();
                var debtor2 = new DebtorData();

                var applicationAlert = new ApplicationAlert
                {
                    Message = "yikes!"
                };

                var billDate = Fixture.Today();
                var entityId = Fixture.Integer();
                var transactionId = Fixture.Integer();

                var fixture = new DebtorsControllerFixture()
                    .WithDebtorDetails(applicationAlert, debtor1, debtor2);

                var r = await fixture.Subject.GetDebtors(DebtorsController.TypeOfDetails.Detailed,
                                                         caseId: caseId,
                                                         billDate: billDate,
                                                         entityId: entityId,
                                                         transactionId: transactionId);

                Assert.Equal("yikes!", r.ErrorMessage);

                fixture.DebtorAvailableWipTotals.DidNotReceiveWithAnyArgs().ForDraftBill(null, 0, null, 0)
                       .IgnoreAwaitForNSubstituteAssertion();

                fixture.DebtorAvailableWipTotals.DidNotReceiveWithAnyArgs().ForNewBill(null, 0, null)
                       .IgnoreAwaitForNSubstituteAssertion();
            }

            [Fact]
            public async Task ShouldRetrieveDebtorRestriction()
            {
                var caseId = Fixture.Integer();

                var debtor1 = new DebtorData {NameId = Fixture.Integer()};
                var debtor2 = new DebtorData {NameId = Fixture.Integer()};
                var billDate = Fixture.Today();
                var entityId = Fixture.Integer();
                var transactionId = Fixture.Integer();
                var debtor1Restriction = new DebtorRestrictionStatus { NameId = debtor1.NameId, DebtorStatusAction = 1, DebtorStatus = "Slow Player" };
                var debtor2Restriction = new DebtorRestrictionStatus { NameId = debtor2.NameId, DebtorStatusAction = 0, DebtorStatus = string.Empty };

                var fixture = new DebtorsControllerFixture()
                              .WithDebtorDetails(null, debtor1, debtor2)
                              .WithBillDebtorRestriction(new Dictionary<int, DebtorRestrictionStatus>
                              {
                                  {debtor1.NameId, debtor1Restriction},
                                  {debtor2.NameId, debtor2Restriction}
                              });

                var r = await fixture.Subject.GetDebtors(DebtorsController.TypeOfDetails.Detailed,
                                                         caseId: caseId,
                                                         billDate: billDate,
                                                         entityId: entityId,
                                                         transactionId: transactionId);

                Assert.Contains(debtor1, r.DebtorList);
                Assert.Contains(debtor2, r.DebtorList);

                Assert.Equal(debtor1Restriction, r.DebtorList.First().DebtorRestriction);
                Assert.Equal(debtor2Restriction, r.DebtorList.Last().DebtorRestriction);
            }
        }

        public class ReloadDebtorsMethod
        {
            [Fact]
            public async Task ShouldReloadRequestedDebtors()
            {
                var caseId = Fixture.Integer();
                var debtor1 = new DebtorData {NameId = Fixture.Integer(), CaseId = caseId};
                var debtor2 = new DebtorData {NameId = Fixture.Integer(), CaseId = caseId};
                var debtor3 = new DebtorData {NameId = Fixture.Integer(), CaseId = caseId};

                var billDate = Fixture.Today();
                var entityId = Fixture.Integer();
                var action = Fixture.String();
                var useRenewalDebtor = Fixture.Boolean();

                var fixture = new DebtorsControllerFixture()
                              .WithDebtorDetails(debtor1)
                              .WithDebtorDetails(debtor2)
                              .WithDebtorDetails(debtor3).WithBillDebtorRestriction(new Dictionary<int, DebtorRestrictionStatus>
                              {
                                  {debtor1.NameId, new DebtorRestrictionStatus()},
                                  {debtor2.NameId, new DebtorRestrictionStatus()},
                                  {debtor3.NameId, new DebtorRestrictionStatus()}
                              });

                var r = await fixture.Subject.ReloadDebtors(caseId, entityId, action, useRenewalDebtor, billDate,
                                                            new[]
                                                            {
                                                                new DebtorsController.ReloadDebtorDetails
                                                                {
                                                                    DebtorNameId = debtor1.NameId
                                                                },
                                                                new DebtorsController.ReloadDebtorDetails
                                                                {
                                                                    DebtorNameId = debtor2.NameId
                                                                },
                                                                new DebtorsController.ReloadDebtorDetails
                                                                {
                                                                    DebtorNameId = debtor3.NameId
                                                                }
                                                            });

                Assert.Contains(debtor1, r.DebtorList);
                Assert.Contains(debtor2, r.DebtorList);
                Assert.Contains(debtor3, r.DebtorList);
            }

            [Fact]
            public async Task ShouldRelayApplicationAlertsInTheDebtorThatContainsTheError()
            {
                var caseId = Fixture.Integer();
                var debtor1 = new DebtorData {NameId = Fixture.Integer(), CaseId = caseId};
                var debtor2 = new DebtorData {NameId = Fixture.Integer(), CaseId = caseId};
                var debtor3 = new DebtorData {NameId = Fixture.Integer(), CaseId = caseId};

                var billDate = Fixture.Today();
                var entityId = Fixture.Integer();
                var action = Fixture.String();
                var useRenewalDebtor = Fixture.Boolean();

                var applicationAlert = new ApplicationAlert
                {
                    Message = "yikes!"
                };

                var fixture = new DebtorsControllerFixture()
                              .WithDebtorDetails(debtor1)
                              .WithDebtorDetails(debtor2, applicationAlert)
                              .WithDebtorDetails(debtor3)
                              .WithDebtorDetails(debtor3).WithBillDebtorRestriction(new Dictionary<int, DebtorRestrictionStatus>
                              {
                                  {debtor1.NameId, new DebtorRestrictionStatus()},
                                  {debtor2.NameId, new DebtorRestrictionStatus()},
                                  {debtor3.NameId, new DebtorRestrictionStatus()}
                              });

                var r = await fixture.Subject.ReloadDebtors(caseId, entityId, action, useRenewalDebtor, billDate,
                                                            new[]
                                                            {
                                                                new DebtorsController.ReloadDebtorDetails
                                                                {
                                                                    DebtorNameId = debtor1.NameId
                                                                },
                                                                new DebtorsController.ReloadDebtorDetails
                                                                {
                                                                    DebtorNameId = debtor2.NameId
                                                                },
                                                                new DebtorsController.ReloadDebtorDetails
                                                                {
                                                                    DebtorNameId = debtor3.NameId
                                                                }
                                                            });

                Assert.Contains(debtor1, r.DebtorList);
                Assert.DoesNotContain(debtor2, r.DebtorList);
                Assert.Contains(debtor3, r.DebtorList);
                Assert.Equal("yikes!", r.DebtorList.ElementAt(1).ErrorMessage);
                Assert.True(r.DebtorList.ElementAt(1).HasError);
            }

            [Fact]
            public async Task ShouldRetrieveDebtorRestriction()
            {
                var caseId = Fixture.Integer();
                var debtor1 = new DebtorData {NameId = Fixture.Integer(), CaseId = caseId};
                var debtor2 = new DebtorData {NameId = Fixture.Integer(), CaseId = caseId};

                var billDate = Fixture.Today();
                var entityId = Fixture.Integer();
                var action = Fixture.String();
                var useRenewalDebtor = Fixture.Boolean();
                var debtor1Restriction = new DebtorRestrictionStatus { NameId = debtor1.NameId, DebtorStatusAction = 1, DebtorStatus = "Slow Player" };
                var debtor2Restriction = new DebtorRestrictionStatus { NameId = debtor2.NameId, DebtorStatusAction = 0, DebtorStatus = string.Empty };
                
                var fixture = new DebtorsControllerFixture()
                              .WithDebtorDetails(debtor1)
                              .WithDebtorDetails(debtor2)
                              .WithBillDebtorRestriction(new Dictionary<int, DebtorRestrictionStatus>
                              {
                                  {debtor1.NameId, debtor1Restriction},
                                  {debtor2.NameId, debtor2Restriction}
                              });

                var r = await fixture.Subject.ReloadDebtors(caseId, entityId, action, useRenewalDebtor, billDate,
                                                            new[]
                                                            {
                                                                new DebtorsController.ReloadDebtorDetails
                                                                {
                                                                    DebtorNameId = debtor1.NameId
                                                                },
                                                                new DebtorsController.ReloadDebtorDetails
                                                                {
                                                                    DebtorNameId = debtor2.NameId
                                                                }
                                                            });

                Assert.Contains(debtor1, r.DebtorList);
                Assert.Contains(debtor2, r.DebtorList);

                Assert.Equal(debtor1Restriction, r.DebtorList.First().DebtorRestriction);
                Assert.Equal(debtor2Restriction, r.DebtorList.Last().DebtorRestriction);
            }
        }

        public class GetDebtorsOnTheBillMethod
        {
            [Fact]
            public async Task ShouldReturnDebtorsOnDraftBillsOrMergedBillsWithTotalWipPopulated()
            {
                var debtor1 = new DebtorData {NameId = Fixture.Integer()};
                var debtor2 = new DebtorData {NameId = Fixture.Integer()};

                var debtor1WipTotal = Fixture.Decimal();
                var debtor2WipTotal = Fixture.Decimal();

                var entityId = Fixture.Integer();
                var transactionId = Fixture.Integer();

                var fixture = new DebtorsControllerFixture()
                              .WithBillDebtors(null, debtor1, debtor2)
                              .WithOpenItemStatus(entityId, transactionId, TransactionStatus.Draft)
                              .WithDraftBillAvailableWipTotals(new Dictionary<int, decimal?>
                              {
                                  {debtor1.NameId, debtor1WipTotal},
                                  {debtor2.NameId, debtor2WipTotal}
                              })
                              .WithBillDebtorRestriction(new Dictionary<int, DebtorRestrictionStatus>
                              {
                                  {debtor1.NameId, new DebtorRestrictionStatus()},
                                  {debtor2.NameId, new DebtorRestrictionStatus()}
                              });

                var r = await fixture.Subject.GetDebtorsOnTheBill(entityId, transactionId);

                Assert.Contains(debtor1, r.DebtorList);
                Assert.Contains(debtor2, r.DebtorList);

                Assert.Equal(debtor1WipTotal, r.DebtorList.First().TotalWip);
                Assert.Equal(debtor2WipTotal, r.DebtorList.Last().TotalWip);
            }

            [Fact]
            public async Task ShouldRelayApplicationAlerts()
            {
                var entityId = Fixture.Integer();
                var transactionId = Fixture.Integer();
                var applicationAlert = new ApplicationAlert
                {
                    Message = "yikes!"
                };

                var fixture = new DebtorsControllerFixture()
                    .WithBillDebtors(applicationAlert);

                var r = await fixture.Subject.GetDebtorsOnTheBill(entityId, transactionId);

                Assert.Equal("yikes!", r.ErrorMessage);
            }

            [Fact]
            public async Task ShouldRetrieveDebtorRestriction()
            {
                var debtor1 = new DebtorData {NameId = Fixture.Integer()};
                var debtor2 = new DebtorData {NameId = Fixture.Integer()};
                var entityId = Fixture.Integer();
                var transactionId = Fixture.Integer();
                var debtor1WipTotal = Fixture.Decimal();
                var debtor2WipTotal = Fixture.Decimal();
                var debtor1Restriction = new DebtorRestrictionStatus { NameId = debtor1.NameId, DebtorStatusAction = 1, DebtorStatus = "Slow Player" };
                var debtor2Restriction = new DebtorRestrictionStatus { NameId = debtor2.NameId, DebtorStatusAction = 0, DebtorStatus = string.Empty };
                
                var fixture = new DebtorsControllerFixture()
                              .WithBillDebtors(null, debtor1, debtor2)
                              .WithOpenItemStatus(entityId, transactionId, TransactionStatus.Draft)
                              .WithDraftBillAvailableWipTotals(new Dictionary<int, decimal?>
                              {
                                  {debtor1.NameId, debtor1WipTotal},
                                  {debtor2.NameId, debtor2WipTotal}
                              })
                              .WithBillDebtorRestriction(new Dictionary<int, DebtorRestrictionStatus>
                              {
                                  {debtor1.NameId, debtor1Restriction},
                                  {debtor2.NameId, debtor2Restriction}
                              });

                var r = await fixture.Subject.GetDebtorsOnTheBill(entityId, transactionId);

                Assert.Contains(debtor1, r.DebtorList);
                Assert.Contains(debtor2, r.DebtorList);

                Assert.Equal(debtor1Restriction, r.DebtorList.First().DebtorRestriction);
                Assert.Equal(debtor2Restriction, r.DebtorList.Last().DebtorRestriction);
            }
        }

        public class GetDebtorCopiesToMethod
        {
            [Fact]
            public async Task ShouldReturnCopiesTo()
            {
                var debtorKey = Fixture.Integer();
                var copyToKey = Fixture.Integer();
                var debtorCopiesTo = new DebtorCopiesTo();

                var fixture = new DebtorsControllerFixture()
                    .WithDebtorCopiesTo(debtorKey, copyToKey, debtorCopiesTo);

                var r = await fixture.Subject.GetDebtorCopiesTo(debtorKey, copyToKey);

                Assert.Equal(debtorCopiesTo, r);
            }
        }

        public class DebtorsControllerFixture : IFixture<DebtorsController>
        {
            public DebtorsControllerFixture()
            {
                var securityContext = Substitute.For<ISecurityContext>();
                securityContext.User.Returns(new User());

                var preferredCultureResolver = Substitute.For<IPreferredCultureResolver>();
                preferredCultureResolver.Resolve().Returns("en");

                BillingLanguageResolver[(Arg.Any<int?>(), Arg.Any<string>())]
                    .Returns(x =>
                    {
                        var a = (Tuple<int?, string>) x[0];
                        return $"Language Description for {a.Item1} in {a.Item2}";
                    });

                Subject = new DebtorsController(securityContext, preferredCultureResolver,
                                                OpenItemStatusResolver, DebtorAvailableWipTotals, BillingLanguageResolver, DebtorListCommands, DebtorRestriction);
            }

            public IOpenItemStatusResolver OpenItemStatusResolver { get; } = Substitute.For<IOpenItemStatusResolver>();

            public IDebtorAvailableWipTotals DebtorAvailableWipTotals { get; } = Substitute.For<IDebtorAvailableWipTotals>();

            public IBillingLanguageResolver BillingLanguageResolver { get; } = Substitute.For<IBillingLanguageResolver>();

            public IDebtorListCommands DebtorListCommands { get; } = Substitute.For<IDebtorListCommands>();

            public IDebtorRestriction DebtorRestriction { get; } = Substitute.For<IDebtorRestriction>();

            public DebtorsController Subject { get; }

            public DebtorsControllerFixture WithBillingLanguage(int? debtorNameId, int? caseId, int? languageKey = null)
            {
                BillingLanguageResolver.Resolve(debtorNameId, caseId, Arg.Any<string>(), Arg.Any<bool?>())
                                       .Returns(languageKey);
                return this;
            }

            public DebtorsControllerFixture WithOpenItemStatus(int entityId, int? transactionId = null, TransactionStatus? status = null)
            {
                OpenItemStatusResolver.Resolve(entityId, transactionId)
                                      .Returns(status);

                return this;
            }

            public DebtorsControllerFixture WithDebtorCopiesTo(int debtorKey, int copyToNameKey, DebtorCopiesTo debtorCopiesTo)
            {
                DebtorListCommands.GetCopiesToContactDetails(Arg.Any<int>(), Arg.Any<string>(), debtorKey, copyToNameKey)
                                  .Returns(debtorCopiesTo);

                return this;
            }

            public DebtorsControllerFixture WithDebtorsFromCases(ApplicationAlert alert, params DebtorData[] debtors)
            {
                var alerts = alert == null ? Enumerable.Empty<ApplicationAlert>() : new[] {alert};

                DebtorListCommands.RetrieveDebtorsFromCases(Arg.Any<int>(), Arg.Any<string>(),
                                                            Arg.Any<bool>(), Arg.Any<string>(),
                                                            Arg.Any<int?>(), Arg.Any<int[]>(), Arg.Any<int?>())
                                  .Returns((debtors, alerts));

                return this;
            }

            public DebtorsControllerFixture WithDebtorDetails(ApplicationAlert alert, params DebtorData[] debtors)
            {
                var alerts = alert == null ? Enumerable.Empty<ApplicationAlert>() : new[] {alert};

                DebtorListCommands.RetrieveDebtorDetails(Arg.Any<int>(), Arg.Any<string>(),
                                                         Arg.Any<int?>(), Arg.Any<int?>(),
                                                         Arg.Any<DateTime?>(),
                                                         Arg.Any<int?>(),
                                                         Arg.Any<bool>(), Arg.Any<bool>(),
                                                         Arg.Any<string>(), Arg.Any<int?>())
                                  .Returns((debtors, alerts));

                return this;
            }

            public DebtorsControllerFixture WithDebtorDetails(DebtorData debtorData, ApplicationAlert alert = null)
            {
                var alerts = alert == null ? Enumerable.Empty<ApplicationAlert>() : new[] {alert};

                DebtorListCommands.RetrieveDebtorDetails(Arg.Any<int>(), Arg.Any<string>(),
                                                         Arg.Any<int?>(), debtorData.NameId,
                                                         Arg.Any<DateTime?>(),
                                                         debtorData.CaseId,
                                                         Arg.Any<bool>(), Arg.Any<bool>(),
                                                         Arg.Any<string>(), Arg.Any<int?>())
                                  .Returns((new[] {debtorData}, alerts));

                return this;
            }

            public DebtorsControllerFixture WithBillDebtors(ApplicationAlert alert, params DebtorData[] debtors)
            {
                var alerts = alert == null ? Enumerable.Empty<ApplicationAlert>() : new[] {alert};

                DebtorListCommands.RetrieveBillDebtors(Arg.Any<int>(), Arg.Any<string>(),
                                                       Arg.Any<int>(), Arg.Any<int>(),
                                                       Arg.Any<int?>())
                                  .Returns((debtors, alerts));

                return this;
            }

            public DebtorsControllerFixture WithDraftBillAvailableWipTotals(Dictionary<int, decimal?> totalAvailableWipMap = null)
            {
                var dataSetup = totalAvailableWipMap ?? new Dictionary<int, decimal?>();

                foreach (var debtorNameId in dataSetup.Keys)
                {
                    DebtorAvailableWipTotals.ForDraftBill(Arg.Any<int[]>(), debtorNameId, Arg.Any<int?>(), Arg.Any<int>())
                                            .Returns(dataSetup.Get(debtorNameId));
                }

                return this;
            }

            public DebtorsControllerFixture WithNewBillAvailableWipTotals(Dictionary<int, decimal?> totalAvailableWipMap = null)
            {
                var dataSetup = totalAvailableWipMap ?? new Dictionary<int, decimal?>();

                foreach (var debtorNameId in dataSetup.Keys)
                {
                    DebtorAvailableWipTotals.ForNewBill(Arg.Any<int[]>(), debtorNameId, Arg.Any<int?>())
                                            .Returns(dataSetup.Get(debtorNameId));
                }

                return this;
            }

            public DebtorsControllerFixture WithBillDebtorRestriction(Dictionary<int, DebtorRestrictionStatus> debtorRestrictions = null)
            {
                var dataSetup = debtorRestrictions ?? new Dictionary<int, DebtorRestrictionStatus>();

                DebtorRestriction.GetDebtorRestriction(Arg.Any<string>(), Arg.Any<int[]>())
                                 .Returns(dataSetup);

                return this;
            }
        }
    }
}