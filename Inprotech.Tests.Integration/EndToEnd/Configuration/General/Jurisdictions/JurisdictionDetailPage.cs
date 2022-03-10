using System.Linq;
using Inprotech.Tests.Integration.PageObjects;
using Inprotech.Tests.Integration.PageObjects.Modals;
using Inprotech.Tests.Integration.Utils;
using OpenQA.Selenium;
using Protractor;

namespace Inprotech.Tests.Integration.EndToEnd.Configuration.General.Jurisdictions
{
    public class JurisdictionDetailPage : DetailPage
    {
        DefaultsTopic _defaultsTopic;
        OverviewTopic _overviewTopic;
        ValidCombinationsTopic _validCombinationTopic;
        GroupsTopic _groupsTopic;
        AttributesTopic _attributesTopic;
        TextsTopic _textsTopic;
        AddressSettingsTopic _addressSettingsTopic;
        BusinessDaysTopic _businessDaysTopic;

        public JurisdictionDetailPage(NgWebDriver driver) : base(driver)
        {
        }

        public DefaultsTopic DefaultsTopic => _defaultsTopic ?? (_defaultsTopic = new DefaultsTopic(Driver));

        public OverviewTopic OverviewTopic => _overviewTopic ?? (_overviewTopic = new OverviewTopic(Driver));

        public string JurisdictionName()
        {
            return Driver.FindElements(By.CssSelector("ip-sticky-header div.page-title h2")).Last().Text;
        }
        public ValidCombinationsTopic ValidCombinationsTopic() => _validCombinationTopic ?? (_validCombinationTopic = new ValidCombinationsTopic(Driver));
        public GroupsTopic GroupsTopic => _groupsTopic ?? (_groupsTopic = new GroupsTopic(Driver));
        public AttributesTopic AttributesTopic => _attributesTopic ?? (_attributesTopic = new AttributesTopic(Driver));
        public TextsTopic TextsTopic => _textsTopic ?? (_textsTopic = new TextsTopic(Driver));
        public AddressSettingsTopic AddressSettingsTopic => _addressSettingsTopic ?? (_addressSettingsTopic = new AddressSettingsTopic(Driver));

        public BusinessDaysTopic BusinessDaysTopic => _businessDaysTopic ?? (_businessDaysTopic = new BusinessDaysTopic(Driver));

        public void LevelUp()
        {
            Driver.FindElement(By.CssSelector("ip-sticky-header div.page-title ip-level-up-button span")).Click();
        }
    }

    public class NewJurisdictionModalDialog : MaintenanceModal
    {
        public NewJurisdictionModalDialog(NgWebDriver driver) : base(driver)
        {
        }
        public TextField Code => new TextField(Driver, "code");
        public TextField Name => new TextField(Driver, "name");
    }

    public class BusinessDaysTopic : Topic
    {
        const string TopicKey = "businessDays";

        public BusinessDaysTopic(NgWebDriver driver) : base(driver, TopicKey)
        {
            HolidayGrid = new KendoGrid(Driver, "holidays");
        }

        public NgWebElement DayOfWeekCheckbox(NgWebDriver driver, string dayOfWeek)
        {
            return driver.FindElement(By.Name(dayOfWeek)).FindElement(By.TagName("input"));
        }

        public KendoGrid HolidayGrid { get; }

        public NgWebElement SearchTextBox(NgWebDriver driver)
        {
            return driver.FindElement(By.Id("search-options-criteria"));
        }

        public NgWebElement SearchButton(NgWebDriver driver)
        {
            return driver.FindElement(By.Id("search-options-search-btn"));
        }

        public void LevelUp()
        {
            Driver.FindElement(By.CssSelector("ip-sticky-header div.page-title ip-level-up-button span")).Click();
        }
        
        public void BulkMenu(NgWebDriver driver)
        {
            driver.FindElement(By.Name("list-ul")).Click();
        }

        public void HolidayBulkMenu(NgWebDriver driver)
        {
            driver.FindElement(By.XPath("//div[@data-context='countryholidays']//span[@name='list-ul']")).Click();
            
        }

        public void HolidayBulkmenuSelectPageOnly(NgWebDriver driver)
        {
            driver.FindElement(By.Id("countryholidays_selectpage")).WithJs().Click();
        }

        public void HolidayBulkmenuEditButton(NgWebDriver driver)
        {
            driver.FindElement(By.Id("bulkaction_countryholidays_edit")).WithJs().Click();
        }

        public void HolidayBulkMenuClickOnDelete(NgWebDriver driver)
        {
            driver.FindElement(By.Id("bulkaction_countryholidays_delete")).WithJs().Click();
        }

