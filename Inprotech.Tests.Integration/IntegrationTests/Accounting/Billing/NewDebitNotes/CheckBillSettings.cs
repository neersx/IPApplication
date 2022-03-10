using System;
using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.DbHelpers.Builders.Accounting;
using InprotechKaizen.Model.Accounting;
using InprotechKaizen.Model.Accounting.Billing;
using InprotechKaizen.Model.Components.Accounting.Billing;
using InprotechKaizen.Model.Components.Accounting.Billing.Items;
using NUnit.Framework;

namespace Inprotech.Tests.Integration.IntegrationTests.Accounting.Billing.NewDebitNotes
{
    [Category(Categories.Integration)]
    [TestFixture]
    public class CheckBillSettings : IntegrationTest
    {
        // TODO Settings related to Exchange Integration is missing.

        [TearDown]
        public void CleanUpModifiedData()
        {
            AccountingDbHelper.Cleanup();
        }

        [Test]
        public void AllSiteSettingsAreConsidered()
        {
            var billingData = new DraftBillDataSetup().Setup();

            var settings = BillingService.GetSettings();

            var openItemModel = BillingService.GetDefaultOpenItem(ItemTypesForBilling.DebitNote);

            Assert.AreEqual(billingData.EntityId, openItemModel.ItemEntityId, "ItemEntityId is HOMENAMENO if Inter Entity Billing is false, otherwise null.");
            Assert.AreEqual(billingData.EntityId, openItemModel.AccountEntityId, "AccountEntityId is HOMENAMENO if Inter Entity Billing is false, otherwise null.");
            Assert.AreEqual(billingData.Today, openItemModel.ItemDate.Date, "ItemDate");
            Assert.AreEqual((int) TransactionStatus.Draft, openItemModel.Status, "ItemStatus");
            Assert.AreEqual(billingData.StaffProfitCentre.Id, openItemModel.StaffProfitCentre, "StaffProfitCentre");
            Assert.AreEqual(billingData.StaffProfitCentre.Name, openItemModel.StaffProfitCentreDescription, "StaffProfitCentreDescription");
            Assert.AreEqual((bool) settings["Site"]["BillRenewalDebtor"], openItemModel.CanUseRenewalDebtor, "Site Settings 'BillRenewalDebtor' should be the same as 'CanUseRenewalDebtor'");
        }

        [Test]
        public void BillingRulesForMinimumNetBill()
        {
            var data = DbSetup.Do(x =>
            {
                var billingData = new DraftBillDataSetup().Setup(x.DbContext);

                /* by default there is a 100 minimum net bill rule against local clients with MYAC. */

                var anotherOpenAction = new OpenActionBuilder(x.DbContext).CreateInDb(billingData.CaseLocalSingle, DateTime.Today.AddDays(-10));

                /* 
                 * if CaseLocalSingle's debtor is passed in with CaseLocalSingle,
                 * the rule will derive most recent action.
                 * There is no other bill rule with that most recent action set, this will return in that case.
                 */
                x.InsertWithNewId(new BillRule
                {
                    RuleTypeId = BillRuleType.MinimumNetBill,
                    EntityId = billingData.EntityId,
                    LocalClientFlag = 1,
                    CaseTypeId = billingData.CaseLocalSingle.TypeId,
                    MinimumNetBill = 200
                }, _ => _.RuleId);

                /* 
                 * if CaseLocalSingle's debtor is passed in with CaseLocalSingle,
                 * the rule will derive most recent action.
                 * if this action is passed then this is the better match rule.
                 */
                x.InsertWithNewId(new BillRule
                {
                    RuleTypeId = BillRuleType.MinimumNetBill,
                    EntityId = billingData.EntityId,
                    LocalClientFlag = 1,
                    CaseTypeId = billingData.CaseLocalSingle.TypeId,
                    CaseActionId = anotherOpenAction.ActionId,
                    MinimumNetBill = 400
                }, _ => _.RuleId);

                /* 
                 * This is the better match rule for foreign debtors
                 */
                x.InsertWithNewId(new BillRule
                {
                    RuleTypeId = BillRuleType.MinimumNetBill,
                    LocalClientFlag = 0,
                    MinimumNetBill = 1000
                }, _ => _.RuleId);

                return new
                {
                    billingData.EntityId,
                    billingData.ServiceCharge1.WipCode,

                    LocalCaseId = billingData.CaseLocalSingle.Id,
                    LocalCaseTypeId = billingData.CaseLocalSingle.TypeId,
                    LocalCaseDebtor1 = billingData.CaseLocalSingle.Debtor1().NameId,
                    LocalCaseNotMostRecentOpenAction = anotherOpenAction.ActionId,

                    AnotherCaseDebtorId = billingData.CaseLocalMultiple.Debtor1().NameId,
                    AnotherCaseId = billingData.CaseLocalMultiple.Id,

                    ForeignCaseId = billingData.CaseForeignMultiple.Id,
                    ForeignCaseDebtorId = billingData.CaseForeignMultiple.Debtor1().NameId
                };
            });

            var defaultRule = BillingService.GetBillRules(data.AnotherCaseDebtorId, data.AnotherCaseId, data.EntityId);

            CommonAssert.BillRuleIsEqual(new BillSettings
            {
                MinimumNetBill = 100
            }, defaultRule, "Resolves default rule because another case did not match any more specific attributes in all other rules");

            var caseTypeRule = BillingService.GetBillRules(data.LocalCaseDebtor1, data.LocalCaseId, data.EntityId);

            CommonAssert.BillRuleIsEqual(new BillSettings
            {
                MinimumNetBill = 200
            }, caseTypeRule, "Resolves case type rule because the case's most recent action does not match the caseTypeCaseAction rule's action attribute");

            var caseTypeCaseActionRule = BillingService.GetBillRules(data.LocalCaseDebtor1, data.LocalCaseId, data.EntityId, data.LocalCaseNotMostRecentOpenAction);

            CommonAssert.BillRuleIsEqual(new BillSettings
            {
                MinimumNetBill = 400
            }, caseTypeCaseActionRule, "Resolves case type case action rule as action is not passed in");

            var nonLocalClientRule = BillingService.GetBillRules(data.ForeignCaseDebtorId, data.ForeignCaseId);

            CommonAssert.BillRuleIsEqual(new BillSettings
            {
                MinimumNetBill = 1000
            }, nonLocalClientRule, "Resolves rule for local client flag is 0");
        }
    }
}