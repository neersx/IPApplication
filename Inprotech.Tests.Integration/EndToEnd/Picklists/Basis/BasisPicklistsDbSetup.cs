using System.Linq;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.ValidCombinations;

namespace Inprotech.Tests.Integration.EndToEnd.Picklists.Basis
{
    class BasisPicklistsDbSetup
    {
        public const string BasisPrefix = "e2e - basis";
        public const string ExistingBasis = BasisPrefix + " existing";
        public const string ExistingBasis2 = ExistingBasis + "2";
        public const string ExistingBasis3 = ExistingBasis + "3";
        public const string BasisToBeAdded = BasisPrefix + " add";

        public BasisPicklistsDbSetup()
        {
            DbContext = new SqlDbContext();
        }

        public IDbContext DbContext { get; }

        public ScenarioData Prepare()
        {
            var existingBasis = AddBasis("1", ExistingBasis);
            AddBasis("2", ExistingBasis2);
            AddBasis("3", ExistingBasis3);

            return new ScenarioData
                   {
                       BasisId = existingBasis.Code,
                       BasisName = existingBasis.Name,
                       ExistingApplicationBasis = existingBasis
                   };
        }

        public ApplicationBasis AddBasis(string id, string name)
        {
            var basis = DbContext.Set<ApplicationBasis>().FirstOrDefault(_ => _.Code == id);
            if (basis != null)
                return basis;

            basis = new ApplicationBasis(id, name)
                    {
                        Convention = 1m
                    };

            DbContext.Set<ApplicationBasis>().Add(basis);
            DbContext.SaveChanges();

            return basis;
        }

        public void AddValidBasis(ApplicationBasis basis)
        {
            var country = DbContext.Set<Country>().FirstOrDefault();
            var propertyType = DbContext.Set<InprotechKaizen.Model.Cases.PropertyType>().FirstOrDefault();
            var validBasis = new ValidBasis(country, propertyType, basis);

            DbContext.Set<ValidBasis>().Add(validBasis);
            DbContext.SaveChanges();
        }

        public class ScenarioData
        {
            public string BasisId;
            public string BasisName;
            public ApplicationBasis ExistingApplicationBasis;
        }
    }
}