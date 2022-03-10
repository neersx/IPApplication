using System;
using System.Linq;
using Inprotech.Infrastructure;
using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.PageObjects.Modals;
using InprotechKaizen.Model.Configuration.SiteControl;
using NUnit.Framework;
using OpenQA.Selenium;
using Protractor;

namespace Inprotech.Tests.Integration.Extensions
{
    public static class PageObjectExtensions
    {
        public static void TestIeOnlyPopup(this CommonPopups popUps, string containsUrl)
        {
            Assert.NotNull(popUps.AlertModal);
            Assert.IsTrue(popUps.AlertModal.FindElements(By.TagName("span")).Any(_ => _.Text.Contains(containsUrl)));
            popUps.AlertModal.Ok();
        }

        public static void TestIeOnlyUrl(this NgWebElement caseRefLink, string containsUrl)
        {

            if (caseRefLink.TagName != "a")
                throw new Exception("Only links(a) are supported for IE urls");
            var driver = caseRefLink.CurrentDriver();

            if (VersionMatched())
            {
                if (driver.Is(BrowserType.Ie))
                {
                    var currentUrl = caseRefLink.GetAttribute("href");
                    Assert.IsTrue(currentUrl.Contains(containsUrl), $"Case ref is a hyper link connecting to {currentUrl} containing caseRef url: {containsUrl}");
                }
                else
                {
                    caseRefLink.ClickWithTimeout();
                    var popUps = new CommonPopups(driver);
                    Assert.NotNull(popUps.AlertModal);
                    Assert.IsTrue(popUps.AlertModal.FindElements(By.TagName("span")).Any(_ => _.Text.Contains(containsUrl)));
                    popUps.AlertModal.Ok();
                }
            }
            else
            {
                var currentUrl = caseRefLink.GetAttribute("href");
                Assert.IsTrue(currentUrl.Contains(containsUrl), $"Case ref is a hyper link connecting to {currentUrl} containing caseRef url: {containsUrl}");
            }
        }

        public static bool VersionMatched()
        {
            var shouldExecute = DbSetup.Do(x =>
            {
                var dbReleaseVersion = x.DbContext.Set<SiteControl>()
                                        .Single(_ => _.ControlId == SiteControls.DBReleaseVersion)
                                        .StringValue;
                return dbReleaseVersion.Contains("13") || dbReleaseVersion.Contains("14") || dbReleaseVersion.Contains("15");
            });

            if (shouldExecute)
            {
                return true;
            }

            return false;
        }
    }
}