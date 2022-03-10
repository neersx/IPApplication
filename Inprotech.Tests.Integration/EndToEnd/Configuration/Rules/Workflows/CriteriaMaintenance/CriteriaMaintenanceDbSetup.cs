using System.Linq;
using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.Utils;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Configuration;
using InprotechKaizen.Model.Rules;

namespace Inprotech.Tests.Integration.EndToEnd.Configuration.Rules.Workflows.CriteriaMaintenance
{
    public class CriteriaMaintenanceDbSetup : DbSetup
    {
        static readonly string OfficeDescription = Fixture.Prefix("office");
        static readonly string CaseTypeDescription = Fixture.Prefix("casetype");
        static readonly string JurisdictionDescription = Fixture.Prefix("country");
        static readonly string PropertyTypeDescription = Fixture.Prefix("propertytype");
        static readonly string ActionDescription = Fixture.Prefix("action");
        static readonly string CaseCategoryDescription = Fixture.Prefix("casecategory");
        static readonly string SubTypeDescription = Fixture.Prefix("subtype");
        static readonly string BasisDescription = Fixture.Prefix("basis");
        static readonly string CriteriaName = Fixture.Prefix("Criteria Name");
        static readonly string RenewalTypeDescription = Fixture.Prefix("RenewalType");

        public DetailDataFixture SetUp()
        {
            {
                var office = InsertWithNewId(new Office
                                             {
                                                 Name = OfficeDescription
                                             });

                var caseType = InsertWithNewId(new CaseType {Name = CaseTypeDescription});
                var country = InsertWithNewId(new Country {Name = JurisdictionDescription, Type = "0"});
                var propertyType = InsertWithNewId(new PropertyType {Name = PropertyTypeDescription});
                var act = InsertWithNewId(new Action {Name = ActionDescription, ActionType = 1}); // renewals action
                var caseCategory = Insert(new CaseCategory {CaseTypeId = caseType.Code, Name = CaseCategoryDescription});
                var subType = InsertWithNewId(new SubType {Name = SubTypeDescription});
                var basis = InsertWithNewId(new ApplicationBasis {Name = BasisDescription});
                InsertWithNewId(new TableCode { Name = RenewalTypeDescription, TableTypeId = (int)TableTypes.RenewalType});

                return new DetailDataFixture
                       {
                           Office = OfficeDescription,
                           CaseType = CaseTypeDescription,
                           Jurisdiction = JurisdictionDescription,
                           PropertyType = PropertyTypeDescription,
                           Action = ActionDescription,
                           CaseCategory = CaseCategoryDescription,
                           SubType = SubTypeDescription,
                           Basis = BasisDescription,
                           RenewalType = RenewalTypeDescription,
                           CriteriaName = CriteriaName
                       };
            }
        }

        public Criteria GetCriteria(string criteriaName)
        {
            return DbContext.Set<Criteria>().FirstOrDefault(_ => _.Description == criteriaName);
        }

        public class DetailDataFixture
        {
            public string Action;
            public string Basis;
            public string CaseCategory;
            public string CaseType;
            public string CriteriaId;
            public string CriteriaName;
            public string InUse;
            public string Jurisdiction;
            public string LocalOrForeign;
            public string Office;
            public string PropertyType;
            public string Protected;
            public string SubType;
            public string RenewalType;
        }
    }
}