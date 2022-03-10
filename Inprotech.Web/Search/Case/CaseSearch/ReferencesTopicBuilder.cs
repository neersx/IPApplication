using System;
using System.Collections.Generic;
using System.Linq;
using Inprotech.Web.Picklists;
using System.Xml.Linq;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Persistence;
using CaseList = Inprotech.Web.Picklists.CaseList;

namespace Inprotech.Web.Search.Case.CaseSearch
{
    public class ReferencesTopicBuilder : ITopicBuilder
    {
        readonly IDbContext _dbContext;

        public ReferencesTopicBuilder(IDbContext dbContext)
        {
            _dbContext = dbContext;
        }

        public CaseSavedSearch.Topic Build(XElement filterCriteria)
        {
            var topic = new CaseSavedSearch.Topic("References");
            var references = new ReferencesTopic
            {
                Id = filterCriteria.GetAttributeIntValue("ID"),
                YourReference = filterCriteria.GetStringValue("ClientReference"),
                YourReferenceOperator = filterCriteria.GetAttributeOperatorValue("ClientReference", "Operator"),
                CaseReference = filterCriteria.GetStringValue("PickListSearch") ?? filterCriteria.GetStringValue("CaseReference"),
                CaseReferenceOperator = GetCaseReferenceOperator(filterCriteria),
                CaseKeys = GetCases(filterCriteria.GetStringValue("PickListSearch") ?? filterCriteria.GetStringValue("CaseKeys")),
                OfficialNumberOperator = filterCriteria.GetAttributeOperatorValue("OfficialNumber", "Operator"),
                SearchRelatedCases = filterCriteria.GetAttributeOperatorValue("OfficialNumber", "UseRelatedCase") == "1",
                Family = GetCaseFamilies(filterCriteria),
                FamilyOperator = filterCriteria.GetAttributeOperatorValue("FamilyKey", "Operator"),
                OfficialNumberType = filterCriteria.Element("OfficialNumber")?.GetStringValue("TypeKey") ?? string.Empty,
                OfficialNumber = filterCriteria.Element("OfficialNumber")?.GetStringValue("Number"),
                SearchNumbersOnly = filterCriteria.Element("OfficialNumber")?.GetAttributeOperatorValue("Number", "UseNumericSearch") == "1",
                CaseNameReferenceOperator = filterCriteria.GetAttributeOperatorValue("CaseNameReference", "Operator", Operators.StartsWith),
                CaseNameReferenceType = filterCriteria.Element("CaseNameReference")?.GetStringValue("TypeKey"),
                CaseNameReference = filterCriteria.Element("CaseNameReference")?.GetStringValue("ReferenceNo"),
                CaseListOperator = filterCriteria.Element("CaseList")?.GetAttributeOperatorValue("CaseListKey", "Operator") ?? Operators.EqualTo,
                CaseList = GetCaseList(filterCriteria.Element("CaseList")),
                IsPrimeCasesOnly = filterCriteria.GetAttributeOperatorValue("CaseList", "IsPrimeCasesOnly") == "1"
            };
            topic.FormData = references;
            return topic;
        }

        static string GetCaseReferenceOperator(XElement filterCriteria)
        {
            var caseKeysOperator = filterCriteria.Element("CaseKeys")?.Attribute("Operator")?.Value;
            return caseKeysOperator ?? filterCriteria.GetAttributeOperatorValue("CaseReference", "Operator", Operators.StartsWith);
        }

        CaseFamily[] GetCaseFamilies(XElement filterCriteria)
        {
            IEnumerable<string> familyKeyArray;
            var familyKeysList = filterCriteria.GetElements("FamilyKeyList", "FamilyKey").ToArray();
            if (familyKeysList.Any())
            {
                familyKeyArray = familyKeysList.Select(k => k?.Value.Trim());
            }
            else
            {
                var familyKeys = filterCriteria.GetStringValue("FamilyKey");
                if (string.IsNullOrEmpty(familyKeys)) return null;
                familyKeyArray = familyKeys.Split(',');
            }

            return _dbContext.Set<Family>().Where(_ => familyKeyArray.Contains(_.Id)).Select(_ => new CaseFamily
            {
                Key = _.Id,
                Value = _.Name
            }).ToArray();
        }

        CaseList GetCaseList(XElement filterCriteria)
        {
            var caseList = filterCriteria?.GetIntegerNullableValue("CaseListKey");
            if (caseList == null) return null;
            var pkCaseList = _dbContext.Set<InprotechKaizen.Model.Cases.CaseList>().FirstOrDefault(_ => _.Id == caseList);
            if (pkCaseList == null) return null;
            return new CaseList
            {
                Key = pkCaseList.Id,
                Description = pkCaseList.Description,
                Value = pkCaseList.Name
            };
        }

        Picklists.Case[] GetCases(string caseKeys)
        {
            var @caseIds = caseKeys.StringToIntList(",");
            var @cases = _dbContext.Set<InprotechKaizen.Model.Cases.Case>()
                                   .Where(_ => @caseIds.Contains(_.Id))
                                   .Select(c => new Picklists.Case
                                   {
                                       Key = c.Id,
                                       Code = c.Irn,
                                       Value = c.Title,
                                       OfficialNumber = c.CurrentOfficialNumber,
                                       CountryName = c.Country.Name,
                                       PropertyTypeDescription = c.PropertyType.Name
                                   }).ToArray();
            return @cases;
        }
    }

    public class ReferencesTopic
    {
        public int Id { get; set; }
        public string YourReferenceOperator { get; set; }
        public string YourReference { get; set; }
        public string CaseReferenceOperator { get; set; }
        public string CaseReference { get; set; }
        public Picklists.Case[] CaseKeys { get; set; }
        public string OfficialNumberType { get; set; }
        public string OfficialNumberOperator { get; set; }
        public string OfficialNumber { get; set; }
        public string CaseNameReferenceType { get; set; }
        public string CaseNameReferenceOperator { get; set; }
        public string CaseNameReference { get; set; }
        public string FamilyOperator { get; set; }
        public CaseFamily[] Family { get; set; }
        public string CaseListOperator { get; set; }
        public CaseList CaseList { get; set; }
        public bool SearchNumbersOnly { get; set; }
        public bool SearchRelatedCases { get; set; }
        public bool IsPrimeCasesOnly { get; set; }
    }

    public static class StringToIntListExtension
    {
        public static IEnumerable<int> StringToIntList(this string commaSeparatedString, string separater)
        {
            if (string.IsNullOrEmpty(commaSeparatedString))
                yield break;
            if (separater == null)
            {
                throw new ArgumentNullException(nameof(separater));
            }
            foreach (var s in commaSeparatedString.Split(separater.ToCharArray()))
            {
                int num;
                if (int.TryParse(s, out num))
                    yield return num;
            }
        }
    }
}

