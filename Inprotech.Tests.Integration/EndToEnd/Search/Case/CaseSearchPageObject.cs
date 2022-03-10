using System;
using System.Collections.Generic;
using System.Linq;
using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.PageObjects;
using Inprotech.Tests.Integration.PageObjects.Modals;
using OpenQA.Selenium;
using OpenQA.Selenium.Support.UI;
using Protractor;

namespace Inprotech.Tests.Integration.EndToEnd.Search.Case
{
    class CaseSearchPageObject : PageObject
    {
        public CaseSearchPageObject(NgWebDriver driver) : base(driver)
        {
            References = new ReferencesTopic(driver);
            Details = new DetailsTopic(driver);
            Text = new TextTopic(driver);
            Names = new NamesTopic(driver);
            Status = new StatusTopic(driver);
            EventsActions = new EventsActions(driver);
            OtherDetails = new OtherDetailsTopic(driver);
            Attributes = new Attributes(driver);
            DataManagement = new DataManagement(driver);
            PatentTermAdjustments = new PatentTermAdjustments(driver);
            DesignElements = new DesignElementsTopic(driver);
            DueDate = new DueDate(driver);
            HomePage = new HomePage(driver);
            Presentation = new Presentation(driver);
        }

        public NgWebElement CaseSearchMenuItem()
        {
            return Driver.FindElement(By.CssSelector("menu-item[text='Case Search'] .nav-label"));
        }

        public NgWebElement CaseSearchBuilder()
        {
            return Driver.FindElement(By.CssSelector(".btn-advance-search"));
        }

        public NgWebElement CaseSubMenu => Driver.FindElement(By.ClassName("saved-search-menu"));

        public NgWebElement SavedSearchSubMenu(string key)
        {
            return Driver.FindElement(By.XPath("//menu-item[contains(@url, '" + key + "')]/div/div/a"));
        }

