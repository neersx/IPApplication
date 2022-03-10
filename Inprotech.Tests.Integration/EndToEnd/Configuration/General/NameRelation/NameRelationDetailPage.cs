using Inprotech.Tests.Integration.PageObjects;
using Inprotech.Tests.Integration.Utils;
using OpenQA.Selenium;
using Protractor;
using Checkbox = Inprotech.Tests.Integration.PageObjects.Checkbox;

namespace Inprotech.Tests.Integration.EndToEnd.Configuration.General.NameRelation
{
    class NameRelationDetailPage : DetailPage
    {
        DefaultsTopic _defaultsTopic;
        public NameRelationDetailPage(NgWebDriver driver) : base(driver)
        {
        }

        public DefaultsTopic DefaultsTopic => _defaultsTopic ?? (_defaultsTopic = new DefaultsTopic(Driver));

        public string Locality()
        {
            return Driver.FindElement(By.CssSelector(".title-header h2")).Text;
        }
    }

    public class DefaultsTopic : Topic
    {
        const string TopicKey = "defaults";

        public DefaultsTopic(NgWebDriver driver) : base(driver, TopicKey)
        {
            ChkEmployee = new Checkbox(driver).ByLabel("namerelation.employee");
            ChkIndividual = new Checkbox(driver).ByLabel("namerelation.individual");
            ChkOrganisation = new Checkbox(driver).ByLabel("namerelation.organisation");
            ChkCrmOnly = new Checkbox(driver).ByLabel("namerelation.crm");
            RdoAllowAccess=new IpRadioButton(driver).ByLabel("Allow Access");
            RdoNotApplicable = new IpRadioButton(driver).ByLabel("Not Applicable");
            RdoDenyAccess = new IpRadioButton(driver).ByLabel("Deny Access");
        }

        public IpRadioButton RdoNotApplicable { get; set; }

        public IpRadioButton RdoAllowAccess { get; set; }

        public IpRadioButton RdoDenyAccess { get; set; }

        public Checkbox ChkEmployee { get; set; }

        public Checkbox ChkIndividual { get; set; }

        public Checkbox ChkOrganisation { get; set; }

        public Checkbox ChkCrmOnly { get; set; }

        public NgWebElement SearchTextBox(NgWebDriver driver)
        {
            return driver.FindElement(By.CssSelector("ip-search-field input"));
        }

        public NgWebElement ClearButton(NgWebDriver driver)
        {
            return driver.FindElement(By.CssSelector("span.cpa-icon.cpa-icon-eraser"));
        }

        public NgWebElement SearchButton(NgWebDriver driver)
        {
            return driver.FindElement(By.CssSelector("ip-search-field span.cpa-icon.cpa-icon-search"));
        }

        public int GetSearchResultCount(NgWebDriver driver)
        {
            return driver.FindElements(By.CssSelector("#searchResults .k-master-row")).Count;
        }

        public NgWebElement AddButton(NgWebDriver driver)
        {
            return driver.FindElement(By.Id("add"));
        }

        public NgWebElement RelationshipCode(NgWebDriver driver)
        {
            return driver.FindElement(By.Name("relationshipCode")).FindElement(By.TagName("input"));
        }

        public NgWebElement RelationshipDescription(NgWebDriver driver)
        {
            return driver.FindElement(By.Name("relationshipDescription")).FindElement(By.TagName("input"));
        }

        public NgWebElement ReverseDescription(NgWebDriver driver)
        {
            return driver.FindElement(By.Name("reverseDescription")).FindElement(By.TagName("input"));
        }
        
        public void ClickOnBulkActionMenu(NgWebDriver driver)
        {
            ActionMenu.OpenOrClose();
        }

        public void ClickOnSelectAll(NgWebDriver driver)
        {
            driver.FindElement(By.Name("selectall")).WithJs().Click();
        }

        public void ClickOnDelete(NgWebDriver driver)
        {
            driver.FindElement(By.Id("bulkaction_namerelation_delete")).WithJs().Click();
        }

        public void ClickOnEdit(NgWebDriver driver)
        {
            driver.FindElement(By.Id("bulkaction_namerelation_edit")).WithJs().Click();
        }

        public void ClickOnDuplicate(NgWebDriver driver)
        {
            driver.FindElement(By.Id("bulkaction_namerelation_duplicate")).WithJs().Click();
        }

        public NgWebElement NavigationBar(NgWebDriver driver)
        {
            return driver.FindElement(By.TagName("ip-nav-modal"));
        }

        ActionMenu _actionMenu;
        public ActionMenu ActionMenu => _actionMenu ?? (_actionMenu = new ActionMenu(Driver, "namerelation"));
    }
}
