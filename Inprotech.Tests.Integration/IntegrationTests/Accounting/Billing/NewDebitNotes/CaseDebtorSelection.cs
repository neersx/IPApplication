using System;
using System.Collections.Generic;
using System.Linq;
using Inprotech.Infrastructure.Notifications.Validation;
using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.DbHelpers.Builders;
using Inprotech.Tests.Integration.DbHelpers.Builders.Accounting;
using Inprotech.Tests.Integration.Extensions;
using Inprotech.Web.Accounting.Billing;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Accounting;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Components.Accounting.Billing.Cases;
using InprotechKaizen.Model.Components.Accounting.Billing.Debtors;
using InprotechKaizen.Model.Components.Names;
using InprotechKaizen.Model.Configuration;
using InprotechKaizen.Model.Names;
using NUnit.Framework;

namespace Inprotech.Tests.Integration.IntegrationTests.Accounting.Billing.NewDebitNotes
{
    [Category(Categories.Integration)]
    [TestFixture]
    public class CaseDebtorSelection : IntegrationTest
    {
        [TearDown]
        public void CleanUpModifiedData()
        {
            AccountingDbHelper.Cleanup();
        }

        [Test]
        public void PickCaseWithLocalDebtor()
        {
            var billingData = new DraftBillDataSetup().Setup();

            var caseSummary = BillingService.GetCase(billingData.CaseLocalSingle.Id, billingData.User.NameId, billingData.EntityId);

            CommonAssert.CaseDataAreEqual(new CaseData
                                          {
                                              CaseId = billingData.CaseLocalSingle.Id,
                                              OpenAction = billingData.LatestOpenActionByCase[billingData.CaseLocalSingle.Id],
                                              IsMainCase = false, /* at selection time, this is false */
                                              BillSourceCountryCode = billingData.EntityCountry /* Entity MYAC is local, and there hasn't been any office attribute set against 'raised by staff id' */
                                          },
                                          caseSummary, "Single Debtor Local Case, Case Summary");

            var debtorSummary = BillingService.GetDebtorsFromCase(caseSummary.CaseId, caseSummary.OpenAction, false);

            CommonAssert.DebtorDataAreEqual(new DebtorData
                                            {
                                                NameId = billingData.CaseLocalSingle.Debtor1().NameId,
                                                BillPercentage = 100,
                                                CaseId = caseSummary.CaseId,
                                                NameType = KnownNameTypes.Debtor,
                                                IsMultiCaseAllowed = true /* Bill Consolidation - Allow Multi Case is ticked */
                                            },
                                            debtorSummary.DebtorList.Single(), "Single Debtor Local Case, Debtor Summary");

            var debtorDetail = BillingService.GetDebtorListFromCase(caseSummary.CaseId, null, caseSummary.OpenAction, false, billingData.EntityId, DateTime.Today, billingData.User.NameId);

            CommonAssert.DebtorDataAreEqual(new DebtorData
                                            {
                                                NameId = billingData.CaseLocalSingle.Debtor1().NameId,
                                                /*
                                                    Address resolution depends on which debtor to be used and considers relationship of send bills to
                                                    The data setup here is simple so it falls back to the debtor's address
                                                 */
                                                AddressId = billingData.CaseLocalSingle.Debtor1().Name.PostalAddressId,
                                                BilledAmount = 0,
                                                TotalWip = 0,
                                                TotalCredits = 0,
                                                BillPercentage = 100,
                                                CaseId = caseSummary.CaseId,
                                                NameType = KnownNameTypes.Debtor
                                            },
                                            debtorDetail.DebtorList.Single(), "Single Debtor Local Case, Debtor Detail");
        }

