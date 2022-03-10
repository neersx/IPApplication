using System;
using System.Data.Entity;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Persistence;

namespace InprotechKaizen.Model.PriorArt
{
    public class CaseSearchResultModelBuilder : IModelBuilder
    {
        public void Build(DbModelBuilder modelBuilder)
        {
            if (modelBuilder == null) throw new ArgumentNullException("modelBuilder");

            var caseSearchResult = modelBuilder.Entity<CaseSearchResult>();

            caseSearchResult.HasKey(x => x.Id);

            caseSearchResult.HasRequired(x => x.Case)
                .WithMany(x => x.CaseSearchResult);
            
            caseSearchResult.HasRequired(x => x.PriorArt)
                .WithMany(x => x.CaseSearchResult);
        }
    }
}
