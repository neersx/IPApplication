using System.Collections.Generic;
using System.Linq;
using Newtonsoft.Json.Linq;

namespace Inprotech.Web.BulkCaseImport
{
    public static class Fields
    {
        public const string PropertyType = "Property Type";
        public const string Country = "Country";
        public const string CaseType = "Case Type";
        public const string CaseCategory = "Case Category";
        public const string SubStype = "Sub Type";
        public const string Basis = "Basis";
        public const string Title = "Title";
        public const string ApplicationNumber = "Application Number";
        public const string ApplicationDate = "Application Date";
        public const string PublicationNumber = "Publication Number";
        public const string PublicationDate = "Publication Date";
        public const string RegistrationNumber = "Registration Number";
        public const string RegistrationDate = "Registration Date";
        public const string EarliestPriorityDate = "Earliest Priority Date";
        public const string ClientNameCode = "Client Name Code";
        public const string ClientName = "Client Name";
        public const string ClientGivenNames = "Client Given Names";
        public const string ClientCaseReference = "Client Case Reference";
        public const string ApplicantNameCode = "Applicant Name Code";
        public const string ApplicantName = "Applicant Name";
        public const string ApplicantGivenNames = "Applicant Given Names";
        public const string AgentNameCode = "Agent Name Code";
        public const string AgentName = "Agent Name";
        public const string AgentGivenNames = "Agent Given Names";
        public const string AgentCaseReference = "Agent Case Reference";
        public const string StaffNameCode = "Staff Name Code";
        public const string StaffGivenNames = "Staff Given Names";
        public const string StaffName = "Staff Name";
        public const string DesignatedCountries = "Designated Countries";
        public const string NumberOfClaims = "Number of Claims";
        public const string NumberOfDesigns = "Number of Designs";
        public const string EntitySize = "Entity Size";
        public const string TypeOfMark = "Type of Mark";
        public const string Classes = "Classes";
        public const string GoodsServicesDescription = "Goods and Services Description";
        public const string CaseReferenceStem = "Case Reference Stem";
        public const string CaseReference = "Case Reference";
        public const string CaseOffice = "Case Office";
        public const string Family = "Family";

        public const string InventorNameCodeBase = "Inventor Name Code";
        public const string InventorNameBase = "Inventor Name";
        public const string InventorGivenNamesBase = "Inventor Given Names";

        public struct RelatedCase
        {
            public const string PriorityCountry = "Priority Country";
            public const string PriorityNumber = "Priority Number";
            public const string PriorityDate = "Priority Date";
            public const string ParentRelationship = "Parent Relationship";
            public const string ParentCountry = "Parent Country";
            public const string ParentNumber = "Parent Number";
            public const string ParentDate = "Parent Date";

            public static List<string> AllRelatedCasesFields
            {
                get
                {
                    return typeof(RelatedCase).GetFields().Select(_ => _.GetRawConstantValue() as string).ToList();

                }
            }
        }

        public static List<string> All
        {
            get
            {
                var fields = typeof(Fields).GetFields().Select(_ => _.GetRawConstantValue() as string).ToList();
                return fields;
            }
        }
    }

    public class FieldDetails
    {
        List<string> _predefinedColumns;

        public HashSet<string> RelatedCasesSuffixes { get; private set; }

        public FieldDetails(IEnumerable<string> fields)
        {
            var trimmedFieldNames = fields.Select(_ => _.Trim());

            FindRelatedCasesSuffixes(trimmedFieldNames);

            SetPredefinedFields();
        }

        void SetPredefinedFields()
        {
            _predefinedColumns = Fields.All;
            if (RelatedCasesSuffixes.Count <= 0)
                return;

            foreach (var a in RelatedCasesSuffixes)
            {
                Fields.RelatedCase.AllRelatedCasesFields.ForEach(_ => _predefinedColumns.Add(_ + a));
            }
        }

        void FindRelatedCasesSuffixes(IEnumerable<string> fields)
        {
            RelatedCasesSuffixes = new HashSet<string> { string.Empty };
            var relatedcasesFields = Fields.RelatedCase.AllRelatedCasesFields;

            foreach (var f in fields)
            {
                var correspondingField = relatedcasesFields.SingleOrDefault(_ => f.StartsWith(_));
                if (correspondingField == null) continue;

                var appended = f.Replace(correspondingField, string.Empty);

                RelatedCasesSuffixes.Add(appended);
            }
        }

        public JToken GetCustomColumnsOnly(JToken @case)
        {
            return @case.Except(_predefinedColumns.ToArray());
        }
    }
}