        [Test]
        public void PickCaseWithCaseWipLockedOnOtherDraftBills()
        {
            var data = DbSetup.Do(x =>
            {
                var billingData = new DraftBillDataSetup().Setup(x.DbContext);

                var wipAvailableForThisBill = new WipBuilder(x.DbContext)
                    .BuildWithWorkHistory(billingData.EntityId, billingData.CaseLocalSingle.Id, billingData.ServiceCharge1.WipCode, 1000);

                var wipLockedOnAnotherBill = new WipBuilder(x.DbContext)
                    .BuildWithWorkHistory(billingData.EntityId, billingData.CaseLocalSingle.Id, billingData.ServiceCharge1.WipCode, 2000, -200);

                var otherDraftBill = new OpenItemBuilder(x.DbContext)
                {
                    StaffId = billingData.StaffName.Id,
                    StaffProfitCentre = billingData.StaffProfitCentre.Id,
                    EntityId = billingData.EntityId,
                    LocalValue = wipLockedOnAnotherBill.Wip.LocalValue,
                    LocalBalance = wipLockedOnAnotherBill.Wip.Balance.GetValueOrDefault()
                }.BuildDraftBill(billingData.CaseLocalSingle.Id, wipLockedOnAnotherBill.Wip, wipLockedOnAnotherBill.Discount);

                billingData.CaseLocalSingle.Debtor1().Name.ClientDetail.ConsolidationType = ConsolidationType.CaseConsolidationDebtorSame; /* allow multi case = true */

                x.DbContext.SaveChanges();

                return new
                {
                    BillingData = billingData,
                    DebtorId = billingData.CaseLocalSingle.Debtor1().NameId,
                    AddressId = billingData.CaseLocalSingle.Debtor1().Name.PostalAddressId,
                    WipAvailableForThisBill = wipAvailableForThisBill.Wip,
                    WipLockedOnAnotherBill = wipLockedOnAnotherBill.Wip,
                    DiscountWipLockedOnAnotherBill = wipLockedOnAnotherBill.Discount,
                    OtherDraftBillOpenItemNo = otherDraftBill.Single().OpenItemNo
                };
            });

            /*
             * Data Setup
             * The case has a local debtor
             * - two wip item are recorded against the case
             * -- 1000 unlocked
             * -- 2000 with 200 discount locked to a different draft bill
             *
             * Notable Test Results Expectations
             * - given that wip is locked onto another bill, requesting details of this case and its debtor for a new bill should return warnings that draft bill is present.
             */

            var caseSummary = BillingService.GetCase(data.BillingData.CaseLocalSingle.Id, data.BillingData.User.NameId, data.BillingData.EntityId);

            CommonAssert.CaseDataAreEqual(new CaseData
                                          {
                                              CaseId = data.BillingData.CaseLocalSingle.Id,
                                              OpenAction = data.BillingData.LatestOpenActionByCase[data.BillingData.CaseLocalSingle.Id],
                                              TotalWip = data.WipAvailableForThisBill.LocalValue + data.WipLockedOnAnotherBill.LocalValue + data.DiscountWipLockedOnAnotherBill.LocalValue,
                                              UnlockedWip = data.WipAvailableForThisBill.LocalValue,
                                              IsMainCase = false, /* at selection time, this is false */
                                              BillSourceCountryCode = data.BillingData.EntityCountry /* Entity MYAC is local, and there hasn't been any office attribute set against 'raised by staff id' */
                                          },
                                          caseSummary, "Single Debtor Local Case, Case Summary");

            var debtorSummary = BillingService.GetDebtorsFromCase(caseSummary.CaseId, caseSummary.OpenAction, false);

            CommonAssert.DebtorDataAreEqual(new DebtorData
                                            {
                                                NameId = data.DebtorId,
                                                BillPercentage = 100,
                                                CaseId = caseSummary.CaseId,
                                                NameType = KnownNameTypes.Debtor,
                                                IsMultiCaseAllowed = true /* Bill Consolidation - Allow Multi Case is ticked */
                                            },
                                            debtorSummary.DebtorList.Single(), "Single Debtor Local Case, Debtor Summary");

            var debtorDetail = BillingService.GetDebtorListFromCase(caseSummary.CaseId, null, caseSummary.OpenAction, false, data.BillingData.EntityId, DateTime.Today, data.BillingData.User.NameId);

            CommonAssert.DebtorDataAreEqual(new DebtorData
                                            {
                                                NameId = data.DebtorId,
                                                /*
                                                    Address resolution depends on which debtor to be used and considers relationship of send bills to
                                                    The data setup here is simple so it falls back to the debtor's address
                                                 */
                                                AddressId = data.AddressId,
                                                BilledAmount = 0,
                                                TotalWip = 0,
                                                TotalCredits = 0,
                                                BillPercentage = 100,
                                                CaseId = caseSummary.CaseId,
                                                NameType = KnownNameTypes.Debtor,
                                                IsMultiCaseAllowed = true, /* Bill Consolidation - Allow Multi Case is ticked */
                                                Warnings = new List<DebtorWarning>
                                                {
                                                    new()
                                                    {
                                                        NameId = data.DebtorId,
                                                        Severity = AlertSeverity.UserError,
                                                        WarningError = $"Draft bill(s) exist for this debtor: {data.OtherDraftBillOpenItemNo}"
                                                    }
                                                }
                                            },
                                            debtorDetail.DebtorList.Single(), "Single Debtor Local Case, Debtor Detail");
        }

