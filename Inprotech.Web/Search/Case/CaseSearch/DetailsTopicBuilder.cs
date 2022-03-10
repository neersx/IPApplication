using System.Collections.Generic;
using System.Linq;
using System.Xml.Linq;
using Inprotech.Web.CaseSupportData;
using Inprotech.Web.Picklists;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Persistence;
using Basis = Inprotech.Web.Picklists.Basis;

namespace Inprotech.Web.Search.Case.CaseSearch
{
    public class DetailsTopicBuilder : ITopicBuilder
    {
        readonly IDbContext _dbContext;
        readonly IBasis _basis;
        readonly ISubTypes _subTypes;
        readonly ICaseCategories _caseCategories;
        readonly IPropertyTypes _propertyTypes;
        readonly ICaseTypes _caseTypes;

        public DetailsTopicBuilder(IDbContext dbContext, ICaseTypes caseTypes, IBasis basis, ISubTypes subTypes, ICaseCategories caseCategories, IPropertyTypes propertyTypes)
        {
            _dbContext = dbContext;
            _caseTypes = caseTypes;
            _basis = basis;
            _subTypes = subTypes;
            _caseCategories = caseCategories;
            _propertyTypes = propertyTypes;
        }

        public CaseSavedSearch.Topic Build(XElement filterCriteria)
        {
            var topic = new CaseSavedSearch.Topic("Details");

            var details = new DetailsTopic
            {
                Id = filterCriteria.GetAttributeIntValue("ID"),
                CaseOfficeOperator = filterCriteria.Element("Office")?.Attribute("Operator")?.Value ?? filterCriteria.GetAttributeOperatorValue("OfficeKeys", "Operator"),
                CaseOffice = GetCaseOffices(filterCriteria),
                CaseTypeOperator = filterCriteria.Element("CaseTypeKey")?.Attribute("Operator")?.Value ?? filterCriteria.GetAttributeOperatorValue("CaseTypeKeys", "Operator"),
                CaseType = GetCaseTypes(filterCriteria),
                IncludeDraftCases = filterCriteria.GetStringValue("IncludeDraftCase") == "1",
                JurisdictionOperator = filterCriteria.GetAttributeOperatorValue("CountryCodes", "Operator"),
                Jurisdiction = GetJurisdictions(filterCriteria),
                IncludeWhereDesignated = filterCriteria.GetAttributeOperatorValue("CountryCodes", "IncludeDesignations") == "1",
                IncludeGroupMembers = filterCriteria.GetAttributeOperatorValue("CountryCodes", "IncludeMembers") == "1",
                PropertyTypeOperator = filterCriteria.Element("PropertyTypeKey")?.Attribute("Operator")?.Value ?? filterCriteria.GetAttributeOperatorValue("PropertyTypeKeys", "Operator"),
                CaseCategoryOperator = filterCriteria.Element("CategoryKey")?.Attribute("Operator")?.Value ?? filterCriteria.GetAttributeOperatorValue("CategoryKeys", "Operator"),
                SubTypeOperator = filterCriteria.GetAttributeOperatorValue("SubTypeKey", "Operator"),
                BasisOperator = filterCriteria.GetAttributeOperatorValue("BasisKey", "Operator"),
                ClassOperator = filterCriteria.GetAttributeOperatorValue("Classes", "Operator", Operators.StartsWith),
                Local = filterCriteria.GetAttributeOperatorValue("Classes", "IsLocal", "1") == "1",
                International = filterCriteria.GetAttributeOperatorValue("Classes", "IsInternational") == "1",
                Class = filterCriteria.GetStringValue("Classes")
            };

            details.PropertyType = GetPropertyTypes(details, filterCriteria);
            details.CaseCategory = GetCaseCategories(details, filterCriteria);
            details.SubType = GetSubType(details, filterCriteria);
            details.Basis = GetBasis(details, filterCriteria);
            topic.FormData = details;
            return topic;
        }

        Office[] GetCaseOffices(XElement filterCriteria)
        {
            var officeKeys = filterCriteria.GetStringValue("OfficeKeys") ?? filterCriteria.GetStringValue("Office");
            if (string.IsNullOrEmpty(officeKeys)) return null;
            var officeKeysArray = officeKeys.Split(',');
            return _dbContext.Set<InprotechKaizen.Model.Cases.Office>().Where(_ => officeKeysArray.Contains(_.Id.ToString())).Select(_ => 
                new Office
                {
                    Key = _.Id,
                    Value = _.Name
                }).ToArray();
        }

        CaseType[] GetCaseTypes(XElement filterCriteria)
        {
            var caseTypeKeys = filterCriteria.GetStringValue("CaseTypeKeys") ?? filterCriteria.GetStringValue("CaseTypeKey");
            if (string.IsNullOrEmpty(caseTypeKeys)) return null;
            var caseTypeKeysArray = caseTypeKeys.Split(',');
            return _caseTypes.GetCaseTypesWithDetails().Where(_ => caseTypeKeysArray.Contains(_.Code)).ToArray();
        }

        Jurisdiction[] GetJurisdictions(XElement filterCriteria)
        {
            var jurisdictionKeys = filterCriteria.GetStringValue("CountryCodes");
            if (string.IsNullOrEmpty(jurisdictionKeys)) return null;
            var jurisdictionKeysArray = jurisdictionKeys.Split(',');
            return _dbContext.Set<InprotechKaizen.Model.Cases.Country>().Where(_ => jurisdictionKeysArray.Contains(_.Id))
                             .Select(_ => new Jurisdiction
                             {
                                 Code = _.Id,
                                 Value = _.Name
                             }).ToArray();
        }

