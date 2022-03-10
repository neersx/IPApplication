using System.Diagnostics.CodeAnalysis;

namespace InprotechKaizen.Model.Components.Cases.Comparison.Results
{
    public class ComparisonError
    {
        [SuppressMessage("Microsoft.Naming", "CA1721:PropertyNamesShouldNotMatchGetMethods")]
        public string Type { get; set; }
        public string Key { get; set; }
        public dynamic Message { get; set; }
    }

    public static class ComparisonErrorTypes
    {
        public static readonly string MappingError = "Mapping";
    }
}