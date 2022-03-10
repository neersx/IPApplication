using System.Linq;
using System.Xml.Linq;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Web.Picklists;
using Inprotech.Web.Search.Case.CaseSearch;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Components.Names;
using InprotechKaizen.Model.Names;
using InprotechKaizen.Model.Persistence;

namespace Inprotech.Web.Search.TaskPlanner.SavedSearch
{
    public class GeneralTopicBuilder : ITaskPlannerTopicBuilder
    {
        readonly IDbContext _dbContext;
        readonly IPreferredCultureResolver _preferredCultureResolver;
        string _culture;

        public GeneralTopicBuilder(IDbContext dbContext, IPreferredCultureResolver preferredCultureResolver)
        {
            _dbContext = dbContext;
            _preferredCultureResolver = preferredCultureResolver;
        }

        public TaskPlannerSavedSearch.Topic Build(XElement filterCriteria)
        {
            _culture = _preferredCultureResolver.Resolve();

            var topic = new TaskPlannerSavedSearch.Topic("general");
            var formData = new General
            {
                IncludeFilter = GetIncludeFilter(filterCriteria.Element("Include")),
                SearchByFilter = GetSearchByFilter(filterCriteria.Element("Dates")),
                DateFilter = GetDateFilter(filterCriteria.Element("Dates")),
                ImportanceLevel = GetImportanceLevel(filterCriteria),
                BelongingToFilter = GetBelongingToFilter(filterCriteria.Element("BelongsTo"))
            };
            topic.FormData = formData;
            return topic;
        }

        static IncludeFilter GetIncludeFilter(XElement filterCriteria)
        {
            var includeFilter = new IncludeFilter
            {
                Reminders = filterCriteria.GetXPathBooleanValue("IsReminders"),
                DueDates = filterCriteria.GetXPathBooleanValue("IsDueDates"),
                AdHocDates = filterCriteria.GetXPathBooleanValue("IsAdHocDates")
            };
            return includeFilter;
        }

        static SearchByFilter GetSearchByFilter(XElement filterCriteria)
        {
            var searchByFilter = new SearchByFilter
            {
                DueDate = filterCriteria.GetAttributeStringValue("UseDueDate") == "1",
                ReminderDate = filterCriteria.GetAttributeStringValue("UseReminderDate") == "1"
            };
            return searchByFilter;
        }

        static DateFilter GetDateFilter(XElement filterCriteria)
        {
            var dateFilter = new DateFilter
            {
                DateFilterType = filterCriteria.GetXPathElement("PeriodRange") != null ? 1 : 0,
                DatePeriod = new DatePeriod
                {
                    From = filterCriteria.GetXPathStringValue("PeriodRange/From"),
                    To = filterCriteria.GetXPathStringValue("PeriodRange/To"),
                    PeriodType = filterCriteria.GetXPathStringValue("PeriodRange/Type")
                },
                DateRange = new DateRange
                {
                    From = filterCriteria.GetXPathStringValue("DateRange/From"),
                    To = filterCriteria.GetXPathStringValue("DateRange/To")
                },
                Operator = filterCriteria.GetXPathElement("PeriodRange") != null ? filterCriteria.GetAttributeOperatorValue("PeriodRange", "Operator") : filterCriteria.GetAttributeOperatorValue("DateRange", "Operator")
            };
            return dateFilter;
        }

        static ImportanceLevel GetImportanceLevel(XElement filterCriteria)
        {
            var importanceLevel = new ImportanceLevel
            {
                Operator = filterCriteria.GetAttributeOperatorValueForXPathElement("ImportanceLevel", "Operator", Operators.Between),
                From = filterCriteria.GetXPathStringValue("ImportanceLevel/From"),
                To = filterCriteria.GetXPathStringValue("ImportanceLevel/To")
            };
            return importanceLevel;
        }

        BelongingToFilter GetBelongingToFilter(XElement filterCriteria)
        {
            var actingAs = new ActingAs
            {
                IsDueDate = filterCriteria.GetXPathElement("ActingAs").GetAttributeStringValue("IsResponsibleStaff") == "1",
                IsReminder = filterCriteria.GetXPathElement("ActingAs").GetAttributeStringValue("IsReminderRecipient") == "1",
                NameTypes = GetNameTypes(filterCriteria)
            };

            var belongingTo = new BelongingToFilter
            {
                Names = GetNames(filterCriteria),
                NameGroups = GetNameGroups(filterCriteria.GetStringValue("MemberOfGroupKeys")),
                ActingAs = actingAs,
                Value = GetBelongingToValue(filterCriteria)
            };
            return belongingTo;
        }

