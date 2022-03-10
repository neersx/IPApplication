using Inprotech.Tests.Integration.PageObjects;
using OpenQA.Selenium;
using Protractor;

namespace Inprotech.Tests.Integration.EndToEnd.SavedSearch.Case
{
    public class CaseSavedSearchMenuObject : PageObject
    {
        public CaseSavedSearchMenuObject(NgWebDriver driver) : base(driver)
        {
        }

        public NgWebElement CaseSearchMenu => GetMenuItem("Case Search");

        public NgWebElement CaseSubMenu => Driver.FindElement(By.ClassName("saved-search-menu"));

        public NgWebElement FilterCaseMenu => Driver.FindElement(By.CssSelector("#secondary-nav-container .quick-search-wrap input"));

        public NgWebElement GetMenuItem(string id)
        {
            return Driver.FindElement(By.CssSelector("menu-item[text='" + id + "'] .nav-label"));
        }

        public NgWebElement GetMenuItemAnchor(string id)
        {
            return Driver.FindElement(By.CssSelector("a[id='" + id + "']"));
        }

        public NgWebElement GetGroupMenuItem(string id)
        {
            return Driver.FindElement(By.CssSelector("label[id='" + id + "']"));
        }

        public NgWebElement GetEditIcon(string id)
        {
            return Driver.FindElement(By.CssSelector("menu-item[text='" + id + "'] span.cpa-icon-edit"));
        }
    }

    public class ReferencesTopic : Topic
    {
        public ReferencesTopic(NgWebDriver driver) : base(driver, "References") {}
        public AngularDropdown YourReferenceOperator => new AngularDropdown(Driver, "ipx-dropdown-operator").ByName("YourReferenceOperator");
        public NgWebElement YourReference => Driver.FindElement(By.CssSelector("ipx-text-field[name='YourReference'] input"));

        public AngularDropdown CaseReferenceOperator => new AngularDropdown(Driver, "ipx-dropdown-operator").ByName("CaseReferenceOperator");
        public NgWebElement CaseReference => Driver.FindElement(By.CssSelector("ipx-text-field[name='CaseReference'] input"));
        public AngularPicklist CasePickList => new AngularPicklist(Driver).ByName(string.Empty, "case");

        public AngularDropdown OfficalNumberType => new AngularDropdown(Driver, "ipx-dropdown").ByName("OfficalNumberType");
        public AngularDropdown OfficialNumberOperator => new AngularDropdown(Driver, "ipx-dropdown-operator").ByName("OfficialNumberOperator");
        public NgWebElement OfficialNumber => Driver.FindElement(By.CssSelector("ipx-text-field[name='OfficialNumber'] input"));

        public NgWebElement SearchNumbersOnly => TopicContainer.FindElement(By.CssSelector("ipx-checkbox[name='SearchNumbersOnly'] input"));
        public NgWebElement SearchRelatedCases => TopicContainer.FindElement(By.CssSelector("ipx-checkbox[name='SearchRelatedCases'] input"));

        public AngularDropdown CaseNameReferenceType => new AngularDropdown(Driver, "ipx-dropdown").ByName("CaseNameReferenceType");

        public AngularDropdown CaseNameReferenceOperator => new AngularDropdown(Driver, "ipx-dropdown-operator").ByName("CaseNameReferenceOperator");
        
        public NgWebElement CaseNameReference => Driver.FindElement(By.CssSelector("ipx-text-field[name='CaseNameReference'] input"));

        public AngularDropdown FamilyOperator => new AngularDropdown(Driver, "ipx-dropdown-operator").ByName("FamilyOperator");

        public AngularPicklist CaseFamily => new AngularPicklist(Driver).ByName(string.Empty, "caseFamily");

        public AngularDropdown CaseListOperator => new AngularDropdown(Driver, "ipx-dropdown-operator").ByName("CaseListOperator");

        public AngularPicklist CaseList => new AngularPicklist(Driver).ByName(string.Empty, "caseList");

