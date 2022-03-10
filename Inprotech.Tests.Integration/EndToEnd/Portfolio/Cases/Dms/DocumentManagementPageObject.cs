using System.Collections.ObjectModel;
using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.PageObjects;
using OpenQA.Selenium;
using Protractor;

namespace Inprotech.Tests.Integration.EndToEnd.Portfolio.Cases.Dms
{
    public class DocumentManagementPageObject : PageObject
    {
        public DocumentManagementPageObject(NgWebDriver driver) : base(driver)
        {
        }

        public DocumentGrid Documents => new DocumentGrid(Driver);
        public ButtonInput OpenIniManageLink => new ButtonInput(Driver).ById("openIniManage");
        public NgWebElement ErrorMessage => Driver.FindElement(By.CssSelector("ipx-inline-alert"));
        public TreeView DirectoryTreeView => new TreeView(Driver);

        public ReadOnlyCollection<NgWebElement> IrnLabel => Driver.FindElements(By.Name("caseReference"));
        public ReadOnlyCollection<NgWebElement> PropertyTypeLabel => Driver.FindElements(By.Name("propertyTypeDescription"));
        public ReadOnlyCollection<NgWebElement> CaseTypeLabel => Driver.FindElements(By.Name("caseTypeDescription"));
        public ReadOnlyCollection<NgWebElement> CountryAdjectiveLabel => Driver.FindElements(By.Name("countryAdjective"));
        public ReadOnlyCollection<NgWebElement> CaseStatusLabel => Driver.FindElements(By.Name("caseStatusDescription"));

        public NgWebElement LoginOauth2Alert => Driver.FindElement(By.CssSelector("ipx-inline-alert"));

        public class DocumentGrid : AngularKendoGrid
        {
            readonly NgWebDriver _driver;

            public DocumentGrid(NgWebDriver driver) : base(driver, "dmsDocuments")
            {
                _driver = driver;
            }

            public void ExpandRow(int rowNumber)
            {
                Cell(rowNumber, 0).FindElement(By.CssSelector("a")).ClickWithTimeout();
            }

            public DocumentDetail DocumentDetail(int rowNumber)
            {
                var detailRow = DetailRows[rowNumber];
                return new DocumentDetail(_driver, detailRow);
            }
        }
    }

    public class DocumentDetail : PageObject
    {
        readonly NgWebElement _self;

        public DocumentDetail(NgWebDriver driver, NgWebElement detailRow) : base(driver, detailRow)
        {
            _self = detailRow;
        }

        public NgWebElement Comments => _self.FindElement(By.CssSelector("textarea"));

        public ReadOnlyCollection<NgWebElement> RelatedDocuments => _self.FindElements(By.CssSelector("tbody > tr"));

        public NgWebElement Cell(int row, int col)
        {
            return _self.FindElements(By.TagName("tbody > tr"))[row].FindElements(By.TagName("td"))[col];
        }
    }
}