using Inprotech.Infrastructure.Security;
using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.EndToEnd.Portfolio.PriorArt.Maintenance;
using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.Utils;
using NUnit.Framework;
using OpenQA.Selenium;

namespace Inprotech.Tests.Integration.EndToEnd.Portfolio.PriorArt
{
    [Category(Categories.E2E)]
    [TestFixture]
    [TestFrom(DbCompatLevel.Release16)]
    class Literature : IntegrationTest
    {
        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.FireFox)]
        [TestCase(BrowserType.Ie)]
        public void LiteratureSearch(BrowserType browserType)
        {
            var data = new PriorArtDataSetup().CreateData();
            var literature = (InprotechKaizen.Model.PriorArt.PriorArt)data.NonPatentLiterature;
            var user = new Users().WithPermission(ApplicationTask.MaintainPriorArt, Allow.Create).Create();

            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, $"/#/priorart", user.Username, user.Password);
            var baseUrl = driver.Url;
            var priorArtPage = new PriorArtPageObjects(driver);
            priorArtPage.LiteratureButton.WithJs().Click();
            priorArtPage.Title.SendKeys("literature");

            priorArtPage.SearchButton.Click();

            var searchResults = priorArtPage.LiteratureGrid;
            Assert.AreEqual(1, searchResults.Rows.Count);
            Assert.AreEqual(literature.Description, searchResults.CellText(0, "Description"));
            Assert.AreEqual(literature.Title, searchResults.CellText(0, "Title of Article/Item"));
            Assert.AreEqual(literature.Publisher, searchResults.CellText(0, "Publisher"));
            priorArtPage.ClickAction(searchResults, 0, "edit");
            PriorArtMaintenanceHelper.CheckMaintenanceTab(driver, literature.Description);

            driver.Url = baseUrl + $"?caseKey={data.Case.Id}";
            priorArtPage = new PriorArtPageObjects(driver);
            priorArtPage.LiteratureButton.WithJs().Click();
            priorArtPage.Title.SendKeys("literature");

            priorArtPage.SearchButton.Click();
            searchResults = priorArtPage.LiteratureGrid;
            priorArtPage.ClickAction(searchResults, 0, "cite");
            driver.WaitForAngularWithTimeout();
            Assert.AreEqual("The selected reference has been successfully cited.", priorArtPage.MessageDiv.Text, "Expected NPL to be cited against case");

            priorArtPage.ClickAction(searchResults, 0, "edit");
            PriorArtMaintenanceHelper.CheckMaintenanceTab(driver, literature.Description, data.Case.Irn);

            driver.Url = baseUrl + $"?sourceId={data.Source.Id}";
            priorArtPage = new PriorArtPageObjects(driver);
            priorArtPage.LiteratureButton.WithJs().Click();
            priorArtPage.Title.SendKeys("literature");

            priorArtPage.SearchButton.Click();
            searchResults = priorArtPage.LiteratureGrid;
            priorArtPage.ClickAction(searchResults, 0, "cite");
            driver.WaitForAngularWithTimeout();
            Assert.AreEqual("The selected reference has been successfully cited.", priorArtPage.MessageDiv.Text, "Expected NPL to be cited against source");
            
            priorArtPage.ClickAction(searchResults, 0, "edit");
            PriorArtMaintenanceHelper.CheckMaintenanceTab(driver, literature.Description);

            driver.Url = baseUrl + $"?sourceId={data.Source.Id}&caseKey={data.Case.Id}";
            priorArtPage = new PriorArtPageObjects(driver);
            priorArtPage.LiteratureButton.WithJs().Click();
            priorArtPage.Title.SendKeys("literature");

            priorArtPage.SearchButton.Click();
            var citeIcon = searchResults.RowElement(0, By.Name("cite")).FindElement(By.CssSelector("div button"));
            Assert.True(citeIcon.GetAttribute("disabled")=="true", "Expected NPL to already be cited");

            priorArtPage.LiteratureGrid.ToggleDetailsRow(0);
            var detailSection = new PriorArtPageObjects.DetailSection(driver, priorArtPage.LiteratureGrid, 0);
            detailSection.GenerateDescription();

            var publishDate = literature.PublishedDate.GetValueOrDefault().ToString("dd-MMM-yyyy");
            var newDescription = $"{literature.Name}, {literature.Title}, {publishDate}, {literature.Publisher}, {literature.Country.Name}";
            Assert.AreEqual(newDescription, detailSection.Description.WithJs().GetValue(), "Expected Description to be generated from details");
            detailSection.SaveButton.Click();

            priorArtPage.SearchButton.Click();
            searchResults = priorArtPage.LiteratureGrid;
            Assert.AreEqual(newDescription, searchResults.CellText(0, "Description"), "Expected auto-generated Description to be displayed in search results");

            priorArtPage.LiteratureGrid.ToggleDetailsRow(0);
            detailSection = new PriorArtPageObjects.DetailSection(driver, priorArtPage.LiteratureGrid, 0);
            Assert.AreEqual(newDescription, detailSection.Description.WithJs().GetValue(), "Expected generated Description to be saved.");

            priorArtPage = new PriorArtPageObjects(driver);
            priorArtPage.Title.Clear();
            priorArtPage.Title.SendKeys("literature title adding default title");
            priorArtPage.SearchButton.Click();
            priorArtPage.AddLiterature.Click();
            var newLiteratureDetailSection = new PriorArtPageObjects.DetailSection(driver);
            newLiteratureDetailSection.Description.SendKeys("adding literature description");
            newLiteratureDetailSection.SaveButton.Click();
            detailSection = new PriorArtPageObjects.DetailSection(driver, priorArtPage.LiteratureGrid, 0);
            Assert.AreEqual("adding literature description", detailSection.Description.WithJs().GetValue(), "Expected new literature description to be saved.");
            Assert.AreEqual("literature title adding default title", detailSection.Title.WithJs().GetValue(), "Expected new literature title to be save with defaulted title.");

            priorArtPage.Title.Clear();
            priorArtPage.SearchButton.Click();
            priorArtPage.AddLiterature.Click();
            newLiteratureDetailSection = new PriorArtPageObjects.DetailSection(driver);
            newLiteratureDetailSection.Name.SendKeys("New-NPL Name");
            newLiteratureDetailSection.Title.SendKeys("New-NPL Title");
            newLiteratureDetailSection.Publisher.SendKeys("New-NPL Publisher");
            detailSection.SaveButton.Click();
            detailSection = new PriorArtPageObjects.DetailSection(driver, priorArtPage.LiteratureGrid, 0);
            Assert.AreEqual("New-NPL Name, New-NPL Title, New-NPL Publisher", detailSection.Description.WithJs().GetValue(), "Expected new auto-generated literature description to be saved.");

            priorArtPage.ClickAction(priorArtPage.LiteratureGrid, 0, "edit");
            PriorArtMaintenanceHelper.CheckMaintenanceTab(driver, "New-NPL Name, New-NPL Title, New-NPL Publisher", data.Case.Irn);
        }
    }
}