        public NgWebElement IsPrimeCasesOnly => TopicContainer.FindElement(By.CssSelector("ipx-checkbox[name='isPrimeCasesOnly'] input"));
    } 

    public class DetailsTopic : Topic
    {
        public DetailsTopic(NgWebDriver driver) : base(driver, "Details") {}

        public AngularDropdown CaseOfficeOperator => new AngularDropdown(Driver, "ipx-dropdown-operator").ByName("caseOfficeOperator");
        public AngularPicklist CaseOffice => new AngularPicklist(Driver).ByName("office");
        public AngularDropdown CaseTypeOperator => new AngularDropdown(Driver, "ipx-dropdown-operator").ByName("caseTypeOperator");
        public AngularPicklist CaseType => new AngularPicklist(Driver).ByName("caseType");
        public NgWebElement IncludeDraftCases => TopicContainer.FindElement(By.CssSelector("ipx-checkbox[name='includeDraftCases'] input"));

        public AngularDropdown JurisdictionOperator => new AngularDropdown(Driver, "ipx-dropdown-operator").ByName("jurisdictionOperator");

        public AngularPicklist Jursidiction => new AngularPicklist(Driver).ByName("jurisdiction");

        public NgWebElement IncludeGroupMembers => TopicContainer.FindElement(By.CssSelector("ipx-checkbox[name='includeGroupMembers'] input"));

        public NgWebElement IncludeWhereDesignated => TopicContainer.FindElement(By.CssSelector("ipx-checkbox[name='includeWhereDesignated'] input"));

        public AngularDropdown CaseCategoryOperator => new AngularDropdown(Driver, "ipx-dropdown-operator").ByName("caseCategoryOperator");
        public AngularPicklist CaseCategory => new AngularPicklist(Driver).ByName("caseCategory");

        public AngularDropdown PropertyTypeOperator => new AngularDropdown(Driver, "ipx-dropdown-operator").ByName("propertyTypeOperator");
        public AngularPicklist PropertyType => new AngularPicklist(Driver).ByName("propertyType");

        public AngularDropdown SubTypeOperator => new AngularDropdown(Driver, "ipx-dropdown-operator").ByName("subTypeOperator");
        public AngularPicklist SubType => new AngularPicklist(Driver).ByName("subType");

        public AngularDropdown BasisOperator => new AngularDropdown(Driver, "ipx-dropdown-operator").ByName("basisOperator");
        public AngularPicklist Basis => new AngularPicklist(Driver).ByName("basis");

        public AngularDropdown ClassOperator => new AngularDropdown(Driver, "ipx-dropdown-operator").ByName("classOperator");
        public NgWebElement Class => Driver.FindElement(By.CssSelector("ipx-text-field[name='class'] input"));
        
        public NgWebElement Local => TopicContainer.FindElement(By.CssSelector("ipx-checkbox[name='Local'] input"));
        public NgWebElement International => TopicContainer.FindElement(By.CssSelector("ipx-checkbox[name='International'] input"));
    }

    public class TextTopic : Topic
    {
        public TextTopic(NgWebDriver driver) : base(driver, "Text") {}

        public AngularDropdown TitleMarkOperator => new AngularDropdown(Driver, "ipx-dropdown-operator").ByName("titleMarkOperator");
        public NgWebElement TitleMarkValue => Driver.FindElement(By.CssSelector("ipx-text-field[name='titleMarkValue'] input"));
        
        public AngularDropdown TypeOfMarkOperator => new AngularDropdown(Driver, "ipx-dropdown-operator").ByName("typeOfMarkOperator");
        public AngularPicklist TypeOfMarkValue => new AngularPicklist(Driver).ByName(string.Empty, "typeOfMarkValue");
        public AngularDropdown TextType => new AngularDropdown(Driver, "ipx-dropdown").ByName("textType");
        public AngularDropdown TextTypeOperator => new AngularDropdown(Driver, "ipx-dropdown-operator").ByName("textTypeOperator");
        public NgWebElement TextTypeValue => Driver.FindElement(By.CssSelector("ipx-text-field[name='textTypeValue'] input"));
        public AngularDropdown KeywordOperator => new AngularDropdown(Driver, "ipx-dropdown-operator").ByName("keywordOperator");
        public AngularPicklist KeywordValue => new AngularPicklist(Driver).ByName(string.Empty, "keywordValue");
        public NgWebElement KeywordTextValue => Driver.FindElement(By.CssSelector("ipx-text-field[name='keywordTextValue'] input"));
    }

