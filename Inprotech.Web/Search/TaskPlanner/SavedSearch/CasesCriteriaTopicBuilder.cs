using System.Collections.Generic;
using System.Linq;
using System.Xml.Linq;
using Inprotech.Web.CaseSupportData;
using Inprotech.Web.Picklists;
using Inprotech.Web.Search.Case.CaseSearch;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Components.Cases;
using InprotechKaizen.Model.Components.Names;
using InprotechKaizen.Model.Persistence;
using Basis = Inprotech.Web.Picklists.Basis;
using CaseCategory = Inprotech.Web.Picklists.CaseCategory;
using CaseList = Inprotech.Web.Picklists.CaseList;
using CaseType = Inprotech.Web.Picklists.CaseType;
using Office = InprotechKaizen.Model.Cases.Office;
using PropertyType = Inprotech.Web.Picklists.PropertyType;
using Status = Inprotech.Web.Picklists.Status;
using SubType = Inprotech.Web.Picklists.SubType;

namespace Inprotech.Web.Search.TaskPlanner.SavedSearch
{
    public class CasesCriteriaTopicBuilder : ITaskPlannerTopicBuilder
    {
        readonly IBasis _basis;
        readonly ICaseCategories _caseCategories;
        readonly ICaseStatuses _caseStatuses;
        readonly ICaseTypes _caseTypes;

        readonly IDbContext _dbContext;
        readonly IPropertyTypes _propertyTypes;
        readonly ISubTypes _subTypes;

        public CasesCriteriaTopicBuilder(IDbContext dbContext, ICaseTypes caseTypes, IBasis basis, ISubTypes subTypes, ICaseCategories caseCategories, IPropertyTypes propertyTypes, ICaseStatuses caseStatuses)
        {
            _dbContext = dbContext;
            _caseTypes = caseTypes;
            _basis = basis;
            _subTypes = subTypes;
            _caseCategories = caseCategories;
            _propertyTypes = propertyTypes;
            _caseStatuses = caseStatuses;
        }