        public ReferencesTopic References { get; set; }
        public DetailsTopic Details { get; set; }
        public TextTopic Text { get; set; }
        public NamesTopic Names { get; set; }
        public StatusTopic Status { get; set; }
        public EventsActions EventsActions { get; set; }
        public Attributes Attributes { get; set; }
        public DataManagement DataManagement { get; set; }
        public PatentTermAdjustments PatentTermAdjustments { get; set; }
        public OtherDetailsTopic OtherDetails { get; set; }
        public DesignElementsTopic DesignElements { get; set; }
        public DueDate DueDate { get; set; }
        public HomePage HomePage { get; set; }
        public Presentation Presentation { get; set; }
        public NgWebElement CaseSearchButton => Driver.FindElement(By.CssSelector(".btn-advancedsearch"));
        public NgWebElement CaseSearchClearButton => Driver.FindElement(By.CssSelector(".cpa-icon-eraser"));
        public NgWebElement ToggleMultiStepButton => Driver.FindElement(By.CssSelector(".cpa-icon-list-ol"));
        public NgWebElement DueDateButton => Driver.FindElement(By.Id("dueDate"));
        public NgWebElement DueDateSearchButton => Driver.FindElement(By.Id("dueDateSearchButton"));
        public NgWebElement AddStepButton => Driver.FindElement(By.CssSelector(".cpa-icon-plus-circle"));
        public NgWebElement MoreItemButton => Driver.FindElement(By.Id("tasksMenu"));
        public NgWebElement Step1 => Driver.FindElement(By.Id("step_0"));
        public NgWebElement Step2 => Driver.FindElement(By.Id("step_1"));
        public NgWebElement Step3 => Driver.FindElement(By.Id("step_2"));
        public AngularDropdown StepOperatorDropDown => new AngularDropdown(Driver, "ipx-dropdown").ByName("stepOperator");
        public NgWebElement CloseSearch => Driver.FindElement(By.Id("closeSearch"));
        public NgWebElement RemoveMultiStep => Driver.FindElement(By.CssSelector(".btn-remove"));
        public NgWebElement PresentationButton => Driver.FindElement(By.Id("presentation"));
        public NgWebElement CaseSaveSearchButton => Driver.FindElement(By.Name("floppy-o"));
        public NgWebElement SavedSearchButton => Driver.FindElement(By.XPath("//div[@class='modal-header-controls']//button//ipx-icon[@name='floppy-o']"));
        public NgWebElement CloseButton => Driver.FindElement(By.CssSelector(".modal-header .modal-header-controls ipx-close-button button"));
        public NgWebElement SearchNameTextbox => Driver.FindElement(By.CssSelector("ipx-text-field[name='searchName'] input"));
        public NgWebElement DescriptionTextBox => Driver.FindElement(By.CssSelector("ipx-text-field[name='description'] input"));
        public AngularPicklist SearchGroupMenuPicklist => new AngularPicklist(Driver).ByName("includeInSearchMenu");
        public AngularCheckbox PublicCheckbox => new AngularCheckbox(Driver).ByName("public");
        public NgWebElement CaseSearchHeaderTitle => Driver.FindElement(By.XPath("//ipx-page-title/div/h2/before-title/span[2]"));
        public NgWebElement CustomisePresentation => Driver.FindElement(By.Id("presentation"));
        public NgWebElement UseDefaultCheckbox => Driver.FindElement(By.CssSelector("ipx-checkbox[name='useDefault'] input"));
        public NgWebElement PresentationSaveButton => Driver.FindElement(By.Name("floppy-o"));
        public NgWebElement SearchTextField => Driver.FindElement(By.CssSelector("input[name='quickSearch']"));
        public NgWebElement SearchButton => Driver.FindElement(By.CssSelector(".cpa-icon.cpa-icon-search"));
        public List<NgWebElement> SelectedColumns => Driver.FindElements(By.XPath("//kendo-grid/div/table/tbody/tr")).ToList();
        public NgWebElement AvailableColumnFirst => Driver.FindElement(By.XPath("//ipx-icon-button[1]/parent::*/span[1]"));
        public SelectElement FirstSortOrderDropDown => new SelectElement(Driver.FindElement(By.XPath("//tbody/tr[1]/td[2]/ipx-dropdown/div/select")));
        public SelectElement SecondSortOrderDropDown => new SelectElement(Driver.FindElement(By.XPath("//tbody/tr[2]/td[2]/ipx-dropdown/div/select")));
        public NgWebElement MakeThisMyDefaultButton => Driver.FindElement(By.XPath("//span[contains(.,'Make this my default')]"));
        public NgWebElement RevertToStandardDefaultButton => Driver.FindElement(By.XPath("//span[contains(.,'Revert to standard default')]"));
        public string SelectedColumnLast => "#KendoGrid table tbody tr:last-child";
        public string SelectedColumnFirst => "#KendoGrid table tbody tr:first-child";
        public string SelectedColumnFourth => "#KendoGrid table tbody tr:nth-child(4)";
        public string AvailableColumns => "#availableColumns li span";
        public string AvailableColumnsFirst => "#availableColumns li:first-child";
        public string SelectedColumnsGrid => "#KendoGrid tbody";
        public void SimulateDragDrop(string source, string target)
        {
            var embeddedJs = From.EmbeddedAssets("drag_and_drop_helper.js");
            var jsLastColumn = $"$('{source}').simulateDragDrop({{ dropTarget: '{target}'}});";
            ((IJavaScriptExecutor)Driver).ExecuteScript(embeddedJs + jsLastColumn);
        }
        public string GetColumnName(int row) => Driver.FindElement(By.XPath("//tbody/tr[" + row + "]/td[1]/span")).Text;
        public NgWebElement GetAvailableColumnOne(String columnText)
        {
            return Driver.FindElement(By.XPath("//ipx-kendo-grid[@id='searchResults']//kendo-grid//table//thead//th//span[contains(text(),'" + columnText + "')]"));
        }

        public string PageSubTitle()
        {
            return Driver.FindElements(By.CssSelector(".ipx-page-subtitle")).First().Text;
        }

        public NgWebElement QuickSearchInput => Driver.FindElement(By.CssSelector("input[name='quickSearch']"));
        public NgWebElement BulkMenu => Driver.FindElement(By.CssSelector(".cpa-icon.cpa-icon-list-ul"));
        public NgWebElement ExportToPdf => Driver.FindElement(By.XPath("//a[@id='bulkaction_a123_export-pdf']"));
        public NgWebElement ExportToPdfMessage => Driver.FindElement(By.XPath("//tbody/tr/td/a"));
        public List<NgWebElement> NotificationButton => Driver.FindElements(By.CssSelector("span.notification-count")).ToList();
        public int NotificationTextCount => Convert.ToInt32(NotificationButton.First().Text);
        public void NotificationCount(int notificationCount)
        {
            var count = 0;
            while (count < 30)
            {
                Driver.WaitForAngularWithTimeout(1000);
                if (NotificationButton.Count == 1)
                {
                    if (NotificationTextCount == notificationCount + 1)
                    {
                        break;
                    }
                }

                count++;
            }
        }
    }

