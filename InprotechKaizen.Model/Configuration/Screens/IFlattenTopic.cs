using System.Collections.Generic;
using System.Diagnostics.CodeAnalysis;

namespace InprotechKaizen.Model.Configuration.Screens
{
    public interface IFlattenTopic
    {
        string Name { get; }

        string Filter1Name { get; }

        string Filter2Name { get; }

        string Filter1Value { get; }

        string Filter2Value { get; }
    }

    public interface IPersistableFlattenTopic : IFlattenTopic
    {
        int? TopicId { get; }
    }

    public static class FlattenTopicExtension
    {
        public static int HashCode(this IFlattenTopic flattenTopic)
        {
            return new FlattenTopicEqualityComparer().GetHashCode(flattenTopic);
        }
    }

    public class FlattenTopicEqualityComparer : IEqualityComparer<IFlattenTopic>
    {
        [SuppressMessage("Microsoft.Design", "CA1062:Validate arguments of public methods", MessageId = "1")]
        public bool Equals(IFlattenTopic x, IFlattenTopic y)
        {
            if (ReferenceEquals(x, null)) return false;

            if (ReferenceEquals(x, y)) return true;

            return x.Name == y.Name &&
                   x.Filter1Name == y.Filter1Name &&
                   x.Filter1Value == y.Filter1Value &&
                   x.Filter2Name == y.Filter2Name &&
                   x.Filter2Value == y.Filter2Value;
        }

        [SuppressMessage("Microsoft.Design", "CA1062:Validate arguments of public methods", MessageId = "0")]
        public int GetHashCode(IFlattenTopic obj)
        {
            return new
                   {
                       obj.Name,
                       obj.Filter1Name,
                       obj.Filter1Value,
                       obj.Filter2Name,
                       obj.Filter2Value
                   }.GetHashCode();
        }
    }
}