        [Test]
        public void PickCaseListCasesWithMultipleDebtors()
        {
            var data = DbSetup.Do(x =>
            {
                var billingData = new DraftBillDataSetup().Setup(x.DbContext);

                var caseList = x.InsertWithNewId(new CaseList {Name = RandomString.Next(20)});
                x.Insert(new CaseListMember(caseList.Id, billingData.CaseLocalMultiple.Id, true));
                x.Insert(new CaseListMember(caseList.Id, billingData.CaseLocalSingle.Id, false));

                var debtorId = billingData.CaseLocalSingle.Debtor1().NameId; /* this is the common and bill debtor for the both cases */
                var debtor1Detail = x.DbContext.Set<ClientDetail>().Single(_ => debtorId == _.Id);
                debtor1Detail.ConsolidationType = ConsolidationType.CaseConsolidationDebtorSame; /* allow multi case = true */

                var copiesTo1 = new NameBuilder(x.DbContext).CreateClientIndividual("cc1");
                var copiesTo2 = new NameBuilder(x.DbContext).CreateClientIndividual("cc2");

                // when NOT using Renewal Debtors, Copies To derives from Copies To name type.
                var copiesToNameType = x.DbContext.Set<NameType>().Single(_ => _.NameTypeCode == KnownNameTypes.DebtorCopiesTo);

                billingData.CaseLocalMultiple.CaseNames.Add(new CaseName(billingData.CaseLocalMultiple, copiesToNameType, billingData.CaseLocalMultiple.Debtor1().Name, 0)
                {
                    AttentionNameId = copiesTo1.Id,
                    IsDerivedAttentionName = 0
                });

                billingData.CaseLocalSingle.CaseNames.Add(new CaseName(billingData.CaseLocalSingle, copiesToNameType, billingData.CaseLocalSingle.Debtor1().Name, 0)
                {
                    AttentionNameId = copiesTo2.Id,
                    IsDerivedAttentionName = 0
                });

                x.DbContext.SaveChanges();

                return new
                {
                    BillingData = billingData,
                    CaseListId = caseList.Id,
                    PrimeCaseId = billingData.CaseLocalMultiple.Id,
                    DebtorId1 = billingData.CaseLocalMultiple.Debtor1().NameId,
                    DebtorId2 = billingData.CaseLocalMultiple.Debtor2().NameId,
                    DebtorName1 = billingData.CaseLocalMultiple.Debtor1().Name.Formatted(NameStyles.FirstNameThenFamilyName),
                    DebtorName2 = billingData.CaseLocalMultiple.Debtor2().Name.Formatted(NameStyles.FirstNameThenFamilyName),
                    AddressId1 = billingData.CaseLocalMultiple.Debtor1().Name.PostalAddressId,
                    AddressId2 = billingData.CaseLocalMultiple.Debtor2().Name.PostalAddressId,
                    Debtor1CopiesToContactNameId = copiesTo1.Id,
                    Debtor2CopiesToContactNameId = copiesTo2.Id,
                    Debtor1CopiesToContactName = copiesTo1.Formatted(NameStyles.FirstNameThenFamilyName),
                    Debtor2CopiesToContactName = copiesTo2.Formatted(NameStyles.FirstNameThenFamilyName)
                };
            });

            /*
             * Data Setup
             * The case list contains
             * - Case Local Multiple as prime case, which has debtors 1 and debtors 2 split 60/40; Debtor Copies To Name Type exist
             * - Case Local Single as another case that has the same debtor 2 in it; Debtor Copies To Name Type exist
             * - Debtor 1 has discount of 10% across the board.
             *
             * Notable Test Results Expectations
             * - Copies to will not be returned for Case Local Single's debtor even though it has value. This is because only the main case will have copies to.
             * - Discount will be returned for Debtor 1.
             */

            var caseSummary = BillingService.GetCaseListCases(data.CaseListId, data.BillingData.User.NameId);

            CommonAssert.CaseDataAreEqual(new CaseData
                                          {
                                              CaseId = data.BillingData.CaseLocalMultiple.Id, /* prime case id */
                                              CaseListId = data.CaseListId,
                                              OpenAction = data.BillingData.LatestOpenActionByCase[data.BillingData.CaseLocalMultiple.Id],
                                              IsMainCase = true, /* this is the prime case */
                                              IsMultiDebtorCase = true,
                                              BillSourceCountryCode = data.BillingData.EntityCountry /* Entity MYAC is local, and there hasn't been any office attribute set against 'raised by staff id' */
                                          },
                                          caseSummary.CaseList.First(), "Case List Case #1");

            CommonAssert.CaseDataAreEqual(new CaseData
                                          {
                                              CaseId = data.BillingData.CaseLocalSingle.Id, /* the other case in the case list */
                                              CaseListId = data.CaseListId,
                                              IsMainCase = false, /* this is not the prime case */
                                              IsMultiDebtorCase = false,
                                              BillSourceCountryCode = data.BillingData.EntityCountry /* Entity MYAC is local, and there hasn't been any office attribute set against 'raised by staff id' */
                                          },
                                          caseSummary.CaseList.Last(), "Case List Case #2");

            var debtorSummary = BillingService.GetDebtorsFromCaseList(data.CaseListId, caseSummary.CaseList.First().OpenAction, false);

            CommonAssert.DebtorDataAreEqual(new DebtorData
                                            {
                                                NameId = data.DebtorId1,
                                                BillPercentage = 60,
                                                CaseId = data.PrimeCaseId,
                                                NameType = KnownNameTypes.Debtor,
                                                IsMultiCaseAllowed = true /* Bill Consolidation - Allow Multi Case is ticked */
                                            },
                                            debtorSummary.DebtorList.Single(_ => _.NameId == data.DebtorId1 && _.CaseId == data.PrimeCaseId), "CaseList Case #1 Debtor #1");

            CommonAssert.DebtorDataAreEqual(new DebtorData
                                            {
                                                NameId = data.DebtorId2,
                                                BillPercentage = 40,
                                                CaseId = data.PrimeCaseId,
                                                NameType = KnownNameTypes.Debtor,
                                                IsMultiCaseAllowed = true /* Bill Consolidation - Allow Multi Case is ticked */
                                            },
                                            debtorSummary.DebtorList.Single(_ => _.NameId == data.DebtorId2 && _.CaseId == data.PrimeCaseId), "CaseList Case #1 Debtor #2");

            CommonAssert.DebtorDataAreEqual(new DebtorData
                                            {
                                                NameId = data.DebtorId2,
                                                BillPercentage = 100,
                                                CaseId = data.BillingData.CaseLocalSingle.Id,
                                                NameType = KnownNameTypes.Debtor,
                                                IsMultiCaseAllowed = true /* Bill Consolidation - Allow Multi Case is ticked */
                                            },
                                            debtorSummary.DebtorList.Single(_ => _.NameId == data.DebtorId2 && _.CaseId != data.PrimeCaseId), "CaseList Case #2 Debtor #1");

            var debtorDetail = BillingService.GetDebtorListFromCase(data.PrimeCaseId,
                                                                    new[]
                                                                    {
                                                                        caseSummary.CaseList.First().CaseId, caseSummary.CaseList.Last().CaseId
                                                                    },
                                                                    caseSummary.CaseList.First().OpenAction, false, data.BillingData.EntityId, DateTime.Today, data.BillingData.User.NameId);

            CommonAssert.DebtorDataAreEqual(new DebtorData
                                            {
                                                NameId = data.DebtorId1,
                                                /*
                                                    Address resolution depends on which debtor to be used and considers relationship of send bills to
                                                    The data setup here is simple so it falls back to the debtor's address
                                                 */
                                                AddressId = data.AddressId1,
                                                BilledAmount = 0,
                                                TotalWip = 0,
                                                TotalCredits = 0,
                                                BillPercentage = 60,
                                                CaseId = data.PrimeCaseId,
                                                NameType = KnownNameTypes.Debtor,
                                                IsMultiCaseAllowed = false,
                                                CopiesTos = new List<DebtorCopiesTo>
                                                {
                                                    new()
                                                    {
                                                        /*
                                                         * For case related bills just being created,
                                                         * Copies To is derived from the Debtor Copies To name type of the main case
                                                         */
                                                        DebtorNameId = data.DebtorId1,
                                                        CopyToNameId = data.DebtorId1,
                                                        CopyToName = data.DebtorName1,
                                                        AddressId = data.AddressId1,
                                                        ContactName = data.Debtor1CopiesToContactName,
                                                        ContactNameId = data.Debtor1CopiesToContactNameId
                                                    }
                                                },
                                                Discounts = new List<DebtorDiscount>
                                                {
                                                    new()
                                                    {
                                                        ApplyAs = "Discount",
                                                        DiscountRate = (decimal) 10.0,
                                                        Sequence = 0,
                                                        NameId = data.DebtorId1
                                                    }
                                                }
                                            },
                                            debtorDetail.DebtorList.First(), "CaseList Case #1 Debtor Detail #1");

            CommonAssert.DebtorDataAreEqual(new DebtorData
                                            {
                                                NameId = data.DebtorId2,
                                                /*
                                                    Address resolution depends on which debtor to be used and considers relationship of send bills to
                                                    The data setup here is simple so it falls back to the debtor's address
                                                 */
                                                AddressId = data.AddressId2,
                                                BilledAmount = 0,
                                                TotalWip = 0,
                                                TotalCredits = 0,
                                                BillPercentage = 40,
                                                CaseId = data.PrimeCaseId,
                                                NameType = KnownNameTypes.Debtor,
                                                IsMultiCaseAllowed = true /* Bill Consolidation - Allow Multi Case is ticked */
                                            },
                                            debtorDetail.DebtorList.Last(), "CaseList Case #1 Debtor Detail #2");
        }

