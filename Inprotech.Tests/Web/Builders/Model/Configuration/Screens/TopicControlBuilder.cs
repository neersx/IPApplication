using System.Collections.Generic;
using System.Linq;
using Inprotech.Infrastructure.Extensions;
using InprotechKaizen.Model.Configuration.Screens;

namespace Inprotech.Tests.Web.Builders.Model.Configuration.Screens
{
    public class TopicControlBuilder : IBuilder<TopicControl>
    {
        public TopicControlBuilder()
        {
            TopicControlFilters = new List<TopicControlFilter>();
        }

        public string Name { get; set; }

        public WindowControl WindowControl { get; set; }

        public short RowPosition { get; set; }

        public List<TopicControlFilter> TopicControlFilters { get; set; }

        public TopicControl Build()
        {
            var topic = new TopicControl(Name ?? Fixture.String("Name")) {RowPosition = RowPosition};

            WindowControl?.TopicControls.Add(topic);

            if (TopicControlFilters.Any())
            {
                topic.Filters.AddRange(TopicControlFilters);
            }

            return topic;
        }

        public static TopicControlBuilder For(WindowControl windowControl, string name, params TopicControlFilter[] filters)
        {
            var position = windowControl.TopicControls.Any() ? (short) (windowControl.TopicControls.Max(_ => _.RowPosition) + 1) : (short) 1;
            var topicControlBuilder = new TopicControlBuilder
            {
                Name = name,
                WindowControl = windowControl,
                RowPosition = position
            };

            if (filters != null && filters.Any()) topicControlBuilder.TopicControlFilters.AddRange(filters);

            return topicControlBuilder;
        }

        public static TopicControlBuilder For(string name, params TopicControlFilter[] filters)
        {
            var topicControlBuilder = new TopicControlBuilder
            {
                Name = name
            };

            if (filters.Any()) topicControlBuilder.TopicControlFilters.AddRange(filters);

            return topicControlBuilder;
        }
    }
}