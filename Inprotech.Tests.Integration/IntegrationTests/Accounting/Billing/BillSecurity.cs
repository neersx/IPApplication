using System.Linq;
using Inprotech.Infrastructure;
using Inprotech.Infrastructure.Security;
using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.DbHelpers.Builders;
using InprotechKaizen.Model.Accounting;
using InprotechKaizen.Model.Configuration.SiteControl;
using NUnit.Framework;

namespace Inprotech.Tests.Integration.IntegrationTests.Accounting.Billing
{
    [Category(Categories.Integration)]
    [TestFixture]
    public class BillSecurity : IntegrationTest
    {
        [TearDown]
        public void CleanUpModifiedData()
        {
            SiteControlRestore.ToDefault(SiteControls.BillReversalDisabled);
        }

        [Test]
        public void SecurityPrivileges()
        {
            DbSetup.Do(x => new Users(x.DbContext)
                            .WithPermission(ApplicationTask.MaintainCreditNote, Allow.Create | Allow.Delete)
                            .WithPermission(ApplicationTask.MaintainDebitNote, Allow.Delete)
                            .Create());

            var result = BillingService.GetSettings(@"user");

            Assert.True((bool)result["User"]["CanDeleteDebitNote"], "CanDeleteDebitNote");
            Assert.True((bool)result["User"]["CanDeleteCreditNote"], "CanDeleteCreditNote");
            Assert.True((bool)result["User"]["CanCreditBill"], "CanCreditBill"); /* default rule has CreditBill access */
            Assert.True((bool)result["User"]["CanFinaliseBill"], "CanFinaliseBill"); /* default rule has FinaliseBill access */

            Assert.AreEqual((int)BillReversalTypeAllowed.ReversalAllowed, (int)result["User"]["CanReverseBill"], "CanReverseBill should be 0 when site control is indicated to allow reversal");
        }

        [Test]
        public void SiteControlledBillReversalSettings()
        {
            DbSetup.Do(x =>
            {
                new Users(x.DbContext)
                {
                    Name = new NameBuilder(x.DbContext).CreateStaff()
                }
                       .WithPermission(ApplicationTask.MaintainCreditNote, Allow.Delete)
                       .WithPermission(ApplicationTask.MaintainDebitNote, Allow.Delete)
                       .Create();

                var sc = x.DbContext.Set<SiteControl>().Single(_ => _.ControlId == SiteControls.BillReversalDisabled);
                sc.IntegerValue = (int)BillReversalTypeAllowed.ReversalNotAllowed;

                x.DbContext.SaveChanges();
            });

            var result = BillingService.GetSettings(@"user");

            Assert.AreEqual((int)BillReversalTypeAllowed.ReversalNotAllowed, (int)result["User"]["CanReverseBill"], "CanReverseBill should be 1 when site control is indicated to not allow reversal");
        }
    }
}