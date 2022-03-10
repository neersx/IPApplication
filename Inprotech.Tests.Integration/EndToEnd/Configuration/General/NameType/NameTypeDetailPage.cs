using Inprotech.Tests.Integration.PageObjects;
using Inprotech.Tests.Integration.Utils;
using OpenQA.Selenium;
using Protractor;

namespace Inprotech.Tests.Integration.EndToEnd.Configuration.General.NameType
{
    class NameTypeDetailPage : DetailPage
    {
        DefaultsTopic _defaultsTopic;
        public NameTypeDetailPage(NgWebDriver driver) : base(driver)
        {
        }

        public DefaultsTopic DefaultsTopic => _defaultsTopic ?? (_defaultsTopic = new DefaultsTopic(Driver));

        public string NumberTypes()
        {
            return Driver.FindElement(By.CssSelector(".title-header h2")).Text;
        }
    }

    class DefaultsTopic : Topic
    {
        const string TopicKey = "defaults";

        public DefaultsTopic(NgWebDriver driver) : base(driver, TopicKey)
        {
            NameTypePicklist = new PickList(driver).ByName(string.Empty, "nameType");
            RelationshipPicklist = new PickList(driver).ByName(string.Empty, "relationship");
            EventPicklist = new PickList(driver).ByName(string.Empty, "event");
            UseNameTypeCheckbox = new Checkbox(driver).ByLabel("nameType.maintenance.useNameType");
            UseHomeNameRelationshipCheckbox = new Checkbox(driver).ByLabel("nameType.maintenance.useHomeNameRelationship");
            SameNameType = new Checkbox(driver).ByLabel("nameType.maintenance.sameNameType");
            Attention = new Checkbox(driver).ByLabel("nameType.maintenance.attention");
            NationalityCheckBox = new Checkbox(driver).ByLabel("nameType.maintenance.nationality");
            NameTypeGroupPicklist = new PickList(driver).ByName(string.Empty, "nameTypeGroup");
            NameTypeGroupSearchPicklist = new PickList(driver).ByName(string.Empty, "nameTypeGroup");
        }

        public PickList NameTypePicklist { get; set; }
        public PickList RelationshipPicklist { get; set; }
        public PickList EventPicklist { get; set; }
        public Checkbox UseNameTypeCheckbox { get; set; }
        public Checkbox UseHomeNameRelationshipCheckbox { get; set; }
        public Checkbox SameNameType { get; set; }
        public Checkbox Attention { get; set; }
        public Checkbox NationalityCheckBox { get; set; }
        public PickList NameTypeGroupPicklist { get; set; }
        public PickList NameTypeGroupSearchPicklist { get; set; }

        public NgWebElement SearchTextBox(NgWebDriver driver)
        {
            return driver.FindElement(By.CssSelector("[ng-model='vm.searchCriteria.text']"));
        }

        public NgWebElement ClearButton(NgWebDriver driver)
        {
            return driver.FindElement(By.CssSelector("span.cpa-icon.cpa-icon-eraser"));
        }

        public NgWebElement SearchButton(NgWebDriver driver)
        {
            return driver.FindElement(By.CssSelector(".search-options span.cpa-icon.cpa-icon-search"));
        }

        public int GetSearchResultCount(NgWebDriver driver)
        {
            return driver.FindElements(By.CssSelector("#searchResults .k-master-row")).Count;
        }

        public NgWebElement AddButton(NgWebDriver driver)
        {
            return driver.FindElement(By.Id("add"));
        }

        public NgWebElement Code(NgWebDriver driver)
        {
            return driver.FindElement(By.Name("nameTypeCode")).FindElement(By.TagName("input"));
        }

        public NgWebElement Description(NgWebDriver driver)
        {
            return driver.FindElement(By.Name("name")).FindElement(By.TagName("input"));
        }

        public NgWebElement MinAllowedForCaseIs0(NgWebDriver driver)
        {
            return driver.FindElement(By.Name("min_0")).FindElement(By.TagName("input"));
        }

        public NgWebElement MaxAllowedForCase(NgWebDriver driver)
        {
            return driver.FindElement(By.Name("maximumAllowed")).FindElement(By.TagName("input"));
        }   

        public NgWebElement EthicalWallOptionNotApplicable(NgWebDriver driver)
        {
            return driver.FindElement(By.Name("notApplicable")).FindElement(By.TagName("input"));
        }

        public NgWebElement DisplayNameCodeNone(NgWebDriver driver)
        {
            return driver.FindElement(By.Name("displayNone")).FindElement(By.TagName("input"));
        }

        public NgWebElement DefaultRelationshipNameType(NgWebDriver driver)
        {
            return driver.FindElement(By.Name("nameType")).FindElement(By.TagName("input"));
        }

        public NgWebElement UpdateWhenParentNameChange(NgWebDriver driver)
        {
            return driver.FindElement(By.Name("chkUpdateFromParent")).FindElement(By.TagName("input"));
        }

        public NgWebElement DefaultRelationship(NgWebDriver driver)
        {
            return driver.FindElement(By.Name("relationship")).FindElement(By.TagName("input"));
        }

        public NgWebElement UseNameType(NgWebDriver driver)
        {
            return driver.FindElement(By.Name("chkUseNameType")).FindElement(By.TagName("input"));
        }

        public NgWebElement UseHomeNameRelationship(NgWebDriver driver)
        {
            return driver.FindElement(By.Name("chkUseHomeName")).FindElement(By.TagName("input"));
        }

        public NgWebElement DefaultToName(NgWebDriver driver)
        {
            return driver.FindElement(By.Name("defaultToName")).FindElement(By.TagName("input"));
        }

        public NgWebElement ChangeEvent(NgWebDriver driver)
        {
            return driver.FindElement(By.Name("event")).FindElement(By.TagName("input"));
        }

        public void ClickOnBulkActionMenu(NgWebDriver driver)
        {
            driver.FindElement(By.Name("list-ul")).Click();
        }

        public void ClickOnSelectAll(NgWebDriver driver)
        {
            driver.FindElement(By.Name("selectall")).WithJs().Click();
        }

        public void ClickOnDelete(NgWebDriver driver)
        {
            driver.FindElement(By.Id("bulkaction_nametypes_delete")).WithJs().Click();
        }

        public void ClickOnEdit(NgWebDriver driver)
        {
            driver.FindElement(By.Id("bulkaction_nametypes_edit")).WithJs().Click();
        }

        public void ClickOnDuplicate(NgWebDriver driver)
        {
            driver.FindElement(By.Id("bulkaction_nametypes_duplicate")).WithJs().Click();
        }

        public NgWebElement SetNameTypePriorityLink(NgWebDriver driver)
        {
            return driver.FindElement(By.Id("nametype-priority-link"));
        }

        public NgWebElement SetNameTypePriorityButtonUp(NgWebDriver driver)
        {
            return driver.FindElement(By.Id("btnUp"));
        }

        public NgWebElement SetNameTypePriorityButtonDown(NgWebDriver driver)
        {
            return driver.FindElement(By.Id("btnDown"));
        }

        ActionMenu _actionMenu;
        public ActionMenu ActionMenu => _actionMenu ?? (_actionMenu = new ActionMenu(Driver, "nametypes"));
    }
}