    public class StatusTopic : Topic
    {
        public StatusTopic(NgWebDriver driver) : base(driver, "Status")
        {
        }

        public NgWebElement IsPending => TopicContainer.FindElement(By.CssSelector("ipx-checkbox[name='pending'] input"));
        public NgWebElement IsRegistered => TopicContainer.FindElement(By.CssSelector("ipx-checkbox[name='registered'] input"));
        public NgWebElement IsDead => TopicContainer.FindElement(By.CssSelector("ipx-checkbox[name='dead'] input"));

        public AngularDropdown CaseStatusOperator => new AngularDropdown(Driver, "ipx-dropdown-operator").ByName("caseStatusOperator");
        public AngularPicklist CaseStatus => new AngularPicklist(Driver).ByName(string.Empty, "caseStatus");
        public AngularDropdown RenewalStatusOperator => new AngularDropdown(Driver, "ipx-dropdown-operator").ByName("renewalStatusOperator");

        public AngularPicklist RenewalStatus => new AngularPicklist(Driver).ByName(string.Empty, "renewalStatus");
    }

    public class NamesTopic : Topic
    {
        public NamesTopic(NgWebDriver driver) : base(driver, "Names") {}

        public AngularDropdown InstructorOperator => new AngularDropdown(Driver, "ipx-dropdown-operator").ByName("instructorOperator");
        public AngularDropdown OwnerOperator => new AngularDropdown(Driver, "ipx-dropdown-operator").ByName("ownerOperator");
        public AngularDropdown AgentOperator => new AngularDropdown(Driver, "ipx-dropdown-operator").ByName("agentOperator");
        public AngularDropdown StaffOperator => new AngularDropdown(Driver, "ipx-dropdown-operator").ByName("staffOperator");
        public AngularDropdown SignatoryOperator => new AngularDropdown(Driver, "ipx-dropdown-operator").ByName("signatoryOperator");
        public AngularDropdown NamesOperator => new AngularDropdown(Driver, "ipx-dropdown-operator").ByName("namesOperator");
        public AngularDropdown InheritedNameTypeOperator => new AngularDropdown(Driver, "ipx-dropdown-operator").ByName("inheritedNameTypeOperator");
        public AngularDropdown ParentNameOperator => new AngularDropdown(Driver, "ipx-dropdown-operator").ByName("parentNameOperator");
        public AngularDropdown DefaultRelationshipOperator => new AngularDropdown(Driver, "ipx-dropdown-operator").ByName("defaultRelationshipOperator");

        public AngularPicklist Instructor => new AngularPicklist(Driver).ByName("instructor");
        public AngularPicklist Owner => new AngularPicklist(Driver).ByName("owner");
        public AngularPicklist Agent => new AngularPicklist(Driver).ByName("agent");
        public AngularPicklist Staff => new AngularPicklist(Driver).ByName("staff");
        public AngularPicklist Signatory => new AngularPicklist(Driver).ByName("signatory");
        public AngularPicklist Names => new AngularPicklist(Driver).ByName("names");
        public AngularPicklist IncludeCaseValue => new AngularPicklist(Driver).ByName("includeCaseValue");
        public AngularPicklist NameTypeValue => new AngularPicklist(Driver).ByName("nameTypeValue");
        public AngularPicklist InheritedNameType => new AngularPicklist(Driver).ByName("inheritedNameType");
        public AngularPicklist ParentName => new AngularPicklist(Driver).ByName("parentName");
        public AngularPicklist DefaultRelationship => new AngularPicklist(Driver).ByName("defaultRelationship");
        public AngularPicklist Relationship => new AngularPicklist(Driver).ByName("relationship");

