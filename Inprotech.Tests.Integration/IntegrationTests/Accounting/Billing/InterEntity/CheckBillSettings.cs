using System.Linq;
using Inprotech.Infrastructure;
using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.DbHelpers.Builders;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Accounting;
using InprotechKaizen.Model.Accounting.Billing;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Configuration.SiteControl;
using InprotechKaizen.Model.Names;
using NUnit.Framework;

namespace Inprotech.Tests.Integration.IntegrationTests.Accounting.Billing.InterEntity
{
    [Category(Categories.Integration)]
    [TestFixture]
    public class CheckBillSettings : IntegrationTest
    {
        [TearDown]
        public void CleanUpModifiedData()
        {
            AccountingDbHelper.Cleanup();
            
            SiteControlRestore.ToDefault(SiteControls.InterEntityBilling);
        }

        [Test]
        [InterEntityBilling]
        public void BillingRulesForBillingEntity()
        {
            var data = DbSetup.Do(x =>
            {
                new Users(x.DbContext).Create();

                var interEntityBilling = x.DbContext.Set<SiteControl>().Single(_ => _.ControlId == SiteControls.InterEntityBilling);
                interEntityBilling.BooleanValue = true;

                var entities = (from sn in x.DbContext.Set<SpecialName>()
                                join n in x.DbContext.Set<Name>() on sn.Id equals n.Id
                                where sn.IsEntity == 1
                                select new
                                {
                                    n.Id,
                                    n.NameCode
                                }).ToDictionary(k => k.Id, v => v.NameCode);

                var debtor1 = new NameBuilder(x.DbContext).CreateClientOrg("LOCAL-1");
                x.Insert(new ClientDetail(debtor1.Id) {LocalClientFlag = 1});

                var debtor2 = new NameBuilder(x.DbContext).CreateClientOrg("FOREIGN-1");
                x.Insert(new ClientDetail(debtor2.Id) {LocalClientFlag = 0});

                var debtorNameType = x.DbContext.Set<NameType>().Single(_ => _.NameTypeCode == KnownNameTypes.Debtor);

                var @case = new CaseBuilder(x.DbContext).Create("local", true, withDebtor: false);
                @case.CaseNames.Add(new CaseName(@case, debtorNameType, debtor1, 101) {BillingPercentage = 100});

                /* 
                 * The below should apply to any local debtors, and will post to first entity in entities.
                 */
                x.InsertWithNewId(new BillRule
                {
                    RuleTypeId = BillRuleType.BillingEntity,
                    BillingEntityId = entities.Keys.ElementAt(0),
                    LocalClientFlag = 1
                }, _ => _.RuleId);

                /* 
                 * The below should apply to any foreign debtors, and will post to second entity in entities.
                 */
                x.InsertWithNewId(new BillRule
                {
                    RuleTypeId = BillRuleType.BillingEntity,
                    BillingEntityId = entities.Keys.ElementAt(1)
                }, _ => _.RuleId);

                /* 
                 * Local client flag is unset, but the debtor for the case is local.
                 * Given case has precedence over local client flag when performing best fit, this will return for the case
                 */
                x.InsertWithNewId(new BillRule
                {
                    RuleTypeId = BillRuleType.BillingEntity,
                    CaseId = @case.Id,
                    BillingEntityId = entities.Keys.ElementAt(2)
                }, _ => _.RuleId);

                return new
                {
                    LocalDebtorId = debtor1.Id,
                    LocalDebtorEntityId = entities.Keys.ElementAt(0),
                    LocalDebtorEntityCode = entities[entities.Keys.ElementAt(0)],

                    ForeignDebtorId = debtor2.Id,
                    ForeignDebtorEntityId = entities.Keys.ElementAt(1),
                    ForeignDebtorEntityCode = entities[entities.Keys.ElementAt(1)],

                    LocalCaseId = @case.Id,
                    LocalCaseEntityId = entities.Keys.ElementAt(2),
                    LocalCaseEntityCode = entities[entities.Keys.ElementAt(2)]
                };
            });

            var ruleMatchesLocalDebtor = BillingService.GetBillRules(data.LocalDebtorId);
            Assert.AreEqual(data.LocalDebtorEntityId, ruleMatchesLocalDebtor.DefaultEntityId, $"Entity {data.LocalDebtorEntityCode} ({data.LocalDebtorEntityId}) should be picked because Local Client Flag is set and matches");

            var ruleMatchesForeignDebtor = BillingService.GetBillRules(data.ForeignDebtorId);
            Assert.AreEqual(data.ForeignDebtorEntityId, ruleMatchesForeignDebtor.DefaultEntityId, $"Entity {data.ForeignDebtorEntityCode} ({data.ForeignDebtorEntityId}) should be picked because Local Client Flag is unset and matches");

            var ruleMatchesCase = BillingService.GetBillRules(data.LocalDebtorId, data.LocalCaseId);

            Assert.AreEqual(data.LocalCaseEntityId, ruleMatchesCase.DefaultEntityId, $"Entity {data.LocalCaseEntityCode} ({data.LocalCaseEntityId}) should be picked because case matches and applies over Local Client Flag");
        }
    }
}