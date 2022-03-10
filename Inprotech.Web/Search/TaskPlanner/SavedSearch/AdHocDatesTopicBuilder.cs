using System.Linq;
using System.Xml.Linq;
using InprotechKaizen.Model.Components.Names;
using InprotechKaizen.Model.Persistence;

namespace Inprotech.Web.Search.TaskPlanner.SavedSearch
{
    public class AdHocDatesTopicBuilder : ITaskPlannerTopicBuilder
    {
        readonly IDbContext _dbContext;

        public AdHocDatesTopicBuilder(IDbContext dbContext)
        {
            _dbContext = dbContext;
        }

        public TaskPlannerSavedSearch.Topic Build(XElement filterCriteria)
        {
            var include = filterCriteria.Element("Include");
            var topic = new TaskPlannerSavedSearch.Topic("adhocDates")
            {
                FormData = new AdHocDates
                {
                    
                    IncludeCase = include.GetXPathBooleanValue("HasCase"),
                    IncludeName = include.GetXPathBooleanValue("HasName"),
                    IncludeGeneral = include.GetXPathBooleanValue("IsGeneral"),
                    IncludeFinalizedAdHocDates = include.GetXPathBooleanValue("IncludeFinalizedAdHocDates"),

                    Names = new NamesFormData
                    {
                        Operator = filterCriteria.GetAttributeOperatorValue("NameReferenceKeys", "Operator"),
                        Value = GetNames(filterCriteria)
                    },
                    GeneralRef = new GeneralReferencesFormData
                    {
                        Operator = filterCriteria.GetAttributeOperatorValue("AdHocReference", "Operator"),
                        Value = filterCriteria.GetStringValue("AdHocReference")
                    },
                    Message = new MessageFormData
                    {
                        Operator = filterCriteria.GetAttributeOperatorValue("AdHocMessage", "Operator"),
                        Value = filterCriteria.GetStringValue("AdHocMessage")
                    },
                    EmailSubject = new EmailSubjectFormData
                    {
                        Operator = filterCriteria.GetAttributeOperatorValue("AdHocEmailSubject", "Operator"),
                        Value = filterCriteria.GetStringValue("AdHocEmailSubject")
                    }
                }
            };

            return topic;
        }

        dynamic GetNames(XElement filterCriteria)
        {
            var otherNames = filterCriteria.GetStringValue("NameReferenceKeys");
            return otherNames == null ? null : GetNamesArray(otherNames);
        }

        Picklists.Name[] GetNamesArray(string names, string type = null)
        {
            if (string.IsNullOrEmpty(names)) return null;
            var namesArray = names.Split(',');
            var showNameCode = string.IsNullOrWhiteSpace(type) ? null : _dbContext.Set<InprotechKaizen.Model.Cases.NameType>().FirstOrDefault(x => x.NameTypeCode == type)?.ShowNameCode;
            var nameEntities = _dbContext.Set<InprotechKaizen.Model.Names.Name>()
                                         .Where(_ => namesArray.Contains(_.Id.ToString())).ToArray();

            return nameEntities.Select(_ => new Picklists.Name
            {
                Key = _.Id,
                Code = _.NameCode,
                DisplayName = _.Formatted(_.NameStyle != null ? (NameStyles) _.NameStyle : NameStyles.Default),
                Remarks = _.Remarks,
                PositionToShowCode = showNameCode
            }).ToArray();
        }
    }

    public class AdHocDates
    {
        public bool IncludeCase { get; set; }
        public bool IncludeGeneral { get; set; }
        public bool IncludeName { get; set; }

        public bool IncludeFinalizedAdHocDates { get; set; }

        public NamesFormData Names { get; set; }
        public GeneralReferencesFormData GeneralRef { get; set; }
        public MessageFormData Message { get; set; }
        public EmailSubjectFormData EmailSubject { get; set; }
    }

    public class NamesFormData
    {
        public string Operator { get; set; }
        public Picklists.Name[] Value { get; set; }
    }

    public class GeneralReferencesFormData
    {
        public string Operator { get; set; }
        public string Value { get; set; }
    }

    public class MessageFormData
    {
        public string Operator { get; set; }
        public string Value { get; set; }
    }

    public class EmailSubjectFormData
    {
        public string Operator { get; set; }
        public string Value { get; set; }
    }
}