        public AngularDropdown NamesType => new AngularDropdown(Driver, "ipx-dropdown").ByName("namesType");

        public NgWebElement SearchAttentionName => TopicContainer.FindElement(By.CssSelector("ipx-checkbox[name='searchAttentionName'] input"));
        public NgWebElement IsSignatoryMyself => TopicContainer.FindElement(By.CssSelector("ipx-checkbox[name='isSignatoryMyself'] input"));
        public NgWebElement IsStaffMyself => TopicContainer.FindElement(By.CssSelector("ipx-checkbox[name='isStaffMyself'] input"));
    }

    public class AttributesTopic : Topic
    {
        public AttributesTopic(NgWebDriver driver) : base(driver, "attributes")
        {
        }

        public NgWebElement BooleanAnd => TopicContainer.FindElement(By.CssSelector("ipx-radio-button[id='rdbAnd'] input"));
        public NgWebElement BooleanOr => TopicContainer.FindElement(By.CssSelector("ipx-radio-button[id='rdbOr'] input"));

        public AngularDropdown AttributeType1 => new AngularDropdown(Driver, "ipx-dropdown").ByName("attributeType1");
        public AngularDropdown AttributeType2 => new AngularDropdown(Driver, "ipx-dropdown").ByName("attributeType2");
        public AngularDropdown AttributeType3 => new AngularDropdown(Driver, "ipx-dropdown").ByName("attributeType3");
        public AngularDropdown AttributeOperator1 => new AngularDropdown(Driver, "ipx-dropdown-operator").ByName("attributeOperator1");
        public AngularDropdown AttributeOperator2 => new AngularDropdown(Driver, "ipx-dropdown-operator").ByName("attributeOperator2");
        public AngularDropdown AttributeOperator3 => new AngularDropdown(Driver, "ipx-dropdown-operator").ByName("attributeOperator3");

        public AngularPicklist AttributeValue1 => new AngularPicklist(Driver).ByName(string.Empty, "attributeValue1");
        public AngularPicklist AttributeValue2 => new AngularPicklist(Driver).ByName(string.Empty, "attributeValue2");
        public AngularPicklist AttributeValue3 => new AngularPicklist(Driver).ByName(string.Empty, "attributeValue3");
    }

    public class OtherDetailsTopic : Topic
    {
        public OtherDetailsTopic(NgWebDriver driver) : base(driver, "otherDetails")
        {
        }

        public NgWebElement IsCaseSpecific => TopicContainer.FindElement(By.CssSelector("input[id='caseSpecific-input']"));
        public NgWebElement IsInherited => TopicContainer.FindElement(By.CssSelector("input[id='inheritedFromName-input']"));
        public NgWebElement IsInstruction => TopicContainer.FindElement(By.CssSelector("input[id='rdbInstruction-input']"));
        public NgWebElement IsCharacteristic => TopicContainer.FindElement(By.CssSelector("input[id='rdbCharacteristic-input']"));

        public NgWebElement Letters => TopicContainer.FindElement(By.CssSelector("ipx-checkbox[name='chkLetters'] input"));
        public NgWebElement Charges => TopicContainer.FindElement(By.CssSelector("ipx-checkbox[name='chkCharges'] input"));
        public NgWebElement PolicingIncomplete => TopicContainer.FindElement(By.CssSelector("ipx-checkbox[name='chkPolicingIncomplete'] input"));
        public NgWebElement GncIncomplete => TopicContainer.FindElement(By.CssSelector("ipx-checkbox[name='chkGlobalNameChangeIncomplete'] input"));

