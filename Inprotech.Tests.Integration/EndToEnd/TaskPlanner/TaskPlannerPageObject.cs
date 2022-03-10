using System;
using System.Linq;
using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.PageObjects;
using Inprotech.Tests.Integration.Utils;
using OpenQA.Selenium;
using OpenQA.Selenium.Support.UI;
using Protractor;

namespace Inprotech.Tests.Integration.EndToEnd.TaskPlanner
{
    public class TaskPlannerPageObject : PageObject
    {
        public TaskPlannerPageObject(NgWebDriver driver, NgWebElement container = null) : base(driver, container)
        {
            Cases = new CasesTopic(driver);
        }
        public CasesTopic Cases { get; set; }

        public AngularKendoGrid Grid => new AngularKendoGrid(Driver, "searchResults", "a123");
        public ContextMenu ContextMenu => new ContextMenu(Driver, Grid);

        public NgWebElement TogglePreviewSwitch => Driver.FindElement(By.CssSelector("label[for='moreDetailsSwitch']"));
        public NgWebElement CaseSummaryPanel => Driver.FindElement(By.XPath("//div[@id='caseSummary']"));
        public NgWebElement TaskDetailsPanel => Driver.FindElement(By.XPath("//div[@id='taskDetailsPanel']"));
        public NgWebElement TaskDetailsEventDesc => Driver.FindElement(By.XPath("//div[@id='eventDescription']"));
        public NgWebElement TaskDetailsDueDate => Driver.FindElement(By.XPath("//div[@id='dueDate']"));
        public NgWebElement TaskDetailsNameSignatory => Driver.FindElements(By.CssSelector("div.names-with-email")).Last().FindElement(By.CssSelector("a i.cpa-icon-envelope"));
        public NgWebElement TaskDetailsGoverningEvent => Driver.FindElement(By.XPath("//div[@id='governingEvent']"));
        public NgWebElement TaskDetailsType => Driver.FindElement(By.XPath("//div[@id='type']"));
        public NgWebElement DelegationDetailsPanel => Driver.FindElement(By.XPath("//div[@id='delegationDetailsPanel']"));
        public NgWebElement CaseNamePanel => Driver.FindElement(By.XPath("//div[@id='caseNames']"));
        public NgWebElement CriticalDates => Driver.FindElement(By.XPath("//div[@id='criticalDates']"));
        public NgWebElement SummaryExpandIcon => Driver.FindElement(By.XPath("//div[@class='fixed-detail-panel-right detail-view']//div[1]//div[1]//div[1]//div[1]//div[1]//a[1]//div[1]//span[1]"));
        public AngularPicklist SavedSearchPicklist => new AngularPicklist(Driver).ByName("savedSearch");
        public AngularPicklist NameKeyPicklist => new AngularPicklist(Driver).ByName("nameKey");
        public DatePicker FromDate => new DatePicker(Driver, "fromDate");
        public DatePicker FinalisedOn => new DatePicker(Driver, "finalise");
        public AngularCheckbox IncludeFinalisedAdHocDatesCheckBox => new AngularCheckbox(Driver).ByName("chkIncludeFinalizedAdHocDates");
        public NgWebElement FinaliseButton => Driver.FindElement(By.Name("finalise"));
        public NgWebElement ReasonDropDown => Driver.FindElement(By.CssSelector("ipx-dropdown[name='reason']"));
        public SelectElement ReasonDropDownSelect => new SelectElement(ReasonDropDown.FindElement(By.TagName("select")));
        public DatePicker ToDate => new DatePicker(Driver, "toDate");
        public NgWebElement FromDateTextBox => Driver.FindElement(By.XPath("//ipx-date-picker[@id='fromDate']/div/span/input"));
        public NgWebElement ToDateTextBox => Driver.FindElement(By.XPath("//ipx-date-picker[@id='toDate']/div/span/input"));
        public NgWebElement RefreshButton => Driver.FindElement(By.Id("btnRefresh"));
        public NgWebElement RevertButton => Driver.FindElement(By.Id("btnRevert"));
        public NgWebElement FilterButton => Driver.FindElement(By.Id("btnSearchBuilder"));
        public NgWebElement PresentationButton => Driver.FindElement(By.Id("presentation"));
        public NgWebElement OpenSavedSearch => Driver.FindElement(By.XPath("(//span[@class='cpa-icon cpa-icon-ellipsis-h'])[1]"));
        public NgWebElement ButtonNewSearch => Driver.FindElement(By.Id("btnNavigateState"));
        public NgWebElement TimePeriod => Driver.FindElement(By.CssSelector("ipx-dropdown[name='timePeriod']"));
        public SelectElement TimePeriodSelect => new SelectElement(TimePeriod.FindElement(By.TagName("select")));
        public NgWebElement NoRecordFound => Driver.FindElement(By.XPath("//span[contains(text(),'No results found.')]"));
        public NgWebElement ClearPicklistSearchText => Driver.FindElement(By.CssSelector("span.cpa-icon.cpa-icon-eraser"));
        public NgWebElement SearchPicklistBtn => Driver.FindElement(By.CssSelector("ip-search-field span.cpa-icon.cpa-icon-search"));
        public NgWebElement BackButton => Driver.FindElement(By.CssSelector(".cpa-icon.cpa-icon-arrow-circle-nw"));
        public NgWebElement PresentationPageSaveButton => Driver.FindElement(By.CssSelector("#presentationSaveSearch > button"));
        public NgWebElement NewSearchButton => Driver.FindElement(By.Id("btnNavigateState"));
        public NgWebElement SearchInputField => Driver.FindElement(By.XPath("//ipx-text-field[@name='searchName']//input"));
        public NgWebElement SaveButton => Driver.FindElement(By.CssSelector("ipx-save-button[name='savedSearch'] > button"));
        public NgWebElement PublicColumn => Driver.FindElement(By.XPath("//span[contains(text(),'Public')]"));
        public NgWebElement TaskMenuButton => Driver.FindElement(By.XPath("//button[@id='tasksMenu']"));
        public NgWebElement PresentationPageSearchButton => Driver.FindElement(By.CssSelector(".btn-advancedsearch"));
        public NgWebElement MoreItemButton => Driver.FindElement(By.Id("tasksMenu"));
        public NgWebElement DeleteButton => Driver.FindElement(By.XPath("//button[text()='Delete']"));
        public AngularCheckbox DueDatesCheckBox => new AngularCheckbox(Driver).ByName("chkDueDates");
        public NgWebElement AdhocDateButton => Driver.FindElement(By.Id("btnAdhocDate"));
        public IpxRadioButton NameRadioButton => new IpxRadioButton(Driver).ById("name");
        public IpxRadioButton GeneralRadioButton => new IpxRadioButton(Driver).ById("general");
        public AngularPicklist CaseReferencePicklist => new AngularPicklist(Driver).ByName("case");
        public NgWebElement DueDateTextBox => Driver.FindElement(By.XPath("//ipx-date-picker[@name='dueDate']/div/span/input"));
        public NgWebElement EndOnTextBox => Driver.FindElement(By.XPath("//ipx-date-picker[@name='endOn']/div/span/input"));
        public AngularPicklist EventPicklist => new AngularPicklist(Driver).ByName("event");
        public AngularPicklist AdHocResponsibleNamePicklist => new AngularPicklist(Driver).ByName("adHocResponsible");
        public AngularPicklist NamePicklist => new AngularPicklist(Driver).ByName("name");
        public AngularPicklist AdHocTemplatePicklist => new AngularPicklist(Driver).ByName("alertTemplate");
        public NgWebElement GeneralTextBox => Driver.FindElement(By.XPath("//ipx-text-field[@name='general']/div/input"));
        public DatePicker DueDate => new DatePicker(Driver, "dueDate");
        public DatePicker AutomaticDeleteOnDate => new DatePicker(Driver, "deleteOn");
        public DatePicker EndOnDate => new DatePicker(Driver, "endOn");
        public NgWebElement MessageTextArea => Driver.FindElement(By.XPath("//ipx-text-field[@name='message']/div/textarea"));
        public NgWebElement ImportanceLevelDropDown => Driver.FindElement(By.CssSelector("ipx-dropdown[name='importanceLevel']"));
        public SelectElement ImportanceLevelDropDownSelect => new SelectElement(ImportanceLevelDropDown.FindElement(By.TagName("select")));
        public NgWebElement SendReminderDropDown => Driver.FindElement(By.CssSelector("ipx-text-dropdown-group[name='sendreminder']"));
        public SelectElement SendReminderDropDownSelect => new SelectElement(SendReminderDropDown.FindElement(By.TagName("select")));
        public NgWebElement SendReminderTextBox => Driver.FindElement(By.XPath("//ipx-text-dropdown-group[@name='sendreminder']/div/div/input"));
        public NgWebElement RepeatEveryTextBox => Driver.FindElement(By.XPath("//ipx-text-field[@name='repeatEvery']/div/input"));
        public NgWebElement RepeatEveryMonthLabel => Driver.FindElement(By.XPath("//ipx-text-field[@name='repeatEvery']//parent::*//parent::*//span[text()='Months']"));
        public NgWebElement RepeatEveryDayLabel => Driver.FindElement(By.XPath("//ipx-text-field[@name='repeatEvery']//parent::*//parent::*//span[text()='Days']"));