    class DesignElementsTopic : Topic
    {
        public DesignElementsTopic(NgWebDriver driver) : base(driver, "designElement")
        {
        }

        public NgWebElement FirmElement => Driver.FindElement(By.CssSelector("ipx-text-field[name='firmElementId'] input"));

        public NgWebElement ClientElementReference => Driver.FindElement(By.CssSelector("ipx-text-field[name='clientElementReference'] input"));

        public NgWebElement OfficialElement => Driver.FindElement(By.CssSelector("ipx-text-field[name='officialElementId'] input"));

        public NgWebElement RegistrationNo => Driver.FindElement(By.CssSelector("ipx-text-field[name='registrationNo'] input"));

        public NgWebElement Typeface => Driver.FindElement(By.CssSelector("ipx-text-field[name='typeface'] input"));

        public AngularCheckbox IsRenew => new AngularCheckbox(Driver).ByName("isRenew");

        public NgWebElement Description => Driver.FindElement(By.Name("description")).FindElement(By.TagName("textarea"));

    }

    class OtherDetailsTopic : Topic
    {
        public OtherDetailsTopic(NgWebDriver driver) : base(driver, "otherDetails")
        {
        }

        public ConfirmModal ConfirmModal => new ConfirmModal(Driver);

        public AngularPicklist FileLocation => new AngularPicklist(Driver).ByName("fileLocation");

        public AngularPicklist Jurisdiction => new AngularPicklist(Driver).ByName("jurisdiction");

        public AngularDropdown FileLocationOperator => new AngularDropdown(Driver, "ipx-dropdown-operator").ByName("fileLocationOperator");

        public AngularPicklist Insrtuction => new AngularPicklist(Driver).ByName("instruction");
        public AngularDropdown InstructionOperator => new AngularDropdown(Driver, "ipx-dropdown-operator").ByName("forInstructionOperator");

        public NgWebElement BayNo => Driver.FindElement(By.CssSelector("ipx-text-field[name='bayNo'] input"));

        public AngularDropdown EntitySize => new AngularDropdown(Driver, "ipx-dropdown").ByName("entitySize");
    }

    class ReferencesTopic : Topic
    {
        public ReferencesTopic(NgWebDriver driver) : base(driver, "References")
        {
        }

        public NgWebElement CaseReference => Driver.FindElement(By.CssSelector("ipx-text-field[name='CaseReference'] input"));
        public AngularPicklist CaseFamily => new AngularPicklist(Driver).ByName("caseFamily");
        public AngularPicklist CaseList => new AngularPicklist(Driver).ByName("caseList");
    }

    class DetailsTopic : Topic
    {
        public DetailsTopic(NgWebDriver driver) : base(driver, "Details")
        {
        }

        public AngularPicklist CaseOffice => new AngularPicklist(Driver).ByName("office");
        public AngularPicklist CaseType => new AngularPicklist(Driver).ByName("caseType");
        public AngularPicklist CaseCategory => new AngularPicklist(Driver).ByName("caseCategory");
        public AngularPicklist PropertyType => new AngularPicklist(Driver).ByName("propertyType");
        public AngularPicklist Jursidiction => new AngularPicklist(Driver).ByName("jurisdiction");
    }

    class TextTopic : Topic
    {
        public TextTopic(NgWebDriver driver) : base(driver, "Text")
        {
        }

        public TextField TitleMark => new TextField(Driver, "titleMarkValue");
        public AngularDropdown TextType => new AngularDropdown(Driver).ByName("textType");
        public TextField TextTypeValue => new TextField(Driver, "textTypeValue");
    }

    class NamesTopic : Topic
    {
        public NamesTopic(NgWebDriver driver) : base(driver, "Names")
        {
        }

        public AngularPicklist Instructor => new AngularPicklist(Driver).ByName("instructor");
        public AngularPicklist Owner => new AngularPicklist(Driver).ByName("owner");
        public AngularDropdown NameType => new AngularDropdown(Driver).ByName("namesType");
        public AngularPicklist OtherName => new AngularPicklist(Driver).ByName("names");
        public AngularPicklist IncludeThisCase => new AngularPicklist(Driver).ByName("includeCaseValue");

    }

    class StatusTopic : Topic
    {
        public StatusTopic(NgWebDriver driver) : base(driver, "Status")
        {
        }

