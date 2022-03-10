using System.Windows.Input;
using Inprotech.Infrastructure.Security;
using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.EndToEnd.Portfolio.PriorArt.Maintenance;
using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.Utils;
using Inprotech.Web.Configuration.Jurisdictions;
using NUnit.Framework;
using OpenQA.Selenium;

namespace Inprotech.Tests.Integration.EndToEnd.Portfolio.PriorArt
{
    [Category(Categories.E2E)]
    [TestFixture]
    [TestFrom(DbCompatLevel.Release16)]
    class PriorArt : IntegrationTest
    {
        [TestCase(BrowserType.Chrome)]
        public void PriorArtDetails(BrowserType browserType)
        {
            var setup = new PriorArtDataSetup();
            var data = setup.CreateData();
            var user = new Users().WithPermission(ApplicationTask.MaintainPriorArt, Allow.Create).Create();

            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, $"/#/priorart", user.Username, user.Password);
            var priorArtPage = new PriorArtPageObjects(driver);

            Assert.AreEqual("Prior Art", priorArtPage.PageTitle(), "Page title should be Prior Art");

            SignIn(driver, $"/#/priorart?sourceId=" + data.Source.Id + "&caseKey=" + data.Case.Id, user.Username, user.Password);
            Assert.True(priorArtPage.CaseAndSourceDetails.Displayed, "should not display info if case and source not passed");

            Assert.AreEqual(data.Case.Irn.ToString(), priorArtPage.CaseName.WithJs().GetInnerText(), "Case name should be case IRN number");
            Assert.AreEqual($"{data.Source.SourceType.Name} - {data.Source.IssuingCountryId} ({data.Source.Description})", priorArtPage.SourceName.WithJs().GetInnerText(), "Source name should have jurisdiction and desc if applied");
        }

        [TestCase(BrowserType.Chrome)]
        public void PriorArtSearchAndCancelDetails(BrowserType browserType)
        {
            var setup = new PriorArtDataSetup();
            var data = setup.CreateData();
            var user = new Users().WithPermission(ApplicationTask.MaintainPriorArt, Allow.Create).Create();

            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, $"/#/priorart", user.Username, user.Password);
            var priorArtPage = new PriorArtPageObjects(driver);

            Assert.False(priorArtPage.SearchButton.Enabled, "Should not enable the search button");

            priorArtPage.Jurisdiction.SendKeys(data.searchOption.Country);
            priorArtPage.ApplicationNo.SendKeys(data.searchOption.Number);
            Assert.True(priorArtPage.SearchButton.Enabled, "Should enable the search button");

            priorArtPage.ClearButton.Click();
            Assert.False(priorArtPage.SearchButton.Enabled, "Should disable the search button after pressing the Clear button.");

            priorArtPage.Jurisdiction.SendKeys(data.searchOption.Country);
            priorArtPage.ApplicationNo.SendKeys(data.searchOption.Number);
            priorArtPage.KindCode.SendKeys(data.searchOption.KindCode);
            priorArtPage.SearchButton.Click();

            Assert.True(priorArtPage.PriorArtGrid.Grid.Displayed, "Search grid is showing");
            Assert.AreEqual(2, priorArtPage.PriorArtGrid.Rows.Count, "Prior art grid should show only 1 Inprotech row and only 1 Ip1D row");

            priorArtPage.PriorArtGrid.ToggleDetailsRow(1);
            var detailSection = new PriorArtPageObjects.DetailSection(driver, priorArtPage.PriorArtGrid, 0);

            Assert.AreNotEqual(string.Empty, detailSection.Abstract, "Details should contain abstract details");
            Assert.AreNotEqual(string.Empty, detailSection.PublishedDate, "Details should contain published Date details");

            priorArtPage.PriorArtGrid.ToggleDetailsRow(0);
            var paDetailSection = new PriorArtPageObjects.DetailSection(driver, priorArtPage.PriorArtGrid, 0);

            Assert.AreNotEqual(string.Empty, paDetailSection.Comment, "Details should contain abstract details");

            Assert.True(priorArtPage.CaseGrid.Grid.Displayed, "Search grid is showing");
            Assert.AreEqual(1, priorArtPage.CaseGrid.Rows.Count, "Prior art grid should show only 1 Inprotech row");

            priorArtPage.CaseGrid.ToggleDetailsRow(0);
            var caseDetailSection = new PriorArtPageObjects.DetailSection(driver, priorArtPage.CaseGrid, 0);

            Assert.AreNotEqual(string.Empty, caseDetailSection.Title, "Details should contain abstract details");