        [Test]
        public void PickForeignCaseWithWipLockedOnOtherDraftBills()
        {
            var data = DbSetup.Do(x =>
            {
                var billingData = new DraftBillDataSetup().Setup(x.DbContext);

                var foreignCurrency = billingData.ForeignCurrency;

                var wipAvailableForThisBill = new WipBuilder(x.DbContext)
                    .BuildWithWorkHistory(billingData.EntityId, billingData.CaseForeignSingle.Id, billingData.ServiceCharge1.WipCode, 1000, foreignCurrency: foreignCurrency.Id, exchangeRate: (decimal) 1.1);

                var wipLockedOnAnotherBill = new WipBuilder(x.DbContext)
                    .BuildWithWorkHistory(billingData.EntityId, billingData.CaseForeignSingle.Id, billingData.ServiceCharge1.WipCode, 2000, -200, foreignCurrency.Id, (decimal) 1.1);

                var otherDraftBill = new OpenItemBuilder(x.DbContext)
                {
                    StaffId = billingData.StaffName.Id,
                    StaffProfitCentre = billingData.StaffProfitCentre.Id,
                    EntityId = billingData.EntityId,
                    LocalValue = wipLockedOnAnotherBill.Wip.LocalValue,
                    LocalBalance = wipLockedOnAnotherBill.Wip.Balance.GetValueOrDefault(),
                    ForeignValue = wipLockedOnAnotherBill.Wip.ForeignValue,
                    ForeignBalance = wipLockedOnAnotherBill.Wip.ForeignBalance,
                    Currency = foreignCurrency.Id,
                    ExchangeRate = (decimal) 1.1
                }.BuildDraftBill(billingData.CaseForeignSingle.Id, wipLockedOnAnotherBill.Wip, wipLockedOnAnotherBill.Discount);

                var debtorId = billingData.CaseForeignSingle.Debtor1().NameId;
                var debtor1Detail = x.DbContext.Set<ClientDetail>().Single(_ => debtorId == _.Id);
                debtor1Detail.ConsolidationType = ConsolidationType.CaseConsolidationDebtorAttnAddressSame; /* allow multi case = true */

                var addressId = x.DbContext.Set<Name>().Single(_ => _.Id == debtorId).PostalAddressId;

                x.DbContext.SaveChanges();

                return new
                {
                    BillingData = billingData,
                    DebtorId = debtorId,
                    AddressId = addressId,
                    WipAvailableForThisBill = wipAvailableForThisBill.Wip,
                    WipLockedOnAnotherBill = wipLockedOnAnotherBill.Wip,
                    DiscountWipLockedOnAnotherBill = wipLockedOnAnotherBill.Discount,
                    OtherDraftBillOpenItemNo = otherDraftBill.Single().OpenItemNo
                };
            });

            /*
             * Data Setup
             * The case has a foreign debtor with foreign currency F1.
             * - the foreign debtor has a 20% discount rate across the board.
             * - two wip item are recorded against the case
             * -- 1000 unlocked, currency = F1, exchange rate = 1.1
             * -- 2000 with 200 discount locked to a different draft bill, currency = F1, exchange rate = 1.1
             *
             * Notable Test Results Expectations
             * - given that wip is locked onto another bill, requesting details of this case and its debtor for a new bill should return warnings that draft bill is present.
             */

            var caseSummary = BillingService.GetCase(data.BillingData.CaseForeignSingle.Id, data.BillingData.User.NameId, data.BillingData.EntityId);

            CommonAssert.CaseDataAreEqual(new CaseData
                                          {
                                              CaseId = data.BillingData.CaseForeignSingle.Id,
                                              OpenAction = data.BillingData.LatestOpenActionByCase[data.BillingData.CaseForeignSingle.Id],
                                              TotalWip = data.WipAvailableForThisBill.LocalValue + data.WipLockedOnAnotherBill.LocalValue + data.DiscountWipLockedOnAnotherBill.LocalValue,
                                              UnlockedWip = data.WipAvailableForThisBill.LocalValue,
                                              IsMainCase = false, /* at selection time, this is false */
                                              BillSourceCountryCode = data.BillingData.EntityCountry /* Entity MYAC is local, and there hasn't been any office attribute set against 'raised by staff id' */
                                          },
                                          caseSummary, "Single Debtor Foreign Case, Case Summary");

            var debtorSummary = BillingService.GetDebtorsFromCase(caseSummary.CaseId, caseSummary.OpenAction, false);

            CommonAssert.DebtorDataAreEqual(new DebtorData
                                            {
                                                NameId = data.DebtorId,
                                                BillPercentage = 100,
                                                CaseId = caseSummary.CaseId,
                                                NameType = KnownNameTypes.Debtor,
                                                IsMultiCaseAllowed = true /* Bill Consolidation - Allow Multi Case is ticked */
                                            },
                                            debtorSummary.DebtorList.Single(), "Single Debtor Foreign Case, Debtor Summary");

            var debtorDetail = BillingService.GetDebtorListFromCase(caseSummary.CaseId, null, caseSummary.OpenAction, false, data.BillingData.EntityId, DateTime.Today, data.BillingData.User.NameId);

            CommonAssert.DebtorDataAreEqual(new DebtorData
                                            {
                                                NameId = data.DebtorId,
                                                /*
                                                    Address resolution depends on which debtor to be used and considers relationship of send bills to
                                                    The data setup here is simple so it falls back to the debtor's address
                                                 */
                                                AddressId = data.AddressId,
                                                BilledAmount = 0,
                                                BuyExchangeRate = (decimal) 1.1,
                                                Currency = data.BillingData.ForeignCurrency.Id,
                                                TotalWip = 0,
                                                TotalCredits = 0,
                                                BillPercentage = 100,
                                                CaseId = caseSummary.CaseId,
                                                NameType = KnownNameTypes.Debtor,
                                                IsMultiCaseAllowed = true /* Bill Consolidation - Allow Multi Case is ticked */,
                                                Discounts = new List<DebtorDiscount>
                                                {
                                                    new()
                                                    {
                                                        NameId = data.DebtorId,
                                                        Sequence = 0,
                                                        DiscountRate = (decimal) 20.0, /* this is as set up in the setup routine */
                                                        ApplyAs = "Discount",
                                                        BasedOnAmount = false
                                                    }
                                                },
                                                Warnings = new List<DebtorWarning>
                                                {
                                                    new()
                                                    {
                                                        NameId = data.DebtorId,
                                                        Severity = AlertSeverity.UserError,
                                                        WarningError = $"Draft bill(s) exist for this debtor: {data.OtherDraftBillOpenItemNo}"
                                                    }
                                                }
                                            },
                                            debtorDetail.DebtorList.Single(), "Single Debtor Foreign Case, Debtor Detail");
        }