        PropertyType[] GetPropertyTypes(DetailsTopic topic, XElement filterCriteria)
        {
            var propertyTypeKey = filterCriteria.GetStringValue("PropertyTypeKey");
            var pList = filterCriteria.Element("PropertyTypeKeys")?.Elements("PropertyTypeKey");
            var propertyTypeKeysArray = new List<string>();
            if (propertyTypeKey != null)
            {
                propertyTypeKeysArray.Add(propertyTypeKey);
            }
            else if(pList != null)
            {
                propertyTypeKeysArray = pList.Select(pt => pt.Value).ToList();
            }
            else
            {
                return null;
            }

            var propertyTypes = _propertyTypes.GetPropertyTypes(topic.Jurisdiction?.Select(_ => _.Code).ToArray());
            return propertyTypes.Where(_ => propertyTypeKeysArray.Contains(_.PropertyTypeKey))
                                                 .Select(_ => new PropertyType(_.Id, _.PropertyTypeKey, _.PropertyTypeDescription)).ToArray();
        }

        CaseCategory[] GetCaseCategories(DetailsTopic topic, XElement filterCriteria)
        {
            var categoryKey = filterCriteria.GetStringValue("CategoryKey");
            var pList = filterCriteria.Element("CategoryKeys")?.Elements("CategoryKey");
            string[] categoryKeysList;
            if (categoryKey != null)
            {
                categoryKeysList = categoryKey.Split(',');
            }
            else if(pList != null)
            {
                categoryKeysList = pList.Select(pt => pt.Value).ToArray();
            }
            else
            {
                return null;
            }
            IEnumerable<CaseCategoryListItem> validCategories;

            if (topic.CaseType?.Length == 1)
            {
                validCategories = _caseCategories.GetCaseCategories(topic.CaseType?.FirstOrDefault()?.Code,
                                                                    topic.Jurisdiction?.Select(_ => _.Code).ToArray(),
                                                                    topic.PropertyType?.Select(_ => _.Code).ToArray());
            }
            else
            {
                validCategories = _caseCategories.GetCaseCategories(null, null, null);
            }

            return validCategories.Where(_ => categoryKeysList.Contains(_.CaseCategoryKey))
                                                   .Select(_ => new CaseCategory(_.Id, _.CaseCategoryKey, _.CaseCategoryDescription)).ToArray();
        }

        SubType GetSubType(DetailsTopic topic, XElement filterCriteria)
        {
            var subType = filterCriteria.GetStringValue("SubTypeKey");
            if (subType == null) return null;
            IEnumerable<SubTypeListItem> validSubtypes;
            if (topic.CaseType?.Length == 1)
            {
                validSubtypes = _subTypes.GetSubTypes(topic.CaseType.FirstOrDefault()?.Code, 
                                                      topic.Jurisdiction?.Select(_ => _.Code).ToArray(), 
                                                      topic.PropertyType?.Select(_ => _.Code).ToArray(), 
                                                      topic.CaseCategory?.Select(_ => _.Code).ToArray());
            }
            else
            {
                validSubtypes = _subTypes.GetSubTypes(null, null, null, null);
            }

            var selectedSybType = validSubtypes.FirstOrDefault(_ => _.SubTypeKey == subType);

            return selectedSybType != null ? new SubType(selectedSybType.Id, selectedSybType.SubTypeKey, selectedSybType.SubTypeDescription) : null;
        }

        Basis GetBasis(DetailsTopic topic, XElement filterCriteria)
        {
            var basis = filterCriteria.GetStringValue("BasisKey");
            if (basis == null) return null;
            var isValidBasisRequired = topic.CaseCategory?.Length == 1 && topic.Jurisdiction?.Length == 1 && topic.PropertyType?.Length == 1 && topic.CaseCategory?.Length == 1;
            IEnumerable<BasisListItem> validBasis;
            if (isValidBasisRequired)
            {
                validBasis = _basis.GetBasis(topic.CaseType.FirstOrDefault()?.Code, 
                                                 topic.Jurisdiction?.Select(_ => _.Code).ToArray(), 
                                                 topic.PropertyType?.Select(_ => _.Code).ToArray(), 
                                                 topic.CaseCategory?.Select(_ => _.Code).ToArray());
            }
            else
            {
                validBasis = _basis.GetBasis(null,null,null,null); 
            }

            var selectedBasis = validBasis.FirstOrDefault(_ => _.ApplicationBasisKey == basis);
            if (selectedBasis != null)
            {
                return topic.Jurisdiction?.Length == 1 ? 
                    new Basis(selectedBasis.Id, selectedBasis.ApplicationBasisKey, selectedBasis.ApplicationBasisDescription, selectedBasis.Convention) 
                    : new Basis(selectedBasis.Id, selectedBasis.ApplicationBasisKey, 1 ,selectedBasis.ApplicationBasisDescription);
            }

            return null;
        }
    }

    public class DetailsTopic
    {
        public int Id { get; set; }
        public string CaseOfficeOperator { get; set; }
        public Office[] CaseOffice { get; set; }
        public string CaseTypeOperator { get; set; }
        public CaseType[] CaseType { get; set; }
        public bool IncludeDraftCases { get; set; }
        public string JurisdictionOperator { get; set; }
        public Jurisdiction[] Jurisdiction { get; set; }
        public bool IncludeGroupMembers { get; set; }
        public bool IncludeWhereDesignated { get; set; }
        public string PropertyTypeOperator { get; set; }
        public PropertyType[] PropertyType { get; set; }
        public string CaseCategoryOperator { get; set; }
        public CaseCategory[] CaseCategory { get; set; }
        public string SubTypeOperator { get; set; }
        public SubType SubType { get; set; }
        public string BasisOperator { get; set; }
        public Basis Basis { get; set; }
        public string ClassOperator { get; set; }
        public string Class { get; set; }
        public bool Local { get; set; }
        public bool International { get; set; }
    }
}