        public TaskPlannerSavedSearch.Topic Build(XElement filterCriteria)
        {
            var topic = new TaskPlannerSavedSearch.Topic("cases");
            var formData = new CasesSection
            {
                OfficialNumber = new OfficialNumberFormData
                {
                    Operator = filterCriteria.GetAttributeOperatorValue("OfficialNumber", "Operator"),
                    Type = filterCriteria.Element("OfficialNumber")?.GetStringValue("TypeKey") ?? string.Empty,
                    Value = filterCriteria.Element("OfficialNumber")?.GetStringValue("Number")
                },
                CaseFamily = new CaseFamilyFormData
                {
                    Operator = filterCriteria.GetAttributeOperatorValue("FamilyKeyList", "Operator"),
                    Value = GetCaseFamilies(filterCriteria)
                },
                CaseReference = new CaseReferenceFormData
                {
                    Operator = GetCaseReferenceOperator(filterCriteria),
                    Value = GetCaseReferenceOrCaseKeys(filterCriteria)
                },
                CaseList = new CaseListFormData
                {
                    Operator = filterCriteria.GetAttributeOperatorValue("CaseListKey", "Operator") ?? Operators.EqualTo,
                    Value = GetCaseList(filterCriteria)
                },
                IsPending = filterCriteria.Element("StatusFlags") == null || filterCriteria.GetXPathBooleanValue("StatusFlags/IsPending"),
                IsDead = filterCriteria.Element("StatusFlags") == null || filterCriteria.GetXPathBooleanValue("StatusFlags/IsDead"),
                IsRegistered = filterCriteria.Element("StatusFlags") == null || filterCriteria.GetXPathBooleanValue("StatusFlags/IsRegistered"),
                CaseStatus = new StatusFormData
                {
                    Operator = filterCriteria.GetAttributeOperatorValue("StatusKey", "Operator"),
                    Value = filterCriteria.Element("StatusKey") != null ? GetStatus(filterCriteria.GetStringValue("StatusKey")) : null
                },
                RenewalStatus = new StatusFormData
                {
                    Operator = filterCriteria.GetAttributeOperatorValue("RenewalStatusKey", "Operator"),
                    Value = filterCriteria.Element("RenewalStatusKey") != null ? GetStatus(filterCriteria.GetStringValue("RenewalStatusKey")) : null
                },
                Owner = new NameTypeFormData
                {
                    Operator = filterCriteria.GetAttributeOperatorValue("OwnerKeys", "Operator"),
                    Value = GetNames(filterCriteria.GetAttributeOperatorValue("OwnerKeys", "Operator"), "O", filterCriteria)
                },
                Instructor = new NameTypeFormData
                {
                    Operator = filterCriteria.GetAttributeOperatorValue("InstructorKeys", "Operator"),
                    Value = GetNames(filterCriteria.GetAttributeOperatorValue("InstructorKeys", "Operator"), "I", filterCriteria)
                },
                OtherNameTypes = new OtherNameTypesFormData
                {
                    Operator = filterCriteria.GetAttributeOperatorValue("OtherNameTypeKeys", "Operator"),
                    Value = GetNames(filterCriteria.GetAttributeOperatorValue("OtherNameTypeKeys", "Operator"), filterCriteria.GetAttributeStringValueForElement("OtherNameTypeKeys", "Type"), filterCriteria),
                    Type = filterCriteria.GetAttributeStringValueForElement("OtherNameTypeKeys", "Type")
                },
                CaseOffice = new CaseOfficeFormData
                {
                    Operator = filterCriteria.GetAttributeOperatorValue("OfficeKeys", "Operator"),
                    Value = GetCaseOffices(filterCriteria)
                },
                CaseType = new CaseTypeFormData
                {
                    Operator = filterCriteria.GetAttributeOperatorValue("CaseTypeKeys", "Operator"),
                    Value = GetCaseTypes(filterCriteria)
                },
                Jurisdiction = new JurisdictionFormData
                {
                    Operator = filterCriteria.GetAttributeOperatorValue("CountryKeys", "Operator"),
                    Value = GetJurisdictions(filterCriteria)
                },
                PropertyType = new PropertyTypeFormData
                {
                    Operator = filterCriteria.GetAttributeOperatorValue("PropertyTypeKeys", "Operator"),
                    
                },
                CaseCategory = new CaseCategoryFormData
                {
                    Operator = filterCriteria.GetAttributeOperatorValue("CategoryKey", "Operator")
                },
                SubType = new SubTypeFormData
                {
                    Operator = filterCriteria.GetAttributeOperatorValue("SubTypeKey", "Operator")
                },
                Basis = new BasisFormData
                {
                    Operator = filterCriteria.GetAttributeOperatorValue("BasisKey", "Operator")
                }
            };

            formData.PropertyType.Value = GetPropertyTypes(formData, filterCriteria);
            formData.CaseCategory.Value = GetCaseCategories(formData, filterCriteria);
            formData.SubType.Value = GetSubType(formData, filterCriteria);
            formData.Basis.Value = GetBasis(formData, filterCriteria);

            topic.FormData = formData;
            return topic;
        }