        public AngularDropdown FileLocationOperator => new AngularDropdown(Driver, "ipx-dropdown-operator").ByName("fileLocationOperator");
        public AngularDropdown BayNoOperator => new AngularDropdown(Driver, "ipx-dropdown-operator").ByName("bayNoOperator");
        public AngularDropdown InstructionOperator => new AngularDropdown(Driver, "ipx-dropdown-operator").ByName("forInstructionOperator");
        public AngularDropdown CharacteristicOperator => new AngularDropdown(Driver, "ipx-dropdown-operator").ByName("forCharacteristicOperator");
        public AngularDropdown PurchaseOrderOperator => new AngularDropdown(Driver, "ipx-dropdown-operator").ByName("purchaseOrderNoOperator");

        public AngularPicklist FileLocation => new AngularPicklist(Driver).ByName(string.Empty, "fileLocation");
        public AngularPicklist Instruction => new AngularPicklist(Driver).ByName(string.Empty, "instruction");
        public AngularPicklist Characteristic => new AngularPicklist(Driver).ByName(string.Empty, "characteristic");

        public NgWebElement BayNo => TopicContainer.FindElement(By.CssSelector("ipx-text-field[name='bayNo'] input"));
        public NgWebElement PurchaseOrder => TopicContainer.FindElement(By.CssSelector("ipx-text-field[name='purchaseOrderNo'] input"));
    }

    public class PtaTopic : Topic
    {
        public PtaTopic(NgWebDriver driver) : base(driver, "patentTermAdjustments")
        {
        }

        public NgWebElement PtaDiscrepancies => TopicContainer.FindElement(By.CssSelector("ipx-checkbox[name='ptaDiscrepancies'] input"));

        public AngularDropdown SuppliedPtaOperator => new AngularDropdown(Driver, "ipx-dropdown-operator").ByName("suppliedPtaOperator");
        public AngularDropdown DeterminedByUsOperator => new AngularDropdown(Driver, "ipx-dropdown-operator").ByName("determinedByUsOperator");
        public AngularDropdown IpOfficeDelayOperator => new AngularDropdown(Driver, "ipx-dropdown-operator").ByName("ipOfficeDelayOperator");
        public AngularDropdown ApplicantDelayOperator => new AngularDropdown(Driver, "ipx-dropdown-operator").ByName("applicantDelayOperator");

        public NgWebElement FromSuppliedPta => TopicContainer.FindElement(By.CssSelector("ipx-text-field[name='fromSuppliedPta'] input"));
        public NgWebElement ToSuppliedPta => TopicContainer.FindElement(By.CssSelector("ipx-text-field[name='toSuppliedPta'] input"));
        public NgWebElement FromPtaDeterminedByUs => TopicContainer.FindElement(By.CssSelector("ipx-text-field[name='fromPtaDeterminedByUs'] input"));
        public NgWebElement ToPtaDeterminedByUs => TopicContainer.FindElement(By.CssSelector("ipx-text-field[name='toPtaDeterminedByUs'] input"));
        public NgWebElement FromIpOfficeDelay => TopicContainer.FindElement(By.CssSelector("ipx-text-field[name='fromIpOfficeDelay'] input"));
        public NgWebElement ToIpOfficeDelay => TopicContainer.FindElement(By.CssSelector("ipx-text-field[name='toIpOfficeDelay'] input"));
        public NgWebElement FromApplicantDelay => TopicContainer.FindElement(By.CssSelector("ipx-text-field[name='fromApplicantDelay'] input"));
        public NgWebElement ToApplicantDelay => TopicContainer.FindElement(By.CssSelector("ipx-text-field[name='toApplicantDelay'] input"));
    }

    public class DataManagementTopic : Topic
    {
        public DataManagementTopic(NgWebDriver driver) : base(driver, "dataManagement"){}

        public NgWebElement BatchIdentifier => TopicContainer.FindElement(By.CssSelector("ipx-text-field[name='batchIdentifier'] input"));
        public AngularDropdown SentToCpa => new AngularDropdown(Driver, "ipx-dropdown").ByName("sentToCPA");
        public AngularPicklist DataSource => new AngularPicklist(Driver).ByName(string.Empty, "dataSource");

    }