        string GetBelongingToValue(XElement filterCriteria)
        {
            if (filterCriteria.Element("NameKey") != null && filterCriteria.Element("NameKey").GetAttributeStringValue("IsCurrentUser") == "1")
            {
                return BelongingToValue.myself.ToString();
            }

            if (filterCriteria.Element("MemberOfGroupKey") != null && filterCriteria.Element("MemberOfGroupKey").GetAttributeStringValue("IsCurrentUser") == "1")
            {
                return BelongingToValue.myTeam.ToString();
            }

            if (filterCriteria.Element("NameKeys") != null && filterCriteria.GetStringValue("NameKeys").Length > 0)
            {
                return BelongingToValue.otherNames.ToString();
            }

            if (filterCriteria.Element("MemberOfGroupKeys") != null && filterCriteria.GetStringValue("MemberOfGroupKeys").Length > 0)
            {
                return BelongingToValue.otherTeams.ToString();
            }

            return string.Empty;
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

        Picklists.Name[] GetNames(XElement filterCriteria)
        {
            var names = filterCriteria?.GetStringValue("NameKeys");
            return names == null ? null : GetNamesArray(names);
        }

        Picklists.Name[] GetNamesArray(string names, string type = null)
        {
            if (string.IsNullOrEmpty(names)) return null;
            var namesArray = names.Split(',');
            var nameEntities = _dbContext.Set<InprotechKaizen.Model.Names.Name>()
                                         .Where(_ => namesArray.Contains(_.Id.ToString())).ToArray();

            return nameEntities.Select(_ => new Picklists.Name
            {
                Key = _.Id,
                Code = _.NameCode,
                DisplayName = _.Formatted(_.NameStyle != null ? (NameStyles)_.NameStyle : NameStyles.Default)
            }).ToArray();
        }

        NameTypeModel[] GetNameTypes(XContainer filterCriteria)
        {
            var nameTypes = string.Empty;
            if (!((XElement)filterCriteria).GetXPathElement("ActingAs").HasElements) return GetNameTypeArray(nameTypes);

            var customers = ((XElement)filterCriteria).GetXPathElement("ActingAs");
            foreach (var xNode in customers.Nodes())
            {
                var customer = (XElement)xNode;
                nameTypes = nameTypes + customer.LastNode + ",";
            }

            nameTypes = nameTypes.Remove(nameTypes.Length - 1);

            return GetNameTypeArray(nameTypes);
        }

        NameTypeModel[] GetNameTypeArray(string nameTypes)
        {
            if (string.IsNullOrEmpty(nameTypes)) return null;
            var nameTypesArray = nameTypes.Split(',');
            var culture = _preferredCultureResolver.Resolve();
            var nameTypesModels = _dbContext.Set<InprotechKaizen.Model.Cases.NameType>().Where(_ => nameTypesArray.Contains(_.NameTypeCode));

            return
                (from _ in nameTypesModels
                 select new NameTypeModel
                 {
                     Key = _.Id,
                     Code = _.NameTypeCode,
                     Value = DbFuncs.GetTranslation(_.Name, null, _.NameTId, culture) ?? string.Empty
                 }).ToArray();
        }

        enum BelongingToValue
        {
            myself,
            myTeam,
            otherNames,
            otherTeams
        }
    }

    public class General
    {
        public IncludeFilter IncludeFilter { get; set; }
        public SearchByFilter SearchByFilter { get; set; }
        public DateFilter DateFilter { get; set; }
        public ImportanceLevel ImportanceLevel { get; set; }
        public BelongingToFilter BelongingToFilter { get; set; }
    }

    public class IncludeFilter
    {
        public bool Reminders { get; set; }
        public bool DueDates { get; set; }
        public bool AdHocDates { get; set; }
    }

    public class SearchByFilter
    {
        public bool DueDate { get; set; }
        public bool ReminderDate { get; set; }
    }

    public class DateRange
    {
        public string From { get; set; }
        public string To { get; set; }
    }

    public class DatePeriod
    {
        public string From { get; set; }
        public string To { get; set; }
        public string PeriodType { get; set; }
    }

    public class DateFilter
    {
        public int DateFilterType { get; set; }
        public string Operator { get; set; }
        public DateRange DateRange { get; set; }
        public DatePeriod DatePeriod { get; set; }
    }

    public class ImportanceLevel
    {
        public string Operator { get; set; }
        public string From { get; set; }
        public string To { get; set; }
    }

    public class NameType
    {
        public int Key { get; set; }
        public string Code { get; set; }
        public string Value { get; set; }
        public bool Selected { get; set; }
    }

    public class ActingAs
    {
        public bool IsDueDate { get; set; }
        public bool IsReminder { get; set; }
        public NameTypeModel[] NameTypes { get; set; }
    }

    public class BelongingToFilter
    {
        public Picklists.Name[] Names { get; set; }
        public dynamic NameGroups { get; set; }
        public ActingAs ActingAs { get; set; }
        public string Value { get; set; }
    }
}