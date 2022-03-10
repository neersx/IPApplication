using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.PageObjects;
using Inprotech.Tests.Integration.Utils;
using OpenQA.Selenium;
using Protractor;

namespace Inprotech.Tests.Integration.EndToEnd.Configuration.General.DataItem
{
    class DataItemDetailPage : DetailPage
    {
        DefaultsTopic _defaultsTopic;

        public Summary SummaryGrid;
        public DataItemDetailPage(NgWebDriver driver) : base(driver)
        {
            SummaryGrid = new Summary(driver);
        }

        public DefaultsTopic DefaultsTopic => _defaultsTopic ?? (_defaultsTopic = new DefaultsTopic(Driver));

        public string DataItems()
        {
            return Driver.FindElement(By.CssSelector(".title-header h2")).Text;
        }

        public class Summary : KendoGrid
        {
            readonly NgWebDriver _driver;

            public Summary(NgWebDriver driver) : base(driver, "searchResults")
            {
                _driver = driver;
            }

            public void ExpandRow(int rowNumber)
            {
                Cell(rowNumber, 0).FindElement(By.CssSelector("a")).TryClick();
            }

            public SummaryDetail SummaryDetail(int rowNumber)
            {
                var detailRow = DetailRows[rowNumber];
                return new SummaryDetail(_driver, detailRow);
            }
        }
    }

    public class DefaultsTopic : Topic
    {
        const string TopicKey = "defaults";

        public DefaultsTopic(NgWebDriver driver) : base(driver, TopicKey)
        {
            DataItemGroupPickList = new PickList(driver).ByName(string.Empty, "dataitemgrouppicklist");
            EntryPointPicklist = new PickList(driver).ByName(string.Empty, "entrypoint");
            ReturnImage = new Checkbox(driver).ByLabel(".returnsImage");
        }

        public NgWebElement AddButton(NgWebDriver driver)
        {
            return driver.FindElement(By.Id("dataitem-add-btn"));
        }

        public NgWebElement ExpandCollapseIcon(NgWebDriver driver)
        {
            return driver.FindElement(By.Id("expandCollapseAll"));
        }

        public NgWebElement Name(NgWebDriver driver)
        {
            return driver.FindElement(By.Name("code")).FindElement(By.TagName("input"));
        }

        public NgWebElement Description(NgWebDriver driver)
        {
            return driver.FindElement(By.Name("description")).FindElement(By.TagName("textarea"));
        }

        public PickList DataItemGroupPickList { get; set; }

        public PickList EntryPointPicklist { get; set; }

        public Checkbox ReturnImage { get; set; }

        public NgWebElement SqlStatementRadioButton(NgWebDriver driver)
        {
            return driver.FindElement(By.Name("radioSql")).FindElement(By.TagName("input"));
        }

        public NgWebElement SqlProcedureRadioButton(NgWebDriver driver)
        {
            return driver.FindElement(By.Name("radioSp")).FindElement(By.TagName("input"));
        }
        
        public void SendSQL(NgWebDriver driver, string val)
        {
            WithJsExt.WithJs(driver).ExecuteJavaScript<string>($"document.querySelector('.CodeMirror').CodeMirror.setValue(\"{val}\")");
        }

        public NgWebElement SqlStatementTextBox(NgWebDriver driver)
        {
            return driver.FindElement(By.Name("statement")).FindElement(By.TagName("textarea"));
        }

        public NgWebElement SqlProcedureTextBox(NgWebDriver driver)
        {
            return driver.FindElement(By.Name("procedurename")).FindElement(By.TagName("input"));
        }

        public NgWebElement NotesTextBox(NgWebDriver driver)
        {
            return driver.FindElement(By.Name("notes")).FindElement(By.TagName("textarea"));
        }

        public NgWebElement SearchTextBox(NgWebDriver driver)
        {
            return driver.FindElement(By.CssSelector("[ng-model='vm.searchCriteria.text']"));
        }

        public AngularCheckbox IncludeSqlCheckbox(NgWebDriver driver)
        {
            return new AngularCheckbox(Driver).ByModel("vm.searchCriteria.includesql");
        }

        public NgWebElement ClearButton(NgWebDriver driver)
        {
            return driver.FindElement(By.CssSelector("span.cpa-icon.cpa-icon-eraser"));
        }

        public NgWebElement TestButton(NgWebDriver driver)
        {
            return driver.FindElement(By.Id("validate"));
        }

        public NgWebElement SearchButton(NgWebDriver driver)
        {
            return driver.FindElement(By.CssSelector(".search-options span.cpa-icon.cpa-icon-search"));
        }

        public int GetSearchResultCount(NgWebDriver driver)
        {
            return driver.FindElements(By.CssSelector("#searchResults .k-master-row")).Count;
        }

        public void ClickOnBulkActionMenu(NgWebDriver driver)
        {
            driver.FindElement(By.Name("list-ul")).Click();
        }

        public void ClickOnSelectPage(NgWebDriver driver)
        {
            driver.FindElement(By.Id("dataitems_selectpage")).WithJs().Click();
        }

        public void ClickOnEdit(NgWebDriver driver)
        {
            driver.FindElement(By.Id("bulkaction_dataitems_edit")).WithJs().Click();
        }

        public void ClickOnDelete(NgWebDriver driver)
        {
            driver.FindElement(By.Id("bulkaction_dataitems_delete")).WithJs().Click();
        }

        ActionMenu _actionMenu;
        public ActionMenu ActionMenu => _actionMenu ?? (_actionMenu = new ActionMenu(Driver, "dataitems"));
    }

    public class SummaryDetail : PageObject
    {
        public TextInput Notes;
        public TextInput Sql;

        public SummaryDetail(NgWebDriver driver, NgWebElement detailRow) : base(driver, detailRow)
        {
            Notes = new TextInput(driver, detailRow).ByName("notes");
            Sql = new TextInput(driver, detailRow).ByName("sql");
        }

        public bool HasError()
        {
            return FindElement(By.CssSelector(".cpa-icon-exclamation-triangle")).Displayed;
        }
    }
}