    public class EventAndActionsTopic : Topic
    {
        public EventAndActionsTopic(NgWebDriver driver) : base(driver, "eventsActions")
        {
        }
        
        public AngularPicklist Event => new AngularPicklist(Driver).ByName(string.Empty, "event");

        public NgWebElement OccurredEvent => TopicContainer.FindElement(By.CssSelector("ipx-checkbox[name='occurredEvent'] input"));

        public NgWebElement DueEvent => TopicContainer.FindElement(By.CssSelector("ipx-checkbox[name='dueEvent'] input"));

        public NgWebElement IncludeClosedActions => TopicContainer.FindElement(By.CssSelector("ipx-checkbox[name='includeClosedActions'] input"));

        public NgWebElement IsRenewals => TopicContainer.FindElement(By.CssSelector("ipx-checkbox[name='isRenewals'] input"));

        public NgWebElement IsNonRenewals => TopicContainer.FindElement(By.CssSelector("ipx-checkbox[name='isNonRenewals'] input"));

        public AngularDropdown ActionOperator => new AngularDropdown(Driver, "ipx-dropdown-operator").ByName("actionOperator");

        public AngularPicklist ActionValue => new AngularPicklist(Driver).ByName(string.Empty, "actionValue");

        public NgWebElement ActionIsOpen => TopicContainer.FindElement(By.CssSelector("ipx-checkbox[name='actionIsOpen'] input"));
        
        public AngularDropdown EventNoteTypeOperator => new AngularDropdown(Driver, "ipx-dropdown-operator").ByName("eventNoteTypeOperator");

        public AngularPicklist EventNoteType => new AngularPicklist(Driver).ByName(string.Empty, "eventNoteType");

        public AngularDropdown EventNotesOperator => new AngularDropdown(Driver, "ipx-dropdown-operator").ByName("eventNotesOperator");

        public NgWebElement EventNotesText => Driver.FindElement(By.CssSelector("ipx-text-field[name='eventNotesText'] input"));

    }

    public class DueDate
    {
        readonly NgWebDriver _driver;
        public DueDate(NgWebDriver driver)
        {
            _driver = driver;
        }
        public NgWebElement DueDateButton => _driver.FindElement(By.Id("dueDate"));
        public TextField RangeStartDate => new TextField(_driver, "startDate");
        public TextField RangeEndDate => new TextField(_driver, "endDate");
        public AngularPicklist DueDateNameType => new AngularPicklist(_driver).ByName(string.Empty, "dueDateNameTypeValue");
        public AngularDropdown DueDateNameTypeOperator => new AngularDropdown(_driver, "ipx-dropdown-operator").ByName("nameTypeOperator");
        public AngularCheckbox EventCheckbox => new AngularCheckbox(_driver).ByName("event");
        public AngularCheckbox AdHocsCheckbox => new AngularCheckbox(_driver).ByName("adhoc");
        public AngularCheckbox SearchByDueDateCheckbox => new AngularCheckbox(_driver).ByName("searchByDate");
        public AngularCheckbox SearchByReminderDateCheckbox => new AngularCheckbox(_driver).ByName("searchByRemindDate");
        public IpxRadioButton RangeRadioButton => new IpxRadioButton(_driver).ById("rdbRange");
        public IpxRadioButton PeriodRadioButton => new IpxRadioButton(_driver).ById("rdbPeriod");
        public AngularCheckbox RenewalsCheckbox => new AngularCheckbox(_driver).ByName("renewals");
        public AngularCheckbox NonRenewalsCheckbox => new AngularCheckbox(_driver).ByName("nonRenewals");
        public AngularCheckbox ClosedActionsCheckbox => new AngularCheckbox(_driver).ByName("isClosedActions");
        public AngularCheckbox AnyNameCheckbox => new AngularCheckbox(_driver).ByName("anyName");
        public AngularCheckbox StaffCheckbox => new AngularCheckbox(_driver).ByName("staff");
        public AngularCheckbox SignatoryCheckbox => new AngularCheckbox(_driver).ByName("signatory");
    }
}