        public AngularCheckbox RecurringCheckBox => new AngularCheckbox(Driver).ByName("recurring");
        public AngularCheckbox MyselfCheckBox => new AngularCheckbox(Driver).ByName("mySelf");
        public AngularCheckbox StaffCheckBox => new AngularCheckbox(Driver).ByName("staff");
        public AngularCheckbox SignatoryCheckBox => new AngularCheckbox(Driver).ByName("signatory");
        public AngularCheckbox CriticalCheckBox => new AngularCheckbox(Driver).ByName("criticalList");
        public AngularPicklist RecipientsNamesPicklist => new AngularPicklist(Driver).ByName("names");
        public AngularPicklist NameTypePicklist => new AngularPicklist(Driver).ByName("nameType");
        public AngularPicklist RelationshipPicklist => new AngularPicklist(Driver).ByName("relationship");
        public AngularPicklist AdditionalNamesPicklist => new AngularPicklist(Driver).ByName("additionalNames");
        public AngularKendoGrid AdditionalNamesGrid => new AngularKendoGrid(Driver, "picklistResults");
        public AngularCheckbox EmailCheckBox => new AngularCheckbox(Driver).ByName("emailToRecipients");
        public NgWebElement EmailSubjectTextArea => Driver.FindElement(By.XPath("//ipx-text-field[@name='emailSubjectLine']/div/textarea"));
        public NgWebElement ApplyTemplate => Driver.FindElement(By.XPath("//button[@name='confirm']"));
        public NgWebElement ApplyButton => Driver.FindElement(By.XPath("//ipx-apply-button/button/ipx-icon[@name='check']"));
        public AngularCheckbox CreateAdHocCheckBox => new AngularCheckbox(Driver).ByName("createAdhoc");
        public NgWebElement ClearButton(NgWebDriver driver)
        {
            return driver.FindElement(By.CssSelector("span.cpa-icon.cpa-icon-eraser"));
        }

