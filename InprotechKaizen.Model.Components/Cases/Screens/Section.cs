using System.Collections.Generic;
using System.Linq;
using InprotechKaizen.Model.Configuration.Screens;

namespace InprotechKaizen.Model.Components.Cases.Screens
{
    public class Section
    {
        public int TopicId { get; set; }

        public int? TabId { get; set; }

        public string TopicTitle { get; set; }

        public string TabTitle { get; set; }

        public string TopicRawName { get; set; }

        public string Ref
        {
            get
            {
                if (!string.IsNullOrWhiteSpace(TopicSuffix) || (Filters ?? new Dictionary<string, string>()).Any())
                {
                    return $"{TopicBaseName}_{TopicSuffix}_{TabId}";
                }

                return null;
            }
        }

        public string Title => IsCombined ? TabTitle : TopicTitle;

        public IEnumerable<TopicControlFilter> RawFilters { get; set; }

        public string TopicBaseName
        {
            get
            {
                var cloned = TopicRawName?.IndexOf("_cloned") ?? -1;
                return cloned > -1
                    ? TopicRawName?.Substring(0, cloned)
                    : TopicRawName;
            }
        }

        public bool IsCombined { get; set; }

        public string TopicSuffix { get; set; }

        public Dictionary<string, string> Filters { get; set; }
    }

    public class ControllableField
    {
        public string FieldName { get; set; }

        public string Label { get; set; }

        public bool Hidden { get; set; }
    }
}
