using System.Linq;
using Inprotech.Infrastructure.Security.Licensing;
using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.Extensions;
using InprotechKaizen.Model.Accounting.OpenItem;
using NUnit.Framework;

namespace Inprotech.Tests.Integration.IntegrationTests.Accounting.Billing.Validations
{
    [Category(Categories.Integration)]
    [TestFixture]
    public class OpenItems : IntegrationTest
    {
        [TearDown]
        public void CleanUpModifiedData()
        {
            AccountingDbHelper.Cleanup();
        }

        [Test]
        public void ItemNumberIsUnique()
        {
            new Users().WithLicense(LicensedModule.Billing).Create();

            var existingOpenItemNo = DbSetup.Do(x => x.DbContext.Set<OpenItem>().First().OpenItemNo);

            Assert.IsFalse(BillingService.ValidateIfOpenItemUnique(existingOpenItemNo), "Should return not unique if it is an existing open item no");

            Assert.IsTrue(BillingService.ValidateIfOpenItemUnique(RandomString.Next(20)), "Should return unique if it is a new open item no");
        }
    }
}