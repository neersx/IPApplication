using System;
using System.Reflection;

namespace InprotechKaizen.Model.Components.Cases.Comparison.DataMapping
{
    public class ComparisonScenario
    {
        public ComparisonScenario(ComparisonType comparisonType)
        {
            ComparisonType = comparisonType;
        }

        public ComparisonType ComparisonType { get; }
    }

    public class ComparisonScenario<T> : ComparisonScenario where T : new()
    {
        public ComparisonScenario(T comparisonSource, ComparisonType type) : base(type)
        {
            if (comparisonSource == null) throw new ArgumentNullException(nameof(comparisonSource));

            ComparisonSource = comparisonSource;

            Mapped = Copy(ComparisonSource);
        }

        public T ComparisonSource { get; set; }

        public T Mapped { get; set; }

        static T Copy(T comparisonSource)
        {
            var t = new T();

            foreach (var property in typeof(T).GetProperties(BindingFlags.Instance | BindingFlags.Public))
                property.SetValue(t, property.GetValue(comparisonSource));

            return t;
        }
    }
}