        public AngularCheckbox Pending => new AngularCheckbox(Driver).ByName("pending");
        public AngularCheckbox Registered => new AngularCheckbox(Driver).ByName("registered");
        public AngularCheckbox Dead => new AngularCheckbox(Driver).ByName("dead");
        public AngularPicklist CaseStatus => new AngularPicklist(Driver).ByName("caseStatus");
        public AngularDropdown RenewlStatusOperator => new AngularDropdown(Driver, "ipx-dropdown-operator").ByName("renewalStatusOperator");
        public AngularPicklist RenewalStatus => new AngularPicklist(Driver).ByName("renewalStatus");
    }

    class EventsActions : Topic
    {
        public EventsActions(NgWebDriver driver) : base(driver, "eventsActions") { }

        public AngularPicklist Event => new AngularPicklist(Driver).ByName("event");
        public AngularDropdown EventOperator => new AngularDropdown(Driver, "ipx-dropdown-operator").ByName("eventOperator");
        public AngularDropdown EventDatesOperator => new AngularDropdown(Driver, "ipx-dropdown-operator").ByName("eventDatesOperator");

        public AngularCheckbox OccurredEvent => new AngularCheckbox(Driver).ByName("occurredEvent");
        public AngularCheckbox DueEvent => new AngularCheckbox(Driver).ByName("dueEvent");
        public AngularCheckbox IncludeClosedActions => new AngularCheckbox(Driver).ByName("includeClosedActions");
        public AngularDropdown ActionOperator => new AngularDropdown(Driver, "ipx-dropdown-operator").ByName("actionOperator");
        public AngularCheckbox IsRenewals => new AngularCheckbox(Driver).ByName("isRenewals");
        public AngularCheckbox IsNonRenewals => new AngularCheckbox(Driver).ByName("isNonRenewals");

        public TextInput DaysInput => new TextInput(Driver).ByCssSelector("ipx-text-dropdown-group[name='eventWithinValue'] input");
        public AngularPicklist EventForCompare => new AngularPicklist(Driver).ByName("eventForCompare");

        public AngularDropdown EventNoteTypeOperator => new AngularDropdown(Driver, "ipx-dropdown-operator").ByName("eventNoteTypeOperator");
    }

    class Attributes : Topic
    {
        public Attributes(NgWebDriver driver) : base(driver, "attributes") { }

        public AngularDropdown AttributeType1 => new AngularDropdown(Driver, "ipx-dropdown").ByName("attributeType1");
        public AngularDropdown AttributeOperator1 => new AngularDropdown(Driver, "ipx-dropdown-operator").ByName("attributeOperator1");
        public AngularPicklist AttributeValue1 => new AngularPicklist(Driver).ByName("attributeValue1");

        public AngularDropdown AttributeType2 => new AngularDropdown(Driver, "ipx-dropdown").ByName("attributeType2");
        public AngularDropdown AttributeOperator2 => new AngularDropdown(Driver, "ipx-dropdown-operator").ByName("attributeOperator2");
        public AngularPicklist AttributeValue2 => new AngularPicklist(Driver).ByName("attributeValue2");

        public AngularDropdown AttributeType3 => new AngularDropdown(Driver, "ipx-dropdown").ByName("attributeType3");
        public AngularDropdown AttributeOperator3 => new AngularDropdown(Driver, "ipx-dropdown-operator").ByName("attributeOperator3");
        public AngularPicklist AttributeValue3 => new AngularPicklist(Driver).ByName("attributeValue3");
    }

    class DataManagement : Topic
    {
        public DataManagement(NgWebDriver driver) : base(driver, "dataManagement") { }
        public AngularPicklist DataSource => new AngularPicklist(Driver).ByName("dataSource");

        public TextField BatchIdentifier => new TextField(Driver, "batchIdentifier");
        public AngularDropdown SentToCpaBatchNo => new AngularDropdown(Driver).ByName("sentToCPA");

    }

    class PatentTermAdjustments : Topic
    {
        public PatentTermAdjustments(NgWebDriver driver) : base(driver, "patentTermAdjustments") { }

        public TextField FromSuppliedPta => new TextField(Driver, "fromSuppliedPta");
        public TextField ToSuppliedPta => new TextField(Driver, "toSuppliedPta");
        public AngularDropdown SuppliedPtaOperator => new AngularDropdown(Driver).ByName("suppliedPtaOperator");

        public TextField FromPtaDeterminedByUs => new TextField(Driver, "fromPtaDeterminedByUs");
        public TextField ToPtaDeterminedByUs => new TextField(Driver, "toPtaDeterminedByUs");
        public AngularDropdown DeterminedByUsOperator => new AngularDropdown(Driver).ByName("determinedByUsOperator");