        [Test]
        public void PickCaseWithStatusRestrictedForBilling()
        {
            var data = DbSetup.Do(x =>
            {
                var billingData = new DraftBillDataSetup().Setup(x.DbContext);

                var status = x.InsertWithNewId(new Status
                {
                    Name = RandomString.Next(20),
                    PreventBilling = true
                });

                billingData.CaseLocalSingle.StatusCode = status.Id;
                billingData.CaseLocalSingle.CurrentOfficialNumber = RandomString.Next(20);

                x.DbContext.SaveChanges();

                return new
                {
                    billingData.EntityId,
                    BillSourceCountryCode = billingData.EntityCountry,
                    RaisedByStaffId = billingData.User.Id,
                    Case = billingData.CaseLocalSingle,
                    CaseOpenAction = billingData.LatestOpenActionByCase[billingData.CaseLocalSingle.Id],
                    RestrictedForBillingStatus = status
                };
            });

            var caseSummary = BillingService.GetCases(new CasesController.CaseRequest
            {
                CaseIds = $"{data.Case.Id}",
                EntityId = data.EntityId,
                RaisedByStaffId = data.RaisedByStaffId
            });

            CommonAssert.CaseDataAreEqual(new CaseData
                                          {
                                              CaseId = data.Case.Id,
                                              Title = data.Case.Title,
                                              OfficialNumber = data.Case.CurrentOfficialNumber,
                                              OpenAction = data.CaseOpenAction,
                                              CaseStatus = data.RestrictedForBillingStatus.Name,
                                              BillSourceCountryCode = data.BillSourceCountryCode,
                                              HasRestrictedStatusForBilling = true,
                                              IsMainCase = false
                                          },
                                          caseSummary.CaseList.Single(), "Case Summary");

            CommonAssert.CaseDataAreEqual(new CaseData
                                          {
                                              CaseId = data.Case.Id,
                                              Title = data.Case.Title,
                                              OfficialNumber = data.Case.CurrentOfficialNumber,
                                              CaseStatus = data.RestrictedForBillingStatus.Name
                                          },
                                          caseSummary.RestrictedCaseList.Single(), "Restricted Case Data");

            var restrictedCases = BillingService.GetCasesRestrictedForBilling(data.Case.Id);

            CommonAssert.CaseDataAreEqual(new CaseData
                                          {
                                              CaseId = data.Case.Id,
                                              Title = data.Case.Title,
                                              OfficialNumber = data.Case.CurrentOfficialNumber,
                                              CaseStatus = data.RestrictedForBillingStatus.Name
                                          },
                                          restrictedCases.CaseList.Single(), "Restricted For Billing Case");
        }