        public NgWebElement SearchButton(NgWebDriver driver)
        {
            return driver.FindElement(By.CssSelector("ipx-picklist-search-field span.cpa-icon.cpa-icon-search"));
        }

        public NgWebElement EditButton(NgWebDriver driver)
        {
            return driver.FindElement(By.CssSelector("ipx-icon span.cpa-icon.cpa-icon-pencil-square-o"));
        }

        public NgWebElement DeleteIcon(NgWebDriver driver)
        {
            return driver.FindElement(By.CssSelector("ipx-icon span.cpa-icon.cpa-icon-trash"));
        }

        public AngularKendoGrid ResultGrid => new AngularKendoGrid(Driver, "picklistResults");

        public NgWebElement SearchPicklistText => Driver.FindElement(By.CssSelector("ipx-picklist-search-field .input-wrap input[type=text]"));

        public NgWebElement AdvancedSearchButton => Driver.FindElement(By.XPath("//ipx-advanced-search-button/button[contains(@class,'btn btn-icon btn-advancedsearch')]"));
        public NgWebElement UseDefaultCheckbox => Driver.FindElement(By.CssSelector("ipx-checkbox[name='useDefault'] input"));
        public NgWebElement SearchColumnTextBox => Driver.FindElement(By.XPath("//ipx-text-field[@name='searchTerm']/div/input"));
        public NgWebElement CommentsEditButton => Driver.FindElement(By.XPath("//button/ipx-icon/span[contains(@class,'cpa-icon cpa-icon-pencil-square-o')]"));
        public NgWebElement CommentsTextArea => Driver.FindElement(By.XPath("//textarea"));
        public NgWebElement CommentsRevertButton => Driver.FindElement(By.XPath("//ipx-revert-button/button/ipx-icon[@name='revert']"));
        public NgWebElement CommentsSaveButton => Driver.FindElement(By.XPath("//ipx-save-button/button/ipx-icon[@name='floppy-o']"));
        public NgWebElement CommentsAddButton => Driver.FindElement(By.XPath("//ipx-add-button/div/button/span[contains(@class,'cpa-icon cpa-icon-plus-circle')]"));
        public NgWebElement AllNamesInBelongingToDropDown => Driver.FindElement(By.XPath("//ipx-dropdown[@name='belongingTo']//select/option[text()=' All Names ']"));
        public NgWebElement PredefinedPicklist => Driver.FindElement(By.XPath("//input[@placeholder='Select Predefined Notes']"));
        public NgWebElement EventNotesExpandButton => Driver.FindElement(By.XPath("(//a[@title='Expand Details'])[1]"));
        public NgWebElement AddNewEventNotesLink => Driver.FindElement(By.XPath("//em[text()='Add New Event Note']"));
        public NgWebElement EventNotesTextArea => Driver.FindElement(By.XPath("//textarea"));
        public NgWebElement EventNotesSaveButton => Driver.FindElement(By.XPath("//ipx-save-button/button/ipx-icon[@name='floppy-o']"));
        public NgWebElement EditButtonTaskPlanner => Driver.FindElement(By.XPath("//span[@class='cpa-icon cpa-icon-pencil-square-o undefined']"));
        public NgWebElement SearchName => Driver.FindElement(By.XPath("//ipx-text-field[@name='value']/div/input"));
        public NgWebElement EditSearchSaveButton => Driver.FindElement(By.XPath("//ipx-save-button[@name='saveButton']/button"));
        public string SavedSearchHeading => Driver.FindElement(By.XPath("//h2")).Text;
        public NgWebElement ShowPreviewPane()
        {
            return FindElement(By.CssSelector("div.fixed-detail-panel-right.detail-view"));
        }
        public NgWebElement FilterAreaExpander => Driver.FindElement(By.Name("chevron-up"));
        public NgWebElement DateRangeDropDown => Driver.FindElement(By.Name("timePeriod"));

