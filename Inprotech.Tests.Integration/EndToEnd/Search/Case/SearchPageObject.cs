using System.Linq;
using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.PageObjects;
using InprotechKaizen.Model;
using OpenQA.Selenium;
using Protractor;

namespace Inprotech.Tests.Integration.EndToEnd.Search.Case
{
    public class SearchPageObject : PageObject
    {
        public SearchPageObject(NgWebDriver driver) : base(driver)
        {
        }

        public AngularKendoGrid ResultGrid => new AngularKendoGrid(Driver, "searchResults", "a123");

        public NgWebElement QuickSearchInput() => Driver.FindElement(By.CssSelector("ipx-quick-search input"));

        public NgWebElement QuickSearchSpan => Driver.FindElement(By.CssSelector("ipx-quick-search .quick-search-wrap-addon"));

        public string CaseSearchTotalRecords => Driver.FindElement(By.Id("caseSearchTotalRecords")).Text;
        public string CaseSearchTermLabel => Driver.FindElement(By.CssSelector("#quick-search-list ipx-page-title span.search-term")).Text;

        public NgWebElement TogglePreviewSwitch => Driver.FindElement(By.CssSelector("ipx-page-title action-buttons div.switch label"));
        public NgWebElement CloseButton() => Driver.FindElement(By.Id("closeSearch"));

        public NgWebElement TaskMenuButton(int rowIndex = 0) => ResultGrid.Cell(rowIndex, 1).FindElement(By.CssSelector("ipx-icon-button button.btn"));
        public NgWebElement CaseWebLinkTaskMenu => Driver.FindElement(By.Id("caseWebLinks"));
        public NgWebElement WebLinkGroupTaskMenu => Driver.FindElement(By.Id("webLinkGroup0"));
        public NgWebElement WebLinkTaskMenu => Driver.FindElement(By.Id("webLinkItem0_0"));
        public NgWebElement OpenWithTaskMenu => Driver.FindElement(By.Id("openWithProgram"));
        public NgWebElement OpenDmsMenu => Driver.FindElement(By.Id("OpenDms"));
        public NgWebElement OpenWithProgramMenu => Driver.FindElement(By.Id("openWithProgram"));
        public NgWebElement EditNameMenu => Driver.FindElement(By.Id("editName"));
        public NgWebElement EditCaseMenu => Driver.FindElement(By.Id("editCase"));
        public NgWebElement RecordTimeMenu => Driver.FindElement(By.CssSelector("#RecordTime span"));
        public NgWebElement RecordTimeWithTimerMenu => Driver.FindElement(By.Id("RecordTimeWithTimer"));
        public NgWebElement TaskMenuFor(string operation)
        {
            Driver.WaitForAngularWithTimeout();
            return Driver.FindElement(By.Id(operation));
        }
        public bool HasTaskMenuFor(string operation)
        {
            Driver.WaitForAngularWithTimeout();
            return Driver.FindElements(By.Id(operation)).Any();
        }
        public NgWebElement OpenWithCaseEnquiryTaskMenu => Driver.FindElement(By.CssSelector("div#" + KnownCasePrograms.CaseEnquiry + " span:nth-child(2)"));
        public NgWebElement MessageDiv => Driver.FindElement(By.ClassName("flash_alert"));
        public NgWebElement SelectAllMenu() => Driver.FindElement(By.CssSelector("a#a123_selectall"));
        public NgWebElement CountryFilter => Driver.FindElement(By.XPath("//span[contains(text(),'Country')]/preceding-sibling::kendo-grid-filter-menu/a/span[@class='k-icon k-i-filter']"));
        public NgWebElement CountryLabel => Driver.FindElement(By.CssSelector("label[for='chk-AU']"));
        public NgWebElement FilterButton => Driver.FindElement(By.CssSelector(".k-button.k-primary"));
        public NgWebElement RefreshButton => Driver.FindElement(By.CssSelector("#refreshColumns"));
    }

    public static class CaseTaskMenuItemOperationType
    {
        public const string MaintainCase = "MaintainCase";
        public const string WorkflowWizard = "WorkflowWizard";
        public const string DocketingWizard = "DocketingWizard";
        public const string MaintainFileLocation = "MaintainFileLocation";
        public const string OpenFirstToFile = "OpenFirstToFile";
        public const string RecordWip = "RecordWip";
        public const string CopyCase = "CopyCase";
        public const string RecordTime = "RecordTime";
        public const string OpenReminders = "OpenReminders";
        public const string CreateAdHocDate = "CreateAdHocDate";
        public const string RequestCaseFile = "RequestCaseFile";
    }

    public static class NameTaskMenuItemOperationType
    {
        public const string NameDetails = "NameDetails";
        public const string MaintainNameText = "MaintainNameText";
        public const string MaintainNameAttributes = "MaintainNameAttributes";
        public const string MaintainName = "MaintainName";
        public const string AdHocDateForName = "AdHocDateForName";
    }

    public static class PriorArtTaskMenuItemOperationType
    {
        public const string MaintainPriorArt = "MaintainPriorArt";
    }
    public static class BillSearchTaskMenuItemOperationType
    {
        public const string ReverseBill = "ReverseFinalisedBill";
        public const string CreditBill = "CreditFinalisedBill";
    }
}
