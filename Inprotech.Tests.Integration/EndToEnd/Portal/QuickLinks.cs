using System.Collections.ObjectModel;
using System.Linq;
using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.PageObjects;
using InprotechKaizen.Model.Configuration;
using InprotechKaizen.Model.Security;
using NUnit.Framework;
using OpenQA.Selenium;
using Protractor;
using QuickLinkSliderPageObject = Inprotech.Tests.Integration.PageObjects.QuickLinks;

namespace Inprotech.Tests.Integration.EndToEnd.Portal
{
    [Category(Categories.E2E)]
    [TestFixture]
    public class QuickLinks : IntegrationTest
    {
        [SetUp]
        public void RemoveAllExistingLinks()
        {
            DbSetup.Do(_ =>
            {
                _.DbContext.RemoveRange(_.DbContext.Set<Link>());
                _.DbContext.SaveChanges();
            });
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.FireFox)]
        [TestCase(BrowserType.Ie)]
        public void InternalUserLinks(BrowserType browserType)
        {
            var internalUser = new Users().Create();
            DbSetup.Do(x =>
            {
                var q = x.DbContext.Set<TableCode>().Single(_ => _.Id == (int)LinksCategory.Quicklinks);
                x.Insert(new Link(q, "ipplatform.com", "IP Platform", displaySequence: 1));
            });

            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, "/#/portal2", internalUser.Username, internalUser.Password);

            driver.With<QuickLinkSliderPageObject>(slider =>
            {
                slider.Open("links");

                driver.With<QuickLinksPageObject>(page =>
                {
                    Assert.AreEqual(1, page.Groups.Count, "Should only contain one group");

                    Assert.AreEqual("Quick Links", page.GroupName(0), $"Should have quick links group, but got {page.GroupName(0)}");

                    Assert.AreEqual(1, page.LinksForGroup(0).Count, "Should only contain one link");

                    Assert.AreEqual("IP Platform", page.LinksForGroup(0)[0].Text, "Should only contain link 'IP Platfrom'");

                    Assert.AreEqual("http://ipplatform.com/", page.LinksForGroup(0)[0].GetAttribute("href"), "Should point the link to 'http://ipplatform.com'");
                });

                slider.Close();
            });

            DbSetup.Do(x =>
            {
                var m = x.DbContext.Set<TableCode>().Single(_ => _.Id == (int)LinksCategory.MyLinks);
                var u = x.DbContext.Set<User>().Single(_ => _.Id == internalUser.Id);

                x.Insert(new Link(m, "https://jira.cpaglobal.com", "JIRA", displaySequence: 1, user: u));
            });

            ReloadPage(driver);

            driver.With<QuickLinkSliderPageObject>(slider =>
            {
                slider.Open("links");

                driver.With<QuickLinksPageObject>(page =>
                {
                    Assert.AreEqual(2, page.Groups.Count, "Should only contain one group");

                    Assert.AreEqual("My Links", page.GroupName(0), "Should have my links group as the first group");

                    Assert.AreEqual(1, page.LinksForGroup(0).Count, "Should only contain one link");

                    Assert.AreEqual("JIRA", page.LinksForGroup(0)[0].Text, "Should only contain link 'JIRA'");

                    Assert.AreEqual("https://jira.cpaglobal.com/", page.LinksForGroup(0)[0].GetAttribute("href"), "Should point the link to 'https://jira.cpaglobal.com'");

                    Assert.AreEqual("Quick Links", page.GroupName(1), "Should have quick links group as the second group");

                    Assert.AreEqual(1, page.LinksForGroup(1).Count, "Should only contain one link");

                    Assert.AreEqual("IP Platform", page.LinksForGroup(1)[0].Text, "Should only contain link 'IP Platfrom'");

                    Assert.AreEqual("http://ipplatform.com/", page.LinksForGroup(1)[0].GetAttribute("href"), "Should point the link to 'http://ipplatform.com'");
                });

                slider.Close();
            });

            DbSetup.Do(x =>
            {
                var quickLinks = x.DbContext.Set<Link>().Where(_ => _.CategoryId == (int)LinksCategory.Quicklinks);
                x.DbContext.RemoveRange(quickLinks);
                x.DbContext.SaveChanges();
            });

            ReloadPage(driver);