        public NgWebElement GetTaskPlannerTab(int id)
        {
            return Driver.FindElement(By.XPath("//li[@id='tab" + id + "']"));
        }
        public bool IsTabSelected(int id)
        {
            return GetTaskPlannerTab(id).GetAttribute("class").Split(' ').Any(x => x == "active");
        }
        public string GetTaskPlannerTabSearchName(int id)
        {
            if (IsTabSelected(id))
            {
                return GetTaskPlannerTab(id).FindElement(By.CssSelector("div.typeahead-wrap>input")).Value();
            }

            return GetTaskPlannerTab(id).FindElement(By.CssSelector("a div.tab-label")).Text;
        }

        public NgWebElement OpenTaskPlannerTab(int id)
        {
            return Driver.FindElement(By.XPath("//a[@id='openTab" + id + "']"));
        }
        public NgWebElement TabList => Driver.FindElement(By.Id("tabsOrder"));
        public DatePicker DeferEnteredDate => new DatePicker(Driver, "enteredDate");
        public NgWebElement EnteredDateDeferButton => Driver.FindElement(By.Name("deferReminder"));
        public NgWebElement SuccessMessage => Driver.FindElement(By.ClassName("flash_alert"));
        public NgWebElement AlertMessage => Driver.FindElement(By.CssSelector("#alertModal .modal-body p"));
        public NgWebElement AlertOkButton => Driver.FindElement(By.CssSelector("#alertModal .modal-footer button.btn"));
        public void SelectGridRow(int row) => Grid.SelectRow(row - 1);
        public void OpenDeferBulkOption(string function)
        {
            Driver.Hover(Grid.ActionMenu.Option("defer-reminders").FindElement(By.ClassName("cpa-icon-right")));
            Driver.WaitForAngularWithTimeout();
            Grid.ActionMenu.Option(function).WithJs().Click();
        }
        public void OpenMarkAsBulkOption(string function)
        {
            Driver.Hover(Grid.ActionMenu.Option("mark-as-read-unread").FindElement(By.ClassName("cpa-icon-right")));
            Driver.WaitForAngularWithTimeout();
            Grid.ActionMenu.Option(function).WithJs().Click();
        }