        [Test]
        public void CheckCaseHasPrepaymentRestriction()
        {
            var data = DbSetup.Do(x =>
            {
                var billingData = new DraftBillDataSetup().Setup(x.DbContext);

                var status = x.InsertWithNewId(new Status
                {
                    Name = RandomString.Next(20),
                    PreventPrepayment = true
                });

                billingData.CaseLocalSingle.StatusCode = status.Id;
                billingData.CaseLocalSingle.CurrentOfficialNumber = RandomString.Next(20);

                x.DbContext.SaveChanges();

                return new
                {
                    CaseWithRestriction = billingData.CaseLocalSingle,
                    CaseWithoutRestriction = billingData.CaseForeignMultiple
                };
            });
            
            Assert.IsTrue(BillingService.HasPrepaymentRestriction(data.CaseWithRestriction.Id), "Case has prepayment restriction");

            Assert.IsFalse(BillingService.HasPrepaymentRestriction(data.CaseWithoutRestriction.Id), "Case does not have prepayment restriction");
        }

        [Test]
        public void PickCaseWithUnpostedTime()
        {
            var data = DbSetup.Do(x =>
            {
                var billingData = new DraftBillDataSetup().Setup(x.DbContext);

                var caseId = billingData.CaseLocalSingle.Id;
                var staffId = billingData.StaffName.Id;
                var sc1 = billingData.ServiceCharge1;
                var sc2 = billingData.ServiceCharge2;

                var diary1 = new DiaryBuilder(x.DbContext).Create(staffId, 0, DateTime.Today, caseId, null, sc1.WipCode, localValue: 1000);
                var diary2 = new DiaryBuilder(x.DbContext).Create(staffId, 1, DateTime.Today, caseId, null, sc2.WipCode, localValue: 2000);

                x.DbContext.SaveChanges();

                return new
                {
                    billingData.EntityId,
                    BillSourceCountryCode = billingData.EntityCountry,
                    RaisedByStaffId = billingData.User.Id,
                    Case = billingData.CaseLocalSingle,
                    CaseInstructorId = billingData.CaseLocalSingle.Instructor().NameId,
                    CaseInstructorName = billingData.CaseLocalSingle.Instructor().Name.Formatted(),
                    CaseOpenAction = billingData.LatestOpenActionByCase[billingData.CaseLocalSingle.Id],
                    UnpostedTime = new[] {diary1, diary2}
                };
            });

            var caseSummary = BillingService.GetCases(new CasesController.CaseRequest
            {
                CaseIds = $"{data.Case.Id}",
                EntityId = data.EntityId,
                RaisedByStaffId = data.RaisedByStaffId
            });

            CommonAssert.CaseDataAreEqual(new CaseData
                                          {
                                              CaseId = data.Case.Id,
                                              Title = data.Case.Title,
                                              OfficialNumber = data.Case.CurrentOfficialNumber,
                                              OpenAction = data.CaseOpenAction,
                                              BillSourceCountryCode = data.BillSourceCountryCode,
                                              IsMainCase = false,
                                              UnpostedTimeList = new List<CaseUnpostedTime>
                                              {
                                                  new()
                                                  {
                                                      Name = data.CaseInstructorName,
                                                      NameId = data.CaseInstructorId,
                                                      StartTime = data.UnpostedTime.First().StartTime.GetValueOrDefault(),
                                                      TimeValue = data.UnpostedTime.First().TimeValue.GetValueOrDefault(),
                                                      TotalTime = data.UnpostedTime.First().TotalTime.GetValueOrDefault()
                                                  },
                                                  new()
                                                  {
                                                      Name = data.CaseInstructorName,
                                                      NameId = data.CaseInstructorId,
                                                      StartTime = data.UnpostedTime.Last().StartTime.GetValueOrDefault(),
                                                      TimeValue = data.UnpostedTime.Last().TimeValue.GetValueOrDefault(),
                                                      TotalTime = data.UnpostedTime.Last().TotalTime.GetValueOrDefault()
                                                  }
                                              }
                                          },
                                          caseSummary.CaseList.Single(), "Case Summary");
        }