            driver.With<QuickLinkSliderPageObject>(slider =>
            {
                slider.Open("links");

                driver.With<QuickLinksPageObject>(page =>
                {
                    Assert.AreEqual(1, page.Groups.Count, "Should only contain one group");

                    Assert.AreEqual("My Links", page.GroupName(0), "Should have my links group as the first group");

                    Assert.AreEqual(1, page.LinksForGroup(0).Count, "Should only contain one link");

                    Assert.AreEqual("JIRA", page.LinksForGroup(0)[0].Text, "Should only contain link 'JIRA'");

                    Assert.AreEqual("https://jira.cpaglobal.com/", page.LinksForGroup(0)[0].GetAttribute("href"), "Should point the link to 'https://jira.cpaglobal.com'");
                });

                slider.Close();
            });
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.FireFox)]
        [TestCase(BrowserType.Ie)]
        public void ExternalUserLinks(BrowserType browserType)
        {
            var externalUser = new Users().CreateExternalUser();
            DbSetup.Do(x =>
            {
                var q = x.DbContext.Set<TableCode>().Single(_ => _.Id == (int)LinksCategory.Quicklinks);
                x.Insert(new Link(q, "ipplatform.com", "IP Platform", displaySequence: 1, isExternal: true));
            });

            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, "/#/portal2", externalUser.Username, externalUser.Password);

            driver.With<QuickLinkSliderPageObject>(slider =>
            {
                slider.Open("links");

                driver.With<QuickLinksPageObject>(page =>
                {
                    Assert.AreEqual(1, page.Groups.Count, "Should only contain one group");

                    Assert.AreEqual("Quick Links", page.GroupName(0), $"Should have quick links group, but got {page.GroupName(0)}");

                    Assert.AreEqual(1, page.LinksForGroup(0).Count, "Should only contain one link");

                    Assert.AreEqual("IP Platform", page.LinksForGroup(0)[0].Text, "Should only contain link 'IP Platfrom'");

                    Assert.AreEqual("http://ipplatform.com/", page.LinksForGroup(0)[0].GetAttribute("href"), "Should point the link to 'http://ipplatform.com'");
                });

                slider.Close();
            });

            DbSetup.Do(x =>
            {
                var a = x.DbContext.Set<AccessAccount>().Single(_ => _.Id == externalUser.AccessAccountId);
                var q = x.DbContext.Set<TableCode>().Single(_ => _.Id == (int)LinksCategory.Quicklinks);
                var u = x.DbContext.Set<User>().Single(_ => _.Id == externalUser.Id);

                x.Insert(new Link(q, "https://jira.cpaglobal.com", "JIRA", displaySequence: 1, user: u, accessAccount: a));
            });

            ReloadPage(driver);

            driver.With<QuickLinkSliderPageObject>(slider =>
            {
                slider.Open("links");

                driver.With<QuickLinksPageObject>(page =>
                {
                    Assert.AreEqual(1, page.Groups.Count, "Should only contain one group");

                    Assert.AreEqual("Quick Links", page.GroupName(0), $"Should have quick links group, but got {page.GroupName(0)}");

                    Assert.AreEqual(1, page.LinksForGroup(0).Count, "Should only contain one link");

                    Assert.AreEqual("JIRA", page.LinksForGroup(0)[0].Text, "Should only contain link 'JIRA'");

                    Assert.AreEqual("https://jira.cpaglobal.com/", page.LinksForGroup(0)[0].GetAttribute("href"), "Should point the link to 'https://jira.cpaglobal.com'");
                });

                slider.Close();
            });

            DbSetup.Do(x =>
            {
                var m = x.DbContext.Set<TableCode>().Single(_ => _.Id == (int)LinksCategory.MyLinks);
                var u = x.DbContext.Set<User>().Single(_ => _.Id == externalUser.Id);

                x.Insert(new Link(m, "https://confluence.cpaglobal.com", "Confluence", displaySequence: 1, user: u));
            });

            ReloadPage(driver);

            driver.With<QuickLinkSliderPageObject>(slider =>
            {
                slider.Open("links");

                driver.With<QuickLinksPageObject>(page =>
                {
                    Assert.AreEqual(2, page.Groups.Count, "Should only contain one group");

                    Assert.AreEqual("My Links", page.GroupName(0), "Should have my links group as the first group");

                    Assert.AreEqual(1, page.LinksForGroup(0).Count, "Should only contain one link");

                    Assert.AreEqual("Confluence", page.LinksForGroup(0)[0].Text, "Should only contain link 'Confluence'");

                    Assert.AreEqual("https://confluence.cpaglobal.com/", page.LinksForGroup(0)[0].GetAttribute("href"), "Should point the link to 'https://confluence.cpaglobal.com'");

                    Assert.AreEqual("Quick Links", page.GroupName(1), "Should have quick links group as the second group");

                    Assert.AreEqual(1, page.LinksForGroup(1).Count, "Should only contain one link");

                    Assert.AreEqual("JIRA", page.LinksForGroup(1)[0].Text, "Should only contain link 'JIRA'");

                    Assert.AreEqual("https://jira.cpaglobal.com/", page.LinksForGroup(1)[0].GetAttribute("href"), "Should point the link to 'https://jira.cpaglobal.com'");
                });

                slider.Close();
            });
        }
    }

    public class QuickLinksPageObject : PageObject
    {
        public QuickLinksPageObject(NgWebDriver driver) : base(driver)
        {
            Container = Driver.FindElement(By.Id("user-quick-links"));
        }

        public ReadOnlyCollection<NgWebElement> Groups => Driver.FindElements(By.CssSelector("h3.groupHeader"));

        public ReadOnlyCollection<NgWebElement> LinksForGroup(int index)
        {
            return Driver.FindElements(By.XPath("//div[@id='user-quick-links']/ul["+(index+1)+"]/li[1]/a"));
        }

        public string GroupName(int index)
        {
            return Groups[index].Text;
        }
    }
}