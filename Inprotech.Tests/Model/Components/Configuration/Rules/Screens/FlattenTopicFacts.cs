using InprotechKaizen.Model.Configuration.Screens;
using Xunit;

namespace Inprotech.Tests.Model.Components.Configuration.Rules.Screens
{
    public class FlattenTopicFacts
    {
        [Fact]
        public void GetsHashCodeForTopic()
        {
            var topic = new TopicControl("newTopic");
            topic.Filters.Add(new TopicControlFilter("filter1", "filter1Value"));
            topic.Filters.Add(new TopicControlFilter("filter2", "filter2Value"));

            var flattenEquality = new FlattenTopicEqualityComparer();
            Assert.Equal(flattenEquality.GetHashCode(topic), topic.HashCode());
        }
    }
}