        [Test]
        public void PickCaseDebtorsLanguageBasedOnBestFit()
        {
            var data = DbSetup.Do(x =>
            {
                var billingData = new DraftBillDataSetup().Setup(x.DbContext);

                var currentOpenActionForCase = billingData.LatestOpenActionByCase[billingData.CaseForeignMultiple.Id];

                var debtor1 = billingData.CaseForeignMultiple.Debtor1().Name;

                var languages = x.DbContext.Set<TableCode>()
                                 .Where(_ => _.TableTypeId == (short) TableTypes.Language)
                                 .ToDictionary(k => k.Id, v => v.Name);

                var languageForCurrentOpenAction = x.InsertWithNewId(
                                                                     new NameLanguage
                                                                     {
                                                                         NameId = debtor1.Id,
                                                                         LanguageId = languages.ElementAt(0).Key,
                                                                         ActionId = currentOpenActionForCase
                                                                     }, _ => _.Sequence);

                var languageWithoutAction = x.InsertWithNewId(
                                                              new NameLanguage
                                                              {
                                                                  NameId = debtor1.Id,
                                                                  LanguageId = languages.ElementAt(2).Key
                                                              }, _ => _.Sequence);

                x.DbContext.SaveChanges();

                return new
                {
                    billingData.EntityId,
                    RaisedByStaffId = billingData.User.Id,
                    Case = billingData.CaseForeignMultiple,
                    DebtorId = debtor1.Id,
                    CurrentActionId = languageForCurrentOpenAction.ActionId,
                    CurrentActionLanguage = languageForCurrentOpenAction.LanguageId,
                    DefaultLanguageId = languageWithoutAction.LanguageId
                };
            });

            var debtorsNoAction = BillingService.GetDebtor(data.DebtorId, null, null, null, false, data.RaisedByStaffId, data.EntityId, null, DateTime.Today);

            var debtorsCurrentAction = BillingService.GetDebtor(data.DebtorId, data.Case.Id, null,
                                                                data.CurrentActionId,
                                                                false, data.RaisedByStaffId, data.EntityId, null, DateTime.Today);

            Assert.AreEqual(data.DefaultLanguageId, debtorsNoAction.LanguageId, "Should falls back to Name's language default when Case and Action not provided");

            Assert.AreEqual(data.CurrentActionLanguage, debtorsCurrentAction.LanguageId, $"Should use the current action {data.CurrentActionLanguage} specified");
        }