        public void ChangeDueDateResponsibilityBulkOption(string function)
        {
            Driver.Hover(Grid.ActionMenu.Option("change-due-date-responsibility").FindElement(By.ClassName("text-elipses")));
            Driver.WaitForAngularWithTimeout();
            Grid.ActionMenu.Option(function).WithJs().Click();
        }
        public void OpenExportBulkOption(string function)
        {
            Grid.ActionMenu.OpenOrClose();
            Driver.Hover(Grid.ActionMenu.Option("export-to").FindElement(By.ClassName("cpa-icon-right")));
            Driver.WaitForAngularWithTimeout();
            Grid.ActionMenu.Option(function).WithJs().Click();
        }
        public void OpenTaskMenuOption(int rowIndex, string taskId)
        {
            Grid.Cell(rowIndex, 2).FindElement(By.CssSelector("ipx-icon-button button.btn")).Click();
            Driver.WaitForAngularWithTimeout();
            Driver.FindElement(By.CssSelector($"div#{taskId} span:nth-child(2)")).Click();
        }

        public void OpenTaskMenuOption(int rowIndex, string taskId, string subTaskId)
        {
            OpenTaskMenuOption(rowIndex, taskId);
            Driver.WaitForAngularWithTimeout();
            Driver.FindElement(By.CssSelector($"div#{subTaskId} span:nth-child(2)")).WithJs().Click();
        }

        public void Proceed()
        {
            Driver.FindElement(By.XPath("//button[@type='button' and contains(text(),'Proceed')]")).ClickWithTimeout();
        }

        public bool HasGridRowError(int row) => Driver.FindElement(By.CssSelector("tr:nth-child(" + row + ")")).GetAttribute("class").Split(' ').Any(x => x == "error");
        public bool IsGridRowBold(int row) => Driver.FindElement(By.CssSelector("tr:nth-child(" + row + ")")).GetAttribute("class").Split(' ').Any(x => x == "text-bold");
        public NgWebElement AssignToMe => Driver.FindElement(By.Name("assignToMe"));
        public NgWebElement ModalRemoveButton => Driver.FindElement(By.Name("confirm"));
        public NgWebElement ModalSaveButton => Driver.FindElement(By.Name("save"));
        public NgWebElement DeleteAdHocButton => Driver.FindElement(By.Name("trash-o"));
        public AngularPicklist NamesPicklist => new AngularPicklist(Driver).ByName("names");
        public NgWebElement ModalEmailWarningMessage => Driver.FindElement(By.CssSelector(".email-warning-msg ipx-inline-alert span"));
        public string NamePickListPlaceholder => Driver.FindElement(By.CssSelector("#dueDateReminder ipx-typeahead input")).GetAttribute("placeholder");
    }

    public class CasesTopic : Topic
    {
        public CasesTopic(NgWebDriver driver) : base(driver, "Cases")
        {
        }

        public NgWebElement CaseReference => Driver.FindElement(By.CssSelector("ipx-text-field[name='caseReference'] input"));
    }

    public class ContextMenu
    {
        readonly NgWebDriver _driver;
        readonly AngularKendoGrid _grid;

        public Action<int> RecordTime;
        public Action<int> RecordTimeWithTimer;
        public Action<int> AddAttachment;

        public ContextMenu(NgWebDriver driver, AngularKendoGrid grid)
        {
            _driver = driver;
            _grid = grid;

            RecordTime = rowIndex => ClickContextMenu(rowIndex, "RecordTime");
            RecordTimeWithTimer = rowIndex => ClickContextMenu(rowIndex, "RecordTimeWithTimer");
            AddAttachment = rowIndex => ClickContextMenu(rowIndex, "addAttachment");
        }

        void ClickContextMenu(int rowIndex, string id)
        {
            _grid.OpenContexualTaskMenu(rowIndex);
            _driver.WaitForAngular();
            WaitHelper.Wait(100);

            Menu(id).FindElement(By.TagName("span")).ClickWithTimeout();

            _driver.WaitForAngular();
        }

        NgWebElement Menu(string id)
        {
            return new AngularKendoGridContextMenu(_driver).Option(id);
        }
    }
}
