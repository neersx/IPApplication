using System.Collections.Generic;
using System.Linq;
using System.Xml;
using System.Xml.Linq;

namespace Inprotech.Web.Search.TaskPlanner.SavedSearch
{
    public interface ITaskPlannerSavedSearch
    {
        dynamic GetTaskPlannerSavedSearchData(string xmlFilterCriteria);
    }

    public interface ITaskPlannerTopicBuilder
    {
        TaskPlannerSavedSearch.Topic Build(XElement filterCriteria);
    }

    public class TaskPlannerSavedSearch : ITaskPlannerSavedSearch
    {
        readonly IEnumerable<ITaskPlannerTopicBuilder> _topicBuilders;

        public TaskPlannerSavedSearch(IEnumerable<ITaskPlannerTopicBuilder> topicBuilders)
        {
            _topicBuilders = topicBuilders;
        }

        public dynamic GetTaskPlannerSavedSearchData(string xmlFilterCriteria)
        {
            if (string.IsNullOrEmpty(xmlFilterCriteria))
            {
                throw Exceptions.BadRequest("xmlFilterCriteria");
            }

            XDocument xDoc;
            try
            {
                xDoc = XDocument.Parse(xmlFilterCriteria);
            }
            catch (XmlException)
            {
                throw Exceptions.BadRequest("xmlFilterCriteria");
            }

            var filterCriteriaElement = xDoc.Descendants("FilterCriteria").FirstOrDefault();

            if (filterCriteriaElement == null)
            {
                throw Exceptions.BadRequest("xmlFilterCriteria");
            }

            var topics = new List<Topic>();
            topics.AddRange(_topicBuilders.Select(builder => builder.Build(filterCriteriaElement)));

            return topics;
        }

        public class Topic
        {
            public Topic(string key)
            {
                TopicKey = key;
            }

            public string TopicKey { get; set; }
            public dynamic FormData { get; set; }
        }
    }
}