            priorArtPage.CancelButton.Click();
            Assert.AreEqual(string.Empty, priorArtPage.Jurisdiction.GetText(), "Jurisdiction must be cleared");
            Assert.AreEqual(string.Empty, priorArtPage.KindCode.Text, "Kind Code must be cleared");
            Assert.AreEqual(string.Empty, priorArtPage.ApplicationNo.Text, "Application number must be cleared");

            priorArtPage.Jurisdiction.SendKeys(data.searchOption.Country);
            priorArtPage.ApplicationNo.SendKeys("123456789");
            priorArtPage.SearchButton.Click();

            Assert.True(priorArtPage.NotFoundGrid.Grid.Displayed, "Search grid is showing");
            Assert.AreEqual(1, priorArtPage.NotFoundGrid.Rows.Count, "Not Found Grid art grid should show only 1 Inprotech row");
            Assert.True(priorArtPage.NotFoundGrid.HasExpandRow(0), "Shows Expand Icon");
            priorArtPage.NotFoundGrid.ExpandRow(0);
            driver.WaitForAngular();
        }

        [TestCase(BrowserType.Chrome)]
        public void SaveExistingPriorArtDetails(BrowserType browserType)
        {
            var setup = new PriorArtDataSetup();
            var data = setup.CreateData();
            var user = new Users().WithPermission(ApplicationTask.MaintainPriorArt, Allow.Create).Create();

            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, $"/#/priorart", user.Username, user.Password);
            var priorArtPage = new PriorArtPageObjects(driver);
            priorArtPage.Jurisdiction.SendKeys(data.searchOption.Country);
            priorArtPage.ApplicationNo.SendKeys(data.searchOption.Number);
            priorArtPage.KindCode.SendKeys(data.searchOption.KindCode);
            priorArtPage.SearchButton.Click();

            Assert.True(priorArtPage.PriorArtGrid.Grid.Displayed, "Search grid is showing");
            Assert.AreEqual(2, priorArtPage.PriorArtGrid.Rows.Count, "Prior art grid should show only 1 Inprotech row and only 1 Ip1D row");

            priorArtPage.PriorArtGrid.ToggleDetailsRow(0);
            var detailInprotechSection = new PriorArtPageObjects.DetailSection(driver, priorArtPage.PriorArtGrid, 0);
            detailInprotechSection.Title.SendKeys("test title");
            detailInprotechSection.SaveButton.Click();
            driver.WaitForAngularWithTimeout();
            Assert.AreEqual("Your changes have been successfully saved.", priorArtPage.MessageDiv.Text);

            detailInprotechSection.Title.SendKeys("save with revert");
            detailInprotechSection.Title.SendKeys(Keys.Alt + Keys.Shift + Key.Z);
            detailInprotechSection.Title.SendKeys("save with short cut");
            detailInprotechSection.Title.SendKeys(Keys.Alt + Keys.Shift + Key.S);
            driver.WaitForAngularWithTimeout();
            Assert.AreEqual("Your changes have been successfully saved.", priorArtPage.MessageDiv.Text);
        }

        [TestCase(BrowserType.Chrome)]
        public void ImportPriorArtDetails(BrowserType browserType)
        {
            var setup = new PriorArtDataSetup();
            var data = setup.CreateData();
            var user = new Users().WithPermission(ApplicationTask.MaintainPriorArt, Allow.Create).Create();

            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, $"/#/priorart", user.Username, user.Password);
            var priorArtPage = new PriorArtPageObjects(driver);
            priorArtPage.Jurisdiction.SendKeys(data.searchOption.Country);
            priorArtPage.ApplicationNo.SendKeys(data.searchOption.Number);
            priorArtPage.KindCode.SendKeys(data.searchOption.KindCode);
            priorArtPage.SearchButton.Click();

            Assert.AreEqual(2, priorArtPage.PriorArtGrid.Rows.Count, "Prior art grid should show only 1 Inprotech row and only 1 Ip1D row");
            Assert.True(priorArtPage.PriorArtGrid.RowElement(1, By.XPath("//button/ipx-icon/span[contains(@class,'cpa-icon cpa-icon-check-in')]")).Enabled);

            priorArtPage.PriorArtGrid.ToggleDetailsRow(1);
            var priorArtDetails = new PriorArtPageObjects.DetailSection(driver, priorArtPage.PriorArtGrid, 0);
            var datePicker = priorArtDetails.PriorityDate;
            datePicker.Input.SendKeys("12/12/12");
            datePicker.Input.SendKeys(Keys.Tab);
            var priorityDate = datePicker.Value;

            datePicker = priorArtDetails.ApplicationFilingDate;
            datePicker.Input.Clear();
            datePicker.Input.SendKeys("12/12/13");
            datePicker.Input.SendKeys(Keys.Tab);
            var applicationFilingDate = datePicker.Value;

            datePicker = priorArtDetails.Published;
            datePicker.Input.Clear();
            datePicker.Input.SendKeys("12/12/14");
            datePicker.Input.SendKeys(Keys.Tab);
            var publishedDate = datePicker.Value;

            datePicker = priorArtDetails.GrantedDate;
            datePicker.Input.Clear();
            datePicker.Input.SendKeys("12/12/15");
            datePicker.Input.SendKeys(Keys.Tab);
            var grantedDate = datePicker.Value;

            datePicker = priorArtDetails.PtoCited;
            datePicker.Input.Clear();
            datePicker.Input.SendKeys("12/12/16");
            datePicker.Input.SendKeys(Keys.Tab);
            var ptoCited = datePicker.Value;
            
            priorArtPage.PriorArtGrid.RowElement(1, By.XPath("//button/ipx-icon/span[contains(@class,'cpa-icon cpa-icon-check-in')]")).Click();
            priorArtPage.ProceedIpOneData();

            priorArtPage.SearchButton.Click();
            driver.WaitForAngularWithTimeout();
            Assert.AreEqual(3, priorArtPage.PriorArtGrid.Rows.Count, "Prior art grid should show Ip One imported row");

            priorArtPage.PriorArtGrid.ToggleDetailsRow(0);
            priorArtDetails = new PriorArtPageObjects.DetailSection(driver, priorArtPage.PriorArtGrid, 0);
            Assert.AreEqual(priorityDate, priorArtDetails.PriorityDate.Value, "Expected Priority Date selected to be saved correctly");
            Assert.AreEqual(applicationFilingDate, priorArtDetails.ApplicationFilingDate.Value, "Expected Application Date selected to be saved correctly");
            Assert.AreEqual(publishedDate, priorArtDetails.Published.Value, "Expected Published Date selected to be saved correctly");
            Assert.AreEqual(grantedDate, priorArtDetails.GrantedDate.Value, "Expected Granted Date selected to be saved correctly");
            Assert.AreEqual(ptoCited, priorArtDetails.PtoCited.Value, "Expected Pto Cited Date selected to be saved correctly");

            var description = priorArtDetails.Title.Value();
            priorArtPage.PriorArtGrid.ToggleDetailsRow(0);
            priorArtPage.ClickAction(priorArtPage.PriorArtGrid, 0, "edit");
            PriorArtMaintenanceHelper.CheckMaintenanceTab(driver, description);
        }

        [TestCase(BrowserType.Chrome)]
        public void CitePriorArt(BrowserType browserType)
        {
            var setup = new PriorArtDataSetup();
            var data = setup.CreateData();
            var user = new Users().WithPermission(ApplicationTask.MaintainPriorArt, Allow.Create).Create();

            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, $"/#/priorart?sourceId=" + data.Source.Id + "&caseKey=" + data.Case.Id, user.Username, user.Password);
            var priorArtPage = new PriorArtPageObjects(driver);
            priorArtPage.Jurisdiction.SendKeys(data.searchOption.Country);
            priorArtPage.ApplicationNo.SendKeys(data.searchOption.Number);
            priorArtPage.KindCode.SendKeys(data.searchOption.KindCode);
            priorArtPage.SearchButton.Click();

            Assert.AreEqual(2, priorArtPage.PriorArtGrid.Rows.Count, "Prior art grid should show only 1 Inprotech row and only 1 Ip1D row");
            Assert.True(priorArtPage.PriorArtGrid.RowElement(0, By.XPath("//button/ipx-icon/span[contains(@class,'cpa-icon cpa-icon-link')]")).Enabled);

            priorArtPage.ClickAction(priorArtPage.PriorArtGrid, 0, "cite");

            driver.WaitForAngularWithTimeout();
            Assert.AreEqual("The selected reference has been successfully cited.", priorArtPage.MessageDiv.Text);
        }

        [TestCase(BrowserType.Chrome)]
        public void SearchSource(BrowserType browserType)
        {
            var setup = new PriorArtDataSetup();
            var data = setup.CreateData();
            var user = new Users().WithPermission(ApplicationTask.MaintainPriorArt, Allow.Create).Create();

            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, $"/#/priorart?sourceId=&caseKey=" + data.Case.Id, user.Username, user.Password);
            var priorArtPage = new PriorArtPageObjects(driver);
            Assert.False(priorArtPage.SearchButton.Enabled, "Search Button is disabled because IPO has required filters");
            priorArtPage.SourceButton.WithJs().Click();
            driver.WaitForAngular();
            Assert.True(priorArtPage.SearchButton.Enabled, "Search Button is enabled because source has no required filters");
            priorArtPage.Jurisdiction.EnterAndSelect(data.searchOption.Country);
            priorArtPage.SearchButton.Click();

            var resultsGrid = priorArtPage.SourceSearchResultsGrid;
            Assert.AreEqual(1, resultsGrid.Rows.Count, "Prior art grid should show only 1 source row");
            Assert.AreEqual(data.Source.SourceType.Name, resultsGrid.Cell(0, 0).Text);
            Assert.AreEqual(data.Source.IssuingCountry.Name, resultsGrid.Cell(0, 1).Text);
            Assert.AreEqual(data.Source.Description, resultsGrid.Cell(0, 2).Text);

            priorArtPage.ClickAction(resultsGrid, 0, "edit");
            PriorArtMaintenanceHelper.CheckMaintenanceTab(driver, data.Source.Description, data.Case.Irn);
        }

        [TestCase(BrowserType.Chrome)]
        public void CiteSource(BrowserType browserType)
        {
            var setup = new PriorArtDataSetup();
            var data = setup.CreateData(false);
            var user = new Users().WithPermission(ApplicationTask.MaintainPriorArt, Allow.Create).Create();

            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, $"/#/priorart?sourceId=&caseKey=" + data.Case.Id, user.Username, user.Password);
            var priorArtPage = new PriorArtPageObjects(driver);
            Assert.False(priorArtPage.SearchButton.Enabled, "Search Button is disabled because IPO has required filters");
            priorArtPage.SourceButton.WithJs().Click();
            driver.WaitForAngular();
            Assert.True(priorArtPage.SearchButton.Enabled, "Search Button is enabled because source has no required filters");
            priorArtPage.Jurisdiction.EnterAndSelect(data.searchOption.Country);
            priorArtPage.SearchButton.Click();

            var resultsGrid = priorArtPage.SourceSearchResultsGrid;
            Assert.AreEqual(1, resultsGrid.Rows.Count, "Prior art grid should show only 1 source row");
            Assert.AreEqual(data.Source.SourceType.Name, resultsGrid.Cell(0, 0).Text);
            Assert.AreEqual(data.Source.IssuingCountry.Name, resultsGrid.Cell(0, 1).Text);
            Assert.AreEqual(data.Source.Description, resultsGrid.Cell(0, 2).Text);

            priorArtPage.ClickAction(resultsGrid, 0, "cite");
            driver.WaitForAngularWithTimeout();
            Assert.AreEqual("The selected reference has been successfully cited.", priorArtPage.MessageDiv.Text);
        }

        [TestCase(BrowserType.Chrome)]
        public void PriorArtMultiSearch(BrowserType browserType)
        {
            var setup = new PriorArtDataSetup();
            var data = setup.CreateData();
            var user = new Users().WithPermission(ApplicationTask.MaintainPriorArt, Allow.Create).Create();
            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, $"/#/priorart", user.Username, user.Password);
            var priorArtPage = new PriorArtPageObjects(driver);

            Assert.True(priorArtPage.SingleRadioButton.IsChecked, "The search should default to single request search.");

            priorArtPage.MultipleRadioButton.Click();

            Assert.True(priorArtPage.MultiSearchText.Displayed, "The search should show the multi search text field after changing search type.");

            var multiRequest = data.Case.Country.Id + '-' + data.Case.CurrentOfficialNumber + ';' + data.Ipo.IssuingCountry.Id + '-' + data.Ipo.OfficialNumber + '-' + data.Ipo.Kind;
            var notFounds = "CN-1;CN-2;CN-3;CN-4;CN-5;CN-6;CN-7;CN-8;CN-9;CN-10";
            multiRequest = multiRequest + ';' + notFounds;
            priorArtPage.MultiSearchText.SendKeys(multiRequest);
            priorArtPage.SearchButton.Click();

            Assert.AreEqual(3, priorArtPage.PriorArtGrid.Rows.Count, "Ensure the correct number of rows return.");
            Assert.AreEqual(10, priorArtPage.NotFoundGrid.Rows.Count, "Ensure the correct number of rows return on first page.");
            Assert.AreEqual(1, priorArtPage.CaseGrid.Rows.Count, "Ensure the correct number of rows return.");
            
            priorArtPage.NotFoundGrid.PageNext();

            Assert.AreEqual(1, priorArtPage.NotFoundGrid.Rows.Count, "Ensure paged correctly.");

            priorArtPage.NotFoundGrid.PagePrev();
            priorArtPage.NotFoundGrid.Headers[1].FindElement(By.TagName("span")).Click();

            Assert.AreEqual("1", priorArtPage.NotFoundGrid.Cell(0,1).Text, "Ensure the page is correctly sorted.");
        }
    }
}