using System;
using System.Diagnostics.CodeAnalysis;

namespace InprotechKaizen.Model.Components.Cases.Comparison.Results
{
    [SuppressMessage("Microsoft.Naming", "CA1716:IdentifiersShouldNotMatchKeywords", MessageId = "Case")]
    public class Case
    {
        public Case()
        {
            Messages = new string[0];
        }

        public int? CaseId { get; set; }

        public string PropertyTypeCode { get; set; }

        public string ApplicationLanguageCode { get; set; }

        public Value<string> Ref { get; set; }

        public Value<string> Title { get; set; }

        public Value<string> TypeOfMark { get; set; }

        public Value<string> Status { get; set; }

        [SuppressMessage("Microsoft.Design", "CA1006:DoNotNestGenericTypesInMemberSignatures")]
        public Value<DateTime?> StatusDate { get; set; }

        public Value<string> LocalClasses { get; set; }

        public Value<string> IntClasses { get; set; }

        public Value<string> Country { get; set; }

        public Value<string> PropertyType { get; set; }

        public string SourceId { get; set; }

        public Uri SourceLink { get; set; }

        public string[] Messages { get; set; }
    }
}