using System;
using System.Linq;
using Inprotech.Infrastructure;
using Inprotech.Infrastructure.Security;
using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.DbHelpers.Builders;
using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.Utils;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Cases.Events;
using InprotechKaizen.Model.Components.Names;
using InprotechKaizen.Model.Configuration.SiteControl;
using InprotechKaizen.Model.Names;
using InprotechKaizen.Model.Queries;
using InprotechKaizen.Model.Rules;
using NUnit.Framework;
using OpenQA.Selenium;
using Protractor;
using Action = InprotechKaizen.Model.Cases.Action;

namespace Inprotech.Tests.Integration.EndToEnd.Search.Case
{
    [Category(Categories.E2E)]
    [TestFixture]
    public class CasePreview : IntegrationTest
    {
        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void CasePreviewDetails(BrowserType browserType)
        {
            var user = new Users().WithPermission(ApplicationTask.ShowLinkstoWeb).Create();

            var @case = DbSetup.Do(setup =>
            {
                setup.Insert(new QueryContent {ColumnId = -39, ContextId = 2, DisplaySequence = 1, PresentationId = -2});

                var irnPrefix = Fixture.AlphaNumericString(10);
                var c = new CaseBuilder(setup.DbContext).Create(irnPrefix);

                c.Title = Fixture.String(5);

                var mainRenewalActionSiteControl = setup.DbContext.Set<SiteControl>().Single(_ => _.ControlId == SiteControls.MainRenewalAction);
                var renewalAction = setup.DbContext.Set<Action>().Single(_ => _.Code == mainRenewalActionSiteControl.StringValue);
                var criticalDatesSiteControl = setup.DbContext.Set<SiteControl>().Single(_ => _.ControlId == SiteControls.CriticalDates_Internal);
                var criticalDatesCriteria = setup.DbContext.Set<Criteria>().First(_ => _.ActionId == criticalDatesSiteControl.StringValue);

                setup.Insert(new OpenAction(renewalAction, c, 1, null, criticalDatesCriteria, true));
                setup.Insert(new CaseEvent(c.Id, (int) KnownEvents.NextRenewalDate, 1) {EventDueDate = DateTime.Today.AddDays(-1), IsOccurredFlag = 0, CreatedByCriteriaKey = criticalDatesCriteria.Id});

                return c;
            });

            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, $"/#/search-result?queryContext=2&q={@case.Irn}", user.Username, user.Password);

            var searchPage = new SearchPageObject(driver);

            var grid = searchPage.ResultGrid;

            Assert.IsFalse(driver.FindElements(By.Id("casePreviewPane")).Any());

            var namelink = grid.Cell(0, "Instructor").FindElements(By.CssSelector("ipx-ie-only-url a")).SingleOrDefault();
            Assert.NotNull(namelink);
            Assert.True(namelink.Text.Equals(@case.CaseNames.Single(_ => _.NameTypeId == KnownNameTypes.Instructor).Name.FormattedNameOrNull()));

            searchPage.TogglePreviewSwitch.Click();
            Assert.IsTrue(driver.FindElement(By.Id("casePreviewPane")).WithJs().IsVisible());

            grid.ClickRow(0);

            CheckCaseDetails(driver, new[] {@case}, true);
            /*
            var nextRenewalDate = @case.CaseEvents.Single(_ => _.EventNo == (int)KnownEvents.NextRenewalDate).EventDueDate.GetValueOrDefault();

            var previewPage = new CasePreviewPageObject(driver);
            var nextRenewalDateEl = previewPage.DatesContainer.FindElement(By.CssSelector(".criticalDateField ip-due-date span.text-red-dark"));
            Assert.AreEqual(nextRenewalDate.ToString("yyyy-MM-dd"), DateTime.Parse(nextRenewalDateEl.Text).ToString("yyyy-MM-dd"), "Overdue Next renewal due date is displayed");

            var colour = nextRenewalDateEl.GetCssValue("color");
            var rgb = colour.Substring(5, colour.Length - 6).Split(',').Select(_ => int.Parse(_.Trim())).ToArray();
            Assert.True(rgb[0] > rgb[1] && rgb[0] > rgb[2], "Red is the predominant colour");
            */
            searchPage.TogglePreviewSwitch.Click();

            Assert.IsFalse(driver.FindElements(By.Id("casePreviewPane")).Any());
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.FireFox)]
        [TestCase(BrowserType.Ie)]
        public void TogglePreview(BrowserType browserType)
        {
            var user = new Users().WithPermission(ApplicationTask.ShowLinkstoWeb).Create();

            var data = DbSetup.Do(setup =>
            {
                var casePrefix = Fixture.UriSafeString(3);

                var property = setup.InsertWithNewId(new PropertyType
                {
                    Name = RandomString.Next(5)
                }, x => x.Code);

                var case1 = new CaseBuilder(setup.DbContext).Create(casePrefix + "1", true, propertyType: property);
                var case2 = new CaseBuilder(setup.DbContext).Create(casePrefix + "2", true, propertyType: property);
                var case3 = new CaseBuilder(setup.DbContext).Create(casePrefix + "3", true, propertyType: property);

                case1.Title = Fixture.String(5);
                case2.Title = Fixture.String(5);
                case3.Title = Fixture.String(5);
                setup.DbContext.SaveChanges();

                return new
                {
                    CasePrefix = casePrefix,
                    Cases = new[] {case1, case2, case3}
                };
            });

            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, $"/#/search-result?queryContext=2&q={data.CasePrefix}", user.Username, user.Password);

            var searchPage = new SearchPageObject(driver);

            var grid = searchPage.ResultGrid;
            
            Assert.IsFalse(driver.FindElements(By.Id("casePreviewPane")).Any());

            searchPage.TogglePreviewSwitch.Click();

            Assert.IsTrue(driver.FindElement(By.Id("casePreviewPane")).WithJs().IsVisible());

            grid.ClickRow(0);
            CheckCaseDetails(driver, data.Cases, true);

            grid.ClickRow(1);
            CheckCaseDetails(driver, data.Cases, true);

            grid.ClickRow(2);
            CheckCaseDetails(driver, data.Cases, true);

            searchPage.TogglePreviewSwitch.Click();
            
            Assert.IsFalse(driver.FindElements(By.Id("casePreviewPane")).Any());
        }

        static void CheckCaseDetails(NgWebDriver driver, InprotechKaizen.Model.Cases.Case[] cases, bool checkWebLinks = false)
        {
            driver.WaitForAngularWithTimeout();

            var previewPage = new CasePreviewPageObject(driver);

            var header = previewPage.Header;
            var curCase = cases.Single(_ => header.Contains(_.Irn));

            Assert.IsTrue(header.Contains(curCase.Title));

            var texts = previewPage.Texts.ToArray();

            Assert.IsTrue(texts.Contains(curCase.Country.Name));
            Assert.IsTrue(texts.Contains(curCase.Type.Name));

            var names = previewPage.Names.ToArray();
            var instructor = curCase.CaseNames.Single(_ => _.NameTypeId == KnownNameTypes.Instructor).Name.FormattedNameOrNull();

            Assert.IsTrue(names.Any(_ => _.Contains(instructor)));

            if (checkWebLinks)
            {
                var ipOnlyUrls = driver.FindElements(By.CssSelector("ipx-ie-only-url a")).Select(ia => ia.Text).ToArray();
                Assert.IsNotEmpty(ipOnlyUrls);

                foreach (var t in ipOnlyUrls) Assert.True(names.Any(n => n.Contains(t)), "Link is not displayed for " + t);
            }
        }
    }
}