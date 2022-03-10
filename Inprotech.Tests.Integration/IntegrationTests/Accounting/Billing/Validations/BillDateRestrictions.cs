using System;
using System.Linq;
using Inprotech.Infrastructure;
using Inprotech.Infrastructure.Security.Licensing;
using Inprotech.Tests.Integration.DbHelpers;
using InprotechKaizen.Model.Accounting;
using InprotechKaizen.Model.Components.Accounting.Billing;
using InprotechKaizen.Model.Configuration.SiteControl;
using NUnit.Framework;

namespace Inprotech.Tests.Integration.IntegrationTests.Accounting.Billing.Validations
{
    [Category(Categories.Integration)]
    [TestFixture]
    public class BillDateRestrictions : IntegrationTest
    {
        [TearDown]
        public void CleanUpModifiedData()
        {
            AccountingDbHelper.Cleanup();

            SiteControlRestore.ToDefault(SiteControls.BillDateOnlyFromToday,
                                         SiteControls.BillDateFutureRestriction);
        }

        [Test]
        public void ValidatesItemDateInThePast()
        {
            AccountingDbHelper.SetupPeriod();

            new Users().WithLicense(LicensedModule.Billing).Create();

            var yesterday = DateTime.Today.AddDays(-1);

            DbSetup.Do(x =>
            {
                var billDateForwardOnly = x.DbContext.Set<SiteControl>().Single(_ => _.ControlId == SiteControls.BillDateOnlyFromToday);
                
                billDateForwardOnly.BooleanValue = false;

                x.DbContext.SaveChanges();
            });

            var allowed = BillingService.ValidateItemDate(yesterday);

            Assert.IsFalse(allowed.HasError, "Should permit bill dates to be in the past as long as it is in an open accounting period");

            DbSetup.Do(x =>
            {
                var billDateForwardOnly = x.DbContext.Set<SiteControl>().Single(_ => _.ControlId == SiteControls.BillDateOnlyFromToday);
                
                billDateForwardOnly.BooleanValue = true;

                x.DbContext.SaveChanges();
            });

            var error = BillingService.ValidateItemDate(yesterday);

            Assert.IsTrue(error.HasError, "Should not permit bill dates to be in the past because 'BillDateOnlyFromToday' is set");
            Assert.AreEqual(error.FirstErrorDescription, "Bill dates in the past are not allowed.");
        }

        [Test]
        public void ValidatesItemDateInFutureAndInPeriodInWhichTodaysDateFalls()
        {
            AccountingDbHelper.SetupPeriod();

            new Users().WithLicense(LicensedModule.Billing).Create();

            var tomorrow = DateTime.Today.AddDays(1);
            
            DbSetup.Do(x =>
            {
                var billDateForwardOnly = x.DbContext.Set<SiteControl>().Single(_ => _.ControlId == SiteControls.BillDateOnlyFromToday);
                
                billDateForwardOnly.BooleanValue = true;

                var billDateFutureRestriction = x.DbContext.Set<SiteControl>().Single(_ => _.ControlId == SiteControls.BillDateFutureRestriction);

                billDateFutureRestriction.IntegerValue = (int) BillDateRestriction.OnlyFutureBillDateWithinSamePeriodAsTodayAllowed;

                x.DbContext.SaveChanges();
            });

            Period currentPeriod = null;
            var nextPeriodStart = DbSetup.Do(x =>
            {
                var today = DateTime.Today;
                currentPeriod = (from p in x.DbContext.Set<Period>()
                                     where p.StartDate <= today && p.EndDate >= today
                                     select p).Single();
                currentPeriod = (from p in x.DbContext.Set<Period>()
                                 where p.StartDate <= today && p.EndDate >= today
                                 select p).Single();

                return (from p in x.DbContext.Set<Period>()
                        where p.Id > currentPeriod.Id
                        orderby p.Id
                        select p.StartDate).First();
            });

            var allowed = BillingService.ValidateItemDate(currentPeriod.EndDate<tomorrow ? currentPeriod.EndDate : tomorrow);

            Assert.IsFalse(allowed.HasError, "Should permit if date is in the future and it is in the period in which today's date falls");
            
            var error = BillingService.ValidateItemDate(nextPeriodStart);
            
            Assert.IsTrue(error.HasError, "Should not permit bill dates to be in the future beyond the period where today's date fall because 'BillDateFutureRestriction' is 1");
            Assert.AreEqual(error.FirstErrorDescription, "Future bill dates are only allowed if the date is in the same period as the current date.");
        }

        [Test]
        public void ValidatesItemDateInFutureIfThePeriodIsOpen()
        {
            AccountingDbHelper.SetupPeriod();

            new Users().WithLicense(LicensedModule.Billing).Create();

            var nextPeriod = DbSetup.Do(x =>
            {
                var billDateForwardOnly = x.DbContext.Set<SiteControl>().Single(_ => _.ControlId == SiteControls.BillDateOnlyFromToday);
                
                billDateForwardOnly.BooleanValue = true;

                var billDateFutureRestriction = x.DbContext.Set<SiteControl>().Single(_ => _.ControlId == SiteControls.BillDateFutureRestriction);

                billDateFutureRestriction.IntegerValue = (int) BillDateRestriction.OnlyFutureBillDateWithinAnyOpenPeriodAllowed;
                
                x.DbContext.SaveChanges();

                var today = DateTime.Today;
                var currentPeriod = (from p in x.DbContext.Set<Period>()
                                     where p.StartDate <= today && p.EndDate >= today
                                     select p).Single();

                var n = (from p in x.DbContext.Set<Period>()
                                  where p.Id > currentPeriod.Id
                                  orderby p.Id
                                  select p).First();

                n.ClosedForModules = null;
                n.PostingCommenced = today;
                
                x.DbContext.SaveChanges();

                return n;
            });

            var allowed = BillingService.ValidateItemDate(nextPeriod.StartDate);

            Assert.IsFalse(allowed.HasError, "Should permit if date is in the future and the period is open");

            DbSetup.Do(x =>
            {
                var n = x.DbContext.Set<Period>().Single(_ => _.Id == nextPeriod.Id);

                n.ClosedForModules = SystemIdentifier.TimeAndBilling;

                x.DbContext.SaveChanges();
            });

            var error = BillingService.ValidateItemDate(nextPeriod.StartDate);
            
            Assert.IsTrue(error.HasError, "Should not permit bill dates to be in the future if period is closed for module because 'BillDateFutureRestriction' is 2");
            Assert.AreEqual(error.FirstErrorDescription, "The item date cannot be in the future period that is closed for the module.");
        }
    }
}