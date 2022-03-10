using System.Linq;
using System.Xml.Linq;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Web.Picklists;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Components.Names;
using InprotechKaizen.Model.Names;
using InprotechKaizen.Model.Persistence;

namespace Inprotech.Web.Search.Case.CaseSearch
{
    public class NamesTopicBuilder : ITopicBuilder
    {
        readonly IPreferredCultureResolver _preferredCultureResolver;
        readonly IDbContext _dbContext;

        public NamesTopicBuilder(IDbContext dbContext, IPreferredCultureResolver preferredCultureResolver)
        {
            _dbContext = dbContext;
            _preferredCultureResolver = preferredCultureResolver;
        }

        public CaseSavedSearch.Topic Build(XElement filterCriteria)
        {
            var topic = new CaseSavedSearch.Topic("Names");
            var namesTopic = new NamesTopic
            {
                Id = filterCriteria.GetAttributeIntValue("ID"),
                InstructorOperator = GetOperatorValue("I", filterCriteria),
                Instructor = GetNames("I", filterCriteria),
                OwnerOperator = GetOperatorValue("O", filterCriteria),
                Owner = GetNames("O", filterCriteria),
                AgentOperator = GetOperatorValue("A", filterCriteria),
                Agent = GetNames("A", filterCriteria),
                StaffOperator = GetOperatorValue("EMP", filterCriteria),
                Staff = GetNames("EMP", filterCriteria),
                IsStaffMyself = GetIsCurrentUser("EMP", filterCriteria),
                SignatoryOperator = GetOperatorValue("SIG", filterCriteria),
                Signatory = GetNames("SIG", filterCriteria),
                IsSignatoryMyself = GetIsCurrentUser("SIG", filterCriteria),
                NamesOperator = GetOtherNameElement(filterCriteria)?.GetAttributeOperatorValue("Operator") ?? Operators.EqualTo,
                NamesType = GetOtherNameElement(filterCriteria)?.GetStringValue("TypeKey"),
                Names = GetOtherNames(filterCriteria),
                NameVariant = GetOtherNameElement(filterCriteria)?.GetStringValue("NameVariant"),
                SearchAttentionName = GetOtherNameElement(filterCriteria)?.Element("NameKeys")?.GetAttributeOperatorValue("UseAttentionName") == "1",
                IncludeCaseValue = GetCasesForNames(filterCriteria),
                IsOtherCasesValue = filterCriteria.Element("CaseNameFromCase")?.GetStringValue("NameTypeKey"),
                NameTypeValue = GetNameTypes(filterCriteria),
                Relationship = GetNameRelationships(filterCriteria),
                InheritedNameTypeOperator = filterCriteria.Element("InheritedName")?.Element("NameTypeKey")?.GetAttributeOperatorValue("Operator") ?? Operators.EqualTo,
                InheritedNameType = GetInheritedNameType(filterCriteria),
                ParentNameOperator = filterCriteria.Element("InheritedName")?.Element("ParentNameKey")?.GetAttributeOperatorValue("Operator") ?? Operators.EqualTo,
                ParentName = GetParentName(filterCriteria),
                DefaultRelationshipOperator = filterCriteria.Element("InheritedName")?.Element("DefaultRelationshipKey")?.GetAttributeOperatorValue("Operator") ?? Operators.EqualTo,
                DefaultRelationship = GetDefaultRelationship(filterCriteria)
            };
            topic.FormData = namesTopic;
            return topic;
        }

        static XElement GetCaseNameElement(string type, XContainer filterCriteria)
        {
            var group = filterCriteria.Element("CaseNameGroup");
            var caseNameElem = group?.Elements().FirstOrDefault(_ => _.Element("TypeKey")?.Value == type);
            return caseNameElem;
        }

        string GetOperatorValue(string type, XContainer filterCriteria)
        {
            var group = filterCriteria.Element("CaseNameGroup");
            var caseNameElem = group?.Elements().FirstOrDefault(_ => _.Element("TypeKey")?.Value == type);
            return caseNameElem?.GetAttributeOperatorValue("Operator") ?? "0";
        }

        bool GetIsCurrentUser(string type, XContainer filterCriteria)
        {
            var caseNameElem = GetCaseNameElement(type, filterCriteria);
            return caseNameElem?.Element("NameKeys")?.Attribute("IsCurrentUser")?.Value == "1";
        }

        Picklists.Name[] GetNames(string type, XContainer filterCriteria)
        {
            var names = GetCaseNameElement(type, filterCriteria)?.GetStringValue("NameKeys");
            return names == null ? null : GetNamesArray(names, type);
        }

        Picklists.Name[] GetOtherNames(XContainer filterCriteria)
        {
            var otherNames = GetOtherNameElement(filterCriteria)?.GetStringValue("NameKeys");
            return otherNames == null ? null : GetNamesArray(otherNames);
        }

        Picklists.Name GetParentName(XContainer filterCriteria)
        {
            var parentNames = filterCriteria.Element("InheritedName")?.Element("ParentNameKey")?.Value;
            return parentNames == null ? null : GetNamesArray(parentNames)?.FirstOrDefault();
        }

        Picklists.Name[] GetNamesArray(string names, string type = null)
        {
            if (string.IsNullOrEmpty(names)) return null;
            var namesArray = names.Split(',');
            var showNameCode = string.IsNullOrWhiteSpace(type) ? null : _dbContext.Set<NameType>().FirstOrDefault(x => x.NameTypeCode == type)?.ShowNameCode;
            var nameEntities = _dbContext.Set<InprotechKaizen.Model.Names.Name>()
                                  .Where(_ => namesArray.Contains(_.Id.ToString())).ToArray();

            return nameEntities.Select(_ => new Picklists.Name
            {
                Key = _.Id,
                Code = _.NameCode,
                DisplayName = _.Formatted(_.NameStyle != null ? (NameStyles)_.NameStyle : NameStyles.Default),
                Remarks = _.Remarks,
                PositionToShowCode = showNameCode
            }).ToArray();
        }

