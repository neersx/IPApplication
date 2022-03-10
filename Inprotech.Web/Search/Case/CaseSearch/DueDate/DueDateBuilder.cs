using System;
using System.Linq;
using System.Xml.Linq;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Web.Picklists;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Components.Names;
using InprotechKaizen.Model.Configuration;
using InprotechKaizen.Model.Names;
using InprotechKaizen.Model.Persistence;
using Action = Inprotech.Web.Picklists.Action;

namespace Inprotech.Web.Search.Case.CaseSearch.DueDate
{

    public interface IDueDateBuilder
    {
        DueDateData Build(XElement filterCriteria);
    }

    public class DueDateBuilder : IDueDateBuilder
    {
        readonly IDbContext _dbContext;
        readonly IPreferredCultureResolver _preferredCultureResolver;
        string _culture;

        public DueDateBuilder(IDbContext dbContext, IPreferredCultureResolver preferredCultureResolver)
        {
            _dbContext = dbContext;
            _preferredCultureResolver = preferredCultureResolver;
        }

        public DueDateData Build(XElement dueDateFilterCriteria)
        {
            _culture = _preferredCultureResolver.Resolve();

            var rangeType = dueDateFilterCriteria.GetXPathStringValue("Dates/PeriodRange") != null ? 1 : 0;
            var rangeXpath = rangeType == 0 ? "Dates/DateRange" : "Dates/PeriodRange";
            var dateOperator = dueDateFilterCriteria.GetAttributeOperatorValueForXPathElement(rangeXpath, "Operator", Operators.Between);
            var dueDateData = new DueDateData
            {
                Event = dueDateFilterCriteria.GetAttributeOperatorValue("UseEventDates") == "1",
                Adhoc = dueDateFilterCriteria.GetAttributeOperatorValue("UseAdHocDates") == "1",
                SearchByRemindDate = dueDateFilterCriteria.Element("Dates")?.GetAttributeOperatorValue("UseReminderDate") == "1",
                SearchByDate = dueDateFilterCriteria.Element("Dates")?.GetAttributeOperatorValue("UseDueDate") == "1",
                RangeType = rangeType,
                IsRange = rangeType == 0,
                IsPeriod = rangeType == 1,
                DueDatesOperator = dateOperator,
                StartDate = !string.IsNullOrEmpty(dueDateFilterCriteria.GetXPathStringValue(rangeXpath + "/From")) && rangeType == 0 ? Convert.ToDateTime(dueDateFilterCriteria.GetXPathStringValue(rangeXpath + "/From")) : (DateTime?) null,
                EndDate = !string.IsNullOrEmpty(dueDateFilterCriteria.GetXPathStringValue(rangeXpath + "/To")) && rangeType == 0 ? Convert.ToDateTime(dueDateFilterCriteria.GetXPathStringValue(rangeXpath + "/To")) : (DateTime?) null,
                FromPeriod = !string.IsNullOrEmpty(dueDateFilterCriteria.GetXPathStringValue(rangeXpath + "/From")) && rangeType == 1 ? Convert.ToInt32(dueDateFilterCriteria.GetXPathStringValue(rangeXpath + "/From")) : (int?) null,
                ToPeriod = !string.IsNullOrEmpty(dueDateFilterCriteria.GetXPathStringValue(rangeXpath + "/To")) && rangeType == 1 ? Convert.ToInt32(dueDateFilterCriteria.GetXPathStringValue(rangeXpath + "/To")) : (int?) null,
                PeriodType = dueDateFilterCriteria.GetXPathStringValue(rangeXpath + "/Type") != null && rangeType == 1 ? Convert.ToString(dueDateFilterCriteria.GetXPathStringValue(rangeXpath + "/Type")) : null,
                EventCategoryValue = GetEventCategories(dueDateFilterCriteria.GetXPathStringValue("EventCategoryKey")),
                EventCategoryOperator = dueDateFilterCriteria.GetAttributeOperatorValueForXPathElement("EventCategoryKey", "Operator", Operators.EqualTo),
                ImportanceLevelOperator = dueDateFilterCriteria.GetAttributeOperatorValueForXPathElement("ImportanceLevel", "Operator", Operators.Between),
                ImportanceLevelFrom = dueDateFilterCriteria.GetXPathStringValue("ImportanceLevel/From"),
                ImportanceLevelTo = dueDateFilterCriteria.GetXPathStringValue("ImportanceLevel/To"),
                EventOperator = dueDateFilterCriteria.GetAttributeOperatorValueForXPathElement("EventKey", "Operator", Operators.EqualTo),
                EventValue = GetEvents(dueDateFilterCriteria.GetXPathStringValue("EventKey")),
                ActionOperator = dueDateFilterCriteria.GetAttributeOperatorValueForXPathElement("Actions/ActionKey", "Operator", Operators.EqualTo),
                ActionValue = GetActions(dueDateFilterCriteria.GetXPathStringValue("Actions/ActionKey")),
                IsClosedActions = dueDateFilterCriteria.Element("Actions")?.GetAttributeOperatorValue("IncludeClosed") == "1",
                IsRenevals = dueDateFilterCriteria.Element("Actions")?.GetAttributeOperatorValue("IsRenewalsOnly") == "1",
                IsNonRenevals = dueDateFilterCriteria.Element("Actions")?.GetAttributeOperatorValue("IsNonRenewalsOnly") == "1",
                IsAnyName = dueDateFilterCriteria.Element("DueDateResponsibilityOf")?.GetAttributeOperatorValue("IsAnyName") == "1",
                IsStaff = dueDateFilterCriteria.Element("DueDateResponsibilityOf")?.GetAttributeOperatorValue("IsStaff") == "1",
                IsSignatory = dueDateFilterCriteria.Element("DueDateResponsibilityOf")?.GetAttributeOperatorValue("IsSignatory") == "1",
                NameTypeOperator = dueDateFilterCriteria.GetAttributeOperatorValueForXPathElement("DueDateResponsibilityOf/NameType", "Operator", Operators.EqualTo),
                NameTypeValue = GetNameTypes(dueDateFilterCriteria.GetXPathStringValue("DueDateResponsibilityOf/NameType")),
                NameOperator = dueDateFilterCriteria.GetAttributeOperatorValueForXPathElement("DueDateResponsibilityOf/NameKey", "Operator", Operators.EqualTo),
                NameValue = GetNames(dueDateFilterCriteria.GetXPathStringValue("DueDateResponsibilityOf/NameKey")),
                NameGroupOperator = dueDateFilterCriteria.GetAttributeOperatorValueForXPathElement("DueDateResponsibilityOf/NameGroupKey", "Operator", Operators.EqualTo),
                NameGroupValue = GetNameGroups(dueDateFilterCriteria.GetXPathStringValue("DueDateResponsibilityOf/NameGroupKey")),
                StaffClassificationOperator = dueDateFilterCriteria.GetAttributeOperatorValueForXPathElement("DueDateResponsibilityOf/StaffClassificationKey", "Operator", Operators.EqualTo),
                StaffClassificationValue = GetStaffClassifications(dueDateFilterCriteria.GetXPathStringValue("DueDateResponsibilityOf/StaffClassificationKey"))
            };

            return dueDateData;
        }

