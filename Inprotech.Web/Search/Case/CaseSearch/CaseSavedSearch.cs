using Inprotech.Web.Search.Case.CaseSearch.DueDate;
using System.Collections.Generic;
using System.Linq;
using System.Xml;
using System.Xml.Linq;

namespace Inprotech.Web.Search.Case.CaseSearch
{
    public interface ICaseSavedSearch
    {
        dynamic GetCaseSavedSearchData(string xmlFilterCriteria);

        DueDateData GetSavedDueDateData(string xmlFilterCriteria);
    }

    public interface ITopicBuilder
    {
        CaseSavedSearch.Topic Build(XElement filterCriteria);
    }

    public class CaseSavedSearch : ICaseSavedSearch
    {
        readonly IEnumerable<ITopicBuilder> _topicBuilders;
        readonly IDueDateBuilder _dueDateBuilder;
        
        public CaseSavedSearch(IEnumerable<ITopicBuilder> topicBuilders, IDueDateBuilder dueDateBuilder)
        {
            _topicBuilders = topicBuilders;
            _dueDateBuilder = dueDateBuilder;
        }
        public class Step
        {
            public int Id { get; set; }
            public bool IsDefault { get; set; }
            public string Operator { get; set; }
            public bool Selected { get; set; }

            public bool IsAdvancedSearch { get; set; }

            public Topic[] TopicsData { get; set; }
        }

        public class Topic
        {
            public Topic(string key)
            {
                TopicKey = key;
            }
            public string TopicKey { get; set; }
            public dynamic FormData { get; set; }
            public dynamic FilterData { get; set; }
        }
        
        public dynamic GetCaseSavedSearchData(string xmlFilterCriteria)
        {
            if (string.IsNullOrEmpty(xmlFilterCriteria))
                throw Exceptions.BadRequest("xmlFilterCriteria");

            XDocument xDoc;
            try
            {
                xDoc = XDocument.Parse(xmlFilterCriteria);
            }
            catch (XmlException)
            {
                throw Exceptions.BadRequest("xmlFilterCriteria");
            }

            var filterCriteriaGroup = xDoc.Descendants("FilterCriteriaGroup").FirstOrDefault();

            if(filterCriteriaGroup == null) 
                throw Exceptions.BadRequest("xmlFilterCriteria");

            var steps = new List<Step>();
            
            foreach (var filterCriteria in filterCriteriaGroup.Elements())
            {
                var topics = _topicBuilders.Select(builder => builder.Build(filterCriteria)).ToList();

                var step = new Step
                {
                    Id = filterCriteria.GetAttributeIntValue("ID"),
                    Operator = filterCriteria.GetAttributeStringValue("BooleanOperator") ?? "AND",
                    IsAdvancedSearch = filterCriteria.GetAttributeBooleanValue("IsAdvancedFilter"),
                    TopicsData = topics.ToArray()
                };

                steps.Add(step);
            }

            if (steps.Count <= 0) return steps;
            steps.First().IsDefault = true;
            steps.First().Selected = true;

            return steps;
        }

        public DueDateData GetSavedDueDateData(string xmlFilterCriteria)
        {
            if (string.IsNullOrEmpty(xmlFilterCriteria))
                throw Exceptions.BadRequest("xmlFilterCriteria");

            XDocument xDoc;
            try
            {
                xDoc = XDocument.Parse(xmlFilterCriteria);
            }
            catch (XmlException)
            {
                throw Exceptions.BadRequest("xmlFilterCriteria");
            }

            var dueDateFilterCriteria = xDoc.Descendants("ColumnFilterCriteria").FirstOrDefault();

            if(dueDateFilterCriteria == null) 
                return null;
           
            return _dueDateBuilder.Build(dueDateFilterCriteria.Descendants("DueDates").FirstOrDefault());
        }
    }
}
