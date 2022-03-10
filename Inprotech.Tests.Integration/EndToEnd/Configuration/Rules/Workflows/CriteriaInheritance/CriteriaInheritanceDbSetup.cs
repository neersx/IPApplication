using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.Utils;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Rules;

namespace Inprotech.Tests.Integration.EndToEnd.Configuration.Rules.Workflows.CriteriaInheritance
{
    public class CriteriaInheritanceDbSetup : DbSetup
    {
        static readonly string DetailCriteria = Fixture.Prefix("detail");
        static readonly string ParentCriteria = Fixture.Prefix("1parent");
        static readonly string ChildCriteria = Fixture.Prefix("child");
        static readonly string AnotherCriteria = Fixture.Prefix("2another");
        static readonly string GrandChildCriteria = Fixture.Prefix("grandchild");
        static readonly string OfficeDescription = Fixture.Prefix("office");
        static readonly string CaseTypeDescription = Fixture.Prefix("casetype");
        static readonly string JurisdictionDescription = Fixture.Prefix("country");
        static readonly string PropertyTypeDescription = Fixture.Prefix("propertytype");
        static readonly string ActionDescription = Fixture.Prefix("action");
        static readonly string CaseCategoryDescription = Fixture.Prefix("casecategory");
        static readonly string SubTypeDescription = Fixture.Prefix("subtype");
        static readonly string BasisDescription = Fixture.Prefix("basis");

        public CriteriaInheritanceDbSetup(IDbContext dbContext) : base(dbContext)
        {
        }

        public DataFixture SetUp()
        {

            var parent = InsertWithNewId(new Criteria
                                         {
                                             Description = ParentCriteria,
                                             PurposeCode = CriteriaPurposeCodes.EventsAndEntries,
                                             UserDefinedRule = 0
                                         });

            var child = InsertWithNewId(new Criteria
                                        {
                                            Description = ChildCriteria,
                                            PurposeCode = CriteriaPurposeCodes.EventsAndEntries,
                                            UserDefinedRule = 1
                                        });

            var grandChild = InsertWithNewId(new Criteria
                                             {
                                                 Description = GrandChildCriteria,
                                                 PurposeCode = CriteriaPurposeCodes.EventsAndEntries
                                             });

            Insert(new Inherits
                   {
                       Criteria = grandChild,
                       FromCriteria = child
                   });

            Insert(new Inherits
                   {
                       Criteria = child,
                       FromCriteria = parent
                   });

            var another = InsertWithNewId(new Criteria
            {
                Description = AnotherCriteria,
                PurposeCode = CriteriaPurposeCodes.EventsAndEntries
            });

            return new DataFixture
                   {
                       ParentId = parent.Id.ToString(),
                       ChildId = child.Id.ToString(),
                       AnotherId = another.Id.ToString(),
                       GrandChildId = grandChild.Id.ToString()
                   };
        }

        public DetailDataFixture SetUpDetail()
        {
            var office = InsertWithNewId(new Office
                                         {
                                             Name = OfficeDescription
                                         });

            var caseType = InsertWithNewId(new CaseType {Name = CaseTypeDescription});
            var country = InsertWithNewId(new Country {Name = JurisdictionDescription, Type = "0"});
            var propertyType = InsertWithNewId(new PropertyType {Name = PropertyTypeDescription});
            var act = InsertWithNewId(new Action {Name = ActionDescription});
            var caseCategory = Insert(new CaseCategory {CaseTypeId = caseType.Code, Name = CaseCategoryDescription});
            var subType = InsertWithNewId(new SubType {Name = SubTypeDescription});
            var basis = InsertWithNewId(new ApplicationBasis {Name = BasisDescription});

            var criteria = InsertWithNewId(new Criteria
                                           {
                                               Description = DetailCriteria,
                                               PurposeCode = CriteriaPurposeCodes.EventsAndEntries,
                                               LocalClientFlag = 0,
                                               RuleInUse = 1,
                                               Office = office,
                                               CaseType = caseType,
                                               Country = country,
                                               PropertyType = propertyType,
                                               Action = act,
                                               CaseCategory = caseCategory,
                                               SubType = subType,
                                               Basis = basis
                                           });

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
                       LocalOrForeign = criteria.IsLocalClient == null ? string.Empty : (criteria.IsLocalClient == true ? "Local clients" : "Foreign clients"),
                       Protected = criteria.IsProtected ? "Yes" : "No",
                       InUse = criteria.InUse ? "Yes" : "No",
                       CriteriaId = criteria.Id.ToString(),
                       CriteriaName = criteria.Description
                   };
        }

        public class DataFixture
        {
            public string ParentName => ParentCriteria;
            public string ParentId { get; internal set; }
            public string ChildName => ChildCriteria;
            public string ChildId { get; internal set; }
            public string AnotherName => AnotherCriteria;
            public string AnotherId { get; internal set; }
            public string GrandChildName => GrandChildCriteria;
            public string GrandChildId { get; internal set; }
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
        }
    }
}