using System.Data.Entity;
using InprotechKaizen.Model.Persistence;

namespace InprotechKaizen.Model.Keywords
{
    public class KeywordModuleBuilder : IModelBuilder
    {
        public void Build(DbModelBuilder modelBuilder)
        {
            modelBuilder.Entity<Keyword>().Map(m => m.ToTable("KEYWORDS"));
            modelBuilder.Entity<CaseWord>().Map(m => m.ToTable("CASEWORDS"));
            modelBuilder.Entity<Synonyms>().Map(m => m.ToTable("SYNONYMS"));
        }
    }
}
