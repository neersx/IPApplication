using System;
using System.Linq;
using Inprotech.Infrastructure.Security;
using Inprotech.Integration.Schedules;
using Inprotech.Integration.Uspto.PrivatePair.Sponsorships;
using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.PageObjects;
using Inprotech.Tests.Integration.Utils;
using NUnit.Framework;
using OpenQA.Selenium;

namespace Inprotech.Tests.Integration.EndToEnd.Integration.PtoAccess.Uspto
{
    [TestFixture]
    [Category(Categories.E2E)]
    [RebuildsIntegrationDatabase]
    [ChangeAppSettings(AppliesTo.InprotechServer, "InnographyOverrides:pp", "http://localhost/e2e/")]
    [ChangeAppSettings(AppliesTo.IntegrationServer, "InnographyOverrides:pp", "http://localhost/e2e/")]
    public class PrivatePairSponsorshipAndSchedule : IntegrationTest
    {
        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie, Ignore = "e2e-flaky: DR-54709")]
        [TestCase(BrowserType.FireFox)]
        public void SettingUpUsptoDataDownloadJob(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);
            var user = new Users()
                       .WithPermission(ApplicationTask.ConfigureUsptoPractitionerSponsorship)
                       .WithPermission(ApplicationTask.ScheduleUsptoPrivatePairDataDownload)
                       .Create();

            SignIn(driver, "/#/integration/ptoaccess/uspto-private-pair-sponsorships", user.Username, user.Password);

            driver.With<SponsorshipsPageObject>(page =>
            {
                Assert.AreEqual(0, page.Sponsorships.Rows.Count, "Should not have any sponsorship initially");
                page.AddSponsorship();
            });

            var fixture = new
            {
                SponsoredEmail = RandomString.Next(6) + "@cpaglobal.com",
                Password = RandomString.Next(20),
                AuthenticatorKey = RandomString.Next(12),
                CustomerNumbers = string.Join(", ", Fixture.Integer().ToString()),
                Name = RandomString.Next(10)
            };

            driver.With<NewSponsorshipPageObject>(page =>
            {
                page.Email.Input.SendKeys(fixture.SponsoredEmail);
                page.Name.Input.SendKeys(fixture.Name);
                page.CustomerNumbers.Input.SendKeys(fixture.CustomerNumbers);
                page.Password.Input.SendKeys(fixture.Password);
                page.AuthenticatorKey.Input.SendKeys(fixture.AuthenticatorKey);
                page.Apply();
            });

            IntegrationDbSetup.WaitForAny<Sponsorship>();

            IntegrationDbSetup.Do(x =>
            {
                var sponsorship = x.IntegrationDbContext.Set<Sponsorship>().Single();

                Assert.AreEqual(fixture.SponsoredEmail, sponsorship.SponsoredAccount, "Should have the same sponsored account");
                Assert.AreEqual(fixture.CustomerNumbers, sponsorship.CustomerNumbers, "Should have the same customer numbers");
                Assert.AreEqual(fixture.Name, sponsorship.SponsorName, "Should have the same sponsored name");
            });

            driver.With<SponsorshipsPageObject>(page =>
            {
                driver.Wait().ForTrue(() => page.Sponsorships.Rows.Count == 1);
                page.AddSponsorship();
            });

            driver.With<NewSponsorshipPageObject>((newSponsorshipPage, popup) =>
            {
                newSponsorshipPage.Email.Input.SendKeys(fixture.SponsoredEmail);
                newSponsorshipPage.Name.Input.SendKeys(fixture.Name);
                newSponsorshipPage.CustomerNumbers.Input.SendKeys(fixture.CustomerNumbers);
                newSponsorshipPage.Password.Input.SendKeys(fixture.Password);
                newSponsorshipPage.AuthenticatorKey.Input.SendKeys(fixture.AuthenticatorKey);
                newSponsorshipPage.Apply();

                popup.AlertModal.Ok();
                newSponsorshipPage.Close();
                popup.DiscardChangesModal.Discard();
            });

            driver.With<SponsorshipsPageObject>(page =>
            {
                Assert.AreEqual(1, page.Sponsorships.Rows.Count, "Should still display the saved sponsorships");
                page.EditSponsorshipByRowIndex(0);
            });

            var newCustomerNumber = Fixture.Integer().ToString();

            driver.With<NewSponsorshipPageObject>(updateSponsorshipPage =>
            {
                updateSponsorshipPage.Password.Input.SendKeys(fixture.Password);
                updateSponsorshipPage.CustomerNumbers.Input.SendKeys(",");
                updateSponsorshipPage.CustomerNumbers.Input.SendKeys(newCustomerNumber);
                updateSponsorshipPage.Apply();
            });

            IntegrationDbSetup.WaitForAny<Sponsorship>(x => x.CustomerNumbers != fixture.CustomerNumbers);

            driver.With<SponsorshipsPageObject>(page =>
            {
                Assert.AreEqual(1, page.Sponsorships.Rows.Count, "Should now display the saved sponsorships");

                var sponsorshipDetails = page.AllSponsorshipSummary().Single();

                Assert.AreEqual(fixture.CustomerNumbers + ", " + newCustomerNumber, string.Join(",", sponsorshipDetails.CustomerNumbers), "Should display all customer numbers");

                page.ViewSchedules();
            });

            driver.With<SchedulesPageObject>(page =>
            {
                Assert.AreEqual(0, page.Schedules.Rows.Count, "Should not have any schedules initially");

                page.NewSchedule();
            });

            driver.With<NewPrivatePairSchedulePageObject>(page =>
            {
                page.ScheduleName.Input.SendKeys(fixture.Name);
                Assert.Throws<NoSuchElementException>(() => page.ContinuousOption.Click());
                page.DataSourceType.Input.SelectByText("USPTO Private PAIR");
                Assert.True(page.ContinuousOption.IsDisplayed);
                page.Apply();

                IntegrationDbSetup.WaitForAny<Schedule>(s => s.Name == fixture.Name);
            });

            driver.With<SchedulesPageObject>(page =>
            {
                Assert.AreEqual(1, page.AllScheduleSummary().Count(_ => _.Source == "USPTO Private PAIR"), "Should have a private pair schedule created");
            });

            driver.Visit("/#/integration/ptoaccess/uspto-private-pair-sponsorships");

            driver.With<SponsorshipsPageObject>(page =>
            {
                Assert.AreEqual(1, page.Sponsorships.Rows.Count, "Should still display the saved sponsorships");

                page.DeleteSponsorshipByRowIndex(0);

                page.ViewSchedules();
            });

            driver.With<SchedulesPageObject>(page =>
            {
                Assert.True(page.AllScheduleSummary().Any(), "Should retain private pair schedules for new sponsors to be added.");
            });
        }
    }
}