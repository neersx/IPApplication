using System.Linq;
using System.Xml.Linq;
using Inprotech.Web.CaseSupportData;
using Inprotech.Web.Picklists;
using InprotechKaizen.Model.Components.Cases;

namespace Inprotech.Web.Search.Case.CaseSearch
{
    public class StatusTopicBuilder : ITopicBuilder
    {
        readonly ICaseStatuses _caseStatuses;

        public StatusTopicBuilder(ICaseStatuses caseStatuses)
        {
            _caseStatuses = caseStatuses;
        }

        public CaseSavedSearch.Topic Build(XElement filterCriteria)
        {
            var topic = new CaseSavedSearch.Topic("Status");
            var formData = new StatusTopic
            {
                Id = filterCriteria.GetAttributeIntValue("ID"),
                IsPending = filterCriteria.GetXPathBooleanValue("StatusFlags/IsPending"),
                IsDead = filterCriteria.GetXPathBooleanValue("StatusFlags/IsDead"),
                IsRegistered = filterCriteria.GetXPathBooleanValue("StatusFlags/IsRegistered"),
                CaseStatus = GetStatuses(filterCriteria.GetStringValue("StatusKey")),
                RenewalStatus = GetStatuses(filterCriteria.GetStringValue("RenewalStatusKey")),
                RenewalStatusOperator = filterCriteria.GetAttributeOperatorValue("RenewalStatusKey", "Operator"),
                CaseStatusOperator =filterCriteria.GetAttributeOperatorValue("StatusKey", "Operator") 
                
            };
            topic.FormData = formData;
            return topic;
        }

        Status[] GetStatuses(string keys)
        {
           var statuses = _caseStatuses.GetStatusByKeys(keys);
           var result = statuses.Select(s => new Status(s.StatusKey, s.StatusDescription, s.IsRenewal) { IsDefaultJurisdiction = s is ValidStatusListItem item && item.IsDefaultCountry });
           return result.ToArray();
        }
    }

    public class StatusTopic
    {
        public int Id { get; set; }

        public bool IsPending { get; set; }

        public bool IsRegistered { get; set; }

        public bool IsDead { get; set; }

        public string CaseStatusOperator { get; set; }

        public Status [] CaseStatus { get; set; }
        
        public string RenewalStatusOperator { get; set; }

        public Status [] RenewalStatus{ get; set; }

    }
}