        EventCategory[] GetEventCategories(string keys)
        {
            if (string.IsNullOrEmpty(keys)) return null;
            var categories = keys.StringToIntList(",");

            return _dbContext.Set<InprotechKaizen.Model.Cases.Events.EventCategory>().Where(_ => categories.Contains(_.Id))
                             .Select(_ => new EventCategory
                             {
                                 Key = _.Id,
                                 Name = DbFuncs.GetTranslation(_.Name, null, _.NameTId, _culture)
                             }).ToArray();
        }

        Event[] GetEvents(string keys)
        {
            if (string.IsNullOrEmpty(keys)) return null;
            var events = keys.StringToIntList(",");
            return _dbContext.Set<InprotechKaizen.Model.Cases.Events.Event>().Where(_ => events.Contains(_.Id))
                             .Select(_ => new Event
                             {
                                 Key = _.Id,
                                 Code = _.Code,
                                 Value = DbFuncs.GetTranslation(_.Description, null, _.DescriptionTId, _culture) ?? string.Empty
                             }).ToArray();
        }
        Action[] GetActions(string codes)
        {
            if (string.IsNullOrEmpty(codes)) return null;
            var actions = codes.Split(',');
            return _dbContext.Set<InprotechKaizen.Model.Cases.Action>().Where(_ => actions.Contains(_.Code))
                             .Select(_ => new Action
                             {
                                 Key = _.Id,
                                 Code = _.Code,
                                 Value = DbFuncs.GetTranslation(_.Name, null, _.NameTId, _culture) ?? string.Empty
                             }).ToArray();
        }

        Picklists.Name[] GetNames(string names)
        {
            if (string.IsNullOrEmpty(names)) return null;
            var namesArray = names.StringToIntList(",");
            var nameEntities = _dbContext.Set<InprotechKaizen.Model.Names.Name>()
                                         .Where(_ => namesArray.Contains(_.Id)).ToArray();

            return nameEntities.Select(_ => new Picklists.Name
            {
                Key = _.Id,
                Code = _.NameCode,
                DisplayName = _.Formatted(_.NameStyle != null ? (NameStyles) _.NameStyle : NameStyles.Default)
            }).ToArray();
        }

        NameTypeModel[] GetNameTypes(string nameTypes)
        {
            if (string.IsNullOrEmpty(nameTypes)) return null;
            var nameTypesArray = nameTypes.Split(',');

            return _dbContext.Set<NameType>().Where(_ => nameTypesArray.Contains(_.NameTypeCode))
                             .Select(_ => new NameTypeModel
                             {
                                 Key = _.Id,
                                 Code = _.NameTypeCode,
                                 Value = DbFuncs.GetTranslation(_.Name, null, _.NameTId, _culture) ?? string.Empty
                             }).ToArray();
        }

        NameGroupPicklistItem[] GetNameGroups(string keys)
        {
            if (string.IsNullOrEmpty(keys)) return null;
            var nameGroups = keys.StringToIntList(",");
            return _dbContext.Set<NameFamily>().Where(_ => nameGroups.Contains(_.Id))
                             .Select(_ => new NameGroupPicklistItem
                             {
                                 Key = _.Id,
                                 Title = DbFuncs.GetTranslation(_.FamilyTitle, null, _.FamilyTitleTid, _culture) ?? string.Empty
                             }).ToArray();
        }

        TableCodePicklistController.TableCodePicklistItem[] GetStaffClassifications(string keys)
        {
            if (string.IsNullOrEmpty(keys)) return null;
            var staffClassifications = keys.StringToIntList(",");
            return _dbContext.Set<TableCode>().Where(_ => staffClassifications.Contains(_.Id))
                             .Select(_ => new TableCodePicklistController.TableCodePicklistItem
                             {
                                 Key = _.Id,
                                 Value = DbFuncs.GetTranslation(_.Name, null, _.NameTId, _culture),
                                 Code = _.UserCode ?? string.Empty,
                             }).ToArray();

        }

    }
}