        dynamic GetNames(string @operator, string type, XElement filterCriteria)
        {
            var elementName = type == "O" ? "OwnerKeys" : type == "I" ? "InstructorKeys" : "OtherNameTypeKeys";

            var names = filterCriteria.GetStringValue(elementName);

            if (@operator == Operators.StartsWith || @operator == Operators.EndsWith)
            {
                return filterCriteria.GetStringValue(elementName);
            }

            return names == null ? null : GetNamesArray(names, type);
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
                DisplayName = _.Formatted(_.NameStyle != null ? (NameStyles)_.NameStyle : NameStyles.Default),
                Remarks = _.Remarks,
                PositionToShowCode = showNameCode
            }).ToArray();
        }

        Picklists.Office[] GetCaseOffices(XElement filterCriteria)
        {
            var officeKeys = filterCriteria.GetStringValue("OfficeKeys") ?? filterCriteria.GetStringValue("Office");
            if (string.IsNullOrEmpty(officeKeys)) return null;

            var officeKeysArray = officeKeys.Split(',');
            return _dbContext.Set<Office>().Where(_ => officeKeysArray.Contains(_.Id.ToString())).Select(_ =>
                                                                                                             new Picklists.Office
                                                                                                             {
                                                                                                                 Key = _.Id,
                                                                                                                 Value = _.Name
                                                                                                             }).ToArray();
        }

        CaseType[] GetCaseTypes(XElement filterCriteria)
        {
            var caseTypeKeys = filterCriteria.GetStringValue("CaseTypeKeys");
            if (string.IsNullOrEmpty(caseTypeKeys)) return new CaseType[0];

            var caseTypeKeysArray = caseTypeKeys.Split(',');
            return GetCaseTypesArray(caseTypeKeysArray);
        }

        Jurisdiction[] GetJurisdictions(XElement filterCriteria)
        {
            var jurisdictionKeys = filterCriteria.GetStringValue("CountryKeys");
            if (string.IsNullOrEmpty(jurisdictionKeys)) return new Jurisdiction[0];

            var jurisdictionKeysArray = jurisdictionKeys.Split(',');
            return GetJurisdictionArray(jurisdictionKeysArray);
        }

        Jurisdiction[] GetJurisdictionArray(string[] jurisdictionKeys)
        {
            return _dbContext.Set<Country>().Where(_ => jurisdictionKeys.Contains(_.Id))
                             .Select(_ => new Jurisdiction
                             {
                                 Code = _.Id,
                                 Value = _.Name
                             }).ToArray();
        }

        Status GetStatus(string keys)
        {
            var statuses = _caseStatuses.GetStatusByKeys(keys);
            var result = statuses.Select(s => new Status(s.StatusKey, s.StatusDescription, s.IsRenewal) { IsDefaultJurisdiction = s is ValidStatusListItem item && item.IsDefaultCountry });

            return result.FirstOrDefault();
        }

        CaseList GetCaseList(XElement filterCriteria)
        {
            var caseList = filterCriteria?.GetIntegerNullableValue("CaseList");
            if (caseList == null) return null;

            var pkCaseList = _dbContext.Set<InprotechKaizen.Model.Cases.CaseList>()
                                       .FirstOrDefault(_ => _.Id == caseList);
            if (pkCaseList == null) return null;

            return new CaseList
            {
                Key = pkCaseList.Id,
                Description = pkCaseList.Description,
                Value = pkCaseList.Name
            };
        }

        static string GetCaseReferenceOperator(XElement filterCriteria)
        {
            var caseKeysOperator = filterCriteria.Element("CaseKeys")?.Attribute("Operator")?.Value;
            return caseKeysOperator ?? filterCriteria.GetAttributeOperatorValue("CaseReference", "Operator", Operators.StartsWith);
        }

        dynamic GetCaseReferenceOrCaseKeys(XElement filterCriteria)
        {
            if (filterCriteria.Element("CaseReference") != null)
            {
                return filterCriteria.GetStringValue("CaseReference");
            }

            if (filterCriteria.Element("CaseKeys") == null) return null;
            var caseKeys = filterCriteria.GetStringValue("CaseKeys");
            return GetCases(caseKeys);
        }

        Picklists.Case[] GetCases(string caseKeys)
        {
            var caseIds = caseKeys.StringToIntList(",");
            var cases = _dbContext.Set<InprotechKaizen.Model.Cases.Case>()
                                  .Where(_ => caseIds.Contains(_.Id))
                                  .Select(c => new Picklists.Case
                                  {
                                      Key = c.Id,
                                      Code = c.Irn,
                                      Value = c.Title,
                                      OfficialNumber = c.CurrentOfficialNumber,
                                      CountryName = c.Country.Name,
                                      PropertyTypeDescription = c.PropertyType.Name
                                  }).ToArray();
            return cases;
        }

        CaseType[] GetCaseTypesArray(string[] caseTypeKeysArray)
        {
            return _caseTypes.GetCaseTypesWithDetails().Where(_ => caseTypeKeysArray.Contains(_.Code)).ToArray();
        }

        CaseFamily[] GetCaseFamilies(XElement filterCriteria)
        {
            var familyKeysList = filterCriteria.GetElements("FamilyKeyList", "FamilyKey").ToArray();
            if (!familyKeysList.Any()) return new CaseFamily[0];

            var familyKeyArray = Enumerable.Empty<string>();
            if (familyKeysList.Any())
            {
                familyKeyArray = familyKeysList.Select(k => k?.Value.Trim());
            }

            return _dbContext.Set<Family>().Where(_ => familyKeyArray.Contains(_.Id)).Select(_ => new CaseFamily
            {
                Key = _.Id,
                Value = _.Name
            }).ToArray();
        }

        PropertyType[] GetPropertyTypes(CasesSection topic, XElement filterCriteria)
        {
            var propertyTypeKeys = filterCriteria.GetStringValue("PropertyTypeKeys");
            if (string.IsNullOrEmpty(propertyTypeKeys)) return new PropertyType[0];

            var propertyTypes = _propertyTypes.GetPropertyTypes(topic.Jurisdiction.Value?.Select(_ => _.Code).ToArray());
            return propertyTypes.Where(_ => propertyTypeKeys.Contains(_.PropertyTypeKey))
                                .Select(_ => new PropertyType(_.Id, _.PropertyTypeKey, _.PropertyTypeDescription)).ToArray();
        }

        CaseCategory[] GetCaseCategories(CasesSection topic, XElement filterCriteria)
        {
            var categoryKeys = filterCriteria.GetStringValue("CategoryKey");
            if (string.IsNullOrEmpty(categoryKeys)) return new CaseCategory[0];

            var categoryKeysList = categoryKeys.Split(',');
            IEnumerable<CaseCategoryListItem> validCategories;

            if (topic.CaseType.Value?.Length == 1)
            {
                validCategories = _caseCategories.GetCaseCategories(topic.CaseType.Value?.FirstOrDefault()?.Code,
                                                                    topic.Jurisdiction.Value?.Select(_ => _.Code).ToArray(),
                                                                    topic.PropertyType.Value?.Select(_ => _.Code).ToArray());
            }
            else
            {
                validCategories = _caseCategories.GetCaseCategories(null, null, null);
            }

            return validCategories.Where(_ => categoryKeysList.Contains(_.CaseCategoryKey))
                                  .Select(_ => new CaseCategory(_.Id, _.CaseCategoryKey, _.CaseCategoryDescription)).ToArray();
        }
        SubType GetSubType(CasesSection topic, XElement filterCriteria)
        {
            var subType = filterCriteria.GetStringValue("SubTypeKey");
            if (subType == null) return null;

            IEnumerable<SubTypeListItem> validSubtypes;
            if (topic.CaseType.Value?.Length == 1)
            {
                validSubtypes = _subTypes.GetSubTypes(topic.CaseType.Value?.FirstOrDefault()?.Code,
                                                      topic.Jurisdiction.Value?.Select(_ => _.Code).ToArray(),
                                                      topic.PropertyType.Value?.Select(_ => _.Code).ToArray(),
                                                      topic.CaseCategory.Value?.Select(_ => _.Code).ToArray());
            }
            else
            {
                validSubtypes = _subTypes.GetSubTypes(null, null, null, null);
            }

            var selectedSybType = validSubtypes.FirstOrDefault(_ => _.SubTypeKey == subType);

            return selectedSybType != null ? new SubType(selectedSybType.Id, selectedSybType.SubTypeKey, selectedSybType.SubTypeDescription) : null;
        }

        Basis GetBasis(CasesSection topic, XElement filterCriteria)
        {
            var basis = filterCriteria.GetStringValue("BasisKey");
            if (basis == null) return null;

            topic.CaseType.Value = GetCaseTypes(filterCriteria);
            topic.Jurisdiction.Value = GetJurisdictions(filterCriteria);
            var isValidBasisRequired = topic.CaseCategory.Value?.Length == 1 && topic.Jurisdiction.Value?.Length == 1 && topic.PropertyType.Value?.Length == 1 && topic.CaseCategory.Value?.Length == 1;
            IEnumerable<BasisListItem> validBasis;
            if (isValidBasisRequired)
            {
                validBasis = _basis.GetBasis(topic.CaseType.Value.FirstOrDefault()?.Code,
                                             topic.Jurisdiction.Value?.Select(_ => _.Code).ToArray(),
                                             topic.PropertyType.Value?.Select(_ => _.Code).ToArray(),
                                             topic.CaseCategory.Value?.Select(_ => _.Code).ToArray());
            }
            else
            {
                validBasis = _basis.GetBasis(null, null, null, null);
            }

            var selectedBasis = validBasis.FirstOrDefault(_ => _.ApplicationBasisKey == basis);
            if (selectedBasis != null)
            {
                return topic.Jurisdiction.Value?.Length == 1
                    ? new Basis(selectedBasis.Id, selectedBasis.ApplicationBasisKey, selectedBasis.ApplicationBasisDescription, selectedBasis.Convention)
                    : new Basis(selectedBasis.Id, selectedBasis.ApplicationBasisKey, 1, selectedBasis.ApplicationBasisDescription);
            }

            return null;
        }
    }

    public class CasesSection
    {
        public CaseReferenceFormData CaseReference { get; set; }
        public CaseListFormData CaseList { get; set; }
        public OfficialNumberFormData OfficialNumber { get; set; }
        public StatusFormData CaseStatus { get; set; }
        public StatusFormData RenewalStatus { get; set; }
        public bool IsRegistered { get; set; }
        public bool IsPending { get; set; }
        public bool IsDead { get; set; }
        public NameTypeFormData Owner { get; set; }
        public NameTypeFormData Instructor { get; set; }
        public OtherNameTypesFormData OtherNameTypes { get; set; }
        public CaseOfficeFormData CaseOffice { get; set; }
        public CaseTypeFormData CaseType { get; set; }
        public JurisdictionFormData Jurisdiction { get; set; }
        public PropertyTypeFormData PropertyType { get; set; }
        public CaseFamilyFormData CaseFamily { get; set; }
        public CaseCategoryFormData CaseCategory { get; set; }
        public SubTypeFormData SubType { get; set; }
        public BasisFormData Basis { get; set; }
    }

    public class CaseReferenceFormData
    {
        public string Operator { get; set; }
        public dynamic Value { get; set; }
    }

    public class CaseListFormData
    {
        public string Operator { get; set; }
        public CaseList Value { get; set; }
    }

    public class CaseFamilyFormData
    {
        public string Operator { get; set; }
        public CaseFamily[] Value { get; set; }
    }

    public class OfficialNumberFormData
    {
        public string Operator { get; set; }
        public string Type { get; set; }
        public string Value { get; set; }
    }

    public class CaseOfficeFormData
    {
        public string Operator { get; set; }
        public Picklists.Office[] Value { get; set; }
    }

    public class CaseTypeFormData
    {
        public string Operator { get; set; }
        public CaseType[] Value { get; set; }
    }

    public class JurisdictionFormData
    {
        public string Operator { get; set; }
        public Jurisdiction[] Value { get; set; }
    }

    public class StatusFormData
    {
        public string Operator { get; set; }
        public Status Value { get; set; }
    }

    public class NameTypeFormData
    {
        public string Operator { get; set; }
        public dynamic Value { get; set; }
    }

    public class PropertyTypeFormData
    {
        public string Operator { get; set; }
        public PropertyType[] Value { get; set; }
    }

    public class CaseCategoryFormData
    {
        public string Operator { get; set; }
        public CaseCategory[] Value { get; set; }
    }

    public class SubTypeFormData
    {
        public string Operator { get; set; }
        public SubType Value { get; set; }
    }

    public class BasisFormData
    {
        public string Operator { get; set; }
        public Basis Value { get; set; }
    }

    public class OtherNameTypesFormData : NameTypeFormData
    {
        public string Type { get; set; }
    }
}