        [Test]
        public void ReturnsMainContactWhenCopiesToIsChangedManually()
        {
            var data = DbSetup.Do(x =>
            {
                var billingData = new DraftBillDataSetup().Setup(x.DbContext);
                
                /*
                 * When manually selecting a name for the bill to be copied to,
                 * the name will not have any rules to derive contact from, except from the main contact set against the name.
                 */
                var copiesToContact = new NameBuilder(x.DbContext).CreateClientIndividual("cc-contact");
                var copiesTo = new NameBuilder(x.DbContext).CreateClientOrg("cc-org");

                copiesTo.MainContactId = copiesToContact.Id;
                
                x.DbContext.SaveChanges();

                return new
                {
                    DebtorId = billingData.CaseLocalSingle.Debtor1().NameId,
                    DebtorName = billingData.CaseLocalSingle.Debtor1().Name.Formatted(NameStyles.FirstNameThenFamilyName),
                    CopiesToNameId = copiesTo.Id,
                    AddressId = copiesTo.PostalAddressId,
                    CopiesToContactNameId = copiesToContact.Id,
                    CopiesToName = copiesTo.Formatted(NameStyles.FirstNameThenFamilyName),
                    CopiesToContactName = copiesToContact.Formatted(NameStyles.FirstNameThenFamilyName)
                };
            });

            var actualCopiesTo = BillingService.GetCopiesToContactDetails(data.DebtorId, data.CopiesToNameId);

            Assert.AreEqual(data.DebtorId, actualCopiesTo.DebtorNameId, $"Copies To - {nameof(data.DebtorId)}");
            Assert.AreEqual(data.CopiesToContactName, actualCopiesTo.ContactName, $"Copies To - {nameof(data.CopiesToContactName)}");
            Assert.AreEqual(data.CopiesToContactNameId, actualCopiesTo.ContactNameId, $"Copies To - {nameof(data.CopiesToContactNameId)}");
            Assert.AreEqual(data.CopiesToNameId, actualCopiesTo.CopyToNameId, $"Copies To - {nameof(data.CopiesToNameId)}");
            Assert.AreEqual(data.AddressId, actualCopiesTo.AddressId, $"Copies To - {nameof(data.AddressId)}");
        }
    }
}