        public void SelectPageOnly(NgWebDriver driver)
        {
            driver.FindElement(By.Id("jurisdictionMenu_selectpage")).WithJs().Click();
        }

        public void EditButton(NgWebDriver driver)
        {
            driver.FindElement(By.Id("bulkaction_jurisdictionMenu_edit")).WithJs().Click();
        }
        public NgWebElement SaveButton(NgWebDriver driver)
        {
            return driver.FindElement(By.Name("floppy-o"));
        }

        public NgWebElement DiscardButton(NgWebDriver driver)
        {
            return driver.FindElement(By.CssSelector(".btn-discard"));
        }

        public NgWebElement HolidayDatePicker(NgWebDriver driver)
        {
            return driver.FindElement(By.Name("holidayDate")).FindElement(By.TagName("input"));
        }

        public NgWebElement HolidayNameTextBox(NgWebDriver driver)
        {
            return driver.FindElement(By.Name("holiday")).FindElement(By.TagName("input"));
        }
        
        public int GridRowsCount => HolidayGrid.Rows.Count;
    }

    public class DefaultsTopic : Topic
    {
        const string TopicKey = "defaults";

        public DefaultsTopic(NgWebDriver driver) : base(driver, TopicKey)
        {
        }

        public NgWebElement TaxMandatoryCheckbox(NgWebDriver driver)
        {
            return driver.FindElement(By.Name("taxNoMandatory")).FindElement(By.TagName("input"));
        }
    }

    public class OverviewTopic : Topic
    {
        const string TopicKey = "overview";

        public OverviewTopic(NgWebDriver driver) : base(driver, TopicKey)
        {
        }
        public NgWebElement Code(NgWebDriver driver)
        {
            return driver.FindElement(By.Name("code")).FindElement(By.TagName("input"));
        }
        public NgWebElement Name(NgWebDriver driver)
        {
            return driver.FindElement(By.Name("name")).FindElement(By.TagName("input"));
        }
        public NgWebElement Notes(NgWebDriver driver)
        {
            return driver.FindElement(By.Name("notes")).FindElement(By.TagName("textarea"));
        }
        public NgWebElement PostalName(NgWebDriver driver)
        {
            return driver.FindElement(By.Name("postalName")).FindElement(By.TagName("input"));
        }
        public NgWebElement InformalName(NgWebDriver driver)
        {
            return driver.FindElement(By.Name("informalName")).FindElement(By.TagName("input"));
        }
        public NgWebElement Adjective(NgWebDriver driver)
        {
            return driver.FindElement(By.Name("countryAdjective")).FindElement(By.TagName("input"));
        }
        public NgWebElement IsdCode(NgWebDriver driver)
        {
            return driver.FindElement(By.Name("isdCode")).FindElement(By.TagName("input"));
        }
    }

    public class GroupsTopic : Topic
    {
        const string TopicKey = "groups";

        public GroupsTopic(NgWebDriver driver) : base(driver, TopicKey)
        {
        }

        public KendoGrid GroupMembers(NgWebDriver driver)
        {   
            return new KendoGrid(driver, "groupMembers");
        }
    }

    public class ValidCombinationsTopic : Topic
    {
        const string TopicKey = "validCombinations";

        public ValidCombinationsTopic(NgWebDriver driver) : base(driver, TopicKey)
        {
        }
    }

    public class AttributesTopic : Topic
    {
        const string TopicKey = "attributes";

        public AttributesTopic(NgWebDriver driver) : base(driver, TopicKey)
        {
        }
        public KendoGrid List(NgWebDriver driver)
        {
            return new KendoGrid(driver, "attributesList");
        }
    }

    public class TextsTopic : Topic
    {
        const string TopicKey = "texts";

        public TextsTopic(NgWebDriver driver) : base(driver, TopicKey)
        {
        }
        public KendoGrid List(NgWebDriver driver)
        {
            return new KendoGrid(driver, "textsGrid");
        }
    }

    public class AddressSettingsTopic : Topic
    {
        const string TopicKey = "addressSettings";

        public AddressSettingsTopic(NgWebDriver driver) : base(driver, TopicKey)
        {
        }
        public NgWebElement StateLabel(NgWebDriver driver)
        {
            return driver.FindElement(By.Name("stateLabel")).FindElement(By.TagName("input"));
        }

        public NgWebElement PostCodeLabel(NgWebDriver driver)
        {
            return driver.FindElement(By.Name("postCodeLabel")).FindElement(By.TagName("input"));
        }
    }
}