        public TextField FromIpOfficeDelay => new TextField(Driver, "fromIpOfficeDelay");
        public TextField ToIpOfficeDelay => new TextField(Driver, "toIpOfficeDelay");
        public AngularDropdown IpOfficeDelayOperator => new AngularDropdown(Driver).ByName("ipOfficeDelayOperator");

        public TextField FromApplicantDelay => new TextField(Driver, "fromApplicantDelay");
        public TextField ToApplicantDelay => new TextField(Driver, "toApplicantDelay");
        public AngularDropdown ApplicantDelayOperator => new AngularDropdown(Driver).ByName("applicantDelayOperator");

        public AngularCheckbox PtaDiscrepancies => new AngularCheckbox(Driver).ByName("ptaDiscrepancies");

    }

    public class DueDate
    {
        NgWebDriver _driver;
        public DueDate(NgWebDriver driver)
        {
            _driver = driver;
        }
        public AngularCheckbox EventCheckbox => new AngularCheckbox(_driver).ByName("event");
        public AngularCheckbox AdHocsCheckbox => new AngularCheckbox(_driver).ByName("adhoc");
        public AngularCheckbox SearchByDueDateCheckbox => new AngularCheckbox(_driver).ByName("searchByDate");
        public AngularCheckbox SearchByReminderDateCheckbox => new AngularCheckbox(_driver).ByName("searchByRemindDate");
        public IpxRadioButton RangeRadioButton => new IpxRadioButton(_driver).ById("rdbRange");
        public IpxRadioButton PeriodRadioButton => new IpxRadioButton(_driver).ById("rdbPeriod");
        public TextField FromPeriod => new TextField(_driver, "fromPeriod");
        public TextField ToPeriod => new TextField(_driver, "toPeriod");

        public AngularCheckbox RenewalsCheckbox => new AngularCheckbox(_driver).ByName("renewals");
        public AngularCheckbox NonRenewalsCheckbox => new AngularCheckbox(_driver).ByName("nonRenewals");
        public AngularCheckbox ClosedActionsCheckbox => new AngularCheckbox(_driver).ByName("isClosedActions");
        public AngularCheckbox AnyNameCheckbox => new AngularCheckbox(_driver).ByName("anyName");
        public AngularCheckbox StaffCheckbox => new AngularCheckbox(_driver).ByName("staff");
        public AngularCheckbox SignatoryCheckbox => new AngularCheckbox(_driver).ByName("signatory");

        public AngularPicklist DueDateNameTypePicklist => new AngularPicklist(_driver).ByName("dueDateNameTypeValue");

    }

    public class HomePage
    {
        NgWebDriver _driver;
        public HomePage(NgWebDriver driver)
        {
            _driver = driver;
        }

        public NgWebElement HomePageLink => _driver.FindElement(By.XPath("//menu-item[@id='Home']/div/div/a[@id='Home']"));
        public NgWebElement QuickSearchInput => _driver.FindElement(By.CssSelector("ipx-quick-search input"));
        public NgWebElement RecentCasesHeader => _driver.FindElement(By.XPath("//span[contains(.,'RECENT CASES')]"));
        public AngularKendoGrid ResultGrid => new AngularKendoGrid(_driver, "recentCasesWidget");
        public NgWebElement ClickCaseReference(String irn) => _driver.FindElement(By.XPath("//a[contains(text(),'" + irn + "')]"));
        public NgWebElement VerifyCaseReference(String irn) => _driver.FindElement(By.XPath("//span[@class='ipx-page-subtitle'and contains(.,'" + irn + "')]"));
    }

    public class Presentation
    {
        NgWebDriver _driver;
        public Presentation(NgWebDriver driver)
        {
            _driver = driver;
        }
        public NgWebElement SearchColumnTextBox => _driver.FindElement(By.XPath("//ipx-text-field[@name='searchTerm']/div/input"));
        public NgWebElement SearchColumn => _driver.FindElement(By.XPath("//kendo-treeview[@id='availableColumns']//div[@id='0']//span"));
        public NgWebElement SecondHideCheckBox => _driver.FindElement(By.XPath("//tbody/tr[2]/td[4]/ipx-checkbox/div/label"));
        public NgWebElement EditSearchCriteriaButton => _driver.FindElement(By.Id("editSearchCriteria"));
        public NgWebElement RefreshButton => _driver.FindElement(By.Id("refreshColumns"));
    }
}