        XElement GetOtherNameElement(XContainer filterCriteria)
        {
            return filterCriteria.Element("CaseNameGroup")?.Elements().FirstOrDefault(_ => _.Attribute("is-other-name-type")?.Value == "true");
        }

        Picklists.Case GetCasesForNames(XContainer filterCriteria)
        {
            var caseKey = filterCriteria.Element("CaseNameFromCase")?.Element("CaseKey")?.Value;
            if (caseKey == null) return null;

            var @case = _dbContext.Set<InprotechKaizen.Model.Cases.Case>()
                             .SingleOrDefault(_ => _.Id.ToString() == caseKey);

            return @case != null ? new Picklists.Case
            {
                Key = @case.Id,
                Code = @case.Irn,
                Value = @case.Title,
                OfficialNumber = @case.CurrentOfficialNumber,
                PropertyTypeDescription = @case.PropertyType.Name,
                CountryName = @case.Country.Name
            }
                            : null;
        }

        NameTypeModel[] GetNameTypeArray(string nameTypes)
        {
            if (string.IsNullOrEmpty(nameTypes)) return null;
            var nameTypesArray = nameTypes.Split(',');
            var culture = _preferredCultureResolver.Resolve();
            var nameTypesModels = _dbContext.Set<NameType>().Where(_ => nameTypesArray.Contains(_.NameTypeCode));

            return
                (from _ in nameTypesModels
                 select new NameTypeModel
                 {
                     Key = _.Id,
                     Code = _.NameTypeCode,
                     Value = DbFuncs.GetTranslation(_.Name, null, _.NameTId, culture) ?? string.Empty
                 }).ToArray();
        }

        NameTypeModel[] GetNameTypes(XContainer filterCriteria)
        {
            var nameTypes = filterCriteria.Element("NameRelationships")?.Element("NameTypes")?.Value;
            return nameTypes == null ? null : GetNameTypeArray(nameTypes);
        }

        NameTypeModel GetInheritedNameType(XContainer filterCriteria)
        {
            var nameTypes = filterCriteria.Element("InheritedName")?.Element("NameTypeKey")?.Value;
            return nameTypes == null ? null : GetNameTypeArray(nameTypes)?.FirstOrDefault();
        }

        NameRelationshipModel[] GetNameRelationships(XContainer filterCriteria)
        {
            var relationships = filterCriteria.Element("NameRelationships")?.Element("Relationships")?.Value;
            return relationships == null ? null : GetNameRelationshipArray(relationships);
        }

        NameRelationshipModel GetDefaultRelationship(XContainer filterCriteria)
        {
            var relationships = filterCriteria.Element("InheritedName")?.Element("DefaultRelationshipKey")?.Value;
            return relationships == null ? null : GetNameRelationshipArray(relationships)?.FirstOrDefault();
        }

        NameRelationshipModel[] GetNameRelationshipArray(string relationships)
        {
            if (string.IsNullOrEmpty(relationships)) return null;
            var relationshipArray = relationships.Split(',');
            var culture = _preferredCultureResolver.Resolve();
            var relations = _dbContext.Set<NameRelation>().Where(_ => relationshipArray.Contains(_.RelationshipCode)).ToArray();
            var nameRelationships = relations.Select(_ => new
            {
                _.Id,
                _.RelationshipCode,
                RelationDescription = DbFuncs.GetTranslation(_.RelationDescription, null, _.RelationDescriptionTId, culture),
                ReverseDescription = DbFuncs.GetTranslation(_.ReverseDescription, null, _.ReverseDescriptionTId, culture)
            });

            return nameRelationships.Select(_ => new NameRelationshipModel(_.RelationshipCode, _.RelationDescription, _.ReverseDescription, string.Empty)).ToArray();
        }
    }

    public class NamesTopic
    {
        public int Id { get; set; }
        public string InstructorOperator { get; set; }
        public Picklists.Name[] Instructor { get; set; }
        public string OwnerOperator { get; set; }
        public Picklists.Name[] Owner { get; set; }
        public string AgentOperator { get; set; }
        public Picklists.Name[] Agent { get; set; }
        public string StaffOperator { get; set; }
        public Picklists.Name[] Staff { get; set; }
        public bool IsStaffMyself { get; set; }
        public string SignatoryOperator { get; set; }
        public Picklists.Name[] Signatory { get; set; }
        public bool IsSignatoryMyself { get; set; }
        public string NamesOperator { get; set; }
        public string NamesType { get; set; }
        public Picklists.Name[] Names { get; set; }
        public string NameVariant { get; set; }
        public bool SearchAttentionName { get; set; }
        public Picklists.Case IncludeCaseValue { get; set; }
        public string IsOtherCasesValue { get; set; }
        public NameTypeModel[] NameTypeValue { get; set; }
        public NameRelationshipModel[] Relationship { get; set; }
        public string InheritedNameTypeOperator { get; set; }
        public NameTypeModel InheritedNameType { get; set; }
        public string ParentNameOperator { get; set; }
        public Picklists.Name ParentName { get; set; }
        public string DefaultRelationshipOperator { get; set; }
        public NameRelationshipModel DefaultRelationship { get